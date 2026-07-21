import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../model/network_conditions.dart';
import '../platform/generated/network_conditions_api.g.dart' as native;
import 'network_conditions_source.dart';
import 'network_monitor_exception.dart';

const int _schemaVersion = 1;

/// Platform-channel source used by the default monitor implementation.
final class NativeNetworkConditionsSource implements NetworkConditionsSource {
  /// Creates a source connected to the generated native API.
  NativeNetworkConditionsSource({native.NativeNetworkConditionsApi? api})
    : _api = api ?? native.NativeNetworkConditionsApi();

  final native.NativeNetworkConditionsApi _api;

  late final Stream<NetworkConditions> _changes = _createChanges();

  @override
  Stream<NetworkConditions> get changes => _changes;

  @override
  Future<NetworkConditions> current() async {
    _ensureSupported();
    try {
      return _decode(await _api.current());
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(_translateError(error), stackTrace);
    }
  }

  Stream<NetworkConditions> _createChanges() {
    if (!_isSupported) {
      return Stream<NetworkConditions>.error(_unsupportedException);
    }
    return native.watch().map(_decode).handleError((
      Object error,
      StackTrace stackTrace,
    ) {
      Error.throwWithStackTrace(_translateError(error), stackTrace);
    });
  }

  NetworkConditions _decode(native.NativeNetworkSnapshot snapshot) {
    if (snapshot.schemaVersion != _schemaVersion ||
        snapshot.observedAtMillis < 0 ||
        (snapshot.downlinkKbps != null && snapshot.downlinkKbps! < 0) ||
        (snapshot.uplinkKbps != null && snapshot.uplinkKbps! < 0)) {
      throw NetworkMonitorException(
        NetworkMonitorErrorCode.invalidNativeData,
        'The native plugin returned an unsupported or invalid snapshot.',
      );
    }

    return NetworkConditions(
      availability: _availability(snapshot.availability),
      transports: snapshot.transports.map(_transport).toSet(),
      cost: _cost(snapshot.cost),
      constraint: _constraint(snapshot.constraint),
      isRoaming: _flag(snapshot.isRoaming),
      isCongested: _flag(snapshot.isCongested),
      isSuspended: _flag(snapshot.isSuspended),
      backgroundData: _backgroundData(snapshot.backgroundData),
      downlinkKbps: snapshot.downlinkKbps,
      uplinkKbps: snapshot.uplinkKbps,
      observedAt: DateTime.fromMillisecondsSinceEpoch(
        snapshot.observedAtMillis,
        isUtc: true,
      ),
    );
  }

  NetworkAvailability _availability(native.NativeNetworkAvailability value) {
    return switch (value) {
      native.NativeNetworkAvailability.unavailable =>
        NetworkAvailability.unavailable,
      native.NativeNetworkAvailability.requiresConnection =>
        NetworkAvailability.requiresConnection,
      native.NativeNetworkAvailability.localOnly =>
        NetworkAvailability.localOnly,
      native.NativeNetworkAvailability.internetConfigured =>
        NetworkAvailability.internetConfigured,
      native.NativeNetworkAvailability.validatedInternet =>
        NetworkAvailability.validatedInternet,
      native.NativeNetworkAvailability.captivePortal =>
        NetworkAvailability.captivePortal,
      native.NativeNetworkAvailability.unknown => NetworkAvailability.unknown,
    };
  }

  NetworkTransport _transport(native.NativeNetworkTransport value) {
    return switch (value) {
      native.NativeNetworkTransport.wifi => NetworkTransport.wifi,
      native.NativeNetworkTransport.cellular => NetworkTransport.cellular,
      native.NativeNetworkTransport.ethernet => NetworkTransport.ethernet,
      native.NativeNetworkTransport.vpn => NetworkTransport.vpn,
      native.NativeNetworkTransport.loopback => NetworkTransport.loopback,
      native.NativeNetworkTransport.other => NetworkTransport.other,
    };
  }

  NetworkCost _cost(native.NativeNetworkCost value) {
    return switch (value) {
      native.NativeNetworkCost.unmetered => NetworkCost.unmetered,
      native.NativeNetworkCost.temporarilyUnmetered =>
        NetworkCost.temporarilyUnmetered,
      native.NativeNetworkCost.metered => NetworkCost.metered,
      native.NativeNetworkCost.unknown => NetworkCost.unknown,
    };
  }

  NetworkConstraint _constraint(native.NativeNetworkConstraint value) {
    return switch (value) {
      native.NativeNetworkConstraint.unconstrained =>
        NetworkConstraint.unconstrained,
      native.NativeNetworkConstraint.constrained =>
        NetworkConstraint.constrained,
      native.NativeNetworkConstraint.unknown => NetworkConstraint.unknown,
    };
  }

  NetworkFlag _flag(native.NativeNetworkFlag value) {
    return switch (value) {
      native.NativeNetworkFlag.yes => NetworkFlag.yes,
      native.NativeNetworkFlag.no => NetworkFlag.no,
      native.NativeNetworkFlag.unknown => NetworkFlag.unknown,
    };
  }

  BackgroundDataStatus _backgroundData(
    native.NativeBackgroundDataStatus value,
  ) {
    return switch (value) {
      native.NativeBackgroundDataStatus.allowed => BackgroundDataStatus.allowed,
      native.NativeBackgroundDataStatus.restricted =>
        BackgroundDataStatus.restricted,
      native.NativeBackgroundDataStatus.exempt => BackgroundDataStatus.exempt,
      native.NativeBackgroundDataStatus.unknown => BackgroundDataStatus.unknown,
    };
  }

  void _ensureSupported() {
    if (!_isSupported) {
      throw _unsupportedException;
    }
  }

  bool get _isSupported {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows => false,
    };
  }

  NetworkMonitorException get _unsupportedException {
    return const NetworkMonitorException(
      NetworkMonitorErrorCode.unsupportedPlatform,
      'adaptive_network_policy supports Android, iOS, and macOS.',
    );
  }

  NetworkMonitorException _translateError(Object error) {
    if (error is NetworkMonitorException) {
      return error;
    }
    if (error is MissingPluginException) {
      return NetworkMonitorException(
        NetworkMonitorErrorCode.unsupportedPlatform,
        'The native adaptive_network_policy implementation is unavailable.',
        cause: error,
      );
    }
    if (error is PlatformException) {
      final code =
          error.code == 'permission-denied'
              ? NetworkMonitorErrorCode.permissionDenied
              : NetworkMonitorErrorCode.nativeFailure;
      return NetworkMonitorException(
        code,
        error.message ?? 'The native network monitor failed.',
        cause: error,
      );
    }
    return NetworkMonitorException(
      NetworkMonitorErrorCode.nativeFailure,
      'The native network monitor failed unexpectedly.',
      cause: error,
    );
  }
}
