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
  });

  final BattleState battle;
  final void Function(int row, int col) onTap;

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
  });

  final BattleState battle;
  final void Function(int row, int col) onTap;

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
                if (board.at(row, col).isPlayable &&
                    board.at(row, col).id != null)
                  _BoardTile(
                    key: ValueKey('tile-${board.at(row, col).id}'),
                    id: board.at(row, col).id!,
                    row: row,
                    col: col,
                    color: board.at(row, col).color,
                    special: board.at(row, col).special,
                    cellW: cellW,
                    cellH: cellH,
                    gap: gap,
                    selected: battle.selectedCell == (row, col),
                    hinted: battle.hintCells.contains((row, col)),
                    clearing: battle.clearingCells.contains((row, col)),
                    spawning:
                        battle.spawningIds.contains(board.at(row, col).id),
                    interactive: !battle.inputLocked,
                    onTap: () => onTap(row, col),
                  ),
          ],
        );
      },
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
    required this.cellW,
    required this.cellH,
    required this.gap,
    required this.selected,
    required this.hinted,
    required this.clearing,
    required this.spawning,
    required this.interactive,
    required this.onTap,
  });

  final int id;
  final int row;
  final int col;
  final TileColor? color;
  final TileSpecial special;
  final double cellW;
  final double cellH;
  final double gap;
  final bool selected;
  final bool hinted;
  final bool clearing;
  final bool spawning;
  final bool interactive;
  final VoidCallback onTap;

  @override
  State<_BoardTile> createState() => _BoardTileState();
}

class _BoardTileState extends State<_BoardTile> {
  late double _left;
  late double _top;
  var _spawnDropPending = false;

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
    if (oldWidget.row != widget.row ||
        oldWidget.col != widget.col ||
        oldWidget.cellW != widget.cellW ||
        oldWidget.cellH != widget.cellH) {
      _left = _targetLeft;
      _top = _targetTop;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showCreatePop = widget.spawning && widget.special != TileSpecial.none;

    return AnimatedPositioned(
      duration: Duration(
        milliseconds: widget.clearing
            ? 100
            : (widget.spawning || _spawnDropPending ? 280 : 260),
      ),
      curve: Curves.easeOutCubic,
      left: _left,
      top: _top,
      width: widget.cellW,
      height: widget.cellH,
      child: GestureDetector(
        onTap: widget.interactive ? widget.onTap : null,
        child: Stack(
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
              scale: widget.clearing ? 0.15 : 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInBack,
              child: AnimatedOpacity(
                opacity: widget.clearing ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: _HintPulse(
                  enabled: widget.hinted && !widget.selected,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: widget.selected
                          ? Border.all(
                              color: MythoraColors.parchment,
                              width: 2,
                            )
                          : widget.hinted
                              ? Border.all(
                                  color: MythoraColors.softGold,
                                  width: 2.5,
                                )
                              : null,
                      boxShadow: widget.hinted && !widget.selected
                          ? [
                              BoxShadow(
                                color: MythoraColors.softGold
                                    .withValues(alpha: 0.55),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.none,
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        Transform.scale(
                          scale:
                              widget.special == TileSpecial.none ? 1.08 : 1.02,
                          child: _TileArt(
                            color: widget.color,
                            special: widget.special,
                          ),
                        ),
                        if (showCreatePop)
                          IgnorePointer(
                            child: Image.asset(
                              GameAssets.fxSpecialCreate,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
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
        ),
      ),
    );
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
          color: MythoraColors.ink,
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
        TileColor.red => MythoraColors.tileRed,
        TileColor.blue => MythoraColors.tileBlue,
        TileColor.green => MythoraColors.tileGreen,
        TileColor.yellow => MythoraColors.tileYellow,
        TileColor.purple => MythoraColors.tilePurple,
        null => MythoraColors.ink,
      },
    );
  }
}
