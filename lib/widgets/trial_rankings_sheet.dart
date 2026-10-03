import '../models/adventure.dart';
import '../services/canonical_game_snapshot.dart';
import '../services/canonical_game_session.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/social.dart';
import '../models/pet.dart';
import '../models/trial.dart';
import '../providers/online_account_provider.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../theme/event_appearance.dart';
import 'online_account_access.dart';
import 'trial_icon_sprite.dart';

SpecialAdventureWindow? _canonicalRankingWindow(CanonicalGameSnapshot? view) {
  if (view == null) return null;
  final now = view.serverTime;
  final active =
      view.adventures.activeEvents.where((w) => w.contains(now)).firstOrNull;
  if (active != null && active.definition != null) {
    return SpecialAdventureWindow(
        event: active.definition!,
        key: active.key,
        startsAt: active.startsAt,
        endsAt: active.endsAt);
  }
  final candidates = <String, SpecialAdventureWindow>{
    for (final window in specialAdventureRankingWindowsAt(now))
      window.key: window,
    for (final p in view.adventures.eventProgress)
      if (!now.isBefore(p.startsAt) &&
          specialAdventureEventById(p.eventId) != null)
        p.key: SpecialAdventureWindow(
            event: specialAdventureEventById(p.eventId)!,
            key: p.key,
            startsAt: p.startsAt,
            endsAt: p.endsAt),
  }.values.toList()
    ..sort((a, b) {
      final start = b.startsAt.compareTo(a.startsAt);
      return start == 0 ? b.key.compareTo(a.key) : start;
    });
  if (candidates.isEmpty) return null;
  final window = candidates.first;
  if (!now.isBefore(window.endsAt.add(window.event.rankingVisibleAfterEvent))) {
    return null;
  }
  if (view.adventures.eventProgress
      .any((p) => p.key == window.key && p.rankingHidden)) {
    return null;
  }
  if (window.key.contains(':preview:') && now.isBefore(window.endsAt)) {
    return null;
  }
  final dismissed = view.adventures.dismissedEvents[window.event.id];
  if (dismissed != null && !dismissed.isBefore(window.endsAt)) return null;
  return window;
}

String? _currentEventKey(BuildContext context) {
  final server = context.read<CanonicalGameSession?>();
  return server == null
      ? context.read<HouseholdProvider>().trialRankingEventWindow?.key
      : _canonicalRankingWindow(server.snapshot)?.key;
}

Future<void> showTrialRankingsSheet(
  BuildContext context, {
  required List<TrialRankingScope> scopes,
  required TrialRankingScope initialScope,
  TrialKind? initialKind,
}) {
  assert(scopes.isNotEmpty && scopes.contains(initialScope));
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TrialRankingsSheet(
      scopes: scopes,
      initialScope: initialScope,
      initialKind: initialKind,
    ),
  );
}

class _TrialRankingsSheet extends StatefulWidget {
  const _TrialRankingsSheet({
    required this.scopes,
    required this.initialScope,
    this.initialKind,
  });

  final List<TrialRankingScope> scopes;
  final TrialRankingScope initialScope;
  final TrialKind? initialKind;

  @override
  State<_TrialRankingsSheet> createState() => _TrialRankingsSheetState();
}

class _TrialRankingsSheetState extends State<_TrialRankingsSheet> {
  late TrialRankingScope _scope;
  TrialKind _kind = TrialKind.cavernFlight;
  late bool _ascendedSection;
  final Map<(TrialRankingScope, TrialKind), List<TrialRankingEntry>> _cache =
      {};
  List<TrialRankingEntry> _entries = const [];
  bool _loading = false;
  bool _loadScheduledForAccount = false;
  String? _errorCode;
  int _requestRevision = 0;
  String? _eventWindowKey;
  Timer? _expiryTimer;
  Timer? _busyRetry;

  @override
  void initState() {
    super.initState();
    _scope = widget.initialScope;
    _kind = widget.initialKind ?? TrialKind.cavernFlight;
    _ascendedSection = standardTrialKinds.skip(3).contains(_kind);
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _currentEventKey(context) != _eventWindowKey) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _busyRetry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.watch<OnlineAccountProvider>();
    final server = context.watch<CanonicalGameSession?>();
    final hasAscendedDragon = server == null
        ? context
            .watch<HouseholdProvider>()
            .ownedDragons
            .any((dragon) => dragon.stage == DragonStage.ascended)
        : (server.snapshot?.dragons.any((dragon) =>
                dragon.owned && dragon.stage == DragonStage.ascended) ??
            false);
    final eventWindow = server == null
        ? context.watch<HouseholdProvider>().trialRankingEventWindow
        : _canonicalRankingWindow(server.snapshot);
    final eventKey = eventWindow?.key;
    final eventId = eventWindow?.event.id;
    final seasonalKinds = trialDefinitions.values
        .where((d) => d.isSeasonal && d.specialEventId == eventId);
    if (_eventWindowKey != eventKey ||
        (trialDefinitions[_kind]!.isSeasonal &&
            !seasonalKinds.any((d) => d.kind == _kind))) {
      _eventWindowKey = eventKey;
      _cache.clear();
      _entries = const [];
      _errorCode = null;
      _requestRevision++;
      _loading = false;
      _loadScheduledForAccount = false;
      if (trialDefinitions[_kind]!.isSeasonal &&
          !seasonalKinds.any((d) => d.kind == _kind)) {
        _kind = TrialKind.cavernFlight;
        _ascendedSection = false;
      }
    }
    if (!hasAscendedDragon && _ascendedSection) {
      _ascendedSection = false;
      if (standardTrialKinds.skip(3).contains(_kind)) {
        _kind = TrialKind.cavernFlight;
        _cache.clear();
        _entries = const [];
        _loadScheduledForAccount = false;
      }
    }
    if (!online.isSignedIn) {
      _loadScheduledForAccount = false;
    } else if (!_loadScheduledForAccount) {
      _loadScheduledForAccount = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    final height = MediaQuery.sizeOf(context).height * .88;
    return Container(
      key: const Key('trial-rankings-sheet'),
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBF4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _RankingsHeader(
            title: strings.pick('Trial Rankings', 'Trial-ranglijsten'),
            subtitle: _scopeSubtitle(strings, _scope),
            onClose: () => Navigator.pop(context),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height * .47),
            child: SingleChildScrollView(
              key: const Key('trial-ranking-controls'),
              child: Column(
                children: [
                  if (widget.scopes.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
                      child: SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<TrialRankingScope>(
                          key: const Key('trial-ranking-scope-selector'),
                          showSelectedIcon: false,
                          segments: [
                            for (final scope in widget.scopes)
                              ButtonSegment(
                                value: scope,
                                icon: Icon(_scopeIcon(scope), size: 17),
                                label: Text(_scopeLabel(strings, scope)),
                              ),
                          ],
                          selected: {_scope},
                          onSelectionChanged: _loading
                              ? null
                              : (selection) {
                                  final next = selection.first;
                                  if (next == _scope) return;
                                  setState(() => _scope = next);
                                  _load();
                                },
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 13, bottom: 11),
                    child: _TrialKindSelector(
                      selectedKind: _kind,
                      showAscended: hasAscendedDragon,
                      ascendedSection: _ascendedSection,
                      onSectionSelected: _loading
                          ? null
                          : (ascended) {
                              if (ascended == _ascendedSection) return;
                              final kind = ascended
                                  ? standardTrialKinds[3]
                                  : standardTrialKinds.first;
                              setState(() {
                                _ascendedSection = ascended;
                                _kind = kind;
                              });
                              _load();
                            },
                      onSelected: _loading
                          ? null
                          : (kind) {
                              if (kind == _kind) return;
                              setState(() {
                                _kind = kind;
                                _ascendedSection =
                                    standardTrialKinds.skip(3).contains(kind);
                              });
                              _load();
                            },
                    ),
                  ),
                  for (final trial in seasonalKinds)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      child: _EventTrialChoice(
                        kind: trial.kind,
                        eventId: trial.specialEventId!,
                        selected: _kind == trial.kind,
                        label: _trialLabel(strings, trial.kind),
                        onTap: () {
                          if (_loading || _kind == trial.kind) return;
                          setState(() => _kind = trial.kind);
                          _load();
                        },
                      ),
                    ),
                  if (trialDefinitions[_kind]!.isSeasonal)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      child: Text(
                        strings.pick(
                          'Best Trial score. Results stay visible for 3 days after the event.',
                          'Beste Trialscore. Resultaten blijven tot 3 dagen na het event zichtbaar.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: !online.isSignedIn
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
                    children: const [OnlineAccountAccessCard()],
                  )
                : _RankingBody(
                    entries: _entries,
                    loading: _loading,
                    errorCode: _errorCode,
                    supportCode: online.supportCode,
                    onRetry: () => _load(force: true),
                    scope: _scope,
                    kind: _kind,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _load({bool force = false}) async {
    final online = context.read<OnlineAccountProvider>();
    if (!online.isSignedIn || _loading) return;
    if (online.busy) {
      _retryWhenOnlineOperationSettles(force: force);
      return;
    }
    _busyRetry?.cancel();
    _busyRetry = null;
    final key = (_scope, _kind);
    final cached = _cache[key];
    if (!force && cached != null) {
      setState(() {
        _entries = cached;
        _errorCode = null;
      });
      return;
    }
    final revision = ++_requestRevision;
    setState(() {
      _loading = true;
      _errorCode = null;
    });
    final result = await online.loadTrialRankings(
      trialKey: _kind.name,
      scope: _scope,
    );
    if (!mounted || revision != _requestRevision) return;
    if (result == null && online.errorCode == null) {
      setState(() => _loading = false);
      _retryWhenOnlineOperationSettles(force: true);
      return;
    }
    setState(() {
      _loading = false;
      if (result == null) {
        _errorCode = online.errorCode ?? 'online_server_error';
      } else {
        _cache[key] = result;
        _entries = result;
      }
    });
  }

  void _retryWhenOnlineOperationSettles({required bool force}) {
    _busyRetry?.cancel();
    _busyRetry = Timer(const Duration(milliseconds: 150), () {
      if (mounted) _load(force: force);
    });
  }
}

class _RankingsHeader extends StatelessWidget {
  const _RankingsHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A1E50), Color(0xFF7652A5)],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.leaderboard_rounded,
                color: AppColors.eventColor(context, AppColors.twilightDark),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE6DCF4),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ],
        ),
      );
}

class _EventTrialChoice extends StatelessWidget {
  const _EventTrialChoice(
      {required this.kind,
      required this.eventId,
      required this.selected,
      required this.label,
      required this.onTap});

  final TrialKind kind;
  final String eventId, label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = EventAppearance.forEvent(eventId);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: theme.primary,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            image: theme.background == null
                ? null
                : DecorationImage(
                    image: AssetImage(theme.background!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: .35), BlendMode.darken)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: selected
                    ? AppColors.gold
                    : theme.accent.withValues(alpha: .6),
                width: 2),
            gradient: LinearGradient(colors: theme.panelColors),
          ),
          child: InkWell(
            key: Key('trial-ranking-kind-${kind.name}'),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                theme.primary.withValues(alpha: .9),
                Colors.transparent
              ])),
              child: Row(children: [
                TrialIconSprite(kind: kind, size: 46),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(blurRadius: 5, color: Colors.black54)
                            ]))),
                const SizedBox(width: 8),
                Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.leaderboard_rounded,
                    color: AppColors.gold,
                    size: 26),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrialKindSelector extends StatelessWidget {
  const _TrialKindSelector({
    required this.selectedKind,
    required this.showAscended,
    required this.ascendedSection,
    required this.onSectionSelected,
    required this.onSelected,
  });

  final TrialKind selectedKind;
  final bool showAscended;
  final bool ascendedSection;
  final ValueChanged<bool>? onSectionSelected;
  final ValueChanged<TrialKind>? onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Padding(
      key: const Key('trial-ranking-kind-selector'),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          if (showAscended) ...[
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                key: const Key('trial-ranking-tier-selector'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.auto_awesome_outlined, size: 17),
                    label: Text(strings.pick('Basic', 'Basis')),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.workspace_premium_rounded, size: 17),
                    label: Text(strings.pick('Ascended', 'Ascended')),
                  ),
                ],
                selected: {ascendedSection},
                onSelectionChanged: onSectionSelected == null
                    ? null
                    : (selection) => onSectionSelected!(selection.first),
              ),
            ),
            const SizedBox(height: 9),
          ] else
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  strings.pick('Basic trials', 'Basis-trials'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final kind in (ascendedSection && showAscended
                    ? standardTrialKinds.skip(3)
                    : standardTrialKinds.take(3))) ...[
                  if (kind !=
                      (ascendedSection && showAscended
                          ? standardTrialKinds[3]
                          : standardTrialKinds.first))
                    const SizedBox(width: 8),
                  Expanded(
                    child: _TrialChoice(
                      kind: kind,
                      selected: kind == selectedKind,
                      label: _trialLabel(strings, kind),
                      onTap:
                          onSelected == null ? null : () => onSelected!(kind),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrialChoice extends StatelessWidget {
  const _TrialChoice({
    required this.kind,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final TrialKind kind;
  final bool selected;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        enabled: onTap != null,
        button: true,
        child: Material(
          color: selected
              ? AppColors.eventColor(context, AppColors.twilightDark)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('trial-ranking-kind-${kind.name}'),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 80),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? AppColors.gold
                      : AppColors.eventColor(context, const Color(0xFFE1D8EA)),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                      child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      TrialIconSprite(kind: kind, size: 34),
                      if (selected)
                        const Positioned(
                            top: -2,
                            right: -7,
                            child: Icon(Icons.check_circle_rounded,
                                color: AppColors.gold, size: 16)),
                    ],
                  )),
                  const SizedBox(height: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 28),
                    child: Center(
                        child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.ink,
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _RankingBody extends StatefulWidget {
  const _RankingBody({
    required this.entries,
    required this.loading,
    required this.errorCode,
    required this.supportCode,
    required this.onRetry,
    required this.scope,
    required this.kind,
  });

  final List<TrialRankingEntry> entries;
  final bool loading;
  final String? errorCode;
  final String? supportCode;
  final Future<void> Function() onRetry;
  final TrialRankingScope scope;
  final TrialKind kind;

  @override
  State<_RankingBody> createState() => _RankingBodyState();
}

class _RankingBodyState extends State<_RankingBody> {
  final ScrollController _controller = ScrollController();
  final GlobalKey _currentUserKey = GlobalKey();
  String? _centeredSignature;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scheduleCenter() {
    final index = widget.entries.indexWhere((entry) => entry.isCurrentUser);
    if (index < 0) return;
    final signature = '${widget.scope.name}:${widget.kind.name}:'
        '${widget.entries.map((entry) => entry.entryKey).join(',')}';
    if (_centeredSignature == signature) return;
    _centeredSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      const estimatedExtent = 87.0;
      final position = _controller.position;
      final target =
          (index * estimatedExtent - (position.viewportDimension - 80) / 2)
              .clamp(position.minScrollExtent, position.maxScrollExtent);
      _controller.jumpTo(target.toDouble());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentContext = _currentUserKey.currentContext;
        if (!mounted || currentContext == null) return;
        Scrollable.ensureVisible(
          currentContext,
          alignment: .5,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.errorCode case final code?) {
      return _RankingMessage(
        icon: Icons.cloud_off_rounded,
        title: strings.pick(
          'Rankings could not be loaded',
          'Ranglijsten konden niet worden geladen',
        ),
        body: socialMessage(strings, code, supportCode: widget.supportCode),
        actionLabel: strings.pick('Try again', 'Opnieuw proberen'),
        onAction: () => widget.onRetry(),
      );
    }
    if (widget.entries.isEmpty) {
      return _RankingMessage(
        icon: Icons.emoji_events_outlined,
        title: strings.pick('No scores yet', 'Nog geen scores'),
        body: strings.pick(
          'Complete this Trial to place the first score in this ranking.',
          'Voltooi deze Trial om de eerste score in deze ranglijst te plaatsen.',
        ),
      );
    }
    _scheduleCenter();
    return RefreshIndicator(
      onRefresh: widget.onRetry,
      child: ListView.separated(
        key: Key('trial-ranking-list-${widget.scope.name}-${widget.kind.name}'),
        controller: _controller,
        padding: const EdgeInsets.fromLTRB(14, 1, 14, 28),
        itemCount: widget.entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 7),
        itemBuilder: (context, index) {
          final entry = widget.entries[index];
          return KeyedSubtree(
            key: entry.isCurrentUser ? _currentUserKey : null,
            child: _RankingRow(entry: entry),
          );
        },
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry});

  final TrialRankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final podiumColor = switch (entry.position) {
      1 => const Color(0xFFF4C95D),
      2 => const Color(0xFFC8CBD3),
      3 => const Color(0xFFD69B70),
      _ => AppColors.eventColor(context, const Color(0xFFE9E0F5)),
    };
    final stackScore = MediaQuery.sizeOf(context).width /
            MediaQuery.textScalerOf(context).scale(1) <
        300;
    final score = Column(
      crossAxisAlignment:
          stackScore ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text('${entry.score}',
            key: Key('trial-ranking-score-${entry.entryKey}'),
            style: TextStyle(
                color: AppColors.eventColor(context, AppColors.twilight),
                fontSize: 17,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()])),
        Text(strings.pick('points', 'punten'),
            style: const TextStyle(
                color: AppColors.muted,
                fontSize: 8.5,
                fontWeight: FontWeight.w800)),
      ],
    );
    return Semantics(
      label:
          '${entry.position}. ${entry.displayName}, ${entry.score} ${strings.pick('points', 'punten')}',
      child: Container(
        key: Key('trial-ranking-entry-${entry.entryKey}'),
        padding: const EdgeInsets.fromLTRB(8, 8, 11, 8),
        decoration: BoxDecoration(
          color: entry.isCurrentUser ? const Color(0xFFFFF7D7) : Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: entry.isCurrentUser
                ? const Color(0xFFD8AA2B)
                : AppColors.eventColor(context, const Color(0xFFE2DBE9)),
            width: entry.isCurrentUser ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: podiumColor,
                shape: BoxShape.circle,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    '#${entry.position}',
                    style: TextStyle(
                      color:
                          AppColors.eventColor(context, AppColors.twilightDark),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            SizedBox.square(
              dimension: 64,
              child: Center(
                child: KeeperPortrait(
                  portraitKey: entry.portraitKey,
                  displayName: entry.displayName,
                  radius: 20,
                  frameKey: entry.frameKey,
                  badgeKey: entry.badgeKey,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (entry.isCurrentUser) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            strings.pick('You', 'Jij'),
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    keeperTitleLabel(strings, entry.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (stackScore) ...[const SizedBox(height: 4), score],
                ],
              ),
            ),
            if (!stackScore) ...[const SizedBox(width: 7), score],
          ],
        ),
      ),
    );
  }
}

class _RankingMessage extends StatelessWidget {
  const _RankingMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(icon,
                  size: 64,
                  color: AppColors.eventColor(context, AppColors.twilight)),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      );
}

String _trialLabel(AppStrings strings, TrialKind kind) {
  final definition = trialDefinitions[kind]!;
  return strings.pick(definition.titleEn, definition.titleNl);
}

String _scopeLabel(AppStrings strings, TrialRankingScope scope) =>
    switch (scope) {
      TrialRankingScope.world => strings.pick('World', 'Wereld'),
      TrialRankingScope.friends => strings.pick('Friends', 'Vrienden'),
      TrialRankingScope.conclave => 'Conclave',
    };

String _scopeSubtitle(AppStrings strings, TrialRankingScope scope) =>
    switch (scope) {
      TrialRankingScope.world => strings.pick(
          'The strongest published Keeper records worldwide.',
          'De sterkste gepubliceerde Keeper-records wereldwijd.',
        ),
      TrialRankingScope.friends => strings.pick(
          'Compare your best score with your friends.',
          'Vergelijk je beste score met je vrienden.',
        ),
      TrialRankingScope.conclave => strings.pick(
          'Every scored Keeper in your Conclave.',
          'Iedere Keeper met een score in jouw Conclave.',
        ),
    };

IconData _scopeIcon(TrialRankingScope scope) => switch (scope) {
      TrialRankingScope.world => Icons.public_rounded,
      TrialRankingScope.friends => Icons.people_alt_rounded,
      TrialRankingScope.conclave => Icons.shield_rounded,
    };
