# adaptive_network_policy

Native network conditions and deterministic execution policies for Flutter
applications.

The pure Dart layer keeps observation and execution policy separate. It offers
immutable network snapshots, explicit allow/defer decisions, presets for
interactive work, background synchronization, and bulk transfers, plus an
injectable source for deterministic tests.

```dart
const evaluator = NetworkPolicyEvaluator();
const requirements = NetworkRequirements.bulkTransfer();

final decision = evaluator.evaluate(conditions, requirements);
if (decision.shouldRun) {
  await upload.run();
}
```

Native observations are available through generated, typed Pigeon channels:

- Android uses `ConnectivityManager` for validation, cost, constraints,
  roaming, congestion, suspension, Data Saver, and link estimates.
- iOS and macOS share a Swift `NWPathMonitor` implementation for availability,
  transport, transfer cost, and Low Data Mode.

Unsupported capabilities remain `unknown` instead of being inferred. The
package performs no probe requests and does not schedule application work.
