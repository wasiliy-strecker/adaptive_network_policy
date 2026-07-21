/// A reason that current network conditions do not meet requirements.
enum NetworkDecisionReason {
  /// No active path exists.
  networkUnavailable,

  /// The path requires user or system action.
  connectionRequired,

  /// Only a local network is available.
  localNetworkOnly,

  /// Network sign-in blocks internet access.
  captivePortal,

  /// Availability cannot be determined.
  unknownAvailability,

  /// The path has not been validated by the operating system.
  internetNotValidated,

  /// The path is metered.
  metered,

  /// A low-data or bandwidth constraint is active.
  constrained,

  /// The path is roaming.
  roaming,

  /// The path is congested.
  congested,

  /// The path is suspended.
  suspended,

  /// Background data is restricted.
  backgroundDataRestricted,

  /// Cost is required but unavailable.
  unknownCost,

  /// Constraint status is required but unavailable.
  unknownConstraint,

  /// Roaming status is required but unavailable.
  unknownRoaming,

  /// Congestion status is required but unavailable.
  unknownCongestion,

  /// Suspension status is required but unavailable.
  unknownSuspension,

  /// Background-data status is required but unavailable.
  unknownBackgroundDataStatus,
}

/// The deterministic outcome of evaluating network requirements.
sealed class NetworkDecision {
  /// Creates a policy result subtype.
  const NetworkDecision();

  /// Whether the operation may start under the evaluated conditions.
  bool get shouldRun;
}

/// The operation can run under the observed conditions.
final class NetworkAllowed extends NetworkDecision {
  /// Creates an allowed decision.
  const NetworkAllowed();

  @override
  bool get shouldRun => true;

  @override
  String toString() => 'NetworkAllowed()';
}

/// The operation should wait for conditions to change.
final class NetworkDeferred extends NetworkDecision {
  /// Creates a deferred decision with one or more blocking [reasons].
  NetworkDeferred(Set<NetworkDecisionReason> reasons)
    : assert(reasons.isNotEmpty),
      reasons = Set<NetworkDecisionReason>.unmodifiable(reasons);

  /// Every requirement that currently blocks the operation.
  final Set<NetworkDecisionReason> reasons;

  @override
  bool get shouldRun => false;

  @override
  String toString() => 'NetworkDeferred($reasons)';
}
