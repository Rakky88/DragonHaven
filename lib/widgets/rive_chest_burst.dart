import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import '../services/rive_runtime.dart';

/// The vector particle layer shared by every chest reveal.
///
/// The actual chest stays a DragonHaven sprite, so seasonal and cosmetic
/// chests keep their exact art. Rive supplies the live vector magic around it.
class RiveChestBurst extends StatefulWidget {
  const RiveChestBurst({
    required this.accent,
    super.key,
  });

  final Color accent;

  @override
  State<RiveChestBurst> createState() => _RiveChestBurstState();
}

class _RiveChestBurstState extends State<RiveChestBurst> {
  rive.File? _file;
  rive.Artboard? _artboard;
  rive.SingleAnimationPainter? _painter;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _failed = true;
      return;
    }
    try {
      if (!await ensureDragonHavenRive()) {
        if (mounted) setState(() => _failed = true);
        return;
      }
      final file = await rive.File.asset(
        'assets/animations/chest_particle_burst.riv',
        riveFactory: rive.Factory.flutter,
      );
      final artboard = file?.defaultArtboard();
      if (file == null || artboard == null) {
        file?.dispose();
        if (mounted) setState(() => _failed = true);
        return;
      }
      final painter = rive.SingleAnimationPainter(
        'Animation 19',
        fit: rive.Fit.contain,
        alignment: Alignment.center,
      );
      if (!mounted) {
        painter.dispose();
        artboard.dispose();
        file.dispose();
        return;
      }
      setState(() {
        _file = file;
        _artboard = artboard;
        _painter = painter;
      });
    } on Object {
      // The Flutter burst underneath remains available if a native renderer
      // cannot be initialised on an unsupported device.
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _painter?.dispose();
    _artboard?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artboard = _artboard;
    final painter = _painter;
    if (_failed || artboard == null || painter == null) {
      return const SizedBox.expand(
        key: Key('rive-chest-burst-fallback'),
      );
    }
    return IgnorePointer(
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          widget.accent.withValues(alpha: .78),
          BlendMode.screen,
        ),
        child: rive.RiveArtboardWidget(
          key: const Key('rive-chest-burst'),
          artboard: artboard,
          painter: painter,
        ),
      ),
    );
  }
}
