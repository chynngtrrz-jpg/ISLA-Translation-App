import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class ScreenBackButton extends StatelessWidget {
  const ScreenBackButton({required this.tooltip, super.key});

  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () => Navigator.of(context).pop(),
      icon: Icon(
        Icons.arrow_back,
        color: AppColors.glacier,
        size: Responsive.sp(context, 24),
      ),
    );
  }
}
