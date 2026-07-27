import 'dart:math';

import '../../heroes/domain/hero_def.dart';
import '../../prep/domain/prep_item.dart';
import '../../puzzle/domain/board_movers.dart';
import '../../puzzle/domain/level_board_config.dart';
import '../../puzzle/domain/puzzle_board.dart';
import '../../puzzle/domain/puzzle_engine.dart';
import '../../puzzle/domain/tile_id_gen.dart';
import 'enemy_def.dart';

enum BattlePhase {
  playerTurn,
  resolving,
  enemyTurn,
  victory,
  defeat,
}

/// Visual feedback flags for combat juice.
enum CombatFx { none, heroHit, enemyHit, heroCast }

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

  static const clearDuration = Duration(milliseconds: 220);
  static const fallDuration = Duration(milliseconds: 260);
  static const spawnDuration = Duration(milliseconds: 280);
  static const combatFxDuration = Duration(milliseconds: 320);
  static const enemyTelegraph = Duration(milliseconds: 400);

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
    final dueMovers = state.movers.where((m) {
      final every = m.everyNTurns < 1 ? 1 : m.everyNTurns;
      return (turn - 1) % every == 0;
    }).toList();

    var enraged = state.enraged;
    final threshold = state.enrageAfterTurns;
    final justEnraged =
        !enraged && threshold != null && threshold > 0 && turn >= threshold;
    if (justEnraged) enraged = true;

    final notes = <String>[
      ...state.log,
      if (dueMovers.isNotEmpty) 'Wind shifts the board…',
      if (justEnraged) '${state.enemy.name} enrages!',
      'Your turn — ${state.movesPerTurn} moves',
    ];

    state = state.copyWith(
      board: shoved,
      playerTurnNumber: turn,
      movesLeft: state.movesPerTurn,
      phase: BattlePhase.playerTurn,
      enraged: enraged,
      clearSelected: true,
      clearHint: true,
      log: notes,
    );
    rollEnemyIntent();

    final cascade = PuzzleEngine.resolveCascade(
      shoved,
      random: _random,
      ids: ids,
    );
    if (cascade.steps.isEmpty) return null;

    if (applyInline) {
      applyMatchRewards(cascade.totals);
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
    state = state.copyWith(resources: resources, ap: ap);
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

  void clearCombatFx() {
    state = state.copyWith(combatFx: CombatFx.none);
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

    if (heroHp <= 0) {
      if (state.secondWindArmed) {
        final reviveHp =
            (state.hero.maxHp * PrepBalance.secondWindHpFraction).round();
        final hp = reviveHp < 1 ? 1 : reviveHp;
        state = state.copyWith(
          heroHp: hp,
          shield: shield,
          secondWindArmed: false,
          phase: BattlePhase.playerTurn,
          combatFx: CombatFx.heroCast,
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
        phase: BattlePhase.defeat,
        combatFx: CombatFx.heroHit,
        lastEnemySkillName: skill.name,
        log: [...logs, 'Defeat…'],
      );
      return;
    }

    state = state.copyWith(
      heroHp: heroHp,
      shield: shield,
      phase: BattlePhase.playerTurn,
      combatFx: CombatFx.heroHit,
      lastEnemySkillName: skill.name,
      log: logs,
    );
  }
}
