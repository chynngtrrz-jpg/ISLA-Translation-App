import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:isla_app/app.dart';
import 'package:isla_app/core/constants/app_config.dart';
import 'package:isla_app/providers/locale_provider.dart';

const _tagline = 'Every island\u2019s voice, kept by choice.';

Future<Widget> _app({String locale = 'en'}) async {
  SharedPreferences.setMockInitialValues({'ui_locale': locale});
  final provider = LocaleProvider(
    preferences: await SharedPreferences.getInstance(),
  );
  await provider.loadSavedLocale();
  return ChangeNotifierProvider<LocaleProvider>.value(
    value: provider,
    child: const IslaApp(),
  );
}

void _size(WidgetTester tester, double w, double h, [double scale = 1.0]) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

void main() {
  testWidgets('shows the tagline with the specified style', (tester) async {
    await tester.pumpWidget(await _app());
    expect(kTagline, _tagline);
    final text = tester.widget<Text>(find.text(_tagline));
    expect(text.style!.fontFamily, 'Alegreya');
    expect(text.style!.fontStyle, FontStyle.italic);
    expect(text.style!.color, const Color(0xFF004CA8));
    expect(text.maxLines, 2);
  });

  testWidgets('vertical order: tagline, mascot, wordmark, credit',
      (tester) async {
    await tester.pumpWidget(await _app());
    final tagline = tester.getTopLeft(find.text(_tagline)).dy;
    final mascot = tester.getTopLeft(find.bySemanticsLabel('ISLA mascot')).dy;
    final logo = tester.getTopLeft(find.bySemanticsLabel('ISLA logo')).dy;
    final credit = tester.getTopLeft(find.text('by')).dy;
    expect(tagline, lessThan(mascot));
    expect(mascot, lessThan(logo));
    expect(logo, lessThan(credit));
  });

  testWidgets('Get Started is a FilledButton going to /language',
      (tester) async {
    await tester.pumpWidget(await _app());
    expect(find.byType(FilledButton), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text(_tagline), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  for (final s in const [
    [360.0, 640.0, 1.3],
    [412.0, 915.0, 1.0],
    [800.0, 1280.0, 1.0],
  ]) {
    testWidgets('no overflow at ${s[0]}x${s[1]} scale ${s[2]}',
        (tester) async {
      _size(tester, s[0], s[1], s[2]);
      await tester.pumpWidget(await _app());
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(FilledButton), findsOneWidget);
      final bottom = tester.getBottomLeft(find.byType(FilledButton)).dy;
      expect(bottom, lessThanOrEqualTo(s[1]));
    });
  }

  testWidgets('tagline stays English under Filipino', (tester) async {
    await tester.pumpWidget(await _app(locale: 'tl'));
    expect(find.text(_tagline), findsOneWidget);
  });
}
