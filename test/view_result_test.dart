import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:isla_app/l10n/app_localizations.dart';
import 'package:isla_app/data/models/language.dart';
import 'package:isla_app/data/models/translation_result.dart';
import 'package:isla_app/data/services/translator_service.dart';
import 'package:isla_app/data/services/tts_service.dart';
import 'package:isla_app/providers/session_provider.dart';
import 'package:isla_app/core/theme/app_colors.dart';
import 'package:isla_app/ui/screens/view_result_screen.dart';
import 'package:isla_app/ui/widgets/isla_app_bar.dart';
import 'package:isla_app/ui/widgets/translation_result_card.dart';

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
        text: 'Maayong aga.',
        confidence: 0.86,
        latencyMs: 10,
      );
}

class _Tts implements TtsService {
  @override
  Future<bool> isLanguageAvailable(String locale) async => true;

  @override
  Future<void> speak(String text, String locale) async {}

  @override
  Future<void> stop() async {}
}

Widget _testApp({
  required SessionProvider session,
  required Widget home,
  Map<String, WidgetBuilder> routes = const {},
}) =>
    ChangeNotifierProvider<SessionProvider>.value(
      value: session,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          '/input-translate': (_) => const Scaffold(body: Text('Input screen')),
          '/select-languages': (_) =>
              const Scaffold(body: Text('Language pair screen')),
          ...routes,
        },
        home: home,
      ),
    );

Future<SessionProvider> _translatedSession() async {
  final session = SessionProvider(translator: _Translator())
    ..setSource('fil')
    ..setTarget('asi')
    ..setInputText('Maayong adlaw');
  await session.translate();
  return session;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows original and translated text with step three active',
      (tester) async {
    final session = await _translatedSession();
    await tester.pumpWidget(
      _testApp(
        session: session,
        home: ViewResultScreen(ttsService: _Tts()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Translation Result'), findsOneWidget);
    expect(find.text('Review your translation below.'), findsOneWidget);
    expect(find.text('ORIGINAL · Tagalog'), findsOneWidget);
    expect(find.text('Maayong adlaw'), findsOneWidget);
    expect(find.text('Maayong aga.'), findsOneWidget);
    expect(find.textContaining('Translation confidence:'), findsNothing);
    expect(find.text('Verify with a local speaker.'), findsNothing);
    expect(find.text('Translate Another'), findsOneWidget);
    expect(find.text('Start Over'), findsOneWidget);

    final completedStepOne = tester.widget<Container>(
      find.byKey(const ValueKey('step-circle-1')),
    );
    final completedStepTwo = tester.widget<Container>(
      find.byKey(const ValueKey('step-circle-2')),
    );
    final activeStepThree = tester.widget<Container>(
      find.byKey(const ValueKey('step-circle-3')),
    );
    expect(
      (completedStepOne.decoration! as BoxDecoration).color,
      AppColors.chambray,
    );
    expect(
      (completedStepTwo.decoration! as BoxDecoration).color,
      AppColors.chambray,
    );
    expect(
      (activeStepThree.decoration! as BoxDecoration).color,
      AppColors.espresso,
    );
  });

  testWidgets('result banner stays near the top of a tall phone screen',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = await _translatedSession();
    await tester.pumpWidget(
      _testApp(
        session: session,
        home: ViewResultScreen(ttsService: _Tts()),
      ),
    );
    await tester.pumpAndSettle();

    final appBarBottom = tester.getRect(find.byType(IslaAppBar)).bottom;
    final bannerTitleTop =
        tester.getTopLeft(find.text('Translation Result')).dy;
    expect(bannerTitleTop - appBarBottom, lessThan(50));
    final startOverBottom = tester.getBottomLeft(find.text('Start Over')).dy;
    expect(startOverBottom, greaterThan(tester.view.physicalSize.height * 0.9));
  });

  testWidgets('Translate Another returns to input and retains session data',
      (tester) async {
    final session = await _translatedSession();
    await tester.pumpWidget(
      _testApp(
        session: session,
        home: ViewResultScreen(ttsService: _Tts()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Translate Another'));
    await tester.tap(find.text('Translate Another'));
    await tester.pumpAndSettle();

    expect(find.text('Input screen'), findsOneWidget);
    expect(session.sourceId, 'fil');
    expect(session.targetId, 'asi');
    expect(session.inputText, 'Maayong adlaw');
    expect(session.result?.text, 'Maayong aga.');
  });

  testWidgets('Start Over resets session and returns to language pair screen',
      (tester) async {
    final session = await _translatedSession();
    await tester.pumpWidget(
      _testApp(
        session: session,
        home: ViewResultScreen(ttsService: _Tts()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Start Over'));
    await tester.tap(find.text('Start Over'));
    await tester.pumpAndSettle();

    expect(find.text('Language pair screen'), findsOneWidget);
    expect(session.sourceId, 'en');
    expect(session.targetId, 'ini');
    expect(session.inputText, isEmpty);
    expect(session.result, isNull);
  });

  testWidgets('shows a safe empty-result state and returns to input',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        session: SessionProvider(),
        home: ViewResultScreen(ttsService: _Tts()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No translation yet'), findsOneWidget);
    expect(find.text('Back to Input'), findsOneWidget);
    expect(find.byType(TranslationResultCard), findsNothing);

    await tester.ensureVisible(find.text('Back to Input'));
    await tester.tap(find.text('Back to Input'));
    await tester.pumpAndSettle();
    expect(find.text('Input screen'), findsOneWidget);
  });

  testWidgets('result screen fits requested phone, tablet, and web widths',
      (tester) async {
    final session = await _translatedSession();
    final viewports = [
      const Size(320, 640),
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1280, 900),
    ];

    for (final viewport in viewports) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(
        _testApp(
          session: session,
          home: ViewResultScreen(ttsService: _Tts()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow at $viewport',
      );
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
