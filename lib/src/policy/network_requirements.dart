/// How a policy treats capabilities the current platform cannot report.
enum UnknownCapabilityBehavior {
  /// Do not block work solely because a capability is unavailable.
  allow,

  /// Defer work when a relevant capability is unavailable.
  defer,
}

/// Declarative requirements for a network-dependent operation.
final class NetworkRequirements {
  /// Creates declarative requirements for one operation.
  const NetworkRequirements({
    this.requiresInternet = true,
    this.requiresValidatedInternet = false,
    this.allowsMetered = true,
    this.allowsConstrained = true,
    this.allowsRoaming = true,
    this.allowsCongested = true,
    this.allowsRestrictedBackgroundData = false,
    this.unknownCapabilityBehavior = UnknownCapabilityBehavior.allow,
  });

  /// A user-initiated request that should attempt work on any usable path.
  const NetworkRequirements.interactive()
    : this(allowsRestrictedBackgroundData: true);

  /// Deferred synchronization that respects system resource preferences.
  const NetworkRequirements.backgroundSync()
    : this(
        allowsConstrained: false,
        allowsRoaming: false,
        allowsCongested: false,
      );

  /// A large transfer that additionally requires a non-metered path.
  const NetworkRequirements.bulkTransfer()
    : this(
        allowsMetered: false,
        allowsConstrained: false,
        allowsRoaming: false,
        allowsCongested: false,
      );

  /// Whether local-only and unavailable paths must be rejected.
  final bool requiresInternet;

  /// Whether OS-validated internet is required instead of a configured route.
  ///
  /// Enabling this also implies [requiresInternet].
  final bool requiresValidatedInternet;

  /// Whether the operation may use a metered path.
  final bool allowsMetered;

  /// Whether the operation may run under a data-saving constraint.
  final bool allowsConstrained;

  /// Whether the operation may run while roaming.
  final bool allowsRoaming;

  /// Whether the operation may run on a congested path.
  final bool allowsCongested;

  /// Whether the operation may run while background data is restricted.
  final bool allowsRestrictedBackgroundData;

  /// How relevant values reported as `unknown` affect the decision.
  final UnknownCapabilityBehavior unknownCapabilityBehavior;

  /// Returns a copy with selected requirements replaced.
  NetworkRequirements copyWith({
    bool? requiresInternet,
    bool? requiresValidatedInternet,
    bool? allowsMetered,
    bool? allowsConstrained,
    bool? allowsRoaming,
    bool? allowsCongested,
    bool? allowsRestrictedBackgroundData,
    UnknownCapabilityBehavior? unknownCapabilityBehavior,
  }) {
    return NetworkRequirements(
      requiresInternet: requiresInternet ?? this.requiresInternet,
      requiresValidatedInternet:
          requiresValidatedInternet ?? this.requiresValidatedInternet,
      allowsMetered: allowsMetered ?? this.allowsMetered,
      allowsConstrained: allowsConstrained ?? this.allowsConstrained,
      allowsRoaming: allowsRoaming ?? this.allowsRoaming,
      allowsCongested: allowsCongested ?? this.allowsCongested,
      allowsRestrictedBackgroundData:
          allowsRestrictedBackgroundData ?? this.allowsRestrictedBackgroundData,
      unknownCapabilityBehavior:
          unknownCapabilityBehavior ?? this.unknownCapabilityBehavior,
    );
  }
}
