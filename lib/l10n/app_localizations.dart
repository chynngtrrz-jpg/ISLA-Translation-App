import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bno.dart';
import 'app_localizations_en.dart';
import 'app_localizations_rol.dart';
import 'app_localizations_tl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bno'),
    Locale('en'),
    Locale('rol'),
    Locale('tl')
  ];

  /// Screen: Landing
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Screen: Language Selection
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageSelectionTitle;

  /// Screen: Language Selection
  ///
  /// In en, this message translates to:
  /// **'Choose the language you are most comfortable with.'**
  String get languageSelectionDescription;

  /// Screen: Language Selection
  ///
  /// In en, this message translates to:
  /// **'You can change the language at any time during your session.'**
  String get languageSelectionChangeNote;

  /// Screen: Language Selection
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectLanguage;

  /// Shared: App Bar
  ///
  /// In en, this message translates to:
  /// **'Language Translation'**
  String get appSubtitle;

  /// Shared: Welcome Banner
  ///
  /// In en, this message translates to:
  /// **'Welcome to ISLA'**
  String get welcomeTitle;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'Select your languages, then tap \"Next\" to type your message.'**
  String get selectLanguagesBanner;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Type your message, then tap Translate.'**
  String get inputTextBanner;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone and speak, then tap Translate.'**
  String get inputVoiceBanner;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Point the camera at text, then tap Capture.'**
  String get inputCameraBanner;

  /// Screens: Select Languages, Input and Translate, and Result (Stepper)
  ///
  /// In en, this message translates to:
  /// **'Choose Languages'**
  String get stepChooseLanguages;

  /// Screens: Select Languages, Input and Translate, and Result (Stepper)
  ///
  /// In en, this message translates to:
  /// **'Input & Translate'**
  String get stepInputTranslate;

  /// Screens: Select Languages, Input and Translate, and Result (Stepper)
  ///
  /// In en, this message translates to:
  /// **'View Result'**
  String get stepViewResult;

  /// Screens: Select Languages, Input and Translate, and Result (Stepper)
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}, {label}, completed'**
  String stepSemanticsCompleted(Object n, Object total, Object label);

  /// Screens: Select Languages, Input and Translate, and Result (Stepper)
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}, {label}, current'**
  String stepSemanticsCurrent(Object n, Object total, Object label);

  /// Screens: Select Languages, Input and Translate, and Result (Stepper)
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}, {label}'**
  String stepSemanticsUpcoming(Object n, Object total, Object label);

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'Select Languages'**
  String get selectLanguagesTitle;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'Source language'**
  String get sourceLanguage;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'Target language'**
  String get targetLanguage;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'SOURCE LANGUAGE'**
  String get sourceLanguageHeading;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'TARGET LANGUAGE'**
  String get targetLanguageHeading;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'This direction is not available.'**
  String get unsupportedDirection;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'Next, disabled'**
  String get nextDisabled;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'Language selection'**
  String get languageDialog;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'Already selected'**
  String get alreadySelected;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'{fieldName}, {value}. Double tap to change.'**
  String languageFieldSemantics(Object fieldName, Object value);

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'{source} to {target}'**
  String translationDirection(Object source, Object target);

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'Swap source and target languages'**
  String get swapLanguages;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'Back to language selection'**
  String get backToLanguageSelection;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'Back to language pair selection'**
  String get backToLanguagePairSelection;

  /// Screen: Result
  ///
  /// In en, this message translates to:
  /// **'Back to input and translation'**
  String get backToInputTranslation;

  /// Screen: Select Languages
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get inputChange;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Your Message'**
  String get inputTitle;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get modeText;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get modeVoice;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get modeCamera;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'ENTER TEXT'**
  String get inputLabelText;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'TRANSCRIPT'**
  String get inputLabelTranscript;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'RECOGNIZED TEXT'**
  String get inputLabelRecognized;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Type your message here'**
  String get inputHint;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'{count} / {max}'**
  String inputCounter(Object count, Object max);

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get inputTranslate;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Translating...'**
  String get inputTranslating;

  /// Screens: Select Languages and Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Clear & Start Over'**
  String get inputClear;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Model loading'**
  String get statusModelLoading;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get commonError;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Tap to speak'**
  String get voiceIdle;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get voiceListening;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get voiceProcessing;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Voice input is not available for {language}.'**
  String voiceUnavailable(Object language);

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required.'**
  String get voicePermissionDenied;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Microphone access is blocked. Enable it in app settings.'**
  String get voicePermissionPermanentlyDenied;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get cameraCapture;

  /// Screen: Input and Translate (Camera)
  ///
  /// In en, this message translates to:
  /// **'Point at text, then tap Capture.'**
  String get cameraLiveHint;

  /// Screen: Input and Translate (Camera)
  ///
  /// In en, this message translates to:
  /// **'Tap the boxes to choose the text to translate.'**
  String get cameraSelectHint;

  /// Screen: Input and Translate (Camera)
  ///
  /// In en, this message translates to:
  /// **'Reading text...'**
  String get cameraReading;

  /// Screen: Input and Translate (Camera)
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get cameraRetake;

  /// Screen: Input and Translate (Camera)
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get cameraSelectAll;

  /// Screen: Input and Translate (Camera)
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get cameraClearSelection;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Upload from gallery'**
  String get cameraGallery;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required.'**
  String get cameraPermissionDenied;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Camera access is blocked. Enable it in app settings.'**
  String get cameraPermissionPermanentlyDenied;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get permissionOpenSettings;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'No text detected. Retake or choose another image.'**
  String get cameraNoText;

  /// Screen: Input and Translate
  ///
  /// In en, this message translates to:
  /// **'Text recognition is available in the Android app only.'**
  String get cameraOcrUnavailable;

  /// Screen: Result
  ///
  /// In en, this message translates to:
  /// **'Translation Result'**
  String get resultTitle;

  /// Screen: Result
  ///
  /// In en, this message translates to:
  /// **'Review your translation below.'**
  String get resultDescription;

  /// Screen: Result
  ///
  /// In en, this message translates to:
  /// **'TRANSLATION RESULT'**
  String get resultLabel;

  /// Screen: Result
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get resultSpeak;

  /// Screen: Result
  ///
  /// In en, this message translates to:
  /// **'Listen (approximate pronunciation)'**
  String get resultSpeakApprox;

  /// Screen: Result
  ///
  /// In en, this message translates to:
  /// **'No voice available for this language.'**
  String get resultSpeakUnavailable;

  /// Screen: Result
  ///
  /// In en, this message translates to:
  /// **'ORIGINAL · {language}'**
  String originalTextLabel(Object language);

  /// Screen: Result
  ///
  /// In en, this message translates to:
  /// **'No translation yet'**
  String get noTranslationYet;

  /// Screen: Result
  ///
  /// In en, this message translates to:
  /// **'Back to Input'**
  String get backToInput;

  /// Screen: Result
  ///
  /// In en, this message translates to:
  /// **'Translate Another'**
  String get translateAnother;

  /// Screen: Result
  ///
  /// In en, this message translates to:
  /// **'Start Over'**
  String get startOver;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bno', 'en', 'rol', 'tl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bno':
      return AppLocalizationsBno();
    case 'en':
      return AppLocalizationsEn();
    case 'rol':
      return AppLocalizationsRol();
    case 'tl':
      return AppLocalizationsTl();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
