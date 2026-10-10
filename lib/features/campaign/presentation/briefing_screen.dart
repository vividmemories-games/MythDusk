import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../battle/domain/enemy_def.dart';
import '../../prep/domain/prep_item.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../../puzzle/domain/level_board_config.dart';
import '../../../shared/presentation/content_error_screen.dart';
import '../data/campaign_repository.dart';
import '../domain/campaign_models.dart';
import '../../../shared/widgets/challenge_art.dart';
import '../../../core/widgets/opaque_character_art.dart';
import 'briefing_widgets.dart';

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

  void _leave() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/campaign');
    }
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
    final brief = boardBriefFor(chapter.boardFor(node));
    final hero = profile.combatHero();
    final heaviest = enemy.heaviestSkill;

    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      body: Stack(fit: StackFit.expand, children: [
        Image.asset(GameAssets.battleBackground(chapter.backgroundId),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: MythDuskColors.ink)),
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
              Color(0x55071118),
              Color(0x88071118),
              Color(0xBB071118)
            ]))),
        SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                      onPressed: _leave,
                      tooltip: 'Back to campaign',
                      icon: const Icon(Icons.chevron_left,
                          size: 32, color: MythDuskColors.softGold)),
                )),
            Expanded(
                child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                      flex: 4,
                      child: SizedBox(
                          height: (MediaQuery.sizeOf(context).width * .48)
                              .clamp(140.0, 220.0),
                          child: OpaqueCharacterArt(
                              assetPath: GameAssets.enemy(enemy.id,
                                  bossForm: node.bossForm),
                              showPlate: false,
                              alignment: Alignment.bottomCenter))),
                  const SizedBox(width: 10),
                  Expanded(
                      flex: 6,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(enemy.name,
                                style: challengeTextStyle(24,
                                    bold: true,
                                    color: MythDuskColors.softGold)),
                            const SizedBox(height: 8),
                            Text(
                                enemy.blurb.isEmpty
                                    ? 'A foe on the dusk road.'
                                    : enemy.blurb,
                                style: challengeTextStyle(13)),
                            const SizedBox(height: 10),
                            BriefingMetaLine(
                                icon: Icons.crisis_alert,
                                color: MythDuskColors.ember,
                                text: 'Likely: ${heaviest.intentLabel}'),
                            const SizedBox(height: 5),
                            BriefingMetaLine(
                                icon: Icons.favorite,
                                color: const Color(0xFFE15B64),
                                text:
                                    'HP ${enemy.maxHp}${node.isBoss ? ' · Boss' : ''}'),
                          ])),
                ]),
                const SizedBox(height: 12),
                Text(brief.title,
                    style: challengeTextStyle(14,
                        bold: true, color: MythDuskColors.softGold)),
                const SizedBox(height: 3),
                Text(brief.detail, style: challengeTextStyle(12)),
                const SizedBox(height: 6),
                BriefingMetaLine(
                    icon: Icons.monetization_on,
                    color: MythDuskColors.amber,
                    text:
                        'Reward ${node.coinReward} coins${node.prepDrops.isEmpty ? '' : ' · prep drop chance'}'),
                const SizedBox(height: 12),
                BriefingLoadout(
                    hero: hero,
                    profile: profile,
                    onEdit: () => context.push('/heroes')),
                const SizedBox(height: 12),
                Text('Select aids (optional)',
                    style: challengeTextStyle(19, bold: true)),
                const SizedBox(height: 4),
                Text(
                    'Up to ${PrepBalance.maxEquipped} spent when battle starts.',
                    style: challengeTextStyle(12, color: MythDuskColors.muted)),
                const SizedBox(height: 8),
                LayoutBuilder(builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 330 ||
                      MediaQuery.textScalerOf(context).scale(14) > 21;
                  final cards = [
                    for (final id in PrepItemId.values)
                      BriefingPrepCard(
                          id: id,
                          count: profile.prepCount(id),
                          selected: _selected.contains(id),
                          blocked: id == PrepItemId.secondWind &&
                              profile.secondWindUsedDay == _todayKey(),
                          canSelect: _canSelect(id, profile),
                          onTap: () => _toggle(id))
                  ];
                  if (stacked) {
                    return Column(children: [
                      for (final card in cards)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: card)
                    ]);
                  }
                  return IntrinsicHeight(
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(child: cards[i]),
                        ]
                      ]));
                }),
              ],
            )),
            Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                child: ChallengePlayButton(
                    enabled: true,
                    onPressed: () => _startBattle(node),
                    label: _selected.isEmpty
                        ? 'Battle'
                        : 'Battle (${_selected.length} prep)')),
          ]),
        ))),
      ]),
    );
  }

  bool _canSelect(PrepItemId id, PlayerProfile profile) {
    final count = profile.prepCount(id);
    final selected = _selected.contains(id);
    final room = selected || _selected.length < PrepBalance.maxEquipped;
    final blocked =
        id == PrepItemId.secondWind && profile.secondWindUsedDay == _todayKey();
    return count > 0 && room && !blocked;
  }

  void _toggle(PrepItemId id) {
    final profile = ref.read(profileProvider);
    if (!_canSelect(id, profile) && !_selected.contains(id)) return;
    if (id == PrepItemId.secondWind &&
        profile.secondWindUsedDay == _todayKey()) {
      return;
    }
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (profile.prepCount(id) > 0 &&
          _selected.length < PrepBalance.maxEquipped) {
        _selected.add(id);
      }
    });
  }
}

/// Player-facing board summary for the briefing card.
class BoardBrief {
  const BoardBrief({required this.title, required this.detail});

  final String title;
  final String detail;
}

BoardBrief boardBriefFor(LevelBoardConfig cfg) {
  final tid = cfg.templateId ?? '';
  final BoardBrief base;
  if (tid.contains('sticky') || tid.contains('mistfen')) {
    base = const BoardBrief(
      title: 'Sticky marsh',
      detail: 'Vines and poison cling to the tiles.',
    );
  } else if (tid.contains('vine')) {
    base = const BoardBrief(
      title: 'Vine corners',
      detail: 'Twisted vines block the corners.',
    );
  } else if (tid.contains('bridge')) {
    base = const BoardBrief(
      title: 'Narrow bridge',
      detail: 'Only a thin path stays open.',
    );
  } else {
    base = const BoardBrief(
      title: 'Open board',
      detail: 'Match tiles to fuel skills.',
    );
  }
  final extra = <String>[];
  if (cfg.effectiveMovers.isNotEmpty) {
    extra.add('Wind shifts rows each turn.');
  }
  if (cfg.hazardSpawn != null) {
    extra.add('Hazards may spread.');
  }
  if (extra.isEmpty) return base;
  return BoardBrief(
    title: base.title,
    detail: '${base.detail} ${extra.join(' ')}',
  );
}
