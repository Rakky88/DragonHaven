import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/household_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.pick('Notifications', 'Notificaties')),
      ),
      body: ListView(
        key: const PageStorageKey('notification-settings-scroll'),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1B59), Color(0xFF7253A8)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332B174D),
                  blurRadius: 16,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFFFDF7D),
                  size: 46,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.pick(
                          'Choose what may call you back',
                          'Kies waarvoor je teruggeroepen wordt',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        strings.pick(
                          'Everything is enabled by default. You remain in control of every reminder.',
                          'Alles staat standaard aan. Je houdt zelf controle over iedere melding.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFFE9E1F8),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0;
                    index < HavenNotificationCategory.values.length;
                    index++) ...[
                  _NotificationToggle(
                    category: HavenNotificationCategory.values[index],
                    enabled: game.notificationEnabled(
                      HavenNotificationCategory.values[index],
                    ),
                    onChanged: (enabled) => game.setNotificationEnabled(
                      HavenNotificationCategory.values[index],
                      enabled,
                    ),
                  ),
                  if (index < HavenNotificationCategory.values.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.category,
    required this.enabled,
    required this.onChanged,
  });

  final HavenNotificationCategory category;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final (icon, titleEn, titleNl, bodyEn, bodyNl) = switch (category) {
      HavenNotificationCategory.eggReady => (
          Icons.egg_alt_rounded,
          'Eggs ready to hatch',
          'Eieren klaar om uit te komen',
          'When an egg in the Rooftop Nest is ready.',
          'Wanneer een ei in het Daknest klaar is.',
        ),
      HavenNotificationCategory.achievements => (
          Icons.emoji_events_rounded,
          'Achievements',
          'Achievements',
          'When you unlock a new achievement.',
          'Wanneer je een nieuwe achievement vrijspeelt.',
        ),
      HavenNotificationCategory.evolutions => (
          Icons.auto_awesome_rounded,
          'Dragon evolutions',
          'Drakenevoluties',
          'When one of your dragons reaches a new form.',
          'Wanneer een van je draken een nieuwe vorm bereikt.',
        ),
      HavenNotificationCategory.friendRequests => (
          Icons.person_add_alt_1_rounded,
          'Friend requests',
          'Vriendschapsverzoeken',
          'When another keeper sends you a request.',
          'Wanneer een andere hoeder je een verzoek stuurt.',
        ),
      HavenNotificationCategory.friendAcceptances => (
          Icons.how_to_reg_rounded,
          'Friend acceptances',
          'Geaccepteerde vriendschappen',
          'When your friend request is accepted.',
          'Wanneer jouw vriendschapsverzoek wordt geaccepteerd.',
        ),
      HavenNotificationCategory.tradeRequests => (
          Icons.swap_horiz_rounded,
          'Trade proposals',
          'Ruilvoorstellen',
          'When a friend starts a trade with you.',
          'Wanneer een vriend een ruil met je start.',
        ),
      HavenNotificationCategory.tradeReturns => (
          Icons.reply_all_rounded,
          'Trade return items',
          'Tegenaanbiedingen bij ruilen',
          'When the other keeper offers their item.',
          'Wanneer de andere hoeder een eigen item aanbiedt.',
        ),
      HavenNotificationCategory.tradeCompletions => (
          Icons.handshake_rounded,
          'Completed trades',
          'Afgeronde ruilen',
          'When a trade has safely completed.',
          'Wanneer een ruil veilig is afgerond.',
        ),
      HavenNotificationCategory.trialsFull => (
          Icons.sports_score_rounded,
          'Three Trials available',
          'Drie Trials beschikbaar',
          'When your Trial board reaches 3/3.',
          'Wanneer je Trial-bord 3/3 bereikt.',
        ),
      HavenNotificationCategory.specialEvents => (
          Icons.auto_awesome_motion_rounded,
          'Special Events',
          'Special Events',
          'When a Special Adventure becomes available.',
          'Wanneer een Speciaal Avontuur beschikbaar wordt.',
        ),
    };
    return SwitchListTile(
      key: Key('notification-${category.name}'),
      secondary: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.twilight),
      ),
      title: Text(
        strings.pick(titleEn, titleNl),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(strings.pick(bodyEn, bodyNl)),
      value: enabled,
      onChanged: onChanged,
    );
  }
}
