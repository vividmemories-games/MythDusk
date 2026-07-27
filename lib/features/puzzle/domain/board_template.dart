import 'overlay_def.dart';

/// One cell instruction from a board template grid.
class TemplateCellSpec {
  const TemplateCellSpec({
    this.masked = false,
    this.overlayId,
    this.layers = 0,
  });

  final bool masked;
  final String? overlayId;
  final int layers;

  bool get isOpen => !masked && overlayId == null;
}

/// Reusable board geometry: size + ASCII grid + legend.
class BoardTemplate {
  const BoardTemplate({
    required this.id,
    required this.width,
    required this.height,
    required this.cells,
    this.schemaVersion = 1,
    this.contentVersion = 1,
    this.isEnabled = true,
  });

  final String id;
  final int width;
  final int height;

  /// Row-major, length == width * height.
  final List<TemplateCellSpec> cells;
  final int schemaVersion;
  final int contentVersion;
  final bool isEnabled;

  TemplateCellSpec at(int row, int col) => cells[row * width + col];

  factory BoardTemplate.fromJson(
    Map<String, dynamic> json, {
    OverlayCatalog? overlays,
  }) {
    final width = json['width'] as int;
    final height = json['height'] as int;
    final legendRaw = json['legend'];
    final legendMap = legendRaw is Map
        ? Map<String, dynamic>.from(legendRaw)
        : <String, dynamic>{};
    final legend = <String, TemplateCellSpec>{
      '.': const TemplateCellSpec(),
    };
    for (final entry in legendMap.entries) {
      legend[entry.key] = _parseLegendValue(entry.value, overlays: overlays);
    }

    final grid = (json['grid'] as List<dynamic>).cast<String>();
    if (grid.length != height) {
      throw FormatException(
        'BoardTemplate ${json['id']}: grid has ${grid.length} rows, '
        'expected $height',
      );
    }

    final cells = <TemplateCellSpec>[];
    for (var row = 0; row < height; row++) {
      final line = grid[row];
      if (line.length != width) {
        throw FormatException(
          'BoardTemplate ${json['id']}: row $row length ${line.length}, '
          'expected $width',
        );
      }
      for (var col = 0; col < width; col++) {
        final ch = line[col];
        final spec = legend[ch];
        if (spec == null) {
          throw FormatException(
            'BoardTemplate ${json['id']}: unknown legend char "$ch" '
            'at ($row,$col)',
          );
        }
        cells.add(spec);
      }
    }

    return BoardTemplate(
      id: json['id'] as String,
      width: width,
      height: height,
      cells: List.unmodifiable(cells),
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      contentVersion: json['contentVersion'] as int? ?? 1,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  static TemplateCellSpec _parseLegendValue(
    Object? value, {
    OverlayCatalog? overlays,
  }) {
    if (value is String) {
      if (value == 'masked' || value == 'hole') {
        return const TemplateCellSpec(masked: true);
      }
      throw FormatException('Unknown legend string: $value');
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      if (map['masked'] == true) {
        return const TemplateCellSpec(masked: true);
      }
      final overlayId = map['overlay'] as String?;
      if (overlayId == null) {
        throw FormatException('Legend object needs overlay or masked: $map');
      }
      var layers = map['layers'] as int? ?? 1;
      if (overlays != null) {
        final def = overlays.require(overlayId);
        if (layers < 1) layers = 1;
        if (layers > def.maxLayers) layers = def.maxLayers;
      } else if (layers < 1) {
        layers = 1;
      }
      return TemplateCellSpec(overlayId: overlayId, layers: layers);
    }
    throw FormatException('Invalid legend value: $value');
  }
}

/// Catalog of board templates keyed by id.
class BoardTemplateCatalog {
  BoardTemplateCatalog(List<BoardTemplate> templates)
      : _byId = {for (final t in templates) t.id: t};

  final Map<String, BoardTemplate> _byId;

  BoardTemplate? operator [](String id) => _byId[id];

  BoardTemplate require(String id) {
    final t = _byId[id];
    if (t == null) {
      throw StateError('Unknown board template id: $id');
    }
    return t;
  }

  Iterable<BoardTemplate> get all => _byId.values;

  factory BoardTemplateCatalog.fromJson(
    Map<String, dynamic> json, {
    OverlayCatalog? overlays,
  }) {
    final raw = json['templates'] as List<dynamic>? ?? const [];
    return BoardTemplateCatalog([
      for (final e in raw)
        BoardTemplate.fromJson(e as Map<String, dynamic>, overlays: overlays),
    ]);
  }
}
