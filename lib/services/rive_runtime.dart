import 'dart:async';

import 'package:rive/rive.dart';

Future<bool>? _riveInitialization;

Future<bool> ensureDragonHavenRive() =>
    _riveInitialization ??= _initializeRive();

Future<bool> _initializeRive() async {
  try {
    return await RiveNative.init();
  } on Object {
    return false;
  }
}

void prewarmDragonHavenRive() {
  unawaited(ensureDragonHavenRive());
}
