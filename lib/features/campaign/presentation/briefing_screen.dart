import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../battle/domain/enemy_def.dart';
import '../../campaign/data/campaign_repository.dart';
import '../../campaign/domain/campaign_models.dart';
import '../../prep/domain/prep_item.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../../puzzle/domain/level_board_config.dart';
import '../../../shared/presentation/content_error_screen.dart';

/// Pre-battle briefing with embedded prep loadout (campaign path).
class BriefingScreen extends ConsumerStatefulWidget {
  const BriefingScreen({super.key, required this.nodeId});

  final String nodeId;

  @override
  ConsumerState<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends ConsumerState<BriefingScreen> {
  final _selected = <PrepItemId>{};

  String _todayKey() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  String _boardRules(LevelBoardConfig cfg) {
    final parts = <String>[];
    if (cfg.effectiveMovers.isNotEmpty) {
      parts.add('Wind shifts rows each turn');
    }
    if (cfg.hazardSpawn != null) {
      parts.add('Hazards may spread');
    }
    final tid = cfg.templateId ?? '';
    if (tid.contains('mistfen') || tid.contains('sticky')) {
      parts.add('Sticky / poison tiles');
    } else if (tid.contains('bridge')) {
      parts.add('Narrow bridge board');
    } else if (tid.contains('vine')) {
      parts.add('Vine corners');
    }
    if (parts.isEmpty) return 'Open board — match to fuel skills';
    return parts.join(' · ');
  }

  Future<void> _startBattle(CampaignNode node) async {
    final list = _selected.toList();
    if (list.isNotEmpty) {
      final ok = ref.read(profileProvider.notifier).consumePrep(list);
      if (!ok) return;
    }
    ref.read(pendingBossPrepProvider.notifier).state = list;
    if (!mounted) return;
    context.push('/battle/${node.id}');
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(campaignChapterProvider);
    return chapterAsync.when(
      loading: () => const Scaffold(
        backgroundColor: MythDuskColors.ink,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const ContentErrorScreen(
        title: 'Campaign unavailable',
        message: 'The selected chapter could not be loaded.',
      ),
      data: (chapter) {
        final node = chapter.tryNodeById(widget.nodeId);
        if (node == null) {
          return ContentErrorScreen(
            title: 'Battle unavailable',
            message: 'Campaign node “${widget.nodeId}” does not exist.',
          );
        }
        final enemy = EnemyCatalog.tryById(node.enemyId);
        if (enemy == null) {
          return ContentErrorScreen(
            title: 'Enemy unavailable',
            message: 'Enemy content “${node.enemyId}” could not be found.',
          );
        }
        return _buildBriefing(context, chapter, node, enemy);
      },
    );
  }

  Widget _buildBriefing(
    BuildContext context,
    CampaignChapter chapter,
    CampaignNode node,
    EnemyDef enemy,
  ) {
    final profile = ref.watch(profileProvider);
    final textTheme = Theme.of(context).textTheme;
    final board = chapter.boardFor(node);
    final hero = profile.combatHero();
    final heaviest = enemy.heaviestSkill;

    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    tooltip: 'Back to campaign',
                    icon: const Icon(Icons.arrow_back,
                        color: MythDuskColors.parchment),
                  ),
                  Expanded(
                    child: Text(
                      node.name,
                      style: textTheme.headlineMedium?.copyWith(
                        color: MythDuskColors.parchment,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _Card(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: Image.asset(
                            GameAssets.enemy(enemy.id, bossForm: node.bossForm),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.pest_control,
                              size: 40,
                              color: MythDuskColors.ember,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                enemy.name,
                                style: textTheme.titleMedium?.copyWith(
                                  color: MythDuskColors.softGold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                enemy.blurb.isEmpty
                                    ? 'A foe on the dusk road.'
                                    : enemy.blurb,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: MythDuskColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Likely: ${heaviest.intentLabel}',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  color: MythDuskColors.ember,
                                ),
                              ),
                              Text(
                                'HP ${enemy.maxHp}'
                                '${node.isBoss ? ' · Boss' : ''}',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  color: MythDuskColors.parchment,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Board',
                            style: textTheme.titleMedium
                                ?.copyWith(color: MythDuskColors.softGold)),
                        const SizedBox(height: 4),
                        Text(
                          _boardRules(board),
                          style: textTheme.bodyMedium?.copyWith(
                            color: MythDuskColors.parchment,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reward: ${node.coinReward} coins'
                          '${node.prepDrops.isEmpty ? '' : ' · prep drop chance'}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: MythDuskColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hero: ${hero.name}',
                          style: textTheme.titleMedium
                              ?.copyWith(color: MythDuskColors.softGold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hero.skills
                              .map((s) => '${s.name} (${s.apCost} AP)')
                              .join(' · '),
                          style: textTheme.bodyMedium?.copyWith(
                            color: MythDuskColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select aids (optional)',
                    style: textTheme.titleMedium
                        ?.copyWith(color: MythDuskColors.parchment),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Up to ${PrepBalance.maxEquipped}. Spent when battle starts.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: MythDuskColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...PrepItemId.values.map((id) {
                    final count = profile.prepCount(id);
                    final selected = _selected.contains(id);
                    final canSelect = count > 0 &&
                        (selected ||
                            _selected.length < PrepBalance.maxEquipped);
                    final secondWindBlocked = id == PrepItemId.secondWind &&
                        profile.secondWindUsedDay == _todayKey();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: selected
                            ? MythDuskColors.mist
                            : MythDuskColors.deepTeal.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: (!canSelect || secondWindBlocked)
                              ? null
                              : () {
                                  setState(() {
                                    if (selected) {
                                      _selected.remove(id);
                                    } else {
                                      _selected.add(id);
                                    }
                                  });
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Image.asset(
                                    id.assetPath,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.science_outlined),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(id.displayName,
                                          style: textTheme.titleMedium),
                                      Text(
                                        secondWindBlocked
                                            ? 'Already used today'
                                            : '${id.blurb} · own $count',
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontSize: 11,
                                          color: secondWindBlocked
                                              ? MythDuskColors.ember
                                              : MythDuskColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: selected
                                      ? MythDuskColors.amber
                                      : MythDuskColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton(
                onPressed: () => _startBattle(node),
                child: Text(
                  _selected.isEmpty
                      ? 'Battle'
                      : 'Battle (${_selected.length} prep)',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MythDuskColors.deepTeal.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}
