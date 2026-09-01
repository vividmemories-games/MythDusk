import 'package:flutter/material.dart';

import '../../features/cosmetics/domain/cosmetic_catalog.dart';
import '../../features/profile/providers/mock_profile_provider.dart';
import '../widgets/opaque_character_art.dart';

/// Resolves equipped overlay/frame for a hero portrait.
({Color? overlayTint, Color? frameColor, List<String> overlayPaths})
    cosmeticLookFor(PlayerProfile profile, String heroId) {
  final overlayId = profile.equippedOverlayIdFor(heroId);
  final overlay = overlayId == null ? null : CosmeticCatalog.byId(overlayId);
  final frame = profile.equippedFrameId == null
      ? null
      : CosmeticCatalog.byId(profile.equippedFrameId!);

  Color? overlayTint;
  final overlayPaths = <String>[];
  if (overlay != null && overlay.slot == CosmeticSlot.overlay) {
    if (overlay.overlayTintArgb != null) {
      overlayTint = Color(overlay.overlayTintArgb!);
    }
    if (overlay.overlayAssetPath != null) {
      overlayPaths.add(overlay.overlayAssetPath!);
    }
  }

  Color? frameColor;
  if (frame != null && frame.slot == CosmeticSlot.frame) {
    frameColor = const Color(0xFFE6C87A);
  }

  return (
    overlayTint: overlayTint,
    frameColor: frameColor,
    overlayPaths: overlayPaths,
  );
}

class CosmeticHeroArt extends StatelessWidget {
  const CosmeticHeroArt({
    super.key,
    required this.heroId,
    required this.assetPath,
    required this.profile,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.locked = false,
    this.borderRadius = 16,
    this.showPlate = true,
    this.errorBuilder,
  });

  final String heroId;
  final String assetPath;
  final PlayerProfile profile;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final bool locked;
  final double borderRadius;
  final bool showPlate;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final look = cosmeticLookFor(profile, heroId);
    return OpaqueCharacterArt(
      assetPath: assetPath,
      fit: fit,
      alignment: alignment,
      locked: locked,
      borderRadius: borderRadius,
      showPlate: showPlate,
      errorBuilder: errorBuilder,
      overlayAssetPaths: look.overlayPaths,
      overlayTint: look.overlayTint,
      frameColor: look.frameColor,
    );
  }
}
