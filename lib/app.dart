import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'l10n/fallback_localizations.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/responsive.dart';
import 'providers/locale_provider.dart';
import 'ui/screens/input_translate_screen.dart';
import 'ui/screens/language_selection_screen.dart';
import 'ui/screens/select_languages_screen.dart';
import 'ui/screens/view_result_screen.dart';

/// Application routes for the ISLA language-selection flow.
class IslaApp extends StatelessWidget {
  const IslaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISLA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: context.watch<LocaleProvider>().locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        EnglishFallbackMaterialLocalizationsDelegate(),
        EnglishFallbackWidgetsLocalizationsDelegate(),
        EnglishFallbackCupertinoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
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
class _LandingScreen extends StatefulWidget {
  const _LandingScreen();

  @override
  State<_LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<_LandingScreen> {
  static const _mascot = AssetImage('assets/images/isla_icon.png');
  static const _wordmark = AssetImage('assets/images/isla_wordmark.png');
  static const _linguaTech = AssetImage('assets/images/linguatech.png');
  bool _didPrecacheImages = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheImages) return;
    _didPrecacheImages = true;
    unawaited(precacheImage(_mascot, context));
    unawaited(precacheImage(_wordmark, context));
    unawaited(precacheImage(_linguaTech, context));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mascotWidth =
                (constraints.maxWidth * 0.38).clamp(0.0, 260.0).toDouble();
            final wordmarkWidth =
                (constraints.maxWidth * 0.58).clamp(0.0, 440.0).toDouble();
            final linguaTechWidth =
                (constraints.maxWidth * 0.42).clamp(0.0, 260.0).toDouble();

            return Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, contentConstraints) =>
                        SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(context, 16),
                        vertical: Responsive.space(context, 12),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (contentConstraints.maxHeight -
                                  Responsive.space(context, 24))
                              .clamp(0.0, double.infinity)
                              .toDouble(),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image(
                                image: _mascot,
                                width: mascotWidth,
                                fit: BoxFit.contain,
                                semanticLabel: app.landingMascotSemantics,
                              ),
                              SizedBox(
                                height: Responsive.space(context, 20),
                              ),
                              Image(
                                image: _wordmark,
                                width: wordmarkWidth,
                                fit: BoxFit.contain,
                                semanticLabel: app.landingLogoSemantics,
                              ),
                              SizedBox(
                                height: Responsive.space(context, 16),
                              ),
                              Semantics(
                                label: 'by LinguaTech',
                                child: ExcludeSemantics(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'by',
                                        style: TextStyle(
                                          color: Color(0xFF809AB4),
                                          fontFamily: 'Alegreya',
                                          fontSize: 20,
                                        ),
                                      ),
                                      SizedBox(
                                        width: Responsive.space(context, 8),
                                      ),
                                      Image(
                                        image: _linguaTech,
                                        width: linguaTechWidth,
                                        fit: BoxFit.contain,
                                      ),
                                    ],
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
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.space(context, 16),
                    Responsive.space(context, 8),
                    Responsive.space(context, 16),
                    Responsive.space(context, 24),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SizedBox(
                      width: double.infinity,
                      height: Responsive.space(context, 52)
                          .clamp(48.0, double.infinity)
                          .toDouble(),
                      child: Semantics(
                        button: true,
                        label: app.getStarted,
                        child: FilledButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            '/language',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.chambray,
                            foregroundColor: AppColors.espresso,
                            shape: const StadiumBorder(),
                            padding: EdgeInsets.zero,
                            textStyle: TextStyle(
                              fontFamily: 'Alegreya',
                              fontSize: Responsive.sp(context, 18),
                              fontWeight: FontWeight.w500,
                              letterSpacing: Responsive.space(context, 0.8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(app.getStarted),
                              SizedBox(width: Responsive.space(context, 8)),
                              const Icon(Icons.arrow_forward),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
