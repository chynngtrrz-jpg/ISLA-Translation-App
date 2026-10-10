import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:isla_app/l10n/app_localizations.dart';
import 'package:isla_app/l10n/fallback_localizations.dart';
import 'package:isla_app/providers/locale_provider.dart';
import 'package:isla_app/ui/screens/language_selection_screen.dart';
import 'package:isla_app/ui/widgets/language_card.dart';

Widget buildTestApp(LocaleProvider localeProvider) {
  return ChangeNotifierProvider<LocaleProvider>.value(
    value: localeProvider,
    child: Consumer<LocaleProvider>(
      builder: (context, locale, child) => MaterialApp(
        locale: locale.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          EnglishFallbackMaterialLocalizationsDelegate(),
          EnglishFallbackWidgetsLocalizationsDelegate(),
          EnglishFallbackCupertinoLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          '/select-languages': (context) => Scaffold(
                body: const Text('Next step'),
                floatingActionButton: IconButton(
                  key: const ValueKey('testBack'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
        },
        home: const LanguageSelectionScreen(),
      ),
    ),
  );
}

Future<LocaleProvider> createLocaleProvider() async {
  final preferences = await SharedPreferences.getInstance();
  final provider = LocaleProvider(preferences: preferences);
  await provider.loadSavedLocale();
  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('defaults to English without highlighting an unselected card',
      (tester) async {
    final provider = await createLocaleProvider();

    await tester.pumpWidget(buildTestApp(provider));

    expect(find.byType(LanguageCard), findsNWidgets(5));
    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('Filipino'), findsNothing);
    expect(find.text('Tagalog'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LanguageCard),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
  });

  testWidgets('selecting Tagalog localizes this page and persists the locale',
      (tester) async {
    final provider = await createLocaleProvider();
    await tester.pumpWidget(buildTestApp(provider));

    await tester.ensureVisible(find.text('Tagalog'));
    await tester.tap(find.text('Tagalog'));
    await tester.pump();

    expect(provider.locale, const Locale('tl'));
    final tagalogCard = find.ancestor(
      of: find.text('Tagalog'),
      matching: find.byType(LanguageCard),
    );
    expect(
      find.descendant(of: tagalogCard, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(find.text('Piliin ang inyong wika'), findsOneWidget);
    expect(find.text('Piliin'), findsNWidgets(4));

    await tester.pump(const Duration(milliseconds: 181));
    await tester.pumpAndSettle();
    expect(find.text('Next step'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('ui_locale'),
      'tl',
    );
  });

  testWidgets('selecting Ini switches to rol and persists the UI locale',
      (tester) async {
    final provider = await createLocaleProvider();
    await tester.pumpWidget(buildTestApp(provider));

    await tester.ensureVisible(find.text('Ini (Romblomanon)'));
    await tester.tap(find.text('Ini (Romblomanon)'));
    await tester.pump();

    expect(provider.locale, const Locale('rol'));
    final iniCard = find.ancestor(
      of: find.text('Ini (Romblomanon)'),
      matching: find.byType(LanguageCard),
    );
    expect(
      find.descendant(of: iniCard, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(find.text('Pumili ng linggwahe'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 181));
    await tester.pumpAndSettle();
    expect(find.text('Next step'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('ui_locale'),
      'rol',
    );
  });

  testWidgets('selecting Asi switches to bno and persists the UI locale',
      (tester) async {
    final provider = await createLocaleProvider();
    await tester.pumpWidget(buildTestApp(provider));

    await tester.ensureVisible(find.text('Asi (Bantoanon)'));
    await tester.tap(find.text('Asi (Bantoanon)'));
    await tester.pump();

    expect(provider.locale, const Locale('bno'));
    final asiCard = find.ancestor(
      of: find.text('Asi (Bantoanon)'),
      matching: find.byType(LanguageCard),
    );
    expect(
      find.descendant(of: asiCard, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(find.text('Choose your language'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 181));
    await tester.pumpAndSettle();
    expect(find.text('Next step'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('ui_locale'),
      'bno',
    );
  });

  testWidgets('selecting Onhan switches to loc and persists the UI locale',
      (tester) async {
    final provider = await createLocaleProvider();
    await tester.pumpWidget(buildTestApp(provider));

    await tester.ensureVisible(find.text('Onhan'));
    await tester.tap(find.text('Onhan'));
    await tester.pump();

    expect(provider.locale, const Locale('loc'));
    final onhanCard = find.ancestor(
      of: find.text('Onhan'),
      matching: find.byType(LanguageCard),
    );
    expect(
      find.descendant(of: onhanCard, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(find.text('Choose your language'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 181));
    await tester.pumpAndSettle();
    expect(find.text('Next step'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('ui_locale'),
      'loc',
    );
  });

  testWidgets('restores saved Tagalog without showing a new selection check',
      (tester) async {
    SharedPreferences.setMockInitialValues({'ui_locale': 'tl'});
    final provider = await createLocaleProvider();

    await tester.pumpWidget(buildTestApp(provider));

    expect(provider.locale, const Locale('tl'));
    expect(provider.hasExplicitSelection, isFalse);
    expect(find.text('Piliin ang inyong wika'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LanguageCard),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
  });

  testWidgets('selecting English switches the page back to English',
      (tester) async {
    final provider = await createLocaleProvider();
    await tester.pumpWidget(buildTestApp(provider));

    await tester.ensureVisible(find.text('Tagalog'));
    await tester.tap(find.text('Tagalog'));
    await tester.pump(const Duration(milliseconds: 181));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('testBack')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('English').first);
    await tester.tap(find.text('English').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 181));
    await tester.pumpAndSettle();

    expect(provider.locale, const Locale('en'));
    expect(find.text('Next step'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('testBack')));
    await tester.pumpAndSettle();
    expect(find.text('Choose your language'), findsOneWidget);
  });

  testWidgets('selected Onhan locale remains after returning to language page',
      (tester) async {
    final provider = await createLocaleProvider();
    await tester.pumpWidget(buildTestApp(provider));

    await tester.ensureVisible(find.text('Onhan'));
    await tester.tap(find.text('Onhan'));
    await tester.pump();

    expect(provider.locale, const Locale('loc'));
    await tester.pump(const Duration(milliseconds: 181));
    await tester.pumpAndSettle();
    expect(find.text('Next step'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('testBack')));
    await tester.pumpAndSettle();
    expect(provider.locale, const Locale('loc'));
    expect(find.text('Onhan'), findsOneWidget);
  });

  testWidgets('fits a 360x640 viewport at 1.3 text scale', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = await createLocaleProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleProvider>.value(
        value: provider,
        child: Consumer<LocaleProvider>(
          builder: (context, locale, child) => MaterialApp(
            locale: locale.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: const LanguageSelectionScreen(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(LanguageCard), findsNWidgets(5));
  });

  testWidgets('fits phone, tablet, and web viewport widths', (tester) async {
    final provider = await createLocaleProvider();
    final viewports = [
      const Size(320, 640),
      const Size(390, 844),
      const Size(600, 900),
      const Size(768, 1024),
      const Size(1024, 768),
      const Size(1440, 900),
    ];

    for (final viewport in viewports) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow at $viewport',
      );
      expect(find.byType(LanguageCard), findsNWidgets(5));
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
