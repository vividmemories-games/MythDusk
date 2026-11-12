import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/providers/battle_provider.dart';
import 'package:mythdusk/features/campaign/data/campaign_repository.dart';
import 'package:mythdusk/features/prep/domain/prep_item.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:mythdusk/features/puzzle/data/board_catalog_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('battleProvider applies pending prep without mutating during create',
      () async {
    SharedPreferences.setMockInitialValues({
      'mythdusk_profile_v2': jsonEncode(const PlayerProfile(
        selectedHeroId: 'mage',
        firstBattleTutorialDone: true,
        hintsEnabled: false,
      ).toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await container.read(campaignChapterProvider.future);
    await container.read(overlayCatalogProvider.future);
    await container.read(boardTemplateCatalogProvider.future);

    container.read(pendingBossPrepProvider.notifier).state = [
      PrepItemId.vanguardTonic,
      PrepItemId.aegisFlask,
    ];

    // Must not throw Riverpod's "modify other providers during initialization".
    final battle = container.read(battleProvider('node_07'));
    expect(battle.movesPerTurn,
        greaterThan(battle.hero.movesPerTurn)); // vanguard +1
    expect(battle.shield, PrepBalance.aegisShield);
    expect(container.read(pendingBossPrepProvider),
        [PrepItemId.vanguardTonic, PrepItemId.aegisFlask]);

    await Future<void>.delayed(Duration.zero);
    expect(container.read(pendingBossPrepProvider), isEmpty);
  });
}
