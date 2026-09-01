import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firebase/firebase_bootstrap.dart';
import '../../heroes/domain/hero_def.dart';
import '../../heroes/domain/hero_loadout.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../data/firestore_pvp_repository.dart';
import '../data/memory_pvp_repository.dart';
import '../data/pvp_repository.dart';
import '../domain/pvp_models.dart';

final memoryPvpRepositoryProvider = Provider<MemoryPvpRepository>((ref) {
  return MemoryPvpRepository();
});

final pvpRepositoryProvider = Provider<PvpRepository>((ref) {
  if (FirebaseBootstrap.isReady) {
    return FirestorePvpRepository();
  }
  return ref.watch(memoryPvpRepositoryProvider);
});

PvpLoadout frozenLoadoutFromProfile(PlayerProfile profile) {
  final heroId = profile.selectedHeroId;
  final hero = HeroCatalog.byId(heroId);
  return PvpLoadout(
    heroId: heroId,
    skillIds: HeroLoadout.sanitize(
      hero: hero,
      raw: profile.equippedSkillIdsFor(heroId),
      unlockedExtraSkillIds: profile.unlockedMasterySkillIds,
    ),
  );
}
