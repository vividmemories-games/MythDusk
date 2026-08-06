import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../profile/providers/mock_profile_provider.dart';

/// QA: drag level pins onto painted pads; survives app restarts.
class PinCoord {
  const PinCoord({required this.x, required this.y});

  final double x;
  final double y;

  Map<String, dynamic> toJson() => {
        'mapX': double.parse(x.toStringAsFixed(3)),
        'mapY': double.parse(y.toStringAsFixed(3)),
      };

  factory PinCoord.fromJson(Map<String, dynamic> json) => PinCoord(
        x: (json['mapX'] as num).toDouble(),
        y: (json['mapY'] as num).toDouble(),
      );
}

class PinCoordOverridesNotifier extends StateNotifier<Map<String, PinCoord>> {
  PinCoordOverridesNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'mythdusk_pin_coord_overrides_v1';

  static Map<String, PinCoord> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final pins = decoded['pins'] as Map<String, dynamic>? ?? decoded;
      return {
        for (final e in pins.entries)
          if (e.value is Map<String, dynamic>)
            e.key: PinCoord.fromJson(e.value as Map<String, dynamic>),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _persist() async {
    final payload = {
      'schemaVersion': 1,
      'pins': {
        for (final e in state.entries) e.key: e.value.toJson(),
      },
    };
    await _prefs.setString(_key, jsonEncode(payload));
  }

  Future<void> setPin(String nodeId, double x, double y) async {
    state = {
      ...state,
      nodeId: PinCoord(
        x: x.clamp(0.05, 0.95),
        y: y.clamp(0.05, 0.95),
      ),
    };
    await _persist();
  }

  Future<void> clearAll() async {
    state = {};
    await _prefs.remove(_key);
  }

  Future<void> clearNodeIds(Iterable<String> ids) async {
    final next = Map<String, PinCoord>.from(state)
      ..removeWhere((k, _) => ids.contains(k));
    state = next;
    await _persist();
  }

  /// Full export payload for `scripts/apply_pin_overrides.py`.
  String exportJson({Set<String>? onlyNodeIds}) {
    final pins = <String, Map<String, dynamic>>{};
    for (final e in state.entries) {
      if (onlyNodeIds != null && !onlyNodeIds.contains(e.key)) continue;
      pins[e.key] = e.value.toJson();
    }
    return const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'pins': pins,
    });
  }
}

final pinEditModeProvider = StateProvider<bool>((ref) => false);

final pinCoordOverridesProvider =
    StateNotifierProvider<PinCoordOverridesNotifier, Map<String, PinCoord>>(
        (ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PinCoordOverridesNotifier(prefs);
});
