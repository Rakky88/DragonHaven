import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_strings.dart';
import 'models/achievement.dart';
import 'models/game_presentation.dart';
import 'providers/household_provider.dart';
import 'providers/online_account_provider.dart';
import 'screens/account_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/adventure_hub_screen.dart';
import 'screens/dragon_tower_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/shop_hub_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pet_screen.dart';
import 'screens/inventory_screen.dart';
import 'services/audio_service.dart';
import 'services/automatic_cloud_backup.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/about_sheet.dart';
import 'widgets/game_icon_sprite.dart';
import 'widgets/game_tutorial.dart';
import 'widgets/achievement_reveal.dart';
import 'widgets/pull_to_dismiss_sheet.dart';
import 'widgets/trade_reveal.dart';

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

enum _HavenMenuAction { account, language, achievements, tutorial }

class DragonHavenShell extends StatefulWidget {
  const DragonHavenShell({super.key});

  @override
  State<DragonHavenShell> createState() => _DragonHavenShellState();
}

class _DragonHavenShellState extends State<DragonHavenShell> {
  int _index = 2;
  final _visited = <int>{2};
  late final AppLifecycleListener _lifecycle;
  late final HouseholdProvider _game;
  late final OnlineAccountProvider _online;
  late final AutomaticCloudBackupCoordinator _automaticCloudBackup;
  late final StreamSubscription<HavenNotificationDestination>
      _notificationNavigation;
  Timer? _presentationRetry;
  Timer? _gameClock;
  int _adventureInitialTab = 0;
  int _adventureNavigationRevision = 0;
  bool _presentationBusy = false;
  bool _tutorialBusy = false;

  @override
  void initState() {
    super.initState();
    _game = context.read<HouseholdProvider>();
    _online = context.read<OnlineAccountProvider>();
    _automaticCloudBackup = AutomaticCloudBackupCoordinator(
      game: _game,
      online: _online,
    );
    unawaited(_automaticCloudBackup.initialize());
    _notificationNavigation = HavenNotifications.navigationEvents.listen(
      (_) {
        final destination = HavenNotifications.takePendingNavigation();
        if (destination != null) _openNotificationDestination(destination);
      },
    );
    _game.addListener(_schedulePresentations);
    _gameClock = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _game.refreshForCurrentDate();
      _schedulePresentations();
    });
    _lifecycle = AppLifecycleListener(
      onPause: () => unawaited(_automaticCloudBackup.tryWhenBackgrounded()),
      onResume: () async {
        _setTowerAmbientMusic();
        await _game.refreshForCurrentDate();
        await _online.refresh();
        _schedulePresentations();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _setTowerAmbientMusic();
      await _game.refreshForCurrentDate();
      await _online.refresh();
      _schedulePresentations();
      final destination = HavenNotifications.takePendingNavigation();
      if (destination != null) _openNotificationDestination(destination);
    });
  }

  void _setTowerAmbientMusic() {
    final hour = DateTime.now().hour;
    HavenAudio.setMusicScene(hour >= 21 || hour < 7
        ? HavenMusicScene.towerNight
        : HavenMusicScene.towerDay);
  }

  @override
  void dispose() {
    _presentationRetry?.cancel();
    _gameClock?.cancel();
    _game.removeListener(_schedulePresentations);
    _automaticCloudBackup.dispose();
    unawaited(_notificationNavigation.cancel());
    _lifecycle.dispose();
    super.dispose();
  }

  void _schedulePresentations() {
    if (!mounted || _presentationBusy || _tutorialBusy) {
      return;
    }
    final next = _game.nextPresentation;
    if (next == null && !_game.shouldStartTutorial) return;
    _presentationRetry?.cancel();
    _presentationRetry = Timer(
      next?.type == GamePresentationType.evolution
          ? const Duration(milliseconds: 70)
          : const Duration(milliseconds: 280),
      () => unawaited(next == null ? _runTutorial() : _drainPresentations()),
    );
  }

  Future<void> _drainPresentations() async {
    if (!mounted || _presentationBusy) return;
    if (ModalRoute.of(context)?.isCurrent != true &&
        _game.nextPresentation?.type != GamePresentationType.evolution) {
      _presentationRetry = Timer(
        const Duration(milliseconds: 450),
        _drainPresentations,
      );
      return;
    }
    _presentationBusy = true;
    try {
      while (mounted) {
        final presentation = _game.nextPresentation;
        if (presentation == null) break;
        if (!mounted) break;
        switch (presentation.type) {
          case GamePresentationType.hatch:
            if (!mounted) return;
            await showHatchMilestonePresentation(
              context,
              _game,
              presentation,
            );
            break;
          case GamePresentationType.evolution:
            if (!mounted) return;
            await showEvolutionMilestonePresentation(
              context,
              _game,
              presentation,
            );
            break;
          case GamePresentationType.trade:
            if (!mounted) return;
            await showTradeReveal(context, _game, presentation);
            break;
          case GamePresentationType.achievement:
            final achievement = _achievementById(presentation.achievementId);
            if (achievement != null && mounted) {
              await showAchievementReveal(context, achievement);
            }
            break;
        }
        await _game.completePresentation(presentation.id);
        if (!mounted) break;
        await Future<void>.delayed(const Duration(milliseconds: 180));
      }
      if (mounted && _game.shouldStartTutorial) await _runTutorial();
    } finally {
      _presentationBusy = false;
      _schedulePresentations();
    }
  }

  AchievementDefinition? _achievementById(String? id) {
    for (final achievement in achievementCatalog) {
      if (achievement.id == id) return achievement;
    }
    return null;
  }

  Future<void> _runTutorial({bool force = false}) async {
    if (!mounted || _game.pet.isEgg) return;
    if (_tutorialBusy) {
      if (force) {
        _presentationRetry?.cancel();
        _presentationRetry = Timer(
          const Duration(milliseconds: 250),
          () => unawaited(_runTutorial(force: true)),
        );
      }
      return;
    }
    if (!force && !_game.shouldStartTutorial) return;
    if (ModalRoute.of(context)?.isCurrent != true && !force) {
      _presentationRetry = Timer(
        const Duration(milliseconds: 450),
        () => unawaited(_runTutorial()),
      );
      return;
    }
    _tutorialBusy = true;
    try {
      final fullyViewed = await showDragonHavenTutorial(
        context,
        dragon: _game.towerControllableDragon,
        onNavigate: _selectIndex,
      );
      await _game.completeTutorial(fullyViewed: fullyViewed);
    } finally {
      _tutorialBusy = false;
      _schedulePresentations();
    }
  }

  void _selectIndex(int index) {
    if (!mounted || index < 0 || index > 4) return;
    setState(() {
      _index = index;
      _visited.add(index);
    });
    _setTowerAmbientMusic();
    if (index == 0) {
      unawaited(_online.refresh());
    }
  }

  void _openNotificationDestination(HavenNotificationDestination destination) {
    if (!mounted) return;
    switch (destination) {
      case HavenNotificationDestination.adventureCompleted:
        setState(() {
          _adventureInitialTab = 3;
          _adventureNavigationRevision++;
          _index = 1;
          _visited.add(1);
        });
      case HavenNotificationDestination.adventureAvailable:
        setState(() {
          _adventureInitialTab = 0;
          _adventureNavigationRevision++;
          _index = 1;
          _visited.add(1);
        });
      case HavenNotificationDestination.adventureTrials:
        setState(() {
          _adventureInitialTab = 1;
          _adventureNavigationRevision++;
          _index = 1;
          _visited.add(1);
        });
      case HavenNotificationDestination.friends:
        _selectIndex(0);
      case HavenNotificationDestination.tower:
        _selectIndex(2);
      case HavenNotificationDestination.achievements:
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const AchievementsScreen(),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final eggOnly = game.pet.isEgg;
    final screens = <Widget>[
      const FriendsScreen(),
      AdventureHubScreen(
        initialTab: _adventureInitialTab,
        navigationRevision: _adventureNavigationRevision,
      ),
      const DragonTowerScreen(),
      const InventoryScreen(),
      const ShopHubScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        leadingWidth: 66,
        titleSpacing: 2,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0x55F4C95D),
                  Color(0x335B4B8A),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        leading: IconButton(
          key: const Key('app-logo-about-button'),
          tooltip: strings.pick('About DragonHaven', 'Over DragonHaven'),
          onPressed: () => showDragonHavenAboutSheet(context),
          padding: const EdgeInsets.fromLTRB(9, 7, 5, 7),
          icon: Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(2),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFFFD76A), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x225B4B8A),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Transform.translate(
              offset: const Offset(.7, 0),
              child: Image.asset(
                'assets/images/dragonhaven_logo.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
        title: _DragonHavenBrandTitle(
          subtitle: eggOnly
              ? strings.pick('Rooftop Nest', 'Daknest')
              : _screenTitle(_index, strings),
        ),
        actions: [
          if (!eggOnly) ...[
            _TopCurrency(kind: GameIconKind.coin, value: game.coins),
            _TopCurrency(kind: GameIconKind.gem, value: game.gems),
          ],
          PopupMenuButton<_HavenMenuAction>(
            key: const Key('app-overflow-menu'),
            tooltip: strings.tr('more'),
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: _handleMenuAction,
            itemBuilder: (_) => [
              PopupMenuItem(
                key: const Key('app-menu-account'),
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
                key: const Key('app-menu-achievements'),
                value: _HavenMenuAction.achievements,
                child: _MenuRow(
                    icon: Icons.emoji_events_rounded,
                    label: strings.tr('achievements'),
                    trailing:
                        '${game.unlockedAchievementIds.length}/${achievementCatalog.length}'),
              ),
              PopupMenuItem(
                key: const Key('app-menu-tutorial'),
                value: _HavenMenuAction.tutorial,
                enabled: !eggOnly,
                child: _MenuRow(
                  icon: Icons.school_rounded,
                  label: strings.pick('Tutorial', 'Tutorial'),
                ),
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
              onDestinationSelected: _selectIndex,
              destinations: [
                NavigationDestination(
                  icon: const GameIconSprite(
                    GameIconKind.navFriends,
                    size: 34,
                  ),
                  selectedIcon: const GameIconSprite(
                    GameIconKind.navFriends,
                    size: 42,
                  ),
                  label: strings.tr('friends'),
                ),
                NavigationDestination(
                  icon: const GameIconSprite(
                    GameIconKind.navAdventure,
                    size: 34,
                  ),
                  selectedIcon: const GameIconSprite(
                    GameIconKind.navAdventure,
                    size: 42,
                  ),
                  label: strings.tr('adventure'),
                ),
                NavigationDestination(
                  icon: const GameIconSprite(
                    GameIconKind.navTower,
                    size: 34,
                  ),
                  selectedIcon: const GameIconSprite(
                    GameIconKind.navTower,
                    size: 42,
                  ),
                  label: strings.pick('Tower', 'Toren'),
                ),
                NavigationDestination(
                  icon: const GameIconSprite(
                    GameIconKind.navInventory,
                    size: 34,
                  ),
                  selectedIcon: const GameIconSprite(
                    GameIconKind.navInventory,
                    size: 42,
                  ),
                  label: strings.tr('inventory'),
                ),
                NavigationDestination(
                  icon: const GameIconSprite(
                    GameIconKind.navShop,
                    size: 34,
                  ),
                  selectedIcon: const GameIconSprite(
                    GameIconKind.navShop,
                    size: 42,
                  ),
                  label: strings.tr('shop'),
                ),
              ],
            ),
    );
  }

  void _handleMenuAction(_HavenMenuAction action) {
    switch (action) {
      case _HavenMenuAction.account:
        if (_online.isSignedIn && !_online.busy) {
          unawaited(_online.loadCloudSaveStatus());
        }
        Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AccountScreen()));
      case _HavenMenuAction.language:
        _showLanguagePicker();
      case _HavenMenuAction.achievements:
        Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const AchievementsScreen()));
      case _HavenMenuAction.tutorial:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_runTutorial(force: true));
        });
    }
  }

  Future<void> _showLanguagePicker() => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final strings = AppStrings.of(sheetContext);
          final selected = sheetContext.watch<HouseholdProvider>().languageCode;
          return PullToDismissSheet(
            heightFactor: .78,
            dragHandleKey: const Key('language-drag-handle'),
            child: ListView(
              key: const Key('language-picker-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
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
                      tileColor:
                          selected == entry.key ? AppColors.mist : Colors.white,
                      leading: Icon(
                          selected == entry.key
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: AppColors.twilight),
                      title: Text(entry.value,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
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
          );
        },
      );
}

class _DragonHavenBrandTitle extends StatelessWidget {
  const _DragonHavenBrandTitle({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            const TextSpan(
              children: [
                TextSpan(text: 'Dragon'),
                TextSpan(
                  text: 'Haven',
                  style: TextStyle(color: AppColors.twilight),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 19,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -.65,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  subtitle.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .75,
                  ),
                ),
              ),
            ],
          ),
        ],
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
  const _TopCurrency({required this.kind, required this.value});
  final GameIconKind kind;
  final int value;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.mist),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          GameIconSprite(kind, size: 20),
          const SizedBox(width: 3),
          Text('$value',
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
        ]),
      );
}

String _screenTitle(int index, AppStrings strings) => switch (index) {
      0 => strings.tr('friends'),
      1 => strings.tr('adventure'),
      2 => strings.tr('tower'),
      3 => strings.tr('inventory'),
      4 => strings.tr('shop'),
      _ => 'DragonHaven',
    };
