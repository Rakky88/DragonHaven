import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';

class JukeboxScreen extends StatelessWidget {
  const JukeboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final tracks = game.ownedMusicTracks;
    return Scaffold(
      appBar: AppBar(title: Text(strings.pick('Jukebox', 'Jukebox'))),
      body: ListView(
        key: const PageStorageKey('jukebox-scroll'),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          Card(
            color: const Color(0xFFF3EEFF),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.queue_music_rounded,
                        color: AppColors.twilight,
                        size: 34,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.pick(
                            '${tracks.length} tracks collected',
                            '${tracks.length} nummers verzameld',
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 9,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        key: const Key('jukebox-shuffle-toggle'),
                        avatar: const Icon(Icons.shuffle_rounded, size: 19),
                        label: Text(strings.pick('Shuffle', 'Shuffle')),
                        selected: game.jukeboxShuffle,
                        onSelected: game.setJukeboxShuffle,
                      ),
                      FilterChip(
                        key: const Key('jukebox-repeat-toggle'),
                        avatar: const Icon(Icons.repeat_rounded, size: 19),
                        label: Text(strings.pick('Repeat', 'Herhalen')),
                        selected: game.jukeboxRepeat,
                        onSelected: game.setJukeboxRepeat,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.pick(
                      'Shuffle changes the order. Repeat starts a new full cycle after every selected track has played.',
                      'Shuffle verandert de volgorde. Herhalen start een nieuwe volledige ronde nadat elk gekozen nummer is afgespeeld.',
                    ),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          if (game.musicEnabled && game.enabledMusicTrackIds.isEmpty) ...[
            const SizedBox(height: 10),
            Card(
              color: const Color(0xFFFFF2DD),
              child: ListTile(
                leading: const Icon(Icons.music_off_rounded),
                title: Text(strings.pick(
                  'No tracks selected',
                  'Geen nummers geselecteerd',
                )),
                subtitle: Text(strings.pick(
                  'Background music stays silent until you enable a track.',
                  'De achtergrondmuziek blijft stil tot je een nummer inschakelt.',
                )),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            strings.pick('Your music', 'Jouw muziek'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0; index < tracks.length; index++) ...[
                  SwitchListTile(
                    key: Key('jukebox-track-${tracks[index].id}'),
                    secondary: const Icon(
                      Icons.music_note_rounded,
                      color: AppColors.twilight,
                    ),
                    title: Text(
                      tracks[index].title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(tracks[index].composer),
                    value: game.enabledMusicTrackIds.contains(tracks[index].id),
                    onChanged: (enabled) => game.setMusicTrackEnabled(
                      tracks[index].id,
                      enabled,
                    ),
                  ),
                  if (index != tracks.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
