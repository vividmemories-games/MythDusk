import '../../features/puzzle/domain/board_cell.dart';
import '../../features/puzzle/domain/tile_color.dart';

/// Central asset paths for presentation wiring.
abstract final class GameAssets {
  static const homeBackground =
      'assets/images/backgrounds/bg_home_mythspire_night.webp';
  static const homeBackgroundFallback =
      'assets/images/backgrounds/bg_home_dusk.webp';
  static const battleTwilightRoad =
      'assets/images/backgrounds/battle/bg_battle_twilight_road.webp';

  static const mapTwilightAct1 =
      'assets/images/maps/map_ch_twilight_road_a1.webp';
  static const mapTwilightAct2 =
      'assets/images/maps/map_ch_twilight_road_a2.webp';
  static const mapTwilightAct3 =
      'assets/images/maps/map_ch_twilight_road_a3.webp';
  static const mapTwilightAct4 =
      'assets/images/maps/map_ch_twilight_road_a4.webp';

  /// Prefer [CampaignAct.mapAsset]; these are the Ch1 defaults.
  static String mapTwilightAct(int actIndex1Based) => switch (actIndex1Based) {
        1 => mapTwilightAct1,
        2 => mapTwilightAct2,
        3 => mapTwilightAct3,
        _ => mapTwilightAct4,
      };

  static const fxMatchClear = 'assets/images/vfx/fx_match_clear.png';
  static const fxSpecialCreate = 'assets/images/vfx/fx_special_create.png';
  static const fxHit = 'assets/images/vfx/fx_hit.png';
  static const fxBossFlee = 'assets/images/vfx/fx_boss_flee.png';

  static const prepVanguard = 'assets/images/prep/prep_vanguard_tonic.png';
  static const prepAegis = 'assets/images/prep/prep_aegis_flask.png';
  static const prepSecondWind = 'assets/images/prep/prep_second_wind.png';

  static const prepIcons = [prepVanguard, prepAegis, prepSecondWind];

  static const iconMoves = 'assets/images/icons/icon_moves.png';
  static const iconAp = 'assets/images/icons/icon_ap.png';

  /// Resource HUD reuses board gem art so colors stay consistent.
  static String resourceIcon(String resourceId) => switch (resourceId) {
        'attack' => tile(TileColor.red),
        'mana' => tile(TileColor.blue),
        'healing' => tile(TileColor.green),
        'shield' => tile(TileColor.yellow),
        'ultimate' => tile(TileColor.purple),
        _ => tile(TileColor.red),
      };

  static String hero(String heroId) => 'assets/heroes/hero_$heroId.webp';

  static String tile(TileColor color) => switch (color) {
        TileColor.red => 'assets/images/tiles/tile_red.png',
        TileColor.blue => 'assets/images/tiles/tile_blue.png',
        TileColor.green => 'assets/images/tiles/tile_green.png',
        TileColor.yellow => 'assets/images/tiles/tile_yellow.png',
        TileColor.purple => 'assets/images/tiles/tile_purple.png',
      };

  static String? powerup(TileSpecial special) => switch (special) {
        TileSpecial.rocketVertical =>
          'assets/images/powerups/powerup_rocket_v.png',
        TileSpecial.rocketHorizontal =>
          'assets/images/powerups/powerup_rocket_h.png',
        TileSpecial.bomb => 'assets/images/powerups/powerup_bomb.png',
        TileSpecial.fireball => 'assets/images/powerups/powerup_fireball.png',
        TileSpecial.seeker => 'assets/images/powerups/powerup_seeker.png',
        TileSpecial.none => null,
      };

  /// Resolves enemy / boss sprite path.
  static String enemy(String enemyId, {int? bossForm}) {
    final form = (bossForm ?? 4).clamp(1, 4);
    return switch (enemyId) {
      'warchief' => 'assets/enemies/bosses/boss_warchief_ruk_f$form.webp',
      'mirelord' => 'assets/enemies/bosses/boss_mirelord_f$form.webp',
      'pack_alpha' => 'assets/enemies/bosses/boss_pack_alpha_f$form.webp',
      'quarry_overseer' =>
        'assets/enemies/bosses/boss_quarry_overseer_f$form.webp',
      'bone_seer' => 'assets/enemies/bosses/boss_bone_seer_f$form.webp',
      'lake_wraith' => 'assets/enemies/bosses/boss_lake_wraith_f$form.webp',
      'gilded_fence' => 'assets/enemies/bosses/boss_gilded_fence_f$form.webp',
      'siege_captain' => 'assets/enemies/bosses/boss_siege_captain_f$form.webp',
      'ember_smith' => 'assets/enemies/bosses/boss_ember_smith_f$form.webp',
      'mythspire_tyrant' =>
        'assets/enemies/bosses/boss_mythspire_tyrant_f$form.webp',
      'weekly_boss_01' => 'assets/enemies/bosses/boss_warchief_ruk_f$form.webp',
      'weekly_boss_02' => 'assets/enemies/bosses/boss_mirelord_f$form.webp',
      'weekly_boss_03' => 'assets/enemies/bosses/boss_pack_alpha_f$form.webp',
      'weekly_boss_04' => 'assets/enemies/bosses/boss_gilded_fence_f$form.webp',
      'weekly_boss_05' =>
        'assets/enemies/bosses/boss_mythspire_tyrant_f$form.webp',
      'weekly_scout' => 'assets/enemies/enemy_goblin.webp',
      'shaman' => 'assets/enemies/enemy_shaman.webp',
      'mire_spawn' => 'assets/enemies/enemy_mire_spawn.webp',
      'leech_wisp' => 'assets/enemies/enemy_mire_spawn.webp',
      'hexer' => 'assets/enemies/enemy_shaman.webp',
      'ridge_hawk' => 'assets/enemies/enemy_ridge_hawk.webp',
      'brute' => 'assets/enemies/enemy_brute.webp',
      'crypt_skel' => 'assets/enemies/enemy_crypt_skel.webp',
      'forge_imp' => 'assets/enemies/enemy_forge_imp.webp',
      _ => 'assets/enemies/enemy_$enemyId.webp',
    };
  }

  static String battleBackground(String? backgroundId) {
    return switch (backgroundId) {
      'bg_battle_mistfen_marshes' ||
      'mistfen_marshes' =>
        'assets/images/backgrounds/battle/bg_battle_mistfen_marshes.webp',
      'bg_battle_howling_ridge' ||
      'howling_ridge' =>
        'assets/images/backgrounds/battle/bg_battle_howling_ridge.webp',
      'bg_battle_ashen_quarries' ||
      'ashen_quarries' =>
        'assets/images/backgrounds/battle/bg_battle_ashen_quarries.webp',
      'bg_battle_candlecrypt' ||
      'candlecrypt' =>
        'assets/images/backgrounds/battle/bg_battle_candlecrypt.webp',
      'bg_battle_mirror_lake' ||
      'mirror_lake' =>
        'assets/images/backgrounds/battle/bg_battle_mirror_lake.webp',
      'bg_battle_thornmarket' ||
      'thornmarket' =>
        'assets/images/backgrounds/battle/bg_battle_thornmarket.webp',
      'bg_battle_skybridge_siege' ||
      'skybridge_siege' =>
        'assets/images/backgrounds/battle/bg_battle_skybridge_siege.webp',
      'bg_battle_eclipse_forge' ||
      'eclipse_forge' =>
        'assets/images/backgrounds/battle/bg_battle_eclipse_forge.webp',
      'bg_battle_mythspire_gate' ||
      'mythspire_gate' =>
        'assets/images/backgrounds/battle/bg_battle_mythspire_gate.webp',
      'bg_battle_twilight_road' ||
      'twilight_road' ||
      null =>
        battleTwilightRoad,
      _ => 'assets/images/backgrounds/battle/bg_battle_$backgroundId.webp',
    };
  }
}
