import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../firebase/firebase_bootstrap.dart';
import '../../auth/providers/auth_provider.dart';
import '../../battle/domain/battle_state.dart';
import '../../battle/domain/skill_affordability.dart';
import '../../battle/presentation/animated_puzzle_board.dart';
import '../../battle/presentation/battle_hud.dart';
import '../../battle/presentation/battle_stage.dart';
import '../../puzzle/domain/puzzle_engine.dart';
import '../domain/battle_action.dart';
import '../domain/pvp_duel.dart';
import '../domain/pvp_models.dart';
import '../providers/pvp_providers.dart';

class PvpBattleScreen extends ConsumerStatefulWidget {
  const PvpBattleScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<PvpBattleScreen> createState() => _PvpBattleScreenState();
}

class _PvpBattleScreenState extends ConsumerState<PvpBattleScreen> {
  StreamSubscription<PvpMatch?>? _sub;
  Timer? _heartbeat;
  PvpMatch? _match;
  (int, int)? _selected;
  String? _error;

  String get _uid =>
      ref.read(authIdentityProvider).asData?.value?.uid ?? 'local_guest';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sub = ref
          .read(pvpRepositoryProvider)
          .watchMatch(widget.matchId)
          .listen((match) {
        if (!mounted) return;
        setState(() => _match = match);
        if (match != null &&
            (match.status == PvpMatchStatus.finished ||
                match.status == PvpMatchStatus.forfeited)) {
          _heartbeat?.cancel();
        }
      });
      _heartbeat = Timer.periodic(const Duration(seconds: 5), (_) {
        final uid = _uid;
        ref.read(pvpRepositoryProvider).heartbeat(
              matchId: widget.matchId,
              uid: uid,
            );
        final match = _match;
        if (match == null || !match.isLive) return;
        final opponent = match.opponentUid(uid);
        if (match.heartbeatTimedOut(opponent, DateTime.now().toUtc())) {
          ref.read(pvpRepositoryProvider).forfeit(
                matchId: widget.matchId,
                uid: opponent,
              );
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _heartbeat?.cancel();
    super.dispose();
  }

  Future<void> _submit(BattleAction action) async {
    final match = _match;
    if (match == null || !match.isMyTurn(_uid)) return;
    final projected = match.copyWith(
      actionLog: [...match.actionLog, action],
    );
    final after = PvpDuelEngine.replay(match: projected, viewerUid: _uid);
    var nextUid = _uid;
    PvpMatchStatus? status;
    if (after.phase == BattlePhase.victory ||
        after.phase == BattlePhase.defeat) {
      status = PvpMatchStatus.finished;
    } else if (action.type == BattleActionType.endTurn ||
        after.phase == BattlePhase.enemyTurn) {
      nextUid = match.opponentUid(_uid);
    }
    await ref.read(pvpRepositoryProvider).appendAction(
          matchId: match.id,
          action: action,
          nextUid: nextUid,
          status: status,
        );
    if (mounted) setState(() => _selected = null);
  }

  void _tap(int row, int col) {
    final match = _match;
    if (match == null) return;
    final state = PvpDuelEngine.replay(match: match, viewerUid: _uid);
    if (!match.isMyTurn(_uid) || state.inputLocked || state.movesLeft <= 0) {
      return;
    }
    if (!state.board.inBounds(row, col)) return;
    final cell = state.board.at(row, col);
    if (!cell.isPlayable) return;
    final selected = _selected;
    if (selected == null && cell.hasSpecial) {
      _submit(BattleAction.activate(actorUid: _uid, pos: (row, col)));
      return;
    }
    if (selected == null) {
      setState(() => _selected = (row, col));
      return;
    }
    if (selected == (row, col)) {
      setState(() => _selected = null);
      return;
    }
    if (!PuzzleEngine.areAdjacent(selected, (row, col))) {
      setState(() => _selected = (row, col));
      return;
    }
    _submit(BattleAction.swap(actorUid: _uid, a: selected, b: (row, col)));
  }

  @override
  Widget build(BuildContext context) {
    final match = _match;
    if (match == null) {
      return Scaffold(
        backgroundColor: MythDuskColors.ink,
        appBar: AppBar(
          title: const Text('Live 1v1'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(_error ?? 'Connecting to match…'),
        ),
      );
    }

    final uid = _uid;
    final state = PvpDuelEngine.replay(match: match, viewerUid: uid).copyWith(
      selectedCell: _selected,
    );
    final myTurn = match.isMyTurn(uid);
    final opponent = match.opponentLoadout(uid).hero;

    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      await ref.read(pvpRepositoryProvider).forfeit(
                            matchId: match.id,
                            uid: uid,
                          );
                      if (context.mounted) context.pop();
                    },
                  ),
                  Expanded(
                    child: Text(
                      myTurn
                          ? 'Your turn vs ${opponent.name}'
                          : '${opponent.name} is playing',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (!FirebaseBootstrap.isReady)
                    const Tooltip(
                      message: 'In-memory match',
                      child: Icon(Icons.cloud_off, size: 18),
                    ),
                ],
              ),
            ),
            BattleHudBar(battle: state),
            Expanded(
              flex: 2,
              child: BattleStage(battle: state),
            ),
            Expanded(
              flex: 3,
              child: AnimatedPuzzleBoard(
                battle: state,
                onTap: _tap,
                onSwipe: myTurn
                    ? (from, to) => _submit(
                          BattleAction.swap(actorUid: uid, a: from, b: to),
                        )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  for (final skill in state.hero.skills)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilledButton(
                          onPressed: myTurn &&
                                  SkillAffordability.evaluate(skill, state)
                                      .canCast
                              ? () => _submit(
                                    BattleAction.cast(
                                      actorUid: uid,
                                      skillId: skill.id,
                                    ),
                                  )
                              : null,
                          child:
                              Text(skill.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  FilledButton.tonal(
                    onPressed: myTurn
                        ? () => _submit(BattleAction.endTurn(actorUid: uid))
                        : null,
                    child: const Text('End'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
