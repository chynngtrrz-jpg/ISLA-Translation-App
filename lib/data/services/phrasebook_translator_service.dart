import '../../core/constants/app_config.dart';
import '../../core/utils/phrase_normalizer.dart';
import '../phrasebook/phrasebook.dart';
import '../models/language.dart';
import '../models/translation_result.dart';
import 'translator_service.dart';

/// Thrown when no phrasebook tier matched and no model fallback is allowed.
class PhraseNotFoundException implements Exception {
  const PhraseNotFoundException(this.suggestions);

  /// Source-language phrases the user could try instead.
  final List<String> suggestions;

  @override
  String toString() => 'PhraseNotFoundException(suggestions: $suggestions)';
}

/// Translates from the bundled phrasebook, optionally falling back to another
/// [TranslatorService]. Every row holds all languages, so any pair works
/// directly with no pivot language.
class PhrasebookTranslatorService implements TranslatorService {
  PhrasebookTranslatorService({
    required Phrasebook phrasebook,
    TranslatorService? fallback,
    bool enabled = kPhraseBookEnabled,
    bool fallbackToModel = kPhraseFallbackToModel,
    double fuzzyThreshold = kFuzzyThreshold,
    int fuzzyMinLength = kFuzzyMinLength,
    int maxSuggestions = kMaxSuggestions,
  })  : _phrasebook = phrasebook,
        _fallback = fallback,
        _enabled = enabled,
        _fallbackToModel = fallbackToModel,
        _fuzzyThreshold = fuzzyThreshold,
        _fuzzyMinLength = fuzzyMinLength,
        _maxSuggestions = maxSuggestions;

  final Phrasebook _phrasebook;
  final TranslatorService? _fallback;
  final bool _enabled;
  final bool _fallbackToModel;
  final double _fuzzyThreshold;
  final int _fuzzyMinLength;
  final int _maxSuggestions;

  @override
  bool get isReady =>
      (!_enabled || _phrasebook.isReady) && (_fallback?.isReady ?? true);

  @override
  Future<TranslationResult> translate({
    required String text,
    required Language source,
    required Language target,
  }) async {
    final stopwatch = Stopwatch()..start();
    final fallback = _fallback;

    if (!_enabled) {
      if (fallback == null) throw const PhraseNotFoundException([]);
      return fallback.translate(text: text, source: source, target: target);
    }

    final normalized = normalize(text);

    // Tiers 1 and 2: whole text, exact then fuzzy.
    final whole = _matchPhrase(normalized, source.id, target.id);
    if (whole != null) {
      return _fromPhrasebook(whole.$1, whole.$2, stopwatch);
    }

    // Tier 3: every sentence must match, otherwise nothing is mixed.
    final segments = splitSentences(text)
        .map(normalize)
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.length >= 2) {
      final matches = <(String, double)>[];
      for (final segment in segments) {
        final match = _matchPhrase(segment, source.id, target.id);
        if (match == null) break;
        matches.add(match);
      }
      if (matches.length == segments.length) {
        final lowest = matches.map((m) => m.$2).reduce((a, b) => a < b ? a : b);
        return _fromPhrasebook(
          matches.map((m) => m.$1).join(' '),
          lowest,
          stopwatch,
        );
      }
    }

    // Tier 4: model fallback, only when allowed.
    if (_fallbackToModel && fallback != null) {
      return fallback.translate(text: text, source: source, target: target);
    }

    // Tier 5: nothing matched.
    throw PhraseNotFoundException(
      _phrasebook.topSuggestions(
        source.id,
        normalized,
        _maxSuggestions,
        targetId: target.id,
      ),
    );
  }

  /// Exact match first, then a fuzzy match above the threshold for inputs of
  /// at least the minimum length. Returns the target text and its confidence.
  (String, double)? _matchPhrase(
    String normalized,
    String sourceId,
    String targetId,
  ) {
    if (normalized.isEmpty) return null;
    final exact = _phrasebook.lookupExact(
      sourceId,
      normalized,
      targetId: targetId,
    );
    if (exact != null) {
      return (_phrasebook.entries[exact].textFor(targetId)!, 1.0);
    }
    if (normalized.length < _fuzzyMinLength) return null;
    final fuzzy = _phrasebook.bestFuzzy(
      sourceId,
      normalized,
      targetId: targetId,
    );
    if (fuzzy == null || fuzzy.$2 < _fuzzyThreshold) return null;
    return (_phrasebook.entries[fuzzy.$1].textFor(targetId)!, fuzzy.$2);
  }

  TranslationResult _fromPhrasebook(
    String text,
    double confidence,
    Stopwatch stopwatch,
  ) =>
      TranslationResult(
        text: text,
        confidence: confidence,
        latencyMs: stopwatch.elapsedMilliseconds,
        origin: TranslationOrigin.phrasebook,
      );
}
