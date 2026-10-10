import 'package:flutter/foundation.dart';

import '../core/constants/app_config.dart';
import '../core/constants/languages.dart';
import '../data/models/translation_result.dart';
import '../data/services/mock_translator_service.dart';
import '../data/services/translator_service.dart';

/// Holds the language pair and transient translation input for one session.
class SessionProvider extends ChangeNotifier {
  SessionProvider({
    bool Function(String, String)? pairSupport,
    TranslatorService? translator,
  })  : _pairSupport = pairSupport ?? isPairSupported,
        _translator = translator ?? const MockTranslatorService();

  final bool Function(String, String) _pairSupport;
  final TranslatorService _translator;

  String sourceId = 'en';
  String targetId = 'ini';
  String inputMode = 'text';
  String inputText = '';
  String resultText = '';
  TranslationResult? result;
  bool isTranslating = false;
  String? errorKey;
  bool modelLoadFailed = false;
  bool get isModelReady => _translator.isReady;
  bool get isValid => supportsPair(sourceId, targetId);

  bool supportsPair(String source, String target) =>
      source != target && _pairSupport(source, target);

  /// Called when the translator finishes loading (or fails to load), so the
  /// UI can drop its "model loading" message.
  void refreshModelState({bool failed = false}) {
    modelLoadFailed = failed;
    notifyListeners();
  }

  void initTranslationFlow() {
    sourceId = 'en';
    targetId = 'ini';
    inputText = '';
    _clearResult();
    inputMode = 'text';
    errorKey = null;
  }

  void setSource(String languageId) {
    if (languageId == targetId) return;
    sourceId = languageId;
    _clearResult();
    errorKey = null;
    notifyListeners();
  }

  void setTarget(String languageId) {
    if (languageId == sourceId) return;
    targetId = languageId;
    _clearResult();
    errorKey = null;
    notifyListeners();
  }

  bool swap() {
    if (!supportsPair(targetId, sourceId)) return false;
    final oldSource = sourceId;
    sourceId = targetId;
    targetId = oldSource;
    _clearResult();
    errorKey = null;
    notifyListeners();
    return true;
  }

  void setInputText(String value) {
    if (inputText == value && result == null) return;
    inputText = value;
    errorKey = null;
    _clearResult();
    notifyListeners();
  }

  void setResultText(String value) {
    resultText = value;
    notifyListeners();
  }

  void setInputMode(String value) {
    if (value != 'text' && value != 'voice' && value != 'camera') return;
    if (inputMode == value) return;
    inputMode = value;
    notifyListeners();
  }

  Future<void> translate() async {
    if (inputText.trim().isEmpty ||
        !_translator.isReady ||
        isTranslating) {
      return;
    }

    isTranslating = true;
    errorKey = null;
    notifyListeners();
    try {
      final source = languages.firstWhere((language) => language.id == sourceId);
      final target = languages.firstWhere((language) => language.id == targetId);
      result = await _translator.translate(
        text: inputText.trim(),
        source: source,
        target: target,
      );
      resultText = result!.text;
    } catch (error, stackTrace) {
      debugPrint('Translation failed: $error\n$stackTrace');
      errorKey = 'common.error';
      _clearResult();
    } finally {
      isTranslating = false;
      notifyListeners();
    }
  }

  void clearInputAndResult() {
    inputText = '';
    inputMode = 'text';
    errorKey = null;
    _clearResult();
    notifyListeners();
  }

  void _clearResult() {
    result = null;
    resultText = '';
  }

  void reset() {
    initTranslationFlow();
    inputMode = 'text';
    isTranslating = false;
    errorKey = null;
    notifyListeners();
  }
}