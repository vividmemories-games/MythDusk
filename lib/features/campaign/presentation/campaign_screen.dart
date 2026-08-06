import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../data/campaign_repository.dart';
import '../domain/campaign_models.dart';
import '../providers/pin_coord_overrides.dart';

/// Chapter campaign: one act map at a time (5 pins), with act dots to switch.
class CampaignScreen extends ConsumerStatefulWidget {
  const CampaignScreen({super.key});

  @override
  ConsumerState<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends ConsumerState<CampaignScreen> {
  /// Portrait act maps are 1024×1536.
  static const _mapAspect = 1024 / 1536;

  String? _selectedActId;

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(campaignChapterProvider);
    final profile = ref.watch(profileProvider);
    final editMode = AppFlavor.showQaTools && ref.watch(pinEditModeProvider);
    final overrides = ref.watch(pinCoordOverridesProvider);

    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      body: chapterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load campaign: $e')),
        data: (chapter) {
          final current = chapter.currentAct(profile.completedNodeIds);
          final selectedId = _selectedActId ?? current.id;
          final act = chapter.acts.any((a) => a.id == selectedId)
              ? chapter.actById(selectedId)
              : current;

          return LayoutBuilder(
            builder: (context, constraints) {
              final mapWidth = constraints.maxWidth;
              // Fill the phone at minimum so the path never sits above a
              // black void. Taller than the screen → scrollable strip.
              final naturalHeight = mapWidth / _mapAspect;
              final mapHeight = naturalHeight < constraints.maxHeight
                  ? constraints.maxHeight
                  : naturalHeight;
              final frontier = chapter.frontierOrder(profile.completedNodeIds);
              final actDone =
                  chapter.isActCompleted(act, profile.completedNodeIds);
              final fogTopY =
                  (editMode || actDone) ? 0.0 : _fogStartY(act, frontier);

              final mapLayer = SizedBox(
                width: mapWidth,
                height: mapHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        act.mapAsset,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: MythDuskColors.ink),
                      ),
                    ),
                    if (fogTopY > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: fogTopY * mapHeight,
                        child: const IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Color(0x000B1C24),
                                  Color(0x990B1C24),
                                  Color(0xCC0B1C24),
                                ],
                                stops: [0.0, 0.35, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    for (final node in act.nodes)
                      _positionPin(
                        context: context,
                        chapter: chapter,
                        node: node,
                        profile: profile,
                        mapWidth: mapWidth,
                        mapHeight: mapHeight,
                        editMode: editMode,
                        overrides: overrides,
                      ),
                  ],
                ),
              );

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (mapHeight <= constraints.maxHeight + 0.5)
                    mapLayer
                  else
                    SingleChildScrollView(
                      reverse: true,
                      physics: editMode
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      child: mapLayer,
                    ),
                  _MapHeader(
                    chapter: chapter,
                    act: act,
                    acts: chapter.acts,
                    completed: profile.completedNodeIds,
                    editMode: editMode,
                    onToggleEdit: AppFlavor.showQaTools
                        ? () {
                            ref.read(pinEditModeProvider.notifier).state =
                                !editMode;
                          }
                        : null,
                    onExportPins: () => _exportPins(context, chapter, act),
                    onExportAllPins: () => _exportAllPins(context),
                    onClearActPins: () => _clearActPins(chapter, act),
                    onClearAllPins: _clearAllPins,
                    onSelectAct: (id) {
                      final next = chapter.actById(id);
                      if (!editMode &&
                          !chapter.isActUnlocked(
                              next, profile.completedNodeIds)) {
                        return;
                      }
                      setState(() => _selectedActId = id);
                    },
                  ),
                  if (editMode)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 16,
                      child: Material(
                        color: MythDuskColors.ink.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            'Pin edit · ${overrides.length} saved · '
                            'drag onto pads · reset=act · long-press reset=all',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: MythDuskColors.parchment,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _positionPin({
    required BuildContext context,
    required CampaignChapter chapter,
    required CampaignNode node,
    required PlayerProfile profile,
    required double mapWidth,
    required double mapHeight,
    required bool editMode,
    required Map<String, PinCoord> overrides,
  }) {
    final completed = chapter.isCompleted(node.id, profile.completedNodeIds);
    final unlocked =
        editMode || chapter.isUnlocked(node.id, profile.completedNodeIds);
    final isCurrent = !editMode && unlocked && !completed;
    final fog = editMode
        ? MapFogTier.clear
        : chapter.fogTier(node, profile.completedNodeIds);

    final (baseX, baseY) = _pinAnchor(actNodeCount: 5, node: node);
    final over = overrides[node.id];
    final x = (over?.x ?? baseX).clamp(0.05, 0.95);
    final y = (over?.y ?? baseY).clamp(0.05, 0.95);
    const pinSize = 64.0;
    const slotWidth = 150.0;
    return Positioned(
      left: x * mapWidth - slotWidth / 2,
      top: y * mapHeight - pinSize / 2,
      width: slotWidth,
      child: _NodePin(
        node: node,
        completed: completed,
        unlocked: unlocked,
        isCurrent: isCurrent,
        fog: fog,
        size: pinSize,
        editMode: editMode,
        coordLabel: editMode
            ? '${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}'
            : null,
        onTap: (!editMode && unlocked) ? () => _openNode(context, node) : null,
        onDrag: editMode
            ? (dx, dy) {
                final nx = (x + dx / mapWidth).clamp(0.05, 0.95);
                final ny = (y + dy / mapHeight).clamp(0.05, 0.95);
                ref
                    .read(pinCoordOverridesProvider.notifier)
                    .setPin(node.id, nx, ny);
              }
            : null,
      ),
    );
  }

  Future<void> _exportPins(
    BuildContext context,
    CampaignChapter chapter,
    CampaignAct act,
  ) async {
    final notifier = ref.read(pinCoordOverridesProvider.notifier);
    // Ensure current act positions are in the export even if undragged.
    for (final node in act.nodes) {
      final existing = ref.read(pinCoordOverridesProvider)[node.id];
      if (existing != null) continue;
      final (bx, by) = _pinAnchor(actNodeCount: 5, node: node);
      await notifier.setPin(node.id, node.mapX ?? bx, node.mapY ?? by);
    }
    final ids = act.nodes.map((n) => n.id).toSet();
    final text = notifier.exportJson(onlyNodeIds: ids);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied ${act.nodes.length} pins (${act.title}). '
          'Paste into tools/pin_overrides.json',
        ),
      ),
    );
  }

  Future<void> _exportAllPins(BuildContext context) async {
    final text = ref.read(pinCoordOverridesProvider.notifier).exportJson();
    final count = ref.read(pinCoordOverridesProvider).length;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pin overrides yet — drag some first')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied $count pin overrides. Paste into tools/pin_overrides.json '
          'then run scripts/apply_pin_overrides.py',
        ),
      ),
    );
  }

  Future<void> _clearActPins(CampaignChapter chapter, CampaignAct act) async {
    await ref
        .read(pinCoordOverridesProvider.notifier)
        .clearNodeIds(act.nodes.map((n) => n.id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleared overrides for ${act.title}'),
      ),
    );
  }

  Future<void> _clearAllPins() async {
    final count = ref.read(pinCoordOverridesProvider).length;
    await ref.read(pinCoordOverridesProvider.notifier).clearAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cleared all $count pin overrides')),
    );
  }

  /// Fog blanket starts just above the N+1 pin (or current if no peek).
  double _fogStartY(CampaignAct act, int frontierOrder) {
    final peekOrder = frontierOrder + 1;
    CampaignNode? anchor;
    for (final n in act.nodes) {
      if (n.order == peekOrder) {
        anchor = n;
        break;
      }
    }
    if (anchor == null) {
      for (final n in act.nodes) {
        if (n.order == frontierOrder) {
          anchor = n;
          break;
        }
      }
    }
    anchor ??= act.nodes.isEmpty ? null : act.nodes.first;
    if (anchor == null) return 0.45;
    final y = anchor.mapY ?? 0.5;
    // Cover everything above the peek pin (smaller y = higher on map).
    return (y - 0.06).clamp(0.0, 1.0);
  }

  (double, double) _pinAnchor({
    required int actNodeCount,
    required CampaignNode node,
  }) {
    final x = node.mapX;
    final y = node.mapY;
    if (x != null && y != null) return (x, y);
    final local = node.order % actNodeCount;
    final t = actNodeCount <= 1 ? 0.5 : local / (actNodeCount - 1);
    return (local.isEven ? 0.44 : 0.56, 0.88 - 0.70 * t);
  }

  Future<void> _openNode(BuildContext context, CampaignNode node) async {
    ref.read(profileProvider.notifier).tickLifeRegen();
    if (ref.read(profileProvider).lives <= 0) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No lives left — wait for regen or refill from Home',
          ),
        ),
      );
      return;
    }
    context.push('/briefing/${node.id}');
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.chapter,
    required this.act,
    required this.acts,
    required this.completed,
    required this.onSelectAct,
    required this.editMode,
    required this.onToggleEdit,
    required this.onExportPins,
    required this.onExportAllPins,
    required this.onClearActPins,
    required this.onClearAllPins,
  });

  final CampaignChapter chapter;
  final CampaignAct act;
  final List<CampaignAct> acts;
  final Set<String> completed;
  final ValueChanged<String> onSelectAct;
  final bool editMode;
  final VoidCallback? onToggleEdit;
  final VoidCallback onExportPins;
  final VoidCallback onExportAllPins;
  final VoidCallback onClearActPins;
  final VoidCallback onClearAllPins;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Material(
                  color: MythDuskColors.ink.withValues(alpha: 0.55),
                  shape: CircleBorder(
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.pop(),
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: MythDuskColors.parchment,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: MythDuskColors.ink.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: MythDuskColors.softGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${chapter.title} · ${act.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: MythDuskColors.parchment,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (onToggleEdit != null)
                  Material(
                    color: editMode
                        ? MythDuskColors.amber.withValues(alpha: 0.35)
                        : MythDuskColors.ink.withValues(alpha: 0.55),
                    shape: CircleBorder(
                      side: BorderSide(
                        color: editMode
                            ? MythDuskColors.amber
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onToggleEdit,
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          Icons.open_with,
                          size: 18,
                          color: editMode
                              ? MythDuskColors.amber
                              : MythDuskColors.parchment,
                        ),
                      ),
                    ),
                  ),
                if (editMode) ...[
                  const SizedBox(width: 6),
                  Material(
                    color: MythDuskColors.ink.withValues(alpha: 0.55),
                    shape: CircleBorder(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onExportPins,
                      child: const SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          Icons.copy_outlined,
                          size: 18,
                          color: MythDuskColors.parchment,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: MythDuskColors.ink.withValues(alpha: 0.55),
                    shape: CircleBorder(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onExportAllPins,
                      child: const SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          Icons.copy_all_outlined,
                          size: 18,
                          color: MythDuskColors.parchment,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: MythDuskColors.ink.withValues(alpha: 0.55),
                    shape: CircleBorder(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onClearActPins,
                      onLongPress: onClearAllPins,
                      child: const SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          Icons.restart_alt,
                          size: 18,
                          color: MythDuskColors.parchment,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final a in acts) ...[
                  if (a.index > 0) const SizedBox(width: 8),
                  _ActDot(
                    act: a,
                    selected: a.id == act.id,
                    unlocked: editMode || chapter.isActUnlocked(a, completed),
                    completed: chapter.isActCompleted(a, completed),
                    onTap: () => onSelectAct(a.id),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActDot extends StatelessWidget {
  const _ActDot({
    required this.act,
    required this.selected,
    required this.unlocked,
    required this.completed,
    required this.onTap,
  });

  final CampaignAct act;
  final bool selected;
  final bool unlocked;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (act.index) {
      0 => 'I',
      1 => 'II',
      2 => 'III',
      _ => 'IV',
    };
    final border = selected
        ? MythDuskColors.softGold
        : completed
            ? MythDuskColors.amber
            : MythDuskColors.muted.withValues(alpha: 0.45);
    return Material(
      color: MythDuskColors.ink.withValues(alpha: unlocked ? 0.65 : 0.35),
      shape: StadiumBorder(
          side: BorderSide(color: border, width: selected ? 2 : 1)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: unlocked ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: unlocked
                        ? MythDuskColors.parchment
                        : MythDuskColors.muted,
                  ),
                ),
                if (!unlocked) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.lock, size: 12, color: MythDuskColors.muted),
                ] else if (completed) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check, size: 12, color: MythDuskColors.amber),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NodePin extends StatelessWidget {
  const _NodePin({
    required this.node,
    required this.completed,
    required this.unlocked,
    required this.isCurrent,
    required this.fog,
    required this.size,
    required this.editMode,
    required this.onTap,
    this.onDrag,
    this.coordLabel,
  });

  final CampaignNode node;
  final bool completed;
  final bool unlocked;
  final bool isCurrent;
  final MapFogTier fog;
  final double size;
  final bool editMode;
  final VoidCallback? onTap;
  final void Function(double dx, double dy)? onDrag;
  final String? coordLabel;

  @override
  Widget build(BuildContext context) {
    final ringColor = editMode
        ? MythDuskColors.softGold
        : completed
            ? MythDuskColors.amber
            : isCurrent
                ? MythDuskColors.softGold
                : MythDuskColors.muted.withValues(alpha: 0.5);

    Widget portrait = ClipOval(
      child: ColoredBox(
        color: MythDuskColors.ink.withValues(alpha: 0.45),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            GameAssets.enemy(node.enemyId, bossForm: node.bossForm),
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: MythDuskColors.deepTeal,
              child: Icon(Icons.flag, color: MythDuskColors.parchment),
            ),
          ),
        ),
      ),
    );

    if (!unlocked || fog != MapFogTier.clear) {
      portrait = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0, 0, 0, 0.7, 0, //
        ]),
        child: portrait,
      );
    }

    final scale = node.isBoss ? 1.15 : 1.0;
    final opacity = switch (fog) {
      MapFogTier.clear => 1.0,
      MapFogTier.peek => 0.72,
      MapFogTier.shrouded => 0.22,
    };
    final showLabel = fog != MapFogTier.shrouded;
    final showLock = !unlocked && fog == MapFogTier.clear;

    final pin = Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseRing(
            enabled: isCurrent,
            child: Container(
              width: size * scale,
              height: size * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MythDuskColors.ink.withValues(alpha: 0.35),
                border: Border.all(
                  color: ringColor.withValues(
                    alpha: fog == MapFogTier.shrouded ? 0.35 : 1,
                  ),
                  width: (isCurrent || editMode) ? 3 : 2,
                ),
                boxShadow: [
                  if (isCurrent || editMode)
                    BoxShadow(
                      color: MythDuskColors.softGold.withValues(alpha: 0.55),
                      blurRadius: 16,
                      spreadRadius: 1,
                    )
                  else if (fog != MapFogTier.shrouded)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  portrait,
                  if (showLock)
                    const Center(
                      child: Icon(
                        Icons.lock,
                        size: 20,
                        color: MythDuskColors.parchment,
                      ),
                    ),
                  if (completed && !editMode)
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: Icon(
                        Icons.check_circle,
                        size: 20,
                        color: MythDuskColors.amber,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: MythDuskColors.ink.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ringColor.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                coordLabel != null
                    ? '${node.order + 1} · $coordLabel'
                    : node.isBoss
                        ? '${node.order + 1}. Boss'
                        : fog == MapFogTier.peek
                            ? '${node.order + 1}. ???'
                            : '${node.order + 1}. ${node.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 10,
                      color: unlocked
                          ? MythDuskColors.parchment
                          : MythDuskColors.muted,
                    ),
              ),
            ),
          ],
        ],
      ),
    );

    if (editMode) {
      return GestureDetector(
        onPanUpdate: (d) => onDrag?.call(d.delta.dx, d.delta.dy),
        child: pin,
      );
    }

    final hidden = fog != MapFogTier.clear;
    final status = completed
        ? 'completed'
        : unlocked && !hidden
            ? 'available'
            : 'locked';
    return Semantics(
      button: unlocked && !hidden,
      enabled: unlocked && !hidden,
      label: '${hidden ? 'Unknown campaign node' : node.name}, $status',
      excludeSemantics: true,
      child: IgnorePointer(
        ignoring: hidden || !unlocked,
        child: GestureDetector(onTap: onTap, child: pin),
      ),
    );
  }
}

class _PulseRing extends StatefulWidget {
  const _PulseRing({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.scale(scale: 1.0 + 0.06 * t, child: child);
      },
      child: widget.child,
    );
  }
}
