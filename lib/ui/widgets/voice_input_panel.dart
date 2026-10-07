import 'package:flutter/material.dart';

import '../../core/localization/isla_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Voice capture control and state feedback.
class VoiceInputPanel extends StatefulWidget {
  const VoiceInputPanel({
    required this.available,
    required this.listening,
    required this.processing,
    required this.errorText,
    required this.languageLabel,
    required this.onTap,
    super.key,
  });

  final bool available;
  final bool listening;
  final bool processing;
  final String? errorText;
  final String languageLabel;
  final VoidCallback onTap;

  @override
  State<VoiceInputPanel> createState() => _VoiceInputPanelState();
}

class _VoiceInputPanelState extends State<VoiceInputPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(covariant VoiceInputPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listening && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.listening && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unavailable = !widget.available;
    final caption = widget.processing
        ? context.t(L10nKeys.voiceProcessing)
        : widget.listening
            ? context.t(L10nKeys.voiceListening)
            : unavailable
                ? context.t(
                    L10nKeys.voiceUnavailable,
                    args: {'language': widget.languageLabel},
                  )
                : context.t(L10nKeys.voiceIdle);
    return Column(
      children: [
        SizedBox(height: Responsive.space(context, 8)),
        SizedBox(
          width: Responsive.space(context, 92),
          height: Responsive.space(context, 92),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.listening)
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) => Container(
                    width:
                        Responsive.space(context, 82 + _pulse.value * 10),
                    height:
                        Responsive.space(context, 82 + _pulse.value * 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.clay.withValues(
                        alpha: 0.3 * (1 - _pulse.value * 0.5),
                      ),
                    ),
                  ),
                ),
              Semantics(
                button: true,
                enabled: !unavailable && !widget.processing,
                label: caption,
                child: SizedBox(
                  width: Responsive.space(context, 72),
                  height: Responsive.space(context, 72),
                  child: IconButton(
                    onPressed: unavailable || widget.processing
                        ? null
                        : widget.onTap,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.chambray,
                      foregroundColor: AppColors.espresso,
                      disabledBackgroundColor:
                          AppColors.chambray.withValues(alpha: 0.4),
                    ),
                    icon: Icon(
                      widget.listening ? Icons.stop : Icons.mic,
                      size: Responsive.sp(context, 32),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.space(context, 8)),
        Text(
          widget.errorText ?? caption,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.espresso,
            fontSize: Responsive.sp(context, 14),
          ),
        ),
      ],
    );
  }
}
