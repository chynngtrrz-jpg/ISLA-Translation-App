import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Accessible tappable field that opens a language picker sheet.
class LanguageField extends StatelessWidget {
  const LanguageField({
    required this.fieldName,
    required this.value,
    required this.onTap,
    required this.focusNode,
    super.key,
  });

  final String fieldName;
  final String value;
  final VoidCallback onTap;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: '$fieldName, $value. Double tap to change.',
      child: Material(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(Responsive.space(context, 20)),
        child: InkWell(
          key: ValueKey('$fieldName-language-field'),
          focusNode: focusNode,
          onTap: onTap,
          borderRadius: BorderRadius.circular(Responsive.space(context, 20)),
          child: Container(
            constraints: BoxConstraints(
              minHeight: Responsive.space(context, 52),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, 16),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Responsive.space(context, 20)),
              border: Border.all(
                color: AppColors.chambray,
                width: Responsive.space(context, 2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    child: Text(
                      value,
                      key: ValueKey(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.espresso,
                        fontSize: Responsive.sp(context, 18),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.espresso,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
