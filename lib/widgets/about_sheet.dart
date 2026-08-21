import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_info.dart';
import '../l10n/app_strings.dart';
import '../providers/household_provider.dart';
import '../services/platform_actions.dart';
import '../services/release_service.dart';
import '../theme/app_theme.dart';

Future<void> showDragonHavenAboutSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AboutSheet(),
    );

class _AboutSheet extends StatefulWidget {
  const _AboutSheet();

  @override
  State<_AboutSheet> createState() => _AboutSheetState();
}

enum _AboutReleaseStatus {
  copied,
  copyFailed,
  opening,
  openFailedCopied,
  openAndCopyFailed,
}

class _AboutSheetState extends State<_AboutSheet> {
  bool _releaseBusy = false;
  bool _supportBusy = false;
  _AboutReleaseStatus? _releaseStatus;

  void _setReleaseStatus(_AboutReleaseStatus status) {
    if (!mounted) return;
    setState(() => _releaseStatus = status);
  }

  Future<void> _copyDownloadLink() async {
    try {
      await PlatformActions.copyText(ReleaseConfig.downloadUrl);
      _setReleaseStatus(_AboutReleaseStatus.copied);
    } catch (_) {
      _setReleaseStatus(_AboutReleaseStatus.copyFailed);
    }
  }

  Future<void> _downloadOrUpdate() async {
    setState(() => _releaseBusy = true);
    try {
      await PlatformActions.openUrl(ReleaseConfig.downloadUrl);
      _setReleaseStatus(_AboutReleaseStatus.opening);
    } catch (_) {
      var copied = false;
      try {
        await PlatformActions.copyText(ReleaseConfig.downloadUrl);
        copied = true;
      } catch (_) {
        // The message below also covers the uncommon clipboard failure.
      }
      _setReleaseStatus(copied
          ? _AboutReleaseStatus.openFailedCopied
          : _AboutReleaseStatus.openAndCopyFailed);
    } finally {
      if (mounted) setState(() => _releaseBusy = false);
    }
  }

  Future<void> _openKofi() async {
    setState(() => _supportBusy = true);
    try {
      await PlatformActions.openUrl(ReleaseConfig.kofiUrl);
    } catch (_) {
      var copied = false;
      try {
        await PlatformActions.copyText(ReleaseConfig.kofiUrl);
        copied = true;
      } catch (_) {
        // The localized fallback below also covers clipboard failures.
      }
      if (mounted) {
        final strings = AppStrings.of(context);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                copied
                    ? strings.pick(
                        'Ko-fi could not be opened. The link was copied instead.',
                        'Ko-fi kon niet worden geopend. De link is daarom gekopieerd.',
                      )
                    : strings.pick(
                        'Ko-fi could not be opened or copied.',
                        'Ko-fi kon niet worden geopend of gekopieerd.',
                      ),
              ),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _supportBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final releaseStatusMessage = switch (_releaseStatus) {
      _AboutReleaseStatus.copied => strings.pick(
          'Android download link copied.', 'Android-downloadlink gekopieerd.'),
      _AboutReleaseStatus.copyFailed => strings.pick(
          'The download link could not be copied.',
          'De downloadlink kon niet worden gekopieerd.'),
      _AboutReleaseStatus.opening => strings.pick(
          'Opening the latest DragonHaven download…',
          'De nieuwste DragonHaven-download wordt geopend…'),
      _AboutReleaseStatus.openFailedCopied => strings.pick(
          'The download could not be opened. The link was copied instead.',
          'De download kon niet worden geopend. De link is daarom gekopieerd.'),
      _AboutReleaseStatus.openAndCopyFailed => strings.pick(
          'The download link could not be opened or copied.',
          'De downloadlink kon niet worden geopend of gekopieerd.'),
      null => null,
    };
    final releaseStatusIsError = switch (_releaseStatus) {
      _AboutReleaseStatus.copyFailed ||
      _AboutReleaseStatus.openFailedCopied ||
      _AboutReleaseStatus.openAndCopyFailed =>
        true,
      _ => false,
    };

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.9,
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          key: const Key('about-scroll'),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 128,
                height: 128,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF514280), AppColors.twilightDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.twilight.withValues(alpha: 0.3),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/dragonhaven_logo.png',
                  filterQuality: FilterQuality.high,
                  semanticLabel:
                      strings.pick('DragonHaven logo', 'DragonHaven-logo'),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                strings.pick('About DragonHaven', 'Over DragonHaven'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 7),
              Text(
                strings.pick(
                  'Raise wonder. Build a home. Fill the Draconomicon.',
                  'Kweek verwondering. Bouw een thuis. Vul het Draconomicon.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              _AboutPanel(
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person_rounded,
                      label: strings.pick('Created by', 'Gemaakt door'),
                      value: AppInfo.creator,
                    ),
                    const _PanelDivider(),
                    _InfoRow(
                      icon: Icons.calendar_month_rounded,
                      label: strings.pick('Built in', 'Gebouwd in'),
                      value: AppInfo.builtYear,
                    ),
                    const _PanelDivider(),
                    _InfoRow(
                      icon: Icons.new_releases_rounded,
                      label: strings.pick('Version', 'Versie'),
                      value: AppInfo.displayVersion,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AboutPanel(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.redeem_rounded,
                      color: AppColors.twilight),
                  title: Text(
                    strings.pick('Redeem code', 'Code inwisselen'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(strings.pick(
                      'Event codes use capital letters without spaces.',
                      'Eventcodes bestaan uit hoofdletters zonder spaties.')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showRedeemCode,
                ),
              ),
              const SizedBox(height: 16),
              _AboutPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.mist,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.system_update_alt_rounded,
                              color: AppColors.twilight),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            strings.pick('Share or update DragonHaven',
                                'DragonHaven delen of updaten'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.pick(
                        'Copy one permanent Android download link for someone else, or open it to install the latest release over this app. Your progress stays safe.',
                        'Kopieer één vaste Android-downloadlink voor iemand anders, of open hem om de nieuwste release over deze app te installeren. Je voortgang blijft veilig.',
                      ),
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      key: const Key('about-copy-download-link'),
                      onPressed: _releaseBusy ? null : _copyDownloadLink,
                      icon: const Icon(Icons.content_copy_rounded, size: 19),
                      label: Text(strings.pick(
                          'Copy download link', 'Downloadlink kopiëren')),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      key: const Key('about-download-update'),
                      onPressed: _releaseBusy ? null : _downloadOrUpdate,
                      icon: _releaseBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2, color: Colors.white),
                            )
                          : const Icon(Icons.system_update_alt_rounded,
                              size: 19),
                      label: Text(strings.pick(
                          'Download or update', 'Downloaden of updaten')),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: releaseStatusMessage == null
                          ? const SizedBox.shrink()
                          : Container(
                              key: const Key('about-release-status'),
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: releaseStatusIsError
                                    ? AppColors.coral.withValues(alpha: 0.18)
                                    : AppColors.mintLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    releaseStatusIsError
                                        ? Icons.info_outline_rounded
                                        : Icons.check_circle_rounded,
                                    size: 19,
                                    color: releaseStatusIsError
                                        ? AppColors.coral
                                        : AppColors.twilight,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      releaseStatusMessage,
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        height: 1.3,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AboutPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.coffee_outlined,
                            color: AppColors.twilightDark,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            strings.pick(
                              'Buy me a coffee',
                              'Trakteer me op koffie',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.pick(
                        'Enjoying DragonHaven? You can support its further development through Ko-fi.',
                        'Blij met DragonHaven? Via Ko-fi kun je de verdere ontwikkeling steunen.',
                      ),
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.paypal_rounded,
                            key: Key('about-paypal-icon'),
                            color: AppColors.twilight,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              strings.pick(
                                'Payment via PayPal',
                                'Betaling via PayPal',
                              ),
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      key: const Key('about-buy-me-coffee'),
                      onPressed: _supportBusy ? null : _openKofi,
                      icon: _supportBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.open_in_new_rounded, size: 19),
                      label: Text(
                        strings.pick(
                          'Open tip form',
                          'Fooiformulier openen',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRedeemCode() async {
    final controller = TextEditingController();
    final strings = AppStrings.of(context);
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.pick('Redeem code', 'Code inwisselen')),
        content: TextField(
          key: const Key('redeem-code-field'),
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Z]')),
          ],
          decoration: const InputDecoration(hintText: 'DRAGONCODE'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(strings.pick('Redeem', 'Inwisselen'))),
        ],
      ),
    );
    controller.dispose();
    if (code == null || !mounted) return;
    final result = await context.read<HouseholdProvider>().redeemCode(code);
    if (!mounted) return;
    final message = result == 'invalid_format'
        ? strings.pick('Use only connected capital letters.',
            'Gebruik alleen aaneengesloten hoofdletters.')
        : strings.pick('This code is not active.', 'Deze code is niet actief.');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.mist),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.twilight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      );
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1, color: AppColors.mist),
      );
}
