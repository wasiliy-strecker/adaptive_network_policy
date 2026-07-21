import 'package:adaptive_network_policy/adaptive_network_policy.dart';
import 'package:flutter/material.dart';

import 'demo_controller.dart';
import 'demo_scenarios.dart';

class NetworkPolicyDashboard extends StatefulWidget {
  const NetworkPolicyDashboard({super.key, this.controller});

  final DemoController? controller;

  @override
  State<NetworkPolicyDashboard> createState() => _NetworkPolicyDashboardState();
}

class _NetworkPolicyDashboardState extends State<NetworkPolicyDashboard> {
  late final DemoController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? DemoController();
    _controller.start();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverSafeArea(
                sliver: SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(controller: _controller),
                            const SizedBox(height: 24),
                            if (_controller.error != null) ...[
                              _ErrorBanner(controller: _controller),
                              const SizedBox(height: 16),
                            ],
                            _ResponsiveOverview(controller: _controller),
                            const SizedBox(height: 16),
                            _ConditionsCard(conditions: _controller.conditions),
                            const SizedBox(height: 16),
                            _CodeCard(controller: _controller),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final DemoController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(Icons.route_rounded, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADAPTIVE NETWORK POLICY',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Native signals → deterministic decisions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final mode = SegmentedButton<DemoMode>(
      key: const Key('mode-selector'),
      segments: [
        ButtonSegment(
          value: DemoMode.live,
          enabled: controller.liveAvailable,
          icon: const Icon(Icons.sensors_rounded),
          label: const Text('Live'),
        ),
        const ButtonSegment(
          value: DemoMode.simulation,
          icon: Icon(Icons.science_outlined),
          label: Text('Simulation'),
        ),
      ],
      selected: {controller.mode},
      onSelectionChanged: (selection) {
        controller.switchMode(selection.first);
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Row(
            children: [Expanded(child: title), const SizedBox(width: 24), mode],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [title, const SizedBox(height: 18), mode],
        );
      },
    );
  }
}

class _ResponsiveOverview extends StatelessWidget {
  const _ResponsiveOverview({required this.controller});

  final DemoController controller;

  @override
  Widget build(BuildContext context) {
    final scenarios = _ScenariosCard(controller: controller);
    final decision = _DecisionCard(controller: controller);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: scenarios),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: decision),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [scenarios, const SizedBox(height: 16), decision],
        );
      },
    );
  }
}

class _ScenariosCard extends StatelessWidget {
  const _ScenariosCard({required this.controller});

  final DemoController controller;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: controller.mode == DemoMode.live ? 'Native path' : 'Test scenario',
      subtitle:
          controller.mode == DemoMode.live
              ? 'Updates arrive directly from the operating system.'
              : controller.scenario.description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.mode == DemoMode.simulation)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final scenario in DemoScenario.values)
                  ChoiceChip(
                    key: Key('scenario-${scenario.name}'),
                    label: Text(scenario.label),
                    selected: scenario == controller.scenario,
                    onSelected: (_) => controller.selectScenario(scenario),
                  ),
              ],
            )
          else
            _LiveStatus(conditions: controller.conditions),
          if (controller.loading) ...[
            const SizedBox(height: 18),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }
}

class _LiveStatus extends StatelessWidget {
  const _LiveStatus({required this.conditions});

  final NetworkConditions conditions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.wifi_tethering_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Listening · ${_label(conditions.availability.name)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.controller});

  final DemoController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decision = controller.decision;
    final allowed = decision.shouldRun;
    final color = allowed ? theme.colorScheme.primary : const Color(0xFFFFB86B);
    final reasons =
        decision is NetworkDeferred
            ? decision.reasons.map((reason) => _label(reason.name)).toList()
            : const <String>[];

    return _Panel(
      title: 'Execution policy',
      subtitle: controller.profile.description,
      trailing: Container(
        key: const Key('decision-badge'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              allowed ? Icons.play_arrow_rounded : Icons.schedule_rounded,
              size: 17,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              allowed ? 'Run now' : 'Defer',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final profile in OperationProfile.values)
                ChoiceChip(
                  key: Key('profile-${profile.name}'),
                  label: Text(profile.label),
                  selected: profile == controller.profile,
                  onSelected: (_) => controller.selectProfile(profile),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (allowed)
            Text(
              'Every declared requirement is satisfied.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final reason in reasons)
                  _ReasonBadge(label: reason, color: color),
              ],
            ),
        ],
      ),
    );
  }
}

class _ConditionsCard extends StatelessWidget {
  const _ConditionsCard({required this.conditions});

  final NetworkConditions conditions;

  @override
  Widget build(BuildContext context) {
    final transports =
        conditions.transports.isEmpty
            ? 'None'
            : conditions.transports
                .map((value) => _label(value.name))
                .join(', ');
    final bandwidth = switch ((
      conditions.downlinkKbps,
      conditions.uplinkKbps,
    )) {
      (final int down, final int up) => '${_speed(down)} ↓  ${_speed(up)} ↑',
      (final int down, null) => '${_speed(down)} ↓',
      (null, final int up) => '${_speed(up)} ↑',
      (null, null) => 'Unknown',
    };

    return _Panel(
      title: 'Observed conditions',
      subtitle: 'A normalized snapshot; unsupported capabilities stay unknown.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth =
              constraints.maxWidth >= 900
                  ? (constraints.maxWidth - 3 * 10) / 4
                  : constraints.maxWidth >= 520
                  ? (constraints.maxWidth - 10) / 2
                  : constraints.maxWidth;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SignalTile(
                width: tileWidth,
                icon: Icons.public_rounded,
                label: 'Availability',
                value: _label(conditions.availability.name),
              ),
              _SignalTile(
                width: tileWidth,
                icon: Icons.cell_tower_rounded,
                label: 'Transport',
                value: transports,
              ),
              _SignalTile(
                width: tileWidth,
                icon: Icons.data_usage_rounded,
                label: 'Cost · constraint',
                value:
                    '${_label(conditions.cost.name)} · ${_label(conditions.constraint.name)}',
              ),
              _SignalTile(
                width: tileWidth,
                icon: Icons.speed_rounded,
                label: 'Estimated bandwidth',
                value: bandwidth,
              ),
              _SignalTile(
                width: tileWidth,
                icon: Icons.travel_explore_rounded,
                label: 'Roaming',
                value: _label(conditions.isRoaming.name),
              ),
              _SignalTile(
                width: tileWidth,
                icon: Icons.traffic_rounded,
                label: 'Congested',
                value: _label(conditions.isCongested.name),
              ),
              _SignalTile(
                width: tileWidth,
                icon: Icons.pause_circle_outline_rounded,
                label: 'Suspended',
                value: _label(conditions.isSuspended.name),
              ),
              _SignalTile(
                width: tileWidth,
                icon: Icons.sync_lock_rounded,
                label: 'Background data',
                value: _label(conditions.backgroundData.name),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.controller});

  final DemoController controller;

  @override
  Widget build(BuildContext context) {
    final code = '''final requirements = ${controller.profile.code};
final decision = const NetworkPolicyEvaluator().evaluate(
  conditions,
  requirements,
);

if (decision.shouldRun) {
  await operation.run();
}''';
    return _Panel(
      title: 'Policy, not scheduler',
      subtitle:
          'The package returns a deterministic decision. Your app owns execution and retries.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF07111F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF20324A)),
        ),
        child: SelectableText(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.55,
            color: Color(0xFFC5D4E8),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF1C2D43)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF122034),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF20324A)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonBadge extends StatelessWidget {
  const _ReasonBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.controller});

  final DemoController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded),
            const SizedBox(width: 12),
            Expanded(child: Text('${controller.error}')),
            TextButton(onPressed: controller.retry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _label(String value) {
  final words = value.replaceAllMapped(
    RegExp('([a-z0-9])([A-Z])'),
    (match) => '${match[1]} ${match[2]}',
  );
  return '${words[0].toUpperCase()}${words.substring(1)}';
}

String _speed(int kbps) {
  if (kbps >= 1000) {
    final mbps = kbps / 1000;
    return '${mbps >= 10 ? mbps.toStringAsFixed(0) : mbps.toStringAsFixed(1)} Mbps';
  }
  return '$kbps Kbps';
}
