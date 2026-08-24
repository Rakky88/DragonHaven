import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/account_title.dart';
import '../models/profile_portrait.dart';
import '../providers/online_account_provider.dart';
import '../theme/app_theme.dart';

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
    final portrait = profilePortraitById(portraitKey);
    if (portrait != null) {
      return Semantics(
        image: true,
        label: displayName,
        child: SizedBox.square(
          dimension: radius * 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: .28),
            ),
            child: Image.asset(
              portrait.assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Icon(
                Icons.person_rounded,
                size: radius * 1.05,
                color: AppColors.twilight,
              ),
            ),
          ),
        ),
      );
    }
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

String keeperTitleLabel(AppStrings strings, String titleId) =>
    accountTitleById(titleId)?.label(strings.languageCode) ?? titleId;

class OnlineAccountAccessCard extends StatelessWidget {
  const OnlineAccountAccessCard({super.key});

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
                'Create a verified account to add friends by Keeper ID. You must confirm your email before signing in, and it is never shown to other players.',
                'Maak een geverifieerd account om vrienden via Keeper-ID toe te voegen. Je moet je e-mailadres bevestigen voordat je kunt inloggen en het wordt nooit aan andere spelers getoond.',
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
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _OnlineAuthDialog(
        createAccount: createAccount,
      ),
    );

class _OnlineAuthDialog extends StatefulWidget {
  const _OnlineAuthDialog({
    required this.createAccount,
  });

  final bool createAccount;

  @override
  State<_OnlineAuthDialog> createState() => _OnlineAuthDialogState();
}

class _OnlineAuthDialogState extends State<_OnlineAuthDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
              Text(
                strings.pick(
                  'Your offline name, portrait and title are used automatically online.',
                  'Je offline naam, portrait en titel worden automatisch online gebruikt.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
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
              validator: (value) => _passwordValidator(strings, value),
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
    final password = _password.text;
    _password.clear();
    if (widget.createAccount) {
      final result = await online.signUp(
        email: _email.text,
        password: password,
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
        password: password,
      );
      if (success && mounted) Navigator.pop(context);
    }
  }

  String? _passwordValidator(AppStrings strings, String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return strings.pick('Enter your password.', 'Vul je wachtwoord in.');
    }
    if (!widget.createAccount) return null;
    if (password.length < 8) {
      return strings.pick(
          'Use at least 8 characters.', 'Gebruik minimaal 8 tekens.');
    }
    final hasRequiredCharacters = RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"\\|<>?,./`]''').hasMatch(password);
    if (!hasRequiredCharacters) {
      return strings.pick(
        'Use an uppercase letter, lowercase letter, number and symbol.',
        'Gebruik een hoofdletter, kleine letter, cijfer en symbool.',
      );
    }
    return null;
  }
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
      'email_not_verified' => strings.pick(
          'Confirm your email before signing in.',
          'Bevestig je e-mailadres voordat je inlogt.'),
      'profile_saved' => strings.pick('Profile saved.', 'Profiel opgeslagen.'),
      'request_sent' =>
        strings.pick('Friend request sent.', 'Vriendschapsverzoek verstuurd.'),
      'friend_removed' => strings.pick('Friend removed for both keepers.',
          'Vriend bij beide hoeders verwijderd.'),
      'keeper_blocked' =>
        strings.pick('Keeper blocked.', 'Hoeder geblokkeerd.'),
      'keeper_unblocked' =>
        strings.pick('Keeper unblocked.', 'Blokkade opgeheven.'),
      'group_lobby_created' => strings.pick(
          'Group created. Friends can now join.',
          'Groep gemaakt. Vrienden kunnen zich nu aanmelden.'),
      'group_joined' => strings.pick('Your dragon joined the group.',
          'Je draak is bij de groep aangemeld.'),
      'group_left' => strings.pick('Your dragon left the group.',
          'Je draak is uit de groep uitgeschreven.'),
      'group_participant_removed' => strings.pick(
          'The dragon was removed from the group.',
          'De draak is uit de groep verwijderd.'),
      'group_lobby_full' =>
        strings.pick('This group is full.', 'Deze groep zit vol.'),
      'group_already_joined' => strings.pick(
          'You already used this weekly Group Adventure.',
          'Je hebt dit wekelijkse groepsavontuur al gebruikt.'),
      'group_adventure_already_completed' => strings.pick(
          "You have already completed this week's Group Adventure.",
          'Je hebt het groepsavontuur van deze week al voltooid.'),
      'group_lobby_closed' => strings.pick(
          'This group has already started or expired.',
          'Deze groep is al gestart of verlopen.'),
      'group_not_friends' => strings.pick(
          'Only friends of the group starter can join.',
          'Alleen vrienden van de groepsstarter kunnen meedoen.'),
      'group_dragon_busy' => strings.pick(
          'This dragon is already reserved for a Group Adventure.',
          'Deze draak is al gereserveerd voor een groepsavontuur.'),
      'group_reward_not_ready' => strings.pick(
          'These Group Adventure rewards are not ready yet.',
          'Deze groepsbeloningen staan nog niet klaar.'),
      'group_reward_apply_failed' => strings.pick(
          'The reward could not be linked to your local dragon.',
          'De beloning kon niet aan je lokale draak worden gekoppeld.'),
      'trade_sent' =>
        strings.pick('Trade proposal sent.', 'Ruilvoorstel verstuurd.'),
      'trade_response_sent' => strings.pick(
          'Your item is reserved. Your friend can now confirm the trade.',
          'Je item is gereserveerd. Je vriend kan de ruil nu bevestigen.'),
      'trade_completed' => strings.pick(
          'Trade completed. The received item is in your inventory.',
          'Ruil afgerond. Het ontvangen item staat in je inventaris.'),
      'trade_cancelled' => strings.pick(
          'Trade cancelled. Reserved items are available again.',
          'Ruil geannuleerd. Gereserveerde items zijn weer beschikbaar.'),
      'trade_rejected' => strings.pick(
          'Trade rejected. Reserved items are available again.',
          'Ruil geweigerd. Gereserveerde items zijn weer beschikbaar.'),
      'trade_not_friends' => strings.pick(
          'Trades are only available between friends.',
          'Ruilen kan alleen tussen vrienden.'),
      'trade_wrong_state' => strings.pick(
          'This trade has already changed. Refresh and try again.',
          'Deze ruil is al gewijzigd. Vernieuw en probeer opnieuw.'),
      'trade_item_invalid' => strings.pick(
          'This item cannot be traded.', 'Dit item kan niet worden geruild.'),
      'trade_item_unavailable' => strings.pick(
          'This item is no longer available or is already reserved.',
          'Dit item is niet meer beschikbaar of is al gereserveerd.'),
      'trade_inventory_locked' => strings.pick(
          'You have too many active trades. Finish or cancel one first.',
          'Je hebt te veel actieve ruilen. Rond er eerst één af of annuleer er één.'),
      'trade_active_limit' => strings.pick(
          'Only one active trade is allowed per account. Finish, reject or cancel it first.',
          'Per account kan maar één ruil tegelijk actief zijn. Rond die eerst af, weiger of annuleer hem.'),
      'trade_daily_limit' => strings.pick(
          'One of you has already completed three trades today. Try again tomorrow.',
          'Een van jullie heeft vandaag al drie ruilen afgerond. Probeer het morgen opnieuw.'),
      'trade_expired' => strings.pick(
          'This trade expired after ten minutes. The reserved items are available again.',
          'Deze ruil is na tien minuten verlopen. De gereserveerde items zijn weer beschikbaar.'),
      'trade_apply_failed' => strings.pick(
          'The completed trade could not be stored locally. Your server items remain safe; please refresh.',
          'De afgeronde ruil kon niet lokaal worden opgeslagen. Je serveritems blijven veilig; vernieuw opnieuw.'),
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
