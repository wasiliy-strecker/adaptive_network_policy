import 'package:adaptive_network_policy/adaptive_network_policy.dart';

enum DemoScenario {
  fastWifi,
  constrainedCellular,
  roaming,
  captivePortal,
  offline,
  unknownCapabilities,
}

extension DemoScenarioDetails on DemoScenario {
  String get label => switch (this) {
    DemoScenario.fastWifi => 'Fast Wi-Fi',
    DemoScenario.constrainedCellular => 'Constrained cellular',
    DemoScenario.roaming => 'Roaming',
    DemoScenario.captivePortal => 'Captive portal',
    DemoScenario.offline => 'Offline',
    DemoScenario.unknownCapabilities => 'Unknown capabilities',
  };

  String get description => switch (this) {
    DemoScenario.fastWifi => 'Validated, unmetered and unconstrained',
    DemoScenario.constrainedCellular =>
      'Metered, low-data and background-restricted',
    DemoScenario.roaming => 'Validated cellular path while roaming',
    DemoScenario.captivePortal => 'Wi-Fi path blocked by sign-in',
    DemoScenario.offline => 'No active network path',
    DemoScenario.unknownCapabilities =>
      'Usable route with platform-specific gaps',
  };

  NetworkConditions snapshot({DateTime? observedAt}) {
    final now = observedAt ?? DateTime.now().toUtc();
    return switch (this) {
      DemoScenario.fastWifi => _snapshot(
        availability: NetworkAvailability.validatedInternet,
        transports: const {NetworkTransport.wifi},
        cost: NetworkCost.unmetered,
        constraint: NetworkConstraint.unconstrained,
        isRoaming: NetworkFlag.no,
        isCongested: NetworkFlag.no,
        isSuspended: NetworkFlag.no,
        backgroundData: BackgroundDataStatus.allowed,
        downlinkKbps: 120000,
        uplinkKbps: 48000,
        observedAt: now,
      ),
      DemoScenario.constrainedCellular => _snapshot(
        availability: NetworkAvailability.validatedInternet,
        transports: const {NetworkTransport.cellular},
        cost: NetworkCost.metered,
        constraint: NetworkConstraint.constrained,
        isRoaming: NetworkFlag.no,
        isCongested: NetworkFlag.yes,
        isSuspended: NetworkFlag.no,
        backgroundData: BackgroundDataStatus.restricted,
        downlinkKbps: 4200,
        uplinkKbps: 900,
        observedAt: now,
      ),
      DemoScenario.roaming => _snapshot(
        availability: NetworkAvailability.validatedInternet,
        transports: const {NetworkTransport.cellular},
        cost: NetworkCost.metered,
        constraint: NetworkConstraint.unconstrained,
        isRoaming: NetworkFlag.yes,
        isCongested: NetworkFlag.no,
        isSuspended: NetworkFlag.no,
        backgroundData: BackgroundDataStatus.allowed,
        downlinkKbps: 18000,
        uplinkKbps: 5000,
        observedAt: now,
      ),
      DemoScenario.captivePortal => _snapshot(
        availability: NetworkAvailability.captivePortal,
        transports: const {NetworkTransport.wifi},
        cost: NetworkCost.unmetered,
        constraint: NetworkConstraint.unconstrained,
        isRoaming: NetworkFlag.no,
        isCongested: NetworkFlag.no,
        isSuspended: NetworkFlag.no,
        backgroundData: BackgroundDataStatus.allowed,
        observedAt: now,
      ),
      DemoScenario.offline => _snapshot(
        availability: NetworkAvailability.unavailable,
        transports: const {},
        cost: NetworkCost.unknown,
        constraint: NetworkConstraint.unknown,
        isRoaming: NetworkFlag.unknown,
        isCongested: NetworkFlag.unknown,
        isSuspended: NetworkFlag.unknown,
        backgroundData: BackgroundDataStatus.allowed,
        observedAt: now,
      ),
      DemoScenario.unknownCapabilities => _snapshot(
        availability: NetworkAvailability.internetConfigured,
        transports: const {NetworkTransport.ethernet},
        cost: NetworkCost.unknown,
        constraint: NetworkConstraint.unknown,
        isRoaming: NetworkFlag.unknown,
        isCongested: NetworkFlag.unknown,
        isSuspended: NetworkFlag.unknown,
        backgroundData: BackgroundDataStatus.unknown,
        observedAt: now,
      ),
    };
  }
}

NetworkConditions _snapshot({
  required NetworkAvailability availability,
  required Set<NetworkTransport> transports,
  required NetworkCost cost,
  required NetworkConstraint constraint,
  required NetworkFlag isRoaming,
  required NetworkFlag isCongested,
  required NetworkFlag isSuspended,
  required BackgroundDataStatus backgroundData,
  required DateTime observedAt,
  int? downlinkKbps,
  int? uplinkKbps,
}) {
  return NetworkConditions(
    availability: availability,
    transports: transports,
    cost: cost,
    constraint: constraint,
    isRoaming: isRoaming,
    isCongested: isCongested,
    isSuspended: isSuspended,
    backgroundData: backgroundData,
    downlinkKbps: downlinkKbps,
    uplinkKbps: uplinkKbps,
    observedAt: observedAt,
  );
}
