import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_ops/main.dart';

void main() {
  testWidgets('AquaOps app launch smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AquaOpsApp());

    // Verify that the app builds without crashing.
    expect(find.byType(AquaOpsApp), findsOneWidget);
  });
}