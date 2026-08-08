import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/battle_state.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/heroes/domain/hero_loadout.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('HeroLoadout', () {
    test('defaults to first two catalog skills', () {
      expect(
        HeroLoadout.defaultEquippedIds(HeroCatalog.mage),
        ['fireball', 'arcane_bolt'],
      );
      expect(HeroCatalog.mage.skills, hasLength(3));
    });

    test('sanitize recovers unknown and partial ids', () {
      expect(
        HeroLoadout.sanitize(
          hero: HeroCatalog.mage,
          raw: ['missing', 'frost_ward'],
        ),
        ['frost_ward', 'fireball'],
      );
      expect(
        HeroLoadout.sanitize(
          hero: HeroCatalog.mage,
          raw: ['frost_ward', 'frost_ward', 'arcane_bolt', 'fireball'],
        ),
        ['frost_ward', 'arcane_bolt'],
      );
      expect(
        HeroLoadout.sanitize(hero: HeroCatalog.knight, raw: null),
        ['basic_slash', 'shield_wall'],
      );
    });

    test('toggleEquip swaps oldest when already full', () {
      final next = HeroLoadout.toggleEquip(
        hero: HeroCatalog.mage,
        current: ['fireball', 'arcane_bolt'],
        skillId: 'frost_ward',
      );
      expect(next, ['arcane_bolt', 'frost_ward']);
      expect(
        HeroLoadout.toggleEquip(
          hero: HeroCatalog.mage,
          current: next,
          skillId: 'arcane_bolt',
        ),
        next,
      );
    });
  });

  group('PlayerProfile loadouts', () {
    test('combatHero exposes only equipped skills', () {
      final profile = PlayerProfile(
        equippedSkillIdsByHero: {
          'mage': ['frost_ward', 'arcane_bolt'],
        },
      );
      final combat = profile.combatHero('mage');
      expect(combat.skills.map((s) => s.id), ['frost_ward', 'arcane_bolt']);
      expect(profile.scaledHero('mage').skills, hasLength(3));
    });

    test('fromJson sanitizes bad loadouts and persists', () {
      final migrated = PlayerProfile.fromJson({
        'equippedSkillIdsByHero': {
          'mage': ['gone', 'frost_ward'],
          'unknown_hero': ['x'],
        },
      });
      expect(migrated.equippedSkillIdsFor('mage'), ['frost_ward', 'fireball']);
      expect(
        migrated.equippedSkillIdsByHero.containsKey('unknown_hero'),
        isFalse,
      );

      final roundTrip = PlayerProfile.fromJson(migrated.toJson());
      expect(roundTrip.toJson()['schemaVersion'], PlayerProfile.schemaVersion);
      expect(
        roundTrip.equippedSkillIdsFor('mage'),
        ['frost_ward', 'fireball'],
      );
    });

    testWidgets('toggleEquippedSkill persists swap', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ProfileNotifier(prefs);
      expect(
        notifier.state.equippedSkillIdsFor('mage'),
        ['fireball', 'arcane_bolt'],
      );
      notifier.toggleEquippedSkill('mage', 'frost_ward');
      expect(
        notifier.state.equippedSkillIdsFor('mage'),
        ['arcane_bolt', 'frost_ward'],
      );
    });
  });

  group('BattleController loadout guard', () {
    test('rejects casting skills not in the equipped hero kit', () {
      final hero = HeroCatalog.mage.withEquippedSkillIds(
        ['fireball', 'arcane_bolt'],
      );
      final frostWard = HeroCatalog.mage.skills.firstWhere(
        (s) => s.id == 'frost_ward',
      );
      final c = BattleController(
        BattleState.initial(hero: hero).copyWith(
          ap: 10,
          resources: const {
            'attack': 99,
            'mana': 99,
            'healing': 99,
            'shield': 99,
            'ultimate': 99,
          },
        ),
      );
      expect(c.canCast(frostWard), isFalse);
      c.castSkill(frostWard);
      expect(c.state.shield, 0);
      expect(c.canCast(hero.skills.first), isTrue);
    });
  });
}
