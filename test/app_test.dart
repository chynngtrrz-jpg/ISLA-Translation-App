import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:isla_app/app.dart';
import 'package:isla_app/core/theme/app_colors.dart';
import 'package:isla_app/providers/locale_provider.dart';

Future<Widget> buildApp({Locale locale = const Locale('en')}) async {
  SharedPreferences.setMockInitialValues({'ui_locale': locale.languageCode});
  final preferences = await SharedPreferences.getInstance();
  final localeProvider = LocaleProvider(preferences: preferences);
  await localeProvider.loadSavedLocale();

  return ChangeNotifierProvider<LocaleProvider>.value(
    value: localeProvider,
    child: const IslaApp(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Get Started is a filled pill button and navigates to language selection',
      (tester) async {
    await tester.pumpWidget(await buildApp());

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(48));
    expect(
      find.bySemanticsLabel('ISLA mascot'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('ISLA logo'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('by LinguaTech'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      const Color(0xFFF8F5F0),
    );
    final by = tester.widget<Text>(find.text('by'));
    expect(by.style?.fontFamily, 'Alegreya');
    final buttonStyle = button.style!;
    expect(
      buttonStyle.textStyle!.resolve({})?.fontFamily,
      'Alegreya',
    );
    expect(buttonStyle.backgroundColor!.resolve({}), AppColors.chambray);
    expect(buttonStyle.foregroundColor!.resolve({}), AppColors.espresso);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Choose your language'), findsOneWidget);
  });

  testWidgets('Get Started label follows the selected UI locale',
      (tester) async {
    for (final testCase in [
      (const Locale('tl'), 'Magsimula'),
      (const Locale('rol'), 'Get Started'),
    ]) {
      await tester.pumpWidget(await buildApp(locale: testCase.$1));
      expect(find.text(testCase.$2), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('welcome page fits compact and tall portrait screens',
      (tester) async {
    for (final size in [
      const Size(320, 480),
      const Size(390, 844),
      const Size(768, 1365),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(await buildApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Overflow at $size');
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.bySemanticsLabel('ISLA mascot'), findsOneWidget);
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
