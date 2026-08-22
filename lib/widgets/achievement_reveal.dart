import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/achievement.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'achievement_badge_sprite.dart';

Future<void> showAchievementReveal(
  BuildContext context,
  AchievementDefinition achievement,
) async {
  await HavenAudio.play(HavenSound.achievement);
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: AppStrings.of(context).tr('achievements'),
    barrierColor: const Color(0xCC17122F),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => _AchievementReveal(achievement: achievement),
    transitionBuilder: (_, animation, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

class _AchievementReveal extends StatefulWidget {
  const _AchievementReveal({required this.achievement});

  final AchievementDefinition achievement;

  @override
  State<_AchievementReveal> createState() => _AchievementRevealState();
}

class _AchievementRevealState extends State<_AchievementReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _turns;
  late final Animation<double> _scale;
  late final Animation<Offset> _panelSlide;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
      reverseDuration: const Duration(milliseconds: 700),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    );
    _turns = Tween<double>(begin: -.9, end: 0).animate(curve);
    _scale = Tween<double>(begin: .12, end: 1).animate(curve);
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, .35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(.2, 1, curve: Curves.easeOutCubic),
      reverseCurve: Curves.easeInCubic,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await HavenAudio.play(HavenSound.uiConfirm);
    if (!mounted) return;
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _controller.reverse();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final title = strings.achievementTitle(widget.achievement);
    final description = strings.achievementDescription(widget.achievement);
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: InkWell(
          key: Key('achievement-reveal-${widget.achievement.id}'),
          onTap: _close,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scale,
                    child: RotationTransition(
                      turns: _turns,
                      child: Container(
                        width: 190,
                        height: 190,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(colors: [
                            Color(0xFFFFF7C8),
                            Color(0xFFFFD76A),
                            Color(0xFF6B4DA0),
                          ]),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x99FFD76A),
                              blurRadius: 42,
                              spreadRadius: 8,
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: ClipOval(
                          child: AchievementBadgeSprite(
                            achievement: widget.achievement,
                            unlocked: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SlideTransition(
                    position: _panelSlide,
                    child: FadeTransition(
                      opacity: _controller,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 470),
                        padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFFFD76A),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 30,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              strings.tr('achievement_unlocked').toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.twilight,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.8,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 16,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.touch_app_rounded,
                                    color: AppColors.twilight, size: 18),
                                const SizedBox(width: 7),
                                Flexible(
                                  child: Text(
                                    strings.tr('tap_to_continue'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.twilight,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
