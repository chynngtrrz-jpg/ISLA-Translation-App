import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../../core/constants/languages.dart';
import '../../core/localization/isla_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/text_editing_ops.dart';
import '../../data/models/language.dart';
import '../../data/services/camera_service.dart';
import '../../data/services/ocr_service.dart';
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

/// Collects typed, spoken, or photographed text and translates it.
class InputTranslateScreen extends StatefulWidget {
  const InputTranslateScreen({
    this.speechService,
    this.ocrService,
    this.cameraService,
    super.key,
  });

  final SpeechService? speechService;
  final OcrService? ocrService;
  final CameraService? cameraService;

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

  CameraController? _cameraController;
  bool _speechAvailable = false;
  bool _speechChecking = false;
  bool _listening = false;
  bool _voiceProcessing = false;
  String? _voiceErrorKey;
  bool _cameraLoading = false;
  bool _cameraProcessing = false;
  String? _cameraErrorKey;
  Timer? _voiceProcessingTimer;
  bool _initializedController = false;
  bool _updatingController = false;

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
      unawaited(_disposeCamera());
    } else if (state == AppLifecycleState.resumed &&
        context.read<SessionProvider>().inputMode == 'camera') {
      unawaited(_initializeCamera());
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
    unawaited(_speechService.stop());
    unawaited(_disposeCamera(updateState: false));
    unawaited(_ocrService.close());
    super.dispose();
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
    if (session.inputMode == 'voice') await _stopListening();
    if (session.inputMode == 'camera') await _disposeCamera();

    session.setInputMode(mode);
    if (!mounted) return;
    setState(() {
      _voiceErrorKey = null;
      _cameraErrorKey = null;
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
      _voiceErrorKey = null;
    });
    try {
      final available =
          await _speechService.initialize(onError: _handleSpeechError);
      if (mounted) setState(() => _speechAvailable = available);
      if (!available && mounted) {
        setState(() => _voiceErrorKey = L10nKeys.commonError);
      }
    } catch (error, stackTrace) {
      debugPrint(
          'Speech recognition initialization failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _speechAvailable = false;
          _voiceErrorKey = L10nKeys.commonError;
        });
      }
    } finally {
      if (mounted) setState(() => _speechChecking = false);
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
      _voiceErrorKey = null;
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
          _voiceErrorKey = L10nKeys.commonError;
        });
      }
    }
  }

  Future<void> _stopListening() async {
    _voiceProcessingTimer?.cancel();
    await _speechService.stop();
    if (mounted) {
      setState(() {
        _listening = false;
        _voiceProcessing = false;
      });
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
      _voiceErrorKey = permissionError
          ? L10nKeys.voicePermissionDenied
          : L10nKeys.commonError;
    });
  }

  Future<void> _initializeCamera() async {
    if (_cameraLoading) return;
    setState(() {
      _cameraLoading = true;
      _cameraErrorKey = null;
    });
    try {
      final controller = await _cameraService.initialize();
      if (!mounted) {
        await controller?.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        if (controller == null) _cameraErrorKey = L10nKeys.commonError;
      });
    } catch (error, stackTrace) {
      debugPrint('Camera initialization failed: $error\n$stackTrace');
      if (mounted) {
        final permissionError =
            error.toString().toLowerCase().contains('permission');
        setState(() {
          _cameraErrorKey = permissionError
              ? L10nKeys.cameraPermissionDenied
              : L10nKeys.commonError;
        });
      }
    } finally {
      if (mounted) setState(() => _cameraLoading = false);
    }
  }

  Future<void> _disposeCamera({bool updateState = true}) async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) await controller.dispose();
    if (updateState && mounted) setState(() {});
  }

  Future<void> _captureImage() async {
    final controller = _cameraController;
    if (controller == null) return;
    try {
      final path = await _cameraService.capture(controller);
      if (path != null) await _recognizeImage(path);
    } catch (error, stackTrace) {
      debugPrint('Camera capture failed: $error\n$stackTrace');
      if (mounted) setState(() => _cameraErrorKey = L10nKeys.commonError);
    }
  }

  Future<void> _chooseImage() async {
    try {
      final path = await _cameraService.chooseFromGallery();
      if (path != null) await _recognizeImage(path);
    } catch (error, stackTrace) {
      debugPrint('Image selection failed: $error\n$stackTrace');
      if (mounted) setState(() => _cameraErrorKey = L10nKeys.commonError);
    }
  }

  Future<void> _recognizeImage(String path) async {
    setState(() {
      _cameraProcessing = true;
      _cameraErrorKey = null;
    });
    try {
      final recognized = await _ocrService.recognizeFile(path);
      if (recognized.trim().isEmpty) {
        if (mounted) {
          setState(() => _cameraErrorKey = L10nKeys.cameraNoText);
        }
        return;
      }
      final value = applyInsert(
        const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        ),
        recognized.characters.take(kMaxChars).toString(),
        kMaxChars,
      );
      _messageController.value = value;
    } catch (error, stackTrace) {
      debugPrint('Text recognition failed: $error\n$stackTrace');
      if (mounted) {
        setState(
          () => _cameraErrorKey = error is UnsupportedError
              ? L10nKeys.cameraOcrUnavailable
              : L10nKeys.commonError,
        );
      }
    } finally {
      if (mounted) setState(() => _cameraProcessing = false);
    }
  }

  Future<void> _clearAndStartOver() async {
    await _stopListening();
    await _disposeCamera();
    if (!mounted) return;
    context.read<SessionProvider>().clearInputAndResult();
    _messageController.clear();
    _messageFocusNode.requestFocus();
  }

  Future<void> _translateAndShowResult(SessionProvider session) async {
    await session.translate();
    if (mounted && session.result != null) {
      await Navigator.pushNamed(context, '/view-result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final source = _languageFor(session.sourceId);
    final target = _languageFor(session.targetId);
    final counterText = context.t(
      L10nKeys.inputCounter,
      args: {
        'count': '${_messageController.text.characters.length}',
        'max': '$kMaxChars',
      },
    );
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          const IslaAppBar(
            subtitle: 'Pagsasalin ng Wika · Language Translation',
            trailing: ScreenBackButton(
              tooltip: 'Back to language pair selection',
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ResponsiveCenter(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    Responsive.space(context, 16),
                    Responsive.space(context, 12),
                    Responsive.space(context, 16),
                    Responsive.space(context, 24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WelcomeBanner(
                        body: context.t(L10nKeys.bannerBodyInput),
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
                                context.t(L10nKeys.inputClear),
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
    final modeLabel = switch (session.inputMode) {
      'voice' => L10nKeys.inputLabelTranscript,
      'camera' => L10nKeys.inputLabelRecognized,
      _ => L10nKeys.inputLabelText,
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
          errorText:
              _voiceErrorKey == null ? null : _voiceErrorText(context, source),
          languageLabel: source.fieldLabel,
          onTap: _toggleListening,
        ),
      if (session.inputMode == 'camera')
        CameraInputPanel(
          controller: _cameraController,
          loading: _cameraLoading || _cameraProcessing,
          errorText:
              _cameraErrorKey == null ? null : context.t(_cameraErrorKey!),
          onCapture: _captureImage,
          onGallery: _chooseImage,
        ),
      SizedBox(height: Responsive.space(context, 16)),
      _SectionHeading(context.t(modeLabel)),
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
          context.t(L10nKeys.statusModelLoading),
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
                  context.t(session.errorKey!),
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
            context.t(L10nKeys.inputTitle),
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

  String _voiceErrorText(BuildContext context, Language source) {
    if (_voiceErrorKey == L10nKeys.voicePermissionDenied) {
      return context.t(L10nKeys.voicePermissionDenied);
    }
    if (_voiceErrorKey == L10nKeys.commonError) {
      return context.t(L10nKeys.commonError);
    }
    return context.t(
      L10nKeys.voiceUnavailable,
      args: {'language': source.fieldLabel},
    );
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
    final text = context.t(
      translating ? L10nKeys.inputTranslating : L10nKeys.inputTranslate,
    );
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
