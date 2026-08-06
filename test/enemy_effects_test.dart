import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/battle_state.dart';
import 'package:mythdusk/features/battle/domain/enemy_def.dart';
import 'package:mythdusk/features/battle/domain/enemy_effect.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/puzzle/domain/board_cell.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_board.dart';
import 'package:mythdusk/features/puzzle/domain/tile_color.dart';
import 'package:mythdusk/features/puzzle/domain/tile_id_gen.dart';

void main() {
  test('mire smother intent mentions poison overlay', () {
    final smother =
        EnemyCatalog.mireSpawn.skills.firstWhere((s) => s.id == 'smother');
    expect(smother.effects, isNotEmpty);
    expect(smother.intentLabel, contains('poison'));
  });

  test('pack howl applies move penalty for next player turn', () {
    final howl =
        EnemyCatalog.packAlpha.skills.firstWhere((s) => s.id == 'howl');
    expect(howl.effects.whereType<ModifyMovesEffect>(), hasLength(1));

    final controller = BattleController(
      BattleState.initial(
        hero: HeroCatalog.mage,
        enemy: EnemyCatalog.packAlpha,
      ),
      random: Random(1),
    );
    controller.startPlayerTurn(applyInline: true);
    final budget = controller.state.movesPerTurn;
    controller.applyEnemySkill(howl);
    expect(controller.state.pendingMovePenalty, 1);

    controller.startPlayerTurn(applyInline: true);
    expect(controller.state.movesLeft, budget - 1);
    expect(controller.state.pendingMovePenalty, 0);
  });

  test('apply_overlay spreads poison binders onto playable tiles', () {
    final ids = TileIdGen(1);
    final cells = [
      for (var i = 0; i < 4; i++)
        BoardCell.tile(id: ids.next(), color: TileColor.red),
    ];
    final board = PuzzleBoard(width: 2, height: 2, cells: cells);
    final controller = BattleController(
      BattleState.initial(
        hero: HeroCatalog.mage,
        enemy: EnemyCatalog.mireSpawn,
        board: board,
        ids: ids,
      ),
      random: Random(2),
      ids: ids,
    );
    const smother = EnemySkill(
      id: 'smother',
      name: 'Smother',
      damage: 0,
      weight: 1,
      effects: [
        ApplyOverlayEffect(overlayId: 'ovl_poison', count: 2),
      ],
    );
    controller.applyEnemySkill(smother);
    final poisoned = controller.state.board.cells
        .where((c) => c.overlayId == 'ovl_poison')
        .length;
    expect(poisoned, 2);
    expect(controller.state.hazardPulseCells, hasLength(2));
    expect(controller.state.combatFx, CombatFx.hazard);
  });

  test('drain_resource removes only the typed resource and clamps at zero', () {
    final controller = BattleController(
      BattleState.initial(
        hero: HeroCatalog.mage,
        enemy: EnemyCatalog.shaman,
      ).copyWith(
        resources: const {
          'attack': 4,
          'mana': 5,
          'healing': 0,
          'shield': 0,
          'ultimate': 0,
        },
      ),
      random: Random(3),
    );
    const drain = EnemySkill(
      id: 'mana_drain',
      name: 'Mana Drain',
      damage: 0,
      weight: 1,
      effects: [
        DrainResourceEffect(resource: BattleResource.mana, amount: 8),
      ],
    );

    controller.applyEnemySkill(drain);

    expect(controller.state.resources['mana'], 0);
    expect(controller.state.resources['attack'], 4);
    expect(controller.state.log.last, 'Drained 8 mana');
  });

  test('resolver throws instead of silently ignoring an unsupported overlay',
      () {
    final controller = BattleController(
      BattleState.initial(
        hero: HeroCatalog.mage,
        enemy: EnemyCatalog.mireSpawn,
      ),
      random: Random(4),
    );
    const invalid = EnemySkill(
      id: 'invalid_overlay',
      name: 'Invalid Overlay',
      damage: 0,
      weight: 1,
      effects: [ApplyOverlayEffect(overlayId: 'ovl_unknown')],
    );

    expect(
      () => controller.applyEnemySkill(invalid),
      throwsA(isA<StateError>()),
    );
  });
}
