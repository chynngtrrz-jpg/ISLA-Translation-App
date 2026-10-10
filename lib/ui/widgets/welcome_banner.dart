import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Introductory banner for the language-pair selection flow.
class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({required this.body, super.key});

  final String body;

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
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
            app.welcomeTitle,
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
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}