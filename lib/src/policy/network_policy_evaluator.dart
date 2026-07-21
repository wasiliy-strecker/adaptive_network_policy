import '../model/network_conditions.dart';
import 'network_decision.dart';
import 'network_requirements.dart';

/// Applies [NetworkRequirements] without performing I/O or scheduling work.
final class NetworkPolicyEvaluator {
  /// Creates a stateless policy evaluator.
  const NetworkPolicyEvaluator();

  /// Evaluates [conditions] against [requirements] without side effects.
  NetworkDecision evaluate(
    NetworkConditions conditions,
    NetworkRequirements requirements,
  ) {
    final reasons = <NetworkDecisionReason>{};

    if (requirements.requiresInternet ||
        requirements.requiresValidatedInternet) {
      _evaluateAvailability(conditions, requirements, reasons);
    }

    _evaluateCost(conditions, requirements, reasons);
    _evaluateConstraint(conditions, requirements, reasons);
    _evaluateFlag(
      value: conditions.isRoaming,
      allowsValue: requirements.allowsRoaming,
      activeReason: NetworkDecisionReason.roaming,
      unknownReason: NetworkDecisionReason.unknownRoaming,
      requirements: requirements,
      reasons: reasons,
    );
    _evaluateFlag(
      value: conditions.isCongested,
      allowsValue: requirements.allowsCongested,
      activeReason: NetworkDecisionReason.congested,
      unknownReason: NetworkDecisionReason.unknownCongestion,
      requirements: requirements,
      reasons: reasons,
    );

    if (conditions.isSuspended == NetworkFlag.yes) {
      reasons.add(NetworkDecisionReason.suspended);
    } else if (conditions.isSuspended == NetworkFlag.unknown &&
        _defersUnknown(requirements)) {
      reasons.add(NetworkDecisionReason.unknownSuspension);
    }

    if (!requirements.allowsRestrictedBackgroundData) {
      switch (conditions.backgroundData) {
        case BackgroundDataStatus.restricted:
          reasons.add(NetworkDecisionReason.backgroundDataRestricted);
          break;
        case BackgroundDataStatus.unknown when _defersUnknown(requirements):
          reasons.add(NetworkDecisionReason.unknownBackgroundDataStatus);
          break;
        case BackgroundDataStatus.allowed:
        case BackgroundDataStatus.exempt:
        case BackgroundDataStatus.unknown:
          break;
      }
    }

    return reasons.isEmpty ? const NetworkAllowed() : NetworkDeferred(reasons);
  }

  void _evaluateAvailability(
    NetworkConditions conditions,
    NetworkRequirements requirements,
    Set<NetworkDecisionReason> reasons,
  ) {
    switch (conditions.availability) {
      case NetworkAvailability.unavailable:
        reasons.add(NetworkDecisionReason.networkUnavailable);
        break;
      case NetworkAvailability.requiresConnection:
        reasons.add(NetworkDecisionReason.connectionRequired);
        break;
      case NetworkAvailability.localOnly:
        reasons.add(NetworkDecisionReason.localNetworkOnly);
        break;
      case NetworkAvailability.captivePortal:
        reasons.add(NetworkDecisionReason.captivePortal);
        break;
      case NetworkAvailability.unknown:
        reasons.add(NetworkDecisionReason.unknownAvailability);
        break;
      case NetworkAvailability.internetConfigured:
        if (requirements.requiresValidatedInternet) {
          reasons.add(NetworkDecisionReason.internetNotValidated);
        }
        break;
      case NetworkAvailability.validatedInternet:
        break;
    }
  }

  void _evaluateCost(
    NetworkConditions conditions,
    NetworkRequirements requirements,
    Set<NetworkDecisionReason> reasons,
  ) {
    if (requirements.allowsMetered) {
      return;
    }
    switch (conditions.cost) {
      case NetworkCost.metered:
        reasons.add(NetworkDecisionReason.metered);
        break;
      case NetworkCost.unknown when _defersUnknown(requirements):
        reasons.add(NetworkDecisionReason.unknownCost);
        break;
      case NetworkCost.unmetered:
      case NetworkCost.temporarilyUnmetered:
      case NetworkCost.unknown:
        break;
    }
  }

  void _evaluateConstraint(
    NetworkConditions conditions,
    NetworkRequirements requirements,
    Set<NetworkDecisionReason> reasons,
  ) {
    if (requirements.allowsConstrained) {
      return;
    }
    switch (conditions.constraint) {
      case NetworkConstraint.constrained:
        reasons.add(NetworkDecisionReason.constrained);
        break;
      case NetworkConstraint.unknown when _defersUnknown(requirements):
        reasons.add(NetworkDecisionReason.unknownConstraint);
        break;
      case NetworkConstraint.unconstrained:
      case NetworkConstraint.unknown:
        break;
    }
  }

  void _evaluateFlag({
    required NetworkFlag value,
    required bool allowsValue,
    required NetworkDecisionReason activeReason,
    required NetworkDecisionReason unknownReason,
    required NetworkRequirements requirements,
    required Set<NetworkDecisionReason> reasons,
  }) {
    if (allowsValue) {
      return;
    }
    if (value == NetworkFlag.yes) {
      reasons.add(activeReason);
    } else if (value == NetworkFlag.unknown && _defersUnknown(requirements)) {
      reasons.add(unknownReason);
    }
  }

  bool _defersUnknown(NetworkRequirements requirements) {
    return requirements.unknownCapabilityBehavior ==
        UnknownCapabilityBehavior.defer;
  }
}
