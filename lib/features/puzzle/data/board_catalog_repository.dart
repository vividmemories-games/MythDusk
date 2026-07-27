import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/board_template.dart';
import '../domain/overlay_def.dart';

/// Loads overlay + board template catalogs from `assets/boards/`.
class BoardCatalogRepository {
  BoardCatalogRepository({
    this.overlaysAsset = 'assets/boards/overlays.json',
    this.templatesAsset = 'assets/boards/templates.json',
  });

  final String overlaysAsset;
  final String templatesAsset;

  OverlayCatalog? _overlays;
  BoardTemplateCatalog? _templates;

  Future<OverlayCatalog> loadOverlays() async {
    if (_overlays != null) return _overlays!;
    final raw = await rootBundle.loadString(overlaysAsset);
    _overlays = OverlayCatalog.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    return _overlays!;
  }

  Future<BoardTemplateCatalog> loadTemplates() async {
    if (_templates != null) return _templates!;
    final overlays = await loadOverlays();
    final raw = await rootBundle.loadString(templatesAsset);
    _templates = BoardTemplateCatalog.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
      overlays: overlays,
    );
    return _templates!;
  }
}

final boardCatalogRepositoryProvider = Provider<BoardCatalogRepository>((ref) {
  return BoardCatalogRepository();
});

final overlayCatalogProvider = FutureProvider<OverlayCatalog>((ref) {
  return ref.watch(boardCatalogRepositoryProvider).loadOverlays();
});

final boardTemplateCatalogProvider =
    FutureProvider<BoardTemplateCatalog>((ref) {
  return ref.watch(boardCatalogRepositoryProvider).loadTemplates();
});
