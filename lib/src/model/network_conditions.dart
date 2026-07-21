/// How much internet access the operating system can currently establish.
enum NetworkAvailability {
  /// No usable network path exists.
  unavailable,

  /// A path could be established, but currently requires user or system action.
  requiresConnection,

  /// A network exists, but it does not advertise general internet access.
  localOnly,

  /// Internet access is configured, but the OS has not validated it.
  internetConfigured,

  /// The operating system has validated general internet access.
  validatedInternet,

  /// The operating system reports that a captive portal blocks internet use.
  captivePortal,

  /// The platform could not determine availability.
  unknown,
}

/// A transport participating in the active system path.
enum NetworkTransport {
  /// Wireless LAN.
  wifi,

  /// A mobile radio connection.
  cellular,

  /// A wired Ethernet connection.
  ethernet,

  /// A virtual private network reported separately by the platform.
  vpn,

  /// A device-local loopback path.
  loopback,

  /// A transport without a more specific cross-platform representation.
  other,
}

/// The operating system's assessment of transfer cost.
enum NetworkCost {
  /// The OS does not consider the current path metered.
  unmetered,

  /// A normally metered path is temporarily treated as unmetered.
  temporarilyUnmetered,

  /// Transfers may consume a limited or billed allowance.
  metered,

  /// The platform cannot report the cost.
  unknown,
}

/// Whether the path is subject to a low-data or bandwidth constraint.
enum NetworkConstraint {
  /// No data-saving constraint is reported.
  unconstrained,

  /// The OS asks applications to reduce network use.
  constrained,

  /// The platform cannot report this condition.
  unknown,
}

/// A platform capability that can be true, false, or unavailable.
enum NetworkFlag {
  /// The condition is active.
  yes,

  /// The condition is explicitly inactive.
  no,

  /// The platform cannot report the condition.
  unknown,
}

/// Whether background traffic is restricted by the operating system.
enum BackgroundDataStatus {
  /// Background transfers are allowed.
  allowed,

  /// Background transfers are restricted.
  restricted,

  /// The application is exempt from a system restriction.
  exempt,

  /// The platform cannot report the status.
  unknown,
}

/// An immutable snapshot of native network conditions.
final class NetworkConditions {
  /// Creates a normalized snapshot.
  NetworkConditions({
    required this.availability,
    required Set<NetworkTransport> transports,
    required this.cost,
    required this.constraint,
    required this.isRoaming,
    required this.isCongested,
    required this.isSuspended,
    required this.backgroundData,
    required DateTime observedAt,
    this.downlinkKbps,
    this.uplinkKbps,
  }) : transports = Set<NetworkTransport>.unmodifiable(transports),
       observedAt = observedAt.toUtc(),
       assert(downlinkKbps == null || downlinkKbps >= 0),
       assert(uplinkKbps == null || uplinkKbps >= 0);

  /// A conservative snapshot for platforms that cannot provide native data.
  factory NetworkConditions.unknown({DateTime? observedAt}) {
    return NetworkConditions(
      availability: NetworkAvailability.unknown,
      transports: const <NetworkTransport>{},
      cost: NetworkCost.unknown,
      constraint: NetworkConstraint.unknown,
      isRoaming: NetworkFlag.unknown,
      isCongested: NetworkFlag.unknown,
      isSuspended: NetworkFlag.unknown,
      backgroundData: BackgroundDataStatus.unknown,
      observedAt: observedAt ?? DateTime.now().toUtc(),
    );
  }

  /// The level of network availability reported by the OS.
  final NetworkAvailability availability;

  /// Active transports, potentially including both VPN and its underlying path.
  final Set<NetworkTransport> transports;

  /// Whether transfers may consume a metered allowance.
  final NetworkCost cost;

  /// Whether low-data or bandwidth-saving behavior is requested.
  final NetworkConstraint constraint;

  /// Whether the active path is roaming.
  final NetworkFlag isRoaming;

  /// Whether the active path is congested.
  final NetworkFlag isCongested;

  /// Whether the active path is temporarily suspended.
  final NetworkFlag isSuspended;

  /// The system policy for background network traffic.
  final BackgroundDataStatus backgroundData;

  /// OS-provided downstream estimate in kilobits per second, when available.
  final int? downlinkKbps;

  /// OS-provided upstream estimate in kilobits per second, when available.
  final int? uplinkKbps;

  /// UTC timestamp at which the native state was observed.
  final DateTime observedAt;

  /// Whether all policy-relevant values match, ignoring observation time.
  bool hasSameStateAs(NetworkConditions other) {
    return availability == other.availability &&
        _setsEqual(transports, other.transports) &&
        cost == other.cost &&
        constraint == other.constraint &&
        isRoaming == other.isRoaming &&
        isCongested == other.isCongested &&
        isSuspended == other.isSuspended &&
        backgroundData == other.backgroundData &&
        downlinkKbps == other.downlinkKbps &&
        uplinkKbps == other.uplinkKbps;
  }

  /// Returns a modified immutable copy, useful for deterministic simulations.
  NetworkConditions copyWith({
    NetworkAvailability? availability,
    Set<NetworkTransport>? transports,
    NetworkCost? cost,
    NetworkConstraint? constraint,
    NetworkFlag? isRoaming,
    NetworkFlag? isCongested,
    NetworkFlag? isSuspended,
    BackgroundDataStatus? backgroundData,
    int? downlinkKbps,
    int? uplinkKbps,
    bool clearDownlinkKbps = false,
    bool clearUplinkKbps = false,
    DateTime? observedAt,
  }) {
    return NetworkConditions(
      availability: availability ?? this.availability,
      transports: transports ?? this.transports,
      cost: cost ?? this.cost,
      constraint: constraint ?? this.constraint,
      isRoaming: isRoaming ?? this.isRoaming,
      isCongested: isCongested ?? this.isCongested,
      isSuspended: isSuspended ?? this.isSuspended,
      backgroundData: backgroundData ?? this.backgroundData,
      downlinkKbps:
          clearDownlinkKbps ? null : downlinkKbps ?? this.downlinkKbps,
      uplinkKbps: clearUplinkKbps ? null : uplinkKbps ?? this.uplinkKbps,
      observedAt: observedAt ?? this.observedAt,
    );
  }

  @override
  String toString() {
    return 'NetworkConditions('
        'availability: $availability, '
        'transports: $transports, '
        'cost: $cost, '
        'constraint: $constraint, '
        'isRoaming: $isRoaming, '
        'isCongested: $isCongested, '
        'isSuspended: $isSuspended, '
        'backgroundData: $backgroundData, '
        'downlinkKbps: $downlinkKbps, '
        'uplinkKbps: $uplinkKbps, '
        'observedAt: $observedAt)';
  }
}

bool _setsEqual<T>(Set<T> left, Set<T> right) {
  return left.length == right.length && left.containsAll(right);
}
