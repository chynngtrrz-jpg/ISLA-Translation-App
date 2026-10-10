import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../core/constants/app_config.dart';
import '../../core/constants/languages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/text_editing_ops.dart';
import '../../data/models/language.dart';
import '../../data/services/camera_service.dart';
import '../../data/services/ocr_service.dart';
import '../../data/services/runtime_permission_service.dart';
import '../../data/services/speech_service.dart';
import '../../providers/session_provider.dart';
import '../widgets/camera_input_panel.dart';
import '../widgets/input_mode_selector.dart';
import '../widgets/isla_app_bar.dart';
import '../widgets/language_pair_bar.dart';
import '../widgets/message_field.dart';
import '../widgets/screen_back_button.dart';
import '../widgets/step_indicator.dart';
import '../widgets/voice_input_panel.dart';
import '../widgets/welcome_banner.dart';

enum _InputError {
  common,
  voicePermissionDenied,
  cameraPermissionDenied,
  voicePermissionPermanentlyDenied,
  cameraPermissionPermanentlyDenied,
  cameraNoText,
}

/// Collects typed, spoken, or photographed text and translates it.
class InputTranslateScreen extends StatefulWidget {
  const InputTranslateScreen({
    this.speechService,
    this.ocrService,
    this.cameraService,
    this.permissionService,
    super.key,
  });

  final SpeechService? speechService;
  final OcrService? ocrService;
  final CameraService? cameraService;
  final RuntimePermissionService? permissionService;

  @override
  State<InputTranslateScreen> createState() => _InputTranslateScreenState();
}

class _InputTranslateScreenState extends State<InputTranslateScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late final SpeechService _speechService =
      widget.speechService ?? DeviceSpeechService();
  late final OcrService _ocrService = widget.ocrService ?? createOcrService();
  late final CameraService _cameraService =
      widget.cameraService ?? DeviceCameraService();
  late final RuntimePermissionService _permissionService =
      widget.permissionService ?? const DeviceRuntimePermissionService();

  CameraController? _cameraController;
  String? _cameraImagePath;
  Size? _cameraImageSize;
  final Set<String> _cameraTemporaryPaths = {};
  List<CameraOcrLine> _cameraLines = const [];
  Set<String> _selectedCameraLineIds = {};
  Future<void>? _cameraProcessingTask;
  bool _speechAvailable = false;
  bool _speechChecking = false;
  bool _listening = false;
  bool _voiceProcessing = false;
  _InputError? _voiceError;
  bool _cameraLoading = false;
  bool _cameraProcessing = false;
  int _cameraProcessingGeneration = 0;
  _InputError? _cameraError;
  Timer? _voiceProcessingTimer;
  bool _initializedController = false;
  bool _updatingController = false;
  bool _appResumed = true;
  int _cameraInitializationGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController.addListener(_handleControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.read<SessionProvider>();
    if (!_initializedController) {
      _updatingController = true;
      _messageController.text = session.inputText;
      _updatingController = false;
      _initializedController = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _appResumed = false;
      _cameraInitializationGeneration++;
      unawaited(_clearCameraResult(clearInput: false));
      unawaited(_disposeCamera());
    } else if (state == AppLifecycleState.resumed) {
      _appResumed = true;
      final mode = context.read<SessionProvider>().inputMode;
      if (mode == 'camera') {
        unawaited(_initializeCamera());
      } else if (mode == 'voice') {
        unawaited(_checkSpeechAvailability());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voiceProcessingTimer?.cancel();
    _messageController
      ..removeListener(_handleControllerChanged)
      ..dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    unawaited(_stopSpeechOnDispose());
    _cameraInitializationGeneration++;
    unawaited(_disposeCameraAndOcr());
    super.dispose();
  }

  Future<void> _disposeCameraAndOcr() async {
    await _disposeCamera(updateState: false);
    await _clearCameraResult(clearInput: false);
    await _ocrService.close();
  }

  Language _languageFor(String id) =>
      languages.firstWhere((language) => language.id == id);

  void _handleControllerChanged() {
    if (_updatingController) return;
    final session = context.read<SessionProvider>();
    session.setInputText(_messageController.text);
  }

  Future<void> _setMode(String mode) async {
    final session = context.read<SessionProvider>();
    if (session.inputMode == mode) return;
    if (mode != 'text') {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    if (session.inputMode == 'voice') await _stopListening();
    if (session.inputMode == 'camera') {
      await _clearCameraResult(clearInput: false);
      await _disposeCamera();
    }

    session.setInputMode(mode);
    if (!mounted) return;
    setState(() {
      _voiceError = null;
      _cameraError = null;
    });
    switch (mode) {
      case 'voice':
        await _checkSpeechAvailability();
        break;
      case 'camera':
        await _initializeCamera();
        break;
      case 'text':
        _messageFocusNode.requestFocus();
        break;
    }
  }

  Future<void> _checkSpeechAvailability() async {
    final source = _languageFor(context.read<SessionProvider>().sourceId);
    if (source.sttLocale == null) {
      setState(() => _speechAvailable = false);
      return;
    }
    if (_speechChecking) return;
    setState(() {
      _speechChecking = true;
      _voiceError = null;
    });
    try {
      final permission = await _permissionService.requestMicrophone();
      if (!mounted) return;
      if (permission != RuntimePermissionState.granted) {
        setState(() {
          _speechAvailable = false;
          _voiceError = permission == RuntimePermissionState.permanentlyDenied
              ? _InputError.voicePermissionPermanentlyDenied
              : _InputError.voicePermissionDenied;
        });
        return;
      }
      final available = await _speechService.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
      );
      if (mounted) setState(() => _speechAvailable = available);
      if (!available && mounted) {
        setState(() => _voiceError = _InputError.common);
      }
    } catch (error, stackTrace) {
      debugPrint(
          'Speech recognition initialization failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _speechAvailable = false;
          _voiceError = _InputError.common;
        });
      }
    } finally {
      if (mounted) setState(() => _speechChecking = false);
    }
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      setState(() => _listening = false);
    }
  }

  Future<void> _toggleListening() async {
    final source = _languageFor(context.read<SessionProvider>().sourceId);
    if (source.sttLocale == null || !_speechAvailable) return;
    if (_listening) {
      await _stopListening();
      return;
    }
    setState(() {
      _listening = true;
      _voiceError = null;
      _messageFocusNode.unfocus();
    });
    try {
      await _speechService.listen(
        localeId: source.sttLocale!,
        onResult: (text, isFinal) {
          if (!mounted) return;
          final value = applyInsert(
            const TextEditingValue(
              text: '',
              selection: TextSelection.collapsed(offset: 0),
            ),
            text,
            kMaxChars,
          );
          _messageController.value = value;
          if (isFinal) {
            setState(() {
              _listening = false;
              _voiceProcessing = true;
            });
            _voiceProcessingTimer?.cancel();
            _voiceProcessingTimer = Timer(
              const Duration(milliseconds: 350),
              () {
                if (mounted) setState(() => _voiceProcessing = false);
              },
            );
          }
        },
        onError: _handleSpeechError,
      );
    } catch (error, stackTrace) {
      debugPrint('Speech recognition failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _listening = false;
          _voiceError = _InputError.common;
        });
      }
    }
  }

  Future<void> _stopListening() async {
    _voiceProcessingTimer?.cancel();
    try {
      await _speechService.stop();
    } catch (error, stackTrace) {
      debugPrint('Stopping speech recognition failed: $error\n$stackTrace');
      if (mounted) setState(() => _voiceError = _InputError.common);
    }
    if (mounted) {
      setState(() {
        _listening = false;
        _voiceProcessing = false;
      });
    }
  }

  Future<void> _stopSpeechOnDispose() async {
    try {
      await _speechService.stop();
    } catch (error, stackTrace) {
      debugPrint('Stopping speech recognition during dispose failed: '
          '$error\n$stackTrace');
    }
  }

  void _handleSpeechError(String error) {
    if (!mounted) return;
    final lowerError = error.toLowerCase();
    final permissionError = lowerError.contains('permission') ||
        lowerError.contains('not-allowed') ||
        lowerError.contains('denied');
    setState(() {
      _listening = false;
      _voiceError = permissionError
          ? _InputError.voicePermissionDenied
          : _InputError.common;
    });
  }

  Future<void> _initializeCamera() async {
    if (_cameraLoading) return;
    setState(() {
      _cameraLoading = true;
      _cameraError = null;
    });
    final generation = ++_cameraInitializationGeneration;
    try {
      final permission = await _permissionService.requestCamera();
      if (!mounted || generation != _cameraInitializationGeneration) return;
      if (permission != RuntimePermissionState.granted) {
        setState(() {
          _cameraError = permission == RuntimePermissionState.permanentlyDenied
              ? _InputError.cameraPermissionPermanentlyDenied
              : _InputError.cameraPermissionDenied;
        });
        return;
      }
      final controller = await _cameraService.initialize();
      if (!mounted ||
          generation != _cameraInitializationGeneration ||
          !_appResumed ||
          context.read<SessionProvider>().inputMode != 'camera') {
        await controller?.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        if (controller == null) _cameraError = _InputError.common;
      });
    } catch (error, stackTrace) {
      debugPrint('Camera initialization failed: $error\n$stackTrace');
      if (mounted && generation == _cameraInitializationGeneration) {
        final errorText = error.toString().toLowerCase();
        final permissionError =
            errorText.contains('permission') || errorText.contains('denied');
        setState(() {
          _cameraError = permissionError
              ? _InputError.cameraPermissionDenied
              : _InputError.common;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _cameraLoading = false);
        if (_appResumed &&
            context.read<SessionProvider>().inputMode == 'camera' &&
            _cameraController == null &&
            generation != _cameraInitializationGeneration) {
          unawaited(_initializeCamera());
        }
      }
    }
  }

  Future<void> _disposeCamera({bool updateState = true}) async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (error, stackTrace) {
        debugPrint('Disposing camera failed: $error\n$stackTrace');
        if (updateState && mounted) {
          setState(() => _cameraError = _InputError.common);
        }
      }
    }
    if (updateState && mounted) setState(() {});
  }

  Future<void> _captureImage() async {
    final controller = _cameraController;
    if (controller == null || _cameraProcessing) return;
    setState(() => _cameraProcessing = true);
    try {
      final path = await _cameraService.capture(controller);
      if (path == null || !mounted) {
        if (mounted) setState(() => _cameraProcessing = false);
        return;
      }
      _cameraTemporaryPaths.add(path);
      await _pauseCameraPreview(controller);
      await _runCameraImageProcessing(path);
    } catch (error, stackTrace) {
      debugPrint('Camera capture failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _cameraProcessing = false;
          _cameraError = _InputError.common;
        });
      }
    }
  }

  Future<void> _pauseCameraPreview(CameraController? controller) async {
    if (controller == null) return;
    try {
      await controller.pausePreview();
    } catch (error, stackTrace) {
      debugPrint('Pausing camera preview failed: $error\n$stackTrace');
    }
  }

  Future<void> _openPermissionSettings({required bool microphone}) async {
    try {
      final opened = await _permissionService.openAppSettings();
      if (!opened && mounted) {
        setState(() {
          if (microphone) {
            _voiceError = _InputError.common;
          } else {
            _cameraError = _InputError.common;
          }
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Opening app settings failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          if (microphone) {
            _voiceError = _InputError.common;
          } else {
            _cameraError = _InputError.common;
          }
        });
      }
    }
  }

  Future<void> _chooseImage() async {
    try {
      final path = await _cameraService.chooseFromGallery();
      if (path == null || !mounted) return;
      await _pauseCameraPreview(_cameraController);
      await _runCameraImageProcessing(path);
    } catch (error, stackTrace) {
      debugPrint('Image selection failed: $error\n$stackTrace');
      if (mounted) setState(() => _cameraError = _InputError.common);
    }
  }

  Future<void> _runCameraImageProcessing(String path) async {
    final task = _processCameraImage(path);
    _cameraProcessingTask = task;
    try {
      await task;
    } finally {
      if (identical(_cameraProcessingTask, task)) {
        _cameraProcessingTask = null;
      }
    }
  }

  Future<void> _processCameraImage(String path) async {
    final generation = ++_cameraProcessingGeneration;
    setState(() {
      _cameraProcessing = true;
      _cameraError = null;
      _cameraImagePath = path;
      _cameraImageSize = null;
      _cameraLines = const [];
      _selectedCameraLineIds = {};
    });
    _messageController.clear();
    try {
      final result = await _ocrService.recognizeImage(
        path,
        onImageNormalized: (normalized) {
          _cameraTemporaryPaths.add(normalized.path);
          if (!mounted || generation != _cameraProcessingGeneration) return;
          setState(() {
            _cameraImagePath = normalized.path;
            _cameraImageSize = normalized.size;
          });
        },
      );
      if (generation != _cameraProcessingGeneration) {
        await _deleteCameraTemporaryImages();
      } else if (mounted) {
        setState(() {
          _cameraLines = result.lines;
          _cameraError = result.lines.isEmpty ? _InputError.cameraNoText : null;
        });
        _rebuildRecognizedText(const {});
      }
    } catch (error, stackTrace) {
      debugPrint('Text recognition failed: $error\n$stackTrace');
      if (mounted && generation == _cameraProcessingGeneration) {
        setState(() {
          _cameraLines = const [];
          _selectedCameraLineIds = {};
          _cameraError = _InputError.cameraNoText;
        });
      }
    } finally {
      if (mounted && generation == _cameraProcessingGeneration) {
        setState(() => _cameraProcessing = false);
      }
    }
  }

  Future<void> _retakeCameraImage() async {
    await _clearCameraResult(clearInput: true);
    final controller = _cameraController;
    if (controller != null && controller.value.isPreviewPaused) {
      try {
        await controller.resumePreview();
      } catch (error, stackTrace) {
        debugPrint('Resuming camera preview failed: $error\n$stackTrace');
        if (mounted) setState(() => _cameraError = _InputError.common);
      }
    }
  }

  Future<void> _clearCameraResult({required bool clearInput}) async {
    _cameraProcessingGeneration++;
    await _cameraProcessingTask;
    await _deleteCameraTemporaryImages();
    if (mounted) {
      setState(() {
        _cameraImagePath = null;
        _cameraImageSize = null;
        _cameraLines = const [];
        _selectedCameraLineIds = {};
        _cameraProcessing = false;
        _cameraError = null;
      });
      if (clearInput) _messageController.clear();
    }
  }

  Future<void> _deleteCameraTemporaryImages() async {
    final paths = _cameraTemporaryPaths.toList(growable: false);
    _cameraTemporaryPaths.clear();
    for (final path in paths) {
      try {
        await File(path).delete();
      } on FileSystemException catch (error) {
        if (error.osError?.errorCode != 2) {
          debugPrint('Deleting camera image failed: $error');
        }
      }
    }
  }

  void _selectCameraLine(CameraOcrLine line) {
    final selected = {..._selectedCameraLineIds};
    if (!selected.add(line.id)) selected.remove(line.id);
    _updateCameraSelection(selected);
  }

  void _selectAllCameraLines() {
    _updateCameraSelection(_cameraLines.map((line) => line.id).toSet());
  }

  void _clearCameraSelection() {
    _updateCameraSelection(const {});
  }

  void _updateCameraSelection(Set<String> selected) {
    setState(() => _selectedCameraLineIds = selected);
    _rebuildRecognizedText(selected);
  }

  void _rebuildRecognizedText(Set<String> selected) {
    _messageController.value = applyInsert(
      const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      ),
      assembleSelectedCameraText(_cameraLines, selected),
      kMaxChars,
    );
  }

  Future<void> _clearAndStartOver() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _stopListening();
    await _clearCameraResult(clearInput: false);
    await _disposeCamera();
    if (!mounted) return;
    context.read<SessionProvider>().clearInputAndResult();
    _messageController.clear();
  }

  Future<void> _translateAndShowResult(SessionProvider session) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await session.translate();
    if (mounted && session.result != null) {
      await Navigator.pushNamed(context, '/view-result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final session = context.watch<SessionProvider>();
    final source = _languageFor(session.sourceId);
    final target = _languageFor(session.targetId);
    final counterText = app.inputCounter(
      '${_messageController.text.characters.length}',
      '$kMaxChars',
    );
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          IslaAppBar(
            subtitle: app.appSubtitle,
            trailing: ScreenBackButton(
              tooltip: app.backToLanguagePairSelection,
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ResponsiveCenter(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      Responsive.space(context, 16),
                      Responsive.space(context, 12),
                      Responsive.space(context, 16),
                      Responsive.space(context, 24) +
                          MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WelcomeBanner(
                          body: switch (session.inputMode) {
                            'voice' => app.inputVoiceBanner,
                            'camera' => app.inputCameraBanner,
                            _ => app.inputTextBanner,
                          },
                        ),
                        SizedBox(height: Responsive.space(context, 16)),
                        const StepIndicator(currentStep: 2),
                        SizedBox(height: Responsive.space(context, 12)),
                        LanguagePairBar(source: source, target: target),
                        SizedBox(height: Responsive.space(context, 16)),
                        _buildMessageCard(
                          context,
                          session,
                          source,
                          counterText,
                        ),
                        SizedBox(height: Responsive.space(context, 12)),
                        SizedBox(
                          height: Responsive.space(context, 46),
                          child: Material(
                            color: AppColors.glacier,
                            shape: const StadiumBorder(),
                            child: InkWell(
                              onTap: _clearAndStartOver,
                              customBorder: const StadiumBorder(),
                              child: Center(
                                child: Text(
                                  app.inputClear,
                                  style: TextStyle(
                                    color: AppColors.espresso,
                                    fontSize: Responsive.sp(context, 16),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(
    BuildContext context,
    SessionProvider session,
    Language source,
    String counterText,
  ) {
    final app = AppLocalizations.of(context)!;
    final modeLabel = switch (session.inputMode) {
      'voice' => app.inputLabelTranscript,
      'camera' => app.inputLabelRecognized,
      _ => app.inputLabelText,
    };
    final voiceAvailable = source.sttLocale != null && _speechAvailable;
    final canTranslate = session.inputText.trim().isNotEmpty &&
        session.isModelReady &&
        !session.isTranslating;

    final inputControls = <Widget>[
      InputModeSelector(mode: session.inputMode, onChanged: _setMode),
      if (session.inputMode == 'voice')
        VoiceInputPanel(
          available: voiceAvailable,
          listening: _listening,
          processing: _voiceProcessing || _speechChecking,
          errorText: _voiceError == null ? null : _voiceErrorText(app),
          permissionPermanentlyDenied:
              _voiceError == _InputError.voicePermissionPermanentlyDenied,
          languageLabel: source.fieldLabel,
          onTap: _toggleListening,
          onOpenSettings: () => _openPermissionSettings(microphone: true),
        ),
      if (session.inputMode == 'camera')
        CameraInputPanel(
          controller: _cameraController,
          loading: _cameraLoading || _cameraProcessing,
          processing: _cameraProcessing,
          errorText: _cameraError == null
              ? null
              : _cameraErrorText(app, _cameraError!),
          permissionPermanentlyDenied:
              _cameraError == _InputError.cameraPermissionPermanentlyDenied,
          onCapture: _captureImage,
          onGallery: _chooseImage,
          imagePath: _cameraImagePath,
          imageSize: _cameraImageSize,
          lines: _cameraLines,
          selectedLineIds: _selectedCameraLineIds,
          onSelectLine: _selectCameraLine,
          onRetake: _retakeCameraImage,
          onSelectAll: _selectAllCameraLines,
          onClearSelection: _clearCameraSelection,
          onOpenSettings: () => _openPermissionSettings(microphone: false),
        ),
      SizedBox(height: Responsive.space(context, 16)),
      _SectionHeading(modeLabel),
      SizedBox(height: Responsive.space(context, 8)),
      MessageField(
        controller: _messageController,
        focusNode: _messageFocusNode,
        onChanged: session.setInputText,
      ),
      SizedBox(height: Responsive.space(context, 4)),
      Align(
        alignment: Alignment.centerRight,
        child: Text(
          counterText,
          style: TextStyle(
            color: AppColors.espresso,
            fontSize: Responsive.sp(context, 14),
            fontWeight: _messageController.text.characters.length >= 540
                ? FontWeight.w800
                : FontWeight.w400,
          ),
        ),
      ),
      SizedBox(height: Responsive.space(context, 12)),
      _TranslateButton(
        enabled: canTranslate,
        translating: session.isTranslating,
        onPressed: () => _translateAndShowResult(session),
      ),
      if (!session.isModelReady) ...[
        SizedBox(height: Responsive.space(context, 8)),
        Text(
          app.statusModelLoading,
          style: TextStyle(
            color: AppColors.clay,
            fontSize: Responsive.sp(context, 14),
          ),
        ),
      ],
      if (session.errorKey != null) ...[
        SizedBox(height: Responsive.space(context, 8)),
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.espresso,
                size: Responsive.sp(context, 18),
              ),
              SizedBox(width: Responsive.space(context, 6)),
              Expanded(
                child: Text(
                  app.commonError,
                  style: TextStyle(
                    color: AppColors.espresso,
                    fontSize: Responsive.sp(context, 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ];
    return Container(
      padding: EdgeInsets.all(Responsive.space(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Responsive.space(context, 24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.12),
            blurRadius: Responsive.space(context, 16),
            offset: Offset(0, Responsive.space(context, 4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            app.inputTitle,
            style: TextStyle(
              color: AppColors.espresso,
              fontSize: Responsive.sp(context, 22),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: Responsive.space(context, 12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: inputControls,
          ),
        ],
      ),
    );
  }

  String _voiceErrorText(AppLocalizations app) {
    return switch (_voiceError!) {
      _InputError.voicePermissionDenied => app.voicePermissionDenied,
      _InputError.voicePermissionPermanentlyDenied =>
        app.voicePermissionPermanentlyDenied,
      _ => app.commonError,
    };
  }

  String _cameraErrorText(AppLocalizations app, _InputError error) {
    return switch (error) {
      _InputError.cameraPermissionDenied => app.cameraPermissionDenied,
      _InputError.cameraPermissionPermanentlyDenied =>
        app.cameraPermissionPermanentlyDenied,
      _InputError.cameraNoText => app.cameraNoText,
      _ => app.commonError,
    };
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          color: AppColors.espresso,
          fontSize: Responsive.sp(context, 14),
          fontWeight: FontWeight.w700,
          letterSpacing: Responsive.space(context, 1.5),
        ),
      );
}

class _TranslateButton extends StatelessWidget {
  const _TranslateButton({
    required this.enabled,
    required this.translating,
    required this.onPressed,
  });

  final bool enabled;
  final bool translating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final text = translating ? app.inputTranslating : app.inputTranslate;
    return SizedBox(
      height: Responsive.space(context, 48),
      child: Material(
        color: AppColors.chambray.withValues(alpha: enabled ? 1 : 0.4),
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          customBorder: const StadiumBorder(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (translating) ...[
                SizedBox(
                  width: Responsive.space(context, 20),
                  height: Responsive.space(context, 20),
                  child: CircularProgressIndicator(
                    color: AppColors.espresso,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: Responsive.space(context, 8)),
              ],
              Text(
                text,
                style: TextStyle(
                  color:
                      AppColors.espresso.withValues(alpha: enabled ? 1 : 0.6),
                  fontSize: Responsive.sp(context, 18),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
