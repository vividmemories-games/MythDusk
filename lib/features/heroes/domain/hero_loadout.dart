import 'hero_def.dart';

/// Equip exactly [equippedCount] skills from a hero's catalog kit.
abstract final class HeroLoadout {
  static const equippedCount = 2;

  /// Default loadout: first [equippedCount] catalog skills.
  static List<String> defaultEquippedIds(HeroDef hero) {
    return [
      for (final skill in hero.skills.take(equippedCount)) skill.id,
    ];
  }

  /// Recovers invalid / partial / unknown IDs to a valid loadout.
  static List<String> sanitize({
    required HeroDef hero,
    List<String>? raw,
  }) {
    final owned = <String>{for (final skill in hero.skills) skill.id};
    final unique = <String>[];
    final seen = <String>{};
    for (final id in raw ?? const <String>[]) {
      if (!owned.contains(id)) continue;
      if (!seen.add(id)) continue;
      unique.add(id);
      if (unique.length >= equippedCount) {
        return List<String>.unmodifiable(unique);
      }
    }

    for (final id in defaultEquippedIds(hero)) {
      if (unique.length >= equippedCount) break;
      if (seen.add(id)) unique.add(id);
    }
    return List<String>.unmodifiable(unique);
  }

  /// Tap-to-equip: selecting a new skill replaces the oldest equipped slot.
  /// Tapping an already-equipped skill is a no-op (must always keep two).
  static List<String> toggleEquip({
    required HeroDef hero,
    required List<String> current,
    required String skillId,
  }) {
    final owned = hero.skills.any((s) => s.id == skillId);
    if (!owned) return sanitize(hero: hero, raw: current);

    final sanitized = sanitize(hero: hero, raw: current);
    if (sanitized.contains(skillId)) return sanitized;

    final next = [...sanitized, skillId];
    while (next.length > equippedCount) {
      next.removeAt(0);
    }
    return sanitize(hero: hero, raw: next);
  }
}
