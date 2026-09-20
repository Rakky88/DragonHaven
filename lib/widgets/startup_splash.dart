import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../services/event_branding_service.dart';

/// Matches Android's white launch screen and reuses its active event logo.
class StartupSplash extends StatefulWidget {
  const StartupSplash({super.key});
  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash> {
  String _logo = EventBrandingService.launchLogoAsset;
  @override
  void initState() {
    super.initState();
    EventBrandingService.readLaunchLogoAsset().then((logo) {
      if (mounted && logo != _logo) setState(() => _logo = logo);
    });
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
              child: Center(
                  child: Semantics(
            liveRegion: true,
            label:
                'DragonHaven. ${AppStrings.of(context).pick('Checking your progress', 'Je voortgang controleren')}',
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 256, maxHeight: 256),
                child: Image.asset(_logo,
                    key: const Key('startup-logo'),
                    width: 256,
                    height: 256,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true),
              ),
            ),
          ))),
        ),
      );
}
