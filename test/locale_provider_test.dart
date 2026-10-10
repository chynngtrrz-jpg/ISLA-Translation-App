import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:isla_app/providers/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads and persists the saved supported locale', () async {
    SharedPreferences.setMockInitialValues({'ui_locale': 'tl'});
    final preferences = await SharedPreferences.getInstance();
    final provider = LocaleProvider(preferences: preferences);

    await provider.loadSavedLocale();

    expect(provider.locale, const Locale('tl'));
    expect(provider.hasExplicitSelection, isFalse);

    await provider.setLocale(const Locale('en'));

    expect(provider.locale, const Locale('en'));
    expect(provider.hasExplicitSelection, isTrue);
    expect(preferences.getString('ui_locale'), 'en');
  });

  test('loads and persists Romblomanon locale', () async {
    SharedPreferences.setMockInitialValues({'ui_locale': 'rol'});
    final preferences = await SharedPreferences.getInstance();
    final provider = LocaleProvider(preferences: preferences);

    await provider.loadSavedLocale();
    expect(provider.locale, const Locale('rol'));
    expect(provider.hasExplicitSelection, isFalse);

    await provider.setLocale(const Locale('rol'));
    expect(provider.locale, const Locale('rol'));
    expect(provider.hasExplicitSelection, isTrue);
    expect(preferences.getString('ui_locale'), 'rol');
  });

  test('loads and persists Bantoanon locale', () async {
    SharedPreferences.setMockInitialValues({'ui_locale': 'bno'});
    final preferences = await SharedPreferences.getInstance();
    final provider = LocaleProvider(preferences: preferences);

    await provider.loadSavedLocale();
    expect(provider.locale, const Locale('bno'));
    expect(provider.hasExplicitSelection, isFalse);

    await provider.setLocale(const Locale('bno'));
    expect(provider.locale, const Locale('bno'));
    expect(provider.hasExplicitSelection, isTrue);
    expect(preferences.getString('ui_locale'), 'bno');
  });

  test('loads and persists Onhan locale', () async {
    SharedPreferences.setMockInitialValues({'ui_locale': 'loc'});
    final preferences = await SharedPreferences.getInstance();
    final provider = LocaleProvider(preferences: preferences);

    await provider.loadSavedLocale();
    expect(provider.locale, const Locale('loc'));
    expect(provider.hasExplicitSelection, isFalse);

    await provider.setLocale(const Locale('loc'));
    expect(provider.locale, const Locale('loc'));
    expect(provider.hasExplicitSelection, isTrue);
    expect(preferences.getString('ui_locale'), 'loc');
  });

  test('unsupported saved and requested locales fall back to English',
      () async {
    SharedPreferences.setMockInitialValues({'ui_locale': 'zzz'});
    final preferences = await SharedPreferences.getInstance();
    final provider = LocaleProvider(preferences: preferences);

    await provider.loadSavedLocale();
    expect(provider.locale, const Locale('en'));

    await provider.setLocale(const Locale('fil'));
    expect(provider.locale, const Locale('en'));
    expect(preferences.getString('ui_locale'), 'en');
  });
}
