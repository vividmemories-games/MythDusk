import '../../puzzle/domain/overlay_def.dart';

/// Optional side-effect on an enemy skill (beyond base [EnemySkill.damage]).
class EnemyEffect {
  const EnemyEffect({
    required this.type,
    this.amount = 0,
    this.resourceId,
    this.overlayId,
    this.count = 1,
  });

  /// `damage` | `modify_moves` | `drain_resource` | `apply_overlay`
  final String type;
  final int amount;
  final String? resourceId;
  final String? overlayId;
  final int count;

  factory EnemyEffect.fromJson(Map<String, dynamic> json) {
    return EnemyEffect(
      type: json['type'] as String,
      amount: json['amount'] as int? ?? 0,
      resourceId: json['resourceId'] as String?,
      overlayId: json['overlayId'] as String?,
      count: json['count'] as int? ?? 1,
    );
  }

  String describe() => switch (type) {
        'modify_moves' =>
          amount < 0 ? '−${-amount} Move next turn' : '+$amount Move next turn',
        'drain_resource' => 'drain $amount ${resourceId ?? 'resource'}',
        'apply_overlay' => 'spread ${overlayId ?? 'hazard'} ×$count',
        'damage' => '$amount damage',
        _ => type,
      };

  /// Catalog defaults for known overlay ids (keeps domain free of asset IO).
  static OverlayDef? catalogOverlay(String? id) {
    return switch (id) {
      'ovl_poison' => const OverlayDef(
          id: 'ovl_poison',
          archetype: OverlayArchetype.binder,
          breakRule: OverlayBreakRule.matchUnder,
          hazard: OverlayHazard.suppressResources,
        ),
      'ovl_vine' => const OverlayDef(
          id: 'ovl_vine',
          archetype: OverlayArchetype.binder,
          breakRule: OverlayBreakRule.matchUnder,
        ),
      _ => null,
    };
  }
}
