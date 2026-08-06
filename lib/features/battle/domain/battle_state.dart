import 'dart:math';

import '../../heroes/domain/hero_def.dart';
import '../../prep/domain/prep_item.dart';
import '../../puzzle/domain/board_cell.dart';
import '../../puzzle/domain/board_movers.dart';
import '../../puzzle/domain/hazard_spawner.dart';
import '../../puzzle/domain/level_board_config.dart';
import '../../puzzle/domain/overlay_def.dart';
import '../../puzzle/domain/puzzle_board.dart';
import '../../puzzle/domain/puzzle_engine.dart';
import '../../puzzle/domain/tile_id_gen.dart';
import '../../weekly/domain/weekly_schedule.dart';
import 'enemy_def.dart';
import 'enemy_effect.dart';

enum BattlePhase {
  playerTurn,
  resolving,
  enemyTurn,
  victory,
  defeat,
}

/// Visual feedback flags for combat juice.
enum CombatFx { none, heroHit, enemyHit, heroCast, wind, hazard }

/// Stub knobs until Balancing Bible owns boss combat math.
abstract final class BossCombatBalance {
  /// Damage multiplier once [BattleState.enraged] is true.
  static const enrageDamageMultiplier = 1.5;

  /// Default player-turn threshold when level JSON omits `enrageAfterTurns`.
  static const defaultEnrageAfterTurns = 8;
}

class BattleState {
  const BattleState({
    required this.hero,
    required this.enemy,
    required this.board,
    required this.heroHp,
    required this.enemyHp,
    required this.movesLeft,
    required this.movesPerTurn,
    required this.ap,
    required this.resources,
    required this.shield,
    required this.phase,
    this.nodeId,
    this.nodeName,
    this.coinReward = 0,
    this.bossForm,
    this.enrageAfterTurns,
    this.enraged = false,
    this.bossFled = false,
    this.secondWindArmed = false,
    this.selectedCell,
    this.clearingCells = const {},
    this.spawningIds = const {},
    this.combatFx = CombatFx.none,
    this.enemyIntent,
    this.hintCells = const {},
    this.lastEnemySkillName,
    this.log = const [],
    this.playerTurnNumber = 0,
    this.movers = const [],
    this.windRows = const {},
    this.windDirection,
    this.hazardPulseCells = const {},
    this.pendingMovePenalty = 0,
    this.isWeekly = false,
    this.objective,
    this.tilesCleared = 0,
    this.hazardSpawn,
    this.hazardOverlayDef,
  });

  final HeroDef hero;
  final EnemyDef enemy;
  final PuzzleBoard board;
  final int heroHp;
  final int enemyHp;
  final int movesLeft;

  /// Turn move budget after prep / level / boss modifiers.
  final int movesPerTurn;
  final int ap;
  final Map<String, int> resources;
  final int shield;
  final BattlePhase phase;
  final String? nodeId;
  final String? nodeName;
  final int coinReward;

  /// Chapter boss form 1–4 when fighting a sighting / finale.
  final int? bossForm;

  /// After this many player turns, boss enrages (null = never).
  final int? enrageAfterTurns;

  /// Boss is hitting harder after [enrageAfterTurns].
  final bool enraged;

  /// True when victory came from a form 1–3 flee (not a final death).
  final bool bossFled;

  /// Equipped Second Wind for this battle (once-per-day gate is profile-side).
  final bool secondWindArmed;
  final (int, int)? selectedCell;

  /// Cells currently playing destroy animation.
  final Set<(int, int)> clearingCells;

  /// Tile ids that just spawned (drop-in from above).
  final Set<int> spawningIds;

  final CombatFx combatFx;

  /// Telegraphed enemy action for the upcoming enemy turn. Rolled at the
  /// start of each player turn and executed exactly, so the threat badge
  /// is honest.
  final EnemySkill? enemyIntent;

  /// Idle match-hint cells (color swap). Cleared on input / reshuffle.
  final Set<(int, int)> hintCells;
  final String? lastEnemySkillName;
  final List<String> log;

  /// Completed player turns so far (0 before first [BattleController.startPlayerTurn]).
  final int playerTurnNumber;

  /// Level movers applied at the start of each player turn.
  final List<BoardMoverConfig> movers;

  /// Rows currently pulsing from a wind shove (UI highlight).
  final Set<int> windRows;

  /// Shove direction while [combatFx] is [CombatFx.wind] (`left`/`right`/…).
  final String? windDirection;

  /// Cells that just gained a hazard overlay (spawn pulse).
  final Set<(int, int)> hazardPulseCells;

  /// Subtracted from next player-turn move refresh (e.g. Pack Howl).
  final int pendingMovePenalty;

  /// Weekly mode battle (settlement skips campaign node completion).
  final bool isWeekly;

  /// Optional non-HP win condition (weekday objectives).
  final BattleObjective? objective;

  /// Tiles cleared this battle (weekly clear-tiles objective).
  final int tilesCleared;

  /// Optional per-turn hazard spawn (Mistfen poison, etc.).
  final HazardSpawnConfig? hazardSpawn;
  final OverlayDef? hazardOverlayDef;

  bool get inputLocked =>
      phase == BattlePhase.resolving ||
      phase == BattlePhase.enemyTurn ||
      phase == BattlePhase.victory ||
      phase == BattlePhase.defeat;

  /// Forms 1–3 flee when HP hits 0; form 4 (finale) dies.
  bool get bossFleesOnDefeat {
    final form = bossForm;
    return form != null && form >= 1 && form <= 3;
  }

  factory BattleState.initial({
    HeroDef hero = HeroCatalog.mage,
    EnemyDef enemy = EnemyCatalog.goblin,
    String? nodeId,
    String? nodeName,
    int coinReward = 0,
    int? bossForm,
    int? enrageAfterTurns,
    int bonusMoves = 0,
    int bonusShield = 0,
    bool secondWindArmed = false,
    int minMoves = PrepBalance.defaultMinMoves,
    int levelMoveModifier = 0,
    int bossMoveDebuff = 0,
    PuzzleBoard? board,
    TileIdGen? ids,
    Random? random,
    List<String> prepLogNotes = const [],
    List<BoardMoverConfig> movers = const [],
    bool isWeekly = false,
    BattleObjective? objective,
    HazardSpawnConfig? hazardSpawn,
    OverlayDef? hazardOverlayDef,
  }) {
    final idGen = ids ?? TileIdGen();
    final effectiveMoves = PrepBalance.movesThisTurn(
      heroMoves: hero.movesPerTurn,
      prepBonus: bonusMoves,
      levelModifier: levelMoveModifier,
      bossDebuff: bossMoveDebuff,
      minMoves: minMoves,
    );
    final notes = [
      'Battle started. Match tiles to fuel your skills.',
      if (objective != null) 'Objective: ${objective.progressLabel}',
      ...prepLogNotes,
    ];
    return BattleState(
      hero: hero,
      enemy: enemy,
      nodeId: nodeId,
      nodeName: nodeName,
      coinReward: coinReward,
      bossForm: bossForm,
      enrageAfterTurns: enrageAfterTurns,
      board: board ??
          PuzzleBoard.squarePlayable(random: random ?? Random(), ids: idGen),
      heroHp: hero.maxHp,
      enemyHp: enemy.maxHp,
      movesLeft: effectiveMoves,
      movesPerTurn: effectiveMoves,
      ap: 0,
      resources: const {
        'attack': 0,
        'mana': 0,
        'healing': 0,
        'shield': 0,
        'ultimate': 0,
      },
      shield: bonusShield,
      secondWindArmed: secondWindArmed,
      phase: BattlePhase.playerTurn,
      log: notes,
      movers: movers,
      isWeekly: isWeekly,
      objective: objective,
      hazardSpawn: hazardSpawn,
      hazardOverlayDef: hazardOverlayDef,
    );
  }

  BattleState copyWith({
    PuzzleBoard? board,
    int? heroHp,
    int? enemyHp,
    int? movesLeft,
    int? movesPerTurn,
    int? ap,
    Map<String, int>? resources,
    int? shield,
    BattlePhase? phase,
    bool? secondWindArmed,
    bool? enraged,
    bool? bossFled,
    (int, int)? selectedCell,
    bool clearSelected = false,
    Set<(int, int)>? clearingCells,
    Set<int>? spawningIds,
    CombatFx? combatFx,
    EnemySkill? enemyIntent,
    Set<(int, int)>? hintCells,
    bool clearHint = false,
    String? lastEnemySkillName,
    bool clearEnemySkill = false,
    List<String>? log,
    int? playerTurnNumber,
    int? tilesCleared,
    Set<int>? windRows,
    bool clearWindRows = false,
    String? windDirection,
    bool clearWindDirection = false,
    Set<(int, int)>? hazardPulseCells,
    bool clearHazardPulse = false,
    int? pendingMovePenalty,
  }) {
    return BattleState(
      hero: hero,
      enemy: enemy,
      nodeId: nodeId,
      nodeName: nodeName,
      coinReward: coinReward,
      bossForm: bossForm,
      enrageAfterTurns: enrageAfterTurns,
      enraged: enraged ?? this.enraged,
      bossFled: bossFled ?? this.bossFled,
      board: board ?? this.board,
      heroHp: heroHp ?? this.heroHp,
      enemyHp: enemyHp ?? this.enemyHp,
      movesLeft: movesLeft ?? this.movesLeft,
      movesPerTurn: movesPerTurn ?? this.movesPerTurn,
      ap: ap ?? this.ap,
      resources: resources ?? this.resources,
      shield: shield ?? this.shield,
      secondWindArmed: secondWindArmed ?? this.secondWindArmed,
      phase: phase ?? this.phase,
      selectedCell: clearSelected ? null : (selectedCell ?? this.selectedCell),
      clearingCells: clearingCells ?? this.clearingCells,
      spawningIds: spawningIds ?? this.spawningIds,
      combatFx: combatFx ?? this.combatFx,
      enemyIntent: enemyIntent ?? this.enemyIntent,
      hintCells: clearHint ? const {} : (hintCells ?? this.hintCells),
      lastEnemySkillName: clearEnemySkill
          ? null
          : (lastEnemySkillName ?? this.lastEnemySkillName),
      log: log ?? this.log,
      playerTurnNumber: playerTurnNumber ?? this.playerTurnNumber,
      movers: movers,
      windRows: clearWindRows ? const {} : (windRows ?? this.windRows),
      windDirection:
          clearWindDirection ? null : (windDirection ?? this.windDirection),
      hazardPulseCells: clearHazardPulse
          ? const {}
          : (hazardPulseCells ?? this.hazardPulseCells),
      pendingMovePenalty: pendingMovePenalty ?? this.pendingMovePenalty,
      isWeekly: isWeekly,
      objective: objective,
      tilesCleared: tilesCleared ?? this.tilesCleared,
      hazardSpawn: hazardSpawn,
      hazardOverlayDef: hazardOverlayDef,
    );
  }
}

class BattleController {
  BattleController(
    this.state, {
    Random? random,
    TileIdGen? ids,
  })  : _random = random ?? Random(),
        ids = ids ?? TileIdGen(1000);

  BattleState state;
  final Random _random;
  final TileIdGen ids;

  static const clearDuration = Duration(milliseconds: 240);
  static const fallDuration = Duration(milliseconds: 280);
  static const spawnDuration = Duration(milliseconds: 300);
  static const combatFxDuration = Duration(milliseconds: 360);
  static const castFxDuration = Duration(milliseconds: 400);
  static const windFxDuration = Duration(milliseconds: 520);
  static const hazardFxDuration = Duration(milliseconds: 380);
  static const enemyTelegraph = Duration(milliseconds: 480);

  /// Start of a player turn: bump turn counter, apply movers, refresh moves.
  ///
  /// Returns a cascade when the shove creates matches. Pass [applyInline] true
  /// at battle start to resolve without UI animation.
  CascadeResult? startPlayerTurn({bool applyInline = false}) {
    final turn = state.playerTurnNumber + 1;
    final shoved = BoardMovers.applyForTurn(
      state.board,
      state.movers,
      playerTurnNumber: turn,
    );
    final dueMovers = BoardMovers.dueOnTurn(state.movers, turn);
    final windRows = BoardMovers.dueWindRows(state.movers, turn);
    final windDir = BoardMovers.dueWindDirection(state.movers, turn);
    final windDue = dueMovers.isNotEmpty;

    var enraged = state.enraged;
    final threshold = state.enrageAfterTurns;
    final justEnraged =
        !enraged && threshold != null && threshold > 0 && turn >= threshold;
    if (justEnraged) enraged = true;

    final notes = <String>[
      ...state.log,
      if (justEnraged) '${state.enemy.name} enrages!',
      if (windDue)
        'Wind! Board shifts — ${state.movesPerTurn} moves'
      else
        'Your turn — ${state.movesPerTurn} moves',
    ];

    final penalty = state.pendingMovePenalty;
    final refreshed =
        (state.movesPerTurn - penalty).clamp(PrepBalance.defaultMinMoves, 99);
    if (penalty > 0) {
      notes.add('Howling winds steal $penalty Move!');
    }

    state = state.copyWith(
      board: shoved,
      playerTurnNumber: turn,
      movesLeft: refreshed,
      pendingMovePenalty: 0,
      phase: BattlePhase.playerTurn,
      enraged: enraged,
      clearSelected: true,
      clearHint: true,
      combatFx: windDue ? CombatFx.wind : CombatFx.none,
      windRows: windRows,
      clearWindRows: windRows.isEmpty,
      windDirection: windDir,
      clearWindDirection: windDir == null,
      clearHazardPulse: true,
      log: notes,
    );

    final hazardCfg = state.hazardSpawn;
    final hazardDef = state.hazardOverlayDef;
    if (hazardCfg != null && hazardDef != null) {
      final outcome = HazardSpawner.maybeSpawnTracked(
        board: state.board,
        config: hazardCfg,
        def: hazardDef,
        random: _random,
      );
      if (outcome.didSpawn) {
        state = state.copyWith(
          board: outcome.board,
          combatFx: windDue ? CombatFx.wind : CombatFx.hazard,
          hazardPulseCells: outcome.spawnedCells,
          log: [
            ...state.log,
            '${_hazardLabel(hazardDef)} spreads across the marsh…',
          ],
        );
      }
    }

    rollEnemyIntent();
    if (_tryObjectiveVictory()) return null;

    final cascade = PuzzleEngine.resolveCascade(
      shoved,
      random: _random,
      ids: ids,
    );
    if (cascade.steps.isEmpty) return null;

    if (applyInline) {
      applyMatchRewards(cascade.totals);
      if (_tryObjectiveVictory()) return null;
      state = state.copyWith(
        board: cascade.finalBoard,
        phase: BattlePhase.playerTurn,
        log: [
          ...state.log,
          'Wind matches clear · +${cascade.totals.apGained} AP',
        ],
      );
      return null;
    }

    state = state.copyWith(phase: BattlePhase.resolving);
    return CascadeResult(
      steps: cascade.steps,
      finalBoard: cascade.finalBoard,
      totals: cascade.totals,
      boardAfterSwap: shoved,
    );
  }

  /// Returns cascade if swap is valid; updates selection clear. Does not mutate board yet.
  CascadeResult? beginSwap((int, int) a, (int, int) b) {
    final cascade = PuzzleEngine.trySwap(
      state.board,
      a,
      b,
      random: _random,
      ids: ids,
    );
    if (cascade == null) {
      state = state.copyWith(
        clearSelected: true,
        log: [...state.log, 'No match — try another swap.'],
      );
      return null;
    }
    state = state.copyWith(
      phase: BattlePhase.resolving,
      clearSelected: true,
    );
    return cascade;
  }

  /// Tap-activate a power-up in place (costs the move when cascade finishes).
  CascadeResult? beginActivate((int, int) pos) {
    final cascade = PuzzleEngine.activateSpecial(
      state.board,
      pos,
      random: _random,
      ids: ids,
    );
    if (cascade == null) return null;
    state = state.copyWith(
      phase: BattlePhase.resolving,
      clearSelected: true,
    );
    return cascade;
  }

  void applyMatchRewards(MatchResult match) {
    final resources = Map<String, int>.from(state.resources);
    match.resourceGains.forEach((key, value) {
      resources[key] = (resources[key] ?? 0) + value;
    });
    final ap = (state.ap + match.apGained).clamp(0, state.hero.maxAp);
    final tiles = state.tilesCleared + match.matchedCells.length;
    state = state.copyWith(
      resources: resources,
      ap: ap,
      tilesCleared: tiles,
    );
  }

  /// Returns true if an objective win was applied.
  bool _tryObjectiveVictory() {
    final objective = state.objective;
    if (objective == null) return false;
    if (state.phase == BattlePhase.victory ||
        state.phase == BattlePhase.defeat) {
      return false;
    }
    if (!objective.isMet(
      playerTurnNumber: state.playerTurnNumber,
      tilesCleared: state.tilesCleared,
    )) {
      return false;
    }
    state = state.copyWith(
      phase: BattlePhase.victory,
      log: [...state.log, 'Objective complete!'],
    );
    return true;
  }

  /// Public check after cascade animations finish.
  bool tryObjectiveVictory() => _tryObjectiveVictory();

  static String _hazardLabel(OverlayDef def) {
    if (def.id.contains('poison')) return 'Poison';
    if (def.id.contains('vine') || def.id.contains('sticky')) return 'Vines';
    return 'Hazard';
  }

  /// Highlight matches still on [board]; tiles animate out before gravity.
  void showClearing(PuzzleBoard board, Set<(int, int)> matched) {
    state = state.copyWith(
      board: board,
      clearingCells: matched,
      spawningIds: {},
    );
  }

  void showHoles(PuzzleBoard boardAfterClear) {
    state = state.copyWith(
      board: boardAfterClear,
      clearingCells: {},
      spawningIds: {},
    );
  }

  void showDrop(PuzzleBoard boardAfterDrop) {
    state = state.copyWith(
      board: boardAfterDrop,
      clearingCells: {},
      spawningIds: {},
    );
  }

  void showSpawn(PuzzleBoard boardAfterFill, Set<int> newIds) {
    state = state.copyWith(
      board: boardAfterFill,
      clearingCells: {},
      spawningIds: newIds,
    );
  }

  void finishPlayerAction({required int movesSpent}) {
    final movesLeft = state.movesLeft - movesSpent;
    state = state.copyWith(
      movesLeft: movesLeft,
      clearingCells: {},
      spawningIds: {},
      phase: movesLeft <= 0 ? BattlePhase.enemyTurn : BattlePhase.playerTurn,
    );
  }

  /// Spend remaining moves and hand the turn to the enemy (End Turn).
  void endPlayerTurn() {
    if (state.phase != BattlePhase.playerTurn) return;
    state = state.copyWith(
      movesLeft: 0,
      phase: BattlePhase.enemyTurn,
      clearSelected: true,
      clearHint: true,
      clearingCells: {},
      spawningIds: {},
      log: [...state.log, 'Turn ended.'],
    );
  }

  bool canCast(SkillDef skill) {
    if (state.phase != BattlePhase.playerTurn) return false;
    if (state.ap < skill.apCost) return false;
    for (final entry in skill.resourceCosts.entries) {
      if ((state.resources[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }

  void castSkill(SkillDef skill) {
    if (!canCast(skill)) return;

    final resources = Map<String, int>.from(state.resources);
    skill.resourceCosts.forEach((key, cost) {
      resources[key] = resources[key]! - cost;
    });

    var enemyHp = state.enemyHp - skill.damage;
    var heroHp = state.heroHp + skill.heal;
    if (heroHp > state.hero.maxHp) heroHp = state.hero.maxHp;
    final shield = state.shield + skill.shield;
    final ap = state.ap - skill.apCost;

    final logs = [...state.log, 'Cast ${skill.name}!'];
    var phase = state.phase;
    var fx = CombatFx.none;

    if (skill.damage > 0) {
      fx = CombatFx.enemyHit;
      logs.add('${skill.name} hits for ${skill.damage}');
    } else {
      fx = CombatFx.heroCast;
    }

    if (enemyHp <= 0) {
      enemyHp = 0;
      phase = BattlePhase.victory;
      final fled = state.bossFleesOnDefeat;
      logs.add(
        fled ? '${state.enemy.name} flees!' : 'Victory!',
      );
      state = state.copyWith(
        resources: resources,
        enemyHp: enemyHp,
        heroHp: heroHp,
        shield: shield,
        ap: ap,
        phase: phase,
        combatFx: fx,
        bossFled: fled,
        log: logs,
      );
      return;
    }

    state = state.copyWith(
      resources: resources,
      enemyHp: enemyHp,
      heroHp: heroHp,
      shield: shield,
      ap: ap,
      phase: phase,
      combatFx: fx,
      log: logs,
    );
  }

  void clearCombatFx({bool clearHazardPulse = true}) {
    state = state.copyWith(
      combatFx: CombatFx.none,
      clearWindRows: true,
      clearWindDirection: true,
      clearHazardPulse: clearHazardPulse,
    );
  }

  /// Switches to hazard FX after wind has finished playing.
  void promoteHazardFx() {
    if (state.hazardPulseCells.isEmpty) return;
    state = state.copyWith(
      combatFx: CombatFx.hazard,
      clearWindRows: true,
      clearWindDirection: true,
    );
  }

  void clearHint() {
    if (state.hintCells.isEmpty) return;
    state = state.copyWith(clearHint: true);
  }

  void showHint(Set<(int, int)> cells) {
    state = state.copyWith(hintCells: cells);
  }

  /// When no color swaps remain, reshuffle normal gems (keeps power-ups).
  bool reshuffleIfDead() {
    if (PuzzleEngine.hasColorMove(state.board, random: _random)) return false;
    final board = PuzzleEngine.reshuffleKeepingSpecials(
      state.board,
      random: _random,
      ids: ids,
    );
    state = state.copyWith(
      board: board,
      clearHint: true,
      clearSelected: true,
      log: [...state.log, 'No moves — reshuffling…'],
    );
    return true;
  }

  EnemySkill pickEnemySkill() {
    final skills = state.enemy.skills;
    final total = skills.fold<int>(0, (sum, s) => sum + s.weight);
    var roll = _random.nextInt(total);
    for (final skill in skills) {
      roll -= skill.weight;
      if (roll < 0) return skill;
    }
    return skills.last;
  }

  /// Rolls the telegraphed action for the next enemy turn. Call at battle
  /// start; [applyEnemySkill] re-rolls automatically for following turns.
  void rollEnemyIntent() {
    state = state.copyWith(enemyIntent: pickEnemySkill());
  }

  /// The action the enemy will actually take — the telegraphed intent.
  EnemySkill get enemyAction => state.enemyIntent ?? pickEnemySkill();

  void applyEnemySkill(EnemySkill skill) {
    var damage = skill.damage;
    if (state.enraged && damage > 0) {
      damage = (damage * BossCombatBalance.enrageDamageMultiplier).round();
      if (damage < skill.damage) damage = skill.damage;
    }
    var shield = state.shield;
    if (shield > 0) {
      final absorbed = damage < shield ? damage : shield;
      shield -= absorbed;
      damage -= absorbed;
    }
    final heroHp = (state.heroHp - damage).clamp(0, state.hero.maxHp);
    final logs = [
      ...state.log,
      '${state.enemy.name} uses ${skill.name}'
          '${state.enraged ? ' (enraged)' : ''}!',
      if (damage > 0) '${skill.name} hits for $damage',
      if (damage == 0 && skill.damage > 0) 'Shield absorbed the blow',
    ];

    var board = state.board;
    var resources = Map<String, int>.from(state.resources);
    var movePenalty = state.pendingMovePenalty;
    final hazardPulse = <(int, int)>{};

    for (final effect in skill.effects) {
      switch (effect) {
        case ModifyMovesEffect(:final amount):
          movePenalty += -amount;
          logs.add(effect.describe());
        case DrainResourceEffect(:final resource, :final amount):
          final key = resource.id;
          final have = resources[key] ?? 0;
          final next = (have - amount).clamp(0, 999);
          resources[key] = next;
          logs.add('Drained $amount $key');
        case ApplyOverlayEffect(:final overlayId, :final count):
          final def = EnemyEffect.requireCatalogOverlay(overlayId);
          final placed = _applyOverlaySpread(
            board,
            def: def,
            count: count,
          );
          if (placed.$2.isNotEmpty) {
            board = placed.$1;
            hazardPulse.addAll(placed.$2);
            logs.add('Poison seeps onto ${placed.$2.length} tiles');
          }
      }
    }

    if (heroHp <= 0) {
      if (state.secondWindArmed) {
        final reviveHp =
            (state.hero.maxHp * PrepBalance.secondWindHpFraction).round();
        final hp = reviveHp < 1 ? 1 : reviveHp;
        state = state.copyWith(
          heroHp: hp,
          shield: shield,
          board: board,
          resources: resources,
          pendingMovePenalty: movePenalty,
          secondWindArmed: false,
          phase: BattlePhase.playerTurn,
          combatFx: CombatFx.heroCast,
          hazardPulseCells: hazardPulse,
          lastEnemySkillName: skill.name,
          log: [
            ...logs,
            'Second Wind! Revived to $hp HP.',
          ],
        );
        return;
      }
      state = state.copyWith(
        heroHp: 0,
        shield: shield,
        board: board,
        resources: resources,
        pendingMovePenalty: movePenalty,
        phase: BattlePhase.defeat,
        combatFx: CombatFx.heroHit,
        hazardPulseCells: hazardPulse,
        lastEnemySkillName: skill.name,
        log: [...logs, 'Defeat…'],
      );
      return;
    }

    state = state.copyWith(
      heroHp: heroHp,
      shield: shield,
      board: board,
      resources: resources,
      pendingMovePenalty: movePenalty,
      phase: BattlePhase.playerTurn,
      combatFx: damage > 0
          ? CombatFx.heroHit
          : (hazardPulse.isNotEmpty ? CombatFx.hazard : CombatFx.heroHit),
      hazardPulseCells: hazardPulse,
      lastEnemySkillName: skill.name,
      log: logs,
    );
  }

  (PuzzleBoard, Set<(int, int)>) _applyOverlaySpread(
    PuzzleBoard board, {
    required OverlayDef def,
    required int count,
  }) {
    final candidates = <(int, int)>[];
    for (var r = 0; r < board.height; r++) {
      for (var c = 0; c < board.width; c++) {
        final cell = board.at(r, c);
        if (!cell.isPlayable) continue;
        if (cell.hasObstacle) continue;
        candidates.add((r, c));
      }
    }
    if (candidates.isEmpty) return (board, const {});
    candidates.shuffle(_random);
    final take = count.clamp(0, candidates.length);
    final cells = List<BoardCell>.from(board.cells);
    final spawned = <(int, int)>{};
    for (var i = 0; i < take; i++) {
      final (r, c) = candidates[i];
      final idx = r * board.width + c;
      final cell = cells[idx];
      cells[idx] = BoardCell.withOverlay(
        def: def,
        layers: 1,
        id: cell.id,
        color: cell.color,
        special: cell.special,
      );
      spawned.add((r, c));
    }
    return (
      PuzzleBoard(width: board.width, height: board.height, cells: cells),
      spawned,
    );
  }
}
