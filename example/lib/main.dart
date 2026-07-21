import 'package:adaptive_network_policy/adaptive_network_policy.dart';
import 'package:flutter/material.dart';

void main() => runApp(const NetworkConditionsHostApp());

/// Minimal native host used to exercise the plugin implementation.
class NetworkConditionsHostApp extends StatelessWidget {
  /// Creates the native plugin host.
  const NetworkConditionsHostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Adaptive Network Policy')),
        body: Center(
          child: FutureBuilder<NetworkConditions>(
            future: NetworkConditionsMonitor().current(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Native monitor failed: ${snapshot.error}');
              }
              final availability = snapshot.data?.availability.name;
              return Text(availability ?? 'Reading native conditions…');
            },
          ),
        ),
      ),
    );
  }
}
