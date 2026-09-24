import 'screens/canonical_nest_screen.dart';
import 'models/achievement.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/app_strings.dart';
import 'models/music_track.dart';
import 'models/day_phase.dart';
import 'providers/household_provider.dart'
    show SpecialAdventureWindow, nextAdventureOfferRefreshAt;
import 'models/adventure.dart';
import 'providers/online_account_provider.dart';
import 'screens/achievements_screen.dart';
import 'screens/canonical_adventures_screen.dart';
import 'screens/canonical_dragons_screen.dart';
import 'screens/canonical_eggs.dart';
import 'screens/canonical_house_screen.dart';
import 'screens/canonical_inventory_screen.dart';
import 'screens/canonical_trials_screen.dart';
import 'screens/draconomicon_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/keeper_journal_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/server_account_screen.dart';
import 'screens/shop_hub_screen.dart';
import 'services/audio_service.dart';
import 'services/canonical_game_actions.dart';
import 'services/canonical_rewarded_ads.dart';
import 'services/canonical_groups.dart';
import 'services/canonical_hatch_scheduler.dart';
import 'services/canonical_game_session.dart';
import 'services/canonical_game_snapshot.dart';
import 'services/event_branding_service.dart';
import 'services/notification_service.dart';
import 'services/release_service.dart';
import 'services/platform_actions.dart';
import 'theme/app_theme.dart';
import 'theme/event_appearance.dart';
import 'widgets/canonical_milestones.dart';
import 'widgets/about_sheet.dart';
import 'widgets/game_icon_sprite.dart';
import 'widgets/game_tutorial.dart';
import 'widgets/haven_header_title.dart';
import 'widgets/notification_destination_listener.dart';
import 'widgets/rooftop_egg_nest.dart';
import 'widgets/haven_lighting.dart';
import 'widgets/seasonal_app_frame.dart';
import 'widgets/shop_economy_scope.dart';

@visibleForTesting
Duration canonicalRefreshDelay({
  required DateTime now,
  required DateTime adventureRefreshAt,
  required Iterable<DateTime> towerAwayUntil,
  int expiredRetryAttempt = 0,
}) {
  final breaks = towerAwayUntil.toList(growable: false);
  if (breaks.any((instant) => !instant.isAfter(now))) {
    const retrySeconds = [2, 4, 8, 16, 30, 60];
    final index = expiredRetryAttempt.clamp(0, retrySeconds.length - 1);
    return Duration(seconds: retrySeconds[index]);
  }
  final future = <DateTime>[
    adventureRefreshAt,
    ...breaks,
  ].where((instant) => instant.isAfter(now)).toList()
    ..sort();
  if (future.isEmpty) return const Duration(milliseconds: 1);
  final delay = future.first.difference(now);
  return delay > Duration.zero ? delay : const Duration(milliseconds: 1);
}

/// The ordinary five-tab app over confirmed account state. No device save is
/// constructed or mutated here; all changes use durable server commands.
class ServerDragonHavenApp extends StatefulWidget {
  const ServerDragonHavenApp({super.key, required this.auth});
  final SupabaseClient auth;
  @override
  State<ServerDragonHavenApp> createState() => _ServerDragonHavenAppState();
}

class _ServerDragonHavenAppState extends State<ServerDragonHavenApp>
    with WidgetsBindingObserver {
  final _branding = EventBrandingService();
  final _elapsed = Stopwatch()..start();
  CanonicalGameSnapshot? _observed;
  Timer? _clock, _refresh;
  CanonicalHatchScheduler? _hatchScheduler;
  String? _eventKey, _audioConfiguration;
  int _towerRefreshRetryAttempt = 0;

  DateTime get _now =>
      (_observed?.serverTime ?? DateTime.now().toUtc()).add(_elapsed.elapsed);
  List<SpecialAdventureWindow> _windows(CanonicalGameSnapshot view) => [
        for (final window in view.adventures.activeEvents)
          if (window.definition case final definition?)
            SpecialAdventureWindow(
                event: definition,
                key: window.key,
                startsAt: window.startsAt,
                endsAt: window.endsAt)
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hatchScheduler =
        CanonicalHatchScheduler(context.read<CanonicalGameSession>());
    unawaited(HavenAudio.setAppInForeground(true));
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      final view = context.read<CanonicalGameSession>().snapshot;
      if (view != null &&
          appEventWindow(_windows(view), _now)?.key != _eventKey &&
          mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(() async {
        await _advance();
        if (mounted) _scheduleRefresh();
      }());
    });
  }

  void _scheduleRefresh() {
    _refresh?.cancel();
    final view = context.read<CanonicalGameSession>().confirmedSnapshot;
    final now = _now;
    final breaks = view?.house.towerDragonAwayUntil.values ?? const [];
    final expiredBreak = breaks.any((instant) => !instant.isAfter(now));
    if (!expiredBreak) _towerRefreshRetryAttempt = 0;
    final remaining = canonicalRefreshDelay(
      now: now,
      adventureRefreshAt: nextAdventureOfferRefreshAt(AdventureKind.mini, now)!,
      towerAwayUntil: breaks,
      expiredRetryAttempt: _towerRefreshRetryAttempt,
    );
    _refresh = Timer(remaining, () async {
      // Let an exclusive command that crossed the quarter-hour finish, so the
      // scheduled refill is not skipped for an entire cycle. Predictable
      // commands need no wait because refresh can join their durable queue.
      final wait = Stopwatch()..start();
      while (mounted &&
          context.read<CanonicalGameSession>().busy &&
          !context.read<CanonicalGameSession>().canAct &&
          wait.elapsed < const Duration(seconds: 30)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      await _advance();
      if (mounted) {
        if (_hasExpiredTowerBreak && _towerRefreshRetryAttempt < 5) {
          _towerRefreshRetryAttempt++;
        }
        _scheduleRefresh();
      }
    });
  }

  bool get _hasExpiredTowerBreak {
    final now = _now;
    return context
            .read<CanonicalGameSession>()
            .confirmedSnapshot
            ?.house
            .towerDragonAwayUntil
            .values
            .any((instant) => !instant.isAfter(now)) ==
        true;
  }

  Future<void> _advance() async {
    final session = context.read<CanonicalGameSession>();
    final view = session.confirmedSnapshot;
    // A predictable refresh may safely join the existing optimistic queue.
    // Only an exclusive command should postpone this automatic work.
    if (!session.canAct || view == null || !view.profile.onboardingComplete) {
      return;
    }
    try {
      if (view.trialAttempt == null && view.schoolAttempt == null) {
        await CanonicalGameActions(session).execute('refresh', const {});
      }
      if (mounted) await context.read<CanonicalGroups?>()?.refresh();
    } on CanonicalGameException {
      // The account gate and session recovery own connection errors.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.inactive) {
      return;
    }
    context.read<OnlineAccountProvider>().setAppInForeground(foreground);
    context.read<CanonicalGameSession>().setForeground(foreground);
    if (foreground) {
      unawaited(_resume());
    }
    unawaited(HavenAudio.setAppInForeground(foreground));
  }

  Future<void> _resume() async {
    final session = context.read<CanonicalGameSession>();
    try {
      await session.synchronize();
      if (mounted) {
        await context.read<CanonicalRewardedAds?>()?.resumed();
        await _advance();
        _scheduleRefresh();
      }
    } on CanonicalGameException {
      // The account gate and reconnect controls handle expired or lost sessions.
    }
  }

  @override
  void dispose() {
    _hatchScheduler?.dispose();
    _clock?.cancel();
    _refresh?.cancel();
    _elapsed.stop();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(HavenAudio.setAppInForeground(false));
    super.dispose();
  }

  Future<void> _configureAudio(
      CanonicalGameSnapshot view, SpecialAdventureWindow? event) async {
    final prefs = view.profile.preferences;
    final tracks = [
      ...seasonalMusicCatalog.where((t) =>
          t.temporaryEventId == event?.event.id &&
          !(prefs['disabledSeasonalMusicTrackIds'] as List).contains(t.id)),
      ...musicCatalog.where((t) =>
          view.shop.music.contains(t.id) &&
          (prefs['enabledMusicTrackIds'] as List).contains(t.id)),
    ];
    final configuration = jsonEncode([prefs, tracks.map((t) => t.id).toList()]);
    if (configuration == _audioConfiguration) return;
    _audioConfiguration = configuration;
    await HavenAudio.configureJukebox(
        trackIds: tracks.map((t) => t.rawResourceId),
        shuffle: prefs['jukeboxShuffle'] as bool,
        repeat: prefs['jukeboxRepeat'] as bool);
    await HavenAudio.applyPreferences(
        musicEnabled: prefs['musicEnabled'] as bool,
        soundEffectsEnabled: prefs['soundEffectsEnabled'] as bool,
        musicStyle:
            HavenMusicStyle.values.byName(prefs['musicStyle'] as String));
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final view = session.snapshot;
    if (view == null) return const SizedBox.shrink();
    final confirmed = session.confirmedSnapshot;
    if (!identical(confirmed, _observed)) {
      _observed = confirmed;
      _elapsed.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scheduleRefresh();
      });
    }
    final windows = _windows(view);
    final event = appEventWindow(windows, _now);
    _eventKey = event?.key;
    final appearance =
        event == null ? null : EventAppearance.forEvent(event.event.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_configureAudio(view, event));
      unawaited(_branding.synchronize(eventBrandingSchedule(_now, windows,
          dismissedUntil: view.adventures.dismissedEvents)));
    });
    return MaterialApp(
      title: 'DragonHaven',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(event: appearance),
      locale: Locale(view.profile.preferences['languageCode'] as String),
      supportedLocales: AppStrings.supportedLanguages.keys.map(Locale.new),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => SeasonalAppFrame(
          window: event,
          child: appearance == null
              ? child!
              : EventBackdrop(appearance: appearance, child: child!)),
      home: Builder(
          builder: (context) => view.profile.onboardingComplete
              ? _ServerShell(auth: widget.auth, now: () => _now)
              : OnboardingScreen(
                  completeOnboarding: (name) =>
                      runShopAction(context, () async {
                        await CanonicalGameActions(session)
                            .completeOnboarding(name);
                        if (mounted) await _advance();
                      }))),
    );
  }
}

class _ServerShell extends StatefulWidget {
  const _ServerShell({required this.auth, required this.now});
  final SupabaseClient auth;
  final DateTime Function() now;
  @override
  State<_ServerShell> createState() => _ServerShellState();
}

enum _Menu { account, journal, achievements, tutorial }

class _ServerShellState extends State<_ServerShell> {
  int _index = 2;
  final _visited = <int>{2};
  bool _tutorialShowing = false;
  bool _showCompleted = false;
  int _adventureNavigationRevision = 0;
  Timer? _updateRetry;

  @override
  void initState() {
    super.initState();
    unawaited(_checkForUpdate());
  }

  @override
  void dispose() {
    _updateRetry?.cancel();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    try {
      final release = await ReleaseService.fetchLatest();
      if (mounted && release.hasApk && release.isNewerThanInstalled) {
        _offerUpdate(release);
      }
    } catch (_) {
      // A failed update lookup never blocks account restoration.
    }
  }

  void _offerUpdate(LatestRelease release) {
    _updateRetry?.cancel();
    _updateRetry = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final view = context.read<CanonicalGameSession>().snapshot;
      if (view == null) return;
      if (_tutorialShowing ||
          view.presentations.isNotEmpty ||
          view.trialAttempt != null ||
          view.schoolAttempt != null ||
          ModalRoute.of(context)?.isCurrent != true) {
        _offerUpdate(release);
        return;
      }
      final s = AppStrings.of(context);
      final update = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(s.pick('Update available', 'Update beschikbaar')),
                content: Text(
                    '${s.pick('A newer version of DragonHaven is ready.', 'Er staat een nieuwere versie van DragonHaven klaar.')}\n\nv${release.version}'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(s.pick('Later', 'Later'))),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(s.pick('Update', 'Updaten'))),
                ],
              ));
      if (update == true && mounted) {
        try {
          await PlatformActions.openUrl(release.downloadUrl);
        } catch (_) {
          if (mounted) await showDragonHavenAboutSheet(context);
        }
      }
    });
  }

  void _notification(HavenNotificationDestination destination) {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    _adventureNavigationRevision++;
    if (destination == HavenNotificationDestination.achievements) {
      Navigator.push(context,
          MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()));
    } else if (destination == HavenNotificationDestination.adventureTrials) {
      _navigate(1);
      Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Dragon Trials')),
                  body: const CanonicalTrialsScreen())));
    } else {
      _showCompleted =
          destination == HavenNotificationDestination.adventureCompleted;
      _navigate(switch (destination) {
        HavenNotificationDestination.friends => 0,
        HavenNotificationDestination.adventureAvailable ||
        HavenNotificationDestination.adventureCompleted =>
          1,
        _ => 2,
      });
    }
  }

  void _navigate(int index) {
    if (!mounted) {
      return;
    }
    setState(() {
      _visited.add(index);
      _index = index;
    });
    final hour = DateTime.now().hour;
    unawaited(HavenAudio.setMusicScene(index == 2
        ? (hour >= 21 || hour < 7
            ? HavenMusicScene.towerNight
            : HavenMusicScene.towerDay)
        : HavenMusicScene.towerDay));
  }

  Future<void> _tutorial() async {
    final session = context.read<CanonicalGameSession>();
    final dragon = session.snapshot?.dragons.where((d) => d.owned).firstOrNull;
    if (dragon == null || _tutorialShowing) return;
    _tutorialShowing = true;
    try {
      final fully = await showDragonHavenTutorial(context, dragon: dragon,
          onNavigate: (index) {
        if (index == 1) {
          _showCompleted = false;
          _adventureNavigationRevision++;
        }
        _navigate(index);
      });
      if (mounted) {
        await runShopAction(context, () async {
          await CanonicalGameActions(session)
              .execute('complete_tutorial', {'fullyViewed': fully});
        });
      }
    } finally {
      _tutorialShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = context.watch<CanonicalGameSession>().snapshot!;
    final session = context.read<CanonicalGameSession>();
    if (!_tutorialShowing &&
        !view.profile.tutorialCompleted &&
        view.presentations.isEmpty &&
        view.trialAttempt == null &&
        view.schoolAttempt == null &&
        view.dragons.any((d) => d.owned && d.name.trim().isNotEmpty) &&
        (view.data['collection']['achievements'] as List)
            .contains('hello_little_one') &&
        session.canRunAutomatic) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          unawaited(_tutorial());
        }
      });
    }
    final s = AppStrings.of(context);
    final event = SeasonalAppFrame.windowOf(context);
    final labels = [
      s.tr('friends'),
      s.pick('Adventure', 'Avontuur'),
      s.pick('Tower', 'Toren'),
      s.pick('Inventory', 'Inventaris'),
      s.tr('shop')
    ];
    final scaffold = Scaffold(
      appBar: AppBar(
        toolbarHeight: HavenHeaderTitle.toolbarHeight(context),
        leadingWidth: 58,
        leading: IconButton(
            key: const Key('about-logo-button'),
            tooltip: s.pick('About DragonHaven', 'Over DragonHaven'),
            padding: const EdgeInsets.all(7),
            onPressed: () => showDragonHavenAboutSheet(context),
            icon: event == null
                ? Image.asset('assets/images/dragonhaven_logo.png')
                : SeasonalAppLogo(eventId: event.event.id)),
        titleSpacing: 0,
        title: HavenHeaderTitle(
            subtitle: labels[_index], coins: view.coins, gems: view.gems),
        actions: [
          PopupMenuButton<_Menu>(
              key: const Key('haven-menu-button'),
              onSelected: (choice) {
                if (choice == _Menu.tutorial) {
                  unawaited(_tutorial());
                  return;
                }
                Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => switch (choice) {
                              _Menu.account =>
                                ServerAccountScreen(auth: widget.auth),
                              _Menu.achievements => const AchievementsScreen(),
                              _ => const KeeperJournalScreen(),
                            }));
              },
              itemBuilder: (_) => [
                    PopupMenuItem(
                        value: _Menu.account,
                        child: _RestoredMenuRow(
                            icon: Icons.person_rounded,
                            label: s.tr('account'))),
                    PopupMenuItem(
                        value: _Menu.achievements,
                        child: _RestoredMenuRow(
                            icon: Icons.emoji_events_rounded,
                            label: s.tr('achievements'),
                            trailing:
                                '${(view.data['collection']['achievements'] as List).length}/${achievementCatalog.length}')),
                    PopupMenuItem(
                        value: _Menu.journal,
                        child: _RestoredMenuRow(
                            icon: Icons.auto_stories_rounded,
                            label: s.pick('Keeper Journal', 'Keeperdagboek'))),
                    PopupMenuItem(
                        value: _Menu.tutorial,
                        child: _RestoredMenuRow(
                            icon: Icons.school_rounded,
                            label: s.pick('Tutorial', 'Uitleg'))),
                  ])
        ],
      ),
      body: SafeArea(
          child: Column(children: [
        if (event != null) EventCountdownBanner(window: event, now: widget.now),
        Expanded(
            child: CanonicalMilestones(
                child: IndexedStack(index: _index, children: [
          _visited.contains(0)
              ? FriendsScreen(active: _index == 0)
              : const SizedBox.shrink(),
          _visited.contains(1)
              ? CanonicalAdventuresScreen(
                  key: ValueKey(
                      'adventures-notification-$_adventureNavigationRevision'),
                  showCompleted: _showCompleted,
                  active: _index == 1)
              : const SizedBox.shrink(),
          const _ServerTower(),
          _visited.contains(3)
              ? const CanonicalInventoryScreen()
              : const SizedBox.shrink(),
          _visited.contains(4)
              ? const ShopHubScreen()
              : const SizedBox.shrink(),
        ]))),
      ])),
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
          // Keep the five fixed-width destinations readable on a small phone;
          // page content retains the keeper's full accessibility text scale.
          maxScaleFactor: MediaQuery.sizeOf(context).width < 360 ? 1.1 : 1.3,
          child: NavigationBar(
              key: const Key('tutorial-primary-navigation'),
              selectedIndex: _index,
              onDestinationSelected: _navigate,
              destinations: [
                for (final (i, kind) in const [
                  GameIconKind.navFriends,
                  GameIconKind.navAdventure,
                  GameIconKind.navTower,
                  GameIconKind.navInventory,
                  GameIconKind.navShop
                ].indexed)
                  NavigationDestination(
                      key: Key('nav-${[
                        'friends',
                        'adventure',
                        'tower',
                        'inventory',
                        'shop'
                      ][i]}'),
                      icon: GameIconSprite(kind, size: 34),
                      label: labels[i])
              ])),
    );
    return NotificationDestinationListener(
        onDestination: _notification, child: scaffold);
  }
}

class _ServerTower extends StatelessWidget {
  const _ServerTower();
  @override
  Widget build(BuildContext context) {
    final view = context.watch<CanonicalGameSession>().snapshot!;
    final s = AppStrings.of(context);
    return CanonicalHouseScreen(
      showHeading: false,
      header: view.nest == null
          ? const _EmptyServerNest()
          : _ServerNest(egg: view.nest!, view: view),
      toolbar: Padding(
          key: const Key('tutorial-tower-actions'),
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Expanded(
                child: Text(s.tr('tower'),
                    style: Theme.of(context).textTheme.displaySmall)),
            IconButton(
                key: const Key('my-dragons-button'),
                tooltip: s.pick('My dragons', 'Mijn draken'),
                icon: const GameIconSprite(GameIconKind.myDragons, size: 40),
                onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const CanonicalDragonsScreen.sheet())),
            IconButton(
                tooltip: 'Draconomicon',
                icon: const GameIconSprite(GameIconKind.draconomicon, size: 40),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                            appBar: AppBar(),
                            body: DraconomiconScreen(
                                discoveredForms: view.shop.discoveredForms,
                                prismaticForms: view.shop.prismaticForms))))),
          ])),
    );
  }
}

class _EmptyServerNest extends StatelessWidget {
  const _EmptyServerNest();
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        key: const Key('server-empty-nest'),
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
                builder: (_) => const CanonicalNestScreen())),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 215,
              child: Stack(fit: StackFit.expand, children: [
                HavenPhaseImage(
                    assetFor: (phase) =>
                        'assets/images/tower_nest_${phase.assetKey}.webp'),
                Positioned(
                    left: 14,
                    right: 14,
                    top: 13,
                    child: Row(children: [
                      Expanded(
                          child: Text(s.pick('Rooftop Nest', 'Daknest'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  shadows: [
                                    Shadow(blurRadius: 6, color: Colors.black54)
                                  ]))),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white),
                    ])),
              ]),
            )),
      ),
    );
  }
}

class _ServerNest extends StatefulWidget {
  const _ServerNest({required this.egg, required this.view});
  final CanonicalEggView egg;
  final CanonicalGameSnapshot view;
  @override
  State<_ServerNest> createState() => _ServerNestState();
}

class _ServerNestState extends State<_ServerNest> {
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return SizedBox(
        height: 215,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
                key: const Key('server-nest-egg'),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => const CanonicalNestScreen())),
                child: Stack(children: [
                  const Positioned.fill(child: RooftopEggNest()),
                  Positioned(
                      left: 14,
                      right: 14,
                      top: 13,
                      child: Row(
                          key: const Key('tutorial-rooftop-header'),
                          children: [
                            Expanded(
                                child: Text(s.pick('Rooftop Nest', 'Daknest'),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18))),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                    color: const Color(0xD91B1436),
                                    borderRadius: BorderRadius.circular(99)),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const GameIconSprite(GameIconKind.clock,
                                          size: 19),
                                      const SizedBox(width: 5),
                                      CanonicalNestClock(
                                          egg: widget.egg,
                                          view: widget.view,
                                          showHatchButton: false,
                                          compact: true),
                                    ])),
                            const Icon(Icons.chevron_right_rounded,
                                color: Colors.white),
                          ])),
                ]))));
  }
}

class _RestoredMenuRow extends StatelessWidget {
  const _RestoredMenuRow(
      {required this.icon, required this.label, this.trailing});
  final IconData icon;
  final String label;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppColors.eventColor(context, AppColors.twilight)),
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
