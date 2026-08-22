import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/day_phase.dart';
import '../providers/household_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/haven_lighting.dart';
import '../widgets/dragon_art.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hour = DateTime.now().hour;
      HavenAudio.setMusicScene(hour >= 21 || hour < 7
          ? HavenMusicScene.towerNight
          : HavenMusicScene.towerDay);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          key: const PageStorageKey('onboarding-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            Center(
              child: Image.asset(
                'assets/images/dragonhaven_logo.png',
                width: 92,
                height: 92,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'DragonHaven',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              strings.pick(
                'A quiet tower. A mysterious egg. A collection waiting to become legend.',
                'Een stille toren. Een mysterieus ei. Een collectie die legendarisch kan worden.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 16),
            ),
            const SizedBox(height: 18),
            Container(
              height: 235,
              decoration: BoxDecoration(
                color: const Color(0xFF292552),
                borderRadius: BorderRadius.circular(28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(children: [
                  Positioned.fill(
                    child: HavenPhaseImage(
                      assetFor: (phase) =>
                          'assets/images/tower_nest_${phase.assetKey}.webp',
                    ),
                  ),
                  const Align(
                    alignment: Alignment(.02, .56),
                    child: DragonArt(
                      height: 150,
                      stageKey: 'moonEgg',
                      animate: true,
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 22),
            Form(
              key: _formKey,
              child: TextFormField(
                key: const Key('account-name-field'),
                controller: _controller,
                maxLength: 24,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText:
                      strings.pick('Your keeper name', 'Naam van je hoeder'),
                  hintText:
                      strings.pick('For example: Rick', 'Bijvoorbeeld: Rick'),
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? strings.pick(
                        'Choose a name first.', 'Kies eerst een naam.')
                    : null,
                onFieldSubmitted: (_) => _continue(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('begin-dragonhaven-button'),
              onPressed: _submitting ? null : _continue,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Text(
                  strings.pick(
                      'Claim the Starter Egg', 'Ontvang het Starter Egg'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    await context
        .read<HouseholdProvider>()
        .completeOnboarding(_controller.text);
    if (mounted) setState(() => _submitting = false);
  }
}
