import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mythora/features/battle/domain/battle_state.dart';
import 'package:mythora/features/campaign/domain/campaign_models.dart';
import 'package:mythora/features/puzzle/domain/board_movers.dart';
import 'package:mythora/features/puzzle/domain/level_board_config.dart';

void main() {
  test('Howling Ridge boardDefaults include dual row shove movers', () {
    final raw = File('assets/levels/howling_ridge.json').readAsStringSync();
    final chapter =
        CampaignChapter.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final movers = chapter.boardDefaults.effectiveMovers;
    expect(movers, hasLength(2));
    expect(movers[0].type, 'row_shove');
    expect(movers[0].rows, [2]);
    expect(movers[0].direction, 'left');
    expect(movers[0].everyNTurns, 1);
    expect(movers[1].rows, [4]);
    expect(movers[1].direction, 'right');
    expect(movers[1].everyNTurns, 2);

    final node = chapter.nodeById('ch_howling_n04');
    expect(node, isNotNull);
    expect(chapter.boardFor(node!).effectiveMovers, hasLength(2));
  });

  test('startPlayerTurn sets wind combat fx and status when movers due', () {
    const movers = [
      BoardMoverConfig(
        type: 'row_shove',
        rows: [2],
        direction: 'left',
        everyNTurns: 1,
      ),
    ];
    final controller = BattleController(
      BattleState.initial(movers: movers),
    );
    controller.startPlayerTurn(applyInline: true);

    expect(controller.state.combatFx, CombatFx.wind);
    expect(controller.state.windRows, {2});
    expect(controller.state.windDirection, 'left');
    expect(
      controller.state.log.any((line) => line.contains('Wind!')),
      isTrue,
    );
    expect(BoardMovers.dueOnTurn(movers, 1), hasLength(1));
  });

  test('clearCombatFx clears wind rows and direction', () {
    final controller = BattleController(
      BattleState.initial(
        movers: const [
          BoardMoverConfig(type: 'row_shove', rows: [1], direction: 'right'),
        ],
      ),
    );
    controller.startPlayerTurn(applyInline: true);
    expect(controller.state.windRows, isNotEmpty);
    expect(controller.state.windDirection, 'right');
    controller.clearCombatFx();
    expect(controller.state.combatFx, CombatFx.none);
    expect(controller.state.windRows, isEmpty);
    expect(controller.state.windDirection, isNull);
  });
}
