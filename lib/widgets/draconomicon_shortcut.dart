import 'package:flutter/material.dart';

import '../screens/draconomicon_screen.dart';

/// A full, wrapping label with its own row: compact even on narrow pickers.
class DraconomiconShortcut extends StatelessWidget {
  const DraconomiconShortcut({super.key});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          key: const Key('dragon-picker-draconomicon'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 12, fontWeight: FontWeight.w800),
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Draconomicon')),
              body: const DraconomiconScreen(),
            ),
          )),
          icon: const Icon(Icons.menu_book_rounded, size: 18),
          label: const Text('Draconomicon'),
        ),
      );
}
