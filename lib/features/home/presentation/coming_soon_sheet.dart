import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Temporary destination until a real feature ships (e.g. Mock rail slot).
Future<void> showComingSoonSheet(
  BuildContext context, {
  required String title,
  required String blurb,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: MythoraColors.deepTeal,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MythoraColors.mist,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                blurb,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Coming before closed testing — not live yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MythoraColors.softGold,
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
