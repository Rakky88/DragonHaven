import 'package:flutter/material.dart';

import '../screens/draconomicon_screen.dart';
import 'game_icon_sprite.dart';

/// A labeled touch target without taking a separate row in a dragon picker.
class DraconomiconShortcut extends StatelessWidget {
  const DraconomiconShortcut({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        key: const Key('dragon-picker-draconomicon'),
        tooltip: 'Draconomicon',
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Draconomicon')),
            body: const DraconomiconScreen(),
          ),
        )),
        icon: const GameIconSprite(GameIconKind.draconomicon, size: 40),
      );
}
