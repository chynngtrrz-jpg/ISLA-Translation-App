import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class L10nKeys {
  static const bannerBodyInput = 'banner.bodyInput';
  static const stepChooseLanguages = 'step.chooseLanguages';
  static const stepInputTranslate = 'step.inputTranslate';
  static const stepViewResult = 'step.viewResult';
  static const stepSemanticsCompleted = 'step.semanticsCompleted';
  static const stepSemanticsCurrent = 'step.semanticsCurrent';
  static const stepSemanticsUpcoming = 'step.semanticsUpcoming';
  static const inputChange = 'input.change';
  static const inputTitle = 'input.title';
  static const modeText = 'mode.text';
  static const modeVoice = 'mode.voice';
  static const modeCamera = 'mode.camera';
  static const inputLabelText = 'input.labelText';
  static const inputLabelTranscript = 'input.labelTranscript';
  static const inputLabelRecognized = 'input.labelRecognized';
  static const inputHint = 'input.hint';
  static const inputCounter = 'input.counter';
  static const inputTranslate = 'input.translate';
  static const inputTranslating = 'input.translating';
  static const inputClear = 'input.clear';
  static const statusModelLoading = 'status.modelLoading';
  static const commonError = 'common.error';
  static const resultLabel = 'result.label';
  static const resultConfidenceLine = 'result.confidenceLine';
  static const resultLevelHigh = 'result.levelHigh';
  static const resultLevelMedium = 'result.levelMedium';
  static const resultLevelLow = 'result.levelLow';
  static const resultLowNote = 'result.lowNote';
  static const resultSpeak = 'result.speak';
  static const resultSpeakApprox = 'result.speakApprox';
  static const resultSpeakUnavailable = 'result.speakUnavailable';
  static const voiceIdle = 'voice.idle';
  static const voiceListening = 'voice.listening';
  static const voiceProcessing = 'voice.processing';
  static const voiceUnavailable = 'voice.unavailable';
  static const voicePermissionDenied = 'voice.permissionDenied';
  static const cameraCapture = 'camera.capture';
  static const cameraGallery = 'camera.gallery';
  static const cameraPermissionDenied = 'camera.permissionDenied';
  static const cameraNoText = 'camera.noText';
  static const cameraOcrUnavailable = 'camera.ocrUnavailable';
  static const keyboardLabel = 'keyboard.label';
  static const keyboardShift = 'keyboard.shift';
  static const keyboardBackspace = 'keyboard.backspace';
  static const keyboardSpace = 'keyboard.space';
  static const keyboardEnter = 'keyboard.enter';
  static const keyboardSymbols = 'keyboard.symbols';
  static const keyboardLetters = 'keyboard.letters';
}

class IslaLocalizations {
  const IslaLocalizations(this._messages, this._fallbackMessages);

  final Map<String, dynamic> _messages;
  final Map<String, dynamic> _fallbackMessages;

  String t(String key, {Map<String, String>? args}) {
    final localized = _messages[key] as String?;
    var value = localized == null || localized.isEmpty
        ? (_fallbackMessages[key] as String? ?? key)
        : localized;
    args?.forEach((name, replacement) {
      value = value.replaceAll('{$name}', replacement);
    });
    return value;
  }

  static const LocalizationsDelegate<IslaLocalizations> delegate =
      _IslaLocalizationsDelegate();
}

class _IslaLocalizationsDelegate
    extends LocalizationsDelegate<IslaLocalizations> {
  const _IslaLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<IslaLocalizations> load(Locale locale) async {
    final file = locale.languageCode == 'fil' ? 'fil' : 'en';
    final englishJson = await rootBundle.loadString('assets/l10n/en.json');
    final selectedJson = file == 'en'
        ? englishJson
        : await rootBundle.loadString('assets/l10n/$file.json');
    return IslaLocalizations(
      (jsonDecode(selectedJson) as Map<String, dynamic>)
          .cast<String, dynamic>(),
      (jsonDecode(englishJson) as Map<String, dynamic>).cast<String, dynamic>(),
    );
  }

  @override
  bool shouldReload(_IslaLocalizationsDelegate old) => false;
}

extension IslaLocalizationContext on BuildContext {
  String t(String key, {Map<String, String>? args}) {
    final localization = Localizations.of<IslaLocalizations>(
      this,
      IslaLocalizations,
    );
    final value = localization?.t(key) ?? _fallbackMessages[key] ?? key;
    var formatted = value;
    args?.forEach((name, replacement) {
      formatted = formatted.replaceAll('{$name}', replacement);
    });
    return formatted;
  }
}

const _fallbackMessages = <String, String>{
  'banner.bodyInput': 'Choose how to enter your message, then tap Translate.',
  'step.chooseLanguages': 'Choose Languages',
  'step.inputTranslate': 'Input & Translate',
  'step.viewResult': 'View Result',
  'step.semanticsCompleted': 'Step {n} of {total}, {label}, completed',
  'step.semanticsCurrent': 'Step {n} of {total}, {label}, current',
  'step.semanticsUpcoming': 'Step {n} of {total}, {label}',
  'input.change': 'Change',
  'input.title': 'Your Message',
  'mode.text': 'Text',
  'mode.voice': 'Voice',
  'mode.camera': 'Camera',
  'input.labelText': 'ENTER TEXT',
  'input.labelTranscript': 'TRANSCRIPT',
  'input.labelRecognized': 'RECOGNIZED TEXT',
  'input.hint': 'Type your message here',
  'input.counter': '{count} / {max}',
  'input.translate': 'Translate',
  'input.translating': 'Translating...',
  'input.clear': 'Clear & Start Over',
  'status.modelLoading': 'Model loading',
  'common.error': 'Something went wrong. Try again.',
  'result.label': 'TRANSLATION RESULT',
  'result.confidenceLine': 'Translation confidence: {level}',
  'result.levelHigh': 'High',
  'result.levelMedium': 'Medium',
  'result.levelLow': 'Low',
  'result.lowNote': 'Verify with a local speaker.',
  'result.speak': 'Listen',
  'result.speakApprox': 'Listen (approximate pronunciation)',
  'result.speakUnavailable': 'No voice available for this language.',
  'voice.idle': 'Tap to speak',
  'voice.listening': 'Listening...',
  'voice.processing': 'Processing...',
  'voice.unavailable': 'Voice input is not available for {language}.',
  'voice.permissionDenied': 'Microphone permission is required.',
  'camera.capture': 'Capture',
  'camera.gallery': 'Upload from gallery',
  'camera.permissionDenied': 'Camera permission is required.',
  'camera.noText': 'No text detected. Try again.',
  'camera.ocrUnavailable':
      'Text recognition is available in the Android app only.',
  'keyboard.label': 'ON-SCREEN KEYBOARD',
  'keyboard.shift': 'Shift',
  'keyboard.backspace': 'Backspace',
  'keyboard.space': 'SPACE',
  'keyboard.enter': 'Enter',
  'keyboard.symbols': 'Numbers and symbols',
  'keyboard.letters': 'Letters',
};
