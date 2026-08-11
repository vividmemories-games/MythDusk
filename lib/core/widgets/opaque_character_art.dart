import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Character portrait. Optional solid plate for hub cards; battle uses
/// [showPlate] false so art sits on the stage background.
class OpaqueCharacterArt extends StatelessWidget {
  const OpaqueCharacterArt({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.locked = false,
    this.borderRadius = 16,
    this.plateColor,
    this.showPlate = true,
    this.errorBuilder,
  });

  final String assetPath;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final bool locked;
  final double borderRadius;
  final Color? plateColor;
  final bool showPlate;
  final ImageErrorWidgetBuilder? errorBuilder;

  static const List<double> _greyscaleMatrix = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      assetPath,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      errorBuilder: errorBuilder ??
          (_, __, ___) => const Icon(
                Icons.person,
                size: 72,
                color: MythDuskColors.muted,
              ),
    );

    if (locked) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_greyscaleMatrix),
        child: image,
      );
    }

    if (!showPlate) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }

    final plate = plateColor ?? MythDuskColors.deepTeal;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: plate,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: MythDuskColors.mist.withValues(alpha: locked ? 0.25 : 0.45),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: ColoredBox(
          color: plate,
          child: image,
        ),
      ),
    );
  }
}
