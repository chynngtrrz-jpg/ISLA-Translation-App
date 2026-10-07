import 'package:flutter/material.dart';

import '../../core/localization/isla_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/language.dart';

/// Shows the selected translation direction and returns to the language picker.
class LanguagePairBar extends StatelessWidget {
  const LanguagePairBar({
    required this.source,
    required this.target,
    super.key,
  });

  final Language source;
  final Language target;

  void _change(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(
        '/select-languages',
        arguments: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Responsive.space(context, 16),
      runSpacing: Responsive.space(context, 8),
      children: [
        Semantics(
          label: '${source.fieldLabel} to ${target.fieldLabel}',
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, 16),
              vertical: Responsive.space(context, 10),
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.all(
                Radius.circular(Responsive.space(context, 24)),
              ),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppColors.espresso,
                  fontSize: Responsive.sp(context, 16),
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(text: source.fieldLabel),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(context, 6),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.espresso,
                        size: Responsive.sp(context, 18),
                      ),
                    ),
                  ),
                  TextSpan(text: target.fieldLabel),
                ],
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: context.t(L10nKeys.inputChange),
          child: SizedBox(
            height: Responsive.space(context, 48),
            child: TextButton(
              onPressed: () => _change(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, 4),
                ),
                foregroundColor: AppColors.espresso,
                textStyle: TextStyle(
                  fontSize: Responsive.sp(context, 16),
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                ),
              ),
              child: Text(context.t(L10nKeys.inputChange)),
            ),
          ),
        ),
      ],
    );
  }
}
