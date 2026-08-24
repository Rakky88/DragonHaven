import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class DragonTrialRecords extends StatelessWidget {
  const DragonTrialRecords({
    super.key,
    required this.cavernFlightBest,
    required this.ruinBreakerBest,
    required this.runeweaverBest,
    this.account = false,
    this.compact = false,
  });

  final int cavernFlightBest;
  final int ruinBreakerBest;
  final int runeweaverBest;
  final bool account;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      key: Key(account ? 'account-trial-records' : 'dragon-trial-records'),
      padding: EdgeInsets.all(compact ? 11 : 14),
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
                  account
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
            ],
          ),
          const SizedBox(height: 9),
          _Record(
            icon: Icons.flight_rounded,
            color: const Color(0xFF479B90),
            label: 'Cavern Flight',
            score: cavernFlightBest,
          ),
          _Record(
            icon: Icons.gavel_rounded,
            color: const Color(0xFFD56850),
            label: 'Ruin Breaker',
            score: ruinBreakerBest,
          ),
          _Record(
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFF7855C7),
            label: 'Runeweaver',
            score: runeweaverBest,
          ),
        ],
      ),
    );
  }
}

class _Record extends StatelessWidget {
  const _Record({
    required this.icon,
    required this.color,
    required this.label,
    required this.score,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: color),
          ),
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
