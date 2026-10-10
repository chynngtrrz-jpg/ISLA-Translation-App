import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider({required SharedPreferences preferences})
      : _preferences = preferences;

  static const String preferenceKey = 'ui_locale';
  static const Locale _english = Locale('en');

  final SharedPreferences _preferences;
  Locale _locale = _english;
  bool _hasExplicitSelection = false;

  Locale get locale => _locale;
  bool get hasExplicitSelection => _hasExplicitSelection;

  Future<void> loadSavedLocale() async {
    final languageCode = _preferences.getString(preferenceKey);
    _hasExplicitSelection = false;
    _locale = _supportedLocale(languageCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    final isSupported = locale.languageCode == 'en' ||
        locale.languageCode == 'tl' ||
        locale.languageCode == 'rol' ||
        locale.languageCode == 'bno' ||
        locale.languageCode == 'loc';
    _locale = _supportedLocale(locale.languageCode);
    _hasExplicitSelection = isSupported;
    notifyListeners();
    await _preferences.setString(preferenceKey, _locale.languageCode);
  }

  static Locale _supportedLocale(String? languageCode) {
    return switch (languageCode) {
      'tl' => const Locale('tl'),
      'rol' => const Locale('rol'),
      'bno' => const Locale('bno'),
      'loc' => const Locale('loc'),
      'en' => const Locale('en'),
      _ => _english,
    };
  }
}
