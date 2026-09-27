import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// Keeps the familiar egg picker first while allowing the same crafted relic
/// to reveal a hatched dragon.
class AltarRelicTargets extends StatelessWidget {
  const AltarRelicTargets({
    super.key,
    required this.eggs,
    required this.dragons,
  });

  final Widget eggs;
  final Widget dragons;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        TabBar(tabs: [
          Tab(text: strings.pick('Eggs', 'Eieren')),
          Tab(text: strings.pick('Dragons', 'Draken')),
        ]),
        Expanded(child: TabBarView(children: [eggs, dragons])),
      ]),
    );
  }
}
