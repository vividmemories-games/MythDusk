import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/challenge_art.dart';
import '../../../shared/widgets/myth_hub_shell.dart';
import '../../expedition/domain/expedition_models.dart';

/// Destinations that should not sit on the Home stage.
Future<void> showHomeMoreSheet(
  BuildContext context, {
  required bool expeditionUnlocked,
  required bool expeditionInProgress,
  required VoidCallback onProfile,
  required VoidCallback onExpedition,
  required VoidCallback onSettings,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: MythDuskColors.ink,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final expeditionSubtitle = !expeditionUnlocked
          ? 'Clear ${ExpeditionBalance.minCampaignClears} campaign nodes'
          : (expeditionInProgress ? 'Run in progress' : 'Relic path');
      return SafeArea(
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MythDuskColors.mist,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'More',
                textAlign: TextAlign.center,
                style: challengeTextStyle(23, bold: true),
              ),
              const SizedBox(height: 8),
              const ChallengeDivider(),
              const SizedBox(height: 12),
              RelicPanel(
                  child: Column(children: [
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: MythDuskColors.parchment,
                  ),
                  title: const Text('Profile'),
                  subtitle: const Text('Progress, prep inventory, cosmetics'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onProfile();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.explore_outlined,
                    color: MythDuskColors.parchment,
                  ),
                  title: const Text('Expedition'),
                  subtitle: Text(expeditionSubtitle),
                  trailing: expeditionInProgress
                      ? const Icon(
                          Icons.circle,
                          size: 10,
                          color: Color(0xFF3ECFCB),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onExpedition();
                  },
                ),
                ListTile(
                    leading: const Icon(Icons.settings_outlined,
                        color: MythDuskColors.softGold),
                    title: const Text('Settings'),
                    subtitle: const Text('Preferences and account'),
                    trailing: const Icon(Icons.chevron_right,
                        color: MythDuskColors.softGold),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onSettings();
                    }),
              ])),
            ],
          ),
        )),
      );
    },
  );
}
