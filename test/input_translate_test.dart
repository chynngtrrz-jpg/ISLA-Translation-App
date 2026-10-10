import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:isla_app/l10n/app_localizations.dart';
import 'package:isla_app/data/models/language.dart';
import 'package:isla_app/data/models/translation_result.dart';
import 'package:isla_app/data/services/camera_service.dart';
import 'package:isla_app/data/services/ocr_service.dart';
import 'package:isla_app/data/services/runtime_permission_service.dart';
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
  int initializations = 0;

  @override
  Future<bool> initialize({
    void Function(String error)? onError,
    void Function(String status)? onStatus,
  }) async {
    initializations++;
    return true;
  }

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

class _FakePermissions implements RuntimePermissionService {
  _FakePermissions({
    this.microphone = RuntimePermissionState.granted,
    this.camera = RuntimePermissionState.granted,
  });

  final RuntimePermissionState microphone;
  final RuntimePermissionState camera;
  int settingsOpened = 0;

  @override
  Future<RuntimePermissionState> requestCamera() async => camera;

  @override
  Future<RuntimePermissionState> requestMicrophone() async => microphone;

  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;
    return true;
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
  Future<CameraOcrResult> recognizeImage(
    String path, {
    required ValueChanged<NormalizedCameraImage> onImageNormalized,
  }) async =>
      const CameraOcrResult(lines: []);
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
  Locale locale = const Locale('en'),
  Map<String, WidgetBuilder> routes = const {},
}) =>
    ChangeNotifierProvider<SessionProvider>.value(
      value: session,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          '/view-result': (_) => ViewResultScreen(ttsService: _FakeTts()),
          ...routes,
        },
        home: screen,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('camera line selection text follows reading order', () {
    final lines = [
      CameraOcrLine(
        id: 'second-block-line',
        text: 'Later block',
        blockIndex: 1,
        boundingBox: const Rect.fromLTWH(20, 60, 100, 20),
        cornerPoints: const [],
      ),
      CameraOcrLine(
        id: 'first-block-line-2',
        text: 'second line',
        blockIndex: 0,
        boundingBox: const Rect.fromLTWH(10, 25, 100, 20),
        cornerPoints: const [],
      ),
      CameraOcrLine(
        id: 'first-block-line-1',
        text: 'First line',
        blockIndex: 0,
        boundingBox: const Rect.fromLTWH(10, 5, 100, 20),
        cornerPoints: const [],
      ),
    ];

    expect(
      assembleSelectedCameraText(lines, {
        'second-block-line',
        'first-block-line-2',
        'first-block-line-1',
      }),
      'First line second line\nLater block',
    );
    expect(assembleSelectedCameraText(lines, const {}), isEmpty);
  });

  testWidgets('translate is disabled until text is entered, then shows result',
      (tester) async {
    final session = SessionProvider(translator: _FakeTranslator());
    await tester.pumpWidget(
      _testApp(
        session: session,
        screen: InputTranslateScreen(
          speechService: _FakeSpeech(),
          permissionService: _FakePermissions(),
        ),
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

    final fieldFinder = find.byType(TextField);
    final field = tester.widget<TextField>(fieldFinder);
    expect(field.keyboardType, TextInputType.multiline);
    expect(field.textInputAction, TextInputAction.newline);
    expect(field.textCapitalization, TextCapitalization.sentences);
    expect(field.minLines, 3);
    expect(field.maxLines, 6);
    expect(field.maxLength, 600);
    expect(field.autocorrect, isTrue);
    expect(field.enableSuggestions, isTrue);

    await tester.ensureVisible(fieldFinder);
    await tester.tap(fieldFinder);
    await tester.pump();
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.enterText(fieldFinder, 'Good morning');
    await tester.pump();
    expect(find.text('12 / 600'), findsOneWidget);
    await tester.ensureVisible(find.text('Translate'));
    await tester.tap(find.text('Translate'));
    await tester.pumpAndSettle();

    expect(field.focusNode!.hasFocus, isFalse);
    expect(find.byType(ViewResultScreen), findsOneWidget);
    expect(find.text('Translation Result'), findsOneWidget);
    expect(find.text('Maayong aga.'), findsOneWidget);
    expect(find.textContaining('Translation confidence:'), findsNothing);
  });

  testWidgets('input banner copy follows the selected mode and locale',
      (tester) async {
    final session = SessionProvider();
    await tester.pumpWidget(
      _testApp(session: session, screen: const InputTranslateScreen()),
    );

    expect(find.text('Type your message, then tap Translate.'), findsOneWidget);
    await tester.ensureVisible(find.text('Voice').first);
    await tester.tap(find.text('Voice').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Tap the microphone and speak, then tap Translate.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Camera').first);
    await tester.tap(find.text('Camera').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Point the camera at text, then tap Capture.'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _testApp(
        session: SessionProvider(),
        screen: const InputTranslateScreen(),
        locale: const Locale('tl'),
      ),
    );
    expect(
      find.text('Isulat ang iyong mensahe, pagkatapos ay pindutin ang Isalin.'),
      findsOneWidget,
    );
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
          permissionService: _FakePermissions(),
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

  testWidgets('denied microphone permission shows a message without starting',
      (tester) async {
    final permissions = _FakePermissions(
      microphone: RuntimePermissionState.denied,
    );
    final speech = _FakeSpeech();
    await tester.pumpWidget(
      _testApp(
        session: SessionProvider(),
        screen: InputTranslateScreen(
          speechService: speech,
          permissionService: permissions,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Voice').first);
    await tester.tap(find.text('Voice').first);
    await tester.pumpAndSettle();

    expect(find.text('Microphone permission is required.'), findsOneWidget);
    expect(speech.initializations, 0);
  });

  testWidgets('permanently denied camera permission offers app settings',
      (tester) async {
    final permissions = _FakePermissions(
      camera: RuntimePermissionState.permanentlyDenied,
    );
    final camera = _FakeCamera();
    await tester.pumpWidget(
      _testApp(
        session: SessionProvider(),
        screen: InputTranslateScreen(
          cameraService: camera,
          permissionService: permissions,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Camera').first);
    await tester.tap(find.text('Camera').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Camera access is blocked. Enable it in app settings.'),
      findsOneWidget,
    );
    expect(find.text('Open Settings'), findsOneWidget);
    expect(camera.initialized, 0);

    await tester.ensureVisible(find.text('Open Settings'));
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(permissions.settingsOpened, 1);
  });

  testWidgets('Ini voice input is unavailable and the microphone is disabled',
      (tester) async {
    final session = SessionProvider()
      ..initTranslationFlow()
      ..setTarget('fil')
      ..setSource('ini')
      ..setTarget('en');
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

  testWidgets(
      'uses native keyboard input and dismisses it outside or on mode change',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        session: SessionProvider(),
        screen: InputTranslateScreen(
          speechService: _FakeSpeech(),
          permissionService: _FakePermissions(),
          cameraService: _FakeCamera(),
        ),
      ),
    );

    final fieldFinder = find.byType(TextField);
    final field = tester.widget<TextField>(fieldFinder);
    expect(field.keyboardType, TextInputType.multiline);
    expect(field.textInputAction, TextInputAction.newline);
    expect(field.textCapitalization, TextCapitalization.sentences);
    await tester.ensureVisible(fieldFinder);
    await tester.tap(fieldFinder);
    await tester.pump();
    expect(field.focusNode!.hasFocus, isTrue);
    final banner = find.text('Type your message, then tap Translate.');
    await tester.ensureVisible(banner);
    await tester.tap(banner);
    await tester.pump();
    expect(field.focusNode!.hasFocus, isFalse);

    await tester.ensureVisible(fieldFinder);
    await tester.tap(fieldFinder);
    await tester.pump();
    await tester.enterText(fieldFinder, 'Typed on device keyboard');
    await tester.pump();
    expect(field.controller!.text, 'Typed on device keyboard');
    expect(find.text('24 / 600'), findsOneWidget);

    await tester.ensureVisible(find.text('Voice').first);
    await tester.tap(find.text('Voice').first);
    await tester.pumpAndSettle();
    expect(field.focusNode!.hasFocus, isFalse);

    await tester.ensureVisible(fieldFinder);
    await tester.tap(fieldFinder);
    await tester.pump();
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.ensureVisible(find.text('Camera').first);
    await tester.tap(find.text('Camera').first);
    await tester.pumpAndSettle();
    expect(field.focusNode!.hasFocus, isFalse);
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
