import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../core/constants/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/translation_result.dart';

/// Animated translated-text card with speech controls.
class TranslationResultCard extends StatelessWidget {
  const TranslationResultCard({
    required this.result,
    required this.speechAvailable,
    required this.approximateVoice,
    required this.isSpeaking,
    required this.onSpeak,
    super.key,
  });

  final TranslationResult? result;
  final bool speechAvailable;
  final bool approximateVoice;
  final bool isSpeaking;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final currentResult = result;
    return AnimatedSize(
      duration:
          disableAnimations ? Duration.zero : const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 200),
        opacity: currentResult == null ? 0 : 1,
        child: currentResult == null
            ? const SizedBox.shrink()
            : _resultContent(context, currentResult),
      ),
    );
  }

  Widget _resultContent(BuildContext context, TranslationResult result) {
    final app = AppLocalizations.of(context)!;
    final tooltip = !speechAvailable
        ? app.resultSpeakUnavailable
        : approximateVoice
            ? app.resultSpeakApprox
            : app.resultSpeak;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(app.resultLabel),
        SizedBox(height: Responsive.space(context, 8)),
        Container(
          padding: EdgeInsets.all(Responsive.space(context, 18)),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(Responsive.space(context, 20)),
            border: Border.all(
              color: AppColors.clay,
              width: Responsive.space(context, 2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: SelectableText(
                    result.text,
                    style: TextStyle(
                      color: AppColors.espresso,
                      fontSize: Responsive.sp(context, 18),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              SizedBox(width: Responsive.space(context, 8)),
              Tooltip(
                message: tooltip,
                child: Semantics(
                  button: true,
                  label: tooltip,
                  child: SizedBox(
                    width: Responsive.space(context, 48),
                    height: Responsive.space(context, 48),
                    child: IconButton(
                      onPressed: speechAvailable ? onSpeak : null,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.espresso,
                        foregroundColor: AppColors.glacier,
                        disabledBackgroundColor: AppColors.espresso,
                        disabledForegroundColor: AppColors.clay,
                      ),
                      icon: Icon(
                        isSpeaking ? Icons.stop : Icons.volume_up,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (kShowResultSource) ...[
          SizedBox(height: Responsive.space(context, 8)),
          Text(
            result.origin == TranslationOrigin.phrasebook
                ? app.resultSourcePhrasebook
                : app.resultSourceModel,
            style: TextStyle(
              color: AppColors.espresso,
              fontSize: Responsive.sp(context, 14),
            ),
          ),
        ],
      ],
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
          letterSpacing: 1.5,
        ),
      );
}