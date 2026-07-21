import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/platform/generated/network_conditions_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/dev/wasiliy/adaptive_network_policy/NetworkConditionsApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'dev.wasiliy.adaptive_network_policy',
    ),
    swiftOut:
        'darwin/adaptive_network_policy/Sources/adaptive_network_policy/NetworkConditionsApi.g.swift',
    swiftOptions: SwiftOptions(),
    copyrightHeader: 'pigeons/copyright.txt',
    dartPackageName: 'adaptive_network_policy',
  ),
)
enum NativeNetworkAvailability {
  unavailable,
  requiresConnection,
  localOnly,
  internetConfigured,
  validatedInternet,
  captivePortal,
  unknown,
}

enum NativeNetworkTransport { wifi, cellular, ethernet, vpn, loopback, other }

enum NativeNetworkCost { unmetered, temporarilyUnmetered, metered, unknown }

enum NativeNetworkConstraint { unconstrained, constrained, unknown }

enum NativeNetworkFlag { yes, no, unknown }

enum NativeBackgroundDataStatus { allowed, restricted, exempt, unknown }

class NativeNetworkSnapshot {
  NativeNetworkSnapshot({
    required this.schemaVersion,
    required this.availability,
    required this.transports,
    required this.cost,
    required this.constraint,
    required this.isRoaming,
    required this.isCongested,
    required this.isSuspended,
    required this.backgroundData,
    required this.observedAtMillis,
    this.downlinkKbps,
    this.uplinkKbps,
  });

  int schemaVersion;
  NativeNetworkAvailability availability;
  List<NativeNetworkTransport> transports;
  NativeNetworkCost cost;
  NativeNetworkConstraint constraint;
  NativeNetworkFlag isRoaming;
  NativeNetworkFlag isCongested;
  NativeNetworkFlag isSuspended;
  NativeBackgroundDataStatus backgroundData;
  int? downlinkKbps;
  int? uplinkKbps;
  int observedAtMillis;
}

@HostApi()
abstract class NativeNetworkConditionsApi {
  NativeNetworkSnapshot current();
}

@EventChannelApi()
abstract class NativeNetworkConditionsEvents {
  NativeNetworkSnapshot watch();
}
