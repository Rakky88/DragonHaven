import 'dart:io';
import 'package:dragon_haven/services/privacy_notice.dart';

void main() {
  File('PRIVACY.md').writeAsStringSync('# DragonHaven privacy\n\n'
      'Public controller/contact: ${PrivacyNotice.controller} — ${PrivacyNotice.email}.\n\n'
      '## Nederlands\n\n${PrivacyNotice.text(dutch: true)}\n\n'
      '## English\n\n${PrivacyNotice.text(dutch: false)}\n');
}
