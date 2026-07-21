import 'package:adaptive_network_policy/adaptive_network_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native monitor returns a coherent snapshot and emits updates', (
    tester,
  ) async {
    final monitor = NetworkConditionsMonitor();
    final current = await monitor.current();
    final streamed = await monitor.changes.first.timeout(
      const Duration(seconds: 5),
    );

    expect(current.observedAt.isUtc, isTrue);
    expect(streamed.observedAt.isUtc, isTrue);
    expect(current.downlinkKbps, anyOf(isNull, isNonNegative));
    expect(current.uplinkKbps, anyOf(isNull, isNonNegative));
  }, skip: kIsWeb);
}
