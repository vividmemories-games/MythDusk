import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/prep/domain/prep_item.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PrepDrops.forVictory', () {
    test('node prepDrops are authoritative when non-empty', () {
      final drops = PrepDrops.forVictory(
        isBoss: false,
        actIndex: 0,
        nodePrepDrops: const ['prep_vanguard_tonic', 'prep_aegis_flask'],
      );
      expect(drops[PrepItemId.vanguardTonic], 1);
      expect(drops[PrepItemId.aegisFlask], 1);
      expect(drops.containsKey(PrepItemId.secondWind), isFalse);
    });

    test('empty node prepDrops falls back to act table', () {
      final drops = PrepDrops.forVictory(
        isBoss: false,
        actIndex: 0,
        nodePrepDrops: const [],
        random: Random(1),
      );
      expect(drops[PrepItemId.vanguardTonic], 1);
    });

    test('boss clears grant no prep', () {
      final drops = PrepDrops.forVictory(
        isBoss: true,
        nodePrepDrops: const ['prep_vanguard_tonic'],
      );
      expect(drops, isEmpty);
    });

    test('tryParseDrop accepts prep_ prefix and bare keys', () {
      expect(
        PrepItemIdX.tryParseDrop('prep_vanguard_tonic'),
        PrepItemId.vanguardTonic,
      );
      expect(PrepItemIdX.tryParseDrop('aegis_flask'), PrepItemId.aegisFlask);
      expect(PrepItemIdX.tryParseDrop('unknown_item'), isNull);
    });
  });

  group('ProfileNotifier.applyVictory prepDrops', () {
    test('applies node prepDrops instead of default tonic only', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ProfileNotifier(prefs);
      final before = notifier.state.prepCount(PrepItemId.aegisFlask);

      await notifier.applyVictory(
        nodeId: 'ch_howling_n03',
        coinReward: 10,
        nodePrepDrops: const ['prep_aegis_flask'],
      );

      expect(
        notifier.state.prepCount(PrepItemId.aegisFlask),
        before + 1,
      );
      // Node list did not include vanguard — should not auto-grant it.
      expect(
        notifier.state.prepCount(PrepItemId.vanguardTonic),
        notifier.state.prepInventory[PrepItemId.vanguardTonic],
      );
    });
  });
}
