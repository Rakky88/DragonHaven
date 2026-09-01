import 'trial_phrase_translations.dart';
import 'notification_phrase_translations.dart';
import 'release_phrase_translations.dart';
import 'feature_batch_phrase_translations.dart';
import 'social_phrase_translations.dart';

/// Offline translations for complete, user-visible UI phrases.
///
/// The list order is German, Spanish, French, Italian, Portuguese and
/// Japanese. English and Dutch remain the authored
/// source strings at each call site.
const _languageIndex = <String, int>{
  'de': 0,
  'es': 1,
  'fr': 2,
  'it': 3,
  'pt': 4,
  'ja': 5,
};

String? translatedUiPhrase(String english, String languageCode) {
  final index = _languageIndex[languageCode];
  final values = uiPhraseTranslations[english] ??
      trialPhraseTranslations[english] ??
      featureBatchPhraseTranslations[english] ??
      socialPhraseTranslations[english];
  if (index == null) return null;
  if (values != null && values.length == 6) return values[index];
  return _translatedDynamicUiPhrase(english, languageCode);
}

String _localized(String languageCode, List<String> values) =>
    values[_languageIndex[languageCode]!];

String? _translatedDynamicUiPhrase(String text, String languageCode) {
  String? capture(RegExp expression, [int group = 1]) =>
      expression.firstMatch(text)?.group(group);

  var value = capture(RegExp(r'^NEW (.+) RECORD!$'));
  if (value != null) {
    return _localized(languageCode, [
      'NEUER REKORD FÜR $value!',
      '¡NUEVO RÉCORD DE $value!',
      'NOUVEAU RECORD DE $value !',
      'NUOVO RECORD DI $value!',
      'NOVO RECORDE DE $value!',
      '$valueの新記録！',
    ]);
  }

  value = capture(RegExp(r'^(\d+) treasures revealed$'));
  if (value != null) {
    return _localized(languageCode, [
      '$value Schätze enthüllt',
      '$value tesoros revelados',
      '$value trésors révélés',
      '$value tesori rivelati',
      '$value tesouros revelados',
      '$value個の宝を公開',
    ]);
  }

  value = capture(RegExp(r'^(.+) already has a place in the house\.$'));
  if (value != null) {
    return _localized(languageCode, [
      '$value hat bereits einen Platz im Haus.',
      '$value ya tiene un lugar en la casa.',
      '$value a déjà une place dans la maison.',
      '$value ha già un posto nella casa.',
      '$value já tem um lugar na casa.',
      '$value はすでに家に置かれています。',
    ]);
  }
  value = capture(RegExp(r'^(.+) now has a place in the sanctuary\.$'));
  if (value != null) {
    return _localized(languageCode, [
      '$value hat nun einen Platz im Refugium.',
      '$value ya tiene un lugar en el santuario.',
      '$value a maintenant une place dans le sanctuaire.',
      '$value ora ha un posto nel santuario.',
      '$value agora tem um lugar no santuário.',
      '$value を聖域に置きました。'
    ]);
  }
  final itemRoom = RegExp(r'^(.+) is now in (.+)\.$').firstMatch(text);
  if (itemRoom != null) {
    final item = itemRoom.group(1);
    final room = itemRoom.group(2);
    return _localized(languageCode, [
      '$item befindet sich jetzt in $room.',
      '$item ahora está en $room.',
      '$item se trouve maintenant dans $room.',
      '$item ora si trova in $room.',
      '$item agora está em $room.',
      '$item を$roomに置きました。'
    ]);
  }
  final bought =
      RegExp(r'^(.+) purchased and placed in (.+)!$').firstMatch(text);
  if (bought != null) {
    final item = bought.group(1);
    final room = bought.group(2);
    return _localized(languageCode, [
      '$item gekauft und in $room platziert!',
      '¡$item comprado y colocado en $room!',
      '$item acheté et placé dans $room !',
      '$item acquistato e posizionato in $room!',
      '$item comprado e posicionado em $room!',
      '$item を購入して$roomに配置しました！'
    ]);
  }
  final stage = RegExp(r'^(.+) in the (.+) life stage$').firstMatch(text);
  if (stage != null) {
    final dragon = stage.group(1);
    final form = stage.group(2);
    return _localized(languageCode, [
      '$dragon in der Lebensphase $form',
      '$dragon en la etapa $form',
      '$dragon au stade $form',
      '$dragon nella fase $form',
      '$dragon no estágio $form',
      '$dragon、$form段階'
    ]);
  }
  final houseSummary =
      RegExp(r'^(\d+) items · (\d+) of (\d+) rooms built$').firstMatch(text);
  if (houseSummary != null) {
    final items = houseSummary.group(1);
    final built = houseSummary.group(2);
    final total = houseSummary.group(3);
    return _localized(languageCode, [
      '$items Gegenstände · $built von $total Räumen gebaut',
      '$items objetos · $built de $total habitaciones construidas',
      '$items objets · $built pièces sur $total construites',
      '$items oggetti · $built stanze su $total costruite',
      '$items itens · $built de $total cômodos construídos',
      'アイテム$items個・$total部屋中$built部屋を建築'
    ]);
  }
  value = capture(RegExp(r'^(.+) placed\. Tap elsewhere to move it\.$'));
  if (value != null) {
    return _localized(languageCode, [
      '$value platziert. Tippe auf eine andere Stelle, um es zu verschieben.',
      '$value colocado. Toca otro lugar para moverlo.',
      '$value placé. Touchez ailleurs pour le déplacer.',
      '$value posizionato. Tocca altrove per spostarlo.',
      '$value posicionado. Toque em outro lugar para movê-lo.',
      '$value を配置しました。別の場所をタップすると移動できます。'
    ]);
  }
  value = capture(RegExp(r'^(.+) remaining$'));
  if (value != null) {
    return _localized(languageCode, [
      'Noch $value',
      'Quedan $value',
      'Encore $value',
      'Mancano $value',
      'Faltam $value',
      '残り$value'
    ]);
  }
  final collected = RegExp(r'^(\d+) of (\d+) collected$').firstMatch(text);
  if (collected != null) {
    final owned = collected.group(1);
    final total = collected.group(2);
    return _localized(languageCode, [
      '$owned von $total gesammelt',
      '$owned de $total coleccionados',
      '$owned sur $total collectionnés',
      '$owned su $total raccolti',
      '$owned de $total coletados',
      '$total個中$owned個を収集'
    ]);
  }
  final unlockedCount = RegExp(r'^(\d+) / (\d+) unlocked$').firstMatch(text);
  if (unlockedCount != null) {
    final count = unlockedCount.group(1);
    final total = unlockedCount.group(2);
    return _localized(languageCode, [
      '$count / $total freigeschaltet',
      '$count / $total desbloqueados',
      '$count / $total débloqués',
      '$count / $total sbloccati',
      '$count / $total desbloqueadas',
      '解除済み $count / $total'
    ]);
  }
  value = capture(RegExp(r'^(\d+) more coins needed\.$'));
  if (value != null) {
    return _localized(languageCode, [
      'Noch $value Münzen benötigt.',
      'Faltan $value monedas.',
      'Il manque $value pièces.',
      'Servono altre $value monete.',
      'Faltam $value moedas.',
      'あと$valueコイン必要です。'
    ]);
  }
  value = capture(RegExp(r'^(\d+) more gems needed\.$'));
  if (value != null) {
    return _localized(languageCode, [
      'Noch $value Edelsteine benötigt.',
      'Faltan $value gemas.',
      'Il manque $value gemmes.',
      'Servono altre $value gemme.',
      'Faltam $value gemas.',
      'あと$valueジェム必要です。'
    ]);
  }
  value = capture(RegExp(r'^(\d+) items shown$'));
  if (value != null) {
    return _localized(languageCode, [
      '$value Gegenstände angezeigt',
      '$value objetos mostrados',
      '$value objets affichés',
      '$value oggetti mostrati',
      '$value itens exibidos',
      '$value個のアイテムを表示'
    ]);
  }
  value = capture(RegExp(r'^(.+) is ready for decorating!$'));
  if (value != null) {
    return _localized(languageCode, [
      '$value kann jetzt eingerichtet werden!',
      '¡$value ya se puede decorar!',
      '$value est prêt à être décoré !',
      '$value è pronta per essere decorata!',
      '$value está pronto para decorar!',
      '$value を飾れるようになりました！'
    ]);
  }
  value = capture(RegExp(r'^(.+) added to your rewards\.$'));
  if (value != null) {
    return _localized(languageCode, [
      '$value wurde deinen Belohnungen hinzugefügt.',
      '$value se añadió a tus recompensas.',
      '$value a été ajouté à tes récompenses.',
      '$value è stato aggiunto alle ricompense.',
      '$value foi adicionado às recompensas.',
      '$value を報酬に追加しました。'
    ]);
  }
  value = capture(RegExp(r'^A (.+) has hatched!$'));
  if (value != null) {
    return _localized(languageCode, [
      'Ein $value ist geschlüpft!',
      '¡Ha nacido un $value!',
      'Un $value vient d’éclore !',
      'È nato un $value!',
      'Um $value nasceu!',
      '$value が孵化しました！'
    ]);
  }
  final evolved = RegExp(r'^(.+) evolved into (.+)\.$').firstMatch(text);
  if (evolved != null) {
    final dragon = evolved.group(1);
    final form = evolved.group(2);
    return _localized(languageCode, [
      '$dragon hat sich zu $form entwickelt.',
      '$dragon evolucionó a $form.',
      '$dragon a évolué en $form.',
      '$dragon si è evoluto in $form.',
      '$dragon evoluiu para $form.',
      '$dragon は$formへ進化しました。'
    ]);
  }
  final acquired = RegExp(r'^Acquired (.+) · identity fixed$').firstMatch(text);
  if (acquired != null) {
    final date = acquired.group(1);
    return _localized(languageCode, [
      'Erhalten $date · Identität festgelegt',
      'Obtenido $date · identidad fijada',
      'Obtenu $date · identité fixée',
      'Ottenuto $date · identità fissata',
      'Obtido $date · identidade definida',
      '$dateに入手・中身は確定済み'
    ]);
  }
  value = capture(RegExp(r'^Add a floor · (.+) coins$'));
  if (value != null) {
    return _localized(languageCode, [
      'Etage hinzufügen · $value Münzen',
      'Añadir piso · $value monedas',
      'Ajouter un étage · $value pièces',
      'Aggiungi piano · $value monete',
      'Adicionar andar · $value moedas',
      '階を追加・$valueコイン'
    ]);
  }
  value = capture(RegExp(
      r'^Build this room for (\d+) star coins\? Furniture and progress stay exactly where they are\.$'));
  if (value != null) {
    return _localized(languageCode, [
      'Diesen Raum für $value Sternenmünzen bauen? Möbel und Fortschritt bleiben genau erhalten.',
      '¿Construir esta habitación por $value monedas estelares? Los muebles y el progreso se conservan.',
      'Construire cette pièce pour $value pièces étoilées ? Les meubles et la progression sont conservés.',
      'Costruire questa stanza per $value monete stellari? Mobili e progressi restano invariati.',
      'Construir este cômodo por $value moedas estelares? Móveis e progresso permanecem intactos.',
      'スターコイン$value枚でこの部屋を建てますか？家具と進行状況はそのまま残ります。'
    ]);
  }
  value = capture(RegExp(r'^CRACK (.+)$'));
  if (value != null) {
    return _localized(languageCode, [
      'KNACK $value',
      'CRAC $value',
      'CRAC $value',
      'CRACK $value',
      'CRAC $value',
      'ピシッ $value'
    ]);
  }
  value = capture(RegExp(r'^Claim (.+)$'));
  if (value != null) {
    return _localized(languageCode, [
      '$value abholen',
      'Reclamar $value',
      'Récupérer $value',
      'Riscatta $value',
      'Coletar $value',
      '$valueを受け取る'
    ]);
  }
  value = capture(RegExp(r'^Discard one (.+)\?$'));
  if (value != null) {
    return _localized(languageCode, [
      'Eine $value verwerfen?',
      '¿Descartar un $value?',
      'Jeter un $value ?',
      'Scartare un $value?',
      'Descartar um $value?',
      '$valueを1つ破棄しますか？'
    ]);
  }
  final dragonCount = RegExp(r'^Dragons (\d+)$').firstMatch(text);
  if (dragonCount != null) {
    final count = dragonCount.group(1);
    return _localized(languageCode, [
      'Drachen $count',
      'Dragones $count',
      'Dragons $count',
      'Draghi $count',
      'Dragões $count',
      'ドラゴン $count'
    ]);
  }
  final dragonFamilies = RegExp(r'^Dragon families (\d+)/42$').firstMatch(text);
  if (dragonFamilies != null) {
    final count = dragonFamilies.group(1);
    return _localized(languageCode, [
      'Drachenfamilien $count/42',
      'Familias de dragones $count/42',
      'Familles de dragons $count/42',
      'Famiglie di draghi $count/42',
      'Famílias de dragões $count/42',
      'ドラゴンの系統 $count/42'
    ]);
  }
  final legacyDragons = RegExp(r'^Dragons (\d+)/42$').firstMatch(text);
  if (legacyDragons != null) {
    final count = legacyDragons.group(1);
    return _localized(languageCode, [
      'Drachen $count/42',
      'Dragones $count/42',
      'Dragons $count/42',
      'Draghi $count/42',
      'Dragões $count/42',
      'ドラゴン $count/42'
    ]);
  }
  value = capture(RegExp(r'^Hatches in (.+)$'));
  if (value != null) {
    return _localized(languageCode, [
      'Schlüpft in $value',
      'Eclosiona en $value',
      'Éclosion dans $value',
      'Schiusa tra $value',
      'Choca em $value',
      '孵化まで$value'
    ]);
  }
  value = capture(RegExp(r'^GitHub could not be checked \(code (\d+)\)\.$'));
  if (value != null) {
    return _localized(languageCode, [
      'GitHub konnte nicht geprüft werden (Code $value).',
      'No se pudo comprobar GitHub (código $value).',
      'Impossible de vérifier GitHub (code $value).',
      'Impossibile controllare GitHub (codice $value).',
      'Não foi possível verificar o GitHub (código $value).',
      'GitHubを確認できませんでした（コード$value）。'
    ]);
  }
  final levelPrice = RegExp(r'^Level (\d+) · (\d+) coins$').firstMatch(text);
  if (levelPrice != null) {
    final level = levelPrice.group(1);
    final price = levelPrice.group(2);
    return _localized(languageCode, [
      'Level $level · $price Münzen',
      'Nivel $level · $price monedas',
      'Niveau $level · $price pièces',
      'Livello $level · $price monete',
      'Nível $level · $price moedas',
      'レベル$level・$priceコイン'
    ]);
  }
  value = capture(RegExp(r'^Next form: (.+)$'));
  if (value != null) {
    return _localized(languageCode, [
      'Nächste Form: $value',
      'Siguiente forma: $value',
      'Forme suivante : $value',
      'Forma successiva: $value',
      'Próxima forma: $value',
      '次の形態：$value'
    ]);
  }
  final pack = RegExp(r'^Pack (\d+) of 6$').firstMatch(text);
  if (pack != null) {
    final number = pack.group(1);
    return _localized(languageCode, [
      'Paket $number von 6',
      'Paquete $number de 6',
      'Lot $number sur 6',
      'Pacchetto $number di 6',
      'Pacote $number de 6',
      'パック$number／6'
    ]);
  }
  value = capture(RegExp(r'^(\d+) players$'));
  if (value != null) {
    return _localized(languageCode, [
      '$value Spieler',
      '$value jugadores',
      '$value joueurs',
      '$value giocatori',
      '$value jogadores',
      '$value人のプレイヤー'
    ]);
  }
  value = capture(RegExp(r'^Release (.+)\?$'));
  if (value != null) {
    return _localized(languageCode, [
      '$value freilassen?',
      '¿Liberar a $value?',
      'Libérer $value ?',
      'Liberare $value?',
      'Libertar $value?',
      '$valueを放しますか？'
    ]);
  }
  value = capture(RegExp(r'^Remove (.+)\?$'));
  if (value != null) {
    return _localized(languageCode, [
      '$value entfernen?',
      '¿Quitar $value?',
      'Retirer $value ?',
      'Rimuovere $value?',
      'Remover $value?',
      '$valueを取り外しますか？'
    ]);
  }
  value = capture(RegExp(r'^Selected: (.+)\. Tap the room to place it\.$'));
  if (value != null) {
    return _localized(languageCode, [
      'Ausgewählt: $value. Tippe zum Platzieren auf den Raum.',
      'Seleccionado: $value. Toca la habitación para colocarlo.',
      'Sélection : $value. Touchez la pièce pour le placer.',
      'Selezionato: $value. Tocca la stanza per posizionarlo.',
      'Selecionado: $value. Toque no cômodo para posicioná-lo.',
      '選択中：$value。部屋をタップして配置します。'
    ]);
  }
  value = capture(RegExp(r'^Talk to (.+)$'));
  if (value != null) {
    return _localized(languageCode, [
      'Mit $value sprechen',
      'Hablar con $value',
      'Parler à $value',
      'Parla con $value',
      'Falar com $value',
      '$valueに話しかける'
    ]);
  }
  value = capture(RegExp(r'^(.+) has returned$'));
  if (value != null) {
    return _localized(languageCode, [
      '$value ist zurückgekehrt',
      '$value ha regresado',
      '$value est de retour',
      '$value è tornato',
      '$value retornou',
      '$value が帰還しました'
    ]);
  }
  value = capture(RegExp(r'^You need (\d+) more coins\.$'));
  if (value != null) {
    return _localized(languageCode, [
      'Du brauchst noch $value Münzen.',
      'Necesitas $value monedas más.',
      'Il te faut encore $value pièces.',
      'Ti servono altre $value monete.',
      'Você precisa de mais $value moedas.',
      'あと$valueコイン必要です。'
    ]);
  }
  value = capture(RegExp(
      r'^Your sanctuary reaches level (\d+) before this room can be built\.$'));
  if (value != null) {
    return _localized(languageCode, [
      'Dein Refugium muss Level $value erreichen, bevor dieser Raum gebaut werden kann.',
      'Tu santuario debe alcanzar el nivel $value para construir esta habitación.',
      'Ton sanctuaire doit atteindre le niveau $value avant de construire cette pièce.',
      'Il santuario deve raggiungere il livello $value prima di costruire questa stanza.',
      'Seu santuário precisa alcançar o nível $value antes de construir este cômodo.',
      '聖域がレベル$valueになると、この部屋を建てられます。'
    ]);
  }
  final roaming =
      RegExp(r'^(\d+) / (\d+) roaming · maximum 3 per room$').firstMatch(text);
  if (roaming != null) {
    final selected = roaming.group(1)!;
    final capacity = roaming.group(2)!;
    return _localized(languageCode, [
      '$selected / $capacity unterwegs · maximal 3 pro Raum',
      '$selected / $capacity deambulando · máximo 3 por habitación',
      '$selected / $capacity en liberté · maximum 3 par pièce',
      '$selected / $capacity in giro · massimo 3 per stanza',
      '$selected / $capacity circulando · máximo de 3 por cômodo',
      '$selected / $capacity 体が巡回中・1部屋につき最大3体',
    ]);
  }
  final relicOwnership = RegExp(
    r'^Owned: (\d+) · shop-bought: (\d+) \(untradeable\)$',
  ).firstMatch(text);
  if (relicOwnership != null) {
    final owned = relicOwnership.group(1)!;
    final shopBought = relicOwnership.group(2)!;
    return _localized(languageCode, [
      'Im Besitz: $owned · im Shop gekauft: $shopBought (nicht handelbar)',
      'En propiedad: $owned · compradas en la tienda: $shopBought (no intercambiables)',
      'Possédées : $owned · achetées en boutique : $shopBought (non échangeables)',
      'Posseduti: $owned · acquistati nel negozio: $shopBought (non scambiabili)',
      'Possuídas: $owned · compradas na loja: $shopBought (não negociáveis)',
      '所持数：$owned・ショップ購入：$shopBought（交換不可）',
    ]);
  }
  value = capture(RegExp(
    r'^(.+) added to your Inventory\. This copy is untradeable\.$',
  ));
  if (value != null) {
    return _localized(languageCode, [
      '$value wurde deinem Inventar hinzugefügt. Dieses Exemplar ist nicht handelbar.',
      '$value se añadió a tu inventario. Esta copia no se puede intercambiar.',
      '$value a été ajouté à ton inventaire. Cet exemplaire n’est pas échangeable.',
      '$value è stato aggiunto al tuo inventario. Questa copia non è scambiabile.',
      '$value foi adicionado ao seu inventário. Esta cópia não é negociável.',
      '$value をインベントリに追加しました。この個体は交換できません。',
    ]);
  }
  return null;
}

const uiPhraseTranslations = <String, List<String>>{
  ...notificationPhraseTranslations,
  ...releasePhraseTranslations,
  'Start trade': [
    'Handel starten',
    'Iniciar intercambio',
    "Commencer l'\u00e9change",
    'Avvia scambio',
    'Iniciar troca',
    '\u4ea4\u63db\u3092\u958b\u59cb',
  ],
  'Collapse records': [
    'Rekorde einklappen',
    'Contraer r\u00e9cords',
    'Replier les records',
    'Comprimi record',
    'Recolher recordes',
    '\u8a18\u9332\u3092\u6298\u308a\u305f\u305f\u3080',
  ],
  'Expand records': [
    'Rekorde ausklappen',
    'Expandir r\u00e9cords',
    'D\u00e9plier les records',
    'Espandi record',
    'Expandir recordes',
    '\u8a18\u9332\u3092\u5c55\u958b',
  ],
  'TRADE COMPLETE!': [
    'TAUSCH ABGESCHLOSSEN!',
    '\u00a1INTERCAMBIO COMPLETADO!',
    '\u00c9CHANGE TERMIN\u00c9 !',
    'SCAMBIO COMPLETATO!',
    'TROCA CONCLU\u00cdDA!',
    '\u4ea4\u63db\u5b8c\u4e86\uff01',
  ],
  'The exchange is safely sealed.': [
    'Der Tausch ist sicher besiegelt.',
    'El intercambio ha quedado sellado de forma segura.',
    "L'\u00e9change est scell\u00e9 en toute s\u00e9curit\u00e9.",
    'Lo scambio \u00e8 stato sigillato in sicurezza.',
    'A troca foi selada com seguran\u00e7a.',
    '\u4ea4\u63db\u306f\u5b89\u5168\u306b\u78ba\u5b9a\u3055\u308c\u307e\u3057\u305f\u3002',
  ],
  'YOU SENT': [
    'DU HAST GESENDET',
    'HAS ENVIADO',
    'VOUS AVEZ ENVOY\u00c9',
    'HAI INVIATO',
    'VOC\u00ca ENVIOU',
    '\u3042\u306a\u305f\u304c\u6e21\u3057\u305f\u3082\u306e',
  ],
  'YOU RECEIVED': [
    'DU HAST ERHALTEN',
    'HAS RECIBIDO',
    'VOUS AVEZ RE\u00c7U',
    'HAI RICEVUTO',
    'VOC\u00ca RECEBEU',
    '\u3042\u306a\u305f\u304c\u53d7\u3051\u53d6\u3063\u305f\u3082\u306e',
  ],
  'Cancel group': [
    'Gruppe abbrechen',
    'Cancelar grupo',
    'Annuler le groupe',
    'Annulla gruppo',
    'Cancelar grupo',
    'グループをキャンセル'
  ],
  'Cancel this group?': [
    'Diese Gruppe abbrechen?',
    '¿Cancelar este grupo?',
    'Annuler ce groupe ?',
    'Annullare questo gruppo?',
    'Cancelar este grupo?',
    'このグループをキャンセルしますか？'
  ],
  'Confirm': [
    'Bestätigen',
    'Confirmar',
    'Confirmer',
    'Conferma',
    'Confirmar',
    '確認'
  ],
  'Create group': [
    'Gruppe erstellen',
    'Crear grupo',
    'Créer un groupe',
    'Crea gruppo',
    'Criar grupo',
    'グループを作成'
  ],
  'Friends looking for dragons': [
    'Freunde suchen Drachen',
    'Amigos que buscan dragones',
    'Amis à la recherche de dragons',
    'Amici in cerca di draghi',
    'Amigos à procura de dragões',
    'ドラゴンを探しているフレンド'
  ],
  'Group Adventures are only available to verified online accounts.': [
    'Gruppenabenteuer sind nur für bestätigte Online-Konten verfügbar.',
    'Las Aventuras de grupo solo están disponibles para cuentas verificadas.',
    'Les Aventures de groupe sont réservées aux comptes en ligne vérifiés.',
    'Le Avventure di gruppo sono disponibili solo per gli account verificati.',
    'As Aventuras de grupo só estão disponíveis para contas verificadas.',
    'グループアドベンチャーは認証済みオンラインアカウントでのみ利用できます。'
  ],
  'Group created. Friends can now join.': [
    'Gruppe erstellt. Freunde können jetzt beitreten.',
    'Grupo creado. Tus amigos ya pueden unirse.',
    'Groupe créé. Tes amis peuvent maintenant le rejoindre.',
    'Gruppo creato. Ora gli amici possono unirsi.',
    'Grupo criado. Os amigos já podem participar.',
    'グループを作成しました。フレンドが参加できます。'
  ],
  'Join with a dragon': [
    'Mit einem Drachen beitreten',
    'Unirse con un dragón',
    'Rejoindre avec un dragon',
    'Unisciti con un drago',
    'Participar com um dragão',
    'ドラゴンと参加'
  ],
  'Only friends of the group starter can join.': [
    'Nur Freunde des Gruppengründers können beitreten.',
    'Solo los amigos del creador del grupo pueden unirse.',
    'Seuls les amis du créateur du groupe peuvent le rejoindre.',
    'Solo gli amici di chi ha creato il gruppo possono unirsi.',
    'Só os amigos de quem criou o grupo podem participar.',
    'グループ作成者のフレンドだけが参加できます。'
  ],
  'Participants': [
    'Teilnehmer',
    'Participantes',
    'Participants',
    'Partecipanti',
    'Participantes',
    '参加者'
  ],
  'Remove dragon': [
    'Drachen entfernen',
    'Quitar dragón',
    'Retirer le dragon',
    'Rimuovi drago',
    'Remover dragão',
    'ドラゴンを外す'
  ],
  'Rewards are ready': [
    'Belohnungen sind bereit',
    'Las recompensas están listas',
    'Les récompenses sont prêtes',
    'Le ricompense sono pronte',
    'As recompensas estão prontas',
    '報酬を受け取れます'
  ],
  'Sign in for Group Adventures': [
    'Für Gruppenabenteuer anmelden',
    'Inicia sesión para las Aventuras de grupo',
    'Connecte-toi pour les Aventures de groupe',
    'Accedi per le Avventure di gruppo',
    'Inicia sessão para as Aventuras de grupo',
    'グループアドベンチャーにログイン'
  ],
  'The dragon was removed from the group.': [
    'Der Drache wurde aus der Gruppe entfernt.',
    'El dragón fue retirado del grupo.',
    'Le dragon a été retiré du groupe.',
    'Il drago è stato rimosso dal gruppo.',
    'O dragão foi removido do grupo.',
    'ドラゴンをグループから外しました。'
  ],
  'The group has returned.': [
    'Die Gruppe ist zurückgekehrt.',
    'El grupo ha regresado.',
    'Le groupe est de retour.',
    'Il gruppo è tornato.',
    'O grupo regressou.',
    'グループが帰還しました。'
  ],
  'The journey starts automatically when all requirements are met.': [
    'Die Reise startet automatisch, sobald alle Anforderungen erfüllt sind.',
    'El viaje comienza automáticamente cuando se cumplen todos los requisitos.',
    'Le voyage commence automatiquement lorsque toutes les conditions sont remplies.',
    'Il viaggio inizia automaticamente quando tutti i requisiti sono soddisfatti.',
    'A viagem começa automaticamente quando todos os requisitos forem cumpridos.',
    'すべての条件を満たすと旅が自動的に始まります。'
  ],
  'The reward could not be linked to your local dragon.': [
    'Die Belohnung konnte deinem lokalen Drachen nicht zugeordnet werden.',
    'No se pudo vincular la recompensa con tu dragón local.',
    'La récompense n’a pas pu être associée à ton dragon local.',
    'Non è stato possibile collegare la ricompensa al tuo drago locale.',
    'Não foi possível associar a recompensa ao teu dragão local.',
    '報酬をローカルのドラゴンに反映できませんでした。'
  ],
  'These Group Adventure rewards are not ready yet.': [
    'Diese Gruppenabenteuer-Belohnungen sind noch nicht bereit.',
    'Estas recompensas de la Aventura de grupo aún no están listas.',
    'Ces récompenses d’Aventure de groupe ne sont pas encore prêtes.',
    'Le ricompense di questa Avventura di gruppo non sono ancora pronte.',
    'Estas recompensas da Aventura de grupo ainda não estão prontas.',
    'このグループアドベンチャーの報酬はまだ受け取れません。'
  ],
  'This dragon is already reserved for a Group Adventure.': [
    'Dieser Drache ist bereits für ein Gruppenabenteuer reserviert.',
    'Este dragón ya está reservado para una Aventura de grupo.',
    'Ce dragon est déjà réservé pour une Aventure de groupe.',
    'Questo drago è già riservato per un’Avventura di gruppo.',
    'Este dragão já está reservado para uma Aventura de grupo.',
    'このドラゴンはすでにグループアドベンチャーに予約されています。'
  ],
  'This group has already started or expired.': [
    'Diese Gruppe ist bereits gestartet oder abgelaufen.',
    'Este grupo ya ha comenzado o ha caducado.',
    'Ce groupe a déjà commencé ou a expiré.',
    'Questo gruppo è già partito o è scaduto.',
    'Este grupo já começou ou expirou.',
    'このグループはすでに出発したか期限切れです。'
  ],
  'This group is full.': [
    'Diese Gruppe ist voll.',
    'Este grupo está completo.',
    'Ce groupe est complet.',
    'Questo gruppo è al completo.',
    'Este grupo está cheio.',
    'このグループは満員です。'
  ],
  'This is only possible before the adventure starts.': [
    'Dies ist nur möglich, bevor das Abenteuer beginnt.',
    'Esto solo es posible antes de que comience la aventura.',
    'Cela n’est possible qu’avant le début de l’aventure.',
    'È possibile farlo solo prima dell’inizio dell’avventura.',
    'Isto só é possível antes de a aventura começar.',
    'この操作はアドベンチャー開始前のみ可能です。'
  ],
  'Withdraw': [
    'Zurückziehen',
    'Retirarse',
    'Se retirer',
    'Ritirati',
    'Retirar-se',
    '参加を取り消す'
  ],
  'Withdraw from this group?': [
    'Aus dieser Gruppe zurückziehen?',
    '¿Retirarte de este grupo?',
    'Te retirer de ce groupe ?',
    'Ritirarti da questo gruppo?',
    'Retirar-te deste grupo?',
    'このグループへの参加を取り消しますか？'
  ],
  'You already used this weekly Group Adventure.': [
    'Du hast dieses wöchentliche Gruppenabenteuer bereits genutzt.',
    'Ya has usado esta Aventura de grupo semanal.',
    'Tu as déjà utilisé cette Aventure de groupe hebdomadaire.',
    'Hai già usato questa Avventura di gruppo settimanale.',
    'Já usaste esta Aventura de grupo semanal.',
    '今週のグループアドベンチャーにはすでに参加しています。'
  ],
  "You have already completed this week's Group Adventure.": [
    'Du hast das Gruppenabenteuer dieser Woche bereits abgeschlossen.',
    'Ya has completado la Aventura de grupo de esta semana.',
    'Tu as déjà terminé l’Aventure de groupe de cette semaine.',
    'Hai già completato l’Avventura di gruppo di questa settimana.',
    'Já concluíste a Aventura de grupo desta semana.',
    '今週のグループアドベンチャーはすでに完了しています。'
  ],
  'Your current weekly Group Adventure is reserved. Its lobby or journey stays under Active, then moves to Completed when rewards are ready.':
      [
    'Dein aktuelles wöchentliches Gruppenabenteuer ist reserviert. Lobby oder Reise bleibt unter Aktiv und wechselt zu Abgeschlossen, sobald die Belohnungen bereit sind.',
    'Tu aventura de grupo semanal está reservada. El grupo o viaje permanece en Activas y pasa a Completadas cuando las recompensas están listas.',
    'Ton aventure de groupe hebdomadaire est réservée. Le groupe ou le voyage reste dans Actives, puis passe dans Terminées quand les récompenses sont prêtes.',
    'La tua avventura di gruppo settimanale è riservata. Il gruppo o viaggio resta in Attive e passa a Completate quando le ricompense sono pronte.',
    'Sua aventura de grupo semanal está reservada. O grupo ou jornada fica em Ativas e passa para Concluídas quando as recompensas estão prontas.',
    '今週のグループ冒険は予約済みです。ロビーまたは旅は「進行中」に表示され、報酬の準備ができると「完了」に移動します。'
  ],
  'Your current weekly Group Adventure is reserved. Its lobby or run is shown under Active.':
      [
    'Dein aktuelles wöchentliches Gruppenabenteuer ist reserviert. Die Gruppe oder Reise wird unter „Aktiv“ angezeigt.',
    'Tu Aventura de grupo semanal está reservada. Su grupo o viaje aparece en Activas.',
    'Ton Aventure de groupe hebdomadaire est réservée. Son groupe ou son trajet apparaît dans Actives.',
    'La tua Avventura di gruppo settimanale è riservata. Il gruppo o il viaggio appare in Attive.',
    'A tua Aventura de grupo semanal está reservada. O grupo ou a viagem aparece em Ativas.',
    '今週のグループアドベンチャーは予約済みです。グループまたは旅は「進行中」に表示されます。'
  ],
  'Your dragon': [
    'Dein Drache',
    'Tu dragón',
    'Ton dragon',
    'Il tuo drago',
    'O teu dragão',
    'あなたのドラゴン'
  ],
  'Your dragon joined the group.': [
    'Dein Drache ist der Gruppe beigetreten.',
    'Tu dragón se ha unido al grupo.',
    'Ton dragon a rejoint le groupe.',
    'Il tuo drago si è unito al gruppo.',
    'O teu dragão entrou no grupo.',
    'ドラゴンがグループに参加しました。'
  ],
  'Your dragon left the group.': [
    'Dein Drache hat die Gruppe verlassen.',
    'Tu dragón ha abandonado el grupo.',
    'Ton dragon a quitté le groupe.',
    'Il tuo drago ha lasciato il gruppo.',
    'O teu dragão saiu do grupo.',
    'ドラゴンがグループを離れました。'
  ],
  'Your offline name, portrait and title are used automatically online.': [
    'Dein Offline-Name, Porträt und Titel werden online automatisch verwendet.',
    'Tu nombre, retrato y título sin conexión se usan automáticamente en línea.',
    'Ton nom, ton portrait et ton titre hors ligne sont utilisés automatiquement en ligne.',
    'Il nome, il ritratto e il titolo offline vengono usati automaticamente online.',
    'O teu nome, retrato e título offline são usados automaticamente online.',
    'オフラインの名前、ポートレート、称号がオンラインでも自動的に使われます。'
  ],
  'combined': [
    'kombinierte',
    'combinado',
    'combiné',
    'combinato',
    'combinado',
    '合計'
  ],
  'combined level': [
    'kombiniertes Level',
    'nivel combinado',
    'niveau combiné',
    'livello combinato',
    'nível combinado',
    '合計レベル'
  ],
  'dragons': ['Drachen', 'dragones', 'dragons', 'draghi', 'dragões', 'ドラゴン'],
  'participants': [
    'Teilnehmer',
    'participantes',
    'participants',
    'partecipanti',
    'participantes',
    '参加者'
  ],
  'Confirm your email before signing in.': [
    'Bestätige deine E-Mail-Adresse, bevor du dich anmeldest.',
    'Confirma tu correo electrónico antes de iniciar sesión.',
    'Confirme ton adresse e-mail avant de te connecter.',
    'Conferma la tua e-mail prima di accedere.',
    'Confirme seu e-mail antes de entrar.',
    'ログイン前にメールアドレスを確認してください。',
  ],
  'Create a verified account to add friends by Keeper ID. You must confirm your email before signing in, and it is never shown to other players.':
      [
    'Erstelle ein bestätigtes Konto, um Freunde per Hüter-ID hinzuzufügen. Du musst deine E-Mail vor der Anmeldung bestätigen; sie wird anderen Spielern nie angezeigt.',
    'Crea una cuenta verificada para añadir amigos por ID de Guardián. Debes confirmar tu correo antes de iniciar sesión y nunca se muestra a otros jugadores.',
    'Crée un compte vérifié pour ajouter des amis par ID de Gardien. Tu dois confirmer ton e-mail avant de te connecter; il n’est jamais montré aux autres joueurs.',
    'Crea un account verificato per aggiungere amici tramite ID Custode. Devi confermare l’e-mail prima di accedere e non viene mai mostrata agli altri giocatori.',
    'Crie uma conta verificada para adicionar amigos pelo ID de Guardião. Você deve confirmar o e-mail antes de entrar, e ele nunca é mostrado a outros jogadores.',
    'キーパーIDでフレンドを追加できる認証済みアカウントを作成します。ログイン前にメール確認が必要で、アドレスは他のプレイヤーに表示されません。',
  ],
  'A Mysterious Egg appeared in the tower nest.': [
    'Ein geheimnisvolles Ei ist im Turmnest erschienen.',
    'Un Huevo Misterioso apareció en el nido de la torre.',
    'Un Œuf mystérieux est apparu dans le nid de la tour.',
    'Un Uovo misterioso è apparso nel nido della torre.',
    'Um Ovo Misterioso apareceu no ninho da torre.',
    '塔の巣に不思議な卵が現れました。',
  ],
  'A chest was opened.': [
    'Eine Truhe wurde geöffnet.',
    'Se abrió un cofre.',
    'Un coffre a été ouvert.',
    'È stato aperto un forziere.',
    'Um baú foi aberto.',
    '宝箱を開けました。'
  ],
  'A dragon evolved.': [
    'Ein Drache hat sich entwickelt.',
    'Un dragón ha evolucionado.',
    'Un dragon a évolué.',
    'Un drago si è evoluto.',
    'Um dragão evoluiu.',
    'ドラゴンが進化しました。'
  ],
  'A dragon hatched!': [
    'Ein Drache ist geschlüpft!',
    '¡Ha nacido un dragón!',
    'Un dragon vient d’éclore !',
    'È nato un drago!',
    'Um dragão nasceu!',
    'ドラゴンが孵化しました！'
  ],
  'A familiar shadow returned': [
    'Ein vertrauter Schatten ist zurückgekehrt',
    'Una sombra familiar ha regresado',
    'Une ombre familière est revenue',
    'È tornata un’ombra familiare',
    'Uma sombra familiar retornou',
    '見覚えのある影が戻ってきました'
  ],
  'A global weekly expedition refreshes on Sunday at 12:00 Europe/Amsterdam. Online friends are required.':
      [
    'Eine globale Wochenexpedition wird sonntags um 12:00 Uhr (Europa/Amsterdam) erneuert. Online-Freunde sind erforderlich.',
    'Una expedición semanal global se renueva el domingo a las 12:00 (Europa/Ámsterdam). Se necesitan amigos en línea.',
    'Une expédition hebdomadaire mondiale est renouvelée le dimanche à 12 h (Europe/Amsterdam). Des amis en ligne sont requis.',
    'Una spedizione settimanale globale si aggiorna la domenica alle 12:00 (Europa/Amsterdam). Servono amici online.',
    'Uma expedição semanal global é renovada no domingo às 12:00 (Europa/Amsterdã). Amigos online são necessários.',
    '世界共通の週間遠征は日曜12:00（ヨーロッパ／アムステルダム）に更新されます。オンラインのフレンドが必要です。'
  ],
  'A new form awakens!': [
    'Eine neue Form erwacht!',
    '¡Despierta una nueva forma!',
    'Une nouvelle forme s’éveille !',
    'Si risveglia una nuova forma!',
    'Uma nova forma desperta!',
    '新たな姿が目覚めました！'
  ],
  'A new form is awakening…': [
    'Eine neue Form erwacht …',
    'Una nueva forma está despertando…',
    'Une nouvelle forme s’éveille…',
    'Una nuova forma si sta risvegliando…',
    'Uma nova forma está despertando…',
    '新たな姿が目覚めようとしています…'
  ],
  'A quiet tower. A mysterious egg. A collection waiting to become legend.': [
    'Ein stiller Turm. Ein geheimnisvolles Ei. Eine Sammlung, die zur Legende werden will.',
    'Una torre silenciosa. Un huevo misterioso. Una colección destinada a convertirse en leyenda.',
    'Une tour paisible. Un œuf mystérieux. Une collection qui ne demande qu’à devenir légendaire.',
    'Una torre silenziosa. Un uovo misterioso. Una collezione pronta a diventare leggenda.',
    'Uma torre tranquila. Um ovo misterioso. Uma coleção esperando para virar lenda.',
    '静かな塔。不思議な卵。伝説になる日を待つコレクション。'
  ],
  'A rare Tower moment': [
    'Ein seltener Turmmoment',
    'Un momento especial en la Torre',
    'Un instant rare dans la Tour',
    'Un raro momento nella Torre',
    'Um momento raro na Torre',
    '塔での特別なひととき'
  ],
  'A sanctuary activity was completed.': [
    'Eine Aktivität im Refugium wurde abgeschlossen.',
    'Se completó una actividad del santuario.',
    'Une activité du sanctuaire a été terminée.',
    'È stata completata un’attività del santuario.',
    'Uma atividade do santuário foi concluída.',
    'サンクチュアリの活動を完了しました。'
  ],
  'A secret life is waiting inside one familiar shell.': [
    'In einer vertrauten Schale wartet ein geheimes Leben.',
    'Una vida secreta espera dentro de una cáscara familiar.',
    'Une vie secrète attend dans une coquille familière.',
    'Una vita segreta attende dentro un guscio familiare.',
    'Uma vida secreta espera dentro de uma casca familiar.',
    '見慣れた殻の中で、秘密の命が待っています。'
  ],
  'A soft glow fills every wellbeing bar.': [
    'Ein sanftes Leuchten füllt alle Wohlfühlleisten.',
    'Un brillo suave llena todas las barras de bienestar.',
    'Une douce lueur remplit toutes les jauges de bien-être.',
    'Un bagliore delicato riempie tutte le barre del benessere.',
    'Um brilho suave preenche todas as barras de bem-estar.',
    'やわらかな光がすべてのコンディションゲージを満たします。'
  ],
  'ABOUT THE GAME': [
    'ÜBER DAS SPIEL',
    'ACERCA DEL JUEGO',
    'À PROPOS DU JEU',
    'INFORMAZIONI SUL GIOCO',
    'SOBRE O JOGO',
    'ゲームについて'
  ],
  'About DragonHaven': [
    'Über DragonHaven',
    'Acerca de DragonHaven',
    'À propos de DragonHaven',
    'Informazioni su DragonHaven',
    'Sobre DragonHaven',
    'DragonHavenについて'
  ],
  'Achievement unlocked!': [
    'Erfolg freigeschaltet!',
    '¡Logro desbloqueado!',
    'Succès débloqué !',
    'Obiettivo sbloccato!',
    'Conquista desbloqueada!',
    '実績を解除しました！'
  ],
  'Activate egg': [
    'Ei aktivieren',
    'Activar huevo',
    'Activer l’œuf',
    'Attiva uovo',
    'Ativar ovo',
    '卵を育てる'
  ],
  'Active expeditions': [
    'Aktive Expeditionen',
    'Expediciones activas',
    'Expéditions en cours',
    'Spedizioni attive',
    'Expedições ativas',
    '進行中の遠征'
  ],
  'Add a keeper': [
    'Drachenhüter hinzufügen',
    'Añadir cuidador',
    'Ajouter un gardien',
    'Aggiungi custode',
    'Adicionar guardião',
    'キーパーを追加'
  ],
  'Adventure rewards will appear here and on Adventure.': [
    'Abenteuerbelohnungen erscheinen hier und im Bereich Abenteuer.',
    'Las recompensas de aventura aparecerán aquí y en Aventura.',
    'Les récompenses d’aventure apparaîtront ici et dans Aventure.',
    'Le ricompense delle avventure appariranno qui e in Avventura.',
    'As recompensas de aventura aparecerão aqui e em Aventura.',
    '冒険の報酬は、ここ及び「冒険」に表示されます。'
  ],
  'Adventure rewards are stored here.': [
    'Abenteuerbelohnungen werden hier aufbewahrt.',
    'Las recompensas de aventura se guardan aquí.',
    'Les récompenses d’aventure sont conservées ici.',
    'Le ricompense delle avventure vengono conservate qui.',
    'As recompensas de aventura ficam guardadas aqui.',
    '冒険の報酬はここに保管されます。'
  ],
  'Adventure started.': [
    'Abenteuer gestartet.',
    'Aventura iniciada.',
    'Aventure lancée.',
    'Avventura iniziata.',
    'Aventura iniciada.',
    '冒険を開始しました。'
  ],
  'Adventuring': [
    'Auf Abenteuer',
    'De aventura',
    'En aventure',
    'In avventura',
    'Em aventura',
    '冒険中'
  ],
  'All': ['Alle', 'Todo', 'Tout', 'Tutto', 'Tudo', 'すべて'],
  'An egg cannot go adventuring.': [
    'Ein Ei kann nicht auf Abenteuer gehen.',
    'Un huevo no puede ir de aventura.',
    'Un œuf ne peut pas partir à l’aventure.',
    'Un uovo non può partire all’avventura.',
    'Um ovo não pode partir em aventura.',
    '卵は冒険に出られません。'
  ],
  'Android download link copied.': [
    'Android-Downloadlink kopiert.',
    'Enlace de descarga de Android copiado.',
    'Lien de téléchargement Android copié.',
    'Link per il download Android copiato.',
    'Link de download do Android copiado.',
    'Androidのダウンロードリンクをコピーしました。'
  ],
  'Arcana is currently leading.': [
    'Arcana liegt derzeit vorn.',
    'Arcana está en cabeza.',
    'Arcana est actuellement en tête.',
    'Arcana è attualmente in testa.',
    'Arcana está na frente.',
    '現在はアルカナが優勢です。'
  ],
  'Archived permanently; every day it has a 10% chance to return at a random time.':
      [
    'Dauerhaft archiviert; jeden Tag besteht eine Chance von 10 %, dass der Drache zu einer zufälligen Zeit zurückkehrt.',
    'Archivado permanentemente; cada día tiene un 10 % de probabilidad de volver a una hora aleatoria.',
    'Archivé définitivement ; chaque jour, il a 10 % de chances de revenir à une heure aléatoire.',
    'Archiviato per sempre; ogni giorno ha il 10% di probabilità di tornare a un orario casuale.',
    'Arquivado permanentemente; todos os dias tem 10% de chance de voltar em um horário aleatório.',
    '永久に記録され、毎日10%の確率でランダムな時刻に戻ってきます。'
  ],
  'Ascension complete': [
    'Aufstieg abgeschlossen',
    'Ascensión completada',
    'Ascension terminée',
    'Ascensione completata',
    'Ascensão concluída',
    '昇華完了'
  ],
  'Ascension paths': [
    'Aufstiegspfade',
    'Sendas de ascensión',
    'Voies d’ascension',
    'Percorsi di ascensione',
    'Caminhos da ascensão',
    '昇華の道'
  ],
  'Ascended': [
    'Erhaben',
    'Ascendido',
    'Transcendé',
    'Asceso',
    'Ascendido',
    '昇華竜'
  ],
  'Audio': ['Audio', 'Audio', 'Audio', 'Audio', 'Áudio', 'オーディオ'],
  'Begin hatching': [
    'Schlüpfen beginnen',
    'Iniciar eclosión',
    'Commencer l’éclosion',
    'Inizia la schiusa',
    'Iniciar eclosão',
    '孵化を始める'
  ],
  'Both keepers must offer at least one egg, chest or item and confirm the final trade.':
      [
    'Beide Hüter müssen mindestens ein Ei, eine Truhe oder einen Gegenstand anbieten und den endgültigen Tausch bestätigen.',
    'Ambos cuidadores deben ofrecer al menos un huevo, cofre u objeto y confirmar el intercambio final.',
    'Les deux gardiens doivent proposer au moins un œuf, un coffre ou un objet et confirmer l’échange final.',
    'Entrambi i custodi devono offrire almeno un uovo, un forziere o un oggetto e confermare lo scambio finale.',
    'Os dois guardiões devem oferecer pelo menos um ovo, baú ou item e confirmar a troca final.',
    '双方のキーパーが卵、宝箱、アイテムのいずれかを1つ以上提示し、最終的な交換を承認する必要があります。'
  ],
  'Both settings react immediately and are stored independently for this local account.':
      [
    'Beide Einstellungen wirken sofort und werden für dieses lokale Konto getrennt gespeichert.',
    'Ambos ajustes se aplican al instante y se guardan por separado para esta cuenta local.',
    'Les deux réglages s’appliquent immédiatement et sont enregistrés séparément pour ce compte local.',
    'Entrambe le impostazioni hanno effetto immediato e vengono salvate separatamente per questo account locale.',
    'As duas configurações têm efeito imediato e são salvas separadamente para esta conta local.',
    'どちらの設定もすぐに反映され、このローカルアカウントに個別に保存されます。'
  ],
  'Build a home that grows with your dragon.': [
    'Baue ein Zuhause, das mit deinem Drachen wächst.',
    'Construye un hogar que crezca con tu dragón.',
    'Construis un foyer qui grandit avec ton dragon.',
    'Costruisci una casa che cresca con il tuo drago.',
    'Construa um lar que cresça com seu dragão.',
    'ドラゴンとともに成長する住まいを作りましょう。'
  ],
  'Build room': [
    'Raum bauen',
    'Construir habitación',
    'Construire la pièce',
    'Costruisci stanza',
    'Construir cômodo',
    '部屋を建てる'
  ],
  'Built and ready': [
    'Gebaut und bereit',
    'Construido y listo',
    'Construit et prêt',
    'Costruita e pronta',
    'Construído e pronto',
    '建築済み'
  ],
  'Built in': [
    'Entstanden',
    'Creada en',
    'Créée en',
    'Realizzata nel',
    'Criado em',
    '制作年'
  ],
  'Buy gems': [
    'Edelsteine kaufen',
    'Comprar gemas',
    'Acheter des gemmes',
    'Compra gemme',
    'Comprar gemas',
    'ジェムを購入'
  ],
  'Buy me a coffee': [
    'Spendiere mir einen Kaffee',
    'Invítame a un café',
    'Offrez-moi un café',
    'Offrimi un caffè',
    'Pague-me um café',
    'コーヒーで応援'
  ],
  'Cancel': [
    'Abbrechen',
    'Cancelar',
    'Annuler',
    'Annulla',
    'Cancelar',
    'キャンセル'
  ],
  'Chests': ['Truhen', 'Cofres', 'Coffres', 'Forzieri', 'Baús', '宝箱'],
  'Choose a name': [
    'Namen wählen',
    'Elige un nombre',
    'Choisir un nom',
    'Scegli un nome',
    'Escolha um nome',
    '名前を選ぶ'
  ],
  'Choose a name first.': [
    'Wähle zuerst einen Namen.',
    'Elige primero un nombre.',
    'Choisis d’abord un nom.',
    'Scegli prima un nome.',
    'Escolha um nome primeiro.',
    'まず名前を決めてください。'
  ],
  'Choose a room type': [
    'Raumtyp wählen',
    'Elige un tipo de habitación',
    'Choisir un type de pièce',
    'Scegli un tipo di stanza',
    'Escolha um tipo de cômodo',
    '部屋の種類を選ぶ'
  ],
  'Claim the Starter Egg': [
    'Starter-Ei annehmen',
    'Recoger el Huevo Inicial',
    'Récupérer l’Œuf de départ',
    'Ottieni l’Uovo iniziale',
    'Receber o Ovo Inicial',
    '最初の卵を受け取る'
  ],
  'Clear search': [
    'Suche löschen',
    'Borrar búsqueda',
    'Effacer la recherche',
    'Cancella ricerca',
    'Limpar pesquisa',
    '検索を消去'
  ],
  'Cloud Sanctuary': [
    'Wolkenrefugium',
    'Santuario de las Nubes',
    'Sanctuaire des Nuages',
    'Santuario delle Nuvole',
    'Santuário das Nuvens',
    '雲の聖域'
  ],
  'Dragon Chest': [
    'Drachentruhe',
    'Cofre de Dragón',
    'Coffre du Dragon',
    'Forziere del Drago',
    'Baú de Dragão',
    'ドラゴンの宝箱'
  ],
  'Coin furniture': [
    'Münzmöbel',
    'Muebles por monedas',
    'Meubles contre des pièces',
    'Mobili con monete',
    'Móveis por moedas',
    'コイン家具'
  ],
  'Collect': [
    'Einsammeln',
    'Recoger',
    'Récupérer',
    'Raccogli',
    'Coletar',
    '受け取る'
  ],
  'Collect furniture for every dragon room.': [
    'Sammle Möbel für jedes Drachenzimmer.',
    'Colecciona muebles para todas las habitaciones de dragones.',
    'Collectionne des meubles pour chaque pièce des dragons.',
    'Colleziona mobili per ogni stanza dei draghi.',
    'Colecione móveis para cada cômodo dos dragões.',
    'すべてのドラゴン部屋に置く家具を集めましょう。'
  ],
  'Comfort': ['Komfort', 'Comodidad', 'Confort', 'Comfort', 'Conforto', '快適さ'],
  'Common': ['Gewöhnlich', 'Común', 'Commun', 'Comune', 'Comum', 'コモン'],
  'Compact view': [
    'Kompaktansicht',
    'Vista compacta',
    'Vue compacte',
    'Vista compatta',
    'Visualização compacta',
    'コンパクト表示'
  ],
  'Connect online friends before joining a Group Adventure.': [
    'Verbinde dich mit Online-Freunden, bevor du einem Gruppenabenteuer beitrittst.',
    'Conecta amigos en línea antes de unirte a una aventura grupal.',
    'Connecte des amis en ligne avant de rejoindre une aventure de groupe.',
    'Collega amici online prima di partecipare a un’avventura di gruppo.',
    'Conecte amigos online antes de entrar em uma aventura em grupo.',
    'グループ冒険に参加する前に、オンラインのフレンドと接続してください。'
  ],
  'Copy download link': [
    'Downloadlink kopieren',
    'Copiar enlace de descarga',
    'Copier le lien de téléchargement',
    'Copia link di download',
    'Copiar link de download',
    'ダウンロードリンクをコピー'
  ],
  'Copy one permanent Android download link for someone else, or open it to install the latest release over this app. Your progress stays safe.':
      [
    'Kopiere einen dauerhaften Android-Downloadlink für andere oder öffne ihn, um die neueste Version über dieser App zu installieren. Dein Fortschritt bleibt erhalten.',
    'Copia un enlace permanente de descarga para Android o ábrelo para instalar la última versión sobre esta aplicación. Tu progreso se conserva.',
    'Copiez un lien Android permanent ou ouvrez-le pour installer la dernière version par-dessus cette application. Votre progression est conservée.',
    'Copia un link Android permanente oppure aprilo per installare l’ultima versione sopra questa app. I progressi restano al sicuro.',
    'Copie um link permanente de download para Android ou abra-o para instalar a versão mais recente sobre este app. Seu progresso fica seguro.',
    'Android用の固定ダウンロードリンクを共有用にコピーするか、開いて最新版を上書きインストールできます。進行状況は保持されます。'
  ],
  'Created by': [
    'Erstellt von',
    'Creado por',
    'Créé par',
    'Creato da',
    'Criado por',
    '制作者'
  ],
  'Crystal Grotto': [
    'Kristallgrotte',
    'Gruta de Cristal',
    'Grotte de Cristal',
    'Grotta di Cristallo',
    'Gruta de Cristal',
    '水晶の洞窟'
  ],
  'Curious': ['Neugierig', 'Curioso', 'Curieux', 'Curioso', 'Curioso', '好奇心旺盛'],
  'Decorate': [
    'Dekorieren',
    'Decorar',
    'Décorer',
    'Decora',
    'Decorar',
    '飾りつける'
  ],
  'Discard': ['Verwerfen', 'Descartar', 'Jeter', 'Scarta', 'Descartar', '破棄'],
  'Discard egg': [
    'Ei verwerfen',
    'Descartar huevo',
    'Jeter l’œuf',
    'Scarta uovo',
    'Descartar ovo',
    '卵を破棄'
  ],
  'Discard one chest': [
    'Eine Truhe verwerfen',
    'Descartar un cofre',
    'Jeter un coffre',
    'Scarta un forziere',
    'Descartar um baú',
    '宝箱を1つ破棄'
  ],
  'Discard this Mysterious Egg?': [
    'Dieses geheimnisvolle Ei verwerfen?',
    '¿Descartar este Huevo Misterioso?',
    'Jeter cet Œuf mystérieux ?',
    'Scartare questo Uovo misterioso?',
    'Descartar este Ovo Misterioso?',
    'この不思議な卵を破棄しますか？'
  ],
  'Dismiss': [
    'Wegschicken',
    'Descartar',
    'Ignorer',
    'Congeda',
    'Dispensar',
    '見送る'
  ],
  'Download or update': [
    'Herunterladen oder aktualisieren',
    'Descargar o actualizar',
    'Télécharger ou mettre à jour',
    'Scarica o aggiorna',
    'Baixar ou atualizar',
    'ダウンロード／更新'
  ],
  'Dragon care': [
    'Drachenpflege',
    'Cuidado del dragón',
    'Soins du dragon',
    'Cura del drago',
    'Cuidados do dragão',
    'ドラゴンのお世話'
  ],
  'Dragon keeper': [
    'Drachenhüter',
    'Cuidador de dragones',
    'Gardien de dragons',
    'Custode dei draghi',
    'Guardião de dragões',
    'ドラゴンキーパー'
  ],
  'Dragon name': [
    'Drachenname',
    'Nombre del dragón',
    'Nom du dragon',
    'Nome del drago',
    'Nome do dragão',
    'ドラゴンの名前'
  ],
  'Dragon room': [
    'Drachenzimmer',
    'Habitación del dragón',
    'Pièce des dragons',
    'Stanza dei draghi',
    'Cômodo dos dragões',
    'ドラゴンの部屋'
  ],
  'Dragon sanctuary': [
    'Drachenrefugium',
    'Santuario de dragones',
    'Sanctuaire des dragons',
    'Santuario dei draghi',
    'Santuário dos dragões',
    'ドラゴンの聖域'
  ],
  'DragonHaven logo': [
    'DragonHaven-Logo',
    'Logotipo de DragonHaven',
    'Logo de DragonHaven',
    'Logo di DragonHaven',
    'Logo do DragonHaven',
    'DragonHavenのロゴ'
  ],
  'EDIT MODE': [
    'BEARBEITUNG',
    'MODO EDICIÓN',
    'MODE ÉDITION',
    'MODALITÀ MODIFICA',
    'MODO DE EDIÇÃO',
    '編集モード'
  ],
  'Each room is permanent and can be decorated independently.': [
    'Jeder Raum bleibt dauerhaft bestehen und kann einzeln eingerichtet werden.',
    'Cada habitación es permanente y puede decorarse por separado.',
    'Chaque pièce est permanente et peut être décorée séparément.',
    'Ogni stanza è permanente e può essere decorata separatamente.',
    'Cada cômodo é permanente e pode ser decorado separadamente.',
    '各部屋はずっと残り、それぞれ別々に飾れます。'
  ],
  'Edit keeper name': [
    'Hüternamen ändern',
    'Editar nombre del cuidador',
    'Modifier le nom du gardien',
    'Modifica nome del custode',
    'Editar nome do guardião',
    'キーパー名を編集'
  ],
  'Edit name': [
    'Namen ändern',
    'Editar nombre',
    'Modifier le nom',
    'Modifica nome',
    'Editar nome',
    '名前を編集'
  ],
  'Egg': ['Ei', 'Huevo', 'Œuf', 'Uovo', 'Ovo', '卵'],
  'Egg moved to the rooftop nest.': [
    'Das Ei wurde ins Dachnest gebracht.',
    'El huevo se trasladó al nido de la azotea.',
    'L’œuf a été déplacé dans le nid du toit.',
    'L’uovo è stato spostato nel nido sul tetto.',
    'O ovo foi levado para o ninho no telhado.',
    '卵を屋上の巣へ移しました。'
  ],
  'Egg inventory': [
    'Eierinventar',
    'Inventario de huevos',
    'Inventaire des œufs',
    'Inventario delle uova',
    'Inventário de ovos',
    '卵の所持品'
  ],
  'Eggs': ['Eier', 'Huevos', 'Œufs', 'Uova', 'Ovos', '卵'],
  'Energy': ['Energie', 'Energía', 'Énergie', 'Energia', 'Energia', '元気'],
  'Enjoying DragonHaven? You can support its further development through Ko-fi.':
      [
    'Gefällt dir DragonHaven? Über Ko-fi kannst du die weitere Entwicklung unterstützen.',
    '¿Te gusta DragonHaven? Puedes apoyar su desarrollo en Ko-fi.',
    'Vous aimez DragonHaven ? Soutenez son développement sur Ko-fi.',
    'Ti piace DragonHaven? Puoi sostenerne lo sviluppo su Ko-fi.',
    'Está gostando do DragonHaven? Apoie o desenvolvimento pelo Ko-fi.',
    'DragonHavenを楽しんでいますか？Ko-fiから今後の開発を支援できます。'
  ],
  'Event, code and returning-dragon adventures stay available for 48 hours.': [
    'Event-, Code- und Rückkehrer-Abenteuer bleiben 48 Stunden verfügbar.',
    'Las aventuras de evento, código y dragones que regresan duran 48 horas.',
    'Les aventures d’événement, de code et de dragons de retour restent disponibles 48 heures.',
    'Le avventure evento, codice e drago di ritorno restano disponibili per 48 ore.',
    'Aventuras de evento, código e dragão retornando ficam disponíveis por 48 horas.',
    'イベント、コード、帰還ドラゴンの冒険は48時間有効です。'
  ],
  'Evolve now': [
    'Jetzt entwickeln',
    'Evolucionar ahora',
    'Évoluer maintenant',
    'Evolvi ora',
    'Evoluir agora',
    '今すぐ進化'
  ],
  'Expand the sanctuary': [
    'Refugium erweitern',
    'Ampliar el santuario',
    'Agrandir le sanctuaire',
    'Espandi il santuario',
    'Expandir o santuário',
    '聖域を拡張'
  ],
  'Finish': ['Fertig', 'Terminar', 'Terminer', 'Fine', 'Concluir', '完了'],
  'For example: Ember': [
    'Zum Beispiel: Ember',
    'Por ejemplo: Ember',
    'Par exemple : Ember',
    'Per esempio: Ember',
    'Por exemplo: Ember',
    '例：Ember'
  ],
  'For example: Rick': [
    'Zum Beispiel: Rick',
    'Por ejemplo: Rick',
    'Par exemple : Rick',
    'Per esempio: Rick',
    'Por exemplo: Rick',
    '例：Rick'
  ],
  'Furniture': ['Möbel', 'Muebles', 'Meubles', 'Mobili', 'Móveis', '家具'],
  'Gem furniture': [
    'Edelsteinmöbel',
    'Muebles por gemas',
    'Meubles contre des gemmes',
    'Mobili con gemme',
    'Móveis por gemas',
    'ジェム家具'
  ],
  'Gold Chest': [
    'Goldtruhe',
    'Cofre de Oro',
    'Coffre en Or',
    'Forziere d’Oro',
    'Baú de Ouro',
    '金の宝箱'
  ],
  'GitHub returned unexpected release data.': [
    'GitHub hat unerwartete Releasedaten zurückgegeben.',
    'GitHub devolvió datos de versión inesperados.',
    'GitHub a renvoyé des données de version inattendues.',
    'GitHub ha restituito dati di versione imprevisti.',
    'O GitHub retornou dados de versão inesperados.',
    'GitHubから予期しないリリースデータが返されました。'
  ],
  'Good afternoon': [
    'Guten Tag',
    'Buenas tardes',
    'Bonjour',
    'Buon pomeriggio',
    'Boa tarde',
    'こんにちは'
  ],
  'Good evening': [
    'Guten Abend',
    'Buenas noches',
    'Bonsoir',
    'Buonasera',
    'Boa noite',
    'こんばんは'
  ],
  'Good morning': [
    'Guten Morgen',
    'Buenos días',
    'Bonjour',
    'Buongiorno',
    'Bom dia',
    'おはようございます'
  ],
  'Greenery': [
    'Grünpflanzen',
    'Vegetación',
    'Verdure',
    'Piante',
    'Plantas',
    '植物'
  ],
  'Group': ['Gruppe', 'Grupo', 'Groupe', 'Gruppo', 'Grupo', 'グループ'],
  'HERE': ['HIER', 'AQUÍ', 'ICI', 'QUI', 'AQUI', 'この部屋'],
  'Hearth room': [
    'Feuerzimmer',
    'Sala del Hogar',
    'Salle du Foyer',
    'Sala del Focolare',
    'Sala da Lareira',
    '暖炉の間'
  ],
  'Hatchling': [
    'Schlüpfling',
    'Cría',
    'Nouveau-né',
    'Cucciolo',
    'Filhote',
    '幼竜'
  ],
  'Hidden chest': [
    'Verborgene Truhe',
    'Cofre oculto',
    'Coffre caché',
    'Forziere nascosto',
    'Baú oculto',
    '隠された宝箱'
  ],
  'House inventory': [
    'Hausinventar',
    'Inventario de la casa',
    'Inventaire de la maison',
    'Inventario della casa',
    'Inventário da casa',
    '家の持ち物'
  ],
  'House item': [
    'Hausgegenstand',
    'Objeto de la casa',
    'Objet de maison',
    'Oggetto per la casa',
    'Item da casa',
    '家のアイテム'
  ],
  'House shop': [
    'Hausladen',
    'Tienda de la casa',
    'Boutique de la maison',
    'Negozio della casa',
    'Loja da casa',
    '家具ショップ'
  ],
  'INVENTORY': [
    'INVENTAR',
    'INVENTARIO',
    'INVENTAIRE',
    'INVENTARIO',
    'INVENTÁRIO',
    '持ち物'
  ],
  'In Tower': [
    'Im Turm',
    'En la Torre',
    'Dans la Tour',
    'Nella Torre',
    'Na Torre',
    '塔にいる'
  ],
  'Incubate': ['Ausbrüten', 'Incubar', 'Incuber', 'Incuba', 'Incubar', '孵す'],
  'Its unopened contents will be lost.': [
    'Der ungeöffnete Inhalt geht verloren.',
    'Su contenido sin abrir se perderá.',
    'Son contenu non ouvert sera perdu.',
    'Il contenuto non aperto andrà perduto.',
    'O conteúdo fechado será perdido.',
    '未開封の中身は失われます。'
  ],
  'Joy': ['Freude', 'Alegría', 'Joie', 'Gioia', 'Alegria', '喜び'],
  'Keep this name': [
    'Namen behalten',
    'Guardar este nombre',
    'Garder ce nom',
    'Conferma questo nome',
    'Manter este nome',
    'この名前にする'
  ],
  'Ko-fi could not be opened or copied.': [
    'Ko-fi konnte weder geöffnet noch kopiert werden.',
    'No se pudo abrir ni copiar Ko-fi.',
    'Impossible d’ouvrir ou de copier Ko-fi.',
    'Impossibile aprire o copiare Ko-fi.',
    'Não foi possível abrir nem copiar o Ko-fi.',
    'Ko-fiを開くこともコピーすることもできませんでした。'
  ],
  'Ko-fi could not be opened. The link was copied instead.': [
    'Ko-fi konnte nicht geöffnet werden. Der Link wurde stattdessen kopiert.',
    'No se pudo abrir Ko-fi. Se copió el enlace.',
    'Impossible d’ouvrir Ko-fi. Le lien a été copié.',
    'Impossibile aprire Ko-fi. Il link è stato copiato.',
    'Não foi possível abrir o Ko-fi. O link foi copiado.',
    'Ko-fiを開けなかったため、リンクをコピーしました。'
  ],
  'List view': [
    'Listenansicht',
    'Vista de lista',
    'Vue en liste',
    'Vista elenco',
    'Visualização em lista',
    'リスト表示'
  ],
  'Listen to the mysterious egg': [
    'Dem geheimnisvollen Ei lauschen',
    'Escuchar el huevo misterioso',
    'Écouter l’œuf mystérieux',
    'Ascolta l’uovo misterioso',
    'Ouvir o ovo misterioso',
    '不思議な卵に耳を澄ます'
  ],
  'Long': ['Lang', 'Larga', 'Longue', 'Lunga', 'Longa', 'ロング'],
  'Magic': ['Magie', 'Magia', 'Magie', 'Magia', 'Magia', '魔法'],
  'Maximum height reached': [
    'Maximale Höhe erreicht',
    'Altura máxima alcanzada',
    'Hauteur maximale atteinte',
    'Altezza massima raggiunta',
    'Altura máxima alcançada',
    '最高階に到達'
  ],
  'Might is currently leading.': [
    'Macht liegt derzeit vorn.',
    'Poder está en cabeza.',
    'Puissance est actuellement en tête.',
    'Potenza è attualmente in testa.',
    'Poder está na frente.',
    '現在はマイトが優勢です。'
  ],
  'Moon garden': [
    'Mondgarten',
    'Jardín Lunar',
    'Jardin Lunaire',
    'Giardino Lunare',
    'Jardim Lunar',
    '月の庭園'
  ],
  'My dragons': [
    'Meine Drachen',
    'Mis dragones',
    'Mes dragons',
    'I miei draghi',
    'Meus dragões',
    'マイドラゴン'
  ],
  'Mysterious Egg': [
    'Geheimnisvolles Ei',
    'Huevo Misterioso',
    'Œuf mystérieux',
    'Uovo misterioso',
    'Ovo Misterioso',
    '不思議な卵'
  ],
  'Mythical Chest': [
    'Mythische Truhe',
    'Cofre Mítico',
    'Coffre Mythique',
    'Forziere Mitico',
    'Baú Mítico',
    '神話の宝箱'
  ],
  'New evolution!': [
    'Neue Entwicklung!',
    '¡Nueva evolución!',
    'Nouvelle évolution !',
    'Nuova evoluzione!',
    'Nova evolução!',
    '新たな進化！'
  ],
  'Name your dragon': [
    'Gib deinem Drachen einen Namen',
    'Ponle nombre a tu dragón',
    'Nomme ton dragon',
    'Dai un nome al tuo drago',
    'Dê um nome ao seu dragão',
    'ドラゴンに名前をつける'
  ],
  'Nest room': [
    'Nestzimmer',
    'Sala del Nido',
    'Salle du Nid',
    'Sala del Nido',
    'Sala do Ninho',
    '巣の間'
  ],
  'No Mysterious Eggs in your inventory yet.': [
    'Du hast noch keine geheimnisvollen Eier im Inventar.',
    'Aún no hay Huevos Misteriosos en tu inventario.',
    'Aucun Œuf mystérieux dans votre inventaire pour le moment.',
    'Non ci sono ancora Uova misteriose nel tuo inventario.',
    'Ainda não há Ovos Misteriosos no seu inventário.',
    '所持品にはまだ不思議な卵がありません。'
  ],
  'No internet connection. Please try again later.': [
    'Keine Internetverbindung. Bitte versuche es später erneut.',
    'Sin conexión a Internet. Inténtalo de nuevo más tarde.',
    'Aucune connexion Internet. Réessayez plus tard.',
    'Nessuna connessione Internet. Riprova più tardi.',
    'Sem conexão com a internet. Tente novamente mais tarde.',
    'インターネットに接続できません。後でもう一度お試しください。'
  ],
  'No public GitHub Release has been published yet.': [
    'Es wurde noch kein öffentliches GitHub-Release veröffentlicht.',
    'Aún no se ha publicado ninguna versión pública en GitHub.',
    'Aucune version publique n’a encore été publiée sur GitHub.',
    'Non è ancora stata pubblicata alcuna release pubblica su GitHub.',
    'Nenhuma versão pública foi publicada no GitHub ainda.',
    '公開GitHubリリースはまだありません。'
  ],
  'No waiting eggs. Rare chest drops will appear here.': [
    'Keine wartenden Eier. Seltene Eier aus Truhen erscheinen hier.',
    'No hay huevos en espera. Aquí aparecerán los raros que encuentres en cofres.',
    'Aucun œuf en attente. Les rares œufs trouvés dans des coffres apparaîtront ici.',
    'Nessun uovo in attesa. Le rare uova trovate nei forzieri appariranno qui.',
    'Nenhum ovo em espera. Ovos raros encontrados em baús aparecerão aqui.',
    '待機中の卵はありません。宝箱から出た珍しい卵がここに並びます。'
  ],
  'Not enough coins for this floor.': [
    'Nicht genug Münzen für diese Etage.',
    'No tienes suficientes monedas para este piso.',
    'Pas assez de pièces pour cet étage.',
    'Monete insufficienti per questo piano.',
    'Moedas insuficientes para este andar.',
    'この階を建てるコインが足りません。'
  ],
  'Not ready yet': [
    'Noch nicht bereit',
    'Aún no está listo',
    'Pas encore prêt',
    'Non ancora pronto',
    'Ainda não está pronto',
    'まだ準備中'
  ],
  'Not yet': [
    'Noch nicht',
    'Todavía no',
    'Pas encore',
    'Non ancora',
    'Ainda não',
    'まだしない'
  ],
  'OTHER ROOM': [
    'ANDERER RAUM',
    'OTRA HABITACIÓN',
    'AUTRE PIÈCE',
    'ALTRA STANZA',
    'OUTRO CÔMODO',
    '別の部屋'
  ],
  'Open tip form': [
    'Trinkgeldseite öffnen',
    'Abrir página de apoyo',
    'Ouvrir la page de soutien',
    'Apri la pagina di supporto',
    'Abrir página de apoio',
    '支援ページを開く'
  ],
  'Opening the latest DragonHaven download…': [
    'Der neueste DragonHaven-Download wird geöffnet …',
    'Abriendo la descarga más reciente de DragonHaven…',
    'Ouverture du dernier téléchargement de DragonHaven…',
    'Apertura dell’ultimo download di DragonHaven…',
    'Abrindo o download mais recente do DragonHaven…',
    '最新のDragonHavenダウンロードを開いています…'
  ],
  'Open': ['Öffnen', 'Abrir', 'Ouvrir', 'Apri', 'Abrir', '開く'],
  'Payment via PayPal': [
    'Zahlung über PayPal',
    'Pago mediante PayPal',
    'Paiement via PayPal',
    'Pagamento tramite PayPal',
    'Pagamento via PayPal',
    'PayPalで支払う'
  ],
  'Place': ['Platzieren', 'Colocar', 'Placer', 'Posiziona', 'Posicionar', '配置'],
  'Placed': [
    'Platziert',
    'Colocado',
    'Placé',
    'Posizionato',
    'Posicionado',
    '配置済み'
  ],
  'Possible hatchling': [
    'Mögliches Jungtier',
    'Posible cría',
    'Nouveau-né possible',
    'Possibile cucciolo',
    'Possível filhote',
    '孵化する可能性のある幼竜'
  ],
  'Purchased items are always yours.': [
    'Gekaufte Gegenstände gehören dauerhaft dir.',
    'Los objetos comprados siempre serán tuyos.',
    'Les objets achetés restent toujours à toi.',
    'Gli oggetti acquistati restano sempre tuoi.',
    'Itens comprados são seus para sempre.',
    '購入したアイテムはずっとあなたのものです。'
  ],
  'Purchases are disabled until Google Play product IDs and server-side receipt validation are configured.':
      [
    'Käufe sind deaktiviert, bis Google-Play-Produkt-IDs und die serverseitige Belegprüfung eingerichtet sind.',
    'Las compras están desactivadas hasta configurar los ID de producto de Google Play y la validación de recibos en el servidor.',
    'Les achats sont désactivés jusqu’à la configuration des identifiants Google Play et de la validation des reçus côté serveur.',
    'Gli acquisti sono disattivati finché non saranno configurati gli ID prodotto Google Play e la convalida delle ricevute sul server.',
    'As compras estão desativadas até configurar IDs de produto do Google Play e validação de recibos no servidor.',
    'Google Playの商品IDとサーバー側のレシート検証が設定されるまで購入は無効です。'
  ],
  'Raise': ['Aufziehen', 'Criar', 'Élever', 'Alleva', 'Criar', '育てる'],
  'Raise this egg?': [
    'Dieses Ei aufziehen?',
    '¿Criar este huevo?',
    'Élever cet œuf ?',
    'Allevare questo uovo?',
    'Criar este ovo?',
    'この卵を育てますか？'
  ],
  'Raise wonder. Build a home. Fill the Draconomicon.': [
    'Zieh Wunder groß. Bau ein Zuhause. Fülle das Draconomicon.',
    'Cría maravillas. Construye un hogar. Completa el Draconomicon.',
    'Élève l’émerveillement. Bâtis un foyer. Remplis le Draconomicon.',
    'Coltiva la meraviglia. Costruisci una casa. Completa il Draconomicon.',
    'Cultive maravilhas. Construa um lar. Complete o Draconomicon.',
    '驚きを育て、住まいを築き、ドラコノミコンを満たそう。'
  ],
  'Rare': ['Selten', 'Raro', 'Rare', 'Raro', 'Raro', 'レア'],
  'Read-only visits can show the favorite dragon, rooms and achievements—including locked ??? secrets.':
      [
    'Bei Besuchen können Lieblingsdrache, Räume und Erfolge nur angesehen werden – auch gesperrte ???-Geheimnisse.',
    'Las visitas de solo lectura muestran el dragón favorito, las habitaciones y los logros, incluidos secretos ??? bloqueados.',
    'Les visites en lecture seule peuvent montrer le dragon favori, les pièces et les succès, y compris les secrets ??? verrouillés.',
    'Le visite in sola lettura mostrano il drago preferito, le stanze e gli obiettivi, compresi i segreti ??? bloccati.',
    'Visitas somente leitura mostram o dragão favorito, cômodos e conquistas, incluindo segredos ??? bloqueados.',
    '閲覧専用の訪問では、お気に入りのドラゴン、部屋、実績（未解除の「???」も含む）を確認できます。'
  ],
  'Ready': ['Bereit', 'Listo', 'Prêt', 'Pronto', 'Pronto', '準備完了'],
  'Ready to hatch': [
    'Bereit zum Schlüpfen',
    'Listo para eclosionar',
    'Prêt à éclore',
    'Pronto a schiudersi',
    'Pronto para chocar',
    '孵化できます'
  ],
  'Redeem': ['Einlösen', 'Canjear', 'Valider', 'Riscatta', 'Resgatar', '引き換える'],
  'Redeem code': [
    'Code einlösen',
    'Canjear código',
    'Utiliser un code',
    'Riscatta codice',
    'Resgatar código',
    'コードを引き換える'
  ],
  'Release': ['Freilassen', 'Liberar', 'Libérer', 'Libera', 'Libertar', '放す'],
  'Release dragon…': [
    'Drachen freilassen …',
    'Liberar dragón…',
    'Libérer le dragon…',
    'Libera drago…',
    'Libertar dragão…',
    'ドラゴンを放す…'
  ],
  'Remove': ['Entfernen', 'Quitar', 'Retirer', 'Rimuovi', 'Remover', '取り外す'],
  'Remove favorite': [
    'Favorit entfernen',
    'Quitar de favoritos',
    'Retirer des favoris',
    'Rimuovi dai preferiti',
    'Remover dos favoritos',
    'お気に入りを解除'
  ],
  'Remove permanently': [
    'Dauerhaft entfernen',
    'Eliminar para siempre',
    'Retirer définitivement',
    'Rimuovi definitivamente',
    'Remover permanentemente',
    '完全に削除'
  ],
  'Repair': ['Reparieren', 'Reparar', 'Réparer', 'Ripara', 'Reparar', '修理'],
  'Return to inventory': [
    'Ins Inventar zurücklegen',
    'Devolver al inventario',
    'Remettre dans l’inventaire',
    'Rimetti nell’inventario',
    'Devolver ao inventário',
    '持ち物に戻す'
  ],
  'Rooftop Nest': [
    'Dachnest',
    'Nido de la Azotea',
    'Nid du Toit',
    'Nido sul Tetto',
    'Ninho no Telhado',
    '屋上の巣'
  ],
  'Rooms': ['Räume', 'Habitaciones', 'Pièces', 'Stanze', 'Cômodos', '部屋'],
  'Search 200 house items': [
    '200 Hausgegenstände durchsuchen',
    'Buscar entre 200 objetos de la casa',
    'Rechercher parmi 200 objets',
    'Cerca tra 200 oggetti per la casa',
    'Pesquisar 200 itens da casa',
    '200個の家具を検索'
  ],
  'Search by a stable player code; names are never treated as unique IDs.': [
    'Suche über einen festen Spielercode; Namen gelten nie als eindeutige IDs.',
    'Busca por un código de jugador estable; los nombres nunca se consideran identificadores únicos.',
    'Recherche avec un code joueur stable ; les noms ne sont jamais utilisés comme identifiants uniques.',
    'Cerca tramite un codice giocatore stabile; i nomi non sono mai considerati ID univoci.',
    'Pesquise por um código fixo de jogador; nomes nunca são tratados como IDs exclusivos.',
    '固定のプレイヤーコードで検索します。名前は一意のIDとして扱われません。'
  ],
  'Synced with your offline profile': [
    'Mit deinem Offline-Profil synchronisiert',
    'Sincronizado con tu perfil sin conexión',
    'Synchronisé avec ton profil hors ligne',
    'Sincronizzato con il tuo profilo offline',
    'Sincronizado com o teu perfil offline',
    'オフラインプロフィールと同期済み'
  ],
  'Secret achievement': [
    'Geheimer Erfolg',
    'Logro secreto',
    'Succès secret',
    'Obiettivo segreto',
    'Conquista secreta',
    '秘密の実績'
  ],
  'Silver Chest': [
    'Silbertruhe',
    'Cofre de Plata',
    'Coffre en Argent',
    'Forziere d’Argento',
    'Baú de Prata',
    '銀の宝箱'
  ],
  'Sinister Chest': [
    'Unheilvolle Truhe',
    'Cofre Siniestro',
    'Coffre Sinistre',
    'Forziere Sinistro',
    'Baú Sinistro',
    '不吉な宝箱'
  ],
  'Select an item, then tap its new place in the room.': [
    'Wähle einen Gegenstand und tippe dann auf seinen neuen Platz im Raum.',
    'Selecciona un objeto y toca su nueva posición en la habitación.',
    'Sélectionne un objet, puis touche son nouvel emplacement dans la pièce.',
    'Seleziona un oggetto, poi tocca il nuovo punto nella stanza.',
    'Selecione um item e toque no novo lugar dele no cômodo.',
    'アイテムを選び、部屋の新しい場所をタップしてください。'
  ],
  'Set as favorite': [
    'Als Favorit markieren',
    'Marcar como favorito',
    'Ajouter aux favoris',
    'Imposta come preferito',
    'Marcar como favorito',
    'お気に入りにする'
  ],
  'Share or update DragonHaven': [
    'DragonHaven teilen oder aktualisieren',
    'Compartir o actualizar DragonHaven',
    'Partager ou mettre à jour DragonHaven',
    'Condividi o aggiorna DragonHaven',
    'Compartilhar ou atualizar DragonHaven',
    'DragonHavenを共有／更新'
  ],
  'Shop': ['Laden', 'Tienda', 'Boutique', 'Negozio', 'Loja', 'ショップ'],
  'Mini': ['Mini', 'Mini', 'Mini', 'Mini', 'Mini', 'ミニ'],
  'Wood': ['Holz', 'Madera', 'Bois', 'Legno', 'Madeira', '木製'],
  'Short': ['Kurz', 'Corta', 'Courte', 'Breve', 'Curta', 'ショート'],
  'Something useful was discovered in the Spire.': [
    'In der Spitze wurde etwas Nützliches entdeckt.',
    'Se descubrió algo útil en la Aguja.',
    'Quelque chose d’utile a été découvert dans la Flèche.',
    'È stato scoperto qualcosa di utile nella Guglia.',
    'Algo útil foi descoberto na Torre.',
    '塔で役立つものを発見しました。'
  ],
  'Special': [
    'Besonders',
    'Especial',
    'Spécial',
    'Speciale',
    'Especial',
    'スペシャル'
  ],
  'Spectral': [
    'Spektral',
    'Espectral',
    'Spectral',
    'Spettrale',
    'Espectral',
    'スペクトラル'
  ],
  'Spirit is currently leading.': [
    'Geist liegt derzeit vorn.',
    'Espíritu está en cabeza.',
    'Esprit est actuellement en tête.',
    'Spirito è attualmente in testa.',
    'Espírito está na frente.',
    '現在はスピリットが優勢です。'
  ],
  'Star loft': [
    'Sternendachboden',
    'Ático Estelar',
    'Grenier des Étoiles',
    'Soffitta Stellare',
    'Sótão Estelar',
    '星のロフト'
  ],
  'Starlight Treat · 3 gems': [
    'Sternenlicht-Leckerli · 3 Edelsteine',
    'Premio de luz estelar · 3 gemas',
    'Friandise astrale · 3 gemmes',
    'Dolcetto stellare · 3 gemme',
    'Petisco estelar · 3 gemas',
    '星明かりのおやつ・ジェム3個'
  ],
  'Start': ['Starten', 'Empezar', 'Commencer', 'Inizia', 'Iniciar', '開始'],
  'Sunforge': [
    'Sonnenschmiede',
    'Forja Solar',
    'Forge Solaire',
    'Forgia Solare',
    'Forja Solar',
    '太陽の鍛冶場'
  ],
  'Talk to': [
    'Sprich mit',
    'Hablar con',
    'Parler à',
    'Parla con',
    'Falar com',
    '話しかける'
  ],
  'Tap the chest': [
    'Tippe auf die Truhe',
    'Toca el cofre',
    'Touchez le coffre',
    'Tocca il forziere',
    'Toque no baú',
    '宝箱をタップ'
  ],
  'A tower treasure awaits': [
    'Ein Turmschatz wartet',
    'Te espera un tesoro de la torre',
    'Un trésor de la tour vous attend',
    'Ti aspetta un tesoro della torre',
    'Um tesouro da torre espera por você',
    '塔の宝物が待っています'
  ],
  'Treasure claimed': [
    'Schatz geborgen',
    'Tesoro conseguido',
    'Trésor récupéré',
    'Tesoro ottenuto',
    'Tesouro resgatado',
    '宝物を受け取りました'
  ],
  'TAP TO CALL YOUR DRAGON': [
    'TIPPEN, UM DEINEN DRACHEN ZU RUFEN',
    'TOCA PARA LLAMAR A TU DRAGÓN',
    'TOUCHEZ POUR APPELER VOTRE DRAGON',
    'TOCCA PER CHIAMARE IL TUO DRAGO',
    'TOQUE PARA CHAMAR SEU DRAGÃO',
    'タップしてドラゴンを呼ぶ'
  ],
  'TAP TO MOVE YOUR DRAGON': [
    'TIPPEN, UM DEINEN DRACHEN ZU BEWEGEN',
    'TOCA PARA MOVER A TU DRAGÓN',
    'TOUCHEZ POUR DÉPLACER VOTRE DRAGON',
    'TOCCA PER SPOSTARE IL TUO DRAGO',
    'TOQUE PARA MOVER SEU DRAGÃO',
    'タップしてドラゴンを移動'
  ],
  'That dragon is already away.': [
    'Dieser Drache ist bereits unterwegs.',
    'Ese dragón ya está fuera.',
    'Ce dragon est déjà parti.',
    'Quel drago è già fuori.',
    'Esse dragão já está fora.',
    'そのドラゴンはすでに外出中です。'
  ],
  'That room cannot be built here.': [
    'Dieser Raum kann hier nicht gebaut werden.',
    'Esa habitación no puede construirse aquí.',
    'Cette pièce ne peut pas être construite ici.',
    'Questa stanza non può essere costruita qui.',
    'Esse cômodo não pode ser construído aqui.',
    'ここにはその部屋を建てられません。'
  ],
  'That was insightful': [
    'Das war aufschlussreich',
    'Ha sido revelador',
    'C’était instructif',
    'È stato illuminante',
    'Isso foi esclarecedor',
    'いい話でした'
  ],
  'The download could not be opened. The link was copied instead.': [
    'Der Download konnte nicht geöffnet werden. Der Link wurde stattdessen kopiert.',
    'No se pudo abrir la descarga. Se copió el enlace.',
    'Impossible d’ouvrir le téléchargement. Le lien a été copié.',
    'Impossibile aprire il download. Il link è stato copiato.',
    'Não foi possível abrir o download. O link foi copiado.',
    'ダウンロードを開けなかったため、リンクをコピーしました。'
  ],
  'The download link could not be copied.': [
    'Der Downloadlink konnte nicht kopiert werden.',
    'No se pudo copiar el enlace de descarga.',
    'Impossible de copier le lien de téléchargement.',
    'Impossibile copiare il link di download.',
    'Não foi possível copiar o link de download.',
    'ダウンロードリンクをコピーできませんでした。'
  ],
  'The download link could not be opened or copied.': [
    'Der Downloadlink konnte weder geöffnet noch kopiert werden.',
    'No se pudo abrir ni copiar el enlace de descarga.',
    'Impossible d’ouvrir ou de copier le lien de téléchargement.',
    'Impossibile aprire o copiare il link di download.',
    'Não foi possível abrir nem copiar o link de download.',
    'ダウンロードリンクを開くこともコピーすることもできませんでした。'
  ],
  'The future form is still a mystery.': [
    'Die zukünftige Form ist noch ein Geheimnis.',
    'La forma futura aún es un misterio.',
    'La forme future reste un mystère.',
    'La forma futura è ancora un mistero.',
    'A forma futura ainda é um mistério.',
    '未来の姿はまだ謎です。'
  ],
  'The Draconomicon': [
    'Das Draconomicon',
    'El Draconomicon',
    'Le Draconomicon',
    'Il Draconomicon',
    'O Draconomicon',
    'ドラコノミコン'
  ],
  'The group does not meet the requirements.': [
    'Die Gruppe erfüllt die Anforderungen nicht.',
    'El grupo no cumple los requisitos.',
    'Le groupe ne remplit pas les conditions.',
    'Il gruppo non soddisfa i requisiti.',
    'O grupo não atende aos requisitos.',
    'グループが条件を満たしていません。'
  ],
  'The GitHub repository is not connected yet. Build with --dart-define=DRAGONHAVEN_GITHUB_OWNER=yourname.':
      [
    'Das GitHub-Repository ist noch nicht verbunden. Baue mit --dart-define=DRAGONHAVEN_GITHUB_OWNER=deinname.',
    'El repositorio de GitHub aún no está conectado. Compila con --dart-define=DRAGONHAVEN_GITHUB_OWNER=tunombre.',
    'Le dépôt GitHub n’est pas encore connecté. Compilez avec --dart-define=DRAGONHAVEN_GITHUB_OWNER=votrenom.',
    'Il repository GitHub non è ancora collegato. Compila con --dart-define=DRAGONHAVEN_GITHUB_OWNER=tuonome.',
    'O repositório do GitHub ainda não está conectado. Compile com --dart-define=DRAGONHAVEN_GITHUB_OWNER=seunome.',
    'GitHubリポジトリが未接続です。--dart-define=DRAGONHAVEN_GITHUB_OWNER=あなたの名前 を指定してビルドしてください。'
  ],
  'The hidden dragon inside will be lost permanently.': [
    'Der darin verborgene Drache geht für immer verloren.',
    'El dragón oculto en su interior se perderá para siempre.',
    'Le dragon caché à l’intérieur sera perdu définitivement.',
    'Il drago nascosto all’interno andrà perduto per sempre.',
    'O dragão escondido dentro será perdido para sempre.',
    '中にいるドラゴンは永久に失われます。'
  ],
  'The highest trained path fixes the final form. Activities in Explore raise these values.':
      [
    'Der am stärksten trainierte Pfad bestimmt die endgültige Form. Aktivitäten unter „Erkunden“ erhöhen diese Werte.',
    'La senda más entrenada determina la forma final. Las actividades de Explorar aumentan estos valores.',
    'La voie la plus entraînée détermine la forme finale. Les activités d’Exploration augmentent ces valeurs.',
    'Il percorso più allenato determina la forma finale. Le attività di Esplorazione aumentano questi valori.',
    'O caminho mais treinado define a forma final. Atividades em Explorar aumentam esses valores.',
    '最も鍛えた道が最終形態を決めます。「探索」の活動で数値が上がります。'
  ],
  'The inventory is empty. Explore the Spire or visit the furniture market.': [
    'Das Inventar ist leer. Erkunde die Spitze oder besuche den Möbelmarkt.',
    'El inventario está vacío. Explora la Aguja o visita el mercado de muebles.',
    'L’inventaire est vide. Explore la Flèche ou visite le marché aux meubles.',
    'L’inventario è vuoto. Esplora la Guglia o visita il mercato dei mobili.',
    'O inventário está vazio. Explore a Torre ou visite o mercado de móveis.',
    '持ち物が空です。塔を探索するか、家具市場へ行きましょう。'
  ],
  'The latest release contains no valid version data.': [
    'Das neueste Release enthält keine gültigen Versionsdaten.',
    'La versión más reciente no contiene datos de versión válidos.',
    'La dernière version ne contient aucune donnée de version valide.',
    'L’ultima release non contiene dati di versione validi.',
    'A versão mais recente não contém dados de versão válidos.',
    '最新リリースに有効なバージョン情報がありません。'
  ],
  'The release check took too long.': [
    'Die Versionsprüfung hat zu lange gedauert.',
    'La comprobación de la versión tardó demasiado.',
    'La vérification de la version a pris trop de temps.',
    'Il controllo della versione ha richiesto troppo tempo.',
    'A verificação da versão demorou demais.',
    'リリースの確認に時間がかかりすぎました。'
  ],
  'The secure connection to GitHub failed.': [
    'Die sichere Verbindung zu GitHub ist fehlgeschlagen.',
    'Falló la conexión segura con GitHub.',
    'La connexion sécurisée à GitHub a échoué.',
    'La connessione sicura a GitHub non è riuscita.',
    'A conexão segura com o GitHub falhou.',
    'GitHubへの安全な接続に失敗しました。'
  ],
  'The shell is trembling...': [
    'Die Schale zittert …',
    'La cáscara está temblando...',
    'La coquille tremble...',
    'Il guscio sta tremando...',
    'A casca está tremendo...',
    '殻が震えています…'
  ],
  'The tower already has 20 floors.': [
    'Der Turm hat bereits 20 Etagen.',
    'La torre ya tiene 20 pisos.',
    'La tour compte déjà 20 étages.',
    'La torre ha già 20 piani.',
    'A torre já tem 20 andares.',
    '塔はすでに20階です。'
  ],
  'The tower nest': [
    'Das Turmnest',
    'El nido de la torre',
    'Le nid de la tour',
    'Il nido della torre',
    'O ninho da torre',
    '塔の巣'
  ],
  'This cannot be undone and gives no coins back.': [
    'Dies kann nicht rückgängig gemacht werden und bringt keine Münzen zurück.',
    'Esto no se puede deshacer y no devuelve monedas.',
    'Cette action est irréversible et ne rend aucune pièce.',
    'L’azione non può essere annullata e non restituisce monete.',
    'Isso não pode ser desfeito e não devolve moedas.',
    '元に戻すことはできず、コインも返却されません。'
  ],
  'This build keeps your collection safely on this device. A real friend list needs authenticated accounts and a server, so no local demo person is shown as if they were online.':
      [
    'Diese Version speichert deine Sammlung sicher auf diesem Gerät. Eine echte Freundesliste benötigt angemeldete Konten und einen Server; deshalb werden keine lokalen Demokontakte als online angezeigt.',
    'Esta versión guarda tu colección de forma segura en este dispositivo. Una lista de amigos real necesita cuentas autenticadas y un servidor, así que no se muestran contactos de prueba como si estuvieran en línea.',
    'Cette version conserve votre collection sur cet appareil. Une vraie liste d’amis exige des comptes authentifiés et un serveur ; aucun contact fictif n’est donc affiché comme connecté.',
    'Questa versione conserva la collezione sul dispositivo. Un vero elenco amici richiede account autenticati e un server, quindi non vengono mostrati contatti demo come se fossero online.',
    'Esta versão mantém sua coleção segura no dispositivo. Uma lista real de amigos requer contas autenticadas e um servidor, por isso nenhum contato de demonstração aparece como online.',
    'このビルドではコレクションを端末内に安全に保存します。本物のフレンドリストには認証済みアカウントとサーバーが必要なため、デモの人物をオンラインとして表示しません。'
  ],
  'This dragon leaves your collection and cannot be trained. Its identity, form, alignment and hidden personality are preserved.':
      [
    'Dieser Drache verlässt deine Sammlung und kann nicht mehr trainiert werden. Identität, Form, Ausrichtung und verborgene Persönlichkeit bleiben erhalten.',
    'Este dragón dejará tu colección y no podrá entrenarse. Se conservarán su identidad, forma, afinidad y personalidad oculta.',
    'Ce dragon quittera votre collection et ne pourra plus être entraîné. Son identité, sa forme, son affinité et sa personnalité cachée seront conservées.',
    'Questo drago lascerà la collezione e non potrà essere allenato. Identità, forma, affinità e personalità nascosta resteranno intatte.',
    'Este dragão deixará sua coleção e não poderá ser treinado. Identidade, forma, afinidade e personalidade oculta serão preservadas.',
    'このドラゴンはコレクションを離れ、訓練できなくなります。個体情報、形態、資質、隠れた性格は保持されます。'
  ],
  'This code is not active.': [
    'Dieser Code ist nicht aktiv.',
    'Este código no está activo.',
    'Ce code n’est pas actif.',
    'Questo codice non è attivo.',
    'Este código não está ativo.',
    'このコードは有効ではありません。'
  ],
  'This offer is no longer available.': [
    'Dieses Angebot ist nicht mehr verfügbar.',
    'Esta oferta ya no está disponible.',
    'Cette offre n’est plus disponible.',
    'Questa offerta non è più disponibile.',
    'Esta oferta não está mais disponível.',
    'この依頼はもう利用できません。'
  ],
  'This room is already part of the house.': [
    'Dieser Raum gehört bereits zum Haus.',
    'Esta habitación ya forma parte de la casa.',
    'Cette pièce fait déjà partie de la maison.',
    'Questa stanza fa già parte della casa.',
    'Este cômodo já faz parte da casa.',
    'この部屋はすでに建築済みです。'
  ],
  'Tidal Library': [
    'Gezeitenbibliothek',
    'Biblioteca de las Mareas',
    'Bibliothèque des Marées',
    'Biblioteca delle Maree',
    'Biblioteca das Marés',
    '潮の図書館'
  ],
  'Tower': ['Turm', 'Torre', 'Tour', 'Torre', 'Torre', '塔'],
  'Tower visits': [
    'Turmbesuche',
    'Visitas a torres',
    'Visites de tours',
    'Visite alle torri',
    'Visitas às torres',
    '塔への訪問'
  ],
  'Two-sided trade': [
    'Beidseitiger Tausch',
    'Intercambio bilateral',
    'Échange bilatéral',
    'Scambio bilaterale',
    'Troca bilateral',
    '相互交換'
  ],
  'Undiscovered dragon form': [
    'Unentdeckte Drachenform',
    'Forma de dragón sin descubrir',
    'Forme de dragon non découverte',
    'Forma di drago non scoperta',
    'Forma de dragão não descoberta',
    '未発見のドラゴン形態'
  ],
  'Unique atmosphere and layout': [
    'Einzigartige Stimmung und Raumaufteilung',
    'Ambiente y distribución únicos',
    'Ambiance et agencement uniques',
    'Atmosfera e disposizione uniche',
    'Atmosfera e disposição únicas',
    '固有の雰囲気とレイアウト'
  ],
  'Unknown lineage': [
    'Unbekannte Familie',
    'Linaje desconocido',
    'Lignée inconnue',
    'Stirpe sconosciuta',
    'Linhagem desconhecida',
    '未知の系統'
  ],
  'Up to 3 offers, refreshed at local midnight.': [
    'Bis zu 3 Angebote, aktualisiert um Mitternacht deiner Ortszeit.',
    'Hasta 3 ofertas, renovadas a medianoche local.',
    'Jusqu’à 3 offres, renouvelées à minuit heure locale.',
    'Fino a 3 offerte, aggiornate a mezzanotte locale.',
    'Até 3 ofertas, atualizadas à meia-noite local.',
    '最大3件。現地時間の午前0時に更新されます。'
  ],
  'Up to 3 offers. Open slots refresh every hour; you may dismiss one.': [
    'Bis zu 3 Angebote. Freie Plätze werden stündlich aufgefüllt; du kannst eines wegschicken.',
    'Hasta 3 ofertas. Los huecos se renuevan cada hora; puedes descartar una.',
    'Jusqu’à 3 offres. Les places libres sont renouvelées chaque heure ; tu peux en ignorer une.',
    'Fino a 3 offerte. Gli spazi liberi si aggiornano ogni ora; puoi congedarne una.',
    'Até 3 ofertas. Vagas abertas são renovadas a cada hora; você pode dispensar uma.',
    '最大3件。空き枠は1時間ごとに更新され、1件を見送れます。'
  ],
  'Use only connected capital letters.': [
    'Verwende nur zusammenhängende Großbuchstaben.',
    'Usa solo letras mayúsculas seguidas.',
    'Utilisez uniquement des lettres majuscules sans espace.',
    'Usa solo lettere maiuscole consecutive.',
    'Use apenas letras maiúsculas juntas.',
    '大文字だけを続けて入力してください。'
  ],
  'Version': ['Version', 'Versión', 'Version', 'Versione', 'Versão', 'バージョン'],
  'Visit towers, lend a friendly dragon and trade eggs, chests or furniture.': [
    'Besuche Türme, leihe einen freundlichen Drachen aus und tausche Eier, Truhen oder Möbel.',
    'Visita torres, presta un dragón amistoso e intercambia huevos, cofres o muebles.',
    'Visite des tours, prête un dragon amical et échange des œufs, coffres ou meubles.',
    'Visita torri, presta un drago amichevole e scambia uova, forzieri o mobili.',
    'Visite torres, empreste um dragão amigável e troque ovos, baús ou móveis.',
    '塔を訪れ、仲良しのドラゴンを貸し、卵・宝箱・家具を交換しましょう。'
  ],
  'Wall': ['Wand', 'Pared', 'Mur', 'Parete', 'Parede', '壁飾り'],
  'Welcome': [
    'Willkommen',
    'Bienvenido',
    'Bienvenue',
    'Benvenuto',
    'Boas-vindas',
    'ようこそ'
  ],
  'Wellbeing': [
    'Wohlbefinden',
    'Bienestar',
    'Bien-être',
    'Benessere',
    'Bem-estar',
    'コンディション'
  ],
  'Wooden Chest': [
    'Holztruhe',
    'Cofre de Madera',
    'Coffre en Bois',
    'Forziere di Legno',
    'Baú de Madeira',
    '木の宝箱'
  ],
  'Wyrmling': [
    'Jungwyrm',
    'Dragón joven',
    'Jeune wyrm',
    'Giovane wyrm',
    'Jovem wyrm',
    '若竜'
  ],
  'Your keeper name': [
    'Name deines Hüters',
    'Nombre de tu cuidador',
    'Nom de ton gardien',
    'Nome del tuo custode',
    'Nome do seu guardião',
    'キーパーの名前'
  ],
  'Your current dragon moves safely into the sanctuary collection. Coins, gems and discoveries stay yours.':
      [
    'Dein aktueller Drache zieht sicher in die Sammlung des Refugiums. Münzen, Edelsteine und Entdeckungen bleiben erhalten.',
    'Tu dragón actual pasará a salvo a la colección del santuario. Conservarás monedas, gemas y descubrimientos.',
    'Votre dragon actuel rejoint la collection du sanctuaire en toute sécurité. Pièces, gemmes et découvertes sont conservées.',
    'Il drago attuale passerà al sicuro nella collezione del santuario. Monete, gemme e scoperte resteranno tue.',
    'Seu dragão atual irá com segurança para a coleção do santuário. Moedas, gemas e descobertas continuam suas.',
    '現在のドラゴンは安全に聖域のコレクションへ移ります。コイン、ジェム、発見記録は残ります。'
  ],
  '✦ SOMETHING IS DIFFERENT...': [
    '✦ ETWAS IST ANDERS …',
    '✦ ALGO ES DIFERENTE...',
    '✦ QUELQUE CHOSE EST DIFFÉRENT...',
    '✦ C’È QUALCOSA DI DIVERSO...',
    '✦ ALGO ESTÁ DIFERENTE...',
    '✦ 何かが違う…'
  ],
  'Your living record of every dragon form you have raised.': [
    'Dein lebendiges Verzeichnis aller Drachenformen, die du aufgezogen hast.',
    'Tu registro vivo de todas las formas de dragón que has criado.',
    'Le registre vivant de toutes les formes de dragon que tu as élevées.',
    'Il registro vivente di ogni forma di drago che hai allevato.',
    'Seu registro vivo de todas as formas de dragão que você criou.',
    '育てたすべてのドラゴン形態を記す、生きた記録です。'
  ],
  'Your purchased furniture is stored here.': [
    'Deine gekauften Möbel werden hier aufbewahrt.',
    'Aquí se guardan los muebles que has comprado.',
    'Tes meubles achetés sont rangés ici.',
    'I mobili acquistati sono conservati qui.',
    'Seus móveis comprados ficam guardados aqui.',
    '購入した家具はここに保管されます。'
  ],
  'Your sanctuary is not ready for this room yet.': [
    'Dein Refugium ist noch nicht bereit für diesen Raum.',
    'Tu santuario aún no está listo para esta habitación.',
    'Ton sanctuaire n’est pas encore prêt pour cette pièce.',
    'Il tuo santuario non è ancora pronto per questa stanza.',
    'Seu santuário ainda não está pronto para este cômodo.',
    '聖域はまだこの部屋を建てられる段階ではありません。'
  ],
  'coins': ['Münzen', 'monedas', 'pièces', 'monete', 'moedas', 'コイン'],
  'floors': ['Etagen', 'pisos', 'étages', 'piani', 'andares', '階'],
  'forms': ['Formen', 'formas', 'formes', 'forme', 'formas', '形態'],
  'locked': [
    'gesperrt',
    'bloqueado',
    'verrouillé',
    'bloccato',
    'bloqueado',
    '未解除'
  ],
  'path undecided': [
    'Pfad unentschieden',
    'senda sin decidir',
    'voie indécise',
    'percorso non deciso',
    'caminho indefinido',
    '進化の道は未定'
  ],
  'unlocked': [
    'freigeschaltet',
    'desbloqueado',
    'débloqué',
    'sbloccato',
    'desbloqueado',
    '解除済み'
  ],
  'training': [
    'Training',
    'entrenamiento',
    'entraînement',
    'allenamento',
    'treino',
    'トレーニング'
  ],
  'Dawn': ['Morgengrauen', 'Amanecer', 'Aube', 'Alba', 'Alvorada', '夜明け'],
  'Day': ['Tag', 'Día', 'Jour', 'Giorno', 'Dia', '昼'],
  'Deep Night': [
    'Tiefe Nacht',
    'Noche profunda',
    'Nuit profonde',
    'Notte fonda',
    'Noite profunda',
    '深夜'
  ],
  'Dusk': [
    'Dämmerung',
    'Anochecer',
    'Crépuscule',
    'Tramonto',
    'Anoitecer',
    '夕暮れ'
  ],
  'Golden Hour': [
    'Goldene Stunde',
    'Hora dorada',
    'Heure dorée',
    'Ora dorata',
    'Hora dourada',
    '黄金の時間'
  ],
  'Legendary': [
    'Legendär',
    'Legendario',
    'Légendaire',
    'Leggendario',
    'Lendário',
    'レジェンダリー'
  ],
  'Morning': ['Morgen', 'Mañana', 'Matin', 'Mattina', 'Manhã', '朝'],
  'Mythical': ['Mythisch', 'Mítico', 'Mythique', 'Mitico', 'Mítico', 'ミシカル'],
  'Night': ['Nacht', 'Noche', 'Nuit', 'Notte', 'Noite', '夜'],
  'Uncommon': [
    'Ungewöhnlich',
    'Poco común',
    'Peu commun',
    'Non comune',
    'Incomum',
    'アンコモン'
  ],
  'Very Rare': [
    'Sehr selten',
    'Muy raro',
    'Très rare',
    'Molto raro',
    'Muito raro',
    'ベリーレア'
  ],
  'A gentle glow lingers beneath your hand.': [
    'Ein sanftes Leuchten bleibt unter deiner Hand zurück.',
    'Un brillo suave permanece bajo tu mano.',
    'Une douce lueur persiste sous votre main.',
    'Un bagliore delicato resta sotto la tua mano.',
    'Um brilho suave permanece sob sua mão.',
    '手の下にやさしい光がしばらく残ります。'
  ],
  'A strange musical tap answers from within.': [
    'Ein seltsames, musikalisches Klopfen antwortet von innen.',
    'Un extraño golpecito musical responde desde dentro.',
    'Un étrange petit bruit musical répond de l’intérieur.',
    'Dall’interno risponde uno strano colpetto musicale.',
    'Uma estranha batidinha musical responde lá de dentro.',
    '中から不思議な音色のノックが返ってきます。'
  ],
  'A tiny spark skips across the shell.': [
    'Ein winziger Funke tanzt über die Schale.',
    'Una chispa diminuta salta sobre la cáscara.',
    'Une minuscule étincelle court sur la coquille.',
    'Una minuscola scintilla corre sul guscio.',
    'Uma faísca minúscula salta pela casca.',
    '小さな火花が殻の上を跳ねました。'
  ],
  'It goes quiet whenever you try to find a pattern.': [
    'Sobald du ein Muster suchst, wird es still.',
    'Se queda quieto cuando intentas encontrar un patrón.',
    'Tout se calme dès que vous cherchez un rythme.',
    'Si ferma ogni volta che cerchi uno schema.',
    'Fica quieto sempre que você tenta encontrar um padrão.',
    '動きの規則を探そうとすると、いつも静かになります。'
  ],
  'Something inside seems to listen back.': [
    'Etwas darin scheint aufmerksam zurückzulauschen.',
    'Algo dentro parece escuchar a su vez.',
    'Quelque chose à l’intérieur semble écouter en retour.',
    'Qualcosa dentro sembra ascoltare a sua volta.',
    'Algo lá dentro parece escutar você também.',
    '中にいる何かも、こちらの音に耳を澄ませています。'
  ],
  'The egg grows restless when the stars appear.': [
    'Wenn die Sterne erscheinen, wird das Ei unruhig.',
    'El huevo se inquieta cuando aparecen las estrellas.',
    'L’œuf s’agite lorsque les étoiles apparaissent.',
    'L’uovo diventa irrequieto quando compaiono le stelle.',
    'O ovo fica inquieto quando as estrelas aparecem.',
    '星が現れると、卵がそわそわし始めます。'
  ],
  'The egg rolls a little. Uphill.': [
    'Das Ei rollt ein Stück. Bergauf.',
    'El huevo rueda un poco. Cuesta arriba.',
    'L’œuf roule un peu. Vers le haut de la pente.',
    'L’uovo rotola un po’. In salita.',
    'O ovo rola um pouco. Morro acima.',
    '卵が少し転がりました。坂の上へ。'
  ],
  'The movements inside follow a precise rhythm.': [
    'Die Bewegungen darin folgen einem präzisen Rhythmus.',
    'Los movimientos interiores siguen un ritmo preciso.',
    'Les mouvements à l’intérieur suivent un rythme précis.',
    'I movimenti all’interno seguono un ritmo preciso.',
    'Os movimentos lá dentro seguem um ritmo preciso.',
    '中の動きは正確なリズムに従っています。'
  ],
  'The nest suddenly smells of rain and moss.': [
    'Das Nest riecht plötzlich nach Regen und Moos.',
    'De pronto, el nido huele a lluvia y musgo.',
    'Le nid sent soudain la pluie et la mousse.',
    'Il nido profuma improvvisamente di pioggia e muschio.',
    'De repente, o ninho cheira a chuva e musgo.',
    '巣から突然、雨と苔の香りがします。'
  ],
  'The shell feels unusually warm.': [
    'Die Schale fühlt sich ungewöhnlich warm an.',
    'La cáscara está inusualmente caliente.',
    'La coquille semble anormalement chaude.',
    'Il guscio sembra insolitamente caldo.',
    'A casca parece quente demais.',
    '殻がいつもより温かく感じます。'
  ],
  'You are fairly sure the egg just tapped back.': [
    'Du bist ziemlich sicher, dass das Ei gerade zurückgeklopft hat.',
    'Estás casi seguro de que el huevo acaba de responder con un golpecito.',
    'Vous êtes presque certain que l’œuf vient de répondre.',
    'Sei quasi certo che l’uovo abbia appena risposto con un colpetto.',
    'Você tem quase certeza de que o ovo acabou de bater de volta.',
    '卵が今、こちらへノックを返した気がします。'
  ],
  'You hear something almost like distant waves.': [
    'Du hörst etwas, das beinahe wie ferne Wellen klingt.',
    'Oyes algo parecido a olas lejanas.',
    'Vous entendez quelque chose qui ressemble à des vagues lointaines.',
    'Senti qualcosa che somiglia a onde lontane.',
    'Você ouve algo parecido com ondas distantes.',
    '遠くの波のような音が聞こえます。'
  ],
  '{dragon} pulled out a book and looked shocked by chapter three.': [
    '{dragon} zog ein Buch heraus und blickte bei Kapitel drei schockiert.',
    '{dragon} sacó un libro y quedó sorprendido con el capítulo tres.',
    '{dragon} a sorti un livre et a semblé bouleversé par le chapitre trois.',
    '{dragon} ha preso un libro ed è rimasto sconvolto dal terzo capitolo.',
    '{dragon} puxou um livro e ficou chocado com o capítulo três.',
    '{dragon} は本を取り出し、第3章を読んで驚きました。'
  ],
  '{dragon} curled up by the fire and immediately claimed the warmest spot.': [
    '{dragon} rollte sich am Feuer zusammen und beanspruchte sofort den wärmsten Platz.',
    '{dragon} se acurrucó junto al fuego y reclamó el lugar más cálido.',
    '{dragon} s’est blotti près du feu et a aussitôt pris la place la plus chaude.',
    '{dragon} si è raggomitolato accanto al fuoco prendendo subito il posto più caldo.',
    '{dragon} se enrolou perto do fogo e logo ocupou o lugar mais quente.',
    '{dragon} は火のそばで丸くなり、一番暖かい場所を確保しました。'
  ],
  '{dragon} inspected the snacks. One snack is now mysteriously absent.': [
    '{dragon} prüfte die Snacks. Einer fehlt nun auf geheimnisvolle Weise.',
    '{dragon} inspeccionó los aperitivos. Ahora falta uno misteriosamente.',
    '{dragon} a inspecté les friandises. L’une d’elles a mystérieusement disparu.',
    '{dragon} ha ispezionato gli spuntini. Ora ne manca misteriosamente uno.',
    '{dragon} inspecionou os petiscos. Um deles sumiu misteriosamente.',
    '{dragon} はおやつを点検しました。一つだけ不思議と消えています。'
  ],
  '{dragon} made one tiny splash and one extremely non-tiny mess.': [
    '{dragon} machte einen winzigen Platscher und ein ganz und gar nicht winziges Durcheinander.',
    '{dragon} dio un pequeño chapuzón y armó un desastre nada pequeño.',
    '{dragon} a fait une petite éclaboussure et un désordre pas petit du tout.',
    '{dragon} ha fatto un piccolo spruzzo e un disastro per niente piccolo.',
    '{dragon} deu um pequeno mergulho e fez uma bagunça nada pequena.',
    '{dragon} は小さく水をはね、とても小さいとは言えない騒ぎを起こしました。'
  ],
  '{dragon} counted every shiny object twice, just to be certain.': [
    '{dragon} zählte jeden glänzenden Gegenstand sicherheitshalber zweimal.',
    '{dragon} contó dos veces cada objeto brillante, por si acaso.',
    '{dragon} a compté deux fois chaque objet brillant, par prudence.',
    '{dragon} ha contato due volte ogni oggetto brillante, per sicurezza.',
    '{dragon} contou cada objeto brilhante duas vezes, só por garantia.',
    '{dragon} は念のため、光るものをすべて二回数えました。'
  ],
  '{dragon} disappeared between the leaves for a highly strategic nap.': [
    '{dragon} verschwand für ein höchst strategisches Nickerchen zwischen den Blättern.',
    '{dragon} desapareció entre las hojas para una siesta muy estratégica.',
    '{dragon} a disparu entre les feuilles pour une sieste hautement stratégique.',
    '{dragon} è sparito tra le foglie per un pisolino altamente strategico.',
    '{dragon} sumiu entre as folhas para um cochilo altamente estratégico.',
    '{dragon} は極めて戦略的な昼寝のため、葉の間に消えました。'
  ],
  '{dragon} turned the bedding into a fort. No adults allowed.': [
    '{dragon} baute aus dem Bettzeug eine Festung. Erwachsene verboten.',
    '{dragon} convirtió la ropa de cama en una fortaleza. Prohibidos los adultos.',
    '{dragon} a transformé la literie en fort. Adultes interdits.',
    '{dragon} ha trasformato il letto in un fortino. Adulti vietati.',
    '{dragon} transformou a cama em um forte. Adultos não entram.',
    '{dragon} は寝具で砦を作りました。大人は立入禁止です。'
  ],
  '{dragon} tapped the magic ornament. It politely tapped back.': [
    '{dragon} tippte auf den magischen Schmuck. Er tippte höflich zurück.',
    '{dragon} tocó el adorno mágico. Este respondió educadamente.',
    '{dragon} a touché l’ornement magique. Il a poliment répondu.',
    '{dragon} ha toccato l’ornamento magico. Quello ha risposto con educazione.',
    '{dragon} tocou no enfeite mágico. Ele respondeu educadamente.',
    '{dragon} は魔法の飾りを叩きました。飾りも丁寧に叩き返しました。'
  ],
  '{dragon} looked around, nodded once, and declared this room acceptable.': [
    '{dragon} sah sich um, nickte einmal und erklärte den Raum für akzeptabel.',
    '{dragon} miró alrededor, asintió y declaró aceptable la habitación.',
    '{dragon} a regardé autour de lui, hoché la tête et déclaré la pièce acceptable.',
    '{dragon} si è guardato intorno, ha annuito e dichiarato la stanza accettabile.',
    '{dragon} olhou ao redor, assentiu e declarou o cômodo aceitável.',
    '{dragon} は周囲を見回し、一度うなずいて、この部屋を合格としました。'
  ],
  'An Adventure reward is ready in DragonHaven.': [
    'In DragonHaven wartet eine Abenteuerbelohnung.',
    'Hay una recompensa de aventura lista en DragonHaven.',
    'Une récompense d’aventure vous attend dans DragonHaven.',
    'Una ricompensa dell’avventura è pronta in DragonHaven.',
    'Uma recompensa de aventura está pronta no DragonHaven.',
    'DragonHavenで冒険の報酬を受け取れます。'
  ],
  'Something inside wants to hatch in the Rooftop Nest.': [
    'Etwas darin möchte im Dachnest schlüpfen.',
    'Algo dentro quiere eclosionar en el Nido de la Azotea.',
    'Quelque chose à l’intérieur veut éclore dans le Nid du Toit.',
    'Qualcosa dentro vuole schiudersi nel Nido sul Tetto.',
    'Algo lá dentro quer chocar no Ninho do Telhado.',
    '中にいる何かが屋上の巣で孵化したがっています。'
  ],
  'Your Mysterious Egg is ready': [
    'Dein geheimnisvolles Ei ist bereit',
    'Tu Huevo Misterioso está listo',
    'Votre Œuf mystérieux est prêt',
    'Il tuo Uovo misterioso è pronto',
    'Seu Ovo Misterioso está pronto',
    '不思議な卵の準備ができました'
  ],
  'Treasure revealed': [
    'Schatz enthüllt',
    'Tesoro revelado',
    'Trésor révélé',
    'Tesoro svelato',
    'Tesouro revelado',
    '宝物が現れました'
  ],
  'The lock is opening...': [
    'Das Schloss öffnet sich...',
    'La cerradura se está abriendo...',
    'La serrure s’ouvre...',
    'La serratura si sta aprendo...',
    'A fechadura está abrindo...',
    '鍵が開いています…'
  ],
  'Tap anywhere to return': [
    'Tippe irgendwo, um zurückzukehren',
    'Toca en cualquier lugar para volver',
    'Touchez n’importe où pour revenir',
    'Tocca ovunque per tornare',
    'Toque em qualquer lugar para voltar',
    'どこかをタップして戻る'
  ],
  'A quiet cradle for the next life in your collection.': [
    'Eine stille Wiege für das nächste Leben in deiner Sammlung.',
    'Una cuna tranquila para la próxima vida de tu colección.',
    'Un berceau paisible pour la prochaine vie de votre collection.',
    'Una culla tranquilla per la prossima vita della tua collezione.',
    'Um berço tranquilo para a próxima vida da sua coleção.',
    'コレクションに加わる次の命のための静かな揺りかご。'
  ],
  'One hidden dragon is growing beneath the shell.': [
    'Unter der Schale wächst ein verborgener Drache.',
    'Un dragón oculto crece bajo el cascarón.',
    'Un dragon caché grandit sous la coquille.',
    'Un drago nascosto cresce sotto il guscio.',
    'Um dragão oculto cresce sob a casca.',
    '殻の下で一体の秘密のドラゴンが育っています。'
  ],
  'Reveal the dragon': [
    'Enthülle den Drachen',
    'Revela el dragón',
    'Révéler le dragon',
    'Rivela il drago',
    'Revelar o dragão',
    'ドラゴンを明らかにする'
  ],
  'No Mysterious Eggs are waiting in your inventory.': [
    'In deinem Inventar warten keine geheimnisvollen Eier.',
    'No hay Huevos Misteriosos esperando en tu inventario.',
    'Aucun Œuf mystérieux n’attend dans votre inventaire.',
    'Non ci sono Uova misteriose nel tuo inventario.',
    'Não há Ovos Misteriosos esperando no seu inventário.',
    '所持品に待機中の不思議な卵はありません。'
  ],
  'Choose a Mysterious Egg': [
    'Wähle ein geheimnisvolles Ei',
    'Elige un Huevo Misterioso',
    'Choisissez un Œuf mystérieux',
    'Scegli un Uovo misterioso',
    'Escolha um Ovo Misterioso',
    '不思議な卵を選ぶ'
  ],
  'Its identity is already safely hidden inside.': [
    'Seine Identität ist bereits sicher darin verborgen.',
    'Su identidad ya está oculta de forma segura en su interior.',
    'Son identité est déjà bien cachée à l’intérieur.',
    'La sua identità è già nascosta al sicuro al suo interno.',
    'A identidade já está escondida com segurança lá dentro.',
    'その正体はすでに中に大切に隠されています。'
  ],
  'The nest is already occupied.': [
    'Das Nest ist bereits belegt.',
    'El nido ya está ocupado.',
    'Le nid est déjà occupé.',
    'Il nido è già occupato.',
    'O ninho já está ocupado.',
    '巣にはすでに卵があります。'
  ],
  'Tap the nest to choose an egg': [
    'Tippe auf das Nest, um ein Ei auszuwählen',
    'Toca el nido para elegir un huevo',
    'Touchez le nid pour choisir un œuf',
    'Tocca il nido per scegliere un uovo',
    'Toque no ninho para escolher um ovo',
    '巣をタップして卵を選ぶ'
  ],
  'Tap the egg once to begin hatching': [
    'Tippe einmal auf das Ei, um das Schlüpfen zu beginnen',
    'Toca el huevo una vez para comenzar la eclosión',
    'Touchez l’œuf une fois pour lancer l’éclosion',
    'Tocca una volta l’uovo per iniziare la schiusa',
    'Toque no ovo uma vez para iniciar a eclosão',
    '卵を一度タップして孵化を始める'
  ],
  'The egg is beginning to hatch': [
    'Das Ei beginnt zu schlüpfen',
    'El huevo está empezando a eclosionar',
    'L’œuf commence à éclore',
    'L’uovo sta iniziando a schiudersi',
    'O ovo está começando a eclodir',
    '卵が孵化し始めています'
  ],
  'Something is moving inside...': [
    'Etwas bewegt sich darin...',
    'Algo se mueve dentro...',
    'Quelque chose bouge à l’intérieur...',
    'Qualcosa si muove dentro...',
    'Algo está se mexendo lá dentro...',
    '中で何かが動いています…'
  ],
  'The nest is empty': [
    'Das Nest ist leer',
    'El nido está vacío',
    'Le nid est vide',
    'Il nido è vuoto',
    'O ninho está vazio',
    '巣は空です'
  ],
  'Choose one egg from your inventory.': [
    'Wähle ein Ei aus deinem Inventar.',
    'Elige un huevo de tu inventario.',
    'Choisissez un œuf dans votre inventaire.',
    'Scegli un uovo dal tuo inventario.',
    'Escolha um ovo do seu inventário.',
    '所持品から卵を一つ選んでください。'
  ],
  'Rare eggs can be found in chests earned on Adventures.': [
    'Seltene Eier können in Truhen aus Abenteuern gefunden werden.',
    'Puedes encontrar huevos raros en cofres ganados en Aventuras.',
    'Des œufs rares peuvent être trouvés dans les coffres gagnés en Aventure.',
    'Puoi trovare uova rare nei forzieri ottenuti nelle Avventure.',
    'Ovos raros podem ser encontrados em baús ganhos nas Aventuras.',
    '冒険で獲得した宝箱から珍しい卵が見つかることがあります。'
  ],
  'Choose an egg': [
    'Ei auswählen',
    'Elegir un huevo',
    'Choisir un œuf',
    'Scegli un uovo',
    'Escolher um ovo',
    '卵を選ぶ'
  ],
  'The egg moves to the Rooftop Nest. Your active dragon and the rest of the app stay available.':
      [
    'Das Ei zieht ins Dachnest. Dein aktiver Drache und der Rest der App bleiben verfügbar.',
    'El huevo se traslada al Nido de la Azotea. Tu dragón activo y el resto de la aplicación siguen disponibles.',
    'L’œuf rejoint le Nid du Toit. Votre dragon actif et le reste de l’application restent disponibles.',
    'L’uovo si sposta nel Nido sul Tetto. Il tuo drago attivo e il resto dell’app restano disponibili.',
    'O ovo vai para o Ninho do Telhado. Seu dragão ativo e o restante do aplicativo continuam disponíveis.',
    '卵は屋上の巣へ移動します。アクティブなドラゴンとアプリの他の機能は引き続き利用できます。'
  ],
  'Every form you raise leaves its magic on the page.': [
    'Jede Form, die du großziehst, hinterlässt ihre Magie auf der Seite.',
    'Cada forma que crías deja su magia en la página.',
    'Chaque forme que vous élevez laisse sa magie sur la page.',
    'Ogni forma che allevi lascia la sua magia sulla pagina.',
    'Cada forma que você cria deixa sua magia na página.',
    '育てたすべての姿が、このページに魔法を残します。'
  ],
  'Available': [
    'Verfügbar',
    'Disponibles',
    'Disponibles',
    'Disponibili',
    'Disponíveis',
    '利用可能'
  ],
  'Active': ['Aktiv', 'Activas', 'Actives', 'Attive', 'Ativas', '進行中'],
  'Choose a path. Bring back stories, training and treasure.': [
    'Wähle einen Pfad. Bring Geschichten, Training und Schätze zurück.',
    'Elige una ruta. Regresa con historias, entrenamiento y tesoros.',
    'Choisissez une voie. Rapportez des histoires, de l’entraînement et des trésors.',
    'Scegli un percorso. Torna con storie, allenamento e tesori.',
    'Escolha um caminho. Traga histórias, treino e tesouros.',
    '道を選び、物語と訓練の成果と宝物を持ち帰りましょう。'
  ],
  'No trail is available here right now.': [
    'Hier ist gerade kein Pfad verfügbar.',
    'Ahora mismo no hay ninguna ruta disponible aquí.',
    'Aucune piste n’est disponible ici pour le moment.',
    'Al momento non è disponibile alcun percorso qui.',
    'Nenhuma trilha está disponível aqui agora.',
    'ここには現在利用できる道がありません。'
  ],
  'Mystery chest': [
    'Mysteriöse Truhe',
    'Cofre misterioso',
    'Coffre mystère',
    'Forziere misterioso',
    'Baú misterioso',
    '謎の宝箱'
  ],
  'Start adventure': [
    'Abenteuer starten',
    'Iniciar aventura',
    'Commencer l’aventure',
    'Avvia avventura',
    'Iniciar aventura',
    '冒険を始める'
  ],
  'Choose a dragon': [
    'Drachen wählen',
    'Elige un dragón',
    'Choisir un dragon',
    'Scegli un drago',
    'Escolha um dragão',
    'ドラゴンを選ぶ'
  ],
  'Recommended for this path': [
    'Für diesen Pfad empfohlen',
    'Recomendados para esta ruta',
    'Recommandés pour cette voie',
    'Consigliati per questo percorso',
    'Recomendados para este caminho',
    'この道におすすめ'
  ],
  'Other available dragons': [
    'Andere verfügbare Drachen',
    'Otros dragones disponibles',
    'Autres dragons disponibles',
    'Altri draghi disponibili',
    'Outros dragões disponíveis',
    'ほかの利用可能なドラゴン'
  ],
  'Recommended': [
    'Empfohlen',
    'Recomendado',
    'Recommandé',
    'Consigliato',
    'Recomendado',
    'おすすめ'
  ],
  'No adventures are active': [
    'Keine Abenteuer sind aktiv',
    'No hay aventuras activas',
    'Aucune aventure n’est active',
    'Nessuna avventura è attiva',
    'Nenhuma aventura está ativa',
    '進行中の冒険はありません'
  ],
  'Send a dragon out and its journey will appear here.': [
    'Schicke einen Drachen los und seine Reise erscheint hier.',
    'Envía un dragón y su viaje aparecerá aquí.',
    'Envoyez un dragon et son voyage apparaîtra ici.',
    'Invia un drago e il suo viaggio apparirà qui.',
    'Envie um dragão e a jornada dele aparecerá aqui.',
    'ドラゴンを送り出すと、その旅がここに表示されます。'
  ],
  'Unknown dragon': [
    'Unbekannter Drache',
    'Dragón desconocido',
    'Dragon inconnu',
    'Drago sconosciuto',
    'Dragão desconhecido',
    '不明なドラゴン'
  ],
  'Ready to return': [
    'Bereit zur Rückkehr',
    'Listo para volver',
    'Prêt à revenir',
    'Pronto a tornare',
    'Pronto para voltar',
    '帰還可能'
  ],
  'Dragon': ['Drache', 'Dragón', 'Dragon', 'Drago', 'Dragão', 'ドラゴン'],
  'Status': ['Status', 'Estado', 'Statut', 'Stato', 'Status', '状態'],
  'Return in': [
    'Rückkehr in',
    'Regresa en',
    'Retour dans',
    'Ritorno tra',
    'Retorno em',
    '帰還まで'
  ],
  'Dragon experience': [
    'Drachenerfahrung',
    'Experiencia del dragón',
    'Expérience du dragon',
    'Esperienza del drago',
    'Experiência do dragão',
    'ドラゴン経験値'
  ],
  'Training reward': [
    'Trainingsbelohnung',
    'Recompensa de entrenamiento',
    'Récompense d’entraînement',
    'Ricompensa di allenamento',
    'Recompensa de treino',
    '訓練報酬'
  ],
  'Treasure': ['Schatz', 'Tesoro', 'Trésor', 'Tesoro', 'Tesouro', '宝物'],
  'One sealed chest': [
    'Eine versiegelte Truhe',
    'Un cofre sellado',
    'Un coffre scellé',
    'Un forziere sigillato',
    'Um baú selado',
    '封印された宝箱1個'
  ],
  'Claim rewards': [
    'Belohnungen abholen',
    'Recoger recompensas',
    'Récupérer les récompenses',
    'Ritira ricompense',
    'Coletar recompensas',
    '報酬を受け取る'
  ],
  'Short Adventures': [
    'Kurze Abenteuer',
    'Aventuras cortas',
    'Aventures courtes',
    'Avventure brevi',
    'Aventuras curtas',
    '短い冒険'
  ],
  'Long Adventures': [
    'Lange Abenteuer',
    'Aventuras largas',
    'Aventures longues',
    'Avventure lunghe',
    'Aventuras longas',
    '長い冒険'
  ],
  'Group Adventures': [
    'Gruppenabenteuer',
    'Aventuras de grupo',
    'Aventures de groupe',
    'Avventure di gruppo',
    'Aventuras em grupo',
    'グループ冒険'
  ],
  'Special Adventures': [
    'Besondere Abenteuer',
    'Aventuras especiales',
    'Aventures spéciales',
    'Avventure speciali',
    'Aventuras especiais',
    '特別な冒険'
  ],
  'Tiny outings': [
    'Kleine Ausflüge',
    'Pequeñas salidas',
    'Petites sorties',
    'Piccole uscite',
    'Pequenos passeios',
    '小さなお出かけ'
  ],
  'Quick routes': [
    'Schnelle Routen',
    'Rutas rápidas',
    'Itinéraires rapides',
    'Percorsi rapidi',
    'Rotas rápidas',
    '短いルート'
  ],
  'Patient journeys': [
    'Geduldige Reisen',
    'Viajes pacientes',
    'Voyages patients',
    'Viaggi pazienti',
    'Jornadas pacientes',
    '気長な旅'
  ],
  'Shared discoveries': [
    'Gemeinsame Entdeckungen',
    'Descubrimientos compartidos',
    'Découvertes partagées',
    'Scoperte condivise',
    'Descobertas compartilhadas',
    '共有の発見'
  ],
  'Rare trails': [
    'Seltene Pfade',
    'Rutas raras',
    'Pistes rares',
    'Percorsi rari',
    'Trilhas raras',
    '珍しい道'
  ],
  'Refresh rules': [
    'Aktualisierungsregeln',
    'Reglas de renovación',
    'Règles de renouvellement',
    'Regole di rinnovo',
    'Regras de renovação',
    '更新ルール'
  ],
  'Close': ['Schließen', 'Cerrar', 'Fermer', 'Chiudi', 'Fechar', '閉じる'],
  'Vanity': [
    'Erscheinungsbild',
    'Apariencia',
    'Apparence',
    'Aspetto',
    'Aparência',
    '外見'
  ],
  'Preferences': [
    'Einstellungen',
    'Preferencias',
    'Préférences',
    'Preferenze',
    'Preferências',
    '環境設定'
  ],
  'No completed adventures': [
    'Keine abgeschlossenen Abenteuer',
    'No hay aventuras completadas',
    'Aucune aventure terminée',
    'Nessuna avventura completata',
    'Nenhuma aventura concluída',
    '完了した冒険はありません'
  ],
  'Finished journeys wait here until you collect their rewards.': [
    'Beendete Reisen warten hier, bis du ihre Belohnungen abholst.',
    'Los viajes terminados esperan aquí hasta que recojas sus recompensas.',
    'Les voyages terminés attendent ici que vous récupériez leurs récompenses.',
    'I viaggi conclusi restano qui finché non ritiri le ricompense.',
    'As jornadas concluídas ficam aqui até você coletar as recompensas.',
    '終わった旅は報酬を受け取るまでここで待機します。'
  ],
  'Up to three routes wait. One free slot refills every 15 minutes. Visible routes stay until you start or dismiss them; they are not automatically replaced.':
      [
    'Bis zu drei Routen warten. Alle 15 Minuten wird ein freier Platz aufgefüllt. Sichtbare Routen bleiben, bis du sie startest oder verwirfst; sie werden nicht automatisch ersetzt.',
    'Esperan hasta tres rutas. Cada 15 minutos se rellena un espacio libre. Las rutas visibles permanecen hasta que las inicies o descartes; no se sustituyen automáticamente.',
    'Jusqu’à trois itinéraires attendent. Une place libre est remplie toutes les 15 minutes. Les itinéraires visibles restent jusqu’à leur lancement ou rejet ; ils ne sont pas remplacés automatiquement.',
    'Sono disponibili fino a tre percorsi. Ogni 15 minuti viene riempito uno spazio libero. I percorsi visibili restano finché non li avvii o scarti; non vengono sostituiti automaticamente.',
    'Até três rotas ficam disponíveis. Uma vaga livre é preenchida a cada 15 minutos. As rotas visíveis permanecem até serem iniciadas ou descartadas; não são substituídas automaticamente.',
    '最大3つのルートが待機します。空き枠は15分ごとに1つ補充されます。表示中のルートは開始または破棄するまで残り、自動では入れ替わりません。'
  ],
  'Up to three routes wait. One free slot refills every hour. Visible routes stay until you start or dismiss them; they are not automatically replaced.':
      [
    'Bis zu drei Routen warten. Jede Stunde wird ein freier Platz aufgefüllt. Sichtbare Routen bleiben, bis du sie startest oder verwirfst; sie werden nicht automatisch ersetzt.',
    'Esperan hasta tres rutas. Cada hora se rellena un espacio libre. Las rutas visibles permanecen hasta que las inicies o descartes; no se sustituyen automáticamente.',
    'Jusqu’à trois itinéraires attendent. Une place libre est remplie chaque heure. Les itinéraires visibles restent jusqu’à leur lancement ou rejet ; ils ne sont pas remplacés automatiquement.',
    'Sono disponibili fino a tre percorsi. Ogni ora viene riempito uno spazio libero. I percorsi visibili restano finché non li avvii o scarti; non vengono sostituiti automaticamente.',
    'Até três rotas ficam disponíveis. Uma vaga livre é preenchida a cada hora. As rotas visíveis permanecem até serem iniciadas ou descartadas; não são substituídas automaticamente.',
    '最大3つのルートが待機します。空き枠は1時間ごとに1つ補充されます。表示中のルートは開始または破棄するまで残り、自動では入れ替わりません。'
  ],
  'Up to three routes wait. Free slots refill at local midnight. Visible routes stay until you start or dismiss them; they are not automatically replaced.':
      [
    'Bis zu drei Routen warten. Freie Plätze werden um lokale Mitternacht aufgefüllt. Sichtbare Routen bleiben, bis du sie startest oder verwirfst; sie werden nicht automatisch ersetzt.',
    'Esperan hasta tres rutas. Los espacios libres se rellenan a medianoche local. Las rutas visibles permanecen hasta que las inicies o descartes; no se sustituyen automáticamente.',
    'Jusqu’à trois itinéraires attendent. Les places libres sont remplies à minuit, heure locale. Les itinéraires visibles restent jusqu’à leur lancement ou rejet ; ils ne sont pas remplacés automatiquement.',
    'Sono disponibili fino a tre percorsi. Gli spazi liberi vengono riempiti alla mezzanotte locale. I percorsi visibili restano finché non li avvii o scarti; non vengono sostituiti automaticamente.',
    'Até três rotas ficam disponíveis. As vagas livres são preenchidas à meia-noite local. As rotas visíveis permanecem até serem iniciadas ou descartadas; não são substituídas automaticamente.',
    '最大3つのルートが待機します。空き枠は現地時間の深夜0時に補充されます。表示中のルートは開始または破棄するまで残り、自動では入れ替わりません。'
  ],
  'Every keeper sees the same weekly route. It changes automatically every Sunday at 12:00 in Europe/Amsterdam. A group that already started always finishes and keeps its reward.':
      [
    'Alle Hüter sehen dieselbe wöchentliche Route. Sie wechselt automatisch jeden Sonntag um 12:00 Uhr in Europe/Amsterdam. Eine bereits gestartete Gruppe beendet die Reise immer und behält ihre Belohnung.',
    'Todos los cuidadores ven la misma ruta semanal. Cambia automáticamente cada domingo a las 12:00 en Europe/Amsterdam. Un grupo que ya empezó siempre termina y conserva su recompensa.',
    'Tous les gardiens voient le même itinéraire hebdomadaire. Il change automatiquement chaque dimanche à 12 h dans Europe/Amsterdam. Un groupe déjà parti termine toujours et conserve sa récompense.',
    'Tutti i custodi vedono lo stesso percorso settimanale. Cambia automaticamente ogni domenica alle 12:00 in Europe/Amsterdam. Un gruppo già partito conclude sempre il viaggio e conserva la ricompensa.',
    'Todos os guardiões veem a mesma rota semanal. Ela muda automaticamente todo domingo às 12:00 em Europe/Amsterdam. Um grupo que já começou sempre termina e mantém a recompensa.',
    'すべてのキーパーに同じ週間ルートが表示されます。Europe/Amsterdamの毎週日曜12:00に自動更新されます。出発済みのグループは必ず完走し、報酬も保持されます。'
  ],
  'Special routes appear only during certain events. They can expire or change automatically; their card shows them only while they are available.':
      [
    'Spezialrouten erscheinen nur während bestimmter Ereignisse. Sie können automatisch ablaufen oder wechseln; ihre Karte wird nur während der Verfügbarkeit angezeigt.',
    'Las rutas especiales solo aparecen durante ciertos eventos. Pueden caducar o cambiar automáticamente; su tarjeta solo se muestra mientras estén disponibles.',
    'Les itinéraires spéciaux n’apparaissent que pendant certains événements. Ils peuvent expirer ou changer automatiquement ; leur carte n’est visible que pendant leur disponibilité.',
    'I percorsi speciali appaiono solo durante determinati eventi. Possono scadere o cambiare automaticamente; la loro scheda è visibile solo mentre sono disponibili.',
    'Rotas especiais aparecem apenas durante certos eventos. Elas podem expirar ou mudar automaticamente; o cartão só aparece enquanto estão disponíveis.',
    '特別ルートは特定のイベント中にのみ表示されます。自動で期限切れまたは変更されることがあり、利用可能な間だけカードが表示されます。'
  ],
  'Tiny outings, quick training and wooden chests.': [
    'Winzige Ausflüge, schnelles Training und Holzkisten.',
    'Pequeñas salidas, entrenamiento rápido y cofres de madera.',
    'Petites sorties, entraînement rapide et coffres en bois.',
    'Piccole uscite, allenamento rapido e forzieri di legno.',
    'Pequenos passeios, treino rápido e baús de madeira.',
    '小さなお出かけ、手軽な訓練、そして木の宝箱。'
  ],
  'Quick routes that refresh throughout the day.': [
    'Schnelle Routen, die sich im Laufe des Tages erneuern.',
    'Rutas rápidas que se renuevan durante el día.',
    'Des itinéraires rapides renouvelés au fil de la journée.',
    'Percorsi rapidi che si aggiornano durante il giorno.',
    'Rotas rápidas que se renovam ao longo do dia.',
    '一日を通して更新される短いルートです。'
  ],
  'Patient journeys with richer returns.': [
    'Geduldige Reisen mit reicheren Erträgen.',
    'Viajes pacientes con mejores recompensas.',
    'Des voyages patients aux gains plus riches.',
    'Viaggi pazienti con ricompense più ricche.',
    'Jornadas pacientes com retornos melhores.',
    '時間をかけるぶん、実り豊かな旅です。'
  ],
  'Shared discoveries for connected keepers.': [
    'Gemeinsame Entdeckungen für verbundene Hüter.',
    'Descubrimientos compartidos para cuidadores conectados.',
    'Des découvertes partagées pour les gardiens connectés.',
    'Scoperte condivise per custodi collegati.',
    'Descobertas compartilhadas para guardiões conectados.',
    'つながったキーパーたちで挑む共同発見です。'
  ],
  'Rare trails that only appear at special moments.': [
    'Seltene Pfade, die nur zu besonderen Momenten erscheinen.',
    'Rutas raras que solo aparecen en momentos especiales.',
    'Des pistes rares qui n’apparaissent qu’à des moments particuliers.',
    'Percorsi rari che appaiono solo in momenti speciali.',
    'Trilhas raras que só aparecem em momentos especiais.',
    '特別な瞬間にだけ現れる珍しい道です。'
  ],
  'Might': ['Stärke', 'Fuerza', 'Puissance', 'Potenza', 'Força', '力'],
  'Arcana': ['Arkana', 'Arcanos', 'Arcanes', 'Arcano', 'Arcana', '秘術'],
  'Spirit': ['Geist', 'Espíritu', 'Esprit', 'Spirito', 'Espírito', '精神'],
  'No dragon is available for this adventure.': [
    'Für dieses Abenteuer ist kein Drache verfügbar.',
    'No hay ningún dragón disponible para esta aventura.',
    'Aucun dragon n’est disponible pour cette aventure.',
    'Nessun drago è disponibile per questa avventura.',
    'Nenhum dragão está disponível para esta aventura.',
    'この冒険に参加できるドラゴンがいません。'
  ],
  'Roaming in the Tower': [
    'Unterwegs im Turm',
    'Paseando por la Torre',
    'Se promène dans la Tour',
    'Gira per la Torre',
    'Passeando pela Torre',
    '塔を散歩中'
  ],
  'Resting off-stage': [
    'Ruht außerhalb der Räume',
    'Descansa fuera de escena',
    'Se repose hors scène',
    'Riposa fuori scena',
    'Descansando fora de cena',
    '画面外で休憩中'
  ],
  'Free roaming in the Tower': [
    'Freies Herumlaufen im Turm',
    'Paseo libre por la Torre',
    'Déplacement libre dans la Tour',
    'Libero movimento nella Torre',
    'Livre circulação na Torre',
    '塔内を自由に歩く'
  ],
  'This dragon may appear and wander through rooms.': [
    'Dieser Drache kann in Räumen erscheinen und umherlaufen.',
    'Este dragón puede aparecer y pasear por las habitaciones.',
    'Ce dragon peut apparaître et se promener dans les pièces.',
    'Questo drago può apparire e girare per le stanze.',
    'Este dragão pode aparecer e passear pelos cômodos.',
    'このドラゴンは部屋に現れて歩き回れます。'
  ],
  'Zoom out': [
    'Herauszoomen',
    'Alejar',
    'Dézoomer',
    'Riduci zoom',
    'Diminuir zoom',
    'ズームアウト'
  ],
  'The dragons found cozy places on other floors.': [
    'Die Drachen haben gemütliche Plätze auf anderen Etagen gefunden.',
    'Los dragones encontraron lugares acogedores en otros pisos.',
    'Les dragons ont trouvé des endroits confortables aux autres étages.',
    'I draghi hanno trovato posti accoglienti sugli altri piani.',
    'Os dragões encontraram lugares aconchegantes em outros andares.',
    'ドラゴンたちは別の階で居心地のよい場所を見つけました。'
  ],
  'Build another floor before clearing this room.': [
    'Baue eine weitere Etage, bevor du diesen Raum leerst.',
    'Construye otro piso antes de despejar esta habitación.',
    'Construisez un autre étage avant de vider cette pièce.',
    'Costruisci un altro piano prima di liberare questa stanza.',
    'Construa outro andar antes de esvaziar este cômodo.',
    'この部屋からドラゴンを移す前に、別の階を建ててください。'
  ],
  'Finish decorating': [
    'Dekorieren beenden',
    'Terminar de decorar',
    'Terminer la décoration',
    'Termina decorazione',
    'Terminar decoração',
    '模様替えを終える'
  ],
  'Clear dragons': [
    'Drachen umquartieren',
    'Mover dragones',
    'Déplacer les dragons',
    'Sposta draghi',
    'Mover dragões',
    'ドラゴンを移動'
  ],
  'TAP TO GUIDE YOUR FAVORITE': [
    'TIPPE, UM DEINEN FAVORITEN ZU LENKEN',
    'TOCA PARA GUIAR A TU FAVORITO',
    'TOUCHEZ POUR GUIDER VOTRE FAVORI',
    'TOCCA PER GUIDARE IL TUO PREFERITO',
    'TOQUE PARA GUIAR SEU FAVORITO',
    'タップしてお気に入りを導く'
  ],
  'TAP TO CALL YOUR FAVORITE': [
    'TIPPE, UM DEINEN FAVORITEN ZU RUFEN',
    'TOCA PARA LLAMAR A TU FAVORITO',
    'TOUCHEZ POUR APPELER VOTRE FAVORI',
    'TOCCA PER CHIAMARE IL TUO PREFERITO',
    'TOQUE PARA CHAMAR SEU FAVORITO',
    'タップしてお気に入りを呼ぶ'
  ],
  'Dragon type': [
    'Drachentyp',
    'Tipo de dragón',
    'Type de dragon',
    'Tipo di drago',
    'Tipo de dragão',
    'ドラゴンの種類'
  ],
  'Maturity': [
    'Reifestufe',
    'Madurez',
    'Maturité',
    'Maturità',
    'Maturidade',
    '成長段階'
  ],
  'Experience': [
    'Erfahrung',
    'Experiencia',
    'Expérience',
    'Esperienza',
    'Experiência',
    '経験値'
  ],
  'Level': ['Level', 'Nivel', 'Niveau', 'Livello', 'Nível', 'レベル'],
  'Invite to Tower': [
    'In den Turm einladen',
    'Invitar a la Torre',
    'Inviter dans la Tour',
    'Invita nella Torre',
    'Convidar para a Torre',
    '塔に招待する'
  ],
  'The Tower is full. Build another floor or disable another roaming dragon.': [
    'Der Turm ist voll. Baue eine weitere Etage oder deaktiviere einen anderen umherziehenden Drachen.',
    'La Torre está llena. Construye otro piso o desactiva otro dragón que deambula.',
    'La Tour est pleine. Construisez un autre étage ou désactivez un autre dragon en liberté.',
    'La Torre è piena. Costruisci un altro piano o disattiva un altro drago in giro.',
    'A Torre está cheia. Construa outro andar ou desative outro dragão que circula.',
    '塔が満員です。階を増やすか、別のドラゴンの巡回を解除してください。'
  ],
  'Duration': ['Dauer', 'Duración', 'Durée', 'Durata', 'Duração', '所要時間'],
  'connected keepers': [
    'verbundene Hüter',
    'cuidadores conectados',
    'gardiens connectés',
    'custodi collegati',
    'guardiões conectados',
    'つながっているキーパー'
  ],
  'Expertise training': [
    'Expertisentraining',
    'Entrenamiento de pericia',
    'Entraînement d’expertise',
    'Allenamento competenza',
    'Treino de especialidade',
    '専門技能トレーニング'
  ],
  'Expertises': [
    'Expertisen',
    'Pericias',
    'Expertises',
    'Competenze',
    'Especialidades',
    '専門技能'
  ],
  'Possible chests': [
    'Mögliche Truhen',
    'Cofres posibles',
    'Coffres possibles',
    'Forzieri possibili',
    'Baús possíveis',
    '入手可能な宝箱'
  ],
  'Keeper requirement': [
    'Hüter-Anforderung',
    'Requisito de cuidadores',
    'Condition de gardiens',
    'Requisito dei custodi',
    'Requisito de guardiões',
    'キーパー条件'
  ],
  'shapes a Might Ascension': [
    'prägt eine Stärke-Aszension',
    'moldea una Ascensión de Fuerza',
    'façonne une Ascension de Puissance',
    'plasma un’Ascensione di Potenza',
    'molda uma Ascensão de Força',
    '力のアセンションを形作る'
  ],
  'shapes an Arcana Ascension': [
    'prägt eine Arkana-Aszension',
    'moldea una Ascensión Arcana',
    'façonne une Ascension des Arcanes',
    'plasma un’Ascensione Arcana',
    'molda uma Ascensão Arcana',
    '秘術のアセンションを形作る'
  ],
  'shapes a Spirit Ascension': [
    'prägt eine Geist-Aszension',
    'moldea una Ascensión de Espíritu',
    'façonne une Ascension d’Esprit',
    'plasma un’Ascensione di Spirito',
    'molda uma Ascensão de Espírito',
    '精神のアセンションを形作る'
  ],
  'Lawful': ['Rechtschaffen', 'Legal', 'Loyal', 'Legale', 'Leal', '秩序'],
  'Neutral': ['Neutral', 'Neutral', 'Neutre', 'Neutrale', 'Neutro', '中立'],
  'Chaotic': ['Chaotisch', 'Caótico', 'Chaotique', 'Caotico', 'Caótico', '混沌'],
  'Good': ['Gut', 'Bueno', 'Bon', 'Buono', 'Bom', '善'],
  'Evil': ['Böse', 'Malvado', 'Mauvais', 'Malvagio', 'Mau', '悪'],
  'Moral nature': [
    'Moralische Natur',
    'Naturaleza moral',
    'Nature morale',
    'Natura morale',
    'Natureza moral',
    '道徳的性質'
  ],
  'Order nature': [
    'Ordnungsnatur',
    'Naturaleza de orden',
    'Nature d’ordre',
    'Natura dell’ordine',
    'Natureza de ordem',
    '秩序的性質'
  ],
  'Personality': [
    'Persönlichkeit',
    'Personalidad',
    'Personnalité',
    'Personalità',
    'Personalidade',
    '性格'
  ],
  'Undiscovered': [
    'Unentdeckt',
    'Sin descubrir',
    'Non découvert',
    'Non scoperto',
    'Não descoberto',
    '未発見'
  ],
  'Highest level reached': [
    'Höchste Stufe erreicht',
    'Nivel máximo alcanzado',
    'Niveau maximal atteint',
    'Livello massimo raggiunto',
    'Nível máximo alcançado',
    '最高レベルに到達'
  ],
  'to next level': [
    'bis zur nächsten Stufe',
    'para el siguiente nivel',
    'avant le niveau suivant',
    'al livello successivo',
    'para o próximo nível',
    '次のレベルまで'
  ],
  'Final evolution reached': [
    'Letzte Evolution erreicht',
    'Evolución final alcanzada',
    'Évolution finale atteinte',
    'Evoluzione finale raggiunta',
    'Evolução final alcançada',
    '最終進化に到達'
  ],
  'Next evolution': [
    'Nächste Evolution',
    'Próxima evolución',
    'Prochaine évolution',
    'Prossima evoluzione',
    'Próxima evolução',
    '次の進化'
  ],
  'Relics': ['Relikte', 'Reliquias', 'Reliques', 'Reliquie', 'Relíquias', '秘宝'],
  'No Relics yet': [
    'Noch keine Relikte',
    'Aún no hay Reliquias',
    'Pas encore de Reliques',
    'Ancora nessuna Reliquia',
    'Ainda não há Relíquias',
    '秘宝はまだありません'
  ],
  'Incubation after nesting': [
    'Brutzeit nach dem Einsetzen',
    'Incubación tras colocarlo',
    'Incubation après installation',
    'Incubazione dopo il posizionamento',
    'Incubação após colocar no ninho',
    '巣に置いた後の孵化時間'
  ],
  'Use this Relic?': [
    'Dieses Relikt benutzen?',
    '¿Usar esta Reliquia?',
    'Utiliser cette Relique ?',
    'Usare questa Reliquia?',
    'Usar esta Relíquia?',
    'この秘宝を使いますか？'
  ],
  'This is a consumable item. It disappears after revealing one dragon. Continue?':
      [
    'Dies ist ein Verbrauchsgegenstand. Er verschwindet, nachdem er einen Drachen enthüllt hat. Fortfahren?',
    'Este objeto es consumible. Desaparece tras revelar un dragón. ¿Continuar?',
    'Cet objet est consommable. Il disparaît après avoir révélé un dragon. Continuer ?',
    'Questo oggetto è consumabile. Scompare dopo aver rivelato un drago. Continuare?',
    'Este item é consumível. Ele desaparece após revelar um dragão. Continuar?',
    'これは消耗アイテムです。ドラゴンを1体明かすと消えます。続けますか？'
  ],
  'Continue': [
    'Weiter',
    'Continuar',
    'Continuer',
    'Continua',
    'Continuar',
    '続ける'
  ],
  'Rewards': [
    'Belohnungen',
    'Recompensas',
    'Récompenses',
    'Ricompense',
    'Recompensas',
    '報酬',
  ],
  '1 Gold, Dragon or Mythical Chest': [
    '1 Gold-, Drachen- oder Mythische Truhe',
    '1 Cofre Dorado, de Dragón o Mítico',
    '1 Coffre d’or, de Dragon ou Mythique',
    '1 Forziere d’Oro, del Drago o Mitico',
    '1 Baú de Ouro, de Dragão ou Mítico',
    'ゴールド、ドラゴン、ミシカル宝箱のいずれか1個',
  ],
  '1 random relic': [
    '1 zufälliges Relikt',
    '1 reliquia aleatoria',
    '1 relique aléatoire',
    '1 reliquia casuale',
    '1 relíquia aleatória',
    'ランダムな秘宝1個',
  ],
  'Tap the chest to open': [
    'Tippe zum Öffnen auf die Truhe',
    'Toca el cofre para abrirlo',
    'Touchez le coffre pour l’ouvrir',
    'Tocca il forziere per aprirlo',
    'Toque no baú para abrir',
    '宝箱をタップして開く',
  ],
  'Music revealed': [
    'Musik enthüllt',
    'Música revelada',
    'Musique révélée',
    'Musica rivelata',
    'Música revelada',
    '楽曲を獲得',
  ],
  'Claim': ['Abholen', 'Recoger', 'Récupérer', 'Riscatta', 'Coletar', '受け取る'],
  'Remove from Tower': [
    'Aus dem Turm entfernen',
    'Retirar de la Torre',
    'Retirer de la Tour',
    'Rimuovi dalla Torre',
    'Remover da Torre',
    '塔から外す'
  ],
  'Ancient magic awakens': [
    'Uralte Magie erwacht',
    'La magia antigua despierta',
    'Une magie ancienne s’éveille',
    'La magia antica si risveglia',
    'A magia antiga desperta',
    '古の魔法が目覚める'
  ],
  'Sealed treasure': [
    'Versiegelter Schatz',
    'Tesoro sellado',
    'Trésor scellé',
    'Tesoro sigillato',
    'Tesouro selado',
    '封印された宝物'
  ],
  'Chest opening': [
    'Truhe öffnet sich',
    'El cofre se abre',
    'Ouverture du coffre',
    'Apertura del forziere',
    'Baú abrindo',
    '宝箱を開封中'
  ],
  'These exceptionally rare treasures can appear in Gold Chests and rarer chests.':
      [
    'Diese außergewöhnlich seltenen Schätze können in Goldtruhen und selteneren Truhen erscheinen.',
    'Estos tesoros excepcionalmente raros pueden aparecer en Cofres Dorados y cofres más raros.',
    'Ces trésors exceptionnellement rares peuvent apparaître dans les Coffres d’or et les coffres plus rares.',
    'Questi tesori eccezionalmente rari possono apparire nei Forzieri d’Oro e in quelli più rari.',
    'Esses tesouros excepcionalmente raros podem aparecer em Baús de Ouro e baús mais raros.',
    'この極めて希少な宝物は、ゴールド宝箱以上の宝箱から出現します。'
  ],
  'Choose carefully: each relic reveals one dragon and is consumed.': [
    'Wähle mit Bedacht: Jedes Relikt enthüllt einen Drachen und wird verbraucht.',
    'Elige con cuidado: cada reliquia revela un dragón y se consume.',
    'Choisissez avec soin : chaque relique révèle un dragon et est consommée.',
    'Scegli con cura: ogni reliquia rivela un drago e viene consumata.',
    'Escolha com cuidado: cada relíquia revela um dragão e é consumida.',
    '慎重に選んでください。秘宝は1体のドラゴンを明かし、使用すると消費されます。'
  ],
  'Use': ['Benutzen', 'Usar', 'Utiliser', 'Usa', 'Usar', '使う'],
  'Already revealed': [
    'Bereits enthüllt',
    'Ya revelado',
    'Déjà révélé',
    'Già rivelato',
    'Já revelado',
    '確認済み'
  ],
  'Secret still hidden': [
    'Geheimnis noch verborgen',
    'Secreto aún oculto',
    'Secret encore caché',
    'Segreto ancora nascosto',
    'Segredo ainda oculto',
    '秘密はまだ隠されています'
  ],
  'Remember this': [
    'Merken',
    'Recordar esto',
    'S’en souvenir',
    'Ricordalo',
    'Lembrar disso',
    '覚えておく'
  ],
  'Moral Prism': [
    'Moralprisma',
    'Prisma Moral',
    'Prisme Moral',
    'Prisma Morale',
    'Prisma Moral',
    '道徳のプリズム'
  ],
  'Order Compass': [
    'Ordnungskompass',
    'Brújula del Orden',
    'Boussole de l’Ordre',
    'Bussola dell’Ordine',
    'Bússola da Ordem',
    '秩序の羅針盤'
  ],
  'Soul Mirror': [
    'Seelenspiegel',
    'Espejo del Alma',
    'Miroir de l’Âme',
    'Specchio dell’Anima',
    'Espelho da Alma',
    '魂の鏡'
  ],
  'Reveals whether one dragon leans toward Good, Neutral or Evil.': [
    'Enthüllt, ob ein Drache zu Gut, Neutral oder Böse neigt.',
    'Revela si un dragón se inclina hacia el Bien, la Neutralidad o el Mal.',
    'Révèle si un dragon penche vers le Bien, la Neutralité ou le Mal.',
    'Rivela se un drago tende al Bene, alla Neutralità o al Male.',
    'Revela se um dragão tende ao Bem, à Neutralidade ou ao Mal.',
    '1体のドラゴンが善・中立・悪のどれに傾くかを明かします。'
  ],
  'Reveals whether one dragon is Lawful, Neutral or Chaotic.': [
    'Enthüllt, ob ein Drache rechtschaffen, neutral oder chaotisch ist.',
    'Revela si un dragón es Legal, Neutral o Caótico.',
    'Révèle si un dragon est Loyal, Neutre ou Chaotique.',
    'Rivela se un drago è Legale, Neutrale o Caotico.',
    'Revela se um dragão é Leal, Neutro ou Caótico.',
    '1体のドラゴンが秩序・中立・混沌のどれかを明かします。'
  ],
  'Reveals the hidden personality traits of one dragon.': [
    'Enthüllt die verborgenen Persönlichkeitsmerkmale eines Drachen.',
    'Revela los rasgos de personalidad ocultos de un dragón.',
    'Révèle les traits de personnalité cachés d’un dragon.',
    'Rivela i tratti nascosti della personalità di un drago.',
    'Revela os traços de personalidade ocultos de um dragão.',
    '1体のドラゴンに隠された性格特性を明かします。'
  ],
  'Sleepy': [
    'Schläfrig',
    'Dormilón',
    'Somnolent',
    'Sonnolento',
    'Sonolento',
    '眠たがり'
  ],
  'Nosy': [
    'Neugierig',
    'Entrometido',
    'Fouineur',
    'Ficcanaso',
    'Intrometido',
    '詮索好き'
  ],
  'Hoarder': [
    'Sammler',
    'Acaparador',
    'Collectionneur',
    'Accumulatore',
    'Acumulador',
    'ため込み屋'
  ],
  'Drama Queen': [
    'Dramakönig',
    'Reina del drama',
    'Roi du drame',
    'Re del dramma',
    'Rei do drama',
    'ドラマ王'
  ],
  'Bookworm': [
    'Bücherwurm',
    'Ratón de biblioteca',
    'Rat de bibliothèque',
    'Topo di biblioteca',
    'Rato de biblioteca',
    '本の虫'
  ],
  'Food Thief': [
    'Futterdieb',
    'Ladrón de comida',
    'Voleur de nourriture',
    'Ladro di cibo',
    'Ladrão de comida',
    '食いしん坊泥棒'
  ],
  'Afraid of Heights': [
    'Höhenangst',
    'Miedo a las alturas',
    'Peur du vide',
    'Paura dell’altezza',
    'Medo de altura',
    '高所恐怖症'
  ],
  'Restless': [
    'Rastlos',
    'Inquieto',
    'Agité',
    'Irrequieto',
    'Inquieto',
    '落ち着きがない'
  ],
  'Shy': ['Schüchtern', 'Tímido', 'Timide', 'Timido', 'Tímido', '恥ずかしがり'],
  'Show-Off': [
    'Angeber',
    'Presumido',
    'Frimeur',
    'Esibizionista',
    'Exibido',
    '目立ちたがり'
  ],
  'Clumsy': [
    'Tollpatschig',
    'Torpe',
    'Maladroit',
    'Goffo',
    'Desajeitado',
    '不器用'
  ],
  'Neat Freak': [
    'Ordnungsfanatiker',
    'Fanático del orden',
    'Maniaque du rangement',
    'Maniaco dell’ordine',
    'Fanático por organização',
    'きれい好き'
  ],
  'Messy': [
    'Unordentlich',
    'Desordenado',
    'Désordonné',
    'Disordinato',
    'Bagunceiro',
    '散らかし屋'
  ],
  'Stubborn': ['Stur', 'Terco', 'Têtu', 'Testardo', 'Teimoso', '頑固'],
  'Cuddly': [
    'Kuschelig',
    'Cariñoso',
    'Câlin',
    'Coccolone',
    'Carinhoso',
    '甘えん坊'
  ],
  'Grumpy': ['Mürrisch', 'Gruñón', 'Grognon', 'Brontolone', 'Rabugento', '不機嫌'],
  'Easily Distracted': [
    'Leicht ablenkbar',
    'Se distrae fácilmente',
    'Facilement distrait',
    'Si distrae facilmente',
    'Distrai-se facilmente',
    '気が散りやすい'
  ],
  'Night Owl': [
    'Nachteule',
    'Noctámbulo',
    'Oiseau de nuit',
    'Nottambulo',
    'Notívago',
    '夜更かし'
  ],
  'Early Bird': [
    'Frühaufsteher',
    'Madrugador',
    'Lève-tôt',
    'Mattiniero',
    'Madrugador',
    '早起き'
  ],
  'Splash Lover': [
    'Planschfreund',
    'Amante de las salpicaduras',
    'Fan d’éclaboussures',
    'Amante degli spruzzi',
    'Amante de respingos',
    '水遊び好き'
  ],
  'Firebug': [
    'Feuerteufel',
    'Pirómano',
    'Pyromane',
    'Piromane',
    'Incendiário',
    '火遊び好き'
  ],
  'Attention Seeker': [
    'Aufmerksamkeitssucher',
    'Busca atención',
    'En quête d’attention',
    'In cerca di attenzioni',
    'Busca atenção',
    'かまってちゃん'
  ],
  'Startles Easily': [
    'Schreckhaft',
    'Se asusta fácilmente',
    'Facile à effrayer',
    'Si spaventa facilmente',
    'Assusta-se facilmente',
    '驚きやすい'
  ],
  'Tutorial': [
    'Tutorial',
    'Tutorial',
    'Tutoriel',
    'Tutorial',
    'Tutorial',
    'チュートリアル'
  ],
  'Welcome to DragonHaven': [
    'Willkommen in DragonHaven',
    'Te damos la bienvenida a DragonHaven',
    'Bienvenue dans DragonHaven',
    'Benvenuto a DragonHaven',
    'Boas-vindas a DragonHaven',
    'DragonHavenへようこそ'
  ],
  'will show you around. You can skip now and replay this tour later from the three-dot menu.':
      [
    'zeigt dir alles. Du kannst jetzt überspringen und diese Führung später über das Dreipunkt-Menü wiederholen.',
    'te enseñará todo. Puedes omitirlo ahora y repetir este recorrido más tarde desde el menú de tres puntos.',
    'va te guider. Tu peux passer maintenant et relancer cette visite plus tard depuis le menu à trois points.',
    'ti farà da guida. Puoi saltare ora e ripetere il tour più tardi dal menu con i tre puntini.',
    'vai guiar você. Você pode pular agora e repetir este passeio depois pelo menu de três pontos.',
    'が案内します。今はスキップしても、後で三点メニューからもう一度始められます。'
  ],
  'Online friends': [
    'Online-Freunde',
    'Amigos en línea',
    'Amis en ligne',
    'Amici online',
    'Amigos online',
    'オンラインのフレンド'
  ],
  "Create an e-mail-verified online account, then add other keepers by their Keeper ID. Friends can open each other's public profile and see portraits, titles, favorite dragons, discovered forms and Trial records.":
      [
    'Erstelle ein per E-Mail bestätigtes Online-Konto und füge andere Hüter über ihre Hüter-ID hinzu. Freunde können gegenseitig ihre öffentlichen Profile öffnen und Porträts, Titel, Lieblingsdrachen, entdeckte Formen und Prüfungsrekorde sehen.',
    'Crea una cuenta en línea verificada por correo electrónico y añade a otros guardianes mediante su ID. Los amigos pueden abrir sus perfiles públicos y ver retratos, títulos, dragones favoritos, formas descubiertas y récords de Pruebas.',
    'Crée un compte en ligne vérifié par e-mail, puis ajoute d’autres gardiens grâce à leur identifiant. Les amis peuvent consulter leurs profils publics, portraits, titres, dragons favoris, formes découvertes et records d’Épreuves.',
    'Crea un account online verificato via e-mail e aggiungi altri custodi tramite il loro ID. Gli amici possono aprire i profili pubblici e vedere ritratti, titoli, draghi preferiti, forme scoperte e record delle Prove.',
    'Crie uma conta online verificada por e-mail e adicione outros guardiões pelo ID. Amigos podem abrir os perfis públicos uns dos outros e ver retratos, títulos, dragões favoritos, formas descobertas e recordes das Provas.',
    'メール認証済みのオンラインアカウントを作成し、Keeper IDでほかのキーパーを追加できます。フレンド同士で公開プロフィール、ポートレート、称号、お気に入りのドラゴン、発見済み形態、試練記録を確認できます。'
  ],
  'Trade and travel together': [
    'Gemeinsam handeln und reisen',
    'Intercambia y viaja en compañía',
    'Échanger et voyager ensemble',
    'Scambia e viaggia insieme',
    'Troque e viaje em grupo',
    '一緒に交換して冒険'
  ],
  'From a friend you can offer a protected one-to-one Trade: eggs, chests and Relics stay reserved until it completes or expires. Logged-in friends can also enroll dragons together in asynchronous Group Adventures.':
      [
    'Bei einem Freund kannst du einen geschützten Eins-zu-eins-Tausch anbieten: Eier, Truhen und Relikte bleiben reserviert, bis der Tausch abgeschlossen ist oder abläuft. Angemeldete Freunde können ihre Drachen außerdem gemeinsam für asynchrone Gruppenabenteuer anmelden.',
    'Desde el perfil de un amigo puedes ofrecer un intercambio individual protegido: los huevos, cofres y Reliquias quedan reservados hasta que termine o caduque. Los amigos conectados también pueden inscribir dragones juntos en Aventuras grupales asíncronas.',
    'Depuis le profil d’un ami, tu peux proposer un échange individuel sécurisé : œufs, coffres et Reliques restent réservés jusqu’à sa conclusion ou son expiration. Les amis connectés peuvent aussi inscrire ensemble leurs dragons à des Aventures de groupe asynchrones.',
    'Dal profilo di un amico puoi proporre uno scambio uno a uno protetto: uova, scrigni e Reliquie restano riservati finché lo scambio non termina o scade. Gli amici connessi possono anche iscrivere insieme i draghi alle Avventure di gruppo asincrone.',
    'No perfil de um amigo, você pode oferecer uma troca individual protegida: ovos, baús e Relíquias ficam reservados até a conclusão ou expiração. Amigos conectados também podem inscrever dragões juntos em Aventuras em grupo assíncronas.',
    'フレンドには保護された1対1の交換を提案できます。卵、宝箱、レリックは交換が完了または期限切れになるまで確保されます。ログイン中のフレンド同士で、非同期のグループ冒険にドラゴンを参加させることもできます。'
  ],
  "Mini Adventures take minutes, Short Adventures hours and Long Adventures days. A dragon's matching Expertise shortens the timer. Group Adventures need 2–4 logged-in friends and begin automatically when their requirements are met.":
      [
    'Mini-Abenteuer dauern Minuten, kurze Abenteuer Stunden und lange Abenteuer Tage. Die passende Expertise eines Drachen verkürzt den Timer. Gruppenabenteuer benötigen 2–4 angemeldete Freunde und starten automatisch, sobald ihre Anforderungen erfüllt sind.',
    'Las Aventuras mini duran minutos, las cortas horas y las largas días. La Pericia correspondiente del dragón reduce el tiempo. Las Aventuras grupales necesitan entre 2 y 4 amigos conectados y comienzan automáticamente cuando se cumplen los requisitos.',
    'Les mini-Aventures durent quelques minutes, les Aventures courtes plusieurs heures et les longues plusieurs jours. L’Expertise correspondante du dragon réduit le temps. Les Aventures de groupe nécessitent 2 à 4 amis connectés et commencent automatiquement lorsque leurs conditions sont remplies.',
    'Le Avventure mini durano minuti, quelle brevi ore e quelle lunghe giorni. La Competenza corrispondente del drago riduce il tempo. Le Avventure di gruppo richiedono 2–4 amici connessi e iniziano automaticamente quando i requisiti sono soddisfatti.',
    'Aventuras mini duram minutos, Aventuras curtas duram horas e Aventuras longas duram dias. A Especialidade correspondente do dragão reduz o tempo. Aventuras em grupo precisam de 2–4 amigos conectados e começam automaticamente quando os requisitos são atendidos.',
    'ミニ冒険は数分、ショート冒険は数時間、ロング冒険は数日かかります。ドラゴンの対応する専門技能で時間が短縮されます。グループ冒険にはログイン中のフレンドが2～4人必要で、条件を満たすと自動で始まります。'
  ],
  'Trials': ['Prüfungen', 'Pruebas', 'Épreuves', 'Prove', 'Provas', '試練'],
  'Trials are skill-based minigames and refill every 15 minutes, up to three waiting. Cavern Flight trains Spirit, Ruin Breaker trains Might and Runeweaver trains Arcana; your performance sets the rank, rewards and personal high score.':
      [
    'Prüfungen sind geschicklichkeitsbasierte Minispiele und werden alle 15 Minuten bis zu maximal drei ergänzt. Höhlenflug trainiert Geist, Ruinenbrecher Stärke und Runenweber Arkana; deine Leistung bestimmt Rang, Belohnungen und persönlichen Rekord.',
    'Las Pruebas son minijuegos de habilidad y se reponen cada 15 minutos, hasta un máximo de tres. Vuelo cavernario entrena Espíritu, Romperruinas Poder y Tejerrunas Arcana; tu rendimiento determina el rango, las recompensas y el récord personal.',
    'Les Épreuves sont des mini-jeux d’adresse renouvelés toutes les 15 minutes, jusqu’à trois en attente. Vol cavernicole entraîne l’Esprit, Briseur de ruines la Puissance et Tisseur de runes les Arcanes ; ta performance détermine le rang, les récompenses et le record personnel.',
    'Le Prove sono minigiochi di abilità e si ricaricano ogni 15 minuti, fino a un massimo di tre. Volo nella caverna allena lo Spirito, Spezzarovine la Potenza e Tessirune l’Arcano; la prestazione determina grado, ricompense e record personale.',
    'As Provas são minijogos de habilidade e são renovadas a cada 15 minutos, até três disponíveis. Voo na caverna treina Espírito, Quebra-ruínas Poder e Tecelão de runas Arcano; seu desempenho determina classificação, recompensas e recorde pessoal.',
    '試練は腕前を試すミニゲームで、15分ごとに最大3つまで補充されます。洞窟飛行は精神、ルインブレイカーは力、ルーンウィーバーは神秘を鍛え、成績によってランク、報酬、自己ベストが決まります。'
  ],
  'Use the two large sprites at the top right: My Dragons opens your complete dragon collection, while the Draconomicon shows every discovered dragon form. Below them you can build, visit and decorate Tower floors.':
      [
    'Nutze die beiden großen Symbole oben rechts: Meine Drachen öffnet deine vollständige Drachensammlung, während das Draconomicon jede entdeckte Drachenform zeigt. Darunter kannst du Turmgeschosse bauen, besuchen und dekorieren.',
    'Usa los dos iconos grandes de arriba a la derecha: Mis dragones abre tu colección completa y el Draconomicon muestra cada forma de dragón descubierta. Debajo puedes construir, visitar y decorar pisos de la Torre.',
    'Utilise les deux grandes icônes en haut à droite : Mes dragons ouvre ta collection complète, tandis que le Draconomicon montre chaque forme de dragon découverte. En dessous, tu peux construire, visiter et décorer les étages de la Tour.',
    'Usa le due grandi icone in alto a destra: I miei draghi apre la collezione completa, mentre il Draconomicon mostra ogni forma di drago scoperta. Sotto puoi costruire, visitare e decorare i piani della Torre.',
    'Use os dois ícones grandes no canto superior direito: Meus dragões abre sua coleção completa, enquanto o Draconomicon mostra cada forma de dragão descoberta. Abaixo deles você pode construir, visitar e decorar andares da Torre.',
    '右上の2つの大きなアイコンを使います。「マイドラゴン」では全ドラゴンを確認でき、ドラコノミコンには発見済みのドラゴン形態が表示されます。その下では塔の階を建築、訪問、装飾できます。'
  ],
  'Eggs, unopened chests, furniture and Relics are stored here. Open chests, start an egg incubation or inspect what you own; items reserved for a Trade cannot be used until released.':
      [
    'Hier werden Eier, ungeöffnete Truhen, Möbel und Relikte aufbewahrt. Öffne Truhen, beginne die Brut eines Eis oder prüfe deinen Besitz; für einen Tausch reservierte Gegenstände bleiben bis zur Freigabe unbenutzbar.',
    'Aquí se guardan huevos, cofres sin abrir, muebles y Reliquias. Abre cofres, inicia la incubación de un huevo o revisa lo que tienes; los objetos reservados para un intercambio no pueden usarse hasta quedar libres.',
    'Tes œufs, coffres non ouverts, meubles et Reliques sont conservés ici. Ouvre des coffres, lance l’incubation d’un œuf ou consulte tes possessions ; les objets réservés pour un échange restent inutilisables jusqu’à leur libération.',
    'Qui vengono conservati uova, scrigni non aperti, mobili e Reliquie. Apri gli scrigni, avvia l’incubazione di un uovo o controlla ciò che possiedi; gli oggetti riservati per uno scambio non possono essere usati finché non vengono liberati.',
    'Ovos, baús fechados, móveis e Relíquias ficam guardados aqui. Abra baús, inicie a incubação de um ovo ou confira o que possui; itens reservados para uma troca não podem ser usados até serem liberados.',
    '卵、未開封の宝箱、家具、レリックはここに保管されます。宝箱を開けたり、卵の孵化を始めたり、所持品を確認できます。交換用に確保されたアイテムは解放されるまで使えません。'
  ],
  'Buy furniture for your Tower with coins or gems. Title Chests cost coins and unlock account titles; Portrait Chests cost gems and unlock profile portraits. Open both from Inventory.':
      [
    'Kaufe mit Münzen oder Edelsteinen Möbel für deinen Turm. Titeltruhen kosten Münzen und schalten Kontotitel frei; Porträttruhen kosten Edelsteine und schalten Profilporträts frei. Beide öffnest du im Inventar.',
    'Compra muebles para tu Torre con monedas o gemas. Los Cofres de títulos cuestan monedas y desbloquean títulos de cuenta; los Cofres de retratos cuestan gemas y desbloquean retratos de perfil. Abre ambos desde el Inventario.',
    'Achète des meubles pour ta Tour avec des pièces ou des gemmes. Les Coffres de titres coûtent des pièces et débloquent des titres de compte ; les Coffres de portraits coûtent des gemmes et débloquent des portraits de profil. Ouvre-les depuis l’Inventaire.',
    'Acquista mobili per la Torre con monete o gemme. Gli Scrigni dei titoli costano monete e sbloccano titoli dell’account; gli Scrigni dei ritratti costano gemme e sbloccano ritratti del profilo. Aprili dall’Inventario.',
    'Compre móveis para a Torre com moedas ou gemas. Baús de títulos custam moedas e desbloqueiam títulos da conta; Baús de retratos custam gemas e desbloqueiam retratos de perfil. Abra ambos no Inventário.',
    'コインやジェムで塔の家具を購入できます。称号の宝箱はコインでアカウント称号を、ポートレートの宝箱はジェムでプロフィール画像を解放します。どちらもインベントリから開けます。'
  ],
  'The three-dot menu': [
    'Das Dreipunkt-Menü',
    'El menú de tres puntos',
    'Le menu à trois points',
    'Il menu con tre puntini',
    'O menu de três pontos',
    '3点メニュー'
  ],
  'Tap the three dots at the top right for Account info, where you can change your portrait and title and manage Notifications and Audio. The same menu opens Language, Achievements and this Tutorial again.':
      [
    'Tippe oben rechts auf die drei Punkte, um die Kontoinformationen zu öffnen. Dort kannst du Porträt und Titel ändern sowie Benachrichtigungen und Audio verwalten. Dasselbe Menü öffnet Sprache, Erfolge und erneut dieses Tutorial.',
    'Toca los tres puntos de arriba a la derecha para abrir la información de la cuenta, donde puedes cambiar el retrato y el título y gestionar Notificaciones y Audio. El mismo menú abre Idioma, Logros y este Tutorial de nuevo.',
    'Touche les trois points en haut à droite pour ouvrir les informations du compte, où tu peux modifier portrait et titre et gérer Notifications et Audio. Le même menu ouvre aussi Langue, Succès et ce Tutoriel.',
    'Tocca i tre puntini in alto a destra per aprire le informazioni dell’account, dove puoi cambiare ritratto e titolo e gestire Notifiche e Audio. Lo stesso menu apre Lingua, Obiettivi e di nuovo questo Tutorial.',
    'Toque nos três pontos no canto superior direito para abrir as informações da conta, onde você pode mudar retrato e título e gerenciar Notificações e Áudio. O mesmo menu abre Idioma, Conquistas e este Tutorial novamente.',
    '右上の3点をタップするとアカウント情報が開き、ポートレートと称号の変更、通知とオーディオの管理ができます。同じメニューから言語、実績、このチュートリアルも開けます。'
  ],
  'This is the future meeting place for linked Dragonkeepers, visits and fair trades.':
      [
    'Dies wird der Treffpunkt für verbundene Drachenhüter, Besuche und faire Tauschgeschäfte.',
    'Este será el punto de encuentro para Guardianes de Dragones conectados, visitas e intercambios justos.',
    'Ce sera le lieu de rencontre des Gardiens de dragons liés, des visites et des échanges équitables.',
    'Questo sarà il punto d’incontro per Custodi di draghi collegati, visite e scambi equi.',
    'Este será o ponto de encontro para Guardiões de Dragões conectados, visitas e trocas justas.',
    'ここは連携したドラゴンキーパーとの訪問や公正な交換の場になります。'
  ],
  'Send an available dragon on an Adventure to earn XP, Expertises and treasure chests.':
      [
    'Schicke einen verfügbaren Drachen auf ein Abenteuer, um XP, Expertisen und Schatztruhen zu verdienen.',
    'Envía un dragón disponible a una Aventura para ganar XP, Pericias y cofres del tesoro.',
    'Envoie un dragon disponible en Aventure pour gagner de l’XP, des Expertises et des coffres au trésor.',
    'Invia un drago disponibile in un’Avventura per ottenere XP, Competenze e scrigni.',
    'Envie um dragão disponível em uma Aventura para ganhar XP, Especialidades e baús do tesouro.',
    '空いているドラゴンを冒険に送り、XP、専門技能、宝箱を獲得しましょう。'
  ],
  'Build unique rooms, decorate them and choose which dragons may roam through their home.':
      [
    'Baue einzigartige Räume, dekoriere sie und wähle, welche Drachen durch ihr Zuhause streifen dürfen.',
    'Construye habitaciones únicas, decóralas y elige qué dragones pueden recorrer su hogar.',
    'Construis des pièces uniques, décore-les et choisis quels dragons peuvent parcourir leur foyer.',
    'Costruisci stanze uniche, decorale e scegli quali draghi possono girare nella loro casa.',
    'Construa cômodos únicos, decore-os e escolha quais dragões podem passear pelo lar.',
    '個性的な部屋を建てて飾り、家の中を歩き回れるドラゴンを選びましょう。'
  ],
  'Your eggs, unopened chests, furniture and consumable Relics are safely stored here.':
      [
    'Deine Eier, ungeöffneten Truhen, Möbel und verbrauchbaren Relikte werden hier sicher aufbewahrt.',
    'Aquí se guardan de forma segura tus huevos, cofres sin abrir, muebles y Reliquias consumibles.',
    'Tes œufs, coffres non ouverts, meubles et Reliques consommables sont conservés ici.',
    'Qui sono custoditi uova, scrigni non aperti, mobili e Reliquie consumabili.',
    'Seus ovos, baús fechados, móveis e Relíquias consumíveis ficam guardados aqui.',
    '卵、未開封の宝箱、家具、消費型のレリックはここに安全に保管されます。'
  ],
  'Spend coins or gems on furniture that makes every Tower room feel like home.':
      [
    'Gib Münzen oder Edelsteine für Möbel aus, die jeden Turmraum wohnlich machen.',
    'Gasta monedas o gemas en muebles que hagan acogedora cada sala de la Torre.',
    'Dépense des pièces ou des gemmes en meubles pour rendre chaque pièce de la Tour accueillante.',
    'Spendi monete o gemme in mobili che rendano accogliente ogni stanza della Torre.',
    'Gaste moedas ou gemas em móveis que deixem cada cômodo da Torre aconchegante.',
    'コインやジェムで家具を買い、塔のどの部屋も居心地のよい家にしましょう。'
  ],
  'Skip tutorial': [
    'Tutorial überspringen',
    'Omitir tutorial',
    'Passer le tutoriel',
    'Salta tutorial',
    'Pular tutorial',
    'チュートリアルをスキップ'
  ],
  'Next': ['Weiter', 'Siguiente', 'Suivant', 'Avanti', 'Próximo', '次へ'],
  'Nothing left to reveal': [
    'Nichts mehr zu enthüllen',
    'No queda nada por revelar',
    'Plus rien à révéler',
    'Non resta nulla da rivelare',
    'Não há mais nada para revelar',
    '明かせる秘密はありません'
  ],
  'This Relic has already revealed its secret for every dragon you own. Hatch or collect another dragon to use it.':
      [
    'Dieses Relikt hat sein Geheimnis bereits für jeden deiner Drachen enthüllt. Brüte einen weiteren Drachen aus oder sammle ihn, um es zu verwenden.',
    'Esta Reliquia ya reveló su secreto para todos tus dragones. Incuba o consigue otro dragón para usarla.',
    'Cette Relique a déjà révélé son secret pour chacun de tes dragons. Fais éclore ou collectionne un autre dragon pour l’utiliser.',
    'Questa Reliquia ha già rivelato il suo segreto per ogni drago che possiedi. Fai schiudere o raccogli un altro drago per usarla.',
    'Esta Relíquia já revelou seu segredo para todos os seus dragões. Choque ou consiga outro dragão para usá-la.',
    'このレリックは所有する全ドラゴンの秘密をすでに明かしています。別のドラゴンを孵化または収集すると使えます。'
  ],
  'Understood': [
    'Verstanden',
    'Entendido',
    'Compris',
    'Capito',
    'Entendido',
    '了解'
  ],
  'Expertises required': [
    'Benötigte Expertisen',
    'Pericias necesarias',
    'Expertises requises',
    'Competenze richieste',
    'Especialidades necessárias',
    '必要な専門技能'
  ],
  'Ascension requirements': [
    'Ascension-Voraussetzungen',
    'Requisitos de Ascensión',
    'Conditions d’Ascension',
    'Requisiti per l’Ascensione',
    'Requisitos de Ascensão',
    'アセンションの条件'
  ],
  'Complete both requirements before Ascension.': [
    'Erfülle vor der Ascension beide Voraussetzungen.',
    'Completa ambos requisitos antes de la Ascensión.',
    'Remplissez les deux conditions avant l’Ascension.',
    'Completa entrambi i requisiti prima dell’Ascensione.',
    'Cumpra os dois requisitos antes da Ascensão.',
    'アセンションの前に両方の条件を達成しましょう。'
  ],
  'Level & XP': [
    'Level & EP',
    'Nivel y XP',
    'Niveau et XP',
    'Livello ed XP',
    'Nível e XP',
    'レベル & XP'
  ],
  'Minimum total Expertise': [
    'Erforderliche Gesamtexpertise',
    'Pericia total mínima',
    'Expertise totale minimale',
    'Competenza totale minima',
    'Especialidade total mínima',
    '必要な合計専門技能'
  ],
  'Skip evolution animation': [
    'Evolutionsanimation überspringen',
    'Omitir animación de evolución',
    'Passer l’animation d’évolution',
    'Salta animazione evoluzione',
    'Pular animação de evolução',
    '進化アニメーションをスキップ'
  ],
  'Portraits': [
    'Porträts',
    'Retratos',
    'Portraits',
    'Ritratti',
    'Retratos',
    'ポートレート'
  ],
  'Account portrait': [
    'Kontoporträt',
    'Retrato de cuenta',
    'Portrait du compte',
    'Ritratto account',
    'Retrato da conta',
    'アカウントポートレート'
  ],
  'No portraits collected yet': [
    'Noch keine Porträts gesammelt',
    'Aún no has conseguido retratos',
    'Aucun portrait collectionné',
    'Nessun ritratto raccolto',
    'Nenhum retrato coletado',
    'ポートレートはまだありません'
  ],
  'Portrait Chests cost 99 gems in the Shop and always reveal a portrait you do not own yet.':
      [
    'Porträttruhen kosten im Shop 99 Edelsteine und enthüllen immer ein Porträt, das du noch nicht besitzt.',
    'Los cofres de retrato cuestan 99 gemas en la tienda y siempre revelan un retrato que aún no tienes.',
    'Les coffres de portrait coûtent 99 gemmes dans la boutique et révèlent toujours un portrait inédit.',
    'I forzieri ritratto costano 99 gemme nel negozio e rivelano sempre un ritratto che non possiedi.',
    'Baús de retrato custam 99 gemas na Loja e sempre revelam um retrato que você ainda não possui.',
    'ポートレートチェストはショップで99ジェム。未所持のポートレートが必ず出ます。'
  ],
  'Choose account portrait': [
    'Kontoporträt wählen',
    'Elegir retrato de cuenta',
    'Choisir le portrait du compte',
    'Scegli ritratto account',
    'Escolher retrato da conta',
    'アカウントポートレートを選択'
  ],
  'Coins': ['Münzen', 'Monedas', 'Pièces', 'Monete', 'Moedas', 'コイン'],
  'Gems': ['Edelsteine', 'Gemas', 'Gemmes', 'Gemme', 'Gemas', 'ジェム'],
  'Buy': ['Kaufen', 'Comprar', 'Acheter', 'Acquista', 'Comprar', '購入'],
  'No coin chests yet': [
    'Noch keine Münztruhen',
    'Aún no hay cofres de monedas',
    'Pas encore de coffres à pièces',
    'Nessun forziere monete per ora',
    'Ainda não há baús de moedas',
    'コイン用チェストはまだありません'
  ],
  'Special chests may be added here in a future update.': [
    'In einem zukünftigen Update können hier besondere Truhen erscheinen.',
    'En una futura actualización podrán aparecer cofres especiales aquí.',
    'Des coffres spéciaux pourront être ajoutés ici ultérieurement.',
    'In futuro potranno essere aggiunti forzieri speciali qui.',
    'Baús especiais poderão ser adicionados aqui futuramente.',
    '今後のアップデートで特別なチェストが追加される予定です。'
  ],
  'Contains one random portrait you do not own. Its contents are decided only when opened.':
      [
    'Enthält ein zufälliges Porträt, das du noch nicht besitzt. Der Inhalt wird erst beim Öffnen bestimmt.',
    'Contiene un retrato aleatorio que no tienes. El contenido se decide al abrirlo.',
    'Contient un portrait aléatoire inédit. Son contenu est déterminé à l’ouverture.',
    'Contiene un ritratto casuale che non possiedi. Il contenuto viene deciso solo all’apertura.',
    'Contém um retrato aleatório que você ainda não possui. O conteúdo só é decidido ao abrir.',
    '未所持のポートレートが1つ入っています。中身は開封時に決まります。'
  ],
  'Collection complete': [
    'Sammlung vollständig',
    'Colección completa',
    'Collection complète',
    'Collezione completa',
    'Coleção completa',
    'コレクション完成'
  ],
  'Portrait Chest added to your Inventory.': [
    'Porträttruhe zum Inventar hinzugefügt.',
    'Cofre de retrato añadido al Inventario.',
    'Coffre de portrait ajouté à l’Inventaire.',
    'Forziere ritratto aggiunto all’Inventario.',
    'Baú de retrato adicionado ao Inventário.',
    'ポートレートチェストをインベントリに追加しました。'
  ],
  'You already own all 100 portraits.': [
    'Du besitzt bereits alle 100 Porträts.',
    'Ya tienes los 100 retratos.',
    'Tu possèdes déjà les 100 portraits.',
    'Possiedi già tutti e 100 i ritratti.',
    'Você já possui todos os 100 retratos.',
    '100種類すべてのポートレートを所持しています。'
  ],
  'You already own all 100 portraits, so another Portrait Chest cannot be purchased.':
      [
    'Du besitzt bereits alle 100 Porträts, daher kann keine weitere Porträttruhe gekauft werden.',
    'Ya tienes los 100 retratos, así que no puedes comprar otro cofre de retrato.',
    'Tu possèdes déjà les 100 portraits, il est donc impossible d’acheter un autre coffre de portrait.',
    'Possiedi già tutti e 100 i ritratti, quindi non puoi acquistare un altro forziere ritratto.',
    'Você já possui todos os 100 retratos, então não pode comprar outro baú de retrato.',
    '100種類すべてを所持しているため、追加のポートレートチェストは購入できません。'
  ],
  'Portrait revealed': [
    'Porträt enthüllt',
    'Retrato revelado',
    'Portrait révélé',
    'Ritratto rivelato',
    'Retrato revelado',
    'ポートレート出現'
  ],
  'Added to your portrait collection': [
    'Deiner Porträtsammlung hinzugefügt',
    'Añadido a tu colección de retratos',
    'Ajouté à ta collection de portraits',
    'Aggiunto alla tua collezione di ritratti',
    'Adicionado à sua coleção de retratos',
    'ポートレートコレクションに追加しました'
  ],
  'Portrait collection complete': [
    'Porträtsammlung vollständig',
    'Colección de retratos completa',
    'Collection de portraits complète',
    'Collezione ritratti completa',
    'Coleção de retratos completa',
    'ポートレートコレクション完成'
  ],
  'You already own all 100 portraits. This Portrait Chest stays safely in your Inventory and cannot be opened.':
      [
    'Du besitzt bereits alle 100 Porträts. Diese Porträttruhe bleibt sicher im Inventar und kann nicht geöffnet werden.',
    'Ya tienes los 100 retratos. Este cofre permanece a salvo en tu Inventario y no puede abrirse.',
    'Tu possèdes déjà les 100 portraits. Ce coffre reste dans ton Inventaire et ne peut pas être ouvert.',
    'Possiedi già tutti e 100 i ritratti. Il forziere rimane al sicuro nell’Inventario e non può essere aperto.',
    'Você já possui todos os 100 retratos. Este baú fica seguro no Inventário e não pode ser aberto.',
    '100種類すべてを所持しているため、このチェストはインベントリに残り、開封できません。'
  ],
  'Portrait Chest': [
    'Porträttruhe',
    'Cofre de retrato',
    'Coffre de portrait',
    'Forziere ritratto',
    'Baú de retrato',
    'ポートレートチェスト'
  ],
  'Infernal': [
    'Infernalisch',
    'Infernal',
    'Infernal',
    'Infernale',
    'Infernal',
    'インファーナル'
  ],
  'A Portrait Chest is waiting in your Inventory.': [
    'Eine Porträttruhe wartet in deinem Inventar.',
    'Hay un cofre de retrato esperando en tu Inventario.',
    'Un coffre de portrait t’attend dans ton Inventaire.',
    'Un forziere ritratto ti aspetta nell’Inventario.',
    'Um baú de retrato está esperando no seu Inventário.',
    'ポートレートチェストがインベントリで待っています。'
  ],
  'A new account portrait joined your collection.': [
    'Ein neues Kontoporträt wurde deiner Sammlung hinzugefügt.',
    'Un nuevo retrato de cuenta se unió a tu colección.',
    'Un nouveau portrait de compte a rejoint ta collection.',
    'Un nuovo ritratto account si è aggiunto alla collezione.',
    'Um novo retrato de conta entrou na sua coleção.',
    '新しいアカウントポートレートがコレクションに加わりました。'
  ],
  'Titles': ['Titel', 'Títulos', 'Titres', 'Titoli', 'Títulos', '称号'],
  'Choose account title': [
    'Kontotitel wählen',
    'Elegir título de cuenta',
    'Choisir le titre du compte',
    'Scegli il titolo dell’account',
    'Escolher título da conta',
    'アカウント称号を選択'
  ],
  'Title Chest': [
    'Titeltruhe',
    'Cofre de títulos',
    'Coffre de titres',
    'Forziere dei titoli',
    'Baú de títulos',
    '称号チェスト'
  ],
  'Contains one random account title you do not own. Its contents are decided only when opened.':
      [
    'Enthält einen zufälligen Kontotitel, den du noch nicht besitzt. Der Inhalt wird erst beim Öffnen bestimmt.',
    'Contiene un título de cuenta aleatorio que aún no tienes. El contenido se decide al abrirlo.',
    'Contient un titre de compte aléatoire que tu ne possèdes pas. Son contenu est déterminé à l’ouverture.',
    'Contiene un titolo account casuale che non possiedi. Il contenuto viene deciso solo all’apertura.',
    'Contém um título de conta aleatório que você ainda não possui. O conteúdo é definido apenas ao abrir.',
    '未所持のアカウント称号が1つランダムで入っています。内容は開封時に決まります。'
  ],
  'Title Chest added to your Inventory.': [
    'Titeltruhe deinem Inventar hinzugefügt.',
    'Cofre de títulos añadido a tu Inventario.',
    'Coffre de titres ajouté à ton Inventaire.',
    'Forziere dei titoli aggiunto all’Inventario.',
    'Baú de títulos adicionado ao Inventário.',
    '称号チェストをインベントリに追加しました。'
  ],
  'You already own all 500 account titles, so another Title Chest cannot be purchased.':
      [
    'Du besitzt bereits alle 500 Kontotitel, daher kann keine weitere Titeltruhe gekauft werden.',
    'Ya tienes los 500 títulos de cuenta, así que no puedes comprar otro cofre de títulos.',
    'Tu possèdes déjà les 500 titres de compte, il est donc impossible d’acheter un autre coffre de titres.',
    'Possiedi già tutti i 500 titoli account, quindi non puoi acquistare un altro forziere dei titoli.',
    'Você já possui todos os 500 títulos de conta, então não pode comprar outro baú de títulos.',
    '500種類すべてのアカウント称号を所持しているため、追加の称号チェストは購入できません。'
  ],
  'Title revealed': [
    'Titel enthüllt',
    'Título revelado',
    'Titre révélé',
    'Titolo rivelato',
    'Título revelado',
    '称号出現'
  ],
  'Added to your title collection': [
    'Deiner Titelsammlung hinzugefügt',
    'Añadido a tu colección de títulos',
    'Ajouté à ta collection de titres',
    'Aggiunto alla tua collezione di titoli',
    'Adicionado à sua coleção de títulos',
    '称号コレクションに追加しました'
  ],
  'Title collection complete': [
    'Titelsammlung vollständig',
    'Colección de títulos completa',
    'Collection de titres complète',
    'Collezione titoli completa',
    'Coleção de títulos completa',
    '称号コレクション完成'
  ],
  'You already own all 500 account titles. This Title Chest stays safely in your Inventory and cannot be opened.':
      [
    'Du besitzt bereits alle 500 Kontotitel. Diese Titeltruhe bleibt sicher im Inventar und kann nicht geöffnet werden.',
    'Ya tienes los 500 títulos de cuenta. Este cofre permanece a salvo en tu Inventario y no puede abrirse.',
    'Tu possèdes déjà les 500 titres de compte. Ce coffre reste dans ton Inventaire et ne peut pas être ouvert.',
    'Possiedi già tutti i 500 titoli account. Il forziere rimane al sicuro nell’Inventario e non può essere aperto.',
    'Você já possui todos os 500 títulos de conta. Este baú fica seguro no Inventário e não pode ser aberto.',
    '500種類すべてのアカウント称号を所持しているため、このチェストはインベントリに残り、開封できません。'
  ],
  'A Title Chest is waiting in your Inventory.': [
    'Eine Titeltruhe wartet in deinem Inventar.',
    'Hay un cofre de títulos esperando en tu Inventario.',
    'Un coffre de titres t’attend dans ton Inventaire.',
    'Un forziere dei titoli ti aspetta nell’Inventario.',
    'Um baú de títulos está esperando no seu Inventário.',
    '称号チェストがインベントリで待っています。'
  ],
  'A request is already pending.': [
    'Eine Anfrage steht bereits aus.',
    'Ya hay una solicitud pendiente.',
    'Une demande est déjà en attente.',
    'Una richiesta è già in attesa.',
    'Já existe uma solicitação pendente.',
    'すでに保留中の申請があります。'
  ],
  'Accept': ['Akzeptieren', 'Aceptar', 'Accepter', 'Accetta', 'Aceitar', '承認'],
  'Add by Keeper ID': [
    'Per Hüter-ID hinzufügen',
    'Añadir por ID de Guardián',
    'Ajouter par ID de Gardien',
    'Aggiungi tramite ID Custode',
    'Adicionar por ID de Guardião',
    'キーパーIDで追加'
  ],
  'An account already exists for this email.': [
    'Für diese E-Mail-Adresse existiert bereits ein Konto.',
    'Ya existe una cuenta para este correo electrónico.',
    'Un compte existe déjà pour cette adresse e-mail.',
    'Esiste già un account per questa e-mail.',
    'Já existe uma conta para este e-mail.',
    'このメールアドレスのアカウントはすでに存在します。'
  ],
  'Block': ['Blockieren', 'Bloquear', 'Bloquer', 'Blocca', 'Bloquear', 'ブロック'],
  'Block keeper': [
    'Hüter blockieren',
    'Bloquear Guardián',
    'Bloquer le Gardien',
    'Blocca Custode',
    'Bloquear Guardião',
    'キーパーをブロック'
  ],
  'Blocked': [
    'Blockiert',
    'Bloqueados',
    'Bloqués',
    'Bloccati',
    'Bloqueados',
    'ブロック中'
  ],
  'Check your email to confirm the account, then sign in.': [
    'Bestätige das Konto über deine E-Mail und melde dich danach an.',
    'Revisa tu correo para confirmar la cuenta y luego inicia sesión.',
    'Consulte ton e-mail pour confirmer le compte, puis connecte-toi.',
    'Controlla l’e-mail per confermare l’account, poi accedi.',
    'Verifique seu e-mail para confirmar a conta e depois entre.',
    'メールでアカウントを確認してからログインしてください。'
  ],
  'Connect your keeper': [
    'Verbinde deinen Hüter',
    'Conecta a tu Guardián',
    'Connecte ton Gardien',
    'Collega il tuo Custode',
    'Conecte seu Guardião',
    'キーパーを接続'
  ],
  'Copy Keeper ID': [
    'Hüter-ID kopieren',
    'Copiar ID de Guardián',
    'Copier l’ID de Gardien',
    'Copia ID Custode',
    'Copiar ID de Guardião',
    'キーパーIDをコピー'
  ],
  'Create': ['Erstellen', 'Crear', 'Créer', 'Crea', 'Criar', '作成'],
  'Create a simple account to add friends by Keeper ID. Your email is never shown to other players.':
      [
    'Erstelle ein einfaches Konto, um Freunde per Hüter-ID hinzuzufügen. Deine E-Mail wird anderen Spielern nie angezeigt.',
    'Crea una cuenta sencilla para añadir amigos por ID de Guardián. Tu correo nunca se muestra a otros jugadores.',
    'Crée un compte simple pour ajouter des amis par ID de Gardien. Ton e-mail n’est jamais montré aux autres joueurs.',
    'Crea un account semplice per aggiungere amici tramite ID Custode. La tua e-mail non viene mai mostrata agli altri giocatori.',
    'Crie uma conta simples para adicionar amigos pelo ID de Guardião. Seu e-mail nunca é exibido a outros jogadores.',
    'シンプルなアカウントを作成すると、キーパーIDでフレンドを追加できます。メールアドレスが他のプレイヤーに表示されることはありません。'
  ],
  'Create account': [
    'Konto erstellen',
    'Crear cuenta',
    'Créer un compte',
    'Crea account',
    'Criar conta',
    'アカウントを作成'
  ],
  'Create online account': [
    'Online-Konto erstellen',
    'Crear cuenta en línea',
    'Créer un compte en ligne',
    'Crea account online',
    'Criar conta online',
    'オンラインアカウントを作成'
  ],
  'Discovered': [
    'Entdeckt',
    'Descubiertos',
    'Découverts',
    'Scoperti',
    'Descobertos',
    '発見済み'
  ],
  'Discovered dragons': [
    'Entdeckte Drachen',
    'Dragones descubiertos',
    'Dragons découverts',
    'Draghi scoperti',
    'Dragões descobertos',
    '発見したドラゴン'
  ],
  'Edit online profile': [
    'Online-Profil bearbeiten',
    'Editar perfil en línea',
    'Modifier le profil en ligne',
    'Modifica profilo online',
    'Editar perfil online',
    'オンラインプロフィールを編集'
  ],
  'Edit profile': [
    'Profil bearbeiten',
    'Editar perfil',
    'Modifier le profil',
    'Modifica profilo',
    'Editar perfil',
    'プロフィールを編集'
  ],
  'Enter a name.': [
    'Gib einen Namen ein.',
    'Introduce un nombre.',
    'Saisis un nom.',
    'Inserisci un nome.',
    'Digite um nome.',
    '名前を入力してください。'
  ],
  'Enter a valid email.': [
    'Gib eine gültige E-Mail-Adresse ein.',
    'Introduce un correo electrónico válido.',
    'Saisis une adresse e-mail valide.',
    'Inserisci un indirizzo e-mail valido.',
    'Digite um e-mail válido.',
    '有効なメールアドレスを入力してください。'
  ],
  'Favorite dragon': [
    'Lieblingsdrache',
    'Dragón favorito',
    'Dragon favori',
    'Drago preferito',
    'Dragão favorito',
    'お気に入りのドラゴン'
  ],
  'Find trusted keepers, compare collections and visit their profiles.': [
    'Finde vertrauenswürdige Hüter, vergleiche Sammlungen und besuche ihre Profile.',
    'Encuentra Guardianes de confianza, compara colecciones y visita sus perfiles.',
    'Trouve des Gardiens de confiance, compare les collections et consulte leurs profils.',
    'Trova Custodi fidati, confronta le collezioni e visita i loro profili.',
    'Encontre Guardiões confiáveis, compare coleções e visite seus perfis.',
    '信頼できるキーパーを見つけ、コレクションを比べてプロフィールを訪問しましょう。'
  ],
  'Friend removed for both keepers.': [
    'Die Freundschaft wurde für beide Hüter entfernt.',
    'La amistad se eliminó para ambos Guardianes.',
    'L’amitié a été supprimée pour les deux Gardiens.',
    'L’amicizia è stata rimossa per entrambi i Custodi.',
    'A amizade foi removida para ambos os Guardiões.',
    '両方のキーパーのフレンド関係を削除しました。'
  ],
  'Friend request sent.': [
    'Freundschaftsanfrage gesendet.',
    'Solicitud de amistad enviada.',
    'Demande d’amitié envoyée.',
    'Richiesta di amicizia inviata.',
    'Solicitação de amizade enviada.',
    'フレンド申請を送信しました。'
  ],
  'Friend requests': [
    'Freundschaftsanfragen',
    'Solicitudes de amistad',
    'Demandes d’amitié',
    'Richieste di amicizia',
    'Solicitações de amizade',
    'フレンド申請'
  ],
  'Incorrect email or password.': [
    'E-Mail oder Passwort ist falsch.',
    'Correo o contraseña incorrectos.',
    'E-mail ou mot de passe incorrect.',
    'E-mail o password errati.',
    'E-mail ou senha incorretos.',
    'メールアドレスまたはパスワードが正しくありません。'
  ],
  'Keeper blocked.': [
    'Hüter blockiert.',
    'Guardián bloqueado.',
    'Gardien bloqué.',
    'Custode bloccato.',
    'Guardião bloqueado.',
    'キーパーをブロックしました。'
  ],
  'Keeper ID copied.': [
    'Hüter-ID kopiert.',
    'ID de Guardián copiado.',
    'ID de Gardien copié.',
    'ID Custode copiato.',
    'ID de Guardião copiado.',
    'キーパーIDをコピーしました。'
  ],
  'Keeper name': [
    'Hütername',
    'Nombre del Guardián',
    'Nom du Gardien',
    'Nome Custode',
    'Nome do Guardião',
    'キーパー名'
  ],
  'Keeper unblocked.': [
    'Hüter entsperrt.',
    'Guardián desbloqueado.',
    'Gardien débloqué.',
    'Custode sbloccato.',
    'Guardião desbloqueado.',
    'キーパーのブロックを解除しました。'
  ],
  'No favorite dragon selected.': [
    'Kein Lieblingsdrache ausgewählt.',
    'No se ha elegido un dragón favorito.',
    'Aucun dragon favori sélectionné.',
    'Nessun drago preferito selezionato.',
    'Nenhum dragão favorito selecionado.',
    'お気に入りのドラゴンが選ばれていません。'
  ],
  'No friends yet. Share your Keeper ID or add someone else.': [
    'Noch keine Freunde. Teile deine Hüter-ID oder füge jemanden hinzu.',
    'Aún no tienes amigos. Comparte tu ID de Guardián o añade a alguien.',
    'Pas encore d’amis. Partage ton ID de Gardien ou ajoute quelqu’un.',
    'Ancora nessun amico. Condividi il tuo ID Custode o aggiungi qualcuno.',
    'Ainda não há amigos. Compartilhe seu ID de Guardião ou adicione alguém.',
    'まだフレンドはいません。キーパーIDを共有するか、誰かを追加しましょう。'
  ],
  'No keeper with that ID was found.': [
    'Kein Hüter mit dieser ID wurde gefunden.',
    'No se encontró ningún Guardián con ese ID.',
    'Aucun Gardien avec cet ID n’a été trouvé.',
    'Nessun Custode trovato con questo ID.',
    'Nenhum Guardião com esse ID foi encontrado.',
    'そのIDのキーパーは見つかりませんでした。'
  ],
  'Online account': [
    'Online-Konto',
    'Cuenta en línea',
    'Compte en ligne',
    'Account online',
    'Conta online',
    'オンラインアカウント'
  ],
  'Online accounts are ready in this build, but this installation still needs its server URL and publishable key.':
      [
    'Online-Konten sind in diesem Build bereit, aber dieser Installation fehlen noch Server-URL und öffentlicher Schlüssel.',
    'Las cuentas en línea están listas, pero esta instalación aún necesita la URL del servidor y la clave pública.',
    'Les comptes en ligne sont prêts, mais cette installation nécessite encore l’URL du serveur et la clé publique.',
    'Gli account online sono pronti, ma questa installazione richiede ancora l’URL del server e la chiave pubblica.',
    'As contas online estão prontas, mas esta instalação ainda precisa da URL do servidor e da chave pública.',
    'オンラインアカウントには対応していますが、このインストールにはサーバーURLと公開キーが必要です。'
  ],
  'Password': [
    'Passwort',
    'Contraseña',
    'Mot de passe',
    'Password',
    'Senha',
    'パスワード'
  ],
  'Pending': [
    'Ausstehend',
    'Pendiente',
    'En attente',
    'In attesa',
    'Pendente',
    '保留中'
  ],
  'Profile saved.': [
    'Profil gespeichert.',
    'Perfil guardado.',
    'Profil enregistré.',
    'Profilo salvato.',
    'Perfil salvo.',
    'プロフィールを保存しました。'
  ],
  'Reject': ['Ablehnen', 'Rechazar', 'Refuser', 'Rifiuta', 'Recusar', '拒否'],
  'Remove friend': [
    'Freund entfernen',
    'Eliminar amigo',
    'Retirer l’ami',
    'Rimuovi amico',
    'Remover amigo',
    'フレンドを削除'
  ],
  'Remove friend?': [
    'Freund entfernen?',
    '¿Eliminar amigo?',
    'Retirer cet ami ?',
    'Rimuovere l’amico?',
    'Remover amigo?',
    'フレンドを削除しますか？'
  ],
  'Send request': [
    'Anfrage senden',
    'Enviar solicitud',
    'Envoyer la demande',
    'Invia richiesta',
    'Enviar solicitação',
    '申請を送信'
  ],
  'Sent requests': [
    'Gesendete Anfragen',
    'Solicitudes enviadas',
    'Demandes envoyées',
    'Richieste inviate',
    'Solicitações enviadas',
    '送信済み申請'
  ],
  'Server setup required': [
    'Server-Einrichtung erforderlich',
    'Configuración del servidor necesaria',
    'Configuration du serveur requise',
    'Configurazione server necessaria',
    'Configuração do servidor necessária',
    'サーバー設定が必要です'
  ],
  'Sign in': [
    'Anmelden',
    'Iniciar sesión',
    'Se connecter',
    'Accedi',
    'Entrar',
    'ログイン'
  ],
  'Sign out': [
    'Abmelden',
    'Cerrar sesión',
    'Se déconnecter',
    'Esci',
    'Sair',
    'ログアウト'
  ],
  'The online service could not complete this action. Please try again.': [
    'Der Onlinedienst konnte diese Aktion nicht abschließen. Versuche es erneut.',
    'El servicio en línea no pudo completar esta acción. Inténtalo de nuevo.',
    'Le service en ligne n’a pas pu terminer cette action. Réessaie.',
    'Il servizio online non ha potuto completare l’azione. Riprova.',
    'O serviço online não conseguiu concluir esta ação. Tente novamente.',
    'オンラインサービスでこの操作を完了できませんでした。もう一度お試しください。'
  ],
  'This installation has no online server configuration yet.': [
    'Diese Installation hat noch keine Online-Serverkonfiguration.',
    'Esta instalación aún no tiene configuración de servidor en línea.',
    'Cette installation n’a pas encore de configuration de serveur en ligne.',
    'Questa installazione non ha ancora una configurazione server online.',
    'Esta instalação ainda não possui configuração de servidor online.',
    'このインストールにはオンラインサーバー設定がありません。'
  ],
  'This keeper is unavailable.': [
    'Dieser Hüter ist nicht verfügbar.',
    'Este Guardián no está disponible.',
    'Ce Gardien est indisponible.',
    'Questo Custode non è disponibile.',
    'Este Guardião não está disponível.',
    'このキーパーは利用できません。'
  ],
  'This request was recently rejected. Try again later.': [
    'Diese Anfrage wurde kürzlich abgelehnt. Versuche es später erneut.',
    'Esta solicitud se rechazó recientemente. Inténtalo más tarde.',
    'Cette demande a été refusée récemment. Réessaie plus tard.',
    'Questa richiesta è stata rifiutata di recente. Riprova più tardi.',
    'Esta solicitação foi recusada recentemente. Tente novamente mais tarde.',
    'この申請は最近拒否されました。後でもう一度お試しください。'
  ],
  'Title': ['Titel', 'Título', 'Titre', 'Titolo', 'Título', '称号'],
  'Too many requests are pending.': [
    'Zu viele Anfragen stehen aus.',
    'Hay demasiadas solicitudes pendientes.',
    'Trop de demandes sont en attente.',
    'Ci sono troppe richieste in attesa.',
    'Há solicitações pendentes demais.',
    '保留中の申請が多すぎます。'
  ],
  'Unblock': [
    'Entsperren',
    'Desbloquear',
    'Débloquer',
    'Sblocca',
    'Desbloquear',
    'ブロック解除'
  ],
  'Use at least 8 characters.': [
    'Verwende mindestens 8 Zeichen.',
    'Usa al menos 8 caracteres.',
    'Utilise au moins 8 caractères.',
    'Usa almeno 8 caratteri.',
    'Use pelo menos 8 caracteres.',
    '8文字以上使用してください。'
  ],
  'You are already friends.': [
    'Ihr seid bereits Freunde.',
    'Ya sois amigos.',
    'Vous êtes déjà amis.',
    'Siete già amici.',
    'Vocês já são amigos.',
    'すでにフレンドです。'
  ],
  'You cannot add yourself.': [
    'Du kannst dich nicht selbst hinzufügen.',
    'No puedes añadirte a ti mismo.',
    'Tu ne peux pas t’ajouter toi-même.',
    'Non puoi aggiungere te stesso.',
    'Você não pode adicionar a si mesmo.',
    '自分自身を追加することはできません。'
  ],
  'Your online account is ready.': [
    'Dein Online-Konto ist bereit.',
    'Tu cuenta en línea está lista.',
    'Ton compte en ligne est prêt.',
    'Il tuo account online è pronto.',
    'Sua conta online está pronta.',
    'オンラインアカウントの準備ができました。'
  ],
  'A new account title joined your collection.': [
    'Ein neuer Kontotitel wurde deiner Sammlung hinzugefügt.',
    'Un nuevo título de cuenta se unió a tu colección.',
    'Un nouveau titre de compte a rejoint ta collection.',
    'Un nuovo titolo account si è aggiunto alla collezione.',
    'Um novo título de conta entrou na sua coleção.',
    '新しいアカウント称号がコレクションに加わりました。'
  ],
  'Cancel trade': [
    'Handel abbrechen',
    'Cancelar intercambio',
    'Annuler l’échange',
    'Annulla scambio',
    'Cancelar troca',
    '交換をキャンセル'
  ],
  'Chest': ['Truhe', 'Cofre', 'Coffre', 'Forziere', 'Baú', '宝箱'],
  'Choose my item': [
    'Meinen Gegenstand wählen',
    'Elegir mi objeto',
    'Choisir mon objet',
    'Scegli il mio oggetto',
    'Escolher meu item',
    '自分のアイテムを選ぶ'
  ],
  'Choose one item': [
    'Einen Gegenstand wählen',
    'Elige un objeto',
    'Choisis un objet',
    'Scegli un oggetto',
    'Escolha um item',
    'アイテムを1つ選ぶ'
  ],
  'Complete this trade?': [
    'Diesen Handel abschließen?',
    '¿Completar este intercambio?',
    'Finaliser cet échange ?',
    'Completare questo scambio?',
    'Concluir esta troca?',
    'この交換を完了しますか？'
  ],
  'Final confirmation': [
    'Endgültig bestätigen',
    'Confirmación final',
    'Confirmation finale',
    'Conferma finale',
    'Confirmação final',
    '最終確認'
  ],
  'New trade proposal': [
    'Neues Handelsangebot',
    'Nueva propuesta de intercambio',
    'Nouvelle proposition d’échange',
    'Nuova proposta di scambio',
    'Nova proposta de troca',
    '新しい交換提案'
  ],
  'Open trade': [
    'Handel öffnen',
    'Abrir intercambio',
    'Ouvrir l’échange',
    'Apri scambio',
    'Abrir troca',
    '交換を開く'
  ],
  'Reject trade': [
    'Handel ablehnen',
    'Rechazar intercambio',
    'Refuser l’échange',
    'Rifiuta scambio',
    'Recusar troca',
    '交換を拒否'
  ],
  'Relic': ['Relikt', 'Reliquia', 'Relique', 'Reliquia', 'Relíquia', 'レリック'],
  'Reserved for trade': [
    'Für Handel reserviert',
    'Reservado para intercambio',
    'Réservé pour un échange',
    'Riservato per lo scambio',
    'Reservado para troca',
    '交換用に予約済み'
  ],
  'Send': ['Senden', 'Enviar', 'Envoyer', 'Invia', 'Enviar', '送信'],
  'Send trade proposal?': [
    'Handelsangebot senden?',
    '¿Enviar propuesta de intercambio?',
    'Envoyer la proposition d’échange ?',
    'Inviare la proposta di scambio?',
    'Enviar proposta de troca?',
    '交換提案を送りますか？'
  ],
  'The completed trade could not be stored locally. Your server items remain safe; please refresh.':
      [
    'Der abgeschlossene Handel konnte lokal nicht gespeichert werden. Deine Servergegenstände sind sicher; bitte aktualisieren.',
    'El intercambio completado no pudo guardarse localmente. Tus objetos del servidor están seguros; actualiza.',
    'L’échange terminé n’a pas pu être enregistré localement. Tes objets serveur restent en sécurité ; actualise.',
    'Lo scambio completato non è stato salvato localmente. Gli oggetti sul server sono al sicuro; aggiorna.',
    'A troca concluída não pôde ser salva localmente. Seus itens no servidor estão seguros; atualize.',
    '完了した交換を端末に保存できませんでした。サーバー上のアイテムは安全です。更新してください。'
  ],
  'The item is kept safe and cannot be used in another trade.': [
    'Der Gegenstand wird sicher verwahrt und kann nicht in einem anderen Handel verwendet werden.',
    'El objeto queda protegido y no puede usarse en otro intercambio.',
    'L’objet est conservé en sécurité et ne peut pas servir dans un autre échange.',
    'L’oggetto viene custodito e non può essere usato in un altro scambio.',
    'O item fica protegido e não pode ser usado em outra troca.',
    'アイテムは安全に確保され、別の交換には使えません。'
  ],
  'This is the final confirmation. Both items will change owner immediately.': [
    'Dies ist die endgültige Bestätigung. Beide Gegenstände wechseln sofort den Besitzer.',
    'Esta es la confirmación final. Ambos objetos cambiarán de dueño inmediatamente.',
    'C’est la confirmation finale. Les deux objets changeront immédiatement de propriétaire.',
    'Questa è la conferma finale. Entrambi gli oggetti cambieranno subito proprietario.',
    'Esta é a confirmação final. Os dois itens mudarão de dono imediatamente.',
    'これが最終確認です。両方のアイテムはすぐに所有者が変わります。'
  ],
  'This item cannot be traded.': [
    'Dieser Gegenstand kann nicht gehandelt werden.',
    'Este objeto no se puede intercambiar.',
    'Cet objet ne peut pas être échangé.',
    'Questo oggetto non può essere scambiato.',
    'Este item não pode ser trocado.',
    'このアイテムは交換できません。'
  ],
  'This item is no longer available or is already reserved.': [
    'Dieser Gegenstand ist nicht mehr verfügbar oder bereits reserviert.',
    'Este objeto ya no está disponible o ya está reservado.',
    'Cet objet n’est plus disponible ou est déjà réservé.',
    'Questo oggetto non è più disponibile o è già riservato.',
    'Este item não está mais disponível ou já está reservado.',
    'このアイテムは利用できないか、すでに予約されています。'
  ],
  'This trade has already changed. Refresh and try again.': [
    'Dieser Handel hat sich bereits geändert. Aktualisiere und versuche es erneut.',
    'Este intercambio ya ha cambiado. Actualiza e inténtalo de nuevo.',
    'Cet échange a déjà changé. Actualise et réessaie.',
    'Questo scambio è già cambiato. Aggiorna e riprova.',
    'Esta troca já mudou. Atualize e tente novamente.',
    'この交換はすでに変更されています。更新してもう一度お試しください。'
  ],
  'Trade': ['Handeln', 'Intercambiar', 'Échanger', 'Scambia', 'Trocar', '交換'],
  'Trade cancelled': [
    'Handel abgebrochen',
    'Intercambio cancelado',
    'Échange annulé',
    'Scambio annullato',
    'Troca cancelada',
    '交換はキャンセルされました'
  ],
  'Trade cancelled. Reserved items are available again.': [
    'Handel abgebrochen. Reservierte Gegenstände sind wieder verfügbar.',
    'Intercambio cancelado. Los objetos reservados vuelven a estar disponibles.',
    'Échange annulé. Les objets réservés sont de nouveau disponibles.',
    'Scambio annullato. Gli oggetti riservati sono di nuovo disponibili.',
    'Troca cancelada. Os itens reservados estão disponíveis novamente.',
    '交換をキャンセルしました。予約アイテムは再び利用できます。'
  ],
  'Trade completed': [
    'Handel abgeschlossen',
    'Intercambio completado',
    'Échange terminé',
    'Scambio completato',
    'Troca concluída',
    '交換完了'
  ],
  'Trade completed. The received item is in your inventory.': [
    'Handel abgeschlossen. Der erhaltene Gegenstand ist in deinem Inventar.',
    'Intercambio completado. El objeto recibido está en tu inventario.',
    'Échange terminé. L’objet reçu est dans ton inventaire.',
    'Scambio completato. L’oggetto ricevuto è nel tuo inventario.',
    'Troca concluída. O item recebido está no seu inventário.',
    '交換完了。受け取ったアイテムはインベントリにあります。'
  ],
  'Trade proposal sent.': [
    'Handelsangebot gesendet.',
    'Propuesta de intercambio enviada.',
    'Proposition d’échange envoyée.',
    'Proposta di scambio inviata.',
    'Proposta de troca enviada.',
    '交換提案を送信しました。'
  ],
  'Trade rejected': [
    'Handel abgelehnt',
    'Intercambio rechazado',
    'Échange refusé',
    'Scambio rifiutato',
    'Troca recusada',
    '交換は拒否されました'
  ],
  'Trade rejected. Reserved items are available again.': [
    'Handel abgelehnt. Reservierte Gegenstände sind wieder verfügbar.',
    'Intercambio rechazado. Los objetos reservados vuelven a estar disponibles.',
    'Échange refusé. Les objets réservés sont de nouveau disponibles.',
    'Scambio rifiutato. Gli oggetti riservati sono di nuovo disponibili.',
    'Troca recusada. Os itens reservados estão disponíveis novamente.',
    '交換を拒否しました。予約アイテムは再び利用できます。'
  ],
  'Trade with this friend': [
    'Mit diesem Freund handeln',
    'Intercambiar con este amigo',
    'Échanger avec cet ami',
    'Scambia con questo amico',
    'Trocar com este amigo',
    'このフレンドと交換'
  ],
  'Trades are only available between friends.': [
    'Handel ist nur zwischen Freunden möglich.',
    'Los intercambios solo están disponibles entre amigos.',
    'Les échanges sont réservés aux amis.',
    'Gli scambi sono disponibili solo tra amici.',
    'Trocas estão disponíveis apenas entre amigos.',
    '交換はフレンド同士でのみ利用できます。'
  ],
  'Waiting for a return item.': [
    'Warten auf einen Gegengegenstand.',
    'Esperando un objeto a cambio.',
    'En attente d’un objet en retour.',
    'In attesa di un oggetto in cambio.',
    'Aguardando um item em troca.',
    '相手のアイテムを待っています。'
  ],
  'Waiting for final confirmation': [
    'Warten auf die endgültige Bestätigung',
    'Esperando la confirmación final',
    'En attente de la confirmation finale',
    'In attesa della conferma finale',
    'Aguardando a confirmação final',
    '最終確認を待っています'
  ],
  'Waiting for your friend': [
    'Warten auf deinen Freund',
    'Esperando a tu amigo',
    'En attente de ton ami',
    'In attesa del tuo amico',
    'Aguardando seu amigo',
    'フレンドを待っています'
  ],
  'You have no unreserved eggs, chests or relics to trade.': [
    'Du hast keine freien Eier, Truhen oder Relikte zum Handeln.',
    'No tienes huevos, cofres ni reliquias sin reservar para intercambiar.',
    'Tu n’as aucun œuf, coffre ou relique libre à échanger.',
    'Non hai uova, forzieri o reliquie liberi da scambiare.',
    'Você não tem ovos, baús ou relíquias livres para trocar.',
    '交換できる未予約の卵、宝箱、レリックがありません。'
  ],
  'You have too many active trades. Finish or cancel one first.': [
    'Du hast zu viele aktive Handel. Schließe zuerst einen ab oder brich ihn ab.',
    'Tienes demasiados intercambios activos. Completa o cancela uno primero.',
    'Tu as trop d’échanges actifs. Termine ou annule-en un d’abord.',
    'Hai troppi scambi attivi. Completane o annullane prima uno.',
    'Você tem trocas ativas demais. Conclua ou cancele uma primeiro.',
    '進行中の交換が多すぎます。先に1件完了またはキャンセルしてください。'
  ],
  'You offer': [
    'Du bietest an',
    'Tú ofreces',
    'Tu proposes',
    'Tu offri',
    'Você oferece',
    'あなたの提示'
  ],
  'Your final confirmation is needed': [
    'Deine endgültige Bestätigung ist erforderlich',
    'Se necesita tu confirmación final',
    'Ta confirmation finale est nécessaire',
    'Serve la tua conferma finale',
    'Sua confirmação final é necessária',
    'あなたの最終確認が必要です'
  ],
  'Your item is reserved. Your friend can now confirm the trade.': [
    'Dein Gegenstand ist reserviert. Dein Freund kann den Handel jetzt bestätigen.',
    'Tu objeto está reservado. Tu amigo ya puede confirmar el intercambio.',
    'Ton objet est réservé. Ton ami peut maintenant confirmer l’échange.',
    'Il tuo oggetto è riservato. Il tuo amico può ora confermare lo scambio.',
    'Seu item está reservado. Seu amigo já pode confirmar a troca.',
    'アイテムを予約しました。フレンドが交換を確認できます。'
  ],
  'The item is kept safe and cannot be used in another trade. The proposal expires ten minutes after it is created.':
      [
    'Der Gegenstand wird sicher verwahrt und kann nicht in einem anderen Handel verwendet werden. Der Vorschlag verfällt zehn Minuten nach seiner Erstellung.',
    'El objeto queda protegido y no puede usarse en otro intercambio. La propuesta caduca diez minutos después de su creación.',
    'L’objet est conservé en sécurité et ne peut pas servir dans un autre échange. La proposition expire dix minutes après sa création.',
    'L’oggetto viene custodito e non può essere usato in un altro scambio. La proposta scade dieci minuti dopo la creazione.',
    'O item fica protegido e não pode ser usado em outra troca. A proposta expira dez minutos após ser criada.',
    'アイテムは安全に確保され、別の交換には使えません。提案は作成から10分後に期限切れになります。'
  ],
  'Only one active trade is allowed per account. Finish, reject or cancel it first.':
      [
    'Pro Konto ist nur ein aktiver Handel erlaubt. Schließe ihn zuerst ab, lehne ihn ab oder brich ihn ab.',
    'Solo se permite un intercambio activo por cuenta. Complétalo, recházalo o cancélalo primero.',
    'Un seul échange actif est autorisé par compte. Termine-le, refuse-le ou annule-le d’abord.',
    'È consentito un solo scambio attivo per account. Prima completalo, rifiutalo o annullalo.',
    'Só é permitida uma troca ativa por conta. Primeiro conclua, recuse ou cancele essa troca.',
    'アカウントごとに同時進行できる交換は1件だけです。先に完了、拒否、またはキャンセルしてください。'
  ],
  'One of you has already completed three trades today. Try again tomorrow.': [
    'Einer von euch hat heute bereits drei Handelsvorgänge abgeschlossen. Versucht es morgen erneut.',
    'Uno de vosotros ya ha completado tres intercambios hoy. Inténtalo de nuevo mañana.',
    'L’un de vous a déjà terminé trois échanges aujourd’hui. Réessayez demain.',
    'Uno di voi ha già completato tre scambi oggi. Riprova domani.',
    'Um de vocês já concluiu três trocas hoje. Tente novamente amanhã.',
    'どちらかが今日すでに3件の交換を完了しています。明日もう一度お試しください。'
  ],
  'This trade expired after ten minutes. The reserved items are available again.':
      [
    'Dieser Handel ist nach zehn Minuten abgelaufen. Die reservierten Gegenstände sind wieder verfügbar.',
    'Este intercambio caducó tras diez minutos. Los objetos reservados vuelven a estar disponibles.',
    'Cet échange a expiré après dix minutes. Les objets réservés sont de nouveau disponibles.',
    'Questo scambio è scaduto dopo dieci minuti. Gli oggetti riservati sono di nuovo disponibili.',
    'Esta troca expirou após dez minutos. Os itens reservados estão disponíveis novamente.',
    'この交換は10分後に期限切れになりました。確保されていたアイテムは再び使用できます。'
  ],
  'Trade expired': [
    'Handel abgelaufen',
    'Intercambio caducado',
    'Échange expiré',
    'Scambio scaduto',
    'Troca expirada',
    '交換期限切れ'
  ],
  'Enter your password.': [
    'Gib dein Passwort ein.',
    'Introduce tu contraseña.',
    'Saisis ton mot de passe.',
    'Inserisci la password.',
    'Digite sua senha.',
    'パスワードを入力してください。'
  ],
  'Online server is not configured': [
    'Der Online-Server ist nicht konfiguriert.',
    'El servidor en línea no está configurado.',
    'Le serveur en ligne n’est pas configuré.',
    'Il server online non è configurato.',
    'O servidor online não está configurado.',
    'オンラインサーバーが設定されていません。'
  ],
  'This profile is currently stored offline': [
    'Dieses Profil wird derzeit offline gespeichert.',
    'Este perfil se guarda actualmente sin conexión.',
    'Ce profil est actuellement enregistré hors ligne.',
    'Questo profilo è attualmente salvato offline.',
    'Este perfil está armazenado offline no momento.',
    'このプロフィールは現在オフラインで保存されています。'
  ],
  'Trusted keepers, shared adventures and safe trades.': [
    'Vertrauenswürdige Hüter, gemeinsame Abenteuer und sichere Tauschgeschäfte.',
    'Guardianes de confianza, aventuras compartidas e intercambios seguros.',
    'Gardiens de confiance, aventures partagées et échanges sécurisés.',
    'Custodi fidati, avventure condivise e scambi sicuri.',
    'Guardiões confiáveis, aventuras compartilhadas e trocas seguras.',
    '信頼できるキーパー、協力アドベンチャー、安全な交換。'
  ],
  'friends': ['Freunde', 'amigos', 'amis', 'amici', 'amigos', 'フレンド'],
  'requests': [
    'Anfragen',
    'solicitudes',
    'demandes',
    'richieste',
    'pedidos',
    'リクエスト'
  ],
  'trades': [
    'Tauschgeschäfte',
    'intercambios',
    'échanges',
    'scambi',
    'trocas',
    '交換'
  ],
  'dragons discovered': [
    'Drachen entdeckt',
    'dragones descubiertos',
    'dragons découverts',
    'draghi scoperti',
    'dragões descobertos',
    '発見したドラゴン'
  ],
  'Use an uppercase letter, lowercase letter, number and symbol.': [
    'Verwende einen Großbuchstaben, einen Kleinbuchstaben, eine Zahl und ein Symbol.',
    'Usa una mayúscula, una minúscula, un número y un símbolo.',
    'Utilise une majuscule, une minuscule, un chiffre et un symbole.',
    'Usa una lettera maiuscola, una minuscola, un numero e un simbolo.',
    'Use uma letra maiúscula, uma minúscula, um número e um símbolo.',
    '大文字、小文字、数字、記号をそれぞれ使用してください。'
  ],
  'Resend confirmation email': [
    'Bestätigungs-E-Mail erneut senden',
    'Reenviar correo de confirmación',
    'Renvoyer l’e-mail de confirmation',
    'Invia di nuovo l’e-mail di conferma',
    'Reenviar e-mail de confirmação',
    '確認メールを再送'
  ],
  'Confirmation email sent. Check your inbox and spam folder.': [
    'Bestätigungs-E-Mail gesendet. Prüfe deinen Posteingang und Spam-Ordner.',
    'Correo de confirmación enviado. Revisa tu bandeja de entrada y spam.',
    'E-mail de confirmation envoyé. Vérifiez votre boîte de réception et vos spams.',
    'E-mail di conferma inviata. Controlla la posta in arrivo e lo spam.',
    'E-mail de confirmação enviado. Verifique a caixa de entrada e o spam.',
    '確認メールを送信しました。受信トレイと迷惑メールをご確認ください。'
  ],
  'All remaining rewards covered': [
    'Alle übrigen Belohnungen abgedeckt',
    'Todas las recompensas restantes cubiertas',
    'Toutes les récompenses restantes sont couvertes',
    'Tutte le ricompense rimanenti sono coperte',
    'Todas as recompensas restantes estão cobertas',
    '残りの報酬はすべて確保済み'
  ],
  'Collection progress': [
    'Sammlungsfortschritt',
    'Progreso de la colección',
    'Progression de la collection',
    'Progresso della collezione',
    'Progresso da coleção',
    'コレクション進捗'
  ],
  'unopened chests': [
    'ungeöffnete Truhen',
    'cofres sin abrir',
    'coffres non ouverts',
    'forzieri non aperti',
    'baús fechados',
    '個の未開封宝箱'
  ],
  'Current portrait odds': [
    'Aktuelle Porträtchancen',
    'Probabilidades actuales de retrato',
    'Chances actuelles de portrait',
    'Probabilità attuali dei ritratti',
    'Probabilidades atuais de retrato',
    '現在の肖像確率'
  ],
  'Tap an egg for its clue and actions.': [
    'Tippe auf ein Ei, um seinen Hinweis und die Aktionen zu sehen.',
    'Toca un huevo para ver su pista y sus acciones.',
    'Touchez un œuf pour voir son indice et ses actions.',
    'Tocca un uovo per vedere il suo indizio e le azioni.',
    'Toque em um ovo para ver a pista e as ações.',
    '卵をタップするとヒントと操作が表示されます。'
  ],
  'egg': ['Ei', 'huevo', 'œuf', 'uovo', 'ovo', '個の卵'],
  'eggs': ['Eier', 'huevos', 'œufs', 'uova', 'ovos', '個の卵'],
  'Change dragon order': [
    'Drachenreihenfolge ändern',
    'Cambiar el orden de los dragones',
    'Modifier l’ordre des dragons',
    'Cambia l’ordine dei draghi',
    'Alterar a ordem dos dragões',
    'ドラゴンの並び順を変更'
  ],
  'Name': ['Name', 'Nombre', 'Nom', 'Nome', 'Nome', '名前'],
  'Received': ['Erhalten', 'Recibido', 'Reçu', 'Ricevuto', 'Recebido', '入手日'],
  'Rarity': ['Seltenheit', 'Rareza', 'Rareté', 'Rarità', 'Raridade', 'レア度'],
  'Show compact list': [
    'Kompakte Liste anzeigen',
    'Mostrar lista compacta',
    'Afficher la liste compacte',
    'Mostra elenco compatto',
    'Mostrar lista compacta',
    'コンパクトリストを表示'
  ],
  'Show gallery': [
    'Galerie anzeigen',
    'Mostrar galería',
    'Afficher la galerie',
    'Mostra galleria',
    'Mostrar galeria',
    'ギャラリーを表示'
  ],
  'Tap the egg to shorten the wait by one second per tap. The final second always counts down normally.':
      [
    'Tippe auf das Ei, um die Wartezeit pro Tippen um eine Sekunde zu verkürzen. Die letzte Sekunde läuft immer normal ab.',
    'Toca el huevo para acortar la espera un segundo por toque. El último segundo siempre transcurre con normalidad.',
    'Touchez l’œuf pour raccourcir l’attente d’une seconde à chaque fois. La dernière seconde se déroule toujours normalement.',
    'Tocca l’uovo per ridurre l’attesa di un secondo a ogni tocco. L’ultimo secondo scorre sempre normalmente.',
    'Toque no ovo para reduzir a espera em um segundo por toque. O último segundo sempre passa normalmente.',
    '卵をタップするたびに待ち時間が1秒短くなります。最後の1秒は必ず通常どおりカウントダウンします。'
  ],
  'Tap the starter egg to shorten the timer by one second': [
    'Tippe auf das Starter-Ei, um den Timer um eine Sekunde zu verkürzen',
    'Toca el huevo inicial para acortar el temporizador un segundo',
    'Touchez l’œuf de départ pour raccourcir le minuteur d’une seconde',
    'Tocca l’uovo iniziale per accorciare il timer di un secondo',
    'Toque no ovo inicial para reduzir o temporizador em um segundo',
    'スターターエッグをタップしてタイマーを1秒短縮'
  ],
  'Relics bought here are untradeable. Relics found through gameplay remain tradeable. You may buy as many as you like.':
      [
    'Hier gekaufte Relikte sind nicht handelbar. Im Spiel gefundene Relikte bleiben handelbar. Du kannst beliebig viele kaufen.',
    'Las reliquias compradas aquí no se pueden intercambiar. Las encontradas durante el juego sí siguen siendo intercambiables. Puedes comprar todas las que quieras.',
    'Les reliques achetées ici ne sont pas échangeables. Celles trouvées en jouant restent échangeables. Vous pouvez en acheter autant que vous voulez.',
    'Le reliquie acquistate qui non sono scambiabili. Quelle trovate durante il gioco restano scambiabili. Puoi acquistarne quante ne vuoi.',
    'As relíquias compradas aqui não são negociáveis. As encontradas durante o jogo continuam negociáveis. Você pode comprar quantas quiser.',
    'ここで購入したレリックは交換できません。ゲームで入手したレリックは引き続き交換できます。購入数に制限はありません。'
  ],
  'A Special Adventure has appeared': [
    'Ein Spezialabenteuer ist erschienen',
    'Ha aparecido una Aventura especial',
    'Une Aventure spéciale est apparue',
    'È apparsa un’Avventura speciale',
    'Uma Aventura especial apareceu',
    'スペシャルアドベンチャーが出現しました'
  ],
  'A gentle golden warmth lingers around this egg, as if it carries a wish meant for someone truly special.':
      [
    'Eine sanfte goldene Wärme umgibt dieses Ei, als trüge es einen Wunsch für einen ganz besonderen Menschen.',
    'Una suave calidez dorada rodea este huevo, como si llevara un deseo para alguien realmente especial.',
    'Une douce chaleur dorée entoure cet œuf, comme s’il portait un vœu destiné à une personne vraiment spéciale.',
    'Un dolce calore dorato avvolge questo uovo, come se custodisse un desiderio per una persona davvero speciale.',
    'Um suave calor dourado envolve este ovo, como se carregasse um desejo para alguém realmente especial.',
    'この卵には、かけがえのない誰かへの願いを宿すような、優しい黄金のぬくもりが残っています。'
  ],
  'All Expertises': [
    'Alle Expertisen',
    'Todas las pericias',
    'Toutes les expertises',
    'Tutte le competenze',
    'Todas as especialidades',
    'すべての専門能力'
  ],
  'Journey shortening': [
    'Reiseverkürzung',
    'Reducción del viaje',
    'Réduction du voyage',
    'Riduzione del viaggio',
    'Redução da jornada',
    '旅程の短縮'
  ],
  'Might + Arcana + Spirit: every combined point removes 1 hour (minimum 1 day).':
      [
    'Macht + Arkana + Geist: Jeder gemeinsame Punkt verkürzt um 1 Stunde (mindestens 1 Tag).',
    'Poder + Arcana + Espíritu: cada punto combinado reduce 1 hora (mínimo 1 día).',
    'Puissance + Arcane + Esprit : chaque point cumulé retire 1 heure (minimum 1 jour).',
    'Forza + Arcano + Spirito: ogni punto combinato riduce di 1 ora (minimo 1 giorno).',
    'Poder + Arcana + Espírito: cada ponto combinado reduz 1 hora (mínimo de 1 dia).',
    'マイト＋アルカナ＋スピリット：合計1ポイントごとに1時間短縮（最短1日）。'
  ],
  'Guaranteed Special Chest': [
    'Garantierte Spezialtruhe',
    'Cofre especial garantizado',
    'Coffre spécial garanti',
    'Forziere speciale garantito',
    'Baú especial garantido',
    'スペシャルチェスト確定'
  ],
  '269 coins, 10 gems and a Special Egg with an event dragon.': [
    '269 Münzen, 10 Edelsteine und ein Spezial-Ei mit einem Eventdrachen.',
    '269 monedas, 10 gemas y un Huevo especial con un dragón del evento.',
    '269 pièces, 10 gemmes et un Œuf spécial contenant un dragon d’événement.',
    '269 monete, 10 gemme e un Uovo speciale con un drago dell’evento.',
    '269 moedas, 10 gemas e um Ovo especial com um dragão do evento.',
    '269コイン、10ジェム、イベントドラゴン入りのスペシャルエッグ。'
  ],
  'Guaranteed relic': [
    'Garantiertes Relikt',
    'Reliquia garantizada',
    'Relique garantie',
    'Reliquia garantita',
    'Relíquia garantida',
    'レリック確定'
  ],
  '1 random relic; which one remains a surprise until you claim it.': [
    '1 zufälliges Relikt; welches es ist, bleibt bis zum Abholen eine Überraschung.',
    '1 reliquia aleatoria; cuál será seguirá siendo una sorpresa hasta reclamarla.',
    '1 relique aléatoire ; son identité reste une surprise jusqu’à sa récupération.',
    '1 reliquia casuale; quale sarà resta una sorpresa fino alla riscossione.',
    '1 relíquia aleatória; qual será continua sendo surpresa até o resgate.',
    'ランダムなレリック1個。受け取るまで中身は秘密です。'
  ],
  'Guaranteed Music Chest': [
    'Garantierte Musiktruhe',
    'Cofre de música garantizado',
    'Coffre musical garanti',
    'Forziere musicale garantito',
    'Baú de música garantido',
    'ミュージックチェスト確定'
  ],
  '1 Music Chest, rolled only when you open it.': [
    '1 Musiktruhe, deren Inhalt erst beim Öffnen bestimmt wird.',
    '1 Cofre de música, cuyo contenido se decide solo al abrirlo.',
    '1 Coffre musical, dont le contenu est tiré uniquement à l’ouverture.',
    '1 Forziere musicale, estratto solo quando lo apri.',
    '1 Baú de música, sorteado somente quando você o abre.',
    'ミュージックチェスト1個。開けた時にだけ抽選されます。'
  ],
  '1 random relic; the exact relic is still a surprise.': [
    '1 zufälliges Relikt; das genaue Relikt bleibt eine Überraschung.',
    '1 reliquia aleatoria; la reliquia exacta sigue siendo una sorpresa.',
    '1 relique aléatoire ; la relique exacte reste une surprise.',
    '1 reliquia casuale; la reliquia esatta resta una sorpresa.',
    '1 relíquia aleatória; a relíquia exata continua sendo surpresa.',
    'ランダムなレリック1個。どれかはまだ秘密です。'
  ],
  '1 Music Chest, rolled when it is opened.': [
    '1 Musiktruhe, deren Inhalt beim Öffnen bestimmt wird.',
    '1 Cofre de música, cuyo contenido se decide al abrirlo.',
    '1 Coffre musical, dont le contenu est tiré à l’ouverture.',
    '1 Forziere musicale, estratto quando viene aperto.',
    '1 Baú de música, sorteado quando é aberto.',
    'ミュージックチェスト1個。開封時に抽選されます。'
  ],
  'Special Egg': [
    'Spezial-Ei',
    'Huevo especial',
    'Œuf spécial',
    'Uovo speciale',
    'Ovo especial',
    'スペシャルエッグ'
  ],
  'Special Events': [
    'Spezialevents',
    'Eventos especiales',
    'Événements spéciaux',
    'Eventi speciali',
    'Eventos especiais',
    'スペシャルイベント'
  ],
  'Available for': [
    'Verfügbar für',
    'Disponible durante',
    'Disponible pendant',
    'Disponibile per',
    'Disponível por',
    '残り時間'
  ],
  'When a Special Adventure becomes available.': [
    'Wenn ein Spezialabenteuer verfügbar wird.',
    'Cuando una Aventura especial esté disponible.',
    'Lorsqu’une Aventure spéciale devient disponible.',
    'Quando diventa disponibile un’Avventura speciale.',
    'Quando uma Aventura especial fica disponível.',
    'スペシャルアドベンチャーが利用可能になった時。'
  ],
  'No Eggs in your inventory yet.': [
    'Noch keine Eier in deinem Inventar.',
    'Todavía no hay huevos en tu inventario.',
    'Aucun œuf dans votre inventaire pour le moment.',
    'Non ci sono ancora uova nel tuo inventario.',
    'Ainda não há ovos no seu inventário.',
    'インベントリにはまだ卵がありません。',
  ],
  'Open 10': [
    '10 öffnen',
    'Abrir 10',
    'Ouvrir 10',
    'Apri 10',
    'Abrir 10',
    '10個開ける',
  ],
  'No Eggs are waiting in your inventory.': [
    'In deinem Inventar warten keine Eier.',
    'No hay huevos esperando en tu inventario.',
    'Aucun œuf n’attend dans votre inventaire.',
    'Non ci sono uova in attesa nel tuo inventario.',
    'Não há ovos esperando no seu inventário.',
    'インベントリに待機中の卵はありません。',
  ],
  'Choose an Egg': [
    'Wähle ein Ei',
    'Elige un huevo',
    'Choisir un œuf',
    'Scegli un uovo',
    'Escolha um ovo',
    '卵を選ぶ',
  ],
  'New title': [
    'Neuer Titel',
    'Nuevo título',
    'Nouveau titre',
    'Nuovo titolo',
    'Novo título',
    '新しい称号',
  ],
  'A golden birthday wish for a beautiful woman whose kindness brightens the Haven.':
      [
    'Ein goldener Geburtstagswunsch für eine wundervolle Frau, deren Güte den Haven erhellt.',
    'Un deseo dorado de cumpleaños para una mujer maravillosa cuya bondad ilumina el Haven.',
    'Un vœu d’anniversaire doré pour une femme merveilleuse dont la bonté illumine le Haven.',
    'Un augurio di compleanno dorato per una donna meravigliosa la cui gentilezza illumina l’Haven.',
    'Um desejo dourado de aniversário para uma mulher maravilhosa cuja bondade ilumina o Haven.',
    '優しさでヘイヴンを照らす素敵な女性へ贈る、黄金の誕生日の願い。'
  ],
};
