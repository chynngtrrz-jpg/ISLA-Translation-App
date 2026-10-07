import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:isla_app/data/models/language.dart';
import 'package:isla_app/data/models/translation_result.dart';
import 'package:isla_app/data/services/camera_service.dart';
import 'package:isla_app/data/services/ocr_service.dart';
import 'package:isla_app/data/services/speech_service.dart';
import 'package:isla_app/data/services/translator_service.dart';
import 'package:isla_app/data/services/tts_service.dart';
import 'package:isla_app/providers/session_provider.dart';
import 'package:isla_app/ui/screens/input_translate_screen.dart';
import 'package:isla_app/ui/screens/view_result_screen.dart';

class _FakeTranslator implements TranslatorService {
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

class _FakeSpeech implements SpeechService {
  int stops = 0;

  @override
  Future<bool> initialize({void Function(String error)? onError}) async => true;

  @override
  Future<void> listen({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String error) onError,
  }) async {}

  @override
  Future<void> stop() async {
    stops++;
  }
}

class _FakeTts implements TtsService {
  @override
  Future<bool> isLanguageAvailable(String locale) async => true;

  @override
  Future<void> speak(String text, String locale) async {}

  @override
  Future<void> stop() async {}
}

class _FakeOcr implements OcrService {
  @override
  Future<void> close() async {}

  @override
  Future<String> recognizeFile(String path) async => '';
}

class _FakeCamera implements CameraService {
  int initialized = 0;

  @override
  Future<CameraController?> initialize() async {
    initialized++;
    return null;
  }

  @override
  Future<String?> capture(CameraController controller) async => null;

  @override
  Future<String?> chooseFromGallery() async => null;
}

Widget _testApp({
  required SessionProvider session,
  required Widget screen,
  Map<String, WidgetBuilder> routes = const {},
}) =>
    ChangeNotifierProvider<SessionProvider>.value(
      value: session,
      child: MaterialApp(
        routes: {
          '/view-result': (_) => ViewResultScreen(ttsService: _FakeTts()),
          ...routes,
        },
        home: screen,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('translate is disabled until text is entered, then shows result',
      (tester) async {
    final session = SessionProvider(translator: _FakeTranslator());
    await tester.pumpWidget(
      _testApp(
        session: session,
        screen: const InputTranslateScreen(),
      ),
    );

    final translate = tester.widget<InkWell>(
      find
          .ancestor(
            of: find.text('Translate').first,
            matching: find.byType(InkWell),
          )
          .first,
    );
    expect(translate.onTap, isNull);

    await tester.enterText(find.byType(TextField), 'Good morning');
    await tester.pump();
    await tester.ensureVisible(find.text('Translate'));
    await tester.tap(find.text('Translate'));
    await tester.pumpAndSettle();

    expect(find.byType(ViewResultScreen), findsOneWidget);
    expect(find.text('Translation Result'), findsOneWidget);
    expect(find.text('Maayong aga.'), findsOneWidget);
    expect(find.text('Translation confidence: High'), findsOneWidget);
  });

  testWidgets('input-and-translate screen fits requested responsive widths',
      (tester) async {
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
        _testApp(
          session: SessionProvider(translator: _FakeTranslator()),
          screen: InputTranslateScreen(
            speechService: _FakeSpeech(),
            ocrService: _FakeOcr(),
            cameraService: _FakeCamera(),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow at $viewport',
      );
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('editing input clears the translation result', (tester) async {
    final session = SessionProvider(translator: _FakeTranslator())
      ..setInputText('hello');
    await session.translate();
    await tester.pumpWidget(
      _testApp(
        session: session,
        screen: const InputTranslateScreen(),
      ),
    );

    await tester.enterText(find.byType(TextField), 'edited');
    await tester.pump();

    expect(session.result, isNull);
    expect(find.text('Maayong aga.'), findsNothing);
  });

  testWidgets('Clear & Start Over clears text and preserves language pair',
      (tester) async {
    final session = SessionProvider(translator: _FakeTranslator())
      ..setSource('fil')
      ..setTarget('asi')
      ..setInputText('hello');
    await session.translate();
    await tester.pumpWidget(
      _testApp(
        session: session,
        screen: const InputTranslateScreen(),
      ),
    );

    await tester.ensureVisible(find.text('Clear & Start Over'));
    await tester.tap(find.text('Clear & Start Over'));
    await tester.pumpAndSettle();

    expect(session.inputText, isEmpty);
    expect(session.result, isNull);
    expect(session.sourceId, 'fil');
    expect(session.targetId, 'asi');
  });

  testWidgets('Change returns to language selection without changing the pair',
      (tester) async {
    final session = SessionProvider()
      ..setSource('fil')
      ..setTarget('asi');
    await tester.pumpWidget(
      _testApp(
        session: session,
        screen: const InputTranslateScreen(),
        routes: {
          '/select-languages': (_) => const Scaffold(body: Text('Select pair')),
        },
      ),
    );

    await tester.ensureVisible(find.text('Change'));
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(find.text('Select pair'), findsOneWidget);
    expect(session.sourceId, 'fil');
    expect(session.targetId, 'asi');
  });

  testWidgets('mode changes preserve text and stop speech when leaving Voice',
      (tester) async {
    final session = SessionProvider();
    final speech = _FakeSpeech();
    final camera = _FakeCamera();
    await tester.pumpWidget(
      _testApp(
        session: session,
        screen: InputTranslateScreen(
          speechService: speech,
          ocrService: _FakeOcr(),
          cameraService: camera,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'kept message');
    await tester.pump();

    await tester.ensureVisible(find.text('Voice').first);
    await tester.tap(find.text('Voice').first);
    await tester.pumpAndSettle();
    expect(session.inputText, 'kept message');
    await tester.ensureVisible(find.text('Text').first);
    await tester.tap(find.text('Text').first);
    await tester.pumpAndSettle();
    expect(speech.stops, greaterThan(0));
    expect(session.inputText, 'kept message');

    await tester.ensureVisible(find.text('Camera').first);
    await tester.tap(find.text('Camera').first);
    await tester.pumpAndSettle();
    expect(camera.initialized, 1);
    await tester.ensureVisible(find.text('Text').first);
    await tester.tap(find.text('Text').first);
    await tester.pumpAndSettle();
    expect(session.inputText, 'kept message');
  });

  testWidgets('Ini voice input is unavailable and the microphone is disabled',
      (tester) async {
    final session = SessionProvider()..initFromUiLanguage('ini');
    await tester.pumpWidget(
      _testApp(
        session: session,
        screen: InputTranslateScreen(
          speechService: _FakeSpeech(),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Voice').first);
    await tester.tap(find.text('Voice').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Voice input is not available for Ini (Romblomanon).'),
      findsOneWidget,
    );
    final mic = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.mic),
    );
    expect(mic.onPressed, isNull);
  });

  testWidgets('step indicator marks step one complete and step two current',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        session: SessionProvider(),
        screen: const InputTranslateScreen(),
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('Input & Translate'), findsOneWidget);
    expect(find.text('View Result'), findsOneWidget);
  });

  testWidgets('uses the device keyboard to edit the message', (tester) async {
    await tester.pumpWidget(
      _testApp(
        session: SessionProvider(),
        screen: const InputTranslateScreen(),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.multiline);
    await tester.enterText(find.byType(TextField), 'Typed on device keyboard');
    await tester.pump();
    expect(field.controller!.text, 'Typed on device keyboard');
  });

  testWidgets('text, voice, and camera modes do not overflow at 360x640',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 640),
          textScaler: TextScaler.linear(1.3),
          disableAnimations: true,
        ),
        child: _testApp(
          session: SessionProvider(),
          screen: InputTranslateScreen(
            speechService: _FakeSpeech(),
            ocrService: _FakeOcr(),
            cameraService: _FakeCamera(),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    for (final mode in ['Voice', 'Camera', 'Text']) {
      final modeKey = ValueKey(
        'input-mode-${mode.toLowerCase()}',
      );
      await tester.ensureVisible(find.byKey(modeKey));
      await tester.tap(find.byKey(modeKey));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$mode mode overflowed');
    }
  });
}
