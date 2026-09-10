import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/chest.dart';
import '../models/dragon_lineage.dart';
import '../models/mystic_relic.dart';
import '../models/pet.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_game_snapshot.dart';
import '../services/canonical_trades.dart';
import '../widgets/canonical_game_controls.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/shop_economy_scope.dart';
import 'canonical_eggs.dart';

class CanonicalTradesScreen extends StatelessWidget {
  const CanonicalTradesScreen({super.key, this.keeperCode = ''});
  final String keeperCode;
  @override
  Widget build(BuildContext context) =>
      ShopEconomyBoundary(child: _Trades(keeperCode: keeperCode));
}

class _Trades extends StatefulWidget {
  const _Trades({required this.keeperCode});
  final String keeperCode;
  @override
  State<_Trades> createState() => _TradesState();
}

class _TradesState extends State<_Trades> {
  late final _code = TextEditingController(text: widget.keeperCode);
  Timer? _poll;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh());
    });
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          context.read<CanonicalGameSession>().canAct) {
        unawaited(_refresh());
      }
    });
  }

  Future<void> _refresh() async {
    final session = context.read<CanonicalGameSession>();
    if (session.busy || session.connection.currentOwner == null) return;
    try {
      await session.synchronize();
    } on CanonicalGameException {/* Recovery is exposed by the boundary. */}
  }

  @override
  void dispose() {
    _poll?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _choose(CanonicalGameActions actions, {String? tradeId}) async {
    final code = _code.text.trim().toUpperCase();
    if (tradeId == null && !RegExp(r'^DH-[A-F0-9]{8}$').hasMatch(code)) {
      throw const CanonicalGameException('game_keeper_code_invalid');
    }
    final item = await chooseCanonicalTradeItem(context);
    if (item == null || !mounted) return;
    if (tradeId == null) {
      await actions.offerTrade(code,
          kind: item.kind, key: item.key, variant: item.variant);
    } else {
      await actions.replyTrade(tradeId,
          kind: item.kind, key: item.key, variant: item.variant);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final view = session.snapshot!;
    final board = view.trades;
    final actions = CanonicalGameActions(session);
    final s = AppStrings.of(context);
    return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
            key: const Key('canonical-trades-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                const GameIconSprite(GameIconKind.friendsTrade, size: 42),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(s.pick('Trades', 'Ruilen'),
                        style: Theme.of(context).textTheme.titleLarge)),
                Text('${board.completedToday}/3'),
                IconButton(
                    key: const Key('canonical-refresh-trades'),
                    tooltip: s.pick('Refresh', 'Vernieuwen'),
                    onPressed: session.busy ? null : _refresh,
                    icon: const Icon(Icons.refresh)),
              ]),
              if (!board.hasActive && board.completedToday < 3) ...[
                TextField(
                    key: const Key('canonical-trade-keeper'),
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                        labelText: s.pick("Your friend's Keeper Code",
                            'Keeper Code van je vriend'),
                        hintText: 'DH-12345678')),
                const SizedBox(height: 12),
                CanonicalActionButton(
                    key: const Key('canonical-offer-trade'),
                    label: s.pick('Choose an item to offer',
                        'Kies een voorwerp om te ruilen'),
                    action: session.canAct ? () => _choose(actions) : null),
              ],
              for (final offer in board.offers.where((t) => t.active))
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(offer.otherName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(_status(s, offer)),
                              for (final pair in [
                                (s.pick('You offer', 'Jij biedt'), offer.sent),
                                (
                                  s.pick('You receive', 'Jij ontvangt'),
                                  offer.received
                                ),
                              ])
                                if (pair.$2 != null)
                                  _ItemTile(
                                      item: CanonicalTradeChoice.display(
                                          pair.$2!),
                                      eyebrow: pair.$1),
                              if (!offer.amInitiator &&
                                  offer.status == 'awaiting_recipient')
                                CanonicalActionButton(
                                    key: Key(
                                        'canonical-reply-trade-${offer.id}'),
                                    label: s.pick('Choose your offer',
                                        'Kies jouw aanbod'),
                                    action: () =>
                                        _choose(actions, tradeId: offer.id)),
                              if (offer.amInitiator &&
                                  offer.status == 'awaiting_initiator')
                                CanonicalActionButton(
                                    key: Key(
                                        'canonical-confirm-trade-${offer.id}'),
                                    label: s.pick(
                                        'Complete trade', 'Ruil voltooien'),
                                    confirmation:
                                        '${s.pick('Complete this trade?', 'Deze ruil voltooien?')}\n'
                                        '${_label(s, CanonicalTradeChoice.display(offer.sent!))} ↔ '
                                        '${_label(s, CanonicalTradeChoice.display(offer.received!))}\n'
                                        '${offer.otherName}',
                                    action: () async {
                                      await actions.confirmTrade(offer.id);
                                    }),
                              CanonicalActionButton(
                                  key:
                                      Key('canonical-cancel-trade-${offer.id}'),
                                  label: s.pick(
                                      offer.amInitiator
                                          ? 'Cancel trade'
                                          : 'Decline trade',
                                      offer.amInitiator
                                          ? 'Ruil annuleren'
                                          : 'Ruil afwijzen'),
                                  action: () async {
                                    if (offer.amInitiator) {
                                      await actions.cancelTrade(offer.id);
                                    } else {
                                      await actions.rejectTrade(offer.id);
                                    }
                                  }),
                            ]))),
              if (board.offers.any((t) => !t.active))
                ExpansionTile(
                    title: Text(s.pick('Recent trades', 'Recente ruilen')),
                    children: [
                      for (final offer in board.offers.where((t) => !t.active))
                        ListTile(
                            title: Text(offer.otherName),
                            subtitle: Text(_status(s, offer)))
                    ])
            ]));
  }
}

String _status(AppStrings s, CanonicalTradeOfferView trade) =>
    switch (trade.status) {
      'awaiting_recipient' =>
        s.pick('Waiting for an offer', 'Wachten op een aanbod'),
      'awaiting_initiator' =>
        s.pick('Waiting for confirmation', 'Wachten op bevestiging'),
      'completed' => s.pick('Trade complete', 'Ruil voltooid'),
      'cancelled' => s.pick('Cancelled', 'Geannuleerd'),
      'rejected' => s.pick('Declined', 'Afgewezen'),
      _ => s.pick('Expired', 'Verlopen'),
    };

String _label(AppStrings s, CanonicalTradeChoice item) => item.egg != null
    ? canonicalEggName(s, item.egg!)
    : item.chest != null
        ? item.chest!.label(s.isDutch)
        : '${s.relicName(item.relic!)}${item.variant == 0 ? '' : ' · ${item.variant}%'}';

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, this.eyebrow, this.onTap});
  final CanonicalTradeChoice item;
  final String? eyebrow;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ListTile(
        key: Key('canonical-trade-item-${item.identity}'),
        contentPadding: EdgeInsets.zero,
        leading: SizedBox.square(
            dimension: 48,
            child: item.egg != null
                ? CanonicalEggArt(egg: item.egg!, height: 48)
                : Image.asset(item.chest?.assetPath ?? item.relic!.assetPath,
                    fit: BoxFit.contain)),
        title: Text(_label(s, item)),
        subtitle: eyebrow == null ? null : Text(eyebrow!),
        trailing: const Icon(Icons.info_outline),
        onTap: onTap ?? () => _itemDetails(context, item));
  }
}

Future<CanonicalTradeChoice?> chooseCanonicalTradeItem(
    BuildContext context) async {
  final session = context.read<CanonicalGameSession>();
  final owner = session.snapshot?.ownerId;
  final epoch = session.connection.sessionEpoch;
  if (owner == null || !session.canAct) return null;
  return showDialog<CanonicalTradeChoice>(
      context: context,
      builder: (context) =>
          Consumer<CanonicalGameSession>(builder: (context, live, _) {
            final s = AppStrings.of(context);
            final same = live.snapshot?.ownerId == owner &&
                live.connection.sessionEpoch == epoch;
            final choices = same
                ? CanonicalTradeChoice.available(live.snapshot!)
                : const <CanonicalTradeChoice>[];
            return AlertDialog(
                title: Text(s.pick('Choose an item', 'Kies een voorwerp')),
                content: SizedBox(
                    width: 380,
                    height: 440,
                    child: !same
                        ? Text(gameConnectionMessage(s, 'game_account_changed'))
                        : choices.isEmpty
                            ? Text(s.pick('No tradeable items are available.',
                                'Er zijn geen ruilbare voorwerpen beschikbaar.'))
                            : ListView(children: [
                                for (final item in choices)
                                  _ItemTile(
                                      item: item,
                                      onTap: () async {
                                        final selected = await _itemDetails(
                                            context, item,
                                            choose: true);
                                        if (selected &&
                                            context.mounted &&
                                            live.connection.sessionEpoch ==
                                                epoch &&
                                            live.snapshot?.ownerId == owner &&
                                            live.canAct &&
                                            CanonicalTradeChoice.available(
                                                    live.snapshot!)
                                                .any((c) =>
                                                    c.identity ==
                                                    item.identity)) {
                                          Navigator.pop(context, item);
                                        }
                                      })
                              ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.pick('Close', 'Sluiten')))
                ]);
          }));
}

Future<bool> _itemDetails(BuildContext context, CanonicalTradeChoice item,
    {bool choose = false}) async {
  final session = context.read<CanonicalGameSession>();
  final owner = session.snapshot?.ownerId;
  final epoch = session.connection.sessionEpoch;
  return await showDialog<bool>(
          context: context,
          builder: (context) =>
              Consumer<CanonicalGameSession>(builder: (context, live, _) {
                final s = AppStrings.of(context);
                final same = live.snapshot?.ownerId == owner &&
                    live.connection.sessionEpoch == epoch;
                final egg = item.egg;
                final lineage = dragonLineages
                    .where((l) => l.id == egg?.revealedLineageId)
                    .firstOrNull;
                final law = LawAxis.values
                    .where((l) => l.name == egg?.revealedLawAxis)
                    .firstOrNull;
                final moral = MoralAxis.values
                    .where((m) => m.name == egg?.revealedMoralAxis)
                    .firstOrNull;
                return AlertDialog(
                    title:
                        Text(same ? _label(s, item) : s.pick('Trade', 'Ruil')),
                    content: SingleChildScrollView(
                        child: !same
                            ? Text(gameConnectionMessage(
                                s, 'game_account_changed'))
                            : Column(mainAxisSize: MainAxisSize.min, children: [
                                if (egg != null) ...[
                                  CanonicalEggArt(egg: egg, height: 110),
                                  Text(egg.hint(s.languageCode)),
                                  if (lineage != null)
                                    Text(s.lineageName(lineage)),
                                  if (egg.revealedRarity != null)
                                    Text(canonicalKnownRarity(
                                        s, egg.revealedRarity)),
                                  if (law != null) Text(s.lawAxisName(law)),
                                  if (moral != null)
                                    Text(s.moralAxisName(moral)),
                                  if (egg.tagged)
                                    Text(s.pick('Tagged egg', 'Getagd ei')),
                                ] else ...[
                                  Image.asset(
                                      item.chest?.assetPath ??
                                          item.relic!.assetPath,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.contain),
                                  if (item.relic != null)
                                    Text(s.relicDescription(item.relic!)),
                                ],
                              ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(s.pick('Close', 'Sluiten'))),
                      if (choose)
                        FilledButton(
                            key: const Key('canonical-trade-select-item'),
                            onPressed: same && live.canAct
                                ? () => Navigator.pop(context, true)
                                : null,
                            child: Text(s.pick(
                                'Offer this item', 'Dit voorwerp aanbieden')))
                    ]);
              })) ??
      false;
}
