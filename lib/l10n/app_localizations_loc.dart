// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Inonhan (`loc`).
class AppLocalizationsLoc extends AppLocalizations {
  AppLocalizationsLoc([String locale = 'loc']) : super(locale);

  @override
  String get getStarted => 'Get Started';

  @override
  String get landingMascotSemantics => 'ISLA mascot';

  @override
  String get landingLogoSemantics => 'ISLA logo';

  @override
  String get languageSelectionTitle => 'Pilia kung diin ang imong linggwahe';

  @override
  String get languageSelectionDescription =>
      'Pili linggwahe nga komportable ka.';

  @override
  String get languageSelectionChangeNote =>
      'Pwede mo palitan ang linggwahe aber kailan mo gusto';

  @override
  String get selectLanguage => 'Pilia';

  @override
  String get appSubtitle => 'Every island\'s voice, kept by choice.';

  @override
  String get appBarMascotSemantics => 'ISLA mascot';

  @override
  String get welcomeTitle => 'Welcome to ISLA';

  @override
  String get selectLanguagesBanner =>
      'Pilia kung diin ang imong linggwahe, tapos pinduta ang \"Sunod\" para ma-type ang imo mensahe';

  @override
  String get inputTextBanner => 'Type your message, then tap Translate.';

  @override
  String get inputVoiceBanner =>
      'Tap the microphone and speak, then tap Translate.';

  @override
  String get inputCameraBanner => 'Point the camera at text, then tap Capture.';

  @override
  String get stepChooseLanguages => 'Pili mga Linggwahe';

  @override
  String get stepInputTranslate => 'I-input kag I-translate';

  @override
  String get stepViewResult => 'I-tan-aw ang resulta';

  @override
  String stepSemanticsCompleted(Object n, Object total, Object label) {
    return 'Step $n of $total, $label, completed';
  }

  @override
  String stepSemanticsCurrent(Object n, Object total, Object label) {
    return 'Step $n of $total, $label, current';
  }

  @override
  String stepSemanticsUpcoming(Object n, Object total, Object label) {
    return 'Step $n of $total, $label';
  }

  @override
  String get selectLanguagesTitle => 'Pili mga Linggwahe';

  @override
  String get sourceLanguage => 'Ginghalinan na linggwahe';

  @override
  String get targetLanguage => 'Punterya nga linggwahe';

  @override
  String get sourceLanguageHeading => 'GINGHALINAN NA LINGGWAHE';

  @override
  String get targetLanguageHeading => 'PUNTERYA NGA LINGGWAHE';

  @override
  String get unsupportedDirection => 'This direction is not available.';

  @override
  String get next => 'Sunod';

  @override
  String get nextDisabled => 'Next, disabled';

  @override
  String get languageDialog => 'Pili linggwahe';

  @override
  String get alreadySelected => 'Napili na';

  @override
  String get notAvailable => 'Not available';

  @override
  String languageFieldSemantics(Object fieldName, Object value) {
    return '$fieldName, $value. Double tap to change.';
  }

  @override
  String translationDirection(Object source, Object target) {
    return '$source to $target';
  }

  @override
  String get swapLanguages => 'Palit ang ginghalinan kag punterya na linggwahe';

  @override
  String get backToLanguageSelection => 'Balik sa pagpili mga linggwahe';

  @override
  String get backToLanguagePairSelection =>
      'Balik sa pagpili mga pares na linggwahe';

  @override
  String get backToInputTranslation => 'Balik sa pag-input kag pag-translate';

  @override
  String get inputChange => 'Bag-o';

  @override
  String get inputTitle => 'Imo Mensahe';

  @override
  String get modeText => 'Text';

  @override
  String get modeVoice => 'Voice';

  @override
  String get modeCamera => 'Camera';

  @override
  String get inputLabelText => 'I-INPUT ANG MENSAHE';

  @override
  String get inputLabelTranscript => 'TRANSCRIPT';

  @override
  String get inputLabelRecognized => 'RECOGNIZED TEXT';

  @override
  String get inputHint => 'I-type ang imong mensahe udya';

  @override
  String inputCounter(Object count, Object max) {
    return '$count / $max';
  }

  @override
  String get inputTranslate => 'Translate';

  @override
  String get inputTranslating => 'Translating...';

  @override
  String get inputClear => 'Buraha kag magliwat';

  @override
  String get statusModelLoading => 'Model loading';

  @override
  String get commonError => 'Something went wrong. Try again.';

  @override
  String get voiceIdle => 'Tap to speak';

  @override
  String get voiceListening => 'Listening...';

  @override
  String get voiceProcessing => 'Processing...';

  @override
  String voiceUnavailable(Object language) {
    return 'Voice input is not available for $language.';
  }

  @override
  String get voicePermissionDenied => 'Microphone permission is required.';

  @override
  String get voicePermissionPermanentlyDenied =>
      'Microphone access is blocked. Enable it in app settings.';

  @override
  String get cameraCapture => 'Capture';

  @override
  String get cameraLiveHint => 'Point at text, then tap Capture.';

  @override
  String get cameraSelectHint =>
      'Tap the boxes to choose the text to translate.';

  @override
  String get cameraReading => 'Reading text...';

  @override
  String get cameraRetake => 'Retake';

  @override
  String get cameraSelectAll => 'Select all';

  @override
  String get cameraClearSelection => 'Clear selection';

  @override
  String get cameraGallery => 'Upload from gallery';

  @override
  String get cameraPermissionDenied => 'Camera permission is required.';

  @override
  String get cameraPermissionPermanentlyDenied =>
      'Camera access is blocked. Enable it in app settings.';

  @override
  String get permissionOpenSettings => 'Open Settings';

  @override
  String get cameraNoText =>
      'No text detected. Retake or choose another image.';

  @override
  String get cameraOcrUnavailable =>
      'Text recognition is available in the Android app only.';

  @override
  String get resultTitle => 'Resulta it Pag-translate';

  @override
  String get resultDescription => 'I-review ang imong pagtranslate sa idalum.';

  @override
  String get resultLabel => 'RESULTA IT PAG TRANSLATE';

  @override
  String get resultSpeak => 'Listen';

  @override
  String get resultSpeakApprox => 'Listen (approximate pronunciation)';

  @override
  String get resultSpeakUnavailable => 'No voice available for this language.';

  @override
  String originalTextLabel(Object language) {
    return 'ORIGINAL · $language';
  }

  @override
  String get noTranslationYet => 'No translation yet';

  @override
  String get backToInput => 'Balik sa Pag-input';

  @override
  String get translateAnother => 'I-translate ang Isa Pa';

  @override
  String get startOver => 'Liwat';

  @override
  String get resultNotFound => 'No translation found for this phrase.';

  @override
  String get resultSuggestionsLabel => 'Try one of these:';

  @override
  String get resultSourcePhrasebook => 'From phrasebook';

  @override
  String get resultSourceModel => 'From model';
}
