import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_lineage.dart';

enum DragonArtworkFrame { fullImage, juvenile, earth, storm, bond }

@immutable
class DragonArtworkSelection {
  const DragonArtworkSelection(this.asset, this.frame);

  final String asset;
  final DragonArtworkFrame frame;
}

abstract final class DragonArtwork {
  static const eggAsset = 'assets/images/dragons/mysterious_egg.webp';

  static String hatchlingAsset(String? lineageId) =>
      'assets/images/dragons/${_spriteLineageId(lineageId)}_hatchling.webp';

  static String formsAsset(String? lineageId) =>
      'assets/images/dragons/${_spriteLineageId(lineageId)}_forms.webp';

  static String sinisterHatchlingAsset() =>
      'assets/images/dragons/everwyrm_sinister_hatchling.webp';

  static String sinisterFormsAsset() =>
      'assets/images/dragons/everwyrm_sinister_forms.webp';

  static DragonArtworkSelection forStage({
    required String stageKey,
    required String? lineageId,
    required String evolutionPath,
    bool sinister = false,
  }) =>
      switch (stageKey) {
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

  static Set<String> get allAssetPaths => {
        eggAsset,
        for (final lineage in dragonLineages) ...{
          hatchlingAsset(lineage.id),
          formsAsset(lineage.id),
        },
        sinisterHatchlingAsset(),
        sinisterFormsAsset(),
      };

  static int get logicalFormCount => 1 + dragonLineages.length * 5;

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
    final lineageName = lineage.name(strings.isDutch);
    final artwork = DragonArtwork.forStage(
      stageKey: widget.stageKey,
      lineageId: lineage.id,
      evolutionPath: widget.evolutionPath,
      sinister: widget.sinister && lineage.id == 'everwyrm',
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
              ColorFiltered(
                colorFilter: widget.silhouette
                    ? const ColorFilter.mode(Color(0xFF2D2941), BlendMode.srcIn)
                    : widget.prismatic && !egg
                        ? const ColorFilter.matrix(<double>[
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
                          ])
                        : const ColorFilter.mode(
                            Colors.transparent, BlendMode.dst),
                child: _DragonImage(
                  artwork: artwork,
                  fit: widget.fit,
                  displaySize: widget.height,
                ),
              ),
              if (widget.prismatic && !widget.silhouette && !egg)
                const IgnorePointer(
                    child: CustomPaint(painter: _PrismaticParticlePainter())),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrismaticParticlePainter extends CustomPainter {
  const _PrismaticParticlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFFFF73B9),
      Color(0xFF7DE5FF),
      Color(0xFFFFDE59),
      Color(0xFFB593FF)
    ];
    const points = [
      Offset(0.16, 0.24),
      Offset(0.82, 0.2),
      Offset(0.75, 0.66),
      Offset(0.24, 0.72),
      Offset(0.58, 0.1),
      Offset(0.9, 0.48)
    ];
    for (var index = 0; index < points.length; index++) {
      final center =
          Offset(points[index].dx * size.width, points[index].dy * size.height);
      final radius = size.shortestSide * (index.isEven ? 0.025 : 0.018);
      final paint = Paint()..color = colors[index % colors.length];
      canvas.drawCircle(center, radius, paint);
      canvas.drawLine(center - Offset(radius * 2.2, 0),
          center + Offset(radius * 2.2, 0), paint..strokeWidth = 1.5);
      canvas.drawLine(center - Offset(0, radius * 2.2),
          center + Offset(0, radius * 2.2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

    if (artwork.frame == DragonArtworkFrame.fullImage) {
      return image(imageFit: fit);
    }

    final alignment = switch (artwork.frame) {
      DragonArtworkFrame.juvenile => Alignment.topLeft,
      DragonArtworkFrame.earth => Alignment.topRight,
      DragonArtworkFrame.storm => Alignment.bottomLeft,
      DragonArtworkFrame.bond => Alignment.bottomRight,
      DragonArtworkFrame.fullImage => Alignment.center,
    };
    return ClipRect(
      child: Transform.scale(
        scale: 2,
        alignment: alignment,
        child: image(
          imageFit: BoxFit.fill,
          loadingAlignment: alignment,
          compensateAtlasScale: true,
        ),
      ),
    );
  }
}
