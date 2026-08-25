import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/trial.dart';
import '../theme/app_theme.dart';
import 'trial_icon_sprite.dart';

class DragonTrialRecords extends StatefulWidget {
  const DragonTrialRecords({
    super.key,
    required this.cavernFlightBest,
    required this.ruinBreakerBest,
    required this.runeweaverBest,
    this.account = false,
    this.compact = false,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  final int cavernFlightBest;
  final int ruinBreakerBest;
  final int runeweaverBest;
  final bool account;
  final bool compact;
  final bool collapsible;
  final bool initiallyExpanded;

  @override
  State<DragonTrialRecords> createState() => _DragonTrialRecordsState();
}

class _DragonTrialRecordsState extends State<DragonTrialRecords> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = !widget.collapsible || widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      key: Key(
          widget.account ? 'account-trial-records' : 'dragon-trial-records'),
      padding: EdgeInsets.all(widget.compact ? 11 : 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8F3FF), Color(0xFFFFF7DF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5B65D), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  size: 20, color: AppColors.gold),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  widget.account
                      ? strings.pick(
                          'Account Trial records', 'Trial-records van account')
                      : strings.pick(
                          'Dragon Trial records', 'Trial-records van draak'),
                  style: const TextStyle(
                    color: AppColors.twilight,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (widget.collapsible)
                IconButton(
                  key: Key(widget.account
                      ? 'toggle-account-trial-records'
                      : 'toggle-dragon-trial-records'),
                  visualDensity: VisualDensity.compact,
                  tooltip: _expanded
                      ? strings.pick('Collapse records', 'Records inklappen')
                      : strings.pick('Expand records', 'Records uitklappen'),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: AnimatedRotation(
                    turns: _expanded ? .5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Column(
                    children: [
                      const SizedBox(height: 9),
                      _Record(
                        kind: TrialKind.cavernFlight,
                        label: 'Cavern Flight',
                        score: widget.cavernFlightBest,
                      ),
                      _Record(
                        kind: TrialKind.ruinBreaker,
                        label: 'Ruin Breaker',
                        score: widget.ruinBreakerBest,
                      ),
                      _Record(
                        kind: TrialKind.runeweaver,
                        label: 'Runeweaver',
                        score: widget.runeweaverBest,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Record extends StatelessWidget {
  const _Record({
    required this.kind,
    required this.label,
    required this.score,
  });

  final TrialKind kind;
  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          TrialIconSprite(kind: kind, size: 31),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
          Text(
            score == 0 ? strings.pick('Not set', 'Geen') : '$score',
            style: TextStyle(
              color: score == 0 ? AppColors.muted : AppColors.twilight,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
