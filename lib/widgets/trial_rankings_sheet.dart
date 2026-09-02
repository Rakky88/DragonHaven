import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/social.dart';
import '../models/trial.dart';
import '../providers/online_account_provider.dart';
import '../theme/app_theme.dart';
import 'online_account_access.dart';
import 'trial_icon_sprite.dart';

Future<void> showTrialRankingsSheet(
  BuildContext context, {
  required List<TrialRankingScope> scopes,
  required TrialRankingScope initialScope,
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
    ),
  );
}

class _TrialRankingsSheet extends StatefulWidget {
  const _TrialRankingsSheet({
    required this.scopes,
    required this.initialScope,
  });

  final List<TrialRankingScope> scopes;
  final TrialRankingScope initialScope;

  @override
  State<_TrialRankingsSheet> createState() => _TrialRankingsSheetState();
}

class _TrialRankingsSheetState extends State<_TrialRankingsSheet> {
  late TrialRankingScope _scope;
  TrialKind _kind = TrialKind.cavernFlight;
  final Map<(TrialRankingScope, TrialKind), List<TrialRankingEntry>> _cache =
      {};
  List<TrialRankingEntry> _entries = const [];
  bool _loading = false;
  bool _loadScheduledForAccount = false;
  String? _errorCode;
  int _requestRevision = 0;

  @override
  void initState() {
    super.initState();
    _scope = widget.initialScope;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.watch<OnlineAccountProvider>();
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
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
            child: Row(
              children: [
                for (final kind in TrialKind.values) ...[
                  if (kind != TrialKind.values.first) const SizedBox(width: 7),
                  Expanded(
                    child: _TrialChoice(
                      kind: kind,
                      selected: kind == _kind,
                      label: _trialLabel(strings, kind),
                      onTap: () {
                        if (_loading || kind == _kind) return;
                        setState(() => _kind = kind);
                        _load();
                      },
                    ),
                  ),
                ],
              ],
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
              child: const Icon(
                Icons.leaderboard_rounded,
                color: AppColors.twilightDark,
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? const Color(0xFFEDE1FF) : Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          key: Key('trial-ranking-kind-${kind.name}'),
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(5, 7, 5, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected ? AppColors.twilight : const Color(0xFFE1D8EA),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                TrialIconSprite(kind: kind, size: 35),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? AppColors.twilightDark : AppColors.ink,
                    fontSize: 9.5,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RankingBody extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorCode case final code?) {
      return _RankingMessage(
        icon: Icons.cloud_off_rounded,
        title: strings.pick(
          'Rankings could not be loaded',
          'Ranglijsten konden niet worden geladen',
        ),
        body: socialMessage(strings, code, supportCode: supportCode),
        actionLabel: strings.pick('Try again', 'Opnieuw proberen'),
        onAction: () => onRetry(),
      );
    }
    if (entries.isEmpty) {
      return _RankingMessage(
        icon: Icons.emoji_events_outlined,
        title: strings.pick('No scores yet', 'Nog geen scores'),
        body: strings.pick(
          'Complete this Trial to place the first score in this ranking.',
          'Voltooi deze Trial om de eerste score in deze ranglijst te plaatsen.',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRetry,
      child: ListView.separated(
        key: Key('trial-ranking-list-${scope.name}-${kind.name}'),
        padding: const EdgeInsets.fromLTRB(14, 1, 14, 28),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 7),
        itemBuilder: (context, index) => _RankingRow(entry: entries[index]),
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
      _ => const Color(0xFFE9E0F5),
    };
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
                : const Color(0xFFE2DBE9),
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
                    style: const TextStyle(
                      color: AppColors.twilightDark,
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
                ],
              ),
            ),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.score}',
                  key: Key('trial-ranking-score-${entry.entryKey}'),
                  style: const TextStyle(
                    color: AppColors.twilight,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  strings.pick('points', 'punten'),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
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
              Icon(icon, size: 64, color: AppColors.twilight),
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
