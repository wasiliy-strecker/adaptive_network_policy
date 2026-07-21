import 'package:adaptive_network_policy/adaptive_network_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = NetworkPolicyEvaluator();

  group('NetworkPolicyEvaluator', () {
    test('interactive work runs on a constrained metered path', () {
      final conditions = _conditions(
        cost: NetworkCost.metered,
        constraint: NetworkConstraint.constrained,
        isRoaming: NetworkFlag.yes,
        isCongested: NetworkFlag.yes,
        backgroundData: BackgroundDataStatus.restricted,
      );

      final decision = evaluator.evaluate(
        conditions,
        const NetworkRequirements.interactive(),
      );

      expect(decision, isA<NetworkAllowed>());
      expect(decision.shouldRun, isTrue);
    });

    test('background sync reports every known blocking reason', () {
      final decision = evaluator.evaluate(
        _conditions(
          constraint: NetworkConstraint.constrained,
          isRoaming: NetworkFlag.yes,
          isCongested: NetworkFlag.yes,
          backgroundData: BackgroundDataStatus.restricted,
        ),
        const NetworkRequirements.backgroundSync(),
      );

      expect((decision as NetworkDeferred).reasons, <NetworkDecisionReason>{
        NetworkDecisionReason.constrained,
        NetworkDecisionReason.roaming,
        NetworkDecisionReason.congested,
        NetworkDecisionReason.backgroundDataRestricted,
      });
    });

    test('bulk transfer accepts temporarily unmetered paths', () {
      final decision = evaluator.evaluate(
        _conditions(cost: NetworkCost.temporarilyUnmetered),
        const NetworkRequirements.bulkTransfer(),
      );

      expect(decision, isA<NetworkAllowed>());
    });

    test('bulk transfer defers on a metered path', () {
      final decision = evaluator.evaluate(
        _conditions(cost: NetworkCost.metered),
        const NetworkRequirements.bulkTransfer(),
      );

      expect((decision as NetworkDeferred).reasons, <NetworkDecisionReason>{
        NetworkDecisionReason.metered,
      });
    });

    test('strict mode exposes unknown capabilities', () {
      final decision = evaluator.evaluate(
        _conditions(
          cost: NetworkCost.unknown,
          constraint: NetworkConstraint.unknown,
          isRoaming: NetworkFlag.unknown,
          isCongested: NetworkFlag.unknown,
          isSuspended: NetworkFlag.unknown,
          backgroundData: BackgroundDataStatus.unknown,
        ),
        const NetworkRequirements.bulkTransfer().copyWith(
          unknownCapabilityBehavior: UnknownCapabilityBehavior.defer,
        ),
      );

      expect((decision as NetworkDeferred).reasons, <NetworkDecisionReason>{
        NetworkDecisionReason.unknownCost,
        NetworkDecisionReason.unknownConstraint,
        NetworkDecisionReason.unknownRoaming,
        NetworkDecisionReason.unknownCongestion,
        NetworkDecisionReason.unknownSuspension,
        NetworkDecisionReason.unknownBackgroundDataStatus,
      });
    });

    test('validated internet can be required explicitly', () {
      final requirements = const NetworkRequirements.interactive().copyWith(
        requiresValidatedInternet: true,
      );

      final configured = evaluator.evaluate(_conditions(), requirements);
      final validated = evaluator.evaluate(
        _conditions(availability: NetworkAvailability.validatedInternet),
        requirements,
      );

      expect((configured as NetworkDeferred).reasons, <NetworkDecisionReason>{
        NetworkDecisionReason.internetNotValidated,
      });
      expect(validated, isA<NetworkAllowed>());
    });

    test('validated internet requirement implies internet access', () {
      final decision = evaluator.evaluate(
        _conditions(availability: NetworkAvailability.localOnly),
        const NetworkRequirements(
          requiresInternet: false,
          requiresValidatedInternet: true,
        ),
      );

      expect((decision as NetworkDeferred).reasons, <NetworkDecisionReason>{
        NetworkDecisionReason.localNetworkOnly,
      });
    });

    for (final entry
        in <NetworkAvailability, NetworkDecisionReason>{
          NetworkAvailability.unavailable:
              NetworkDecisionReason.networkUnavailable,
          NetworkAvailability.requiresConnection:
              NetworkDecisionReason.connectionRequired,
          NetworkAvailability.localOnly: NetworkDecisionReason.localNetworkOnly,
          NetworkAvailability.captivePortal:
              NetworkDecisionReason.captivePortal,
          NetworkAvailability.unknown:
              NetworkDecisionReason.unknownAvailability,
        }.entries) {
      test('${entry.key.name} defers internet work', () {
        final decision = evaluator.evaluate(
          _conditions(availability: entry.key),
          const NetworkRequirements.interactive(),
        );

        expect((decision as NetworkDeferred).reasons, <NetworkDecisionReason>{
          entry.value,
        });
      });
    }

    test('a suspended path always defers work', () {
      final decision = evaluator.evaluate(
        _conditions(isSuspended: NetworkFlag.yes),
        const NetworkRequirements.interactive(),
      );

      expect(
        (decision as NetworkDeferred).reasons,
        contains(NetworkDecisionReason.suspended),
      );
    });
  });
}

NetworkConditions _conditions({
  NetworkAvailability availability = NetworkAvailability.internetConfigured,
  NetworkCost cost = NetworkCost.unmetered,
  NetworkConstraint constraint = NetworkConstraint.unconstrained,
  NetworkFlag isRoaming = NetworkFlag.no,
  NetworkFlag isCongested = NetworkFlag.no,
  NetworkFlag isSuspended = NetworkFlag.no,
  BackgroundDataStatus backgroundData = BackgroundDataStatus.allowed,
}) {
  return NetworkConditions(
    availability: availability,
    transports: const <NetworkTransport>{NetworkTransport.wifi},
    cost: cost,
    constraint: constraint,
    isRoaming: isRoaming,
    isCongested: isCongested,
    isSuspended: isSuspended,
    backgroundData: backgroundData,
    downlinkKbps: 100000,
    uplinkKbps: 20000,
    observedAt: DateTime.utc(2026, 7, 21),
  );
}
