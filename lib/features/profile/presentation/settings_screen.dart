import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/mock_profile_provider.dart';

/// Player preferences and account shortcuts.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    return Scaffold(
      backgroundColor: MythoraColors.ink,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.person_outline,
              color: MythoraColors.softGold,
            ),
            title: const Text('Profile'),
            subtitle: const Text('Progress, upgrades, and prep'),
            trailing: const Icon(
              Icons.chevron_right,
              color: MythoraColors.muted,
            ),
            onTap: () => context.push('/profile'),
          ),
          const Divider(color: MythoraColors.mist),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Match hints'),
            subtitle: const Text(
              'Highlight a move after 5 seconds of idle play',
            ),
            activeThumbColor: MythoraColors.amber,
            value: profile.hintsEnabled,
            onChanged: notifier.setHintsEnabled,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sound'),
            subtitle: const Text('Battle and UI sound effects (coming soon)'),
            activeThumbColor: MythoraColors.amber,
            value: profile.soundEnabled,
            onChanged: notifier.setSoundEnabled,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Haptics'),
            subtitle: const Text('Light vibration on matches (coming soon)'),
            activeThumbColor: MythoraColors.amber,
            value: profile.hapticsEnabled,
            onChanged: notifier.setHapticsEnabled,
          ),
        ],
      ),
    );
  }
}
