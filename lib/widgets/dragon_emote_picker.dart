import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_emote.dart';
import '../theme/app_theme.dart';

class DragonEmoteSprite extends StatelessWidget {
  const DragonEmoteSprite({
    super.key,
    required this.emote,
    required this.size,
  });

  final DragonEmoteDefinition emote;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        emote.assetPath,
        key: Key('dragon-emote-sprite-${emote.id}'),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: emote.label(AppStrings.of(context).languageCode),
        errorBuilder: (_, __, ___) => SizedBox.square(
          dimension: size,
          child: const Icon(
            Icons.emoji_emotions_rounded,
            color: AppColors.twilight,
          ),
        ),
      );
}

Future<DragonEmoteDefinition?> showDragonEmotePicker(
  BuildContext context,
  List<DragonEmoteDefinition> ownedEmotes,
) =>
    showModalBottomSheet<DragonEmoteDefinition>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _DragonEmotePicker(emotes: ownedEmotes),
    );

class _DragonEmotePicker extends StatelessWidget {
  const _DragonEmotePicker({required this.emotes});

  final List<DragonEmoteDefinition> emotes;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final height = MediaQuery.sizeOf(context).height * .56;
    return SafeArea(
      child: SizedBox(
        height: height.clamp(300, 560),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_emotions_rounded,
                    color: AppColors.twilight,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      strings.pick('Dragon emotes', 'Drakenemotes'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${emotes.length} / ${allDragonEmotes.length}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                strings.pick(
                  'Unlocked emotes can be used without limits.',
                  'Vrijgespeelde emotes kun je onbeperkt gebruiken.',
                ),
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: emotes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          strings.pick(
                            'Find emotes in chests, win them with S+ Trial scores, or collect an emote pack.',
                            'Vind emotes in kisten, win ze met S+-Trialscores of verzamel een emotepakket.',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : GridView.builder(
                      key: const Key('dragon-emote-picker-grid'),
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: .86,
                      ),
                      itemCount: emotes.length,
                      itemBuilder: (context, index) {
                        final emote = emotes[index];
                        return InkWell(
                          key: Key('pick-dragon-emote-${emote.id}'),
                          onTap: () => Navigator.pop(context, emote),
                          borderRadius: BorderRadius.circular(18),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F0FA),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE1D8EA),
                              ),
                            ),
                            padding: const EdgeInsets.all(5),
                            child: Column(
                              children: [
                                Expanded(
                                  child: DragonEmoteSprite(
                                    emote: emote,
                                    size: 68,
                                  ),
                                ),
                                Text(
                                  emote.label(strings.languageCode),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
