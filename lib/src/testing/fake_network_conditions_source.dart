import 'dart:async';

import '../model/network_conditions.dart';
import '../monitor/network_conditions_source.dart';

/// A controllable source for unit tests, demos, and unsupported platforms.
final class FakeNetworkConditionsSource implements NetworkConditionsSource {
  /// Creates a source whose first emitted value is [initial].
  FakeNetworkConditionsSource(NetworkConditions initial) : _current = initial;

  final StreamController<NetworkConditions> _updates =
      StreamController<NetworkConditions>.broadcast(sync: true);
  NetworkConditions _current;
  bool _closed = false;

  @override
  Stream<NetworkConditions> get changes {
    return Stream<NetworkConditions>.multi((controller) {
      controller.add(_current);
      final subscription = _updates.stream.listen(
        controller.addSync,
        onError: controller.addErrorSync,
        onDone: controller.closeSync,
      );
      controller.onCancel = subscription.cancel;
    }, isBroadcast: true);
  }

  @override
  Future<NetworkConditions> current() async => _current;

  /// Publishes [conditions] to active listeners and makes it current.
  void emit(NetworkConditions conditions) {
    if (_closed) {
      throw StateError('Cannot emit after the fake source is closed.');
    }
    _current = conditions;
    _updates.add(conditions);
  }

  /// Completes active streams and releases the controller.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _updates.close();
  }
}
