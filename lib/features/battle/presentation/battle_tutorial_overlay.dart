import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../domain/battle_tutorial.dart';

/// Bottom callout for first-battle teaching beats.
class BattleTutorialOverlay extends ConsumerWidget {
  const BattleTutorialOverlay({
    super.key,
    required this.enabled,
  });

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return const SizedBox.shrink();
    final profile = ref.watch(profileProvider);
    if (profile.firstBattleTutorialDone) return const SizedBox.shrink();

    final beat = BattleTutorial.nextBeat(profile.tutorialBeatsSeen);
    if (beat == null) return const SizedBox.shrink();
    final caption = BattleTutorial.captions[beat] ?? '';

    return Positioned(
      left: 12,
      right: 12,
      bottom: 110,
      child: Material(
        color: MythDuskColors.ink.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                caption,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MythDuskColors.parchment,
                      fontSize: 13,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => ref
                        .read(profileProvider.notifier)
                        .skipFirstBattleTutorial(),
                    child: const Text('Skip tips'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => ref
                        .read(profileProvider.notifier)
                        .markTutorialBeat(beat),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
