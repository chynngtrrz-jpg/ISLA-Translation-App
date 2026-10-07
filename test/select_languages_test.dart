import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:isla_app/providers/language_provider.dart';
import 'package:isla_app/providers/session_provider.dart';
import 'package:isla_app/ui/screens/input_translate_screen.dart';
import 'package:isla_app/ui/screens/language_selection_screen.dart';
import 'package:isla_app/ui/screens/select_languages_screen.dart';

Widget buildTestApp({
  required LanguageProvider languageProvider,
  required SessionProvider sessionProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
      ChangeNotifierProvider<SessionProvider>.value(value: sessionProvider),
    ],
    child: MaterialApp(
      initialRoute: '/select-languages',
      routes: {
        '/language': (_) => const LanguageSelectionScreen(),
        '/select-languages': (_) => const SelectLanguagesScreen(),
        '/input-translate': (_) => const InputTranslateScreen(),
      },
    ),
  );
}

Future<LanguageProvider> createLanguageProvider(String uiLanguageId) async {
  SharedPreferences.setMockInitialValues({'ui_language': uiLanguageId});
  final preferences = await SharedPreferences.getInstance();
  return LanguageProvider(preferences: preferences);
}

void main() {
  test('entry rule chooses a different default target', () {
    final englishSession = SessionProvider()..initFromUiLanguage('en');
    expect(englishSession.sourceId, 'en');
    expect(englishSession.targetId, 'ini');

    final iniSession = SessionProvider()..initFromUiLanguage('ini');
    expect(iniSession.sourceId, 'ini');
    expect(iniSession.targetId, 'en');
  });

  test('swap exchanges a supported pair and blocks an unsupported direction',
      () {
    final session = SessionProvider()..initFromUiLanguage('en');
    expect(session.swap(), isTrue);
    expect(session.sourceId, 'ini');
    expect(session.targetId, 'en');

    final restrictedSession = SessionProvider(
      pairSupport: (source, target) => source == 'en' && target == 'fil',
    )
      ..initFromUiLanguage('en')
      ..setTarget('fil');
    expect(restrictedSession.swap(), isFalse);
    expect(restrictedSession.sourceId, 'en');
    expect(restrictedSession.targetId, 'fil');
  });

  testWidgets(
      'picker disables the language already selected in the other field',
      (tester) async {
    final session = SessionProvider();
    final languageProvider = await createLanguageProvider('en');
    await tester.pumpWidget(
      buildTestApp(
        languageProvider: languageProvider,
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
    final disabledIni = tester.widget<ListTile>(
      find
          .ancestor(
            of: find.text('Romblomanon (Ini)').last,
            matching: find.byType(ListTile),
          )
          .last,
    );
    expect(disabledIni.enabled, isFalse);
  });

  testWidgets('Next navigates to the input and translation screen',
      (tester) async {
    final languageProvider = await createLanguageProvider('en');
    await tester.pumpWidget(
      buildTestApp(
        languageProvider: languageProvider,
        sessionProvider: SessionProvider(),
      ),
    );

    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.byType(InputTranslateScreen), findsOneWidget);
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
    final languageProvider = await createLanguageProvider('fil');
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>.value(
            value: languageProvider,
          ),
          ChangeNotifierProvider<SessionProvider>.value(
            value: SessionProvider(),
          ),
        ],
        child: MaterialApp(
          home: const LanguageSelectionScreen(),
          routes: {
            '/select-languages': (_) => const SelectLanguagesScreen(),
            '/input-translate': (_) => const InputTranslateScreen(),
          },
        ),
      ),
    );

    await tester.ensureVisible(find.text('Filipino'));
    await tester.tap(find.text('Filipino'));
    await tester.pump(const Duration(milliseconds: 181));
    await tester.pumpAndSettle();
    expect(find.byType(SelectLanguagesScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back to language selection'));
    await tester.pumpAndSettle();

    expect(find.byType(LanguageSelectionScreen), findsOneWidget);
    expect(languageProvider.uiLanguage, 'fil');
  });

  testWidgets(
      'Clear & Start Over restores entry defaults and clears session text',
      (tester) async {
    final session = SessionProvider();
    final languageProvider = await createLanguageProvider('en');

    await tester.pumpWidget(
      buildTestApp(
        languageProvider: languageProvider,
        sessionProvider: session,
      ),
    );

    session
      ..setSource('fil')
      ..setTarget('asi')
      ..setInputText('hello')
      ..setResultText('kamusta');
    await tester.pump();
    await tester.ensureVisible(find.text('Clear & Start Over'));
    await tester.tap(find.text('Clear & Start Over'));
    await tester.pump();

    expect(session.sourceId, 'en');
    expect(session.targetId, 'ini');
    expect(session.inputText, isEmpty);
    expect(session.resultText, isEmpty);
  });

  testWidgets('fits 360x640 at 1.3 text scale without overflow',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final languageProvider = await createLanguageProvider('en');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>.value(
            value: languageProvider,
          ),
          ChangeNotifierProvider<SessionProvider>.value(
            value: SessionProvider(),
          ),
        ],
        child: MaterialApp(
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
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('select-language screen fits requested responsive widths',
      (tester) async {
    final languageProvider = await createLanguageProvider('en');
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
          languageProvider: languageProvider,
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
