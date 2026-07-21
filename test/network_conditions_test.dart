import 'package:adaptive_network_policy/adaptive_network_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkConditions', () {
    test('copies the transport set defensively', () {
      final transports = <NetworkTransport>{NetworkTransport.wifi};
      final conditions = _conditions(transports: transports);

      transports.add(NetworkTransport.vpn);

      expect(conditions.transports, <NetworkTransport>{NetworkTransport.wifi});
      expect(
        () => conditions.transports.add(NetworkTransport.cellular),
        throwsUnsupportedError,
      );
    });

    test('semantic equality ignores observation time', () {
      final first = _conditions(observedAt: DateTime.utc(2026, 7, 21));
      final second = first.copyWith(observedAt: DateTime.utc(2026, 7, 22));

      expect(first.hasSameStateAs(second), isTrue);
      expect(
        first.hasSameStateAs(second.copyWith(cost: NetworkCost.metered)),
        isFalse,
      );
    });

    test('normalizes observation time to UTC', () {
      final conditions = _conditions(observedAt: DateTime(2026, 7, 21, 12));

      expect(conditions.observedAt.isUtc, isTrue);
    });

    test('unknown snapshot is conservative', () {
      final conditions = NetworkConditions.unknown(
        observedAt: DateTime.utc(2026, 7, 21),
      );

      expect(conditions.availability, NetworkAvailability.unknown);
      expect(conditions.cost, NetworkCost.unknown);
      expect(conditions.constraint, NetworkConstraint.unknown);
      expect(conditions.transports, isEmpty);
    });
  });
}

NetworkConditions _conditions({
  Set<NetworkTransport> transports = const <NetworkTransport>{
    NetworkTransport.wifi,
  },
  DateTime? observedAt,
}) {
  return NetworkConditions(
    availability: NetworkAvailability.validatedInternet,
    transports: transports,
    cost: NetworkCost.unmetered,
    constraint: NetworkConstraint.unconstrained,
    isRoaming: NetworkFlag.no,
    isCongested: NetworkFlag.no,
    isSuspended: NetworkFlag.no,
    backgroundData: BackgroundDataStatus.allowed,
    observedAt: observedAt ?? DateTime.utc(2026, 7, 21),
  );
}
