import 'package:flutter/material.dart';

import '../models/supporter_pack.dart';

class KeeperBadgeArt extends StatelessWidget {
  const KeeperBadgeArt({super.key, required this.badge, required this.size});

  final KeeperBadgeDefinition badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final level = badge.keeperLevel;
    if (level == null) {
      return Image.asset(
        badge.assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.shield_rounded, size: size * .82),
      );
    }
    return Semantics(
      image: true,
      label: badge.nameEn,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD96A), Color(0xFF6A48AA)],
          ),
          border: Border.all(color: Colors.white, width: size * .07),
          boxShadow: const [
            BoxShadow(color: Color(0x55381967), blurRadius: 6),
          ],
        ),
        child: Text(
          '$level',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * (level >= 10 ? .34 : .42),
            fontWeight: FontWeight.w900,
            shadows: const [Shadow(color: Color(0xAA28174D), blurRadius: 2)],
          ),
        ),
      ),
    );
  }
}

class KeeperFrameArt extends StatelessWidget {
  const KeeperFrameArt({super.key, required this.frame, required this.size});

  final KeeperFrameDefinition frame;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!frame.isGeneratedKeeperLevelFrame) {
      return Image.asset(
        frame.assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return Semantics(
      image: true,
      label: frame.nameEn,
      child: CustomPaint(
        size: Size.square(size),
        painter: const _LevelFortyFramePainter(),
      ),
    );
  }
}

class _LevelFortyFramePainter extends CustomPainter {
  const _LevelFortyFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Offset.zero & size;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .075
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
      ..color = const Color(0x88FFD76A);
    canvas.drawCircle(center, radius * .89, glow);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .065
      ..shader = const SweepGradient(colors: [
        Color(0xFFFFE58D),
        Color(0xFF7C5BC2),
        Color(0xFF55C8D1),
        Color(0xFFFFE58D),
      ]).createShader(rect);
    canvas.drawCircle(center, radius * .9, ring);
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .018
      ..color = Colors.white;
    canvas.drawCircle(center, radius * .81, inner);
    for (var index = 0; index < 8; index++) {
      final angle = index * 3.141592653589793 / 4;
      final point = center +
          Offset.fromDirection(angle, radius * (index.isEven ? .91 : .84));
      canvas.drawCircle(point, size.shortestSide * .024,
          Paint()..color = const Color(0xFFFFE58D));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
