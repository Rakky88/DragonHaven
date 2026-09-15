import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_info.dart';
import 'canonical_staging_app.dart';
import 'config/firebase_config.dart';
import 'config/online_config.dart';
import 'dragonhaven_app.dart';
import 'l10n/app_strings.dart';
import 'providers/household_provider.dart';
import 'screens/account_save_choice_screen.dart';
import 'services/account_legacy_game_storage.dart';
import 'services/canonical_account_bootstrap.dart';
import 'services/canonical_beacon.dart';
import 'services/canonical_game_session.dart';
import 'services/canonical_game_snapshot.dart';
import 'services/canonical_game_transport.dart';
import 'services/canonical_groups.dart';
import 'services/canonical_legacy_account_source.dart';
import 'services/canonical_partners.dart';
import 'services/firebase_monitoring.dart';
import 'services/diagnostic_reporter.dart';
import 'services/legacy_app_runtime.dart';
import 'services/storage_service.dart';
import 'services/supabase_social_repository.dart';
import 'theme/app_theme.dart';
import 'widgets/canonical_account_gate.dart';
import 'widgets/online_account_access.dart';
import 'services/social_repository.dart';

Future<void> runAccountStartup(OnlineConfig config) async {
  final firebase =
      await HavenFirebase.initialize(HavenFirebaseConfig.fromEnvironment());
  await Supabase.initialize(
      url: config.url, publishableKey: config.publishableKey);
  final support = await getApplicationSupportDirectory();
  runApp(AccountStartupApp(
      config: config,
      auth: Supabase.instance.client,
      directory:
          Directory('${support.path}/canonical-${config.environment.name}-v1'),
      firebaseAvailable: firebase.available,
      diagnostics: firebase.reporter));
}

class AccountStartupApp extends StatefulWidget {
  const AccountStartupApp(
      {super.key,
      required this.config,
      required this.auth,
      required this.directory,
      this.firebaseAvailable = false,
      this.diagnostics = const NoopDiagnosticReporter(),
      this.connectionFactory});
  final OnlineConfig config;
  final SupabaseClient auth;
  final Directory directory;
  final bool firebaseAvailable;
  final DiagnosticReporter diagnostics;
  final CanonicalGameTransport Function()? connectionFactory;
  @override
  State<AccountStartupApp> createState() => _AccountStartupAppState();
}

class _AccountStartupAppState extends State<AccountStartupApp>
    with WidgetsBindingObserver {
  late final CanonicalGameTransport _authority = _connection();
  late final StreamSubscription<int> _accounts;
  AccountSaveReview? _review;
  Completer<AccountSaveChoice?>? _choice;
  bool _fresh = false;
  String _language = 'en';

  CanonicalGameTransport _connection() =>
      widget.connectionFactory?.call() ??
      (widget.config.environment == OnlineEnvironment.production
          ? CanonicalGameTransport.production(widget.auth, widget.config)
          : CanonicalGameTransport.staging(widget.auth, widget.config));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _accounts = _authority.accountChanges.listen((_) => _cancelChoice());
  }

  void _cancelChoice() {
    final pending = _choice;
    _choice = null;
    if (pending != null && !pending.isCompleted) pending.complete(null);
    if (mounted) setState(() => _review = null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _cancelChoice();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final pending = _choice;
    if (pending != null && !pending.isCompleted) pending.complete(null);
    unawaited(_accounts.cancel());
    unawaited(_authority.dispose());
    super.dispose();
  }

  void _requireOwner(String owner, int epoch) {
    if (!mounted ||
        _authority.currentOwner != owner ||
        _authority.sessionEpoch != epoch) {
      throw const CanonicalGameException('game_account_changed');
    }
  }

  Future<CanonicalLegacyAccountSource> _legacy(String owner) async {
    final epoch = _authority.sessionEpoch;
    _requireOwner(owner, epoch);
    final repository = SupabaseSocialRepository(widget.auth,
        sessionIsCurrent: () =>
            mounted &&
            _authority.currentOwner == owner &&
            _authority.sessionEpoch == epoch);
    LegacyAppRuntime? runtime;
    HouseholdProvider? game;
    try {
      var review = await AccountLegacyGameStorage.reviewSources(
          repository: repository,
          owner: owner,
          currentOwner: () => _authority.currentOwner,
          sessionEpoch: () => _authority.sessionEpoch);
      _requireOwner(owner, epoch);
      AccountLegacyGameStorage storage;
      if (!review.needsChoice) {
        storage = (await AccountLegacyGameStorage.open(owner))!;
      } else {
        _fresh = review.local == null && review.cloud == null;
        if (_fresh) {
          final fresh = HouseholdProvider(persistenceEnabled: false);
          try {
            review = review.withFreshState(fresh.exportState());
          } finally {
            fresh.dispose();
          }
        }
        final choice = Completer<AccountSaveChoice?>();
        _choice = choice;
        setState(() {
          _review = review;
          _language =
              (review.local ?? review.cloud)?['languageCode'] as String? ??
                  'en';
        });
        final selected = await choice.future;
        _requireOwner(owner, epoch);
        if (selected == null) {
          throw const CanonicalGameException('game_account_changed');
        }
        storage = await AccountLegacyGameStorage.chooseSource(
            review: review,
            choice: selected,
            repository: repository,
            currentOwner: () => _authority.currentOwner,
            sessionEpoch: () => _authority.sessionEpoch);
      }
      _requireOwner(owner, epoch);
      game = await HouseholdProvider.loadFromStorage(storage: storage);
      _requireOwner(owner, epoch);
      game.persistentSeasonalPreviewRewards =
          widget.config.environment != OnlineEnvironment.production;
      await game.synchronizeNotificationPermissionWithPlatform();
      _requireOwner(owner, epoch);
      runtime = await createLegacyAppRuntime(
          game: game,
          socialRepository: repository,
          auth: widget.auth,
          firebaseAvailable: widget.firebaseAvailable,
          diagnostics: widget.diagnostics,
          accountStorage: storage);
      _requireOwner(owner, epoch);
      final source = CanonicalLegacyAccountSource(
          storage: storage,
          game: game,
          online: runtime.online,
          altar: runtime.altar!,
          repository: repository,
          directory: widget.directory,
          currentOwner: () => _authority.currentOwner,
          sessionEpoch: () => _authority.sessionEpoch,
          deviceId: StorageService.deviceId,
          clientVersion: AppInfo.version,
          beforeClose: runtime.push?.dispose);
      return source;
    } on Object {
      runtime?.push?.dispose();
      if (runtime != null) {
        await runtime.online.stopLegacyOperations();
        await game?.stopAltarOperations();
        await runtime.altar?.stopLegacyOperations();
        runtime.online.dispose();
      } else {
        repository.dispose();
      }
      if (game != null) {
        await game.retireLegacySave();
        game.dispose();
      }
      rethrow;
    }
  }

  Future<CanonicalGameplayLease<Widget>> _openLegacy(String owner) async {
    final source = await _legacy(owner);
    return CanonicalGameplayLease(
        MultiProvider(providers: [
          ChangeNotifierProvider.value(value: source.game),
          ChangeNotifierProvider.value(value: source.online),
        ], child: const DragonHavenApp()),
        close: source.close);
  }

  Future<int> _upload(String owner) async {
    final source = await _legacy(owner);
    try {
      return await source.upload();
    } finally {
      await source.close();
    }
  }

  Future<CanonicalGameplayLease<Widget>> _openServer(
      String owner, int minimum) async {
    final connection = _connection();
    final session = CanonicalGameSession(
        connection: connection,
        directory: widget.directory,
        expectedAuthority: CanonicalGameAuthority.server);
    try {
      await session.synchronize(minimumServerRevision: minimum);
      if (session.snapshot == null || connection.currentOwner != owner) {
        throw const CanonicalGameException('game_snapshot_unavailable');
      }
      final groups = CanonicalGroups(
          connection: connection,
          source: SupabaseCanonicalGroupsSource(widget.auth));
      final partners = CanonicalPartners(
          connection: connection,
          source: SupabaseCanonicalPartnersSource(widget.auth));
      return CanonicalGameplayLease(
          MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: session),
                Provider<CanonicalBeaconSource>.value(
                    value: SupabaseCanonicalBeaconSource(widget.auth)),
                ChangeNotifierProvider.value(value: groups),
                ChangeNotifierProvider.value(value: partners),
              ],
              child: CanonicalStagingApp(
                  session: session,
                  auth: widget.auth,
                  stagingLabel: false)), close: () async {
        groups.dispose();
        partners.dispose();
        await session.close();
      });
    } on Object {
      await session.close();
      rethrow;
    }
  }

  Widget _choiceScreen() {
    final review = _review!;
    final pending = _choice;
    bool current() =>
        mounted &&
        identical(_review, review) &&
        identical(_choice, pending) &&
        pending != null &&
        !pending.isCompleted &&
        review.owner == _authority.currentOwner &&
        review.epoch == _authority.sessionEpoch;
    return AccountSaveChoiceScreen(
        review: review,
        fresh: _fresh,
        onSignOut: () {
          if (!current()) return;
          _cancelChoice();
          unawaited(widget.auth.auth.signOut(scope: SignOutScope.local));
        },
        onChoose: (choice) {
          if (!current()) return;
          _choice = null;
          setState(() => _review = null);
          pending!.complete(choice);
        });
  }

  @override
  Widget build(BuildContext context) => CanonicalAccountGate<Widget>(
        createBootstrap: (beforeRetire) => CanonicalAccountBootstrap(
            directory: widget.directory,
            currentOwner: () => _authority.currentOwner,
            sessionEpoch: () => _authority.sessionEpoch,
            accountChanges: _authority.accountChanges,
            readStatus: (_) => _authority.readAccountStatus(),
            prepareAndUploadLegacy: _upload,
            activate: (_, request, revision) => _authority.migrateAccount(
                requestId: request, sourceRevision: revision),
            openLegacy: _openLegacy,
            openServer: _openServer,
            beforeRetire: beforeRetire),
        gameplayBuilder: (_, gameplay) => gameplay,
        statusBuilder: (_, bootstrap) => MaterialApp(
            key: ValueKey(
                'startup-${_authority.currentOwner}-${_authority.sessionEpoch}'),
            title: 'DragonHaven',
            theme: buildAppTheme(),
            debugShowCheckedModeBanner: false,
            locale: Locale(_language),
            supportedLocales: const [
              Locale('en'),
              Locale('nl'),
              Locale('de'),
              Locale('fr'),
              Locale('es'),
              Locale('it'),
              Locale('pt'),
              Locale('ja')
            ],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: _review != null &&
                    _review!.owner == _authority.currentOwner &&
                    _review!.epoch == _authority.sessionEpoch
                ? _choiceScreen()
                : _StartupStatus(
                    auth: widget.auth,
                    phase: bootstrap.phase,
                    retry: () => unawaited(bootstrap.synchronize()))),
      );
}

class _StartupStatus extends StatefulWidget {
  const _StartupStatus(
      {required this.auth, required this.phase, required this.retry});
  final SupabaseClient auth;
  final CanonicalBootstrapPhase phase;
  final VoidCallback retry;
  @override
  State<_StartupStatus> createState() => _StartupStatusState();
}

class _StartupStatusState extends State<_StartupStatus> {
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _name = TextEditingController();
  bool _busy = false, _register = false;
  String? _message;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final repository = SupabaseSocialRepository(widget.auth);
    try {
      if (_register) {
        final result = await repository.signUp(
            email: _email.text.trim(),
            password: _password.text,
            displayName: _name.text.trim());
        if (result.requiresEmailConfirmation && mounted) {
          setState(() => _message = 'email_not_verified');
        }
      } else {
        await repository.signIn(
            email: _email.text.trim(), password: _password.text);
      }
    } on SocialException catch (error) {
      if (mounted) setState(() => _message = error.code);
    } finally {
      repository.dispose();
      if (mounted) {
        setState(() {
          _password.clear();
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final signedOut = widget.phase == CanonicalBootstrapPhase.signedOut;
    return Scaffold(
        appBar: AppBar(title: const Text('DragonHaven')),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(24),
                        children: [
                          Text(
                              s.pick(
                                  signedOut
                                      ? 'Open your Haven'
                                      : 'Checking your progress',
                                  signedOut
                                      ? 'Open je Haven'
                                      : 'Je voortgang controleren'),
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          if (signedOut) ...[
                            if (_register)
                              TextField(
                                  controller: _name,
                                  enabled: !_busy,
                                  decoration: InputDecoration(
                                      labelText: s.pick(
                                          'Keeper name', 'Bewaardersnaam'))),
                            TextField(
                                controller: _email,
                                enabled: !_busy,
                                autocorrect: false,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                    labelText: s.pick('Email', 'E-mail'))),
                            TextField(
                                controller: _password,
                                enabled: !_busy,
                                obscureText: true,
                                autocorrect: false,
                                enableSuggestions: false,
                                onSubmitted: (_) => _authenticate(),
                                decoration: InputDecoration(
                                    labelText:
                                        s.pick('Password', 'Wachtwoord'))),
                            if (_message != null)
                              Text(socialMessage(s, _message!)),
                            const SizedBox(height: 16),
                            FilledButton(
                                onPressed: _busy ? null : _authenticate,
                                child: Text(s.pick(
                                    _register ? 'Create account' : 'Sign in',
                                    _register ? 'Account maken' : 'Inloggen'))),
                            TextButton(
                                onPressed: _busy
                                    ? null
                                    : () =>
                                        setState(() => _register = !_register),
                                child: Text(s.pick(
                                    _register
                                        ? 'Already have an account?'
                                        : 'Create an account',
                                    _register
                                        ? 'Heb je al een account?'
                                        : 'Een account maken'))),
                          ] else if (widget.phase ==
                              CanonicalBootstrapPhase.failed) ...[
                            Text(s.pick(
                                'Your progress could not be opened safely. Both saves are retained. Check your connection and try again.',
                                'Je voortgang kon niet veilig worden geopend. Beide saves zijn behouden. Controleer je verbinding en probeer opnieuw.')),
                            FilledButton(
                                onPressed: widget.retry,
                                child: Text(
                                    s.pick('Try again', 'Opnieuw proberen'))),
                            TextButton(
                                onPressed: () => widget.auth.auth
                                    .signOut(scope: SignOutScope.local),
                                child: Text(s.pick('Sign out', 'Uitloggen'))),
                          ] else
                            const Center(child: CircularProgressIndicator()),
                        ])))));
  }
}
