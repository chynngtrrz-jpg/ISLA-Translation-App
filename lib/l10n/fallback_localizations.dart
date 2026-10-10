import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const Set<String> _englishFallbackLocaleCodes = {'rol', 'bno', 'loc'};

class EnglishFallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const EnglishFallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      _englishFallbackLocaleCodes.contains(locale.languageCode);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(EnglishFallbackMaterialLocalizationsDelegate old) => false;
}

class EnglishFallbackWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const EnglishFallbackWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      _englishFallbackLocaleCodes.contains(locale.languageCode);

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(EnglishFallbackWidgetsLocalizationsDelegate old) => false;
}

class EnglishFallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const EnglishFallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      _englishFallbackLocaleCodes.contains(locale.languageCode);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(EnglishFallbackCupertinoLocalizationsDelegate old) => false;
}
