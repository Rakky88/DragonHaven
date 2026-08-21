import 'package:flutter/services.dart';

abstract final class PlatformActions {
  static const _channel = MethodChannel('nl.dragonhaven.app/platform');

  static Future<void> openUrl(String url) async {
    final opened =
        await _channel.invokeMethod<bool>('openUrl', {'url': url}) ?? false;
    if (!opened) {
      throw PlatformException(code: 'open_failed');
    }
  }

  static Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
