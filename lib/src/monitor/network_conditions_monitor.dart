import '../model/network_conditions.dart';
import 'native_network_conditions_source.dart';
import 'network_conditions_source.dart';

/// Reads native conditions and exposes a stable, deduplicated stream.
final class NetworkConditionsMonitor implements NetworkConditionsSource {
  /// Creates a monitor backed by native APIs or an injected [source].
  NetworkConditionsMonitor({NetworkConditionsSource? source})
    : _source = source ?? NativeNetworkConditionsSource();

  final NetworkConditionsSource _source;

  late final Stream<NetworkConditions> _changes = _source.changes.distinct(
    (previous, next) => previous.hasSameStateAs(next),
  );

  @override
  Stream<NetworkConditions> get changes => _changes;

  @override
  Future<NetworkConditions> current() => _source.current();
}
