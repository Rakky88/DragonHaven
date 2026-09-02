import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_lineage.dart';
import 'game_icon_sprite.dart';

enum DragonArtworkFrame { fullImage, juvenile, earth, storm, bond }

@immutable
class DragonArtworkSelection {
  const DragonArtworkSelection(this.asset, this.frame);

  final String asset;
  final DragonArtworkFrame frame;
}

abstract final class DragonArtwork {
  static const eggAsset = 'assets/images/ui/ui_mysterious_egg.webp';
  static const seraphscaleHatchlingAsset =
      'assets/images/dragons/seraphscale_hatchling_v2.webp';
  static const seraphscaleHatchlingSilhouetteAsset =
      'assets/images/dragons/seraphscale_hatchling_silhouette_v2.webp';
  static const seraphscaleHatchlingSpectralAsset =
      'assets/images/dragons/seraphscale_hatchling_spectral_v2.webp';
  static const seraphscaleWyrmlingAsset =
      'assets/images/dragons/seraphscale_wyrmling_v2.png';
  static const seraphscaleMightAsset =
      'assets/images/dragons/seraphscale_ascended_might_v2.png';
  static const seraphscaleArcanaAsset =
      'assets/images/dragons/seraphscale_ascended_arcana_v2.png';

  // These are the exact source forms selected during the on-device audit.
  // They are shipped as standalone images so Flutter never has to crop them
  // from a scaled 2x2 atlas at runtime.
  static const safeStandaloneForms = <String, Set<String>>{
    'cluckatrice': {'wyrmling', 'might', 'arcana', 'spirit'},
    'sinisterra': {'wyrmling', 'might', 'arcana', 'spirit'},
    'auroracrown': {'wyrmling', 'might', 'arcana', 'spirit'},
    'bramblequill': {'wyrmling', 'might', 'arcana', 'spirit'},
    'cinderlynx': {'wyrmling', 'might', 'arcana', 'spirit'},
    'clockskip': {'might', 'spirit'},
    'coraloracle': {'wyrmling', 'might'},
    'crystalwhisk': {'might'},
    'dreammoth': {'arcana'},
    'dustglimmer': {'arcana', 'spirit'},
    'echofern': {'wyrmling', 'might', 'arcana'},
    'eclipseantler': {'wyrmling', 'might'},
    'everwyrm': {'wyrmling', 'might', 'spirit'},
    'frostfable': {'wyrmling', 'might', 'arcana'},
    'harmonytail': {'spirit'},
    'ironwhistle': {'wyrmling', 'might', 'arcana'},
    'leviathanecho': {'wyrmling', 'might', 'spirit'},
    'meteorhide': {'wyrmling', 'might'},
    'mistmantle': {'wyrmling', 'might', 'arcana', 'spirit'},
    'opalchimera': {'wyrmling', 'might', 'spirit'},
    'petaldrift': {'wyrmling', 'might', 'arcana', 'spirit'},
    'quietstar': {'might', 'spirit'},
    'rainbowruff': {'spirit'},
    'runehopper': {'might', 'arcana', 'spirit'},
    'starforged': {'wyrmling', 'might', 'arcana'},
    'sunmuzzle': {'wyrmling', 'might', 'arcana', 'spirit'},
    'temporalark': {'might'},
    'tidescale': {'might', 'spirit'},
    'twinflare': {'spirit'},
    'velvetvolt': {'wyrmling', 'might', 'arcana', 'spirit'},
    'voidbloom': {'wyrmling', 'might', 'arcana', 'spirit'},
    'worldroot': {'wyrmling', 'might'},
  };

  static String hatchlingAsset(String? lineageId) =>
      'assets/images/dragons/${_spriteLineageId(lineageId)}_hatchling.webp';

  static String formsAsset(String? lineageId) =>
      'assets/images/dragons/${_spriteLineageId(lineageId)}_forms.webp';

  static String masteryAsset(String? lineageId) =>
      'assets/images/dragons/${dragonLineageById(lineageId).id}_mastery.webp';

  static String safeStandaloneFormAsset(String lineageId, String form) =>
      secondPassStandaloneForms[lineageId]?.contains(form) == true
          ? 'assets/images/dragons/${_spriteLineageId(lineageId)}_${form}_safe_v2.webp'
          : 'assets/images/dragons/${_spriteLineageId(lineageId)}_${form}_safe.webp';

  // These source forms were still marked after the first full on-device audit.
  // Their second pass is true outpainting: missing anatomy was reconstructed
  // before each full body was placed on a generous transparent canvas.
  static const secondPassStandaloneForms = <String, Set<String>>{
    'clockskip': {'might'},
    'dreammoth': {'arcana'},
    'echofern': {'might'},
    'harmonytail': {'spirit'},
    'ironwhistle': {'might'},
    'meteorhide': {'might'},
    'petaldrift': {'might'},
    'runehopper': {'arcana'},
    'starforged': {'might'},
    'tidescale': {'might', 'spirit'},
    'worldroot': {'might'},
  };

  static String sinisterHatchlingAsset() =>
      'assets/images/dragons/everwyrm_sinister_hatchling.webp';

  static String sinisterFormsAsset() =>
      'assets/images/dragons/everwyrm_sinister_forms.webp';

  static DragonArtworkSelection forStage({
    required String stageKey,
    required String? lineageId,
    required String evolutionPath,
    bool sinister = false,
  }) {
    if (stageKey == 'homeGuardian' && evolutionPath == 'mastery') {
      return DragonArtworkSelection(
        masteryAsset(lineageId),
        DragonArtworkFrame.fullImage,
      );
    }
    if (lineageId == 'seraphscale') {
      final individualAsset = switch (stageKey) {
        'spark' => seraphscaleHatchlingAsset,
        'nestDragon' => seraphscaleWyrmlingAsset,
        'homeGuardian'
            when evolutionPath == 'might' || evolutionPath == 'earth' =>
          seraphscaleMightAsset,
        'homeGuardian'
            when evolutionPath == 'arcana' || evolutionPath == 'storm' =>
          seraphscaleArcanaAsset,
        _ => null,
      };
      if (individualAsset != null) {
        return DragonArtworkSelection(
          individualAsset,
          DragonArtworkFrame.fullImage,
        );
      }
    }
    final safeForm = switch (stageKey) {
      'nestDragon' => 'wyrmling',
      'homeGuardian' => switch (evolutionPath) {
          'storm' || 'arcana' => 'arcana',
          'bond' || 'spirit' => 'spirit',
          _ => 'might',
        },
      _ => null,
    };
    if (safeForm != null &&
        safeStandaloneForms[lineageId]?.contains(safeForm) == true) {
      return DragonArtworkSelection(
        safeStandaloneFormAsset(lineageId!, safeForm),
        DragonArtworkFrame.fullImage,
      );
    }
    return switch (stageKey) {
      'moonEgg' => const DragonArtworkSelection(
          eggAsset,
          DragonArtworkFrame.fullImage,
        ),
      'spark' => DragonArtworkSelection(
          sinister ? sinisterHatchlingAsset() : hatchlingAsset(lineageId),
          DragonArtworkFrame.fullImage,
        ),
      'nestDragon' => DragonArtworkSelection(
          sinister ? sinisterFormsAsset() : formsAsset(lineageId),
          DragonArtworkFrame.juvenile,
        ),
      _ => DragonArtworkSelection(
          sinister ? sinisterFormsAsset() : formsAsset(lineageId),
          switch (evolutionPath) {
            'storm' || 'arcana' => DragonArtworkFrame.storm,
            'bond' || 'spirit' => DragonArtworkFrame.bond,
            _ => DragonArtworkFrame.earth,
          },
        ),
    };
  }

  static Set<String> get allAssetPaths => {
        eggAsset,
        seraphscaleHatchlingAsset,
        seraphscaleHatchlingSilhouetteAsset,
        seraphscaleHatchlingSpectralAsset,
        seraphscaleWyrmlingAsset,
        seraphscaleMightAsset,
        seraphscaleArcanaAsset,
        for (final family in safeStandaloneForms.entries)
          for (final form in family.value)
            safeStandaloneFormAsset(family.key, form),
        for (final lineage in dragonLineages) ...{
          hatchlingAsset(lineage.id),
          formsAsset(lineage.id),
          masteryAsset(lineage.id),
        },
        sinisterHatchlingAsset(),
        sinisterFormsAsset(),
      };

  static int get logicalFormCount => 1 + dragonLineages.length * 6;

  static String _spriteLineageId(String? lineageId) =>
      dragonLineageById(lineageId).spriteId;
}

class DragonArt extends StatefulWidget {
  const DragonArt({
    super.key,
    this.height = 240,
    this.animate = true,
    this.stageKey = 'homeGuardian',
    this.lineageId,
    this.evolutionPath = 'earth',
    this.fit = BoxFit.contain,
    this.prismatic = false,
    this.sinister = false,
    this.silhouette = false,
  });

  final double height;
  final bool animate;
  final String stageKey;
  final String? lineageId;
  final String evolutionPath;
  final BoxFit fit;
  final bool prismatic;
  final bool sinister;
  final bool silhouette;

  @override
  State<DragonArt> createState() => _DragonArtState();
}

class _DragonArtState extends State<DragonArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _float = Tween<double>(begin: -3, end: 5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant DragonArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) return;
    widget.animate ? _controller.repeat(reverse: true) : _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final stage = strings.petStageNameByKey(widget.stageKey);
    final lineage = dragonLineageById(widget.lineageId);
    final egg = widget.stageKey == 'moonEgg';
    final lineageName = strings.lineageName(lineage);
    final artwork = DragonArtwork.forStage(
      stageKey: widget.stageKey,
      lineageId: lineage.id,
      evolutionPath: widget.evolutionPath,
      sinister: widget.sinister && lineage.id == 'everwyrm',
    );
    final preRenderedHatchling =
        artwork.asset == DragonArtwork.seraphscaleHatchlingAsset;
    final displayArtwork = preRenderedHatchling
        ? DragonArtworkSelection(
            widget.silhouette
                ? DragonArtwork.seraphscaleHatchlingSilhouetteAsset
                : widget.prismatic
                    ? DragonArtwork.seraphscaleHatchlingSpectralAsset
                    : DragonArtwork.seraphscaleHatchlingAsset,
            DragonArtworkFrame.fullImage,
          )
        : artwork;
    final needsColorFilter = !preRenderedHatchling &&
        (widget.silhouette || (widget.prismatic && !egg));
    final dragonImage = _DragonImage(
      artwork: displayArtwork,
      fit: widget.fit,
      displaySize: widget.height,
    );
    return Semantics(
      image: true,
      label: widget.silhouette
          ? strings.pick('Undiscovered dragon form', 'Onontdekte drakenvorm')
          : egg
              ? strings.pick('Mysterious Egg', 'Mysterieus Ei')
              : strings.pick(
                  '$lineageName in the $stage life stage',
                  '$lineageName in de levensfase $stage',
                ),
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, widget.animate ? _float.value : 0),
          child: child,
        ),
        child: SizedBox.square(
          dimension: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.prismatic && !widget.silhouette && !egg)
                IgnorePointer(
                  child: Opacity(
                    opacity: .72,
                    child: Padding(
                      padding: EdgeInsets.all(widget.height * .025),
                      child: Image.asset(
                        GameVfxAssets.spectralAura,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              if (needsColorFilter)
                ColorFiltered(
                  colorFilter: widget.silhouette
                      ? const ColorFilter.mode(
                          Color(0xFF2D2941),
                          BlendMode.srcIn,
                        )
                      : const ColorFilter.matrix(<double>[
                          0.25,
                          0.75,
                          0.25,
                          0,
                          18,
                          0.65,
                          0.15,
                          0.55,
                          0,
                          4,
                          0.35,
                          0.55,
                          0.15,
                          0,
                          26,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                  child: dragonImage,
                ),
              if (!needsColorFilter) dragonImage,
            ],
          ),
        ),
      ),
    );
  }
}

class _DragonImage extends StatelessWidget {
  const _DragonImage({
    required this.artwork,
    required this.fit,
    required this.displaySize,
  });

  final DragonArtworkSelection artwork;
  final BoxFit fit;
  final double displaySize;

  @override
  Widget build(BuildContext context) {
    final isAtlas = artwork.frame != DragonArtworkFrame.fullImage;
    final sourceWidth = (displaySize *
            MediaQuery.devicePixelRatioOf(context) *
            (isAtlas ? 2 : 1))
        .ceil()
        .clamp(1, 2048);
    Widget image({
      required BoxFit imageFit,
      Alignment loadingAlignment = Alignment.center,
      bool compensateAtlasScale = false,
    }) =>
        Image.asset(
          artwork.asset,
          fit: imageFit,
          cacheWidth: sourceWidth,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return Transform.scale(
              scale: compensateAtlasScale ? 0.5 : 1,
              alignment: loadingAlignment,
              child: const Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.pets_rounded, size: 96),
          ),
        );

    Widget withSafetyMargin(Widget child) => Padding(
          key: const ValueKey('dragon-art-safety-margin'),
          padding: EdgeInsets.all(displaySize * .055),
          child: child,
        );

    if (artwork.frame == DragonArtworkFrame.fullImage) {
      return withSafetyMargin(image(imageFit: fit));
    }

    final alignment = switch (artwork.frame) {
      DragonArtworkFrame.juvenile => Alignment.topLeft,
      DragonArtworkFrame.earth => Alignment.topRight,
      DragonArtworkFrame.storm => Alignment.bottomLeft,
      DragonArtworkFrame.bond => Alignment.bottomRight,
      DragonArtworkFrame.fullImage => Alignment.center,
    };
    return withSafetyMargin(
      ClipRect(
        child: Transform.scale(
          scale: 2,
          alignment: alignment,
          child: image(
            imageFit: BoxFit.fill,
            loadingAlignment: alignment,
            compensateAtlasScale: true,
          ),
        ),
      ),
    );
  }
}
