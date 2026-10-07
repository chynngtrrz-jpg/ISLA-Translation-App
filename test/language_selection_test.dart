import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:isla_app/providers/language_provider.dart';
import 'package:isla_app/ui/screens/language_selection_screen.dart';
import 'package:isla_app/ui/widgets/language_card.dart';

Widget buildTestApp(LanguageProvider provider) {
  return ChangeNotifierProvider<LanguageProvider>.value(
    value: provider,
    child: MaterialApp(
      routes: {
        '/select-languages': (_) => const Scaffold(body: Text('Next step')),
      },
      home: const LanguageSelectionScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders five unselected cards before a language is chosen',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final provider = LanguageProvider(preferences: preferences);

    await tester.pumpWidget(buildTestApp(provider));

    expect(find.byType(LanguageCard), findsNWidgets(5));
    expect(find.text('Selected'), findsNothing);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.text('Select'), findsNWidgets(5));
  });

  testWidgets('selecting Onhan updates and persists the interface language',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final provider = LanguageProvider(preferences: preferences);

    await tester.pumpWidget(buildTestApp(provider));
    await tester.ensureVisible(find.text('Onhan'));
    await tester.tap(find.text('Onhan'));
    await tester.pump();

    expect(provider.uiLanguage, 'onh');
    await tester.pump(const Duration(milliseconds: 181));
    await tester.pumpAndSettle();
    expect(preferences.getString('ui_language'), 'onh');
    expect(find.text('Next step'), findsOneWidget);
  });

  testWidgets('fits a 360x640 viewport at 1.3 text scale', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = await SharedPreferences.getInstance();
    final provider = LanguageProvider(preferences: preferences);

    await tester.pumpWidget(
      ChangeNotifierProvider<LanguageProvider>.value(
        value: provider,
        child: MaterialApp(
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
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(LanguageCard), findsNWidgets(5));
  });

  testWidgets('fits phone, tablet, and web viewport widths', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final provider = LanguageProvider(preferences: preferences);
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

  testWidgets('selected card shows its check without the word Selected',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final provider = LanguageProvider(preferences: preferences);
    await tester.pumpWidget(buildTestApp(provider));

    await provider.selectLanguage('fil');
    await tester.pump();

    final filipinoCard = find.ancestor(
      of: find.text('Filipino'),
      matching: find.byType(LanguageCard),
    );
    expect(
      find.descendant(of: filipinoCard, matching: find.text('Select')),
      findsNothing,
    );
    expect(
      find.descendant(of: filipinoCard, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    final cardRect = tester.getRect(filipinoCard);
    final rows = tester.widgetList<Row>(
      find.descendant(of: filipinoCard, matching: find.byType(Row)),
    );
    final trailingRow =
        rows.lastWhere((row) => row.mainAxisSize == MainAxisSize.min);
    expect(trailingRow.mainAxisSize, MainAxisSize.min);
    final trailingRect = tester.getRect(
      find.descendant(
        of: filipinoCard,
        matching: find.byWidget(trailingRow),
      ),
    );
    expect(trailingRect.right, greaterThan(cardRect.right - 40));
    expect(trailingRect.right, lessThan(cardRect.right));
  });
}
