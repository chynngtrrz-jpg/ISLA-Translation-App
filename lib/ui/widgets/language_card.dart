import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/language.dart';

/// Tappable language choice with a persistent visual identity and selection border.
class LanguageCard extends StatelessWidget {
  const LanguageCard({
    required this.language,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final Language language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final selectedBorderColor =
        language.id == 'asi' ? AppColors.bisque : AppColors.espresso;
    final radius = Responsive.space(context, 24);
    final border = isSelected
        ? Border.all(color: selectedBorderColor, width: 3)
        : language.borderColor == null
            ? null
            : Border.all(color: language.borderColor!, width: 2);

    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      label: '${language.name}, ${language.greeting}',
      child: AnimatedContainer(
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 200),
        constraints: BoxConstraints(minHeight: Responsive.space(context, 80)),
        decoration: BoxDecoration(
          color: language.fillColor,
          borderRadius: BorderRadius.circular(radius),
          border: border,
        ),
        child: Material(
          color: language.fillColor,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.space(context, 20),
                vertical: Responsive.space(context, 12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: TextStyle(
                            color: language.textColor,
                            fontSize: Responsive.sp(context, 22),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          language.greeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: TextStyle(
                            color: language.textColor,
                            // Onhan white on clay is 4.2:1; bold large text is the specified exception.
                            fontSize: Responsive.sp(context, 16),
                            fontWeight: language.id == 'onh'
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: isSelected
                        ? [
                            Icon(
                              Icons.check,
                              size: Responsive.sp(context, 18),
                              color: language.textColor,
                            ),
                          ]
                        : [
                            Text(
                              app.selectLanguage,
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                color: language.textColor,
                                fontSize: Responsive.sp(context, 16),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                left: Responsive.space(context, 4),
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                size: Responsive.sp(context, 18),
                                color: language.textColor,
                              ),
                            ),
                          ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
