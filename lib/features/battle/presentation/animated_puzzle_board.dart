import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../puzzle/domain/board_cell.dart';
import '../../puzzle/domain/tile_color.dart';
import '../domain/battle_state.dart';

/// Flat match-3 board, bottom-anchored above the skill dock.
/// No grid chrome — gems float on the background with soft contact shadows.
class AnimatedPuzzleBoard extends StatelessWidget {
  const AnimatedPuzzleBoard({
    super.key,
    required this.battle,
    required this.onTap,
    this.onSwipe,
  });

  final BattleState battle;
  final void Function(int row, int col) onTap;

  /// Primary match-3 input: swipe from one cell toward an adjacent neighbor.
  final void Function((int, int) from, (int, int) to)? onSwipe;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Bottom breathing room lifts the board off the skill dock.
        // Cap so gems don't dwarf the fighters (~85% + 5% bump).
        const bottomGap = 18.0;
        const boardScale = 0.89;
        final available = math.max(0.0, constraints.maxHeight - bottomGap);
        final boardSize =
            math.min(constraints.maxWidth, available) * boardScale;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: bottomGap),
            child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: _BoardSurface(
                battle: battle,
                onTap: onTap,
                onSwipe: onSwipe,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardSurface extends StatelessWidget {
  const _BoardSurface({
    required this.battle,
    required this.onTap,
    this.onSwipe,
  });

  final BattleState battle;
  final void Function(int row, int col) onTap;
  final void Function((int, int) from, (int, int) to)? onSwipe;

  @override
  Widget build(BuildContext context) {
    final board = battle.board;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 3.0;
        final cellW =
            (constraints.maxWidth - gap * (board.width - 1)) / board.width;
        final cellH =
            (constraints.maxHeight - gap * (board.height - 1)) / board.height;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var row = 0; row < board.height; row++)
              for (var col = 0; col < board.width; col++)
                _BoardSlotBackdrop(
                  row: row,
                  col: col,
                  cell: board.at(row, col),
                  cellW: cellW,
                  cellH: cellH,
                  gap: gap,
                ),
            for (final mover in battle.movers)
              if (mover.type == 'row_shove')
                for (final row in mover.rows)
                  if (row >= 0 && row < board.height)
                    _WindLane(
                      row: row,
                      direction: mover.direction,
                      boardWidth: board.width,
                      cellW: cellW,
                      cellH: cellH,
                      gap: gap,
                      pulsing: battle.combatFx == CombatFx.wind &&
                          battle.windRows.contains(row),
                    ),
            if (battle.combatFx == CombatFx.wind)
              _WindGustOverlay(
                direction: battle.windDirection ?? 'left',
                windRows: battle.windRows,
                boardHeight: board.height,
                cellW: cellW,
                cellH: cellH,
                gap: gap,
                boardWidth: board.width,
              ),
            for (var row = 0; row < board.height; row++)
              for (var col = 0; col < board.width; col++)
                if (board.at(row, col).isPlayable &&
                    board.at(row, col).id != null)
                  _BoardTile(
                    key: ValueKey('tile-${board.at(row, col).id}'),
                    id: board.at(row, col).id!,
                    row: row,
                    col: col,
                    color: board.at(row, col).color,
                    special: board.at(row, col).special,
                    overlayId: board.at(row, col).overlayId,
                    suppressesResources: board.at(row, col).suppressesResources,
                    cellW: cellW,
                    cellH: cellH,
                    gap: gap,
                    selected: battle.selectedCell == (row, col),
                    hinted: battle.hintCells.contains((row, col)),
                    clearing: battle.clearingCells.contains((row, col)),
                    spawning:
                        battle.spawningIds.contains(board.at(row, col).id),
                    windShoving: battle.combatFx == CombatFx.wind &&
                        battle.windRows.contains(row),
                    windDirection: battle.windDirection,
                    hazardPulse: battle.hazardPulseCells.contains((row, col)),
                    interactive: !battle.inputLocked,
                    onTap: () => onTap(row, col),
                    onSwipe: onSwipe == null
                        ? null
                        : (to) => onSwipe!((row, col), to),
                  ),
          ],
        );
      },
    );
  }
}

class _BoardSlotBackdrop extends StatelessWidget {
  const _BoardSlotBackdrop({
    required this.row,
    required this.col,
    required this.cell,
    required this.cellW,
    required this.cellH,
    required this.gap,
  });

  final int row;
  final int col;
  final BoardCell cell;
  final double cellW;
  final double cellH;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final left = col * (cellW + gap);
    final top = row * (cellH + gap);
    Color? fill;
    if (cell.masked) {
      fill = MythDuskColors.ink.withValues(alpha: 0.55);
    } else if (cell.isSolidObstacle) {
      fill = const Color(0xFF5A6A72);
    } else {
      fill = MythDuskColors.deepTeal.withValues(alpha: 0.25);
    }
    return Positioned(
      left: left,
      top: top,
      width: cellW,
      height: cellH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(cellW * 0.22),
          border: cell.isSolidObstacle
              ? Border.all(color: MythDuskColors.mist.withValues(alpha: 0.7))
              : null,
        ),
        child: cell.isSolidObstacle
            ? Center(
                child: Icon(
                  Icons.terrain,
                  size: cellW * 0.4,
                  color: MythDuskColors.parchment.withValues(alpha: 0.7),
                ),
              )
            : null,
      ),
    );
  }
}

class _WindLane extends StatefulWidget {
  const _WindLane({
    required this.row,
    required this.direction,
    required this.boardWidth,
    required this.cellW,
    required this.cellH,
    required this.gap,
    required this.pulsing,
  });

  final int row;
  final String direction;
  final int boardWidth;
  final double cellW;
  final double cellH;
  final double gap;
  final bool pulsing;

  @override
  State<_WindLane> createState() => _WindLaneState();
}

class _WindLaneState extends State<_WindLane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _WindLane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.pulsing && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = widget.row * (widget.cellH + widget.gap);
    final width =
        widget.boardWidth * widget.cellW + (widget.boardWidth - 1) * widget.gap;
    final towardRight =
        widget.direction == 'right' || widget.direction == 'down';
    final accent = widget.pulsing
        ? MythDuskColors.softGold.withValues(alpha: 0.7)
        : MythDuskColors.mist.withValues(alpha: 0.28);

    return Positioned(
      left: 0,
      top: top,
      width: width,
      height: widget.cellH,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = widget.pulsing ? _controller.value : 0.0;
            final streak = towardRight ? t : 1 - t;
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.cellW * 0.22),
                border: Border.all(
                  color: accent,
                  width: widget.pulsing ? 2.5 : 1,
                ),
                gradient: LinearGradient(
                  begin: towardRight
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  end: towardRight
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  stops: [
                    (streak - 0.25).clamp(0.0, 1.0),
                    streak.clamp(0.0, 1.0),
                    (streak + 0.25).clamp(0.0, 1.0),
                  ],
                  colors: [
                    accent.withValues(alpha: 0.04),
                    accent.withValues(alpha: widget.pulsing ? 0.45 : 0.14),
                    accent.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Align(
                alignment:
                    towardRight ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    towardRight
                        ? Icons.keyboard_double_arrow_right
                        : Icons.keyboard_double_arrow_left,
                    size: widget.cellH * 0.42,
                    color: accent,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Full-board gust wash while wind shove plays.
class _WindGustOverlay extends StatelessWidget {
  const _WindGustOverlay({
    required this.direction,
    required this.windRows,
    required this.boardHeight,
    required this.boardWidth,
    required this.cellW,
    required this.cellH,
    required this.gap,
  });

  final String direction;
  final Set<int> windRows;
  final int boardHeight;
  final int boardWidth;
  final double cellW;
  final double cellH;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final towardRight = direction == 'right' || direction == 'down';
    final width = boardWidth * cellW + (boardWidth - 1) * gap;
    final height = boardHeight * cellH + (boardHeight - 1) * gap;
    return Positioned(
      left: 0,
      top: 0,
      width: width,
      height: height,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: ValueKey('gust-$direction-${windRows.join(',')}'),
          tween: Tween(begin: 0, end: 1),
          duration: BattleController.windFxDuration,
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Stack(
              children: [
                for (final row in windRows)
                  if (row >= 0 && row < boardHeight)
                    Positioned(
                      left: 0,
                      top: row * (cellH + gap),
                      width: width,
                      height: cellH,
                      child: Opacity(
                        opacity: (1 - value) * 0.55,
                        child: Transform.translate(
                          offset: Offset(
                            towardRight
                                ? (value - 0.5) * cellW * 1.4
                                : (0.5 - value) * cellW * 1.4,
                            0,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(cellW * 0.2),
                              gradient: LinearGradient(
                                begin: towardRight
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                end: towardRight
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                colors: [
                                  MythDuskColors.softGold.withValues(alpha: 0),
                                  MythDuskColors.parchment
                                      .withValues(alpha: 0.35),
                                  MythDuskColors.softGold.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BoardTile extends StatefulWidget {
  const _BoardTile({
    super.key,
    required this.id,
    required this.row,
    required this.col,
    required this.color,
    required this.special,
    required this.overlayId,
    required this.suppressesResources,
    required this.cellW,
    required this.cellH,
    required this.gap,
    required this.selected,
    required this.hinted,
    required this.clearing,
    required this.spawning,
    required this.windShoving,
    required this.windDirection,
    required this.hazardPulse,
    required this.interactive,
    required this.onTap,
    this.onSwipe,
  });

  final int id;
  final int row;
  final int col;
  final TileColor? color;
  final TileSpecial special;
  final String? overlayId;
  final bool suppressesResources;
  final double cellW;
  final double cellH;
  final double gap;
  final bool selected;
  final bool hinted;
  final bool clearing;
  final bool spawning;
  final bool windShoving;
  final String? windDirection;
  final bool hazardPulse;
  final bool interactive;
  final VoidCallback onTap;
  final void Function((int, int) to)? onSwipe;

  @override
  State<_BoardTile> createState() => _BoardTileState();
}

class _BoardTileState extends State<_BoardTile> {
  late double _left;
  late double _top;
  var _spawnDropPending = false;
  var _teleport = false;
  var _wrapFlash = false;
  var _swipeFired = false;
  var _panAccum = Offset.zero;

  double get _targetLeft => widget.col * (widget.cellW + widget.gap);
  double get _targetTop => widget.row * (widget.cellH + widget.gap);

  @override
  void initState() {
    super.initState();
    _left = _targetLeft;
    if (widget.spawning) {
      _top = _targetTop - (widget.cellH + widget.gap) * (widget.row + 3);
      _spawnDropPending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_spawnDropPending) return;
        setState(() {
          _top = _targetTop;
          _spawnDropPending = false;
        });
      });
    } else {
      _top = _targetTop;
    }
  }

  @override
  void didUpdateWidget(covariant _BoardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sizeChanged = oldWidget.cellW != widget.cellW ||
        oldWidget.cellH != widget.cellH ||
        oldWidget.gap != widget.gap;
    final rowDelta = (widget.row - oldWidget.row).abs();
    final colDelta = (widget.col - oldWidget.col).abs();
    // Wrap-around jumps look wrong as a long slide — snap + flash those.
    final wrapped = rowDelta > 1 || colDelta > 1;
    _teleport = sizeChanged || wrapped;
    _wrapFlash = wrapped && widget.windShoving;
    if (sizeChanged) {
      _left = _targetLeft;
      _top = _targetTop;
      _spawnDropPending = false;
    }
  }

  Duration _moveDuration(bool reduceMotion) {
    if (reduceMotion) return Duration.zero;
    if (widget.clearing) {
      return const Duration(milliseconds: 100);
    }
    if (_teleport) return Duration.zero;
    if (widget.windShoving) return BattleController.windFxDuration;
    if (widget.spawning || _spawnDropPending) {
      return BattleController.spawnDuration;
    }
    return BattleController.fallDuration;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final showCreatePop = widget.spawning && widget.special != TileSpecial.none;
    final left = _spawnDropPending ? _left : _targetLeft;
    final top = _spawnDropPending ? _top : _targetTop;
    final shoveSign =
        (widget.windDirection == 'right' || widget.windDirection == 'down')
            ? 1.0
            : -1.0;

    Widget gem = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (!widget.clearing)
          Positioned(
            left: widget.cellW * 0.16,
            right: widget.cellW * 0.16,
            bottom: -widget.cellH * 0.02,
            height: widget.cellH * 0.20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.40),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        AnimatedScale(
          scale: widget.clearing ? 0.12 : (widget.hazardPulse ? 1.08 : 1),
          duration: reduceMotion
              ? Duration.zero
              : (widget.clearing
                  ? BattleController.clearDuration
                  : const Duration(milliseconds: 180)),
          curve: widget.clearing ? Curves.easeInBack : Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: widget.clearing ? 0 : 1,
            duration:
                reduceMotion ? Duration.zero : BattleController.clearDuration,
            child: _HintPulse(
              enabled: widget.hinted && !widget.selected,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: widget.selected
                      ? Border.all(
                          color: MythDuskColors.parchment,
                          width: 2,
                        )
                      : widget.hinted
                          ? Border.all(
                              color: MythDuskColors.softGold,
                              width: 2.5,
                            )
                          : widget.hazardPulse
                              ? Border.all(
                                  color: const Color(0xFF9B59B6),
                                  width: 3,
                                )
                              : null,
                  boxShadow: [
                    if (widget.hinted && !widget.selected)
                      BoxShadow(
                        color: MythDuskColors.softGold.withValues(alpha: 0.55),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    if (widget.hazardPulse)
                      BoxShadow(
                        color: const Color(0xFF9B59B6).withValues(alpha: 0.55),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                clipBehavior: Clip.none,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    Transform.scale(
                      scale: widget.special == TileSpecial.none ? 1.08 : 1.02,
                      child: _TileArt(
                        color: widget.color,
                        special: widget.special,
                      ),
                    ),
                    if (widget.overlayId != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: 1,
                            duration: const Duration(milliseconds: 200),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: widget.suppressesResources
                                      ? const Color(0xFF9B59B6)
                                      : const Color(0xFF3D9B6E),
                                  width: widget.hazardPulse ? 3.5 : 2.5,
                                ),
                                color: (widget.suppressesResources
                                        ? const Color(0xFF9B59B6)
                                        : const Color(0xFF3D9B6E))
                                    .withValues(
                                  alpha: widget.hazardPulse ? 0.4 : 0.22,
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    widget.suppressesResources
                                        ? Icons.science
                                        : Icons.grass,
                                    size: widget.cellW * 0.28,
                                    color: MythDuskColors.parchment,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (showCreatePop)
                      IgnorePointer(
                        child: Image.asset(
                          GameAssets.fxSpecialCreate,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.clearing)
          IgnorePointer(
            child: Image.asset(
              GameAssets.fxMatchClear,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
      ],
    );

    if (widget.windShoving && !reduceMotion) {
      gem = TweenAnimationBuilder<double>(
        key: ValueKey('shove-${widget.id}-${widget.col}'),
        tween: Tween(begin: 0, end: 1),
        duration: BattleController.windFxDuration,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final nudge =
              math.sin(value * math.pi) * shoveSign * widget.cellW * 0.22;
          final flash = _wrapFlash ? (1 - value) * 0.35 : 0.0;
          Widget painted = child!;
          if (flash > 0.01) {
            painted = ColorFiltered(
              colorFilter: ColorFilter.mode(
                MythDuskColors.softGold.withValues(alpha: flash),
                BlendMode.srcATop,
              ),
              child: painted,
            );
          }
          return Transform.translate(
            offset: Offset(nudge, 0),
            child: painted,
          );
        },
        child: gem,
      );
    }

    return AnimatedPositioned(
      duration: _moveDuration(reduceMotion),
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: widget.cellW,
      height: widget.cellH,
      child: GestureDetector(
        onTap: widget.interactive ? widget.onTap : null,
        onPanStart: widget.interactive && widget.onSwipe != null
            ? (_) {
                _swipeFired = false;
                _panAccum = Offset.zero;
              }
            : null,
        onPanUpdate: widget.interactive && widget.onSwipe != null
            ? _handlePanUpdate
            : null,
        onPanEnd: widget.interactive && widget.onSwipe != null
            ? (_) {
                _swipeFired = false;
                _panAccum = Offset.zero;
              }
            : null,
        onPanCancel: widget.interactive && widget.onSwipe != null
            ? () {
                _swipeFired = false;
                _panAccum = Offset.zero;
              }
            : null,
        child: gem,
      ),
    );
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_swipeFired || widget.onSwipe == null) return;
    _panAccum += details.delta;
    final threshold = math.min(widget.cellW, widget.cellH) * 0.28;
    final dx = _panAccum.dx;
    final dy = _panAccum.dy;
    if (dx.abs() < threshold && dy.abs() < threshold) return;

    final (int, int) to;
    if (dx.abs() >= dy.abs()) {
      to = (widget.row, widget.col + (dx > 0 ? 1 : -1));
    } else {
      to = (widget.row + (dy > 0 ? 1 : -1), widget.col);
    }
    _swipeFired = true;
    widget.onSwipe!(to);
  }
}

/// Soft scale pulse while a match hint is active.
class _HintPulse extends StatefulWidget {
  const _HintPulse({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_HintPulse> createState() => _HintPulseState();
}

class _HintPulseState extends State<_HintPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _HintPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// Puzzle gem or power-up art; falls back to tint if asset missing.
class _TileArt extends StatelessWidget {
  const _TileArt({
    required this.color,
    required this.special,
  });

  final TileColor? color;
  final TileSpecial special;

  @override
  Widget build(BuildContext context) {
    final powerupPath = GameAssets.powerup(special);
    if (powerupPath != null) {
      return Image.asset(
        powerupPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _gemFallback(),
      );
    }

    if (color == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: MythDuskColors.ink,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    return Image.asset(
      GameAssets.tile(color!),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _gemFallback(),
    );
  }

  Widget _gemFallback() {
    return ColoredBox(
      color: switch (color) {
        TileColor.red => MythDuskColors.tileRed,
        TileColor.blue => MythDuskColors.tileBlue,
        TileColor.green => MythDuskColors.tileGreen,
        TileColor.yellow => MythDuskColors.tileYellow,
        TileColor.purple => MythDuskColors.tilePurple,
        null => MythDuskColors.ink,
      },
    );
  }
}
