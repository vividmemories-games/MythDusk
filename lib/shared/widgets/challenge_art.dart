import 'package:flutter/material.dart';
import '../../core/assets/game_assets.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/opaque_character_art.dart';

abstract final class ChallengeArtwork {
  static const stage = 'assets/images/daily/bog_stage.webp';
  static String path(String name) => 'assets/images/daily/$name.webp';
}

TextStyle challengeTextStyle(double size,
        {bool bold = false, Color color = MythDuskColors.parchment}) =>
    TextStyle(
        fontFamily: 'DailySerif',
        fontFamilyFallback: const ['Georgia', 'serif'],
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: color);

class ChallengeArtIcon extends StatelessWidget {
  const ChallengeArtIcon(this.name, {super.key, this.size = 48});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(ChallengeArtwork.path(name),
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true);
}

class ChallengeDivider extends StatelessWidget {
  const ChallengeDivider({super.key});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Row(children: [
        Expanded(
            child: Container(
                height: 1,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                  Colors.transparent,
                  MythDuskColors.softGold
                ])))),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Transform.rotate(
                angle: .785398,
                child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: MythDuskColors.softGold, width: 1.2))))),
        Expanded(
            child: Container(
                height: 1,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                  MythDuskColors.softGold,
                  Colors.transparent
                ])))),
      ]));
}

class ChallengeStage extends StatelessWidget {
  const ChallengeStage(
      {super.key,
      required this.enemyId,
      required this.name,
      this.bossForm,
      this.heightFactor = .48});
  final String enemyId;
  final int? bossForm;
  final double heightFactor;
  final String name;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final height = constraints.maxWidth * heightFactor;
        return SizedBox(
            height: height + 40,
            child: Stack(children: [
              Positioned.fill(
                  child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.white,
                                Colors.white,
                                Colors.transparent
                              ],
                              stops: [
                                0,
                                .13,
                                .8,
                                1
                              ]).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(ChallengeArtwork.stage,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, .35)))),
              Positioned(
                  top: 0,
                  left: 24,
                  right: 24,
                  height: height,
                  child: OpaqueCharacterArt(
                      assetPath: GameAssets.enemy(enemyId, bossForm: bossForm),
                      showPlate: false,
                      alignment: Alignment.bottomCenter)),
              Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Column(children: [
                    Text(name,
                        textAlign: TextAlign.center,
                        style: challengeTextStyle(27, bold: true).copyWith(
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 8)
                            ])),
                    const SizedBox(height: 5),
                    const ChallengeDivider()
                  ])),
            ]));
      });
}

class ChallengePanel extends StatelessWidget {
  const ChallengePanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned.fill(
              child: Container(
                  margin: const EdgeInsets.all(9),
                  color: const Color(0xF003252D))),
          Positioned.fill(
              child: Image.asset(ChallengeArtwork.path('panel_frame'),
                  fit: BoxFit.fill, excludeFromSemantics: true)),
          Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12), child: child),
        ],
      );
}

class ChallengeCoinReward extends StatelessWidget {
  const ChallengeCoinReward(
      {super.key, required this.amount, this.claimed = false});
  final int amount;
  final bool claimed;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        const ChallengeArtIcon('coin', size: 24),
        const SizedBox(width: 5),
        Text(claimed ? 'Claimed' : '+$amount',
            style: challengeTextStyle(17,
                bold: true, color: MythDuskColors.softGold)),
      ]);
}

class ChallengePlayButton extends StatelessWidget {
  const ChallengePlayButton(
      {super.key,
      required this.enabled,
      required this.onPressed,
      required this.label});
  final bool enabled;
  final VoidCallback onPressed;
  final String label;
  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 19;
    return Opacity(
      opacity: enabled ? 1 : .55,
      child: DecoratedBox(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage(ChallengeArtwork.path('button')),
                fit: BoxFit.fill)),
        child: TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              foregroundColor: MythDuskColors.ink),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (!largeText) ...[
              if (enabled)
                const SizedBox(
                    width: 28,
                    height: 28,
                    child: CustomPaint(painter: _CrossedBlades()))
              else
                const Icon(Icons.check_circle_outline,
                    size: 26, color: MythDuskColors.ink),
              const SizedBox(width: 12),
            ],
            Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: challengeTextStyle(largeText ? 22 : 25,
                        bold: true, color: MythDuskColors.ink)))
          ]),
        ),
      ),
    );
  }
}

class _CrossedBlades extends CustomPainter {
  const _CrossedBlades();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = MythDuskColors.ink;
    canvas.scale(size.width / 28, size.height / 28);
    for (final flip in [false, true]) {
      canvas.save();
      if (flip) {
        canvas.translate(28, 0);
        canvas.scale(-1, 1);
      }
      final blade = Path()
        ..moveTo(3, 1)
        ..lineTo(10, 4)
        ..lineTo(21, 19)
        ..lineTo(18, 22)
        ..lineTo(4, 9)
        ..close();
      canvas.drawPath(blade, paint);
      canvas.drawLine(
          const Offset(15, 23), const Offset(24, 14), paint..strokeWidth = 2.5);
      canvas.drawLine(
          const Offset(20, 21), const Offset(25, 26), paint..strokeWidth = 3);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CrossedBlades oldDelegate) => false;
}

class ChallengeActions extends StatelessWidget {
  const ChallengeActions(
      {super.key,
      required this.lives,
      required this.maxLives,
      required this.enabled,
      required this.label,
      required this.onPressed});
  final int lives;
  final int maxLives;
  final bool enabled;
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                MythDuskColors.ink.withValues(alpha: .7),
                MythDuskColors.ink
              ])),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ChallengePlayButton(
                      enabled: enabled,
                      onPressed: onPressed,
                      label: label,
                    ),
                    const SizedBox(height: 7),
                    Semantics(
                        label: 'Lives $lives of $maxLives',
                        child: ExcludeSemantics(
                            child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10,
                                runSpacing: 4,
                                children: [
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                for (var i = 0; i < maxLives; i++)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      child: Opacity(
                                          opacity: i < lives ? 1 : .25,
                                          child: const ChallengeArtIcon('heart',
                                              size: 22))),
                              ]),
                              Text('Lives $lives/$maxLives',
                                  style: challengeTextStyle(14,
                                      color: MythDuskColors.muted)),
                            ]))),
                  ])),
        ),
      ));
}
