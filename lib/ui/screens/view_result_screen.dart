import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/languages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/language.dart';
import '../../data/services/tts_service.dart';
import '../../providers/session_provider.dart';
import '../widgets/isla_app_bar.dart';
import '../widgets/screen_back_button.dart';
import '../widgets/step_indicator.dart';
import '../widgets/translation_result_card.dart';

class ViewResultScreen extends StatefulWidget {
  const ViewResultScreen({this.ttsService, super.key});

  final TtsService? ttsService;

  @override
  State<ViewResultScreen> createState() => _ViewResultScreenState();
}

class _ViewResultScreenState extends State<ViewResultScreen> {
  late final TtsService _ttsService =
      widget.ttsService ?? DeviceTtsService();
  bool _ttsAvailable = false;
  bool _speaking = false;
  String? _checkedTtsLocale;

  Language _languageFor(String id) =>
      languages.firstWhere((language) => language.id == id);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final target = _languageFor(context.watch<SessionProvider>().targetId);
    if (target.ttsLocale != _checkedTtsLocale) {
      _checkedTtsLocale = target.ttsLocale;
      unawaited(_checkTtsAvailability(target.ttsLocale));
    }
  }

  @override
  void dispose() {
    unawaited(_ttsService.stop());
    super.dispose();
  }

  Future<void> _checkTtsAvailability(String? locale) async {
    if (locale == null) {
      if (mounted) setState(() => _ttsAvailable = false);
      return;
    }
    try {
      final available = await _ttsService.isLanguageAvailable(locale);
      if (mounted && _checkedTtsLocale == locale) {
        setState(() => _ttsAvailable = available);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Text-to-speech availability check failed: $error\n$stackTrace',
      );
      if (mounted && _checkedTtsLocale == locale) {
        setState(() => _ttsAvailable = false);
      }
    }
  }

  Future<void> _toggleSpeaking(SessionProvider session) async {
    if (_speaking) {
      await _stopSpeaking();
      return;
    }
    final result = session.result;
    final target = _languageFor(session.targetId);
    final locale = target.ttsLocale;
    if (!_ttsAvailable || result == null || locale == null) return;

    setState(() => _speaking = true);
    try {
      await _ttsService.speak(result.text, locale);
    } catch (error, stackTrace) {
      debugPrint('Text-to-speech playback failed: $error\n$stackTrace');
      if (mounted) setState(() => _ttsAvailable = false);
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<void> _stopSpeaking() async {
    await _ttsService.stop();
    if (mounted) setState(() => _speaking = false);
  }

  void _translateAnother() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed('/input-translate');
    }
  }

  void _startOver(SessionProvider session) {
    session.reset();
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/select-languages',
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final result = session.result;
    final source = _languageFor(session.sourceId);
    final target = _languageFor(session.targetId);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          const IslaAppBar(
            subtitle: 'Pagsasalin ng Wika · Language Translation',
            trailing: ScreenBackButton(
              tooltip: 'Back to input and translation',
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ResponsiveCenter(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.space(context, 16),
                    Responsive.space(context, 12),
                    Responsive.space(context, 16),
                    Responsive.space(context, 24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ResultBanner(
                        title: 'Translation Result',
                        body: 'Review your translation below.',
                      ),
                      SizedBox(height: Responsive.space(context, 16)),
                      const StepIndicator(currentStep: 3),
                      SizedBox(height: Responsive.space(context, 20)),
                      if (result == null)
                        _NoResultCard(onBack: _translateAnother)
                      else ...[
                        _OriginalTextCard(
                          languageLabel: source.fieldLabel,
                          text: session.inputText,
                        ),
                        SizedBox(height: Responsive.space(context, 16)),
                        Container(
                          padding: EdgeInsets.all(Responsive.space(context, 16)),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, 24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.espresso.withValues(
                                  alpha: 0.12,
                                ),
                                blurRadius: Responsive.space(context, 16),
                                offset: Offset(
                                  0,
                                  Responsive.space(context, 4),
                                ),
                              ),
                            ],
                          ),
                          child: TranslationResultCard(
                            result: result,
                            speechAvailable:
                                _ttsAvailable && target.ttsLocale != null,
                            approximateVoice: target.ttsApproximate,
                            isSpeaking: _speaking,
                            onSpeak: () => _toggleSpeaking(session),
                          ),
                        ),
                        SizedBox(height: Responsive.space(context, 20)),
                        _ActionButton(
                          label: 'Translate Another',
                          onPressed: _translateAnother,
                          backgroundColor: AppColors.chambray,
                        ),
                        SizedBox(height: Responsive.space(context, 12)),
                        _ActionButton(
                          label: 'Start Over',
                          onPressed: () => _startOver(session),
                          backgroundColor: AppColors.glacier,
                        ),
                      ],
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
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.bisque,
        borderRadius: BorderRadius.circular(Responsive.space(context, 20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.espresso,
              fontSize: Responsive.sp(context, 20),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: Responsive.space(context, 8)),
          Text(
            body,
            style: TextStyle(
              color: AppColors.espresso,
              fontSize: Responsive.sp(context, 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _OriginalTextCard extends StatelessWidget {
  const _OriginalTextCard({
    required this.languageLabel,
    required this.text,
  });

  final String languageLabel;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Responsive.space(context, 20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORIGINAL · $languageLabel',
            style: TextStyle(
              color: AppColors.espresso,
              fontSize: Responsive.sp(context, 14),
              fontWeight: FontWeight.w700,
              letterSpacing: Responsive.space(context, 1.2),
            ),
          ),
          SizedBox(height: Responsive.space(context, 8)),
          SelectableText(
            text,
            style: TextStyle(
              color: AppColors.espresso,
              fontSize: Responsive.sp(context, 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResultCard extends StatelessWidget {
  const _NoResultCard({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.space(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Responsive.space(context, 20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'No translation yet',
            style: TextStyle(
              color: AppColors.espresso,
              fontSize: Responsive.sp(context, 18),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: Responsive.space(context, 12)),
          _ActionButton(
            label: 'Back to Input',
            onPressed: onBack,
            backgroundColor: AppColors.chambray,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Responsive.space(context, 48),
      child: Material(
        color: backgroundColor,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.espresso,
                fontSize: Responsive.sp(context, 16),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
