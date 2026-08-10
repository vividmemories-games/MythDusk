#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:mythdusk/core/assets/game_assets.dart';
import 'package:mythdusk/features/battle/domain/enemy_def.dart';
import 'package:mythdusk/features/battle/domain/enemy_effect.dart';
import 'package:mythdusk/features/campaign/domain/campaign_models.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/prep/domain/prep_item.dart';
import 'package:mythdusk/features/puzzle/domain/board_template.dart';
import 'package:mythdusk/features/puzzle/domain/level_board_config.dart';
import 'package:mythdusk/features/puzzle/domain/overlay_def.dart';
import 'package:mythdusk/features/puzzle/domain/tile_color.dart';

const _resourceIds = {
  'attack',
  'mana',
  'healing',
  'shield',
  'ultimate',
};

class ContentValidationResult {
  const ContentValidationResult({
    required this.errors,
    required this.chapterCount,
    required this.nodeCount,
  });

  final List<String> errors;
  final int chapterCount;
  final int nodeCount;

  bool get isValid => errors.isEmpty;
}

class ContentValidator {
  ContentValidator(this.root);

  final Directory root;
  final List<String> _errors = [];

  ContentValidationResult validate() {
    _errors.clear();
    final overlays = _loadOverlays();
    final templates = _loadTemplates(overlays);

    _validateHeroCatalog();
    _validateEnemyCatalog(overlays);
    _validateStaticAssets();

    final campaign = _validateCampaign(templates, overlays);
    return ContentValidationResult(
      errors: List.unmodifiable(_errors),
      chapterCount: campaign.$1,
      nodeCount: campaign.$2,
    );
  }

  OverlayCatalog _loadOverlays() {
    const path = 'assets/boards/overlays.json';
    final json = _readJsonMap(path);
    final raw = json?['overlays'];
    if (raw is! List) {
      _error(path, 'must contain an overlays list');
      return OverlayCatalog(const []);
    }

    _checkUniqueIds(raw, path, 'overlay');
    for (final entry in raw.whereType<Map>()) {
      final item = Map<String, dynamic>.from(entry);
      final id = item['id'] ?? '<unknown>';
      final maxLayers = item['maxLayers'];
      if (maxLayers is! int || maxLayers < 1) {
        _error(path, '$id maxLayers must be a positive integer');
      }
    }

    try {
      return OverlayCatalog.fromJson(json!);
    } on Object catch (error) {
      _error(path, 'cannot load overlay catalog: $error');
      return OverlayCatalog(const []);
    }
  }

  BoardTemplateCatalog _loadTemplates(OverlayCatalog overlays) {
    const path = 'assets/boards/templates.json';
    final json = _readJsonMap(path);
    final raw = json?['templates'];
    if (raw is! List) {
      _error(path, 'must contain a templates list');
      return BoardTemplateCatalog(const []);
    }

    _checkUniqueIds(raw, path, 'board template');
    try {
      final catalog = BoardTemplateCatalog.fromJson(
        json!,
        overlays: overlays,
      );
      for (final template in catalog.all) {
        if (template.width < 3 || template.height < 3) {
          _error(path, '${template.id} must be at least 3×3');
        }
        final playable = template.cells.where((cell) => !cell.masked).length;
        if (playable < 3) {
          _error(path, '${template.id} needs at least 3 playable cells');
        }
      }
      return catalog;
    } on Object catch (error) {
      _error(path, 'cannot load board templates: $error');
      return BoardTemplateCatalog(const []);
    }
  }

  void _validateHeroCatalog() {
    _checkUniqueValues(
      HeroCatalog.all.map((hero) => hero.id),
      'HeroCatalog',
      'hero id',
    );
    final skillIds = <String>[];
    for (final hero in HeroCatalog.all) {
      if (hero.maxHp <= 0 || hero.movesPerTurn <= 0 || hero.maxAp <= 0) {
        _error('HeroCatalog', '${hero.id} has non-positive combat stats');
      }
      for (final resource in hero.primaryResources) {
        if (!_resourceIds.contains(resource)) {
          _error('HeroCatalog', '${hero.id} uses unknown resource $resource');
        }
      }
      for (final skill in hero.skills) {
        skillIds.add(skill.id);
        if (skill.apCost < 0) {
          _error('HeroCatalog', '${skill.id} has a negative AP cost');
        }
        if (skill.damage < 0 || skill.heal < 0 || skill.shield < 0) {
          _error('HeroCatalog', '${skill.id} has a negative effect value');
        }
        if (skill.damage == 0 && skill.heal == 0 && skill.shield == 0) {
          _error('HeroCatalog', '${skill.id} has no gameplay effect');
        }
        for (final cost in skill.resourceCosts.entries) {
          if (!_resourceIds.contains(cost.key)) {
            _error('HeroCatalog', '${skill.id} costs unknown ${cost.key}');
          }
          if (cost.value <= 0) {
            _error(
                'HeroCatalog', '${skill.id} has non-positive ${cost.key} cost');
          }
        }
      }
      if (hero.skills.length < 2) {
        _error(
            'HeroCatalog', '${hero.id} needs at least 2 skills for loadouts');
      }
      _requireAsset(GameAssets.hero(hero.id), 'hero ${hero.id}');
    }
    _checkUniqueValues(skillIds, 'HeroCatalog', 'skill id');
  }

  void _validateEnemyCatalog(OverlayCatalog overlays) {
    _checkUniqueValues(
      EnemyCatalog.all.map((enemy) => enemy.id),
      'EnemyCatalog',
      'enemy id',
    );
    for (final enemy in EnemyCatalog.all) {
      if (enemy.maxHp <= 0 || enemy.skills.isEmpty) {
        _error('EnemyCatalog', '${enemy.id} needs HP and at least one skill');
      }
      _checkUniqueValues(
        enemy.skills.map((skill) => skill.id),
        'EnemyCatalog/${enemy.id}',
        'skill id',
      );
      var totalWeight = 0;
      for (final skill in enemy.skills) {
        totalWeight += skill.weight;
        if (skill.damage < 0 || skill.weight <= 0) {
          _error(
            'EnemyCatalog/${enemy.id}',
            '${skill.id} has invalid damage or weight',
          );
        }
        for (final effect in skill.effects) {
          _validateEnemyEffect(enemy.id, skill.id, effect, overlays);
        }
      }
      if (totalWeight != 100) {
        _error('EnemyCatalog/${enemy.id}',
            'skill weights total $totalWeight, not 100');
      }
      _requireAsset(GameAssets.enemy(enemy.id), 'enemy ${enemy.id}');
    }
  }

  void _validateEnemyEffect(
    String enemyId,
    String skillId,
    EnemyEffect effect,
    OverlayCatalog overlays,
  ) {
    final location = 'EnemyCatalog/$enemyId/$skillId';
    switch (effect) {
      case ModifyMovesEffect(:final amount):
        if (amount >= 0) {
          _error(location, 'modify_moves amount must be negative');
        }
      case DrainResourceEffect(:final resource, :final amount):
        if (!_resourceIds.contains(resource.id) || amount <= 0) {
          _error(
              location, 'drain_resource needs a known resource and amount > 0');
        }
      case ApplyOverlayEffect(:final overlayId, :final count):
        if (overlays[overlayId] == null) {
          _error(location, 'apply_overlay references $overlayId');
        }
        if (!EnemyEffect.supportsOverlay(overlayId)) {
          _error(location, 'battle resolver cannot apply overlay $overlayId');
        }
        if (count <= 0) {
          _error(location, 'apply_overlay count must be positive');
        }
      case HealSelfEffect(:final amount):
        if (amount <= 0) {
          _error(location, 'heal_self amount must be positive');
        }
      case ModifySpawnWeightsEffect(:final weights):
        if (weights.isEmpty) {
          _error(location, 'modify_spawn_weights needs at least one weight');
        }
        var anyPositive = false;
        for (final entry in weights.entries) {
          if (!TileColorId.known.contains(entry.key)) {
            _error(location, 'unknown tile color ${entry.key}');
          }
          if (entry.value < 0) {
            _error(location, '${entry.key} spawn weight cannot be negative');
          }
          if (entry.value > 0) anyPositive = true;
        }
        if (!anyPositive) {
          _error(location, 'at least one spawn weight must be positive');
        }
    }
  }

  void _validateStaticAssets() {
    for (final asset in GameAssets.prepIcons) {
      _requireAsset(asset, 'prep item');
    }
    _requireAsset(GameAssets.homeBackground, 'home background');
    _requireAsset(GameAssets.battleTwilightRoad, 'default battle background');
    for (final color in TileColor.values) {
      _requireAsset(GameAssets.tile(color), '${color.name} tile');
    }
  }

  (int, int) _validateCampaign(
    BoardTemplateCatalog templates,
    OverlayCatalog overlays,
  ) {
    const indexPath = 'assets/levels/campaign_index.json';
    final indexJson = _readJsonMap(indexPath);
    final rawEntries = indexJson?['chapters'];
    if (rawEntries is! List) {
      _error(indexPath, 'must contain a chapters list');
      return (0, 0);
    }
    _checkUniqueIds(rawEntries, indexPath, 'chapter');
    _checkUniqueField(rawEntries, indexPath, 'chapter', 'order');

    final chapters = <CampaignChapter>[];
    final requirements = <String, String>{};
    final allActIds = <String>[];
    final allNodeIds = <String>[];

    for (final rawEntry in rawEntries.whereType<Map>()) {
      final entry = Map<String, dynamic>.from(rawEntry);
      final id = entry['id'];
      final asset = entry['asset'];
      if (id is! String || id.isEmpty || asset is! String || asset.isEmpty) {
        _error(indexPath, 'chapter entries require non-empty id and asset');
        continue;
      }
      _requireAsset(asset, 'chapter $id data');
      final requirement = entry['requiresNodeId'];
      if (requirement is String && requirement.isNotEmpty) {
        requirements[id] = requirement;
      }

      final chapterJson = _readJsonMap(asset);
      if (chapterJson == null) continue;
      try {
        final chapter = CampaignChapter.fromJson(chapterJson);
        chapters.add(chapter);
        if (chapter.id != id) {
          _error(asset, 'chapter id ${chapter.id} does not match index id $id');
        }
        _validateChapter(
          chapter,
          asset,
          templates,
          overlays,
          allActIds,
          allNodeIds,
        );
      } on Object catch (error) {
        _error(asset, 'cannot load campaign chapter: $error');
      }
    }

    _checkUniqueValues(allActIds, 'campaign', 'act id');
    _checkUniqueValues(allNodeIds, 'campaign', 'node id');
    final nodeIdSet = allNodeIds.toSet();
    for (final requirement in requirements.entries) {
      if (!nodeIdSet.contains(requirement.value)) {
        _error(
          indexPath,
          '${requirement.key} requires missing node ${requirement.value}',
        );
      }
    }
    return (chapters.length, allNodeIds.length);
  }

  void _validateChapter(
    CampaignChapter chapter,
    String path,
    BoardTemplateCatalog templates,
    OverlayCatalog overlays,
    List<String> allActIds,
    List<String> allNodeIds,
  ) {
    if (chapter.acts.isEmpty || chapter.nodes.isEmpty) {
      _error(path, '${chapter.id} must contain acts and nodes');
      return;
    }
    final orders = chapter.nodes.map((node) => node.order).toList()..sort();
    final expectedOrders = List<int>.generate(chapter.nodes.length, (i) => i);
    if (!_sameList(orders, expectedOrders)) {
      _error(path, '${chapter.id} node orders must be contiguous from zero');
    }

    _requireAsset(
      GameAssets.battleBackground(chapter.backgroundId),
      '${chapter.id} battle background',
    );

    for (final act in chapter.acts) {
      allActIds.add(act.id);
      _requireAsset(act.mapAsset, 'map ${chapter.id}/${act.id}');
      if (act.nodes.isEmpty) {
        _error(path, '${act.id} has no nodes');
        continue;
      }
      if (!act.finale.isBoss) {
        _error(
            path, '${act.id} finale ${act.finale.id} is not marked as a boss');
      }
    }

    for (final node in chapter.nodes) {
      allNodeIds.add(node.id);
      final location = '$path/${node.id}';
      final enemy = EnemyCatalog.tryById(node.enemyId);
      if (enemy == null) {
        _error(location, 'references unknown enemy ${node.enemyId}');
      } else {
        if (node.isBoss != enemy.isBoss) {
          _error(location, 'boss flag disagrees with enemy ${enemy.id}');
        }
        _requireAsset(
          GameAssets.enemy(enemy.id, bossForm: node.bossForm),
          'enemy art ${node.id}',
        );
      }
      if (node.coinReward < 0) {
        _error(location, 'coinReward cannot be negative');
      }
      if (node.isBoss && (node.bossForm == null || node.bossForm! < 1)) {
        _error(location, 'boss node needs a valid bossForm');
      }
      for (final drop in node.prepDrops) {
        if (PrepItemIdX.tryParseDrop(drop) == null) {
          _error(location, 'references unknown prep drop $drop');
        }
      }
      _validateBoardConfig(
        chapter.boardFor(node),
        location,
        templates,
        overlays,
      );
    }
  }

  void _validateBoardConfig(
    LevelBoardConfig board,
    String location,
    BoardTemplateCatalog templates,
    OverlayCatalog overlays,
  ) {
    final templateId = board.templateId;
    final template = templateId == null ? null : templates[templateId];
    if (templateId == null || templateId.isEmpty) {
      _error(location, 'has no resolved board template');
    } else if (template == null) {
      _error(location, 'references unknown board template $templateId');
    }

    final weights = board.spawnWeights;
    if (weights != null) {
      var positiveWeights = 0;
      for (final color in TileColor.values) {
        final weight = weights.weightOf(color);
        if (weight < 0) {
          _error(location, '${color.name} spawn weight cannot be negative');
        }
        if (weight > 0) positiveWeights++;
      }
      if (positiveWeights == 0) {
        _error(location, 'at least one tile spawn weight must be positive');
      }
    }

    final hazard = board.hazardSpawn;
    if (hazard != null) {
      if (overlays[hazard.overlayId] == null) {
        _error(
            location, 'hazard references unknown overlay ${hazard.overlayId}');
      }
      if (hazard.chancePerTurn < 0 || hazard.chancePerTurn > 1) {
        _error(location, 'hazard chancePerTurn must be between 0 and 1');
      }
      if (hazard.maxOnBoard <= 0) {
        _error(location, 'hazard maxOnBoard must be positive');
      }
    }

    for (final mover in board.effectiveMovers) {
      if (mover.everyNTurns <= 0) {
        _error(location, '${mover.type} everyNTurns must be positive');
      }
      switch (mover.type) {
        case 'row_shove':
          if (mover.rows.isEmpty ||
              !{'left', 'right'}.contains(mover.direction)) {
            _error(location, 'row_shove needs rows and a left/right direction');
          }
          if (template != null &&
              mover.rows.any((row) => row < 0 || row >= template.height)) {
            _error(location, 'row_shove contains an out-of-bounds row');
          }
        case 'col_shove':
          if (mover.cols.isEmpty || !{'up', 'down'}.contains(mover.direction)) {
            _error(
                location, 'col_shove needs columns and an up/down direction');
          }
          if (template != null &&
              mover.cols.any((col) => col < 0 || col >= template.width)) {
            _error(location, 'col_shove contains an out-of-bounds column');
          }
        default:
          _error(location, 'uses unsupported board mover ${mover.type}');
      }
    }
  }

  Map<String, dynamic>? _readJsonMap(String relativePath) {
    final file = File('${root.path}/$relativePath');
    if (!file.existsSync()) {
      _error(relativePath, 'file does not exist');
      return null;
    }
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map) {
        _error(relativePath, 'root JSON value must be an object');
        return null;
      }
      return Map<String, dynamic>.from(decoded);
    } on Object catch (error) {
      _error(relativePath, 'invalid JSON: $error');
      return null;
    }
  }

  void _requireAsset(String relativePath, String owner) {
    if (!File('${root.path}/$relativePath').existsSync()) {
      _error(owner, 'missing asset $relativePath');
    }
  }

  void _checkUniqueIds(List<dynamic> items, String path, String label) {
    _checkUniqueValues(
      items.whereType<Map>().map((item) => item['id']).whereType<String>(),
      path,
      '$label id',
    );
  }

  void _checkUniqueField(
    List<dynamic> items,
    String path,
    String label,
    String field,
  ) {
    final seen = <Object?>{};
    for (final item in items.whereType<Map>()) {
      final value = item[field];
      if (value == null) {
        _error(path, '$label is missing $field');
      } else if (!seen.add(value)) {
        _error(path, 'duplicate $label $field: $value');
      }
    }
  }

  void _checkUniqueValues(
    Iterable<String> values,
    String path,
    String label,
  ) {
    final seen = <String>{};
    for (final value in values) {
      if (value.isEmpty) {
        _error(path, '$label cannot be empty');
      } else if (!seen.add(value)) {
        _error(path, 'duplicate $label: $value');
      }
    }
  }

  bool _sameList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _error(String location, String message) {
    _errors.add('$location: $message');
  }
}

Directory _findRepoRoot() {
  var directory = Directory.current;
  while (true) {
    if (File('${directory.path}/pubspec.yaml').existsSync() &&
        Directory('${directory.path}/assets').existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) return Directory.current;
    directory = parent;
  }
}

void main() {
  final result = ContentValidator(_findRepoRoot()).validate();
  if (result.isValid) {
    print(
      'content validation: OK '
      '(${result.chapterCount} chapters, ${result.nodeCount} nodes)',
    );
    exit(0);
  }
  for (final error in result.errors) {
    stderr.writeln('CONTENT: $error');
  }
  stderr.writeln('content validation: ${result.errors.length} issue(s)');
  exit(1);
}
