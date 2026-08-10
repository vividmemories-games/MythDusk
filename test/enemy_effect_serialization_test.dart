import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/enemy_def.dart';
import 'package:mythdusk/features/battle/domain/enemy_effect.dart';

void main() {
  group('EnemyEffect serialization', () {
    test('every supported type round-trips through its stable wire format', () {
      const effects = <EnemyEffect>[
        ModifyMovesEffect(amount: -1),
        DrainResourceEffect(resource: BattleResource.mana, amount: 3),
        ApplyOverlayEffect(overlayId: 'ovl_poison', count: 2),
        HealSelfEffect(amount: 8),
        ModifySpawnWeightsEffect(weights: {'purple': 3.0, 'green': 0.25}),
      ];

      for (final original in effects) {
        final decoded = EnemyEffect.fromJson(original.toJson());
        expect(decoded.runtimeType, original.runtimeType);
        expect(decoded.toJson(), original.toJson());
      }
    });

    test('apply_overlay defaults count to one', () {
      final effect = EnemyEffect.fromJson({
        'type': 'apply_overlay',
        'overlayId': 'ovl_vine',
      });

      expect(effect, isA<ApplyOverlayEffect>());
      expect((effect as ApplyOverlayEffect).count, 1);
    });

    test('rejects unsupported or previously ignored effect types', () {
      expect(
        () => EnemyEffect.fromJson({'type': 'damage', 'amount': 10}),
        throwsFormatException,
      );
      expect(
        () => EnemyEffect.fromJson({'type': 'unknown'}),
        throwsFormatException,
      );
    });

    test('rejects invalid effect parameters', () {
      final invalid = <Map<String, dynamic>>[
        {'type': 'modify_moves', 'amount': 0},
        {'type': 'modify_moves', 'amount': 1},
        {'type': 'modify_moves', 'amount': -1.5},
        {'type': 'drain_resource', 'amount': 2},
        {'type': 'drain_resource', 'resourceId': 'rage', 'amount': 2},
        {'type': 'drain_resource', 'resourceId': 'mana', 'amount': 0},
        {'type': 'apply_overlay', 'count': 1},
        {'type': 'apply_overlay', 'overlayId': 'ovl_unknown', 'count': 1},
        {'type': 'apply_overlay', 'overlayId': 'ovl_poison', 'count': 0},
        {'type': 'heal_self', 'amount': 0},
        {'type': 'heal_self', 'amount': -2},
        {'type': 'modify_spawn_weights'},
        {'type': 'modify_spawn_weights', 'weights': <String, Object>{}},
        {
          'type': 'modify_spawn_weights',
          'weights': {'orange': 2},
        },
        {
          'type': 'modify_spawn_weights',
          'weights': {'purple': -1},
        },
      ];

      for (final json in invalid) {
        expect(
          () => EnemyEffect.fromJson(json),
          throwsFormatException,
          reason: '$json should be rejected',
        );
      }
    });
  });

  test('EnemyDef scaling scales drains but preserves structural effects', () {
    const enemy = EnemyDef(
      id: 'typed_effect_fixture',
      name: 'Typed Effect Fixture',
      maxHp: 10,
      skills: [
        EnemySkill(
          id: 'mixed',
          name: 'Mixed',
          damage: 5,
          weight: 100,
          effects: [
            ModifyMovesEffect(amount: -1),
            DrainResourceEffect(resource: BattleResource.mana, amount: 3),
            ApplyOverlayEffect(overlayId: 'ovl_poison', count: 2),
            HealSelfEffect(amount: 5),
            ModifySpawnWeightsEffect(weights: {'purple': 2.0}),
          ],
        ),
      ],
    );

    final effects = enemy.scaled(damageMult: 2).skills.single.effects;

    expect((effects[0] as ModifyMovesEffect).amount, -1);
    expect((effects[1] as DrainResourceEffect).amount, 6);
    expect((effects[2] as ApplyOverlayEffect).count, 2);
    expect((effects[3] as HealSelfEffect).amount, 5);
    expect(
      (effects[4] as ModifySpawnWeightsEffect).weights,
      {'purple': 2.0},
    );
  });
}
