import 'widgets/shop_economy_scope.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_info.dart';
import 'server_dragonhaven_app.dart';
import 'config/firebase_config.dart';
import 'config/online_config.dart';
import 'dragonhaven_app.dart';
import 'l10n/app_strings.dart';
import 'providers/household_provider.dart';
import 'providers/online_account_provider.dart';
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
import 'services/firebase_push.dart';
import 'services/server_game_notifications.dart';
import 'services/diagnostic_reporter.dart';
import 'services/legacy_app_runtime.dart';
import 'services/storage_service.dart';
import 'services/supabase_social_repository.dart';
import 'theme/app_theme.dart';
import 'widgets/canonical_account_gate.dart';
import 'widgets/online_account_access.dart';
import 'services/social_repository.dart';
import 'services/privacy_notice.dart';
import 'services/release_service.dart';
import 'services/platform_actions.dart';
import 'services/canonical_account_handoff.dart';
import 'config/rewarded_ads_config.dart';
import 'services/canonical_rewarded_ads.dart';
import 'services/rewarded_ads_platform.dart';
import 'services/rewarded_ads_repository.dart';
import 'screens/privacy_screen.dart';
import 'widgets/startup_splash.dart';

Future<void> runAccountStartup(OnlineConfig config) async {
  if (!config.isConfigured) {
    runApp(MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(
            body: SafeArea(
                child: Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'DragonHaven requires an online connection and a configured server. Please install the official app.')))))));
    return;
  }
  final firebase =
      await HavenFirebase.initialize(HavenFirebaseConfig.fromEnvironment());
  if (firebase.available) {
    unawaited(FirebaseNotificationNavigation.initialize());
  }
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
  Completer<void>? _privacy;
  String? _privacyOwner;
  int? _privacyEpoch;
  bool _fresh = false;
  String _language =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'nl'
          ? 'nl'
          : 'en';

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
    final privacy = _privacy;
    _privacy = null;
    _privacyOwner = null;
    if (privacy != null && !privacy.isCompleted) {
      privacy
          .completeError(const CanonicalGameException('game_account_changed'));
    }
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
    final privacy = _privacy;
    if (privacy != null && !privacy.isCompleted) {
      privacy
          .completeError(const CanonicalGameException('game_account_changed'));
    }
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

  Future<CanonicalAccountStatus> _readStatus(String owner) async {
    final epoch = _authority.sessionEpoch;
    final status = await _authority.readAccountStatus();
    _requireOwner(owner, epoch);
    final accepted = await widget.auth
        .rpc('get_my_privacy_acknowledgement')
        .timeout(const Duration(seconds: 8));
    _requireOwner(owner, epoch);
    if (accepted != true) {
      final metadata = widget.auth.auth.currentUser?.userMetadata;
      if (metadata?['privacy_notice_version'] == PrivacyNotice.version &&
          metadata?['age_16_confirmed'] == true) {
        // The registration form already collected these two choices. Record
        // that self-declaration only after the email is verified; it is not
        // identity-verified proof of age or authorization for diagnostics.
        final recorded =
            await widget.auth.rpc('acknowledge_my_privacy_notice', params: {
          'p_version': PrivacyNotice.version,
          'p_age_16_confirmed': true,
        }).timeout(const Duration(seconds: 8));
        _requireOwner(owner, epoch);
        if (recorded != true) {
          throw const CanonicalGameException('game_migration_unavailable');
        }
        return status;
      }
      final pending = Completer<void>();
      setState(() {
        _privacy = pending;
        _privacyOwner = owner;
        _privacyEpoch = epoch;
      });
      await pending.future;
      _requireOwner(owner, epoch);
      // No cached authority may open the game after a lengthy notice review.
      return _authority.readAccountStatus();
    }
    return status;
  }

  Future<void> _acknowledgePrivacy() async {
    final pending = _privacy;
    final owner = _privacyOwner;
    final epoch = _privacyEpoch;
    if (pending == null || owner == null || epoch == null) return;
    _requireOwner(owner, epoch);
    final accepted =
        await widget.auth.rpc('acknowledge_my_privacy_notice', params: {
      'p_version': PrivacyNotice.version,
      'p_age_16_confirmed': true,
    }).timeout(const Duration(seconds: 8));
    _requireOwner(owner, epoch);
    if (accepted != true || !identical(_privacy, pending)) {
      throw const CanonicalGameException('game_account_changed');
    }
    setState(() {
      _privacy = null;
      _privacyOwner = null;
    });
    pending.complete();
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
      } else if (review.local == null && review.cloud != null) {
        // A new installation has no competing progress. Load its account's
        // confirmed server copy without presenting a needless save chooser.
        // chooseSource rechecks owner, session and revision before writing.
        storage = await AccountLegacyGameStorage.chooseSource(
            review: review,
            choice: AccountSaveChoice.cloud,
            repository: repository,
            currentOwner: () => _authority.currentOwner,
            sessionEpoch: () => _authority.sessionEpoch);
      } else {
        _fresh = review.local == null && review.cloud == null;
        if (_fresh) {
          final fresh = HouseholdProvider(persistenceEnabled: false);
          fresh.languageCode = _language;
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
    final epoch = _authority.sessionEpoch;
    final repository = SupabaseSocialRepository(widget.auth);
    try {
      final review = await AccountLegacyGameStorage.reviewSources(
          repository: repository,
          owner: owner,
          currentOwner: () => _authority.currentOwner,
          sessionEpoch: () => _authority.sessionEpoch);
      _requireOwner(owner, epoch);
      // Zero is a handoff-only marker for trusted server creation, never an
      // upload revision. A failed cloud read cannot reach this branch.
      if (review.local == null && review.cloud == null) return 0;
    } finally {
      repository.dispose();
    }
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
    OnlineAccountProvider? online;
    CanonicalGroups? groups;
    CanonicalPartners? partners;
    CanonicalRewardedAds? rewardedAds;
    FirebasePushCoordinator? push;
    ServerGameNotifications? notifications;
    try {
      await session.synchronize(minimumServerRevision: minimum);
      if (session.snapshot == null || connection.currentOwner != owner) {
        throw const CanonicalGameException('game_snapshot_unavailable');
      }
      groups = CanonicalGroups(
          connection: connection,
          source: SupabaseCanonicalGroupsSource(widget.auth));
      partners = CanonicalPartners(
          connection: connection,
          source: SupabaseCanonicalPartnersSource(widget.auth));
      online = OnlineAccountProvider(
          repository: SupabaseSocialRepository(widget.auth),
          serverOwned: true,
          inventorySnapshot: () =>
              throw const SocialException('game_server_authority_required'),
          languageCode: () =>
              session.snapshot?.profile.preferences['languageCode']
                  as String? ??
              'en',
          prepareAccountExit: () async {
            await push?.unregisterBeforeSignOut();
          },
          accountExitFinished: () => push?.afterSignOutAttempt(),
          diagnostics: widget.diagnostics);
      await online.initialize();
      if (connection.currentOwner != owner || session.snapshot == null) {
        throw const CanonicalGameException('game_account_changed');
      }
      rewardedAds = CanonicalRewardedAds(
        session: session,
        repository: SupabaseRewardedAdsRepository(widget.auth),
        platform: GoogleRewardedAdsPlatform(),
        config: RewardedAdsConfig.fromEnvironment(),
      );
      unawaited(rewardedAds.initialize());
      notifications = ServerGameNotifications(session);
      if (widget.firebaseAvailable) {
        push = FirebasePushCoordinator.server(session, online, widget.auth);
      }
      final ownedOnline = online,
          ownedGroups = groups,
          ownedPartners = partners,
          ownedRewardedAds = rewardedAds;
      return CanonicalGameplayLease(
          MultiProvider(providers: [
            ChangeNotifierProvider.value(value: session),
            Provider<CanonicalBeaconSource>.value(
                value: SupabaseCanonicalBeaconSource(widget.auth)),
            ChangeNotifierProvider.value(value: groups),
            ChangeNotifierProvider.value(value: partners),
            ChangeNotifierProvider.value(value: online),
            ChangeNotifierProvider.value(value: rewardedAds),
          ], child: ServerDragonHavenApp(auth: widget.auth)), quiesce: () {
        unawaited(ownedOnline.stopLegacyOperations());
      }, close: () async {
        push?.dispose();
        final stopOnline = ownedOnline.stopLegacyOperations();
        await notifications?.close();
        await stopOnline;
        ownedOnline.dispose();
        ownedGroups.dispose();
        ownedPartners.dispose();
        ownedRewardedAds.dispose();
        await session.close();
      });
    } on Object {
      push?.dispose();
      await notifications?.close();
      online?.dispose();
      groups?.dispose();
      partners?.dispose();
      rewardedAds?.dispose();
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
            readStatus: _readStatus,
            checkConnection: (_) => _authority.readAccountStatus(),
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
            home: _privacy != null &&
                    _privacyOwner == _authority.currentOwner &&
                    _privacyEpoch == _authority.sessionEpoch
                ? PrivacyScreen(
                    onAcknowledge: _acknowledgePrivacy,
                    onSignOut: () => unawaited(
                        widget.auth.auth.signOut(scope: SignOutScope.local)))
                : _review != null &&
                        _review!.owner == _authority.currentOwner &&
                        _review!.epoch == _authority.sessionEpoch
                    ? _choiceScreen()
                    : _StartupStatus(
                        auth: widget.auth,
                        phase: bootstrap.phase,
                        errorCode: bootstrap.errorCode,
                        retry: () => unawaited(bootstrap.synchronize()))),
      );
}

class _StartupStatus extends StatefulWidget {
  const _StartupStatus(
      {required this.auth,
      required this.phase,
      required this.retry,
      this.errorCode});
  final String? errorCode;
  final SupabaseClient auth;
  final CanonicalBootstrapPhase phase;
  final VoidCallback retry;
  @override
  State<_StartupStatus> createState() => _StartupStatusState();
}

class _StartupStatusState extends State<_StartupStatus> {
  final _email = TextEditingController(), _password = TextEditingController();
  bool _busy = false, _register = true, _age = false, _read = false;
  String? _message;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_busy || (_register && (!_age || !_read))) return;
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
            displayName: 'Keeper',
            acknowledgedPrivacyVersion: PrivacyNotice.version);
        if (result.requiresEmailConfirmation && mounted) {
          setState(() {
            _message = 'email_not_verified';
            _register = false;
          });
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

  Future<void> _resend() async {
    if (_busy || _email.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final repository = SupabaseSocialRepository(widget.auth);
    try {
      await repository.resendSignupConfirmation(_email.text.trim());
      if (mounted) setState(() => _message = 'email_not_verified');
    } on SocialException catch (error) {
      if (mounted) setState(() => _message = error.code);
    } finally {
      repository.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final signedOut = widget.phase == CanonicalBootstrapPhase.signedOut;
    if (!signedOut && widget.phase != CanonicalBootstrapPhase.failed) {
      return const StartupSplash();
    }
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
                          if (signedOut) ...[
                            Center(
                                child: Image.asset(
                                    'assets/images/dragonhaven_logo.png',
                                    width: 76,
                                    height: 76,
                                    fit: BoxFit.contain)),
                            const SizedBox(height: 16),
                          ],
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
                            Text(s.pick(
                                'An online game for ages 16+. Create and verify your account first, then choose your keeper name and claim your starter egg.',
                                'Een online spel voor 16+. Maak eerst een account en bevestig je e-mail. Daarna kies je je spelersnaam en krijg je je starterei.')),
                            const SizedBox(height: 16),
                            TextField(
                                key: const Key('startup-email'),
                                controller: _email,
                                enabled: !_busy,
                                autocorrect: false,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                    labelText: s.pick('Email', 'E-mail'))),
                            TextField(
                                key: const Key('startup-password'),
                                controller: _password,
                                enabled: !_busy,
                                obscureText: true,
                                autocorrect: false,
                                enableSuggestions: false,
                                onSubmitted: (_) => _authenticate(),
                                decoration: InputDecoration(
                                    labelText: s.pick('Password', 'Wachtwoord'),
                                    helperText: _register
                                        ? s.pick(
                                            'At least 8 characters, with uppercase, lowercase, a number and a symbol.',
                                            'Minimaal 8 tekens, met hoofdletter, kleine letter, cijfer en symbool.')
                                        : null,
                                    helperMaxLines: 3)),
                            TextButton(
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                        builder: (_) => const PrivacyScreen(
                                            showPreferences: false))),
                                child: Text(s.pick('Read the privacy notice',
                                    'Lees de privacyverklaring'))),
                            if (_register) ...[
                              CheckboxListTile(
                                  value: _age,
                                  key: const Key('signup-age'),
                                  onChanged: _busy
                                      ? null
                                      : (v) =>
                                          setState(() => _age = v ?? false),
                                  title: Text(s.pick('I am 16 or older.',
                                      'Ik ben 16 jaar of ouder.'))),
                              CheckboxListTile(
                                  value: _read,
                                  key: const Key('signup-notice'),
                                  onChanged: _busy
                                      ? null
                                      : (v) =>
                                          setState(() => _read = v ?? false),
                                  title: Text(s.pick(
                                      'I have read the privacy notice.',
                                      'Ik heb de privacyverklaring gelezen.'))),
                            ],
                            if (_message != null)
                              Text(socialMessage(s, _message!)),
                            const SizedBox(height: 16),
                            FilledButton(
                                key: const Key('startup-authenticate'),
                                onPressed:
                                    _busy || (_register && (!_age || !_read))
                                        ? null
                                        : _authenticate,
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
                            if (_message == 'email_not_verified')
                              TextButton(
                                  onPressed: _busy ? null : _resend,
                                  child: Text(s.pick(
                                      'Resend confirmation email',
                                      'Bevestigingsmail opnieuw sturen'))),
                          ] else if (widget.phase ==
                              CanonicalBootstrapPhase.failed) ...[
                            if (widget.errorCode ==
                                'game_client_upgrade_required') ...[
                              Text(s.pick(
                                  'A newer version of DragonHaven is ready.',
                                  'Er staat een nieuwere versie van DragonHaven klaar.')),
                              FilledButton.icon(
                                  icon: const Icon(Icons.download_rounded),
                                  label: Text(s.pick('Update', 'Updaten')),
                                  onPressed: () async {
                                    try {
                                      await PlatformActions.openUrl(
                                          ReleaseConfig.downloadUrl);
                                    } catch (_) {
                                      await PlatformActions.copyText(
                                          ReleaseConfig.downloadUrl);
                                    }
                                  }),
                            ] else if (widget.errorCode != null &&
                                !const {
                                  'game_command_unavailable',
                                  'game_read_unavailable',
                                  'game_auth_unavailable',
                                  'game_migration_unavailable'
                                }.contains(widget.errorCode))
                              Text(gameConnectionMessage(s, widget.errorCode!))
                            else
                              Text(s.pick(
                                  'DragonHaven needs a connection to the server. Your saved progress is kept. Check your internet connection; we will try again automatically.',
                                  'DragonHaven heeft verbinding met de server nodig. Je opgeslagen voortgang blijft bewaard. Controleer je internetverbinding; we proberen het automatisch opnieuw.')),
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
