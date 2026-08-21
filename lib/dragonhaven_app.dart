import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_strings.dart';
import 'providers/household_provider.dart';
import 'screens/account_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/adventure_screen.dart';
import 'screens/dragon_tower_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/haven_shop_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/stash_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/about_sheet.dart';

class DragonHavenApp extends StatelessWidget {
  const DragonHavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<HouseholdProvider>().languageCode;
    return MaterialApp(
      title: 'DragonHaven',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: Locale(languageCode),
      supportedLocales: AppStrings.supportedLanguages.keys.map(Locale.new),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const DragonHavenGate(),
    );
  }
}

class DragonHavenGate extends StatelessWidget {
  const DragonHavenGate({super.key});

  @override
  Widget build(BuildContext context) {
    final ready = context
        .select<HouseholdProvider, bool>((game) => game.onboardingComplete);
    return ready ? const DragonHavenShell() : const OnboardingScreen();
  }
}

enum _HavenMenuAction { account, language, achievements }

class DragonHavenShell extends StatefulWidget {
  const DragonHavenShell({super.key});

  @override
  State<DragonHavenShell> createState() => _DragonHavenShellState();
}

class _DragonHavenShellState extends State<DragonHavenShell> {
  int _index = 1;
  final _visited = <int>{1};
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<HouseholdProvider>().refreshForCurrentDate(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HouseholdProvider>().refreshForCurrentDate();
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final eggOnly = game.pet.isEgg;
    final screens = <Widget>[
      const AdventureScreen(),
      const DragonTowerScreen(),
      const FriendsScreen(),
      const StashScreen(),
      const HavenShopScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        leading: IconButton(
          key: const Key('app-logo-about-button'),
          tooltip: strings.pick('About DragonHaven', 'Over DragonHaven'),
          onPressed: () => showDragonHavenAboutSheet(context),
          padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
          icon: Image.asset('assets/images/dragonhaven_logo.png',
              width: 42, height: 42, fit: BoxFit.contain),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('DragonHaven',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3)),
          Text(
            eggOnly
                ? strings.pick('Rooftop Nest', 'Daknest')
                : _screenTitle(_index, strings),
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.muted,
                fontWeight: FontWeight.w700),
          ),
        ]),
        actions: [
          if (!eggOnly) ...[
            _TopCurrency(
                icon: Icons.monetization_on_rounded, value: game.coins),
            _TopCurrency(icon: Icons.diamond_rounded, value: game.gems),
          ],
          PopupMenuButton<_HavenMenuAction>(
            key: const Key('app-overflow-menu'),
            tooltip: strings.tr('more'),
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: _handleMenuAction,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _HavenMenuAction.account,
                child: _MenuRow(
                    icon: Icons.person_rounded, label: strings.tr('account')),
              ),
              PopupMenuItem(
                key: const Key('app-menu-language'),
                value: _HavenMenuAction.language,
                child: _MenuRow(
                    icon: Icons.translate_rounded,
                    label: strings.tr('language'),
                    trailing: game.languageCode.toUpperCase()),
              ),
              PopupMenuItem(
                value: _HavenMenuAction.achievements,
                child: _MenuRow(
                    icon: Icons.emoji_events_rounded,
                    label: strings.tr('achievements'),
                    trailing: '${game.unlockedAchievementIds.length}/20'),
              ),
            ],
          ),
          const SizedBox(width: 3),
        ],
      ),
      body: eggOnly
          ? const DragonTowerScreen()
          : IndexedStack(
              index: _index,
              children: [
                for (var index = 0; index < screens.length; index++)
                  _visited.contains(index)
                      ? screens[index]
                      : const SizedBox.shrink(),
              ],
            ),
      bottomNavigationBar: eggOnly
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() {
                _index = index;
                _visited.add(index);
              }),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.explore_outlined),
                  selectedIcon: const Icon(Icons.explore_rounded),
                  label: strings.tr('adventure'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.castle_outlined),
                  selectedIcon: const Icon(Icons.castle_rounded),
                  label: strings.pick('Tower', 'Toren'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.people_outline_rounded),
                  selectedIcon: const Icon(Icons.people_rounded),
                  label: strings.tr('friends'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.inventory_2_outlined),
                  selectedIcon: const Icon(Icons.inventory_2_rounded),
                  label: strings.tr('stash'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.storefront_outlined),
                  selectedIcon: const Icon(Icons.storefront_rounded),
                  label: strings.tr('shop'),
                ),
              ],
            ),
    );
  }

  void _handleMenuAction(_HavenMenuAction action) {
    switch (action) {
      case _HavenMenuAction.account:
        Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AccountScreen()));
      case _HavenMenuAction.language:
        _showLanguagePicker();
      case _HavenMenuAction.achievements:
        Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const AchievementsScreen()));
    }
  }

  Future<void> _showLanguagePicker() => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) {
          final strings = AppStrings.of(sheetContext);
          final selected = sheetContext.watch<HouseholdProvider>().languageCode;
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * .72,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                children: [
                  Text(strings.tr('language'),
                      style: Theme.of(sheetContext).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  for (final entry in AppStrings.supportedLanguages.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        key: Key('language-option-${entry.key}'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: selected == entry.key
                                  ? AppColors.twilight
                                  : AppColors.mist),
                        ),
                        tileColor: selected == entry.key
                            ? AppColors.mist
                            : Colors.white,
                        leading: Icon(
                            selected == entry.key
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: AppColors.twilight),
                        title: Text(entry.value,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        trailing: Text(entry.key.toUpperCase(),
                            style: const TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w800)),
                        onTap: () async {
                          await sheetContext
                              .read<HouseholdProvider>()
                              .setLanguage(entry.key);
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.trailing});
  final IconData icon;
  final String label;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppColors.twilight),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w800))),
        if (trailing != null)
          Text(trailing!,
              style: const TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w800)),
      ]);
}

class _TopCurrency extends StatelessWidget {
  const _TopCurrency({required this.icon, required this.value});
  final IconData icon;
  final int value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: AppColors.twilight),
          const SizedBox(width: 2),
          Text('$value',
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
        ]),
      );
}

String _screenTitle(int index, AppStrings strings) => switch (index) {
      0 => strings.tr('adventure'),
      1 => strings.tr('tower'),
      2 => strings.tr('friends'),
      3 => strings.tr('stash'),
      4 => strings.tr('shop'),
      _ => 'DragonHaven',
    };
