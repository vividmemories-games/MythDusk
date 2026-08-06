import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/presentation/home_hub_widgets.dart';
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
                return Opacity(
                  opacity: pageUnlocked ? 1 : 0.4,
                  child: Image.asset(
                    GameAssets.hero(h.id),
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
          const SizedBox(height: 20),
          Text('Skills', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final skill in viewed.skills) ...[
            _SkillCard(skill: skill),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          Text('Upgrades', style: textTheme.titleMedium),
          Text(
            '+5% per tier · max 6 tiers (+30%). Applies in battle for the '
            'selected hero.',
            style: textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          for (final stat in EconomyBalance.upgradeStatKeys) ...[
            _UpgradeRow(stat: stat),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.skill});

  final SkillDef skill;

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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HubColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HubColors.frameGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            skill.name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: MythDuskColors.parchment,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            costs,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: MythDuskColors.softGold,
                ),
          ),
          if (effects.isNotEmpty)
            Text(
              effects,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                  ),
            ),
        ],
      ),
    );
  }
}

class _UpgradeRow extends ConsumerWidget {
  const _UpgradeRow({required this.stat});

  final String stat;

  String get _label => switch (stat) {
        EconomyBalance.upgradeStatHp => 'Max HP',
        EconomyBalance.upgradeStatDamage => 'Skill damage',
        EconomyBalance.upgradeStatShield => 'Shield power',
        _ => stat,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final level = profile.upgradeLevel(stat);
    final cost = EconomyBalance.coinCostForNextTier(level);
    final mult = EconomyBalance.multiplierFor(level);
    final pct = ((mult - 1) * 100).round();
    final canBuy = cost > 0 && profile.coins >= cost;

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
            onPressed: cost < 0
                ? null
                : canBuy
                    ? () {
                        final ok = ref
                            .read(profileProvider.notifier)
                            .purchaseUpgrade(stat);
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
