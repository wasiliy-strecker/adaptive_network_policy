import '../model/network_conditions.dart';

/// Replaceable source for current and changing network conditions.
abstract interface class NetworkConditionsSource {
  /// Reads the most recent conditions from the source.
  Future<NetworkConditions> current();

  /// Emits an initial snapshot followed by subsequent semantic changes.
  Stream<NetworkConditions> get changes;
}
