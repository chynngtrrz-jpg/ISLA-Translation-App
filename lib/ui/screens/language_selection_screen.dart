import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/languages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/language_provider.dart';
import '../widgets/isla_app_bar.dart';
import '../widgets/language_card.dart';

/// Interface-language selection shown immediately after the landing screen.
class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Future<void> _selectLanguage(
    BuildContext context,
    LanguageProvider provider,
    String languageId,
  ) async {
    await provider.selectLanguage(languageId);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (context.mounted) {
      Navigator.pushNamed(context, '/select-languages');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          const IslaAppBar(),
          Expanded(
            child: SafeArea(
              top: false,
              child: ResponsiveCenter(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, 20),
                    vertical: Responsive.space(context, 24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: Responsive.space(context, 56),
                          height: Responsive.space(context, 56),
                          decoration: BoxDecoration(
                            color: AppColors.bisque,
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, 16),
                            ),
                          ),
                          child: Icon(
                            Icons.language,
                            color: AppColors.espresso,
                            size: Responsive.sp(context, 28),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.space(context, 16)),
                      Text(
                        'Piliin ang inyong wika',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.espresso,
                          fontSize: Responsive.sp(context, 26),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: Responsive.space(context, 12)),
                      Text(
                        'Choose the language you are most comfortable with. '
                        'Pumili ng wika. Pagpili wika. Pili it wika.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.espresso,
                          fontSize: Responsive.sp(context, 16),
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: Responsive.space(context, 24)),
                      for (var index = 0; index < languages.length; index++) ...[
                        if (index > 0)
                          SizedBox(height: Responsive.space(context, 12)),
                        LanguageCard(
                          language: languages[index],
                          isSelected: provider.hasExplicitSelection &&
                              provider.uiLanguage == languages[index].id,
                          onTap: () => _selectLanguage(
                            context,
                            provider,
                            languages[index].id,
                          ),
                        ),
                      ],
                      SizedBox(height: Responsive.space(context, 16)),
                      Text(
                        'You can change the language at any time during your session.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.espresso,
                          fontSize: Responsive.sp(context, 14),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
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