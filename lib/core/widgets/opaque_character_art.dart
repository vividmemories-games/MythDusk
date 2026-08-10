import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-opacity character portrait plate so chibi art does not ghost into the
/// dark hub / battle backgrounds (assets often sit on near-black pads).
class OpaqueCharacterArt extends StatelessWidget {
  const OpaqueCharacterArt({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.locked = false,
    this.borderRadius = 16,
    this.plateColor,
    this.errorBuilder,
  });

  final String assetPath;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final bool locked;
  final double borderRadius;
  final Color? plateColor;
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: plateColor ?? MythDuskColors.deepTeal,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: MythDuskColors.mist.withValues(alpha: locked ? 0.25 : 0.45),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: ColoredBox(
          // Solid underlay so PNG/WebP alpha never composites onto the stage.
          color: plateColor ?? MythDuskColors.deepTeal,
          child: image,
        ),
      ),
    );
  }
}
