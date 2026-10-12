// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romblomanon (`rol`).
class AppLocalizationsRol extends AppLocalizations {
  AppLocalizationsRol([String locale = 'rol']) : super(locale);

  @override
  String get getStarted => 'Get Started';

  @override
  String get landingMascotSemantics => 'ISLA mascot';

  @override
  String get landingLogoSemantics => 'ISLA logo';

  @override
  String get languageSelectionTitle => 'Pumili ng linggwahe';

  @override
  String get languageSelectionDescription =>
      'Pumili linggwahe kung diin ka sanay.';

  @override
  String get languageSelectionChangeNote =>
      'Pwede mo palitan ang linggwahe kung san\'o mo gusto.';

  @override
  String get selectLanguage => 'Pilia';

  @override
  String get appSubtitle => 'Every island\'s voice, kept by choice.';

  @override
  String get appBarMascotSemantics => 'ISLA mascot';

  @override
  String get welcomeTitle => 'Welcome to ISLA!';

  @override
  String get selectLanguagesBanner =>
      'Pagpili mga linggwahe, tapos pinduta ang \"Masunod\" para ma-type and imo mensahe.';

  @override
  String get inputTextBanner =>
      'I-type ang imo mensahe, tapos pinduta ang \"Isaylo\".';

  @override
  String get inputVoiceBanner =>
      'Pinduta ang mikropono kag maghambay, tapos pinduta ang \"Isaylo\".';

  @override
  String get inputCameraBanner =>
      'I-tutok and camera, tapos pinduta ang \"Picture\".';

  @override
  String get stepChooseLanguages => 'Pagpili mga Linggwahe';

  @override
  String get stepInputTranslate => 'Butanga kag Isaylo';

  @override
  String get stepViewResult => 'Tan-awa ang Resulta';

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
  String get selectLanguagesTitle => 'Pagpili mga Linggwahe';

  @override
  String get sourceLanguage => 'Ginghalinan nga Linggwahe';

  @override
  String get targetLanguage => 'Punterya nga Linggwahe';

  @override
  String get sourceLanguageHeading => 'Ginghalinan nga Linggwahe';

  @override
  String get targetLanguageHeading => 'Punterya nga Linggwahe';

  @override
  String get unsupportedDirection => 'This direction is not available.';

  @override
  String get next => 'Masunod';

  @override
  String get nextDisabled => 'Next, disabled';

  @override
  String get languageDialog => 'Pagpili Linggwahe';

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
  String get swapLanguages =>
      'Ipagpalit ang ginghalinan kag punterya nga linggwahe';

  @override
  String get backToLanguageSelection => 'Balik sa pagpili mga linggwahe';

  @override
  String get backToLanguagePairSelection => 'Balik sa pagpili ng mga linggwahe';

  @override
  String get backToInputTranslation => 'Balik sa pagbutang kag pagsaylo';

  @override
  String get inputChange => 'Bayluhi';

  @override
  String get inputTitle => 'Imo Mensahe';

  @override
  String get modeText => 'Text';

  @override
  String get modeVoice => 'Voice';

  @override
  String get modeCamera => 'Camera';

  @override
  String get inputLabelText => 'PAGBUTANG MENSAHE';

  @override
  String get inputLabelTranscript => 'TRANSCRIPT';

  @override
  String get inputLabelRecognized => 'RECOGNIZED TEXT';

  @override
  String get inputHint => 'Diri butanga ang imo mensahe.';

  @override
  String inputCounter(Object count, Object max) {
    return '$count / $max';
  }

  @override
  String get inputTranslate => 'Isaylo';

  @override
  String get inputTranslating => 'Nagsasalin...';

  @override
  String get inputClear => 'Payaa kag Magliwat';

  @override
  String get statusModelLoading => 'Model loading';

  @override
  String get commonError => 'Something went wrong. Try again.';

  @override
  String get voiceIdle => 'Pinduta kag maghambay';

  @override
  String get voiceListening => 'Gapamati...';

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
  String get cameraLiveHint => 'Itutok sa mensahe kag pinduta ang \"Picture\".';

  @override
  String get cameraSelectHint =>
      'Pinduta ang mga kahon para mapili ang mensahe nga imo isaylo.';

  @override
  String get cameraReading => 'Ginabasa ang mensahe...';

  @override
  String get cameraRetake => 'Liwat';

  @override
  String get cameraSelectAll => 'Pilia tanan';

  @override
  String get cameraClearSelection => 'Payaa tanan';

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
  String get resultTitle => 'Resulta ng Pagsaylo';

  @override
  String get resultDescription => 'Basaha ang resulta sa idayom.';

  @override
  String get resultLabel => 'Resulta ng Pagsaylo';

  @override
  String get resultSpeak => 'Pamati';

  @override
  String get resultSpeakApprox => 'Pamati';

  @override
  String get resultSpeakUnavailable => 'No voice available for this language.';

  @override
  String originalTextLabel(Object language) {
    return 'ORIGINAL · $language';
  }

  @override
  String get noTranslationYet => 'No translation yet';

  @override
  String get backToInput => 'Balik sa Pagbutang';

  @override
  String get translateAnother => 'Pagsaylo liwat';

  @override
  String get startOver => 'Magtuna Liwat';

  @override
  String get resultNotFound => 'No translation found for this phrase.';

  @override
  String get resultSuggestionsLabel => 'Try one of these:';

  @override
  String get resultSourcePhrasebook => 'From phrasebook';

  @override
  String get resultSourceModel => 'From model';
}
