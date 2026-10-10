import 'dart:math' as math;

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import '../models/language.dart';
import '../models/translation_result.dart';
import 'translator_service.dart';

/// On-device NLLB-200 translator (ONNX Runtime) for the ISLA app.
///
/// Implements [TranslatorService], so the UI can use it exactly like the
/// mock translator. Call [init] once at startup; [isReady] turns true when
/// the model files have loaded.
class NllbTranslatorService implements TranslatorService {
  NllbTranslatorService();

  static const String _encoderAsset = 'assets/models/encoder_model.onnx';
  static const String _decoderAsset = 'assets/models/decoder_model.onnx';
  static const String _tokenizerAsset = 'assets/models/tokenizer.json';

  /// App language id -> NLLB language tag.
  static const Map<String, String> languageCodes = {
    'en': 'eng_Latn',
    'fil': 'tgl_Latn',
    'ini': 'rol_Latn',
    'onh': 'loc_Latn',
    'asi': 'bno_Latn',
  };

  static const int _maxInputTokens = 200;
  static const int _maxNewTokens = 200;

  final OnnxRuntime _ort = OnnxRuntime();
  late OrtSession _encoderSession;
  late OrtSession _decoderSession;
  late SentencePieceTokenizer _tokenizer;

  bool _ready = false;
  Future<void>? _initFuture;

  @override
  bool get isReady => _ready;

  /// Loads the model and tokenizer. Safe to call more than once.
  Future<void> init() => _initFuture ??= _load();

  Future<void> _load() async {
    _encoderSession = await _ort.createSessionFromAsset(_encoderAsset);
    _decoderSession = await _ort.createSessionFromAsset(_decoderAsset);
    final tokenizerJson = await rootBundle.loadString(_tokenizerAsset);
    _tokenizer = TokenizerJsonLoader.fromJsonString(tokenizerJson);
    _ready = true;
  }

  /// True when the loaded model knows this language (its tag is in the
  /// tokenizer vocabulary). The old English-Filipino model only knows
  /// 'en' and 'fil'.
  bool supportsLanguage(String languageId) {
    if (!_ready) return false;
    final code = languageCodes[languageId];
    return code != null && _tokenizer.vocab.vocabularyMap.containsKey(code);
  }

  @override
  Future<TranslationResult> translate({
    required String text,
    required Language source,
    required Language target,
  }) async {
    if (!_ready) {
      throw StateError('The translation model is not ready yet.');
    }
    final sourceCode = languageCodes[source.id];
    final targetCode = languageCodes[target.id];
    if (sourceCode == null || targetCode == null) {
      throw UnsupportedError(
        'No NLLB language tag for ${source.id} or ${target.id}.',
      );
    }
    final vocab = _tokenizer.vocab.vocabularyMap;
    final sourceTagId = vocab[sourceCode];
    final targetTagId = vocab[targetCode];
    if (sourceTagId == null || targetTagId == null) {
      throw UnsupportedError(
        'The loaded model does not include $sourceCode or $targetCode.',
      );
    }

    final stopwatch = Stopwatch()..start();
    final outputs = <String>[];
    var logProbSum = 0.0;
    var tokenCount = 0;

    for (final sentence in _splitSentences(text)) {
      final result = await _translateSentence(
        sentence,
        sourceTagId,
        targetTagId,
      );
      if (result.text.isNotEmpty) outputs.add(result.text);
      logProbSum += result.logProbSum;
      tokenCount += result.tokenCount;
    }

    // Confidence = geometric mean of the probability the model gave to each
    // word piece it produced. It is a rough signal, not a measured accuracy.
    final confidence =
        tokenCount == 0 ? 0.0 : math.exp(logProbSum / tokenCount);
    return TranslationResult(
      text: outputs.join(' '),
      confidence: math.min(1.0, math.max(0.0, confidence)),
      latencyMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// NLLB is trained on single sentences, so long input is translated one
  /// sentence at a time. Line breaks (for example from OCR) become spaces.
  List<String> _splitSentences(String text) {
    final collapsed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) return const [];
    return collapsed
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  Future<OrtValue> _makeInt64Tensor(List<int> data, List<int> shape) async {
    final tensor = await OrtValue.fromList(data, shape);
    return tensor.to(OrtDataType.int64);
  }

  Future<_SentenceResult> _translateSentence(
    String sentence,
    int sourceTagId,
    int targetTagId,
  ) async {
    final rawEncoding = _tokenizer.encode(sentence, addSpecialTokens: false);
    var tokenIds = rawEncoding.ids;
    if (tokenIds.length > _maxInputTokens) {
      tokenIds = tokenIds.sublist(0, _maxInputTokens);
    }

    final eosTokenId = _tokenizer.vocab.eosId;
    final inputIds = <int>[sourceTagId, ...tokenIds, eosTokenId];
    final attentionMask = List<int>.filled(inputIds.length, 1);

    final encoderInputs = {
      'input_ids': await _makeInt64Tensor(inputIds, [1, inputIds.length]),
      'attention_mask': await _makeInt64Tensor(attentionMask, [
        1,
        inputIds.length,
      ]),
    };
    final encoderOutputs = await _encoderSession.run(encoderInputs);
    final encoderHiddenStates = encoderOutputs['last_hidden_state']!;

    // The decoder must start with [eos, target language tag].
    final decoderIds = <int>[eosTokenId, targetTagId];
    final generated = <int>[];
    final maxNewTokens = math.min(_maxNewTokens, inputIds.length * 2 + 10);
    var logProbSum = 0.0;
    var tokenCount = 0;

    for (var step = 0; step < maxNewTokens; step++) {
      final decoderInputs = {
        'input_ids': await _makeInt64Tensor(decoderIds, [
          1,
          decoderIds.length,
        ]),
        'encoder_hidden_states': encoderHiddenStates,
        'encoder_attention_mask': await _makeInt64Tensor(attentionMask, [
          1,
          inputIds.length,
        ]),
      };
      final decoderOutputs = await _decoderSession.run(decoderInputs);

      // asFlattenedList() gives one flat list of [batch, seq, vocab].
      final logits = (await decoderOutputs['logits']!.asFlattenedList())
          .cast<num>();
      final vocabSize = logits.length ~/ decoderIds.length;
      final offset = logits.length - vocabSize;
      final blocked = _blockedTokens(generated);

      // Pick the best token (skipping blocked repeats) and remember the
      // highest raw score, which is needed for the probability below.
      var bestId = -1;
      var bestLogit = double.negativeInfinity;
      var maxLogit = double.negativeInfinity;
      for (var i = 0; i < vocabSize; i++) {
        final value = logits[offset + i].toDouble();
        if (value > maxLogit) maxLogit = value;
        if (value > bestLogit && !blocked.contains(i)) {
          bestLogit = value;
          bestId = i;
        }
      }
      if (bestId < 0 || bestId == eosTokenId) break;

      var sumExp = 0.0;
      for (var i = 0; i < vocabSize; i++) {
        sumExp += math.exp(logits[offset + i].toDouble() - maxLogit);
      }
      logProbSum += (bestLogit - maxLogit) - math.log(sumExp);
      tokenCount++;

      generated.add(bestId);
      decoderIds.add(bestId);
    }

    final text = generated.isEmpty
        ? ''
        : _tokenizer.decode(generated, skipSpecialTokens: true).trim();
    return _SentenceResult(
      text: text,
      logProbSum: logProbSum,
      tokenCount: tokenCount,
    );
  }

  /// Blocks any word piece that would repeat a three-piece sequence already
  /// generated (stops loops like "malamig, malamig, malamig").
  Set<int> _blockedTokens(List<int> generated) {
    final blocked = <int>{};
    if (generated.length < 2) return blocked;
    final a = generated[generated.length - 2];
    final b = generated[generated.length - 1];
    for (var i = 0; i + 2 < generated.length; i++) {
      if (generated[i] == a && generated[i + 1] == b) {
        blocked.add(generated[i + 2]);
      }
    }
    return blocked;
  }
}

class _SentenceResult {
  const _SentenceResult({
    required this.text,
    required this.logProbSum,
    required this.tokenCount,
  });

  final String text;
  final double logProbSum;
  final int tokenCount;
}