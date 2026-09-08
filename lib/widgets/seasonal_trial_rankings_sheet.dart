import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/dragon_emote.dart';
import '../models/social.dart';
import '../providers/online_account_provider.dart';
import '../theme/app_theme.dart';

Future<void> showSeasonalTrialRankingsSheet(
  BuildContext context, {
  required SpecialAdventureEventDefinition event,
  required bool preview,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SeasonalRankingsSheet(event: event, preview: preview),
    );

class _SeasonalRankingsSheet extends StatefulWidget {
  const _SeasonalRankingsSheet({required this.event, required this.preview});

  final SpecialAdventureEventDefinition event;
  final bool preview;

  @override
  State<_SeasonalRankingsSheet> createState() => _SeasonalRankingsSheetState();
}

class _SeasonalRankingsSheetState extends State<_SeasonalRankingsSheet> {
  List<SeasonalTrialRankingEntry> _entries = const [];
  var _loading = true;
  String? _error;

  String _occurrenceKey(DateTime now, String? userId) {
    if (widget.preview) {
      return 'preview:${widget.event.id}:${userId ?? ''}';
    }
    var year = now.year;
    if (widget.event.id == 'new_year_first_dawn' && now.month == 1) year--;
    return '${widget.event.id}:$year';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final online = context.read<OnlineAccountProvider>();
    if (!online.isSignedIn) {
      setState(() {
        _loading = false;
        _error = 'online_login_required';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await online.loadSeasonalTrialRankings(
      eventId: widget.event.id,
      occurrenceKey: _occurrenceKey(DateTime.now(), online.currentUserId),
      preview: widget.preview,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _entries = result ?? const [];
      _error = result == null ? online.errorCode : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final eventSlug = switch (widget.event.id) {
      'halloween_witchlight' => 'halloween',
      'christmas_winter_hearth' => 'christmas',
      'new_year_first_dawn' => 'new_year',
      'valentine_two_heartlights' => 'valentine',
      _ => 'pride',
    };
    final visual = _SeasonalRankingVisual.forSlug(eventSlug);
    return Container(
      height: MediaQuery.sizeOf(context).height * .88,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBF4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 15, 8, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [visual.deep, visual.accent],
              ),
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/events/$eventSlug/trial_background.webp',
                ),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                colorFilter: ColorFilter.mode(
                  visual.deep.withValues(alpha: .66),
                  BlendMode.srcOver,
                ),
              ),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/events/$eventSlug/trial_icon.webp',
                  width: 58,
                  height: 58,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.pick(
                            widget.event.titleEn, widget.event.titleNl),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        widget.preview
                            ? strings.pick(
                                'Private test ranking', 'PrivÃ©-testranglijst')
                            : strings.pick(
                                'World ranking Â· results remain visible for 5 days',
                                'Wereldranglijst Â· resultaten blijven 5 dagen zichtbaar',
                              ),
                        style: const TextStyle(
                          color: Color(0xFFE7DCF7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(child: _body(strings, eventSlug)),
        ],
      ),
    );
  }

  Widget _body(AppStrings strings, String eventSlug) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/events/$eventSlug/trial_icon.webp',
                width: 92,
                height: 92,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 10),
              Text(
                strings.pick('Rankings could not be loaded.',
                    'De ranglijst kon niet worden geladen.'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _load,
                child: Text(strings.pick('Try again', 'Opnieuw proberen')),
              ),
            ],
          ),
        ),
      );
    }
    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/events/$eventSlug/trial_icon.webp',
                width: 116,
                height: 116,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 10),
              Text(
                strings.pick(
                  'No official score yet. Be the first light on the board!',
                  'Nog geen officiÃ«le score. Zet het eerste licht op het bord!',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.twilightDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final chronicle = context
        .watch<OnlineAccountProvider>()
        .seasonalChronicle
        .where((entry) => entry.eventId == widget.event.id)
        .toList(growable: false);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 15, 14, 28),
        itemCount: _entries.length + (chronicle.isEmpty ? 0 : 1),
        itemBuilder: (_, index) {
          if (index == _entries.length) {
            return _SeasonalChronicleCard(
              entries: chronicle,
              eventSlug: eventSlug,
            );
          }
          final entry = _entries[index];
          final medal = entry.position <= 3
              ? switch (entry.position) {
                  1 => 'gold',
                  2 => 'silver',
                  _ => 'bronze'
                }
              : null;
          final emote = medal == null
              ? null
              : dragonEmotesById['seasonal_${eventSlug}_$medal'];
          return Card(
            color: entry.isCurrentUser ? const Color(0xFFFFF2C9) : Colors.white,
            child: ListTile(
              leading: SizedBox(
                width: 48,
                child: emote == null
                    ? Center(
                        child: Text('#${entry.position}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.twilight)),
                      )
                    : Image.asset(emote.assetPath, fit: BoxFit.contain),
              ),
              title: Text(entry.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(
                '${entry.accuracyPermille / 10}% Â· ${(entry.durationMs / 1000).toStringAsFixed(1)}s',
              ),
              trailing: Text(
                '${entry.score}',
                style: const TextStyle(
                  color: AppColors.twilightDark,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SeasonalChronicleCard extends StatelessWidget {
  const _SeasonalChronicleCard({
    required this.entries,
    required this.eventSlug,
  });

  final List<SeasonalChampionEntry> entries;
  final String eventSlug;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final latestKeys =
        entries.map((entry) => entry.occurrenceKey).toSet().take(3);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.panelGradient(context,
            fallback: const LinearGradient(
                colors: [Color(0xFF2B1B4D), Color(0xFF5C3D88)])),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/events/$eventSlug/trial_icon.webp',
                width: 42,
                height: 42,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.pick('Seasonal Chronicle', 'Seizoenskroniek'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final key in latestKeys) ...[
            Text(
              key.split(':').last,
              style: const TextStyle(
                color: Color(0xFFFFDF83),
                fontWeight: FontWeight.w900,
              ),
            ),
            for (final entry
                in entries.where((value) => value.occurrenceKey == key))
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  children: [
                    Image.asset(
                      dragonEmotesById[entry.podiumEmoteId]?.assetPath ??
                          'assets/images/events/$eventSlug/podium_bronze.webp',
                      width: 31,
                      height: 31,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '#${entry.position} ${entry.displayName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text('${entry.score}',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SeasonalRankingVisual {
  const _SeasonalRankingVisual({
    required this.deep,
    required this.accent,
  });

  final Color deep;
  final Color accent;

  static _SeasonalRankingVisual forSlug(String slug) => switch (slug) {
        'halloween' => const _SeasonalRankingVisual(
            deep: Color(0xFF160E26),
            accent: Color(0xFF773C75),
          ),
        'christmas' => const _SeasonalRankingVisual(
            deep: Color(0xFF082E2C),
            accent: Color(0xFF2F6A55),
          ),
        'new_year' => const _SeasonalRankingVisual(
            deep: Color(0xFF182044),
            accent: Color(0xFF6A5495),
          ),
        'valentine' => const _SeasonalRankingVisual(
            deep: Color(0xFF5E1E3F),
            accent: Color(0xFFB64F77),
          ),
        _ => const _SeasonalRankingVisual(
            deep: Color(0xFF33235D),
            accent: Color(0xFF8B55A5),
          ),
      };
}
