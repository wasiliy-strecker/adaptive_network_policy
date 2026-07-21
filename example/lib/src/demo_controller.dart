import 'dart:async';

import 'package:adaptive_network_policy/adaptive_network_policy.dart';
import 'package:adaptive_network_policy/testing.dart';
import 'package:flutter/foundation.dart';

import 'demo_scenarios.dart';

enum DemoMode { live, simulation }

enum OperationProfile { interactive, backgroundSync, bulkTransfer, strict }

extension OperationProfileDetails on OperationProfile {
  String get label => switch (this) {
    OperationProfile.interactive => 'Interactive API',
    OperationProfile.backgroundSync => 'Background sync',
    OperationProfile.bulkTransfer => 'Bulk transfer',
    OperationProfile.strict => 'Strict upload',
  };

  String get description => switch (this) {
    OperationProfile.interactive => 'User-initiated; prefers responsiveness',
    OperationProfile.backgroundSync => 'Defers constrained or roaming work',
    OperationProfile.bulkTransfer => 'Requires a cost-friendly path',
    OperationProfile.strict => 'Also defers unknown native capabilities',
  };

  NetworkRequirements get requirements => switch (this) {
    OperationProfile.interactive => const NetworkRequirements.interactive(),
    OperationProfile.backgroundSync =>
      const NetworkRequirements.backgroundSync(),
    OperationProfile.bulkTransfer => const NetworkRequirements.bulkTransfer(),
    OperationProfile.strict => const NetworkRequirements.bulkTransfer()
        .copyWith(
          requiresValidatedInternet: true,
          unknownCapabilityBehavior: UnknownCapabilityBehavior.defer,
        ),
  };

  String get code => switch (this) {
    OperationProfile.interactive => 'const NetworkRequirements.interactive()',
    OperationProfile.backgroundSync =>
      'const NetworkRequirements.backgroundSync()',
    OperationProfile.bulkTransfer => 'const NetworkRequirements.bulkTransfer()',
    OperationProfile.strict =>
      '''const NetworkRequirements.bulkTransfer().copyWith(
  requiresValidatedInternet: true,
  unknownCapabilityBehavior: UnknownCapabilityBehavior.defer,
)''',
  };
}

class DemoController extends ChangeNotifier {
  DemoController({
    bool forceSimulation = false,
    NetworkConditionsSource? liveSource,
  }) : _liveSource = liveSource,
       _liveAvailable = !forceSimulation && _supportsNativePlatform,
       _scenario = DemoScenario.fastWifi,
       _conditions = DemoScenario.fastWifi.snapshot(),
       _fake = FakeNetworkConditionsSource(DemoScenario.fastWifi.snapshot()) {
    _mode = _liveAvailable ? DemoMode.live : DemoMode.simulation;
  }

  final NetworkConditionsSource? _liveSource;
  final bool _liveAvailable;
  final FakeNetworkConditionsSource _fake;
  final NetworkPolicyEvaluator _evaluator = const NetworkPolicyEvaluator();

  late DemoMode _mode;
  DemoScenario _scenario;
  NetworkConditions _conditions;
  OperationProfile _profile = OperationProfile.interactive;
  StreamSubscription<NetworkConditions>? _subscription;
  Object? _error;
  bool _loading = false;
  bool _started = false;
  bool _disposed = false;
  int _generation = 0;

  DemoMode get mode => _mode;
  bool get liveAvailable => _liveAvailable;
  DemoScenario get scenario => _scenario;
  NetworkConditions get conditions => _conditions;
  OperationProfile get profile => _profile;
  NetworkDecision get decision =>
      _evaluator.evaluate(_conditions, _profile.requirements);
  Object? get error => _error;
  bool get loading => _loading;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    await _connect();
  }

  Future<void> switchMode(DemoMode mode) async {
    if (mode == _mode || (mode == DemoMode.live && !_liveAvailable)) {
      return;
    }
    _mode = mode;
    await _connect();
  }

  void selectScenario(DemoScenario scenario) {
    _scenario = scenario;
    if (_mode == DemoMode.simulation) {
      _fake.emit(scenario.snapshot());
    }
    _notify();
  }

  void selectProfile(OperationProfile profile) {
    if (_profile == profile) {
      return;
    }
    _profile = profile;
    _notify();
  }

  Future<void> retry() => _connect();

  Future<void> _connect() async {
    final generation = ++_generation;
    await _subscription?.cancel();
    _subscription = null;

    _loading = true;
    _error = null;
    _notify();

    final source = switch (_mode) {
      DemoMode.live => _liveSource ?? NetworkConditionsMonitor(),
      DemoMode.simulation => NetworkConditionsMonitor(source: _fake),
    };

    _subscription = source.changes.listen(
      (conditions) => _accept(conditions, generation),
      onError: (Object error, StackTrace stackTrace) {
        if (generation != _generation) {
          return;
        }
        _error = error;
        _loading = false;
        _notify();
      },
    );

    try {
      final conditions = await source.current();
      _accept(conditions, generation);
    } on Object catch (error) {
      if (generation != _generation) {
        return;
      }
      _error = error;
      _loading = false;
      _notify();
    }
  }

  void _accept(NetworkConditions conditions, int generation) {
    if (generation != _generation) {
      return;
    }
    _conditions = conditions;
    _loading = false;
    _error = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_subscription?.cancel());
    unawaited(_fake.close());
    super.dispose();
  }

  static bool get _supportsNativePlatform {
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
}
