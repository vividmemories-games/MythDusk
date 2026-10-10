/// Decorative artwork is keyed by stable skill ID, independently of loadout order.
class SkillArtwork {
  const SkillArtwork(this.assetPath, this.column, this.row);
  final String assetPath;
  final int column;
  final int row;

  static const _mage = 'assets/images/skills/mage.webp';
  static const _knight = 'assets/images/skills/knight.webp';
  static const _ranger = 'assets/images/skills/ranger.webp';
  static const _priest = 'assets/images/skills/priest.webp';
  static const _ninja = 'assets/images/skills/ninja.webp';

  /// Each atlas has four independent icons in a two-by-two grid.
  static const bySkillId = <String, SkillArtwork>{
    'fireball': SkillArtwork(_mage, 0, 0),
    'arcane_bolt': SkillArtwork(_mage, 1, 0),
    'frost_ward': SkillArtwork(_mage, 0, 1),
    'meteor_shard': SkillArtwork(_mage, 1, 1),
    'basic_slash': SkillArtwork(_knight, 0, 0),
    'shield_wall': SkillArtwork(_knight, 1, 0),
    'rallying_cry': SkillArtwork(_knight, 0, 1),
    'bulwark_slam': SkillArtwork(_knight, 1, 1),
    'arrow_shot': SkillArtwork(_ranger, 0, 0),
    'marked_shot': SkillArtwork(_ranger, 1, 0),
    'natures_salve': SkillArtwork(_ranger, 0, 1),
    'volley_rain': SkillArtwork(_ranger, 1, 1),
    'smite': SkillArtwork(_priest, 0, 0),
    'mend': SkillArtwork(_priest, 1, 0),
    'holy_barrier': SkillArtwork(_priest, 0, 1),
    'sanctuary': SkillArtwork(_priest, 1, 1),
    'dagger_flurry': SkillArtwork(_ninja, 0, 0),
    'shadow_strike': SkillArtwork(_ninja, 1, 0),
    'smoke_bomb': SkillArtwork(_ninja, 0, 1),
    'shadow_bind': SkillArtwork(_ninja, 1, 1),
  };

  static SkillArtwork? forSkill(String skillId) => bySkillId[skillId];
}
