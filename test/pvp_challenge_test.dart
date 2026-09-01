import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/pvp/data/memory_pvp_repository.dart';
import 'package:mythdusk/features/pvp/domain/pvp_models.dart';

void main() {
  test('memory challenge accepts only while live and freezes loadouts',
      () async {
    final repo = MemoryPvpRepository(random: null);
    final challenge = await repo.createChallenge(
      challengerUid: 'a',
      loadout: const PvpLoadout(heroId: 'mage', skillIds: ['fireball']),
    );
    expect(challenge.joinCode.length, 6);
    expect(challenge.status, PvpChallengeStatus.open);

    final match = await repo.acceptChallenge(
      joinCode: challenge.joinCode,
      inviteeUid: 'b',
      loadout: const PvpLoadout(heroId: 'knight', skillIds: []),
    );
    expect(match.uidA, 'a');
    expect(match.uidB, 'b');
    expect(match.loadoutA.heroId, 'mage');
    expect(match.loadoutB.heroId, 'knight');
    expect(match.currentUid, 'a');
  });
}
