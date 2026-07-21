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

Native Android and Apple observations are added in the next focused commit.
