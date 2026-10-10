import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/services/nllb_translator_service.dart';
import 'providers/locale_provider.dart';
import 'providers/session_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final preferences = await SharedPreferences.getInstance();
  final localeProvider = LocaleProvider(preferences: preferences);
  await localeProvider.loadSavedLocale();

  final translator = NllbTranslatorService();
  final sessionProvider = SessionProvider(translator: translator);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: sessionProvider),
      ],
      child: const IslaApp(),
    ),
  );

  // Load the model after the first frame so the UI appears right away.
  translator.init().then((_) {
    sessionProvider.refreshModelState();
  }).catchError((Object error, StackTrace stackTrace) {
    debugPrint('Model failed to load: $error\n$stackTrace');
    sessionProvider.refreshModelState(failed: true);
  });
}