import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/widgets/app_logo.dart';

void main() {
  group('AppLogo', () {
    testWidgets('renders the bundled logo at the requested size', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const CupertinoApp(home: Center(child: AppLogo(size: 64))),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, 64);
      expect(image.height, 64);
      expect((image.image as AssetImage).assetName, AppLogo.assetPath);
    });

    testWidgets('is exposed to accessibility as an image', (
      WidgetTester tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(const CupertinoApp(home: AppLogo()));

      expect(find.bySemanticsLabel('TrueNAS Manager logo'), findsOneWidget);
      handle.dispose();
    });
  });
}
