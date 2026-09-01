import '../../battle/domain/enemy_def.dart';
import '../../heroes/domain/hero_def.dart';

/// Maps a frozen PvP loadout onto the existing enemy slot so both players
/// fight through the same [BattleController] / battle screen.
abstract final class HeroAsEnemy {
  static EnemyDef fromHero(HeroDef hero) {
    final skills = <EnemySkill>[
      for (final skill in hero.skills)
        EnemySkill(
          id: skill.id,
          name: skill.name,
          damage: skill.damage > 0 ? skill.damage : 1,
          weight: 1,
        ),
    ];
    return EnemyDef(
      id: 'pvp_${hero.id}',
      name: hero.name,
      maxHp: hero.maxHp,
      blurb: 'Live 1v1 — hero vs hero',
      skills: skills,
    );
  }
}
