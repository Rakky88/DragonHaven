import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/social.dart';
import '../providers/online_account_provider.dart';
import '../theme/app_theme.dart';

const keeperPortraitKeys = ['moon', 'ember', 'forest', 'tide', 'storm'];
const keeperTitles = [
  'Dragon Keeper',
  'Nest Guardian',
  'Sky Explorer',
  'Draconomicon Scholar',
  'Tower Architect',
];

class KeeperPortrait extends StatelessWidget {
  const KeeperPortrait({
    super.key,
    required this.portraitKey,
    required this.displayName,
    this.radius = 25,
  });

  final String portraitKey;
  final String displayName;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (portraitKey) {
      'ember' => (const Color(0xFFE66B4E), Icons.local_fire_department_rounded),
      'forest' => (const Color(0xFF4A956C), Icons.park_rounded),
      'tide' => (const Color(0xFF438CB8), Icons.water_rounded),
      'storm' => (const Color(0xFF7568B5), Icons.bolt_rounded),
      _ => (AppColors.twilight, Icons.nightlight_round),
    };
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: .14),
      foregroundColor: color,
      child: Icon(icon, size: radius * 1.05),
    );
  }
}

class OnlineAccountAccessCard extends StatelessWidget {
  const OnlineAccountAccessCard({super.key, required this.suggestedName});

  final String suggestedName;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      key: const Key('online-account-access-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.shield_outlined,
                size: 42, color: AppColors.twilight),
            const SizedBox(height: 10),
            Text(
              strings.pick('Connect your keeper', 'Koppel je hoeder'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              strings.pick(
                'Create a simple account to add friends by Keeper ID. Your email is never shown to other players.',
                'Maak een simpel account om vrienden via Keeper-ID toe te voegen. Je e-mailadres wordt nooit aan andere spelers getoond.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('create-online-account'),
                    onPressed: () => showOnlineAuthDialog(
                      context,
                      createAccount: true,
                      suggestedName: suggestedName,
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label:
                        Text(strings.pick('Create account', 'Account maken')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('sign-in-online-account'),
                    onPressed: () => showOnlineAuthDialog(
                      context,
                      createAccount: false,
                      suggestedName: suggestedName,
                    ),
                    child: Text(strings.pick('Sign in', 'Inloggen')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showOnlineAuthDialog(
  BuildContext context, {
  required bool createAccount,
  required String suggestedName,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _OnlineAuthDialog(
        createAccount: createAccount,
        suggestedName: suggestedName,
      ),
    );

class _OnlineAuthDialog extends StatefulWidget {
  const _OnlineAuthDialog({
    required this.createAccount,
    required this.suggestedName,
  });

  final bool createAccount;
  final String suggestedName;

  @override
  State<_OnlineAuthDialog> createState() => _OnlineAuthDialogState();
}

class _OnlineAuthDialogState extends State<_OnlineAuthDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.suggestedName);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.watch<OnlineAccountProvider>();
    return AlertDialog(
      scrollable: true,
      title: Text(widget.createAccount
          ? strings.pick('Create online account', 'Online account maken')
          : strings.pick('Sign in', 'Inloggen')),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.createAccount) ...[
              TextFormField(
                key: const Key('online-display-name'),
                controller: _name,
                maxLength: 24,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: strings.pick('Keeper name', 'Naam van hoeder'),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? strings.pick('Enter a name.', 'Vul een naam in.')
                    : null,
              ),
              const SizedBox(height: 5),
            ],
            TextFormField(
              key: const Key('online-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (value) => value == null ||
                      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value.trim())
                  ? strings.pick(
                      'Enter a valid email.', 'Vul een geldig e-mailadres in.')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('online-password'),
              controller: _password,
              obscureText: _hidePassword,
              autofillHints: widget.createAccount
                  ? const [AutofillHints.newPassword]
                  : const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: strings.pick('Password', 'Wachtwoord'),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded),
                ),
              ),
              validator: (value) => value == null || value.length < 8
                  ? strings.pick('Use at least 8 characters.',
                      'Gebruik minimaal 8 tekens.')
                  : null,
            ),
            if (online.errorCode case final error?) ...[
              const SizedBox(height: 12),
              Text(
                socialMessage(strings, error),
                key: const Key('online-auth-error'),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: online.busy ? null : () => Navigator.pop(context),
          child: Text(strings.tr('cancel')),
        ),
        FilledButton(
          key: const Key('submit-online-auth'),
          onPressed: online.busy ? null : _submit,
          child: online.busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.createAccount
                  ? strings.pick('Create', 'Maken')
                  : strings.pick('Sign in', 'Inloggen')),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final online = context.read<OnlineAccountProvider>();
    if (widget.createAccount) {
      final result = await online.signUp(
        email: _email.text,
        password: _password.text,
        displayName: _name.text,
      );
      if (!mounted || result == null) return;
      Navigator.pop(context);
      final strings = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.requiresEmailConfirmation
            ? strings.pick(
                'Check your email to confirm the account, then sign in.',
                'Controleer je e-mail om het account te bevestigen en log daarna in.')
            : strings.pick('Your online account is ready.',
                'Je online account is klaar.')),
      ));
    } else {
      final success = await online.signIn(
        email: _email.text,
        password: _password.text,
      );
      if (success && mounted) Navigator.pop(context);
    }
  }
}

Future<void> showOnlineProfileEditor(
    BuildContext context, KeeperProfile profile) async {
  final name = TextEditingController(text: profile.displayName);
  var title =
      keeperTitles.contains(profile.title) ? profile.title : keeperTitles.first;
  var portrait = keeperPortraitKeys.contains(profile.portraitKey)
      ? profile.portraitKey
      : keeperPortraitKeys.first;
  final strings = AppStrings.of(context);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final online = context.watch<OnlineAccountProvider>();
        return AlertDialog(
          scrollable: true,
          title: Text(
              strings.pick('Edit online profile', 'Online profiel aanpassen')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('edit-online-name'),
                controller: name,
                maxLength: 24,
                decoration: InputDecoration(
                    labelText: strings.pick('Keeper name', 'Naam van hoeder')),
              ),
              DropdownButtonFormField<String>(
                key: const Key('edit-online-title'),
                initialValue: title,
                decoration:
                    InputDecoration(labelText: strings.pick('Title', 'Titel')),
                items: [
                  for (final candidate in keeperTitles)
                    DropdownMenuItem(value: candidate, child: Text(candidate)),
                ],
                onChanged: (value) => setState(() => title = value ?? title),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final key in keeperPortraitKeys)
                    InkWell(
                      key: Key('portrait-$key'),
                      borderRadius: BorderRadius.circular(99),
                      onTap: () => setState(() => portrait = key),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: portrait == key
                                  ? AppColors.gold
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: KeeperPortrait(
                            portraitKey: key,
                            displayName: name.text,
                            radius: 21,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: online.busy ? null : () => Navigator.pop(context),
              child: Text(strings.tr('cancel')),
            ),
            FilledButton(
              key: const Key('save-online-profile'),
              onPressed: online.busy || name.text.trim().isEmpty
                  ? null
                  : () async {
                      final saved = await online.updateProfile(
                        displayName: name.text,
                        title: title,
                        portraitKey: portrait,
                      );
                      if (saved && context.mounted) Navigator.pop(context);
                    },
              child: Text(strings.tr('save')),
            ),
          ],
        );
      },
    ),
  );
  name.dispose();
}

String socialMessage(AppStrings strings, String code) => switch (code) {
      'keeper_not_found' => strings.pick('No keeper with that ID was found.',
          'Er is geen hoeder met dat ID gevonden.'),
      'keeper_unavailable' => strings.pick(
          'This keeper is unavailable.', 'Deze hoeder is niet beschikbaar.'),
      'cannot_friend_self' => strings.pick(
          'You cannot add yourself.', 'Je kunt jezelf niet toevoegen.'),
      'request_already_pending' => strings.pick(
          'A request is already pending.', 'Er staat al een verzoek open.'),
      'request_recently_rejected' => strings.pick(
          'This request was recently rejected. Try again later.',
          'Dit verzoek is onlangs afgewezen. Probeer het later opnieuw.'),
      'too_many_requests' => strings.pick(
          'Too many requests are pending.', 'Er staan te veel verzoeken open.'),
      'already_friends' =>
        strings.pick('You are already friends.', 'Jullie zijn al vrienden.'),
      'invalid login credentials' ||
      'invalid_login_credentials' =>
        strings.pick('Incorrect email or password.',
            'Onjuist e-mailadres of wachtwoord.'),
      'user already registered' || 'user_already_registered' => strings.pick(
          'An account already exists for this email.',
          'Voor dit e-mailadres bestaat al een account.'),
      'profile_saved' => strings.pick('Profile saved.', 'Profiel opgeslagen.'),
      'request_sent' =>
        strings.pick('Friend request sent.', 'Vriendschapsverzoek verstuurd.'),
      'friend_removed' => strings.pick('Friend removed for both keepers.',
          'Vriend bij beide hoeders verwijderd.'),
      'keeper_blocked' =>
        strings.pick('Keeper blocked.', 'Hoeder geblokkeerd.'),
      'keeper_unblocked' =>
        strings.pick('Keeper unblocked.', 'Blokkade opgeheven.'),
      _ => strings.pick(
          'The online service could not complete this action. Please try again.',
          'De online dienst kon deze actie niet uitvoeren. Probeer het opnieuw.'),
    };

Future<void> copyKeeperCode(BuildContext context, String code) async {
  await Clipboard.setData(ClipboardData(text: code));
  if (!context.mounted) return;
  final strings = AppStrings.of(context);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(strings.pick('Keeper ID copied.', 'Keeper-ID gekopieerd.')),
  ));
}
