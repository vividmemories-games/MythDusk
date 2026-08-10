import 'hero_def.dart';

/// Equip exactly [equippedCount] skills from a hero's available kit.
abstract final class HeroLoadout {
  static const equippedCount = 2;

  /// Catalog skills 1–3 are always available; skill 4+ need mastery unlocks.
  static List<SkillDef> availableSkills(
    HeroDef hero,
    Set<String> unlockedExtraSkillIds,
  ) {
    return [
      for (var i = 0; i < hero.skills.length; i++)
        if (i < 3 || unlockedExtraSkillIds.contains(hero.skills[i].id))
          hero.skills[i],
    ];
  }

  /// Default loadout: first [equippedCount] available skills.
  static List<String> defaultEquippedIds(
    HeroDef hero, {
    Set<String> unlockedExtraSkillIds = const {},
  }) {
    final available = availableSkills(hero, unlockedExtraSkillIds);
    return [
      for (final skill in available.take(equippedCount)) skill.id,
    ];
  }

  /// Recovers invalid / partial / unknown IDs to a valid loadout.
  static List<String> sanitize({
    required HeroDef hero,
    List<String>? raw,
    Set<String> unlockedExtraSkillIds = const {},
  }) {
    final owned = <String>{
      for (final skill in availableSkills(hero, unlockedExtraSkillIds))
        skill.id,
    };
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

    for (final id in defaultEquippedIds(
      hero,
      unlockedExtraSkillIds: unlockedExtraSkillIds,
    )) {
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
    Set<String> unlockedExtraSkillIds = const {},
  }) {
    final available = availableSkills(hero, unlockedExtraSkillIds);
    final owned = available.any((s) => s.id == skillId);
    if (!owned) {
      return sanitize(
        hero: hero,
        raw: current,
        unlockedExtraSkillIds: unlockedExtraSkillIds,
      );
    }

    final sanitized = sanitize(
      hero: hero,
      raw: current,
      unlockedExtraSkillIds: unlockedExtraSkillIds,
    );
    if (sanitized.contains(skillId)) return sanitized;

    final next = [...sanitized, skillId];
    while (next.length > equippedCount) {
      next.removeAt(0);
    }
    return sanitize(
      hero: hero,
      raw: next,
      unlockedExtraSkillIds: unlockedExtraSkillIds,
    );
  }
}
