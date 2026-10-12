import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:isla_app/app.dart';
import 'package:isla_app/data/models/language.dart';
import 'package:isla_app/data/models/translation_result.dart';
import 'package:isla_app/data/services/camera_service.dart';
import 'package:isla_app/data/services/ocr_service.dart';
import 'package:isla_app/data/services/runtime_permission_service.dart';
import 'package:isla_app/data/services/speech_service.dart';
import 'package:isla_app/data/services/translator_service.dart';
import 'package:isla_app/data/services/tts_service.dart';
import 'package:isla_app/l10n/app_localizations.dart';
import 'package:isla_app/l10n/fallback_localizations.dart';
import 'package:isla_app/providers/locale_provider.dart';
import 'package:isla_app/providers/session_provider.dart';
import 'package:isla_app/ui/screens/input_translate_screen.dart';
import 'package:isla_app/ui/screens/language_selection_screen.dart';
import 'package:isla_app/ui/screens/select_languages_screen.dart';
import 'package:isla_app/ui/screens/view_result_screen.dart';

import '../tool/import_onhan.dart';
import '../tool/onhan_common.dart';

const _onhan = Locale('loc');

class _Translator implements TranslatorService {
  @override
  bool isReady = true;

  @override
  Future<TranslationResult> translate({
    required String text,
    required Language source,
    required Language target,
  }) async =>
      const TranslationResult(
          text: 'Maayong aga.', confidence: 0.86, latencyMs: 1);
}

class _Speech implements SpeechService {
  @override
  Future<bool> initialize({
    void Function(String error)? onError,
    void Function(String status)? onStatus,
  }) async =>
      true;

  @override
  Future<void> listen({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String error) onError,
  }) async {}

  @override
  Future<void> stop() async {}
}

class _Permissions implements RuntimePermissionService {
  @override
  Future<RuntimePermissionState> requestCamera() async =>
      RuntimePermissionState.granted;

  @override
  Future<RuntimePermissionState> requestMicrophone() async =>
      RuntimePermissionState.granted;

  @override
  Future<bool> openAppSettings() async => true;
}

class _Tts implements TtsService {
  @override
  Future<bool> isLanguageAvailable(String locale) async => true;

  @override
  Future<void> speak(String text, String locale) async {}

  @override
  Future<void> stop() async {}
}

class _Ocr implements OcrService {
  @override
  Future<void> close() async {}

  @override
  Future<CameraOcrResult> recognizeImage(
    String path, {
    required ValueChanged<NormalizedCameraImage> onImageNormalized,
  }) async =>
      const CameraOcrResult(lines: []);
}

class _Camera implements CameraService {
  @override
  Future<CameraController?> initialize() async => null;

  @override
  Future<String?> capture(CameraController controller) async => null;

  @override
  Future<String?> chooseFromGallery() async => null;
}

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  EnglishFallbackMaterialLocalizationsDelegate(),
  EnglishFallbackWidgetsLocalizationsDelegate(),
  EnglishFallbackCupertinoLocalizationsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Future<LocaleProvider> _provider([String? saved]) async {
  SharedPreferences.setMockInitialValues(
      {if (saved != null) 'ui_locale': saved});
  final provider = LocaleProvider(
    preferences: await SharedPreferences.getInstance(),
  );
  await provider.loadSavedLocale();
  return provider;
}

Widget _app(
  LocaleProvider locale,
  SessionProvider session,
  Widget home, {
  Map<String, WidgetBuilder> routes = const {},
}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: locale),
        ChangeNotifierProvider<SessionProvider>.value(value: session),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, l, _) => MaterialApp(
          locale: l.locale,
          localizationsDelegates: _delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: routes,
          home: home,
        ),
      ),
    );

String _localeName(WidgetTester tester, Type screen) =>
    AppLocalizations.of(tester.element(find.byType(screen)))!.localeName;

Future<void> _setPhone(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 640);
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

void main() {
  group('locale selection', () {
    testWidgets('Onhan card sets, persists, and restores the locale',
        (tester) async {
      final provider = await _provider();
      await tester.pumpWidget(
        _app(provider, SessionProvider(), const LanguageSelectionScreen(),
            routes: {
              '/select-languages': (_) => const SelectLanguagesScreen()
            }),
      );
      await tester.ensureVisible(find.text('Onhan'));
      await tester.tap(find.text('Onhan'));
      await tester.pumpAndSettle();

      expect(provider.locale, _onhan);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(LocaleProvider.preferenceKey), 'loc');
      expect(_localeName(tester, SelectLanguagesScreen), 'loc');

      final restored = LocaleProvider(preferences: prefs);
      await restored.loadSavedLocale();
      expect(restored.locale, _onhan);
    });

    testWidgets('Asi to Onhan to English switches without restart',
        (tester) async {
      final provider = await _provider('bno');
      await tester.pumpWidget(
        _app(provider, SessionProvider(), const LanguageSelectionScreen(),
            routes: {
              '/select-languages': (_) => const SelectLanguagesScreen()
            }),
      );
      expect(_localeName(tester, LanguageSelectionScreen), 'bno');

      Future<void> choose(String card, String code) async {
        await tester.ensureVisible(find.text(card));
        await tester.tap(find.text(card));
        await tester.pumpAndSettle();
        expect(provider.locale.languageCode, code);
        expect(_localeName(tester, SelectLanguagesScreen), code);
        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pumpAndSettle();
        expect(_localeName(tester, LanguageSelectionScreen), code);
      }

      await choose('Onhan', 'loc');
      await choose('English', 'en');
    });

    testWidgets('app starts in the restored Onhan locale', (tester) async {
      final provider = await _provider('loc');
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>.value(value: provider),
            ChangeNotifierProvider<SessionProvider>(
              create: (_) => SessionProvider(),
            ),
          ],
          child: const IslaApp(),
        ),
      );
      await tester.pump();
      expect(
        AppLocalizations.of(tester.element(find.byType(Scaffold).first))!
            .localeName,
        'loc',
      );
    });
  });

  group('ARB structure', () {
    final en = readArb(templateArbPath);
    final loc = readArb(onhanArbPath);

    test('every English key exists in Onhan with the same ICU arguments', () {
      expect(loc['@@locale'], 'loc');
      expect(messageKeys(loc), messageKeys(en));
      for (final key in messageKeys(en)) {
        expect(
          icuArguments(loc[key] as String),
          icuArguments(en[key] as String),
          reason: key,
        );
      }
    });

    test('values are never empty or a raw key', () {
      for (final key in messageKeys(loc)) {
        final value = loc[key] as String;
        expect(value.trim(), isNotEmpty, reason: key);
        expect(value, isNot(key));
      }
    });

    test('untranslated keys in other locales fall back to English', () async {
      final asi = await AppLocalizations.delegate.load(const Locale('bno'));
      final english = await AppLocalizations.delegate.load(const Locale('en'));
      expect(asi.landingMascotSemantics, english.landingMascotSemantics);
      expect(asi.landingMascotSemantics, isNotEmpty);
    });
  });

  group('screens under Onhan', () {
    Future<void> pumpScreen(
      WidgetTester tester,
      Widget screen, {
      String mode = 'text',
      bool translated = false,
    }) async {
      await _setPhone(tester);
      final session = SessionProvider(translator: _Translator())
        ..setInputMode(mode);
      if (translated) {
        session
          ..setInputText('Maayong adlaw')
          ..setTarget('asi');
        await session.translate();
      }
      await tester.pumpWidget(
        _app(await _provider('loc'), session, screen, routes: {
          '/view-result': (_) => ViewResultScreen(ttsService: _Tts()),
        }),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(_localeName(tester, screen.runtimeType), 'loc');
    }

    testWidgets('landing', (tester) async {
      await _setPhone(tester);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>.value(
              value: await _provider('loc'),
            ),
            ChangeNotifierProvider<SessionProvider>(
              create: (_) => SessionProvider(),
            ),
          ],
          child: const IslaApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('language selection', (tester) async {
      await pumpScreen(tester, const LanguageSelectionScreen());
    });

    testWidgets('select languages, with tooltip', (tester) async {
      await pumpScreen(tester, const SelectLanguagesScreen());
      await tester.longPress(find.byType(IconButton).first);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Tooltip), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    for (final mode in ['text', 'voice', 'camera']) {
      testWidgets('input and translate ($mode)', (tester) async {
        await pumpScreen(
          tester,
          InputTranslateScreen(
            speechService: _Speech(),
            ocrService: _Ocr(),
            cameraService: _Camera(),
            permissionService: _Permissions(),
          ),
          mode: mode,
        );
        if (mode == 'text') {
          await tester.enterText(find.byType(TextField), 'Good morning');
          await tester.pump();
          await tester.ensureVisible(find.byType(TextField));
          await tester.pump();
          await tester.longPress(find.byType(TextField), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('view result', (tester) async {
      await pumpScreen(
        tester,
        ViewResultScreen(ttsService: _Tts()),
        translated: true,
      );
    });
  });

  group('import_onhan', () {
    final template = <String, dynamic>{
      'hello': 'Hello',
      '@hello': {'description': 'Screen: Landing'},
      'greet': 'Hi {name}',
      '@greet': {
        'placeholders': {'name': {}},
        'description': 'Screen: Landing',
      },
      'bye': 'Bye',
    };
    const header = ['Screen', 'Key', 'English', 'Onhan', 'Placeholders'];

    test('placeholder mismatch is rejected and nothing is produced', () {
      final result = buildOnhanArb(template, [
        header,
        ['Landing', 'greet', 'Hi {name}', 'Kumusta {pangalan}', 'name'],
      ]);
      expect(result.arbText, isNull);
      expect(result.errors.single, startsWith('greet:'));
    });

    test('unbalanced braces are rejected', () {
      final result = buildOnhanArb(template, [
        header,
        ['Landing', 'greet', 'Hi {name}', 'Kumusta {name', 'name'],
      ]);
      expect(result.arbText, isNull);
      expect(result.errors, isNotEmpty);
    });

    test('empty cells keep English and output is deterministic', () {
      final rows = [
        header,
        ['Landing', 'bye', 'Bye', '', ''],
        ['Landing', 'greet', 'Hi {name}', 'Kumusta {name}', 'name'],
        ['Landing', 'hello', 'Hello', 'Maayong adlaw', ''],
      ];
      final first = buildOnhanArb(template, rows);
      final second = buildOnhanArb(template, rows);
      expect(first.errors, isEmpty);
      expect(first.arbText, second.arbText);

      final arb = json.decode(first.arbText!) as Map<String, dynamic>;
      expect(arb.keys.toList(), [
        '@@locale',
        'hello',
        '@hello',
        'greet',
        '@greet',
        'bye',
      ]);
      expect(arb['hello'], 'Maayong adlaw');
      expect(arb['greet'], 'Kumusta {name}');
      expect(arb['bye'], 'Bye');
      expect(first.translated, 2);
      expect(first.pending, 1);
    });
  });
}
