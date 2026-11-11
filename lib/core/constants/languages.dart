import '../../data/models/language.dart';
import '../theme/app_colors.dart';

// No native recognizer exists for ini, onh, and asi, so the Filipino
// recognizer is used as the closest available engine.
const String _fallbackSttLocale = 'fil_PH';

/// Editable list of interface-language choices shown on the selection screen.
const List<Language> languages = [
  Language(
    id: 'en',
    name: 'English',
    fieldLabel: 'English',
    greeting: 'Good day!',
    fillColor: AppColors.chambray,
    textColor: AppColors.espresso,
    sttLocale: 'en_US',
    ttsLocale: 'en-US',
  ),
  Language(
    id: 'fil',
    name: 'Tagalog',
    fieldLabel: 'Tagalog',
    greeting: 'Magandang Araw!',
    fillColor: AppColors.bisque,
    textColor: AppColors.espresso,
    sttLocale: 'fil_PH',
    ttsLocale: 'fil-PH',
  ),
  Language(
    id: 'ini',
    name: 'Ini (Romblomanon)',
    fieldLabel: 'Ini (Romblomanon)',
    greeting: 'Maayong Adlaw!',
    fillColor: AppColors.glacier,
    textColor: AppColors.espresso,
    borderColor: AppColors.chambray,
    sttFallbackLocale: _fallbackSttLocale,
    ttsLocale: 'fil-PH',
    ttsApproximate: true,
  ),
  Language(
    id: 'onh',
    name: 'Onhan',
    fieldLabel: 'Onhan',
    greeting: 'Maayong Adlaw!',
    fillColor: AppColors.clay,
    textColor: AppColors.onClay,
    sttFallbackLocale: _fallbackSttLocale,
    ttsLocale: 'fil-PH',
    ttsApproximate: true,
  ),
  Language(
    id: 'asi',
    name: 'Asi (Bantoanon)',
    fieldLabel: 'Asi (Bantoanon)',
    greeting: 'Maado nga Adlaw!',
    fillColor: AppColors.espresso,
    textColor: AppColors.bisque,
    sttFallbackLocale: _fallbackSttLocale,
    ttsLocale: 'fil-PH',
    ttsApproximate: true,
  ),
];
