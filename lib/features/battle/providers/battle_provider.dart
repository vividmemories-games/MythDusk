import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../campaign/data/campaign_repository.dart';
import '../../heroes/domain/hero_def.dart';
import '../../prep/domain/prep_item.dart';
import '../../profile/domain/economy_balance.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../../puzzle/data/board_catalog_repository.dart';
import '../../puzzle/domain/board_builder.dart';
import '../../puzzle/domain/level_board_config.dart';
import '../../puzzle/domain/overlay_def.dart';
import '../../puzzle/domain/puzzle_board.dart';
import '../../puzzle/domain/puzzle_engine.dart';
import '../../weekly/domain/weekly_schedule.dart';
import '../../weekly/providers/weekly_providers.dart';
import '../domain/battle_state.dart';
import '../domain/enemy_def.dart';

final battleProvider = StateNotifierProvider.autoDispose
    .family<BattleNotifier, BattleState, String>((ref, nodeId) {
  // Watch hero id + upgrades so prep inventory updates do not reset the battle.
  final heroId = ref.watch(profileProvider.select((p) => p.selectedHeroId));
  final upgradeSnapshot = ref.watch(
    profileProvider.select(
      (p) => (
        p.upgradeLevel(EconomyBalance.upgradeStatHp, heroId),
        p.upgradeLevel(EconomyBalance.upgradeStatDamage, heroId),
        p.upgradeLevel(EconomyBalance.upgradeStatShield, heroId),
      ),
    ),
  );
  final equippedIds = ref.watch(
    profileProvider.select((p) => p.equippedSkillIdsFor(heroId).join(',')),
  );
  final hero = HeroCatalog.byId(heroId)
      .withCombatMultipliers(
        hpMult: EconomyBalance.multiplierFor(upgradeSnapshot.$1),
        damageMult: EconomyBalance.multiplierFor(upgradeSnapshot.$2),
        shieldMult: EconomyBalance.multiplierFor(upgradeSnapshot.$3),
      )
      .withEquippedSkillIds(
          equippedIds.split(',').where((id) => id.isNotEmpty).toList());

  final isWeekly = nodeId == WeeklyBalance.battleNodeId;
  if (isWeekly) {
    final challenge = ref.watch(weeklyChallengeProvider);
    final equipped = List<PrepItemId>.from(ref.read(pendingBossPrepProvider));
    if (equipped.isNotEmpty) {
      ref.read(pendingBossPrepProvider.notifier).state = const [];
    }
    final enemy = EnemyCatalog.byId(challenge.enemyId).scaled(
      hpMult: WeeklyBalance.enemyStatMultiplier,
      damageMult: WeeklyBalance.enemyStatMultiplier,
    );
    return BattleNotifier(
      hero: hero,
      enemy: enemy,
      nodeId: WeeklyBalance.battleNodeId,
      nodeName: challenge.title,
      coinReward: challenge.coinReward,
      enrageAfterTurns: challenge.enrageAfterTurns,
      minMoves: PrepBalance.defaultMinMoves,
      equippedPrep: equipped,
      isWeekly: true,
      objective: challenge.objective,
      onSecondWindUsed: () {
        ref.read(profileProvider.notifier).markSecondWindUsed();
      },
    );
  }

  final chapter = ref.watch(campaignChapterProvider).valueOrNull;
  if (chapter == null) {
    throw StateError('Campaign content is not ready for battle $nodeId');
  }
  final node = chapter.nodeById(nodeId);
  final enemy = EnemyCatalog.byId(node.enemyId);

  final overlays = ref.watch(overlayCatalogProvider).valueOrNull;
  final templates = ref.watch(boardTemplateCatalogProvider).valueOrNull;
  if (overlays == null || templates == null) {
    throw StateError('Board catalogs are not ready for battle $nodeId');
  }
  final boardConfig = chapter.boardFor(node);
  final templateId = boardConfig.templateId;
  if (templateId == null || templateId.isEmpty) {
    throw StateError('Battle $nodeId has no board template');
  }
  final template = templates[templateId];
  if (template == null) {
    throw StateError('Battle $nodeId references unknown template $templateId');
  }
  final hazardOverlayDef = boardConfig.hazardSpawn == null
      ? null
      : overlays[boardConfig.hazardSpawn!.overlayId];
  if (boardConfig.hazardSpawn != null && hazardOverlayDef == null) {
    throw StateError(
      'Battle $nodeId references unknown hazard overlay '
      '${boardConfig.hazardSpawn!.overlayId}',
    );
  }

  // Inventory already consumed by prep picker; apply modifiers then clear.
  final equipped = List<PrepItemId>.from(ref.read(pendingBossPrepProvider));
  if (equipped.isNotEmpty) {
    ref.read(pendingBossPrepProvider.notifier).state = const [];
  }

  return BattleNotifier(
    hero: hero,
    enemy: enemy,
    nodeId: nodeId,
    nodeName: node.name,
    coinReward: node.coinReward,
    bossForm: node.bossForm,
    enrageAfterTurns: node.isBoss
        ? (node.enrageAfterTurns ?? BossCombatBalance.defaultEnrageAfterTurns)
        : node.enrageAfterTurns,
    minMoves: node.minMoves ?? PrepBalance.defaultMinMoves,
    equippedPrep: equipped,
    movers: boardConfig.effectiveMovers,
    hazardSpawn: boardConfig.hazardSpawn,
    hazardOverlayDef: hazardOverlayDef,
    boardFactory: () {
      return BoardBuilder.fromTemplate(
        template: template,
        overlays: overlays,
        spawnWeights: boardConfig.effectiveSpawnWeights,
      );
    },
    onSecondWindUsed: () {
      ref.read(profileProvider.notifier).markSecondWindUsed();
    },
  );
});

class BattleNotifier extends StateNotifier<BattleState> {
  BattleNotifier({
    HeroDef? hero,
    EnemyDef? enemy,
    String? nodeId,
    String? nodeName,
    int coinReward = 0,
    int? bossForm,
    int? enrageAfterTurns,
    int minMoves = PrepBalance.defaultMinMoves,
    List<PrepItemId> equippedPrep = const [],
    List<BoardMoverConfig> movers = const [],
    PuzzleBoard? Function()? boardFactory,
    void Function()? onSecondWindUsed,
    bool isWeekly = false,
    BattleObjective? objective,
    HazardSpawnConfig? hazardSpawn,
    OverlayDef? hazardOverlayDef,
  })  : _onSecondWindUsed = onSecondWindUsed,
        _equippedPrep = List.unmodifiable(equippedPrep),
        _minMoves = minMoves,
        _enrageAfterTurns = enrageAfterTurns,
        _movers = List.unmodifiable(movers),
        _boardFactory = boardFactory,
        super(
          _initialState(
            hero: hero ?? HeroCatalog.mage,
            enemy: enemy ?? EnemyCatalog.goblin,
            nodeId: nodeId,
            nodeName: nodeName,
            coinReward: coinReward,
            bossForm: bossForm,
            enrageAfterTurns: enrageAfterTurns,
            minMoves: minMoves,
            equippedPrep: equippedPrep,
            movers: movers,
            board: boardFactory?.call(),
            isWeekly: isWeekly,
            objective: objective,
            hazardSpawn: hazardSpawn,
            hazardOverlayDef: hazardOverlayDef,
          ),
        ) {
    _controller = BattleController(state);
    _controller.startPlayerTurn(applyInline: true);
    state = _controller.state;
    _scheduleClearWindFx();
  }

  late BattleController _controller;
  int _actionGen = 0;
  final List<PrepItemId> _equippedPrep;
  final int _minMoves;
  final int? _enrageAfterTurns;
  final List<BoardMoverConfig> _movers;
  final PuzzleBoard? Function()? _boardFactory;
  final void Function()? _onSecondWindUsed;

  static BattleState _initialState({
    required HeroDef hero,
    required EnemyDef enemy,
    String? nodeId,
    String? nodeName,
    required int coinReward,
    int? bossForm,
    int? enrageAfterTurns,
    required int minMoves,
    required List<PrepItemId> equippedPrep,
    List<BoardMoverConfig> movers = const [],
    PuzzleBoard? board,
    bool isWeekly = false,
    BattleObjective? objective,
    HazardSpawnConfig? hazardSpawn,
    OverlayDef? hazardOverlayDef,
  }) {
    var bonusMoves = 0;
    var bonusShield = 0;
    var secondWind = false;
    final notes = <String>[];
    for (final id in equippedPrep) {
      switch (id) {
        case PrepItemId.vanguardTonic:
          bonusMoves += PrepBalance.vanguardBonusMoves;
          notes.add('Vanguard Tonic: +${PrepBalance.vanguardBonusMoves} Move');
        case PrepItemId.aegisFlask:
          bonusShield += PrepBalance.aegisShield;
          notes.add('Aegis Flask: +${PrepBalance.aegisShield} shield');
        case PrepItemId.secondWind:
          secondWind = true;
          notes.add('Second Wind armed');
      }
    }
    return BattleState.initial(
      hero: hero,
      enemy: enemy,
      nodeId: nodeId,
      nodeName: nodeName,
      coinReward: coinReward,
      bossForm: bossForm,
      enrageAfterTurns: enrageAfterTurns,
      bonusMoves: bonusMoves,
      bonusShield: bonusShield,
      secondWindArmed: secondWind,
      minMoves: minMoves,
      board: board,
      movers: movers,
      prepLogNotes: notes,
      isWeekly: isWeekly,
      objective: objective,
      hazardSpawn: hazardSpawn,
      hazardOverlayDef: hazardOverlayDef,
    );
  }

  void tapCell(int row, int col) {
    if (state.inputLocked || state.movesLeft <= 0) return;
    if (!state.board.inBounds(row, col)) return;
    if (!state.board.at(row, col).isPlayable) return;

    _controller.state = state;
    _controller.clearHint();
    state = _controller.state;

    final cell = state.board.at(row, col);
    final selected = state.selectedCell;

    if (selected == null && cell.hasSpecial) {
      _runActivate((row, col));
      return;
    }

    if (selected == null) {
      state = state.copyWith(selectedCell: (row, col));
      return;
    }

    if (selected == (row, col)) {
      if (cell.hasSpecial) {
        _runActivate((row, col));
      } else {
        state = state.copyWith(clearSelected: true);
      }
      return;
    }

    if (!PuzzleEngine.areAdjacent(selected, (row, col))) {
      if (cell.hasSpecial) {
        _runActivate((row, col));
      } else {
        state = state.copyWith(selectedCell: (row, col));
      }
      return;
    }

    _runSwap(selected, (row, col));
  }

  void showHint(Set<(int, int)> cells) {
    _controller.state = state;
    _controller.showHint(cells);
    state = _controller.state;
  }

  void clearHint() {
    _controller.state = state;
    _controller.clearHint();
    state = _controller.state;
  }

  Future<void> _runActivate((int, int) pos) async {
    final gen = ++_actionGen;
    _controller.state = state;
    final cascade = _controller.beginActivate(pos);
    state = _controller.state;
    if (cascade == null) return;
    await _playCascade(cascade, gen);
  }

  Future<void> _runSwap((int, int) a, (int, int) b) async {
    final gen = ++_actionGen;
    _controller.state = state;
    final cascade = _controller.beginSwap(a, b);
    state = _controller.state;
    if (cascade == null) return;
    await _playCascade(cascade, gen);
  }

  Future<void> _playCascade(
    CascadeResult cascade,
    int gen, {
    int movesSpent = 1,
  }) async {
    var knownIds = state.board.tilePositions().keys.toSet();

    final swapped = cascade.boardAfterSwap;
    if (swapped != null && swapped != state.board) {
      state = state.copyWith(board: swapped, phase: BattlePhase.resolving);
      knownIds = swapped.tilePositions().keys.toSet();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted || gen != _actionGen) return;
    }

    var boardWithMatches = swapped ?? state.board;

    for (final step in cascade.steps) {
      _controller.state = state;
      _controller.applyMatchRewards(step.match);
      _controller.showClearing(boardWithMatches, step.clearingCells);
      final powerNote = [
        if (step.match.mergeLabel != null) step.match.mergeLabel!,
        if (step.match.rocketsCreated > 0)
          '+${step.match.rocketsCreated} rocket',
        if (step.match.bombsCreated > 0) '+${step.match.bombsCreated} bomb',
        if (step.match.fireballsCreated > 0)
          '+${step.match.fireballsCreated} fireball',
        if (step.match.seekersCreated > 0)
          '+${step.match.seekersCreated} seeker',
      ].join(' · ');
      state = _controller.state.copyWith(
        log: [
          ..._controller.state.log,
          'Matched ${step.match.matchedCells.length} · +${step.match.apGained} AP'
              '${powerNote.isEmpty ? '' : ' · $powerNote'}',
        ],
      );
      await Future<void>.delayed(BattleController.clearDuration);
      if (!mounted || gen != _actionGen) return;

      _controller.state = state;
      _controller.showHoles(step.boardAfterClear);
      state = _controller.state;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      if (!mounted || gen != _actionGen) return;

      _controller.state = state;
      _controller.showDrop(step.boardAfterDrop);
      state = _controller.state;
      await Future<void>.delayed(BattleController.fallDuration);
      if (!mounted || gen != _actionGen) return;

      final afterIds = step.boardAfterFill.tilePositions().keys.toSet();
      final spawned = afterIds.difference(knownIds);
      knownIds = afterIds;

      _controller.state = state;
      _controller.showSpawn(step.boardAfterFill, spawned);
      state = _controller.state;
      await Future<void>.delayed(BattleController.spawnDuration);
      if (!mounted || gen != _actionGen) return;

      boardWithMatches = step.boardAfterFill;
    }

    _controller.state = state;
    if (_controller.tryObjectiveVictory()) {
      state = _controller.state;
      return;
    }
    _controller.finishPlayerAction(movesSpent: movesSpent);
    state = _controller.state;
    if (_controller.tryObjectiveVictory()) {
      state = _controller.state;
      return;
    }

    if (state.phase == BattlePhase.enemyTurn) {
      await _runEnemyTurn(gen);
    } else if (state.phase == BattlePhase.playerTurn) {
      await _ensurePlayableBoard(gen);
    }
  }

  Future<void> _ensurePlayableBoard(int gen) async {
    if (state.phase != BattlePhase.playerTurn) return;
    _controller.state = state;
    if (!_controller.reshuffleIfDead()) return;
    state = _controller.state;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || gen != _actionGen) return;
  }

  Future<void> _runEnemyTurn(int gen) async {
    state = state.copyWith(
      phase: BattlePhase.enemyTurn,
      clearEnemySkill: true,
    );
    await Future<void>.delayed(BattleController.enemyTelegraph);
    if (!mounted) return;

    // Resolve the enemy action even if this gen was superseded — otherwise we
    // can soft-lock on enemyTurn (input locked) or playerTurn with 0 moves.
    if (state.phase == BattlePhase.enemyTurn) {
      final armedBefore = state.secondWindArmed;
      _controller.state = state;
      _controller.applyEnemySkill(_controller.enemyAction);
      state = _controller.state;

      if (armedBefore && !state.secondWindArmed && state.heroHp > 0) {
        _onSecondWindUsed?.call();
      }
    }

    final impactFx = state.combatFx == CombatFx.hazard
        ? BattleController.hazardFxDuration
        : BattleController.combatFxDuration;
    await Future<void>.delayed(impactFx);
    if (!mounted) return;

    _controller.state = state;
    _controller.clearCombatFx();
    state = _controller.state;

    if (state.phase != BattlePhase.playerTurn) return;

    // Always refresh moves after the enemy acts. If a newer action stole the
    // gen mid-FX, adopt a fresh gen so startPlayerTurn still runs.
    final turnGen = (gen == _actionGen) ? gen : ++_actionGen;
    await _beginPlayerTurn(turnGen);
  }

  Future<void> _beginPlayerTurn(int gen) async {
    _controller.state = state;
    final cascade = _controller.startPlayerTurn();
    state = _controller.state;
    if (state.phase == BattlePhase.victory ||
        state.phase == BattlePhase.defeat) {
      return;
    }
    // Let the row shove animate / wind lanes pulse before match clears.
    if (state.combatFx == CombatFx.wind) {
      await Future<void>.delayed(BattleController.windFxDuration);
      if (!mounted || gen != _actionGen) return;
      _controller.state = state;
      if (state.hazardPulseCells.isNotEmpty) {
        _controller.promoteHazardFx();
        state = _controller.state;
        await Future<void>.delayed(BattleController.hazardFxDuration);
        if (!mounted || gen != _actionGen) return;
        _controller.state = state;
      }
      _controller.clearCombatFx();
      state = _controller.state;
    } else if (state.combatFx == CombatFx.hazard ||
        state.hazardPulseCells.isNotEmpty) {
      await Future<void>.delayed(BattleController.hazardFxDuration);
      if (!mounted || gen != _actionGen) return;
      _controller.state = state;
      _controller.clearCombatFx();
      state = _controller.state;
    }
    if (cascade != null) {
      await _playCascade(cascade, gen, movesSpent: 0);
      return;
    }
    await _ensurePlayableBoard(gen);
  }

  void _scheduleClearWindFx() {
    if (state.combatFx != CombatFx.wind) return;
    Future<void>.delayed(BattleController.windFxDuration, () {
      if (!mounted) return;
      if (state.combatFx != CombatFx.wind) return;
      _controller.state = state;
      if (state.hazardPulseCells.isNotEmpty) {
        _controller.promoteHazardFx();
        state = _controller.state;
        Future<void>.delayed(BattleController.hazardFxDuration, () {
          if (!mounted) return;
          if (state.combatFx != CombatFx.hazard) return;
          _controller.state = state;
          _controller.clearCombatFx();
          state = _controller.state;
        });
        return;
      }
      _controller.clearCombatFx();
      state = _controller.state;
    });
  }

  /// Player voluntarily ends the turn (remaining moves are discarded).
  Future<void> endPlayerTurn() async {
    if (state.phase != BattlePhase.playerTurn) return;
    if (state.inputLocked) return;
    final gen = ++_actionGen;
    _controller.state = state;
    _controller.endPlayerTurn();
    state = _controller.state;
    await _runEnemyTurn(gen);
  }

  Future<void> castSkill(SkillDef skill) async {
    if (state.phase != BattlePhase.playerTurn) return;
    _controller.state = state;
    if (!_controller.canCast(skill)) return;

    final gen = ++_actionGen;
    final dealsDamage = skill.damage > 0;
    _controller.castSkill(skill);
    state = _controller.state;

    // Cast cue on the hero, then impact flash when the skill deals damage.
    if (dealsDamage && state.combatFx == CombatFx.enemyHit) {
      _controller.state = state.copyWith(combatFx: CombatFx.heroCast);
      state = _controller.state;
      await Future<void>.delayed(BattleController.castFxDuration);
      if (!mounted || gen != _actionGen) return;
      _controller.state = state.copyWith(combatFx: CombatFx.enemyHit);
      state = _controller.state;
      await Future<void>.delayed(BattleController.combatFxDuration);
    } else {
      await Future<void>.delayed(BattleController.castFxDuration);
    }
    if (!mounted || gen != _actionGen) return;
    _controller.state = state;
    _controller.clearCombatFx();
    state = _controller.state;

    // Safety: never leave the player on 0 moves with no board actions.
    if (state.phase == BattlePhase.playerTurn && state.movesLeft <= 0) {
      await _runEnemyTurn(gen);
    }
  }

  bool canCast(SkillDef skill) {
    _controller.state = state;
    return _controller.canCast(skill);
  }

  /// Recover from playerTurn + 0 moves (aborted enemy→player handoff).
  Future<void> recoverIfSoftLocked() async {
    if (!mounted) return;
    if (state.phase != BattlePhase.playerTurn || state.movesLeft > 0) return;
    final gen = ++_actionGen;
    await _beginPlayerTurn(gen);
  }

  /// Debug/dev-only UI hook that runs one of the current enemy's real skills
  /// through the normal enemy-turn pipeline.
  Future<bool> forceEnemySkillForQa(EnemySkill skill) async {
    if (!mounted ||
        state.phase != BattlePhase.playerTurn ||
        state.inputLocked) {
      return false;
    }
    if (!state.enemy.skills.any((candidate) => candidate.id == skill.id)) {
      return false;
    }
    final gen = ++_actionGen;
    _controller.state = state.copyWith(enemyIntent: skill);
    state = _controller.state;
    await _runEnemyTurn(gen);
    return true;
  }

  void restart() {
    _actionGen++;
    // Restart does not re-consume prep; keep same battle modifiers.
    _controller = BattleController(
      _initialState(
        hero: state.hero,
        enemy: state.enemy,
        nodeId: state.nodeId,
        nodeName: state.nodeName,
        coinReward: state.coinReward,
        bossForm: state.bossForm,
        enrageAfterTurns: _enrageAfterTurns,
        minMoves: _minMoves,
        equippedPrep: _equippedPrep,
        movers: _movers,
        board: _boardFactory?.call(),
      ),
    );
    _controller.startPlayerTurn(applyInline: true);
    state = _controller.state;
    _scheduleClearWindFx();
  }
}
