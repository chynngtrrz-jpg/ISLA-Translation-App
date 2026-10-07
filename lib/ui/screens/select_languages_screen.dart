import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/languages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/language.dart';
import '../../providers/language_provider.dart';
import '../../providers/session_provider.dart';
import '../widgets/isla_app_bar.dart';
import '../widgets/language_field.dart';
import '../widgets/language_picker_sheet.dart';
import '../widgets/screen_back_button.dart';
import '../widgets/step_indicator.dart';
import '../widgets/swap_button.dart';
import '../widgets/welcome_banner.dart';

/// Lets the user choose a supported source and target language pair.
class SelectLanguagesScreen extends StatefulWidget {
  const SelectLanguagesScreen({super.key});

  @override
  State<SelectLanguagesScreen> createState() => _SelectLanguagesScreenState();
}

class _SelectLanguagesScreenState extends State<SelectLanguagesScreen> {
  final FocusNode _sourceFocusNode = FocusNode();
  final FocusNode _targetFocusNode = FocusNode();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final preservePair = ModalRoute.of(context)?.settings.arguments == true;
      if (!preservePair) {
        final uiLanguageId = context.read<LanguageProvider>().uiLanguage;
        context.read<SessionProvider>().initFromUiLanguage(uiLanguageId);
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _sourceFocusNode.dispose();
    _targetFocusNode.dispose();
    super.dispose();
  }

  Language _languageFor(String id) =>
      languages.firstWhere((language) => language.id == id);

  Future<void> _openPicker({required bool isSource}) async {
    final session = context.read<SessionProvider>();
    final focusNode = isSource ? _sourceFocusNode : _targetFocusNode;
    await LanguagePickerSheet.show(
      context: context,
      title: isSource ? 'Source language' : 'Target language',
      selectedId: isSource ? session.sourceId : session.targetId,
      otherId: isSource ? session.targetId : session.sourceId,
      isSource: isSource,
      isPairSupported: session.supportsPair,
      onSelected: isSource ? session.setSource : session.setTarget,
    );
    if (mounted) focusNode.requestFocus();
  }

  bool _swapLanguages() {
    final swapped = context.read<SessionProvider>().swap();
    if (!swapped) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This direction is not available.')),
      );
    }
    return swapped;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final source = _languageFor(session.sourceId);
    final target = _languageFor(session.targetId);
    final isValid = session.isValid;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          const IslaAppBar(
            subtitle: 'Pagsasalin ng Wika · Language Translation',
            trailing: ScreenBackButton(
              tooltip: 'Back to language selection',
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ResponsiveCenter(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.space(context, 16),
                    Responsive.space(context, 12),
                    Responsive.space(context, 16),
                    Responsive.space(context, 24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const WelcomeBanner(),
                      SizedBox(height: Responsive.space(context, 16)),
                      const StepIndicator(currentStep: 1),
                      SizedBox(height: Responsive.space(context, 16)),
                      Container(
                        padding: EdgeInsets.all(Responsive.space(context, 16)),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, 24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.espresso.withValues(alpha: 0.12),
                              blurRadius: Responsive.space(context, 16),
                              offset: Offset(0, Responsive.space(context, 4)),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Select Languages',
                              style: TextStyle(
                                color: AppColors.espresso,
                                fontSize: Responsive.sp(context, 22),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: Responsive.space(context, 16)),
                            const _FieldHeading('SOURCE LANGUAGE'),
                            SizedBox(height: Responsive.space(context, 8)),
                            LanguageField(
                              key: const ValueKey('source-language-field'),
                              fieldName: 'Source language',
                              value: source.fieldLabel,
                              focusNode: _sourceFocusNode,
                              onTap: () => _openPicker(isSource: true),
                            ),
                            SizedBox(height: Responsive.space(context, 12)),
                            Center(child: SwapButton(onSwap: _swapLanguages)),
                            SizedBox(height: Responsive.space(context, 12)),
                            const _FieldHeading('TARGET LANGUAGE'),
                            SizedBox(height: Responsive.space(context, 8)),
                            LanguageField(
                              key: const ValueKey('target-language-field'),
                              fieldName: 'Target language',
                              value: target.fieldLabel,
                              focusNode: _targetFocusNode,
                              onTap: () => _openPicker(isSource: false),
                            ),
                            SizedBox(height: Responsive.space(context, 20)),
                            Semantics(
                              button: true,
                              enabled: isValid,
                              label: isValid ? 'Next' : 'Next, disabled',
                              child: SizedBox(
                                height: Responsive.space(context, 52),
                                child: Material(
                                  color: AppColors.chambray.withValues(
                                    alpha: isValid ? 1 : 0.4,
                                  ),
                                  shape: const StadiumBorder(),
                                  child: InkWell(
                                    onTap: isValid
                                        ? () => Navigator.pushNamed(
                                              context,
                                              '/input-translate',
                                            )
                                        : null,
                                    customBorder: const StadiumBorder(),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Next',
                                          style: TextStyle(
                                            color: AppColors.espresso.withValues(
                                              alpha: isValid ? 1 : 0.6,
                                            ),
                                            fontSize:
                                                Responsive.sp(context, 18),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(
                                          width: Responsive.space(context, 8),
                                        ),
                                        Icon(
                                          Icons.arrow_forward,
                                          color: AppColors.espresso.withValues(
                                            alpha: isValid ? 1 : 0.6,
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
                      ),
                      SizedBox(height: Responsive.space(context, 12)),
                      SizedBox(
                        height: Responsive.space(context, 46),
                        child: Material(
                          color: AppColors.glacier,
                          shape: const StadiumBorder(),
                          child: InkWell(
                            onTap: session.reset,
                            customBorder: const StadiumBorder(),
                            child: Center(
                              child: Text(
                                'Clear & Start Over',
                                style: TextStyle(
                                  color: AppColors.espresso,
                                  fontSize: Responsive.sp(context, 16),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
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

class _FieldHeading extends StatelessWidget {
  const _FieldHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.espresso,
        fontSize: Responsive.sp(context, 14),
        fontWeight: FontWeight.w700,
        letterSpacing: Responsive.space(context, 1.5),
      ),
    );
  }
}
