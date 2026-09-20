import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/firebase_monitoring.dart';
import '../services/privacy_notice.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen(
      {super.key,
      this.onAcknowledge,
      this.onSignOut,
      this.showPreferences = true});
  final Future<void> Function()? onAcknowledge;
  final VoidCallback? onSignOut;
  final bool showPreferences;
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _age = false, _read = false, _busy = false;
  String? _error;
  Future<void> _accept() async {
    if (!_age || !_read || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onAcknowledge!();
    } on Object {
      if (mounted) {
        setState(() => _error = AppStrings.of(context).pick(
            'Could not save your confirmation. Check your connection and try again.',
            'Je bevestiging kon niet worden opgeslagen. Controleer je verbinding en probeer opnieuw.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.pick('Privacy · 16+', 'Privacy · 16+'))),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(padding: const EdgeInsets.all(24), children: [
                Text(
                    s.pick(
                        'DragonHaven is an online game for ages 16+. We need your email to secure your account and save your progress. Your player profile and messages are visible through the social features you use. Optional diagnostics are off by default.',
                        'DragonHaven is een online spel voor 16+. Je e-mail is nodig om je account te beveiligen en je voortgang te bewaren. Je spelersprofiel en berichten zijn zichtbaar via de sociale functies die je gebruikt. Optionele diagnostiek staat standaard uit.'),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.5)),
                const SizedBox(height: 12),
                ExpansionTile(
                    title: Text(s.pick(
                        'Full privacy notice', 'Volledige privacyverklaring')),
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(12),
                          child: SelectableText(
                              PrivacyNotice.text(
                                  dutch: Localizations.localeOf(context)
                                          .languageCode ==
                                      'nl'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(height: 1.5)))
                    ]),
                const SizedBox(height: 16),
                if (widget.onAcknowledge != null) ...[
                  CheckboxListTile(
                      key: const Key('age-16-confirmation'),
                      value: _age,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _age = v ?? false),
                      title: Text(s.pick(
                          'I am 16 or older.', 'Ik ben 16 jaar of ouder.'))),
                  CheckboxListTile(
                      key: const Key('privacy-read-confirmation'),
                      value: _read,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _read = v ?? false),
                      title: Text(s.pick('I have read the privacy notice.',
                          'Ik heb de privacyverklaring gelezen.'))),
                  if (_error != null)
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  FilledButton(
                      key: const Key('privacy-continue'),
                      onPressed: _age && _read && !_busy ? _accept : null,
                      child: Text(s.pick('Continue', 'Verder'))),
                  if (widget.onSignOut != null)
                    TextButton(
                        onPressed: _busy ? null : widget.onSignOut,
                        child: Text(s.pick('Sign out', 'Uitloggen'))),
                ] else if (widget.showPreferences) ...[
                  ValueListenableBuilder<bool>(
                      valueListenable: HavenFirebase.diagnosticsEnabled,
                      builder: (_, enabled, __) => SwitchListTile(
                          key: const Key('privacy-diagnostics'),
                          value: enabled,
                          title: Text(s.pick(
                              'Share crash and performance diagnostics',
                              'Crash- en prestatiegegevens delen')),
                          subtitle: Text(s.pick(
                              'Optional, on this device. You can turn this off at any time.',
                              'Optioneel, op dit apparaat. Je kunt dit altijd weer uitzetten.')),
                          onChanged: _busy
                              ? null
                              : (value) async {
                                  setState(() => _busy = true);
                                  try {
                                    await HavenFirebase.setDiagnosticsConsent(
                                        value);
                                  } on Object {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(s.pick(
                                                  'Could not save this setting. Try again.',
                                                  'Instelling niet opgeslagen. Probeer opnieuw.'))));
                                    }
                                  } finally {
                                    if (mounted) setState(() => _busy = false);
                                  }
                                })),
                ],
              ]))),
    );
  }
}
