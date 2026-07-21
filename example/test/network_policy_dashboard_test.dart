import 'package:adaptive_network_policy_example/src/demo_app.dart';
import 'package:adaptive_network_policy_example/src/demo_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('simulates conditions and explains a deferred operation', (
    tester,
  ) async {
    final controller = DemoController(forceSimulation: true);
    addTearDown(controller.dispose);

    await tester.pumpWidget(DemoApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('ADAPTIVE NETWORK POLICY'), findsOneWidget);
    expect(find.text('Run now'), findsOneWidget);

    await tester.tap(find.text('Constrained cellular'));
    await tester.pump();
    await tester.tap(find.text('Bulk transfer'));
    await tester.pump();

    expect(find.text('Defer'), findsOneWidget);
    expect(find.text('Metered'), findsAtLeastNWidgets(1));
    expect(find.text('Constrained'), findsAtLeastNWidgets(1));
  });
}
