import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/core/analytics/gameplay_analytics.dart';
import 'package:mythdusk/features/expedition/domain/expedition_models.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/heroes/domain/hero_loadout.dart';
import 'package:mythdusk/features/mastery/domain/mastery_catalog.dart';

void main() {
  group('RelicCatalog', () {
    test('offerThree returns up to 3 unique relics', () {
      final offers = RelicCatalog.offerThree(seed: 42, ownedIds: {});
      expect(offers.length, 3);
      expect(offers.map((r) => r.id).toSet().length, 3);
    });

    test('offerThree skips owned relics', () {
      final owned = {RelicCatalog.all.first.id};
      final offers = RelicCatalog.offerThree(seed: 7, ownedIds: owned);
      expect(offers.every((r) => !owned.contains(r.id)), isTrue);
    });
  });

  group('RelicRuntime', () {
    test('first blue match grants AP when relic owned', () {
      final ap = RelicRuntime.bonusApFromMatch(
        relicIds: const ['relic_first_blue_ap'],
        resourceGains: const {'mana': 3},
        firstBlueThisTurn: true,
      );
      expect(ap, 1);
      final again = RelicRuntime.bonusApFromMatch(
        relicIds: const ['relic_first_blue_ap'],
        resourceGains: const {'mana': 3},
        firstBlueThisTurn: false,
      );
      expect(again, 0);
    });

    test('low HP skill power only below 50%', () {
      expect(
        RelicRuntime.skillDamageMult(
          relicIds: const ['relic_bloodied_power'],
          heroHp: 20,
          heroMaxHp: 80,
        ),
        1.25,
      );
      expect(
        RelicRuntime.skillDamageMult(
          relicIds: const ['relic_bloodied_power'],
          heroHp: 50,
          heroMaxHp: 80,
        ),
        1,
      );
    });

    test('overlay break grants mana', () {
      expect(
        RelicRuntime.bonusManaFromOverlays(
          relicIds: const ['relic_overlay_mana'],
          overlaysBroken: 2,
        ),
        4,
      );
    });
  });

  group('ExpeditionRunState', () {
    test('start → win rooms → boss flag', () {
      var run = ExpeditionRunState.start(heroId: 'mage', seed: 1);
      expect(run.phase, ExpeditionPhase.hub);
      expect(run.isInProgress, isTrue);
      expect(run.isBossFight, isFalse);
      run = run.copyWith(battleIndex: 3);
      expect(run.isBossFight, isTrue);
    });

    test('json round-trip', () {
      final run = ExpeditionRunState.start(heroId: 'knight', seed: 99)
          .copyWith(relicIds: const ['relic_first_blue_ap']);
      final again = ExpeditionRunState.fromJson(run.toJson());
      expect(again.heroId, 'knight');
      expect(again.relicIds, ['relic_first_blue_ap']);
      expect(again.seed, 99);
    });

    test('settled and failed runs are not in progress', () {
      final settled = ExpeditionRunState.start(heroId: 'mage', seed: 1)
          .copyWith(phase: ExpeditionPhase.settled);
      final failed = ExpeditionRunState.start(heroId: 'mage', seed: 2)
          .copyWith(phase: ExpeditionPhase.failed);
      expect(settled.isInProgress, isFalse);
      expect(failed.isInProgress, isFalse);
    });
  });

  group('Mastery + skill 4 gate', () {
    test('each hero has 4 catalog skills', () {
      for (final hero in HeroCatalog.all) {
        expect(hero.skills.length, 4, reason: hero.id);
      }
    });

    test('skill 4 hidden until unlocked', () {
      final mage = HeroCatalog.mage;
      final locked = HeroLoadout.availableSkills(mage, {});
      expect(locked.length, 3);
      expect(locked.any((s) => s.id == 'meteor_shard'), isFalse);

      final unlocked = HeroLoadout.availableSkills(mage, {'meteor_shard'});
      expect(unlocked.length, 4);
      expect(unlocked.last.id, 'meteor_shard');
    });

    test('mastery claim condition math', () {
      final def = MasteryCatalog.forHero('mage').first;
      expect(def.condition, MasteryConditionType.winsWithHero);
      final counters = const HeroMasteryCounters(wins: 3);
      expect(counters.valueFor(def.condition) >= def.target, isTrue);
    });
  });

  group('GameplayAnalytics', () {
    test('debug sink captures events', () {
      final lines = <String>[];
      final analytics = DebugGameplayAnalytics(sink: lines.add);
      analytics.log(GameplayAnalyticsEvents.sessionStart, {'v': 1});
      expect(lines.single, contains('session_start'));
      expect(lines.single, contains('{v: 1}'));
    });

    test('noop is silent', () {
      const NoopGameplayAnalytics().log('anything');
    });
  });
}
