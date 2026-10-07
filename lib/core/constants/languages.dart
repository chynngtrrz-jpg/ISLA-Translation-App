import '../../data/models/language.dart';
import '../theme/app_colors.dart';

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
    name: 'Filipino',
    fieldLabel: 'Filipino',
    greeting: 'Magandang Araw!',
    fillColor: AppColors.bisque,
    textColor: AppColors.espresso,
    sttLocale: 'fil_PH',
    ttsLocale: 'fil-PH',
  ),
  Language(
    id: 'ini',
    name: 'Romblomanon (Ini)',
    fieldLabel: 'Ini (Romblomanon)',
    greeting: 'Maayong Adlaw!',
    fillColor: AppColors.glacier,
    textColor: AppColors.espresso,
    borderColor: AppColors.chambray,
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
    ttsLocale: 'fil-PH',
    ttsApproximate: true,
  ),
];
