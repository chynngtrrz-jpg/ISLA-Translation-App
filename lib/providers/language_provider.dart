import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/languages.dart';

/// Holds and persists the user's preferred interface language.
class LanguageProvider extends ChangeNotifier {
  LanguageProvider({required SharedPreferences preferences})
      : _preferences = preferences,
        _uiLanguage = _readInitialLanguage(preferences),
        _hasExplicitSelection = _hasStoredLanguage(preferences);

  static const String preferenceKey = 'ui_language';

  final SharedPreferences _preferences;
  String _uiLanguage;
  String get uiLanguage => _uiLanguage;
  bool _hasExplicitSelection;
  bool get hasExplicitSelection => _hasExplicitSelection;

  static String _readInitialLanguage(SharedPreferences preferences) {
    final storedLanguage = preferences.getString(preferenceKey);
    if (_isLanguageId(storedLanguage)) {
      return storedLanguage!;
    }
    return 'en';
  }

  static bool _hasStoredLanguage(SharedPreferences preferences) =>
      _isLanguageId(preferences.getString(preferenceKey));

  static bool _isLanguageId(String? languageId) =>
      languages.any((language) => language.id == languageId);

  Future<void> selectLanguage(String languageId) async {
    if (!_isLanguageId(languageId)) {
      return;
    }
    _uiLanguage = languageId;
    _hasExplicitSelection = true;
    notifyListeners();
    await _preferences.setString(preferenceKey, languageId);
  }
}
