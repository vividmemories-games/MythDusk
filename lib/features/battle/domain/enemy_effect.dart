import '../../puzzle/domain/overlay_def.dart';

/// Stable wire discriminators for data-driven enemy effects.
enum EnemyEffectType {
  modifyMoves('modify_moves'),
  drainResource('drain_resource'),
  applyOverlay('apply_overlay');

  const EnemyEffectType(this.wireName);

  final String wireName;

  static EnemyEffectType parse(Object? raw) {
    for (final type in values) {
      if (type.wireName == raw) return type;
    }
    throw FormatException('Unsupported enemy effect type: $raw');
  }
}

/// Resource ids an enemy effect may drain from the player.
enum BattleResource {
  attack,
  mana,
  healing,
  shield,
  ultimate;

  String get id => name;

  static BattleResource parse(Object? raw) {
    for (final resource in values) {
      if (resource.id == raw) return resource;
    }
    throw FormatException('Unknown battle resource: $raw');
  }
}

/// Typed optional side-effect on an enemy skill.
///
/// Base hit damage remains on `EnemySkill.damage`; it is deliberately not an
/// effect subtype, which prevents a second damage path from being ignored or
/// applied twice.
sealed class EnemyEffect {
  const EnemyEffect();

  EnemyEffectType get type;

  String describe();

  Map<String, Object> toJson();

  /// Preserves the previous weekly-scaling behavior: only resource drains
  /// scale with enemy damage. Move penalties and overlay counts stay fixed.
  EnemyEffect scaled({required double damageMultiplier});

  factory EnemyEffect.fromJson(Map<String, dynamic> json) {
    final type = EnemyEffectType.parse(json['type']);
    return switch (type) {
      EnemyEffectType.modifyMoves => ModifyMovesEffect(
          amount: _negativeInt(json, 'amount'),
        ),
      EnemyEffectType.drainResource => DrainResourceEffect(
          resource: BattleResource.parse(json['resourceId']),
          amount: _positiveInt(json, 'amount'),
        ),
      EnemyEffectType.applyOverlay => _parseApplyOverlay(json),
    };
  }

  static bool supportsOverlay(String id) => switch (id) {
        'ovl_poison' || 'ovl_vine' => true,
        _ => false,
      };

  /// Catalog defaults for enemy-applied overlays.
  ///
  /// Throws instead of silently ignoring an effect that the battle resolver
  /// cannot execute.
  static OverlayDef requireCatalogOverlay(String id) {
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
      _ => throw StateError('Unsupported enemy overlay: $id'),
    };
  }

  static ApplyOverlayEffect _parseApplyOverlay(Map<String, dynamic> json) {
    final overlayId = _requiredString(json, 'overlayId');
    if (!supportsOverlay(overlayId)) {
      throw FormatException('Unsupported enemy overlay: $overlayId');
    }
    final count = json['count'] == null ? 1 : _positiveInt(json, 'count');
    return ApplyOverlayEffect(overlayId: overlayId, count: count);
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw FormatException('Enemy effect $key must be an integer');
    }
    return value;
  }

  static int _negativeInt(Map<String, dynamic> json, String key) {
    final value = _requiredInt(json, key);
    if (value >= 0) {
      throw FormatException('Enemy effect $key must be negative');
    }
    return value;
  }

  static int _positiveInt(Map<String, dynamic> json, String key) {
    final value = _requiredInt(json, key);
    if (value <= 0) {
      throw FormatException('Enemy effect $key must be positive');
    }
    return value;
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Enemy effect $key must be a non-empty string');
    }
    return value;
  }
}

final class ModifyMovesEffect extends EnemyEffect {
  const ModifyMovesEffect({required this.amount}) : assert(amount < 0);

  /// Negative move delta applied to the next player turn.
  final int amount;

  @override
  EnemyEffectType get type => EnemyEffectType.modifyMoves;

  @override
  String describe() => '−${-amount} Move next turn';

  @override
  Map<String, Object> toJson() => {
        'type': type.wireName,
        'amount': amount,
      };

  @override
  EnemyEffect scaled({required double damageMultiplier}) => this;
}

final class DrainResourceEffect extends EnemyEffect {
  const DrainResourceEffect({
    required this.resource,
    required this.amount,
  }) : assert(amount > 0);

  final BattleResource resource;
  final int amount;

  @override
  EnemyEffectType get type => EnemyEffectType.drainResource;

  @override
  String describe() => 'drain $amount ${resource.id}';

  @override
  Map<String, Object> toJson() => {
        'type': type.wireName,
        'resourceId': resource.id,
        'amount': amount,
      };

  @override
  EnemyEffect scaled({required double damageMultiplier}) {
    final scaledAmount = (amount * damageMultiplier).round().clamp(1, 999);
    if (scaledAmount == amount) return this;
    return DrainResourceEffect(resource: resource, amount: scaledAmount);
  }
}

final class ApplyOverlayEffect extends EnemyEffect {
  const ApplyOverlayEffect({
    required this.overlayId,
    this.count = 1,
  })  : assert(overlayId != ''),
        assert(count > 0);

  final String overlayId;
  final int count;

  @override
  EnemyEffectType get type => EnemyEffectType.applyOverlay;

  @override
  String describe() => 'spread $overlayId ×$count';

  @override
  Map<String, Object> toJson() => {
        'type': type.wireName,
        'overlayId': overlayId,
        'count': count,
      };

  @override
  EnemyEffect scaled({required double damageMultiplier}) => this;
}
