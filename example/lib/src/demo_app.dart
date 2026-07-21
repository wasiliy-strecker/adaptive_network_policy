import 'package:flutter/material.dart';

import 'demo_controller.dart';
import 'network_policy_dashboard.dart';

class DemoApp extends StatelessWidget {
  const DemoApp({super.key, this.controller});

  final DemoController? controller;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF54E1C1);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF0E1A29),
    );

    return MaterialApp(
      title: 'Adaptive Network Policy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF07111F),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          color: Color(0xFF0E1A29),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF142337),
          selectedColor: seed.withValues(alpha: 0.18),
          side: const BorderSide(color: Color(0xFF253750)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: NetworkPolicyDashboard(controller: controller),
    );
  }
}
