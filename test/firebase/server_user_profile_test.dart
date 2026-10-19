import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/firebase/cloud_functions_client.dart';

void main() {
  group('ServerUserProfile', () {
    test('fromMap reads economy fields', () {
      final profile = ServerUserProfile.fromMap({
        'coins': 1200,
        'gems': 40,
        'lives': 3,
        'completedNodeIds': ['n1', 'n2'],
        'displayName': 'Apoorv',
        'selectedHeroId': 'knight',
        'lastLifeRegenAt': '2026-10-12T10:00:00.000Z',
      });

      expect(profile.coins, 1200);
      expect(profile.gems, 40);
      expect(profile.lives, 3);
      expect(profile.completedNodeIds, {'n1', 'n2'});
      expect(profile.displayName, 'Apoorv');
      expect(profile.selectedHeroId, 'knight');
      expect(profile.lastLifeRegenAt, '2026-10-12T10:00:00.000Z');
    });

    test('bootstrapFromLocal sends clampable payload', () {
      final boot = ServerUserProfile.bootstrapFromLocal(
        coins: 800,
        gems: 20,
        lives: 4,
        completedNodeIds: {'a', 'b'},
        displayName: 'Wanderer',
        selectedHeroId: 'mage',
      );

      expect(boot['coins'], 800);
      expect(boot['completedNodeIds'], ['a', 'b']);
      expect(boot['selectedHeroId'], 'mage');
    });
  });

  group('EnsureUserResult', () {
    test('fromMap with nested profile', () {
      final result = EnsureUserResult.fromMap({
        'created': true,
        'uid': 'uid-1',
        'profile': {
          'coins': 500,
          'gems': 50,
          'lives': 5,
          'completedNodeIds': <String>[],
          'displayName': 'Wanderer',
          'selectedHeroId': 'mage',
        },
      });

      expect(result.created, isTrue);
      expect(result.uid, 'uid-1');
      expect(result.profile?.coins, 500);
    });
  });

  group('SubmitBattleRunResult', () {
    test('fromMap reads grant and authoritative economy', () {
      final result = SubmitBattleRunResult.fromMap({
        'alreadyProcessed': false,
        'grantCoins': 40,
        'completedNode': true,
        'coins': 540,
        'lives': 5,
        'completedNodeIds': ['n1'],
      });

      expect(result.grantCoins, 40);
      expect(result.completedNode, isTrue);
      expect(result.coins, 540);
      expect(result.completedNodeIds, {'n1'});
    });
  });
}
