import 'package:flutter/material.dart';

import '../models/social.dart';
import '../theme/app_theme.dart';
import 'online_account_access.dart';

/// A fixed portrait well keeps vanity frames from changing list geometry.
class KeeperListRow extends StatelessWidget {
  const KeeperListRow(
      {super.key,
      required this.keeper,
      required this.onTap,
      this.subtitle,
      this.detail,
      this.trailing});

  final KeeperProfile keeper;
  final VoidCallback onTap;
  final Widget? subtitle;
  final Widget? detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Theme.of(context).colorScheme.surface,
              Color.alphaBlend(accent.withValues(alpha: .055), AppColors.cream),
            ]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Color.lerp(accent, AppColors.gold, .6)!
                    .withValues(alpha: .28)),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(children: [
                SizedBox.square(
                  key: Key('keeper-list-portrait-${keeper.userId}'),
                  dimension: 64,
                  child: Center(
                      child: KeeperPortrait(
                    portraitKey: keeper.portraitKey,
                    displayName: keeper.displayName,
                    frameKey: keeper.frameKey,
                    badgeKey: keeper.badgeKey,
                    radius: 20,
                  )),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(keeper.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800, color: AppColors.ink)),
                    if (subtitle != null)
                      DefaultTextStyle.merge(
                          style: TextStyle(
                              fontSize: 11,
                              height: 1.35,
                              color: accent.withValues(alpha: .85)),
                          child: subtitle!),
                    if (detail != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: DefaultTextStyle.merge(
                              style: const TextStyle(
                                  fontSize: 10,
                                  height: 1.2,
                                  color: AppColors.muted),
                              child: detail!)),
                  ],
                )),
                if (trailing != null) ...[
                  const SizedBox(width: 4),
                  trailing!,
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
