/// Stable failure categories exposed by the network monitor.
enum NetworkMonitorErrorCode {
  /// The current Flutter target has no native implementation.
  unsupportedPlatform,

  /// A required operating-system permission is unavailable.
  permissionDenied,

  /// Native data violates the shared channel schema.
  invalidNativeData,

  /// The platform implementation failed unexpectedly.
  nativeFailure,
}

/// A typed failure produced while reading native network conditions.
final class NetworkMonitorException implements Exception {
  /// Creates a typed monitor exception.
  const NetworkMonitorException(this.code, this.message, {this.cause});

  /// Stable, machine-readable failure category.
  final NetworkMonitorErrorCode code;

  /// Human-readable failure description.
  final String message;

  /// Original exception, when retaining it is useful for diagnostics.
  final Object? cause;

  @override
  String toString() => 'NetworkMonitorException($code, $message)';
}
