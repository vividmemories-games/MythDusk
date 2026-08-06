import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Player-safe boundary for an invalid route or unavailable content record.
class ContentErrorScreen extends StatelessWidget {
  const ContentErrorScreen({
    super.key,
    required this.title,
    required this.message,
    this.destination = '/chapters',
    this.actionLabel = 'Back to Campaign',
  });

  final String title;
  final String message;
  final String destination;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MythoraColors.ink,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 52,
                    color: MythoraColors.ember,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: MythoraColors.parchment,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MythoraColors.muted,
                        ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => context.go(destination),
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
