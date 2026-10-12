import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants/app_config.dart';
import 'data/phrasebook/phrasebook.dart';
import 'data/services/mock_translator_service.dart';
import 'data/services/phrasebook_translator_service.dart';
import 'data/services/translator_service.dart';
import 'providers/locale_provider.dart';
import 'providers/session_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final preferences = await SharedPreferences.getInstance();
  final localeProvider = LocaleProvider(preferences: preferences);
  await localeProvider.loadSavedLocale();
  final translator = await _createTranslator();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(
          create: (_) => SessionProvider(translator: translator),
        ),
      ],
      child: const IslaApp(),
    ),
  );
}

/// Wraps the base translator with the offline phrasebook layer.
/// Set [kPhraseBookEnabled] to false to remove the layer.
Future<TranslatorService> _createTranslator() async {
  const base = MockTranslatorService();
  if (!kPhraseBookEnabled) return base;
  final phrasebook = Phrasebook();
  await phrasebook.initialize();
  return PhrasebookTranslatorService(phrasebook: phrasebook, fallback: base);
}
