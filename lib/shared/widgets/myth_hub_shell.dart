import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets/game_assets.dart';
import '../../core/theme/app_theme.dart';
import 'challenge_art.dart';
import 'relic_frame.dart';

/// Shared atmospheric shell for the player's collection and economy screens.
class MythHubShell extends StatelessWidget {
  const MythHubShell(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.child,
      this.resources});
  final String title, subtitle;
  final Widget child;
  final Widget? resources;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: MythDuskColors.ink,
        body: Stack(children: [
          Positioned.fill(
              child: Image.asset(GameAssets.homeBackground,
                  fit: BoxFit.cover, excludeFromSemantics: true)),
          const Positioned.fill(
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xB807151C), Color(0xEF07151C)])))),
          SafeArea(
              child: Column(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(children: [
                  IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back,
                          color: MythDuskColors.softGold),
                      onPressed: () {
                        final router = GoRouter.of(context);
                        if (router.canPop()) {
                          router.pop();
                        } else {
                          router.go('/');
                        }
                      }),
                  Expanded(
                      child: Text(title,
                          style: challengeTextStyle(23, bold: true),
                          textAlign: TextAlign.center)),
                  const SizedBox(width: 32),
                ])),
            const ChallengeDivider(),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(children: [
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style:
                          challengeTextStyle(12, color: MythDuskColors.muted)),
                  if (resources != null) ...[
                    const SizedBox(height: 8),
                    resources!
                  ],
                ])),
            Expanded(
                child: Theme(
                    data: Theme.of(context).copyWith(
                        textTheme: Theme.of(context).textTheme.copyWith(
                              headlineMedium:
                                  challengeTextStyle(27, bold: true),
                              titleMedium: challengeTextStyle(18, bold: true),
                            )),
                    child: child)),
          ])),
        ]),
      );
}

/// Open gold frame over a dark surface, with an optional equipped accent.
class RelicPanel extends StatelessWidget {
  const RelicPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(14),
      this.selected = false});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;
  @override
  Widget build(BuildContext context) => Stack(children: [
        Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
                color: const Color(0xE6091C24),
                boxShadow: selected
                    ? const [
                        BoxShadow(color: Color(0x335DCAC5), blurRadius: 10)
                      ]
                    : null),
            child: child),
        const Positioned.fill(child: RelicFrame()),
      ]);
}

class HeroPedestal extends StatelessWidget {
  const HeroPedestal({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Stack(alignment: Alignment.bottomCenter, children: [
        Positioned(
            bottom: 0,
            left: 12,
            right: 12,
            child: Image.asset(GameAssets.homeDais,
                height: 46, fit: BoxFit.contain, excludeFromSemantics: true)),
        Positioned.fill(bottom: 12, child: child),
      ]);
}
