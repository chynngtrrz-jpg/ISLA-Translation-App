// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tagalog (`tl`).
class AppLocalizationsTl extends AppLocalizations {
  AppLocalizationsTl([String locale = 'tl']) : super(locale);

  @override
  String get getStarted => 'Magsimula';

  @override
  String get landingMascotSemantics => 'ISLA mascot';

  @override
  String get landingLogoSemantics => 'ISLA logo';

  @override
  String get languageSelectionTitle => 'Piliin ang inyong wika';

  @override
  String get languageSelectionDescription =>
      'Piliin ang wikang pinakakomportable kayong gamitin.';

  @override
  String get languageSelectionChangeNote =>
      'Maaari ninyong palitan ang wika anumang oras habang ginagamit ang app.';

  @override
  String get selectLanguage => 'Piliin';

  @override
  String get appSubtitle => 'Every island\'s voice, kept by choice.';

  @override
  String get appBarMascotSemantics => 'ISLA mascot';

  @override
  String get welcomeTitle => 'Welcome to ISLA';

  @override
  String get selectLanguagesBanner =>
      'Piliin ang mga wika, pagkatapos ay pindutin ang \"Susunod\" upang ilagay ang inyong mensahe.';

  @override
  String get inputTextBanner =>
      'Isulat ang iyong mensahe, pagkatapos ay pindutin ang Isalin.';

  @override
  String get inputVoiceBanner =>
      'Pindutin ang mikropono at magsalita, pagkatapos ay pindutin ang Isalin.';

  @override
  String get inputCameraBanner =>
      'Itutok ang kamera sa teksto, pagkatapos ay pindutin ang Kunan ng larawan.';

  @override
  String get stepChooseLanguages => 'Pumili ng mga Wika';

  @override
  String get stepInputTranslate => 'Ilagay at Isalin';

  @override
  String get stepViewResult => 'Tingnan ang Salin';

  @override
  String stepSemanticsCompleted(Object n, Object total, Object label) {
    return 'Hakbang $n sa $total, $label, kumpleto na';
  }

  @override
  String stepSemanticsCurrent(Object n, Object total, Object label) {
    return 'Hakbang $n sa $total, $label, kasalukuyan';
  }

  @override
  String stepSemanticsUpcoming(Object n, Object total, Object label) {
    return 'Hakbang $n sa $total, $label';
  }

  @override
  String get selectLanguagesTitle => 'Pumili ng mga Wika';

  @override
  String get sourceLanguage => 'Pinagmumulang wika';

  @override
  String get targetLanguage => 'Wikang pagsasalinan';

  @override
  String get sourceLanguageHeading => 'PINAGMUMULANG WIKA';

  @override
  String get targetLanguageHeading => 'WIKANG PAGSASALINAN';

  @override
  String get unsupportedDirection => 'Hindi available ang direksiyong ito.';

  @override
  String get next => 'Susunod';

  @override
  String get nextDisabled => 'Susunod, hindi pa magagamit';

  @override
  String get languageDialog => 'Pagpili ng wika';

  @override
  String get alreadySelected => 'Napili na';

  @override
  String get notAvailable => 'Hindi available';

  @override
  String languageFieldSemantics(Object fieldName, Object value) {
    return '$fieldName, $value. Mag-double tap para palitan.';
  }

  @override
  String translationDirection(Object source, Object target) {
    return '$source patungong $target';
  }

  @override
  String get swapLanguages =>
      'Pagpalitin ang mga pinagmulan at pagsasalinang wika';

  @override
  String get backToLanguageSelection => 'Bumalik sa pagpili ng wika';

  @override
  String get backToLanguagePairSelection =>
      'Bumalik sa pagpili ng pares ng wika';

  @override
  String get backToInputTranslation => 'Bumalik sa paglalagay at pagsasalin';

  @override
  String get inputChange => 'Palitan';

  @override
  String get inputTitle => 'Inyong Mensahe';

  @override
  String get modeText => 'Teksto';

  @override
  String get modeVoice => 'Boses';

  @override
  String get modeCamera => 'Kamera';

  @override
  String get inputLabelText => 'ILAGAY ANG TEKSTO';

  @override
  String get inputLabelTranscript => 'TRANSKRIPSIYON';

  @override
  String get inputLabelRecognized => 'KINILALANG TEKSTO';

  @override
  String get inputHint => 'I-type rito ang inyong mensahe';

  @override
  String inputCounter(Object count, Object max) {
    return '$count / $max';
  }

  @override
  String get inputTranslate => 'Isalin';

  @override
  String get inputTranslating => 'Isinasalin...';

  @override
  String get inputClear => 'Burahin at Magsimulang Muli';

  @override
  String get statusModelLoading => 'Inihahanda ang modelo';

  @override
  String get commonError => 'Nagkaproblema. Subukan muli.';

  @override
  String get voiceIdle => 'Pindutin para magsalita';

  @override
  String get voiceListening => 'Nakikinig...';

  @override
  String get voiceProcessing => 'Pinoproseso...';

  @override
  String voiceUnavailable(Object language) {
    return 'Hindi magagamit ang pag-input gamit ang boses para sa $language.';
  }

  @override
  String get voicePermissionDenied => 'Kailangan ang pahintulot sa mikropono.';

  @override
  String get voicePermissionPermanentlyDenied =>
      'Naka-block ang mikropono. Paganahin ito sa mga setting ng app.';

  @override
  String get cameraCapture => 'Kunan ng larawan';

  @override
  String get cameraLiveHint =>
      'Itutok sa teksto, pagkatapos ay pindutin ang Kunan.';

  @override
  String get cameraSelectHint =>
      'Pindutin ang mga kahon para piliin ang tekstong isasalin.';

  @override
  String get cameraReading => 'Binabasa ang teksto...';

  @override
  String get cameraRetake => 'Kumuha Muli';

  @override
  String get cameraSelectAll => 'Piliin Lahat';

  @override
  String get cameraClearSelection => 'Alisin ang Pinili';

  @override
  String get cameraGallery => 'Mag-upload mula sa gallery';

  @override
  String get cameraPermissionDenied => 'Kailangan ang pahintulot sa kamera.';

  @override
  String get cameraPermissionPermanentlyDenied =>
      'Naka-block ang kamera. Paganahin ito sa mga setting ng app.';

  @override
  String get permissionOpenSettings => 'Buksan ang Mga Setting';

  @override
  String get cameraNoText =>
      'Walang natukoy na teksto. Kumuha muli o pumili ng ibang larawan.';

  @override
  String get cameraOcrUnavailable =>
      'Sa Android app lamang magagamit ang pagkilala ng teksto.';

  @override
  String get resultTitle => 'Resulta ng Salin';

  @override
  String get resultDescription => 'Suriin sa ibaba ang inyong salin.';

  @override
  String get resultLabel => 'RESULTA NG SALIN';

  @override
  String get resultSpeak => 'Pakinggan';

  @override
  String get resultSpeakApprox => 'Pakinggan (tinatayang pagbigkas)';

  @override
  String get resultSpeakUnavailable =>
      'Walang magagamit na boses para sa wikang ito.';

  @override
  String originalTextLabel(Object language) {
    return 'ORIHINAL · $language';
  }

  @override
  String get noTranslationYet => 'Wala pang salin';

  @override
  String get backToInput => 'Bumalik sa Paglalagay';

  @override
  String get translateAnother => 'Magsalin Pa';

  @override
  String get startOver => 'Magsimula Muli';

  @override
  String get resultNotFound =>
      'Walang nahanap na salin para sa pariralang ito.';

  @override
  String get resultSuggestionsLabel => 'Subukan ang isa sa mga ito:';

  @override
  String get resultSourcePhrasebook => 'Mula sa phrasebook';

  @override
  String get resultSourceModel => 'Mula sa model';
}
