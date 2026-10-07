import 'package:flutter/material.dart';

import '../../core/localization/isla_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Three equal-width controls for choosing how to enter a message.
class InputModeSelector extends StatelessWidget {
  const InputModeSelector({
    required this.mode,
    required this.onChanged,
    super.key,
  });

  final String mode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      ('text', context.t(L10nKeys.modeText), Icons.text_fields),
      ('voice', context.t(L10nKeys.modeVoice), Icons.mic_none),
      ('camera', context.t(L10nKeys.modeCamera), Icons.photo_camera_outlined),
    ];
    return Container(
      padding: EdgeInsets.all(Responsive.space(context, 6)),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(Responsive.space(context, 20)),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, 2),
                ),
                child: Semantics(
                  button: true,
                  selected: option.$1 == mode,
                  label: option.$2,
                  child: Material(
                    color: option.$1 == mode
                        ? AppColors.espresso
                        : AppColors.surface.withValues(alpha: 0),
                    borderRadius:
                        BorderRadius.circular(Responsive.space(context, 16)),
                    child: InkWell(
                      key: ValueKey('input-mode-${option.$1}'),
                      borderRadius:
                          BorderRadius.circular(Responsive.space(context, 16)),
                      onTap: () => onChanged(option.$1),
                      child: SizedBox(
                        height: Responsive.space(context, 44),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              option.$3,
                              size: Responsive.sp(context, 19),
                              color: option.$1 == mode
                                  ? AppColors.glacier
                                  : AppColors.espresso,
                            ),
                            SizedBox(width: Responsive.space(context, 4)),
                            Flexible(
                              child: Text(
                                option.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: option.$1 == mode
                                      ? AppColors.glacier
                                      : AppColors.espresso,
                                  fontSize: Responsive.sp(context, 16),
                                  fontWeight: FontWeight.w700,
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
            ),
        ],
      ),
    );
  }
}
