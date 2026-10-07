import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Circular swap action with rotation animation and an accessible tooltip.
class SwapButton extends StatefulWidget {
  const SwapButton({required this.onSwap, super.key});

  final bool Function() onSwap;

  @override
  State<SwapButton> createState() => _SwapButtonState();
}

class _SwapButtonState extends State<SwapButton> {
  bool _isReversed = false;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Tooltip(
      message: 'Swap source and target languages',
      child: Semantics(
        button: true,
        label: 'Swap source and target languages',
        child: Material(
          color: AppColors.bisque,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {
              if (widget.onSwap()) {
                setState(() => _isReversed = !_isReversed);
              }
            },
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: Responsive.space(context, 48),
              height: Responsive.space(context, 48),
              child: Center(
                child: AnimatedRotation(
                  turns: _isReversed ? 0.5 : 0,
                  duration: disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.swap_vert,
                    color: AppColors.espresso,
                    size: Responsive.sp(context, 24),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
