import '../../puzzle/domain/level_board_config.dart';

class CampaignNode {
  const CampaignNode({
    required this.id,
    required this.name,
    required this.enemyId,
    required this.coinReward,
    required this.order,
    this.kind = 'normal',
    this.bossForm,
    this.backgroundId,
    this.mapX,
    this.mapY,
    this.board = const LevelBoardConfig(),
    this.minMoves,
    this.enrageAfterTurns,
    this.prepDrops = const [],
  });

  final String id;
  final String name;
  final String enemyId;
  final int coinReward;

  /// Chapter-global order (0–19 for a 20-node chapter).
  final int order;

  /// `normal` | `boss_sighting`
  final String kind;

  /// Returning chapter-boss form 1–4. Null for trash nodes.
  final int? bossForm;

  /// Optional battle BG override (defaults to chapter BG).
  final String? backgroundId;

  /// Pin on this act's map art, normalized 0–1.
  final double? mapX;
  final double? mapY;

  /// Per-node board overrides (merged over chapter [boardDefaults]).
  final LevelBoardConfig board;

  /// Optional moves floor override (default 2 via PrepBalance).
  final int? minMoves;

  /// Optional boss enrage after N player turns.
  final int? enrageAfterTurns;

  /// Prep item ids granted on clear (e.g. `prep_vanguard_tonic`).
  final List<String> prepDrops;

  bool get isBoss => kind == 'boss_sighting' || kind == 'boss';

  factory CampaignNode.fromJson(Map<String, dynamic> json) {
    double? coord(Object? v) {
      if (v is! num) return null;
      final d = v.toDouble();
      return (d < 0 || d > 1) ? null : d;
    }

    final rawForm = json['bossForm'];
    final form =
        rawForm is int ? rawForm : (rawForm is num ? rawForm.toInt() : null);

    final dropsRaw = json['prepDrops'] as List<dynamic>?;

    return CampaignNode(
      id: json['id'] as String,
      name: json['name'] as String,
      enemyId: json['enemyId'] as String,
      coinReward: json['coinReward'] as int,
      order: json['order'] as int,
      kind: json['kind'] as String? ?? 'normal',
      bossForm: (form != null && form >= 1 && form <= 4) ? form : null,
      backgroundId: json['backgroundId'] as String?,
      mapX: coord(json['mapX']),
      mapY: coord(json['mapY']),
      board: LevelBoardConfig.fromJson(
        json['board'] as Map<String, dynamic>?,
      ),
      minMoves: json['minMoves'] as int?,
      enrageAfterTurns: json['enrageAfterTurns'] as int?,
      prepDrops: [
        for (final e in dropsRaw ?? const [])
          if (e is String) e,
      ],
    );
  }
}

/// One map segment of a chapter (e.g. Ch1 Act I = nodes 1–5).
class CampaignAct {
  const CampaignAct({
    required this.id,
    required this.title,
    required this.mapAsset,
    required this.nodes,
    this.index = 0,
  });

  final String id;
  final String title;

  /// Asset path for this act's portrait map.
  final String mapAsset;
  final List<CampaignNode> nodes;

  /// 0-based act index within the chapter.
  final int index;

  factory CampaignAct.fromJson(Map<String, dynamic> json, {int index = 0}) {
    final rawNodes = json['nodes'] as List<dynamic>;
    final nodes = rawNodes
        .map((e) => CampaignNode.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return CampaignAct(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Act ${index + 1}',
      mapAsset: json['mapAsset'] as String,
      nodes: nodes,
      index: index,
    );
  }

  CampaignNode get finale => nodes.last;
}

class CampaignChapter {
  const CampaignChapter({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.acts,
    this.boardDefaults = const LevelBoardConfig(),
    this.backgroundId,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<CampaignAct> acts;

  /// Chapter-wide board defaults (template, spawn weights, movers).
  final LevelBoardConfig boardDefaults;

  /// Default battle stage background id (e.g. `bg_battle_mistfen_marshes`).
  final String? backgroundId;

  /// Flat node list in unlock order (across all acts).
  List<CampaignNode> get nodes => [for (final a in acts) ...a.nodes];

  /// Resolved board config for a node (defaults ← node overrides).
  LevelBoardConfig boardFor(CampaignNode node) =>
      node.board.mergeOver(boardDefaults);

  factory CampaignChapter.fromJson(Map<String, dynamic> json) {
    final defaults = LevelBoardConfig.fromJson(
      json['boardDefaults'] as Map<String, dynamic>?,
    );
    final backgroundId = json['backgroundId'] as String?;

    // New schema: acts[]. Legacy: flat nodes[] → one synthetic act.
    if (json['acts'] is List) {
      final rawActs = json['acts'] as List<dynamic>;
      final acts = <CampaignAct>[];
      for (var i = 0; i < rawActs.length; i++) {
        acts.add(
          CampaignAct.fromJson(rawActs[i] as Map<String, dynamic>, index: i),
        );
      }
      return CampaignChapter(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        acts: acts,
        boardDefaults: defaults,
        backgroundId: backgroundId,
      );
    }

    final rawNodes = json['nodes'] as List<dynamic>? ?? const [];
    final nodes = rawNodes
        .map((e) => CampaignNode.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return CampaignChapter(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      boardDefaults: defaults,
      backgroundId: backgroundId,
      acts: [
        CampaignAct(
          id: '${json['id']}_act1',
          title: 'Act I',
          mapAsset: json['mapAsset'] as String? ??
              'assets/images/maps/map_ch_twilight_road_a1.webp',
          nodes: nodes,
        ),
      ],
    );
  }

  CampaignNode nodeById(String id) =>
      nodes.firstWhere((n) => n.id == id, orElse: () => nodes.first);

  CampaignAct actById(String id) =>
      acts.firstWhere((a) => a.id == id, orElse: () => acts.first);

  CampaignAct? actForNode(String nodeId) {
    for (final act in acts) {
      if (act.nodes.any((n) => n.id == nodeId)) return act;
    }
    return null;
  }

  bool isUnlocked(String nodeId, Set<String> completedNodeIds) {
    final node = nodeById(nodeId);
    if (node.order == 0) return true;
    final prev = nodes.where((n) => n.order == node.order - 1);
    if (prev.isEmpty) return true;
    return completedNodeIds.contains(prev.first.id);
  }

  bool isCompleted(String nodeId, Set<String> completedNodeIds) =>
      completedNodeIds.contains(nodeId);

  bool isActUnlocked(CampaignAct act, Set<String> completedNodeIds) {
    if (act.index == 0) return true;
    final prev = acts[act.index - 1];
    return completedNodeIds.contains(prev.finale.id);
  }

  bool isActCompleted(CampaignAct act, Set<String> completedNodeIds) =>
      completedNodeIds.contains(act.finale.id);

  /// Furthest unlocked act (for auto-resume).
  CampaignAct currentAct(Set<String> completedNodeIds) {
    CampaignAct best = acts.first;
    for (final act in acts) {
      if (isActUnlocked(act, completedNodeIds)) best = act;
    }
    return best;
  }

  /// Order of the node the player should play next (first unlocked incomplete).
  /// If the chapter is fully cleared, returns the last node's order.
  int frontierOrder(Set<String> completedNodeIds) {
    for (final node in nodes) {
      if (isUnlocked(node.id, completedNodeIds) &&
          !isCompleted(node.id, completedNodeIds)) {
        return node.order;
      }
    }
    if (nodes.isEmpty) return 0;
    return nodes.last.order;
  }

  /// Fog of war: completed + current are clear; N+1 is a peek; farther is shrouded.
  MapFogTier fogTier(CampaignNode node, Set<String> completedNodeIds) {
    if (isCompleted(node.id, completedNodeIds)) return MapFogTier.clear;
    final frontier = frontierOrder(completedNodeIds);
    if (node.order <= frontier) return MapFogTier.clear;
    if (node.order == frontier + 1) return MapFogTier.peek;
    return MapFogTier.shrouded;
  }
}

/// How visible a pin is under map fog of war.
enum MapFogTier {
  /// Completed or current playable node.
  clear,

  /// Immediate next node (N+1) — visible but not yet playable.
  peek,

  /// Beyond N+1 — barely visible through fog.
  shrouded,
}
