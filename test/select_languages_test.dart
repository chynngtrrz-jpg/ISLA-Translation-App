import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:isla_app/l10n/app_localizations.dart';
import 'package:isla_app/l10n/fallback_localizations.dart';
import 'package:isla_app/providers/locale_provider.dart';
import 'package:isla_app/providers/session_provider.dart';
import 'package:isla_app/ui/screens/input_translate_screen.dart';
import 'package:isla_app/ui/screens/language_selection_screen.dart';
import 'package:isla_app/ui/screens/select_languages_screen.dart';

Widget buildTestApp({
  required LocaleProvider localeProvider,
  required SessionProvider sessionProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ChangeNotifierProvider<SessionProvider>.value(value: sessionProvider),
    ],
    child: Consumer<LocaleProvider>(
      builder: (context, locale, child) => MaterialApp(
        locale: locale.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          EnglishFallbackMaterialLocalizationsDelegate(),
          EnglishFallbackWidgetsLocalizationsDelegate(),
          EnglishFallbackCupertinoLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: '/select-languages',
        routes: {
          '/language': (_) => const LanguageSelectionScreen(),
          '/select-languages': (_) => const SelectLanguagesScreen(),
          '/input-translate': (_) => const InputTranslateScreen(),
        },
      ),
    ),
  );
}

Future<LocaleProvider> createLocaleProvider(String localeCode) async {
  SharedPreferences.setMockInitialValues({'ui_locale': localeCode});
  final preferences = await SharedPreferences.getInstance();
  final provider = LocaleProvider(preferences: preferences);
  await provider.loadSavedLocale();
  return provider;
}

void main() {
  test('translation flow defaults do not depend on the interface locale', () {
    final session = SessionProvider()..initTranslationFlow();
    expect(session.sourceId, 'en');
    expect(session.targetId, 'ini');
  });

  test('swap exchanges a supported pair and blocks an unsupported direction',
      () {
    final session = SessionProvider()..initTranslationFlow();
    expect(session.swap(), isTrue);
    expect(session.sourceId, 'ini');
    expect(session.targetId, 'en');

    final restrictedSession = SessionProvider(
      pairSupport: (source, target) => source == 'en' && target == 'fil',
    )
      ..initTranslationFlow()
      ..setTarget('fil');
    expect(restrictedSession.swap(), isFalse);
    expect(restrictedSession.sourceId, 'en');
    expect(restrictedSession.targetId, 'fil');
  });

  testWidgets(
      'picker disables the language already selected in the other field',
      (tester) async {
    final session = SessionProvider();
    final localeProvider = await createLocaleProvider('en');
    await tester.pumpWidget(
      buildTestApp(
        localeProvider: localeProvider,
        sessionProvider: session,
      ),
    );

    final sourceField =
        find.byKey(const ValueKey('Source language-language-field'));
    await tester.ensureVisible(sourceField);
    await tester.tap(sourceField);
    await tester.pumpAndSettle();

    expect(find.text('Source language'), findsOneWidget);
    expect(find.text('Already selected'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    final disabledIni = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Ini (Romblomanon)'),
        matching: find.byType(ListTile),
      ),
    );
    expect(disabledIni.enabled, isFalse);
  });

  testWidgets('Bantoanon locale opens the language picker with English fallback',
      (tester) async {
    final localeProvider = await createLocaleProvider('bno');
    await tester.pumpWidget(
      buildTestApp(
        localeProvider: localeProvider,
        sessionProvider: SessionProvider(),
      ),
    );

    final sourceField =
        find.byKey(const ValueKey('Source language-language-field'));
    await tester.ensureVisible(sourceField);
    await tester.tap(sourceField);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Source language'), findsOneWidget);
    expect(find.text('Already selected'), findsOneWidget);
  });

  testWidgets('Onhan locale opens the language picker with English fallback',
      (tester) async {
    final localeProvider = await createLocaleProvider('loc');
    await tester.pumpWidget(
      buildTestApp(
        localeProvider: localeProvider,
        sessionProvider: SessionProvider(),
      ),
    );

    final sourceField =
        find.byKey(const ValueKey('Source language-language-field'));
    await tester.ensureVisible(sourceField);
    await tester.tap(sourceField);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Source language'), findsOneWidget);
    expect(find.text('Already selected'), findsOneWidget);
  });

  testWidgets('Next navigates to the input and translation screen',
      (tester) async {
    final localeProvider = await createLocaleProvider('en');
    await tester.pumpWidget(
      buildTestApp(
        localeProvider: localeProvider,
        sessionProvider: SessionProvider(),
      ),
    );

    expect(
      find.text(
        'Select your languages, then tap "Next" to type your message.',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.byType(InputTranslateScreen), findsOneWidget);
    expect(find.text('Type your message, then tap Translate.'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('English') &&
            widget.text.toPlainText().contains('Ini (Romblomanon)'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
  });

  testWidgets('back button returns to Language Selection', (tester) async {
    final localeProvider = await createLocaleProvider('tl');
    final sessionProvider = SessionProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
          ChangeNotifierProvider<SessionProvider>.value(
            value: sessionProvider,
          ),
        ],
        child: Consumer<LocaleProvider>(
          builder: (context, locale, child) => MaterialApp(
            locale: locale.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LanguageSelectionScreen(),
            routes: {
              '/select-languages': (_) => const SelectLanguagesScreen(),
              '/input-translate': (_) => const InputTranslateScreen(),
            },
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Tagalog'));
    await tester.tap(find.text('Tagalog'));
    await tester.pump(const Duration(milliseconds: 181));
    await tester.pumpAndSettle();
    expect(find.byType(SelectLanguagesScreen), findsOneWidget);
    expect(sessionProvider.sourceId, 'en');
    expect(sessionProvider.targetId, 'ini');

    await tester.tap(find.byTooltip('Bumalik sa pagpili ng wika'));
    await tester.pumpAndSettle();

    expect(find.byType(LanguageSelectionScreen), findsOneWidget);
    expect(localeProvider.locale, const Locale('tl'));
  });

  testWidgets(
      'Choose Languages does not show Clear & Start Over or reset the session',
      (tester) async {
    final session = SessionProvider();
    final localeProvider = await createLocaleProvider('en');

    await tester.pumpWidget(
      buildTestApp(
        localeProvider: localeProvider,
        sessionProvider: session,
      ),
    );

    session
      ..setSource('fil')
      ..setTarget('asi')
      ..setInputText('hello')
      ..setResultText('kamusta');
    await tester.pump();
    expect(find.text('Clear & Start Over'), findsNothing);

    expect(session.sourceId, 'fil');
    expect(session.targetId, 'asi');
    expect(session.inputText, 'hello');
    expect(session.resultText, 'kamusta');
  });

  testWidgets('fits 360x640 at 1.3 text scale without overflow',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final localeProvider = await createLocaleProvider('en');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
          ChangeNotifierProvider<SessionProvider>.value(
            value: SessionProvider(),
          ),
        ],
        child: Consumer<LocaleProvider>(
          builder: (context, locale, child) => MaterialApp(
            locale: locale.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: const SelectLanguagesScreen(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('select-language screen fits requested responsive widths',
      (tester) async {
    final localeProvider = await createLocaleProvider('en');
    final session = SessionProvider();
    final viewports = [
      const Size(320, 640),
      const Size(390, 844),
      const Size(600, 900),
      const Size(768, 1024),
      const Size(1024, 768),
      const Size(1440, 900),
    ];

    for (final viewport in viewports) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(
        buildTestApp(
          localeProvider: localeProvider,
          sessionProvider: session,
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow at $viewport',
      );
      expect(find.byType(SelectLanguagesScreen), findsOneWidget);
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
