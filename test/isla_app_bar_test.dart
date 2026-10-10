import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isla_app/core/theme/app_colors.dart';
import 'package:isla_app/ui/widgets/isla_app_bar.dart';

void main() {
  testWidgets('shared header uses a 48 dp mascot avatar with image semantics',
      (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1170, 2532);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IslaAppBar(subtitle: 'Language Translation'),
        ),
      ),
    );

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.radius, 24);
    expect(avatar.backgroundColor, AppColors.bisque);
    expect(tester.getSize(find.byType(IslaAppBar)).height, 96);
    expect(find.bySemanticsLabel('ISLA mascot'), findsOneWidget);

    final mascot = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.semanticLabel == 'ISLA mascot',
      ),
    );
    expect(mascot.width, closeTo(48 * 0.82, 0.001));
    expect(mascot.height, closeTo(48 * 0.82, 0.001));
    expect(mascot.image, isA<ResizeImage>());
    expect(mascot.filterQuality, FilterQuality.medium);

    final wordmark = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.semanticLabel == 'ISLA',
      ),
    );
    expect(wordmark.height, 28);
    expect(wordmark.image, isA<ResizeImage>());
    expect(wordmark.filterQuality, FilterQuality.medium);
    expect(wordmark.alignment, Alignment.centerLeft);
    expect(find.text('ISLA'), findsNothing);
    expect(find.text('Language Translation'), findsOneWidget);
  });

  testWidgets('larger mascot fits a compact header without overflow',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 480);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IslaAppBar(subtitle: 'Language Translation'),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.semanticLabel == 'ISLA',
      ),
      findsOneWidget,
    );
    expect(find.text('Language Translation'), findsOneWidget);
  });
}
