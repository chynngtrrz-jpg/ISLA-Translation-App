import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/isla_localizations.dart';
import 'providers/language_provider.dart';
import 'ui/screens/input_translate_screen.dart';
import 'ui/screens/language_selection_screen.dart';
import 'ui/screens/select_languages_screen.dart';
import 'ui/screens/view_result_screen.dart';

/// Application routes for the ISLA language-selection flow.
class IslaApp extends StatelessWidget {
  const IslaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageId = context.watch<LanguageProvider>().uiLanguage;
    return MaterialApp(
      title: 'ISLA',
      theme: AppTheme.light,
      locale: Locale(languageId),
      localizationsDelegates: const [
        IslaLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fil'),
        Locale('ini'),
        Locale('onh'),
        Locale('asi'),
      ],
      initialRoute: '/',
      routes: {
        '/': (_) => const _LandingScreen(),
        '/language': (_) => const LanguageSelectionScreen(),
        '/select-languages': (_) => const SelectLanguagesScreen(),
        '/input-translate': (_) => const InputTranslateScreen(),
        '/view-result': (_) => const ViewResultScreen(),
      },
    );
  }
}

/// Minimal landing screen; Get Started replaces it with language selection.
class _LandingScreen extends StatelessWidget {
  const _LandingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.espresso,
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/language'),
          child: const Text('Get Started'),
        ),
      ),
    );
  }
}
