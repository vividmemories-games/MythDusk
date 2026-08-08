import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/prep/domain/prep_item.dart';
import 'package:mythdusk/features/profile/domain/economy_balance.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('EconomyBalance upgrades', () {
    test('multiplier caps at +30% after 6 tiers', () {
      expect(EconomyBalance.multiplierFor(0), 1.0);
      expect(EconomyBalance.multiplierFor(1), 1.05);
      expect(EconomyBalance.multiplierFor(6), 1.30);
      expect(EconomyBalance.multiplierFor(99), 1.30);
    });

    test('HeroDef.withCombatMultipliers scales hp damage shield', () {
      final scaled = HeroCatalog.mage.withCombatMultipliers(
        hpMult: 1.30,
        damageMult: 1.30,
        shieldMult: 1.30,
      );
      expect(scaled.maxHp, (HeroCatalog.mage.maxHp * 1.30).round());
      expect(
        scaled.skills.first.damage,
        (HeroCatalog.mage.skills.first.damage * 1.30).round(),
      );
    });
  });

  group('LifeRegenMath', () {
    test('grants lives after 20-minute intervals and freezes at max', () {
      final start = DateTime(2026, 7, 27, 12, 0);
      final mid = LifeRegenMath.apply(
        lives: 3,
        lastLifeRegenAt: start,
        now: start.add(const Duration(minutes: 45)),
      );
      expect(mid.lives, 5); // 3 + 2 intervals → max
      expect(mid.lastLifeRegenAt, isNull);

      final none = LifeRegenMath.apply(
        lives: 4,
        lastLifeRegenAt: start,
        now: start.add(const Duration(minutes: 19)),
      );
      expect(none.lives, 4);
      expect(none.lastLifeRegenAt, start);
    });
  });

  group('PrepDrops', () {
    test('always grants tonic; act-gated extras with low RNG', () {
      final act1 = PrepDrops.forNonBossClear(
        actIndex: 0,
        random: _FixedRandom(0.0),
      );
      expect(act1[PrepItemId.vanguardTonic], 1);
      expect(act1.containsKey(PrepItemId.aegisFlask), isFalse);

      final act2 = PrepDrops.forNonBossClear(
        actIndex: 1,
        random: _FixedRandom(0.0),
      );
      expect(act2[PrepItemId.aegisFlask], 1);

      final act3 = PrepDrops.forNonBossClear(
        actIndex: 2,
        random: _FixedRandom(0.0),
      );
      expect(act3[PrepItemId.secondWind], 1);
    });
  });

  group('ProfileNotifier economy', () {
    late ProfileNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      notifier = ProfileNotifier(prefs);
    });

    test('applyDefeat spends one life and starts regen timer', () async {
      final now = DateTime(2026, 7, 27, 10, 0);
      expect(notifier.state.lives, EconomyBalance.startingLives);
      await notifier.applyDefeat(now);
      expect(notifier.state.lives, EconomyBalance.startingLives - 1);
      expect(notifier.state.lastLifeRegenAt, now);
    });

    test('tickLifeRegen restores lives after interval', () async {
      final now = DateTime(2026, 7, 27, 10, 0);
      await notifier.applyDefeat(now);
      await notifier.applyDefeat(now);
      expect(notifier.state.lives, 3);
      notifier.tickLifeRegen(now.add(const Duration(minutes: 40)));
      expect(notifier.state.lives, 5);
      expect(notifier.state.lastLifeRegenAt, isNull);
    });

    test('gem life refill respects cost and daily cap', () async {
      SharedPreferences.setMockInitialValues({
        'mythdusk_profile_v2': jsonEncode(
          const PlayerProfile(gems: 400, lives: 1).toJson(),
        ),
      });
      final prefs = await SharedPreferences.getInstance();
      final rich = ProfileNotifier(prefs);
      final now = DateTime(2026, 7, 27, 10, 0);

      expect(rich.purchaseGemLifeRefill(now), isTrue);
      expect(
        rich.state.lives,
        (1 + EconomyBalance.gemLifeRefillAmount)
            .clamp(0, EconomyBalance.maxLives),
      );
      expect(
        rich.state.gems,
        400 - EconomyBalance.gemLifeRefillCost,
      );

      // 1 → 4 → 5; third refill blocked because lives are full.
      expect(rich.purchaseGemLifeRefill(now), isTrue);
      expect(rich.state.lives, EconomyBalance.maxLives);
      expect(rich.purchaseGemLifeRefill(now), isFalse);
      expect(rich.state.gemLifeRefillCount, 2);

      // Daily cap still enforced when lives drop again.
      await rich.applyDefeat(now);
      expect(rich.purchaseGemLifeRefill(now), isTrue);
      expect(rich.purchaseGemLifeRefill(now), isFalse); // daily cap (3 used)
      expect(rich.state.gemLifeRefillCount, 3);
    });

    test('purchaseUpgrade is per-hero and clamps at 6 tiers', () async {
      expect(
        notifier.purchaseUpgrade(EconomyBalance.upgradeStatDamage),
        isTrue,
      );
      expect(
        notifier.state.upgradeLevel(EconomyBalance.upgradeStatDamage, 'mage'),
        1,
      );
      expect(
          notifier.state
              .upgradeLevel(EconomyBalance.upgradeStatDamage, 'knight'),
          0);
      expect(notifier.state.coins, 500 - 100);

      await notifier.applyVictory(nodeId: 'coin_dump', coinReward: 5000);
      for (var i = 0; i < 10; i++) {
        notifier.purchaseUpgrade(EconomyBalance.upgradeStatDamage);
      }
      expect(
        notifier.state.upgradeLevel(EconomyBalance.upgradeStatDamage, 'mage'),
        EconomyBalance.upgradeMaxTiers,
      );
      expect(
        notifier.state.combatHero('mage').skills.first.damage,
        (HeroCatalog.mage.skills.first.damage * 1.30).round(),
      );
      expect(
        notifier.state.combatHero('knight').skills.first.damage,
        HeroCatalog.knight.skills.first.damage,
      );
    });

    test('legacy upgradeLevels migrate onto unlocked heroes only', () {
      final migrated = PlayerProfile.fromJson({
        'completedNodeIds': List.generate(5, (i) => 'n$i'),
        'upgradeLevels': {
          EconomyBalance.upgradeStatHp: 2,
          EconomyBalance.upgradeStatDamage: 3,
          EconomyBalance.upgradeStatShield: 1,
        },
      });
      expect(
          migrated.upgradeLevel(EconomyBalance.upgradeStatDamage, 'mage'), 3);
      expect(
          migrated.upgradeLevel(EconomyBalance.upgradeStatDamage, 'knight'), 3);
      expect(
          migrated.upgradeLevel(EconomyBalance.upgradeStatDamage, 'ranger'), 0);
      expect(migrated.toJson().containsKey('upgradeLevels'), isFalse);
      expect(migrated.toJson()['schemaVersion'], PlayerProfile.schemaVersion);
    });
  });
}

/// Always returns [value] from [nextDouble].
class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final double value;

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => value < 0.5;

  @override
  int nextInt(int max) => 0;
}
