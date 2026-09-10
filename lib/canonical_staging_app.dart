import 'widgets/canonical_milestones.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/online_config.dart';
import 'l10n/app_strings.dart';
import 'screens/canonical_inventory_screen.dart';
import 'screens/canonical_dragons_screen.dart';
import 'screens/canonical_adventures_screen.dart';
import 'screens/canonical_house_screen.dart';
import 'screens/canonical_profile_screen.dart';
import 'screens/shop_hub_screen.dart';
import 'services/canonical_game_session.dart';
import 'services/canonical_groups.dart';
import 'services/canonical_beacon.dart';
import 'services/canonical_partners.dart';
import 'services/canonical_game_snapshot.dart';
import 'services/canonical_game_transport.dart';
import 'theme/app_theme.dart';
import 'widgets/shop_economy_scope.dart';

void requireCanonicalStaging(OnlineConfig config) {
  if (config.environment != OnlineEnvironment.staging ||
      config.url != CanonicalGameTransport.stagingUrl ||
      !config.isConfigured) {
    throw const CanonicalGameException('game_staging_required');
  }
}

/// Explicit opt-in build lane. Runs before any legacy save/provider is loaded.
/// Its Auth key and inventory journals are isolated from normal game storage.
Future<void> runCanonicalStaging(OnlineConfig config) async {
  requireCanonicalStaging(config);
  await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
      authOptions: FlutterAuthClientOptions(
          localStorage: SharedPreferencesLocalStorage(
              persistSessionKey: 'dragonhaven_canonical_staging_auth_v1')));
  final auth = Supabase.instance.client;
  final support = await getApplicationSupportDirectory();
  final session = CanonicalGameSession(
      connection: CanonicalGameTransport.staging(auth, config),
      directory: Directory('${support.path}/canonical-staging-v1'));
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider.value(value: session),
    Provider<CanonicalBeaconSource>(
        create: (_) => SupabaseCanonicalBeaconSource(auth)),
    ChangeNotifierProvider(
        create: (_) => CanonicalGroups(
            connection: session.connection,
            source: SupabaseCanonicalGroupsSource(auth))),
    ChangeNotifierProvider(
        create: (_) => CanonicalPartners(
            connection: session.connection,
            source: SupabaseCanonicalPartnersSource(auth))),
  ], child: CanonicalStagingApp(session: session, auth: auth)));
}

class CanonicalStagingApp extends StatefulWidget {
  const CanonicalStagingApp(
      {super.key, required this.session, required this.auth});
  final CanonicalGameSession session;
  final SupabaseClient auth;
  @override
  State<CanonicalStagingApp> createState() => _CanonicalStagingAppState();
}

class _CanonicalStagingAppState extends State<CanonicalStagingApp>
    with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  late StreamSubscription<int> _accounts;
  int _tab = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _accounts = widget.session.connection.accountChanges.listen((_) {
      if (!mounted) return;
      _navigator.currentState?.popUntil((route) => route.isFirst);
      setState(() => _tab = 0);
      unawaited(_synchronize());
    });
    unawaited(_synchronize());
  }

  Future<void> _synchronize() async {
    if (widget.session.connection.currentOwner == null) return;
    try {
      await widget.session.synchronize();
    } on CanonicalGameException {
      /* The session exposes a recoverable status. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.session.setForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) unawaited(_synchronize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_accounts.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final signedIn = session.connection.currentOwner != null;
    return MaterialApp(
      navigatorKey: _navigator,
      title: 'DragonHaven Staging',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      supportedLocales: const [Locale('en'), Locale('nl')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(builder: (context) {
        final strings = AppStrings.of(context);
        return Scaffold(
          appBar: AppBar(title: const Text('DragonHaven · Staging'), actions: [
            if (signedIn)
              IconButton(
                  tooltip: strings.pick('Haven', 'Haven'),
                  icon: const Icon(Icons.home_outlined),
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (context) => Scaffold(
                              appBar: AppBar(
                                  title: Text(AppStrings.of(context)
                                      .pick('Haven', 'Haven'))),
                              body: const SafeArea(
                                  child: CanonicalHouseScreen()))))),
            if (signedIn)
              IconButton(
                  tooltip: strings.pick('Profile', 'Profiel'),
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => Scaffold(
                              appBar: AppBar(
                                  title:
                                      Text(strings.pick('Profile', 'Profiel'))),
                              body: const SafeArea(
                                  child: CanonicalProfileScreen()))))),
            if (signedIn)
              IconButton(
                  tooltip: strings.pick('Sign out', 'Uitloggen'),
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    try {
                      await widget.auth.auth.signOut(scope: SignOutScope.local);
                    } on Object {
                      if (context.mounted) setState(() {});
                    }
                  }),
          ]),
          body: SafeArea(
              child: signedIn
                  ? CanonicalMilestones(
                      child: switch (_tab) {
                      0 => const ShopHubScreen(),
                      1 => const CanonicalInventoryScreen(),
                      2 => const CanonicalDragonsScreen(),
                      _ => const CanonicalAdventuresScreen(),
                    })
                  : _StagingSignIn(auth: widget.auth)),
          bottomNavigationBar: signedIn
              ? NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  destinations: [
                      NavigationDestination(
                          icon: const Icon(Icons.storefront),
                          label: strings.pick('Shop', 'Winkel')),
                      NavigationDestination(
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: strings.pick('Inventory', 'Inventaris')),
                      NavigationDestination(
                          icon: const Icon(Icons.pets),
                          label: strings.pick('Dragons', 'Draken')),
                      NavigationDestination(
                          icon: const Icon(Icons.explore_outlined),
                          label: strings.pick('Adventures', 'Avonturen')),
                    ])
              : null,
        );
      }),
    );
  }
}

class _StagingSignIn extends StatefulWidget {
  const _StagingSignIn({required this.auth});
  final SupabaseClient auth;
  @override
  State<_StagingSignIn> createState() => _StagingSignInState();
}

class _StagingSignInState extends State<_StagingSignIn> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.auth.auth.signInWithPassword(
          email: _email.text.trim(), password: _password.text);
      if (result.user?.emailConfirmedAt == null && mounted) {
        setState(() => _error = 'game_login_required');
      }
    } on Object {
      if (mounted) setState(() => _error = 'game_login_required');
    } finally {
      if (mounted) {
        _password.clear();
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ListView(padding: const EdgeInsets.all(24), children: [
      Text(strings.pick('Server economy test', 'Servereconomie testen'),
          style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      Text(strings.pick(
          'Sign in with a prepared staging account. Actions affect only its test inventory.',
          'Log in met een voorbereid stagingaccount. Acties veranderen alleen de testinventaris.')),
      const SizedBox(height: 24),
      TextField(
          controller: _email,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration:
              InputDecoration(labelText: strings.pick('Email', 'E-mail'))),
      const SizedBox(height: 12),
      TextField(
          controller: _password,
          enabled: !_busy,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          onSubmitted: (_) => _signIn(),
          decoration: InputDecoration(
              labelText: strings.pick('Password', 'Wachtwoord'))),
      if (_error != null)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(gameConnectionMessage(strings, _error))),
      const SizedBox(height: 16),
      FilledButton(
          onPressed: _busy ? null : _signIn,
          child: Text(strings.pick(_busy ? 'Signing in…' : 'Sign in',
              _busy ? 'Inloggen…' : 'Inloggen'))),
    ]);
  }
}
