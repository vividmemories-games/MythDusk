import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_providers.dart';
import '../../../core/analytics/gameplay_analytics.dart';
import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cosmetic_hero_art.dart';
import '../../cosmetics/domain/cosmetic_catalog.dart';
import '../../home/presentation/home_hub_widgets.dart';
import '../../mastery/domain/mastery_catalog.dart';
import '../../profile/domain/economy_balance.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../domain/hero_def.dart';
import '../domain/hero_unlocks.dart';

/// One-hero detail page: swipe / chevrons, skills, and combat upgrades.
class HeroesScreen extends ConsumerStatefulWidget {
  const HeroesScreen({super.key});

  @override
  ConsumerState<HeroesScreen> createState() => _HeroesScreenState();
}

class _HeroesScreenState extends ConsumerState<HeroesScreen> {
  late final PageController _pageController;
  late int _index;

  List<HeroDef> get _heroes => HeroCatalog.all;

  @override
  void initState() {
    super.initState();
    final selectedId = ref.read(profileProvider).selectedHeroId;
    final start = _heroes.indexWhere((h) => h.id == selectedId);
    _index = start < 0 ? 0 : start;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int next) {
    final clamped = next.clamp(0, _heroes.length - 1);
    if (clamped == _index) return;
    _pageController.animateToPage(
      clamped,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    final hero = _heroes[i];
    final clears = ref.read(profileProvider).completedNodeIds.length;
    if (HeroUnlocks.isUnlocked(hero.id, clears)) {
      ref.read(profileProvider.notifier).selectHero(hero.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final clears = profile.completedNodeIds.length;
    final hero = _heroes[_index];
    final viewed = profile.combatHero(hero.id);
    final unlocked = HeroUnlocks.isUnlocked(hero.id, clears);
    final isSelected = profile.selectedHeroId == hero.id;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      appBar: AppBar(
        title: const Text('Heroes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: HubResourceChip(
                label: '${profile.coins}',
                icon: Icons.monetization_on,
                iconColor: MythDuskColors.amber,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _heroes.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) {
                final h = _heroes[i];
                final pageUnlocked = HeroUnlocks.isUnlocked(h.id, clears);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: CosmeticHeroArt(
                    heroId: h.id,
                    assetPath: GameAssets.hero(h.id),
                    profile: profile,
                    locked: !pageUnlocked,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 96,
                      color: MythDuskColors.muted,
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                icon: const Icon(
                  Icons.chevron_left,
                  color: HubColors.frameGold,
                  size: 32,
                ),
              ),
              Flexible(
                child: Text(
                  viewed.name,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium,
                ),
              ),
              IconButton(
                onPressed: _index < _heroes.length - 1
                    ? () => _goTo(_index + 1)
                    : null,
                icon: const Icon(
                  Icons.chevron_right,
                  color: HubColors.frameGold,
                  size: 32,
                ),
              ),
            ],
          ),
          Text(
            '${viewed.movesPerTurn} moves · ${viewed.maxHp} HP · '
            '${viewed.maxAp} AP',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            unlocked
                ? (isSelected ? 'Selected for battle' : 'Unlocked')
                : HeroUnlocks.lockBlurb(hero.id, clears),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: unlocked ? HubColors.glow : MythDuskColors.muted,
            ),
          ),
          if (unlocked && !isSelected) ...[
            const SizedBox(height: 10),
            Center(
              child: FilledButton(
                onPressed: () =>
                    ref.read(profileProvider.notifier).selectHero(hero.id),
                child: const Text('Select'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Cosmetics', style: textTheme.titleMedium),
          Text(
            unlocked
                ? 'Overlays and titles are visual only — they do not change combat.'
                : 'Unlock this hero to equip cosmetics.',
            style: textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          _CosmeticsPanel(heroId: hero.id, canEdit: unlocked),
          const SizedBox(height: 20),
          Text('Skills', style: textTheme.titleMedium),
          Text(
            unlocked
                ? 'Equip exactly two for battle. Tap an unequipped skill to swap it in.'
                : 'Unlock this hero to edit their loadout.',
            style: textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final catalog = HeroCatalog.byId(hero.id);
              final scaled = profile.scaledHero(hero.id);
              final scaledById = {for (final s in scaled.skills) s.id: s};
              final equipped = profile.equippedSkillIdsFor(hero.id);
              return Column(
                children: [
                  for (var i = 0; i < catalog.skills.length; i++) ...[
                    Builder(
                      builder: (context) {
                        final skill = catalog.skills[i];
                        final locked = i >= 3 &&
                            !profile.unlockedMasterySkillIds.contains(skill.id);
                        final display = scaledById[skill.id] ?? skill;
                        return _SkillCard(
                          skill: display,
                          equipped: equipped.contains(skill.id),
                          canEdit: unlocked && !locked,
                          locked: locked,
                          onToggle: unlocked && !locked
                              ? () => ref
                                  .read(profileProvider.notifier)
                                  .toggleEquippedSkill(hero.id, skill.id)
                              : null,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text('Mastery', style: textTheme.titleMedium),
          Text(
            unlocked
                ? 'Long-term challenges unlock skill 4 and cosmetics.'
                : 'Unlock this hero to train mastery.',
            style: textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          for (final def in MasteryCatalog.forHero(hero.id)) ...[
            _MasteryRow(def: def, heroId: hero.id, canEdit: unlocked),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          Text('Personality', style: textTheme.titleMedium),
          Text(
            unlocked
                ? 'Train ${viewed.name} only — upgrades do not transfer between heroes.'
                : 'Unlock this hero to train their personality stats.',
            style: textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          for (final stat in EconomyBalance.upgradeStatKeys) ...[
            _UpgradeRow(stat: stat, heroId: hero.id, canEdit: unlocked),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.skill,
    required this.equipped,
    required this.canEdit,
    this.locked = false,
    this.onToggle,
  });

  final SkillDef skill;
  final bool equipped;
  final bool canEdit;
  final bool locked;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final costs = [
      if (skill.apCost > 0) '${skill.apCost} AP',
      for (final e in skill.resourceCosts.entries) '${e.value} ${e.key}',
    ].join(' · ');
    final effects = [
      if (skill.damage > 0) '${skill.damage} dmg',
      if (skill.heal > 0) '+${skill.heal} HP',
      if (skill.shield > 0) '+${skill.shield} shield',
    ].join(' · ');

    return Material(
      color: HubColors.panel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: locked ? null : onToggle,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: locked
                  ? MythDuskColors.muted
                  : equipped
                      ? HubColors.glow
                      : HubColors.frameGold.withValues(alpha: 0.4),
              width: equipped ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: locked
                            ? MythDuskColors.muted
                            : MythDuskColors.parchment,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locked ? 'Locked — claim Mastery tier 2' : costs,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: MythDuskColors.softGold,
                          ),
                    ),
                    if (!locked && effects.isNotEmpty)
                      Text(
                        effects,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                      ),
                  ],
                ),
              ),
              if (locked)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 2),
                  child: Icon(Icons.lock_outline,
                      size: 18, color: MythDuskColors.muted),
                )
              else if (canEdit)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    equipped ? 'Equipped' : 'Tap to equip',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: equipped ? HubColors.glow : MythDuskColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CosmeticsPanel extends ConsumerWidget {
  const _CosmeticsPanel({required this.heroId, required this.canEdit});

  final String heroId;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final overlays = CosmeticCatalog.claimedFor(
      claimedIds: profile.claimedCosmeticIds,
      slot: CosmeticSlot.overlay,
      heroId: heroId,
    );
    final titles = CosmeticCatalog.claimedFor(
      claimedIds: profile.claimedCosmeticIds,
      slot: CosmeticSlot.title,
      heroId: heroId,
    );
    final frames = CosmeticCatalog.claimedFor(
      claimedIds: profile.claimedCosmeticIds,
      slot: CosmeticSlot.frame,
      heroId: heroId,
    );

    if (overlays.isEmpty && titles.isEmpty && frames.isEmpty) {
      return Text(
        'No cosmetics claimed yet. Mastery and the starter pack grant them.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
      );
    }

    return Column(
      children: [
        for (final c in [...overlays, ...titles, ...frames]) ...[
          _CosmeticRow(def: c, heroId: heroId, canEdit: canEdit),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CosmeticRow extends ConsumerWidget {
  const _CosmeticRow({
    required this.def,
    required this.heroId,
    required this.canEdit,
  });

  final CosmeticDef def;
  final String heroId;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final equipped = switch (def.slot) {
      CosmeticSlot.overlay => profile.equippedOverlayIdFor(heroId) == def.id,
      CosmeticSlot.title => profile.equippedTitleId == def.id,
      CosmeticSlot.frame => profile.equippedFrameId == def.id,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HubColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HubColors.frameGold.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: MythDuskColors.parchment,
                  ),
                ),
                Text(
                  def.slot.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: MythDuskColors.muted,
                      ),
                ),
              ],
            ),
          ),
          if (canEdit)
            TextButton(
              onPressed: () {
                final notifier = ref.read(profileProvider.notifier);
                final ok = equipped
                    ? notifier.unequipCosmetic(def.id, heroId: heroId)
                    : notifier.equipCosmetic(def.id, heroId: heroId);
                if (ok) {
                  ref.read(gameplayAnalyticsProvider).log(
                    GameplayAnalyticsEvents.cosmeticEquipped,
                    {
                      'cosmeticId': def.id,
                      'heroId': heroId,
                      'equipped': !equipped,
                    },
                  );
                }
              },
              child: Text(equipped ? 'Unequip' : 'Equip'),
            )
          else
            Text(
              equipped ? 'Equipped' : 'Owned',
              style: const TextStyle(fontSize: 11, color: MythDuskColors.muted),
            ),
        ],
      ),
    );
  }
}

class _MasteryRow extends ConsumerWidget {
  const _MasteryRow({
    required this.def,
    required this.heroId,
    required this.canEdit,
  });

  final MasteryDefinition def;
  final String heroId;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final counters = profile.masteryFor(heroId);
    final current = counters.valueFor(def.condition);
    final claimed = profile.isMasteryClaimed(def.id);
    final met = current >= def.target;
    final rewardLabel = switch (def.rewardType) {
      MasteryRewardType.unlockSkill => 'Unlock ${def.rewardSkillId}',
      MasteryRewardType.cosmeticTitle =>
        CosmeticCatalog.byId(def.rewardCosmeticId ?? '')?.name ?? 'Title',
      MasteryRewardType.cosmeticFrame =>
        CosmeticCatalog.byId(def.rewardCosmeticId ?? '')?.name ?? 'Frame',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HubColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HubColors.frameGold.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'T${def.tier} · ${def.title}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: MythDuskColors.parchment,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$current / ${def.target} · $rewardLabel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: MythDuskColors.muted,
                      ),
                ),
              ],
            ),
          ),
          if (claimed)
            const Text(
              'Claimed',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: HubColors.glow,
              ),
            )
          else if (met && canEdit)
            TextButton(
              onPressed: () {
                ref.read(profileProvider.notifier).claimMastery(def.id);
              },
              child: const Text('Claim'),
            )
          else
            Text(
              met ? 'Ready' : 'In progress',
              style: const TextStyle(fontSize: 11, color: MythDuskColors.muted),
            ),
        ],
      ),
    );
  }
}

class _UpgradeRow extends ConsumerWidget {
  const _UpgradeRow({
    required this.stat,
    required this.heroId,
    required this.canEdit,
  });

  final String stat;
  final String heroId;
  final bool canEdit;

  String get _label => switch (stat) {
        EconomyBalance.upgradeStatHp => 'Max HP',
        EconomyBalance.upgradeStatDamage => 'Skill damage',
        EconomyBalance.upgradeStatShield => 'Shield power',
        _ => stat,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final level = profile.upgradeLevel(stat, heroId);
    final cost = EconomyBalance.coinCostForNextTier(level);
    final mult = EconomyBalance.multiplierFor(level);
    final pct = ((mult - 1) * 100).round();
    final canBuy = canEdit && cost > 0 && profile.coins >= cost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HubColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HubColors.frameGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: MythDuskColors.parchment,
                  ),
                ),
                Text(
                  'Tier $level / ${EconomyBalance.upgradeMaxTiers} · +$pct%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: !canEdit || cost < 0
                ? null
                : canBuy
                    ? () {
                        final ok = ref
                            .read(profileProvider.notifier)
                            .purchaseUpgrade(stat, heroId: heroId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok ? 'Upgraded $_label' : 'Not enough coins',
                            ),
                          ),
                        );
                      }
                    : null,
            child: Text(cost < 0 ? 'Max' : '$cost'),
          ),
        ],
      ),
    );
  }
}
