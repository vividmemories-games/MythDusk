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
    this.overlayAssetPaths = const [],
    this.overlayTint,
    this.frameColor,
  });

  final String assetPath;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final bool locked;
  final double borderRadius;
  final Color? plateColor;
  final bool showPlate;
  final ImageErrorWidgetBuilder? errorBuilder;

  /// Optional PNG overlays (middle-approach cosmetics; art may land later).
  final List<String> overlayAssetPaths;

  /// Programmatic sash/rim tint when no overlay asset exists.
  final Color? overlayTint;

  /// Optional profile-frame border.
  final Color? frameColor;

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

    image = _withCosmeticLayers(image);

    final frame = frameColor;
    if (!showPlate) {
      Widget clipped = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
      if (frame != null) {
        clipped = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: frame, width: 2.5),
          ),
          child: clipped,
        );
      }
      return clipped;
    }

    final plate = plateColor ?? MythDuskColors.deepTeal;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: plate,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: frame ??
              MythDuskColors.mist.withValues(alpha: locked ? 0.25 : 0.45),
          width: frame == null ? 1 : 2.5,
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

  Widget _withCosmeticLayers(Widget image) {
    final paths = overlayAssetPaths;
    final tint = overlayTint;
    if (paths.isEmpty && tint == null) return image;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: image),
        for (final path in paths)
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                path,
                fit: fit,
                alignment: alignment,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        if (tint != null)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: tint, width: 3),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      tint.withValues(alpha: 0.22),
                      const Color(0x00000000),
                      tint.withValues(alpha: 0.38),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
