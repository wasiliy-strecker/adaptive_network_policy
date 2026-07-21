import 'dart:async';

import 'package:adaptive_network_policy/adaptive_network_policy.dart';
import 'package:adaptive_network_policy/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monitor emits the initial state and deduplicates updates', () async {
    final initial = _conditions();
    final source = FakeNetworkConditionsSource(initial);
    addTearDown(source.close);
    final monitor = NetworkConditionsMonitor(source: source);
    final received = <NetworkConditions>[];
    final twoValues = Completer<void>();
    final subscription = monitor.changes.listen((conditions) {
      received.add(conditions);
      if (received.length == 2) {
        twoValues.complete();
      }
    });
    addTearDown(subscription.cancel);

    await Future<void>.delayed(Duration.zero);
    source.emit(initial.copyWith(observedAt: DateTime.utc(2026, 7, 22)));
    source.emit(initial.copyWith(cost: NetworkCost.metered));
    await twoValues.future.timeout(const Duration(seconds: 1));

    expect(received, hasLength(2));
    expect(received.first.cost, NetworkCost.unmetered);
    expect(received.last.cost, NetworkCost.metered);
    expect(identical(monitor.changes, monitor.changes), isTrue);
    expect((await monitor.current()).cost, NetworkCost.metered);
  });

  test('fake source rejects updates after close', () async {
    final source = FakeNetworkConditionsSource(_conditions());
    await source.close();

    expect(() => source.emit(_conditions()), throwsStateError);
  });
}

NetworkConditions _conditions() {
  return NetworkConditions(
    availability: NetworkAvailability.validatedInternet,
    transports: const <NetworkTransport>{NetworkTransport.wifi},
    cost: NetworkCost.unmetered,
    constraint: NetworkConstraint.unconstrained,
    isRoaming: NetworkFlag.no,
    isCongested: NetworkFlag.no,
    isSuspended: NetworkFlag.no,
    backgroundData: BackgroundDataStatus.allowed,
    observedAt: DateTime.utc(2026, 7, 21),
  );
}
