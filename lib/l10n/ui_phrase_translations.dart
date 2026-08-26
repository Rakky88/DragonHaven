import 'trial_phrase_translations.dart';
import 'notification_phrase_translations.dart';

/// Offline translations for complete, user-visible UI phrases.
///
/// The list order is German, Spanish, French, Italian, Portuguese,
/// Simplified Chinese and Japanese. English and Dutch remain the authored
/// source strings at each call site.
const _languageIndex = <String, int>{
  'de': 0,
  'es': 1,
  'fr': 2,
  'it': 3,
  'pt': 4,
  'zh': 5,
  'ja': 6,
};

String? translatedUiPhrase(String english, String languageCode) {
  final index = _languageIndex[languageCode];
  final values =
      uiPhraseTranslations[english] ?? trialPhraseTranslations[english];
  if (index == null) return null;
  if (values != null && values.length == 7) return values[index];
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
      '$value 的新纪录！',
      '$valueの新記録！',
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
      '$value 已经摆放在房屋中了。',
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
      '$value 现在在庇护所中有了位置。',
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
      '$item 现在位于$room。',
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
      '已购买$item并摆放在$room！',
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
      '$dragon，$form阶段',
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
      '$items 件物品 · 已建造 $built/$total 个房间',
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
      '已摆放$value。点击其他位置即可移动。',
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
      '剩余 $value',
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
      '已收集 $owned/$total',
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
      '已解锁 $count / $total',
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
      '还需要 $value 金币。',
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
      '还需要 $value 宝石。',
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
      '显示 $value 件物品',
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
      '$value 可以开始装饰了！',
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
      '$value 已加入你的奖励。',
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
      '$value 孵化了！',
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
      '$dragon 进化为$form。',
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
      '获得于 $date · 身份已确定',
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
      '添加楼层 · $value 金币',
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
      '要花费 $value 星币建造此房间吗？家具和进度都会原样保留。',
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
      '咔嚓 $value',
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
      '领取$value',
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
      '要丢弃一个$value吗？',
      '$valueを1つ破棄しますか？'
    ]);
  }
  final dragons = RegExp(r'^Dragons (\d+)/42$').firstMatch(text);
  if (dragons != null) {
    final count = dragons.group(1);
    return _localized(languageCode, [
      'Drachen $count/42',
      'Dragones $count/42',
      'Dragons $count/42',
      'Draghi $count/42',
      'Dragões $count/42',
      '龙 $count/42',
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
      '$value 后孵化',
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
      '无法检查 GitHub（代码 $value）。',
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
      '等级 $level · $price 金币',
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
      '下一形态：$value',
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
      '礼包 $number/6',
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
      '$value 名玩家',
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
      '要放归$value吗？',
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
      '要移除$value吗？',
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
      '已选择：$value。点击房间进行摆放。',
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
      '与$value交谈',
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
      '$value 已归来',
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
      '还需要 $value 金币。',
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
      '庇护所达到 $value 级后才能建造此房间。',
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
      '$selected / $capacity 只正在漫游 ·每个房间最多 3 只',
      '$selected / $capacity 体が巡回中・1部屋につき最大3体',
    ]);
  }
  return null;
}

const uiPhraseTranslations = <String, List<String>>{
  ...notificationPhraseTranslations,
  'Start trade': [
    'Handel starten',
    'Iniciar intercambio',
    "Commencer l'\u00e9change",
    'Avvia scambio',
    'Iniciar troca',
    '\u5f00\u59cb\u4ea4\u6613',
    '\u4ea4\u63db\u3092\u958b\u59cb',
  ],
  'Collapse records': [
    'Rekorde einklappen',
    'Contraer r\u00e9cords',
    'Replier les records',
    'Comprimi record',
    'Recolher recordes',
    '\u6536\u8d77\u7eaa\u5f55',
    '\u8a18\u9332\u3092\u6298\u308a\u305f\u305f\u3080',
  ],
  'Expand records': [
    'Rekorde ausklappen',
    'Expandir r\u00e9cords',
    'D\u00e9plier les records',
    'Espandi record',
    'Expandir recordes',
    '\u5c55\u5f00\u7eaa\u5f55',
    '\u8a18\u9332\u3092\u5c55\u958b',
  ],
  'TRADE COMPLETE!': [
    'TAUSCH ABGESCHLOSSEN!',
    '\u00a1INTERCAMBIO COMPLETADO!',
    '\u00c9CHANGE TERMIN\u00c9 !',
    'SCAMBIO COMPLETATO!',
    'TROCA CONCLU\u00cdDA!',
    '\u4ea4\u6613\u5b8c\u6210\uff01',
    '\u4ea4\u63db\u5b8c\u4e86\uff01',
  ],
  'The exchange is safely sealed.': [
    'Der Tausch ist sicher besiegelt.',
    'El intercambio ha quedado sellado de forma segura.',
    "L'\u00e9change est scell\u00e9 en toute s\u00e9curit\u00e9.",
    'Lo scambio \u00e8 stato sigillato in sicurezza.',
    'A troca foi selada com seguran\u00e7a.',
    '\u4ea4\u6613\u5df2\u5b89\u5168\u5c01\u5b58\u3002',
    '\u4ea4\u63db\u306f\u5b89\u5168\u306b\u78ba\u5b9a\u3055\u308c\u307e\u3057\u305f\u3002',
  ],
  'YOU SENT': [
    'DU HAST GESENDET',
    'HAS ENVIADO',
    'VOUS AVEZ ENVOY\u00c9',
    'HAI INVIATO',
    'VOC\u00ca ENVIOU',
    '\u4f60\u9001\u51fa\u4e86',
    '\u3042\u306a\u305f\u304c\u6e21\u3057\u305f\u3082\u306e',
  ],
  'YOU RECEIVED': [
    'DU HAST ERHALTEN',
    'HAS RECIBIDO',
    'VOUS AVEZ RE\u00c7U',
    'HAI RICEVUTO',
    'VOC\u00ca RECEBEU',
    '\u4f60\u6536\u5230\u4e86',
    '\u3042\u306a\u305f\u304c\u53d7\u3051\u53d6\u3063\u305f\u3082\u306e',
  ],
  'Cancel group': [
    'Gruppe abbrechen',
    'Cancelar grupo',
    'Annuler le groupe',
    'Annulla gruppo',
    'Cancelar grupo',
    '取消队伍',
    'グループをキャンセル'
  ],
  'Cancel this group?': [
    'Diese Gruppe abbrechen?',
    '¿Cancelar este grupo?',
    'Annuler ce groupe ?',
    'Annullare questo gruppo?',
    'Cancelar este grupo?',
    '要取消这个队伍吗？',
    'このグループをキャンセルしますか？'
  ],
  'Confirm': [
    'Bestätigen',
    'Confirmar',
    'Confirmer',
    'Conferma',
    'Confirmar',
    '确认',
    '確認'
  ],
  'Create group': [
    'Gruppe erstellen',
    'Crear grupo',
    'Créer un groupe',
    'Crea gruppo',
    'Criar grupo',
    '创建队伍',
    'グループを作成'
  ],
  'Friends looking for dragons': [
    'Freunde suchen Drachen',
    'Amigos que buscan dragones',
    'Amis à la recherche de dragons',
    'Amici in cerca di draghi',
    'Amigos à procura de dragões',
    '正在寻找龙的好友',
    'ドラゴンを探しているフレンド'
  ],
  'Group Adventures are only available to verified online accounts.': [
    'Gruppenabenteuer sind nur für bestätigte Online-Konten verfügbar.',
    'Las Aventuras de grupo solo están disponibles para cuentas verificadas.',
    'Les Aventures de groupe sont réservées aux comptes en ligne vérifiés.',
    'Le Avventure di gruppo sono disponibili solo per gli account verificati.',
    'As Aventuras de grupo só estão disponíveis para contas verificadas.',
    '组队冒险仅对已验证的在线账号开放。',
    'グループアドベンチャーは認証済みオンラインアカウントでのみ利用できます。'
  ],
  'Group created. Friends can now join.': [
    'Gruppe erstellt. Freunde können jetzt beitreten.',
    'Grupo creado. Tus amigos ya pueden unirse.',
    'Groupe créé. Tes amis peuvent maintenant le rejoindre.',
    'Gruppo creato. Ora gli amici possono unirsi.',
    'Grupo criado. Os amigos já podem participar.',
    '队伍已创建，好友现在可以加入。',
    'グループを作成しました。フレンドが参加できます。'
  ],
  'Join with a dragon': [
    'Mit einem Drachen beitreten',
    'Unirse con un dragón',
    'Rejoindre avec un dragon',
    'Unisciti con un drago',
    'Participar com um dragão',
    '携带一条龙加入',
    'ドラゴンと参加'
  ],
  'Only friends of the group starter can join.': [
    'Nur Freunde des Gruppengründers können beitreten.',
    'Solo los amigos del creador del grupo pueden unirse.',
    'Seuls les amis du créateur du groupe peuvent le rejoindre.',
    'Solo gli amici di chi ha creato il gruppo possono unirsi.',
    'Só os amigos de quem criou o grupo podem participar.',
    '只有发起者的好友可以加入。',
    'グループ作成者のフレンドだけが参加できます。'
  ],
  'Participants': [
    'Teilnehmer',
    'Participantes',
    'Participants',
    'Partecipanti',
    'Participantes',
    '参与者',
    '参加者'
  ],
  'Remove dragon': [
    'Drachen entfernen',
    'Quitar dragón',
    'Retirer le dragon',
    'Rimuovi drago',
    'Remover dragão',
    '移除龙',
    'ドラゴンを外す'
  ],
  'Rewards are ready': [
    'Belohnungen sind bereit',
    'Las recompensas están listas',
    'Les récompenses sont prêtes',
    'Le ricompense sono pronte',
    'As recompensas estão prontas',
    '奖励已就绪',
    '報酬を受け取れます'
  ],
  'Sign in for Group Adventures': [
    'Für Gruppenabenteuer anmelden',
    'Inicia sesión para las Aventuras de grupo',
    'Connecte-toi pour les Aventures de groupe',
    'Accedi per le Avventure di gruppo',
    'Inicia sessão para as Aventuras de grupo',
    '登录以参加组队冒险',
    'グループアドベンチャーにログイン'
  ],
  'The dragon was removed from the group.': [
    'Der Drache wurde aus der Gruppe entfernt.',
    'El dragón fue retirado del grupo.',
    'Le dragon a été retiré du groupe.',
    'Il drago è stato rimosso dal gruppo.',
    'O dragão foi removido do grupo.',
    '这条龙已被移出队伍。',
    'ドラゴンをグループから外しました。'
  ],
  'The group has returned.': [
    'Die Gruppe ist zurückgekehrt.',
    'El grupo ha regresado.',
    'Le groupe est de retour.',
    'Il gruppo è tornato.',
    'O grupo regressou.',
    '队伍已经归来。',
    'グループが帰還しました。'
  ],
  'The journey starts automatically when all requirements are met.': [
    'Die Reise startet automatisch, sobald alle Anforderungen erfüllt sind.',
    'El viaje comienza automáticamente cuando se cumplen todos los requisitos.',
    'Le voyage commence automatiquement lorsque toutes les conditions sont remplies.',
    'Il viaggio inizia automaticamente quando tutti i requisiti sono soddisfatti.',
    'A viagem começa automaticamente quando todos os requisitos forem cumpridos.',
    '满足所有要求后，旅程会自动开始。',
    'すべての条件を満たすと旅が自動的に始まります。'
  ],
  'The reward could not be linked to your local dragon.': [
    'Die Belohnung konnte deinem lokalen Drachen nicht zugeordnet werden.',
    'No se pudo vincular la recompensa con tu dragón local.',
    'La récompense n’a pas pu être associée à ton dragon local.',
    'Non è stato possibile collegare la ricompensa al tuo drago locale.',
    'Não foi possível associar a recompensa ao teu dragão local.',
    '无法将奖励关联到你的本地龙。',
    '報酬をローカルのドラゴンに反映できませんでした。'
  ],
  'These Group Adventure rewards are not ready yet.': [
    'Diese Gruppenabenteuer-Belohnungen sind noch nicht bereit.',
    'Estas recompensas de la Aventura de grupo aún no están listas.',
    'Ces récompenses d’Aventure de groupe ne sont pas encore prêtes.',
    'Le ricompense di questa Avventura di gruppo non sono ancora pronte.',
    'Estas recompensas da Aventura de grupo ainda não estão prontas.',
    '这些组队冒险奖励尚未就绪。',
    'このグループアドベンチャーの報酬はまだ受け取れません。'
  ],
  'This dragon is already reserved for a Group Adventure.': [
    'Dieser Drache ist bereits für ein Gruppenabenteuer reserviert.',
    'Este dragón ya está reservado para una Aventura de grupo.',
    'Ce dragon est déjà réservé pour une Aventure de groupe.',
    'Questo drago è già riservato per un’Avventura di gruppo.',
    'Este dragão já está reservado para uma Aventura de grupo.',
    '这条龙已被预留给一次组队冒险。',
    'このドラゴンはすでにグループアドベンチャーに予約されています。'
  ],
  'This group has already started or expired.': [
    'Diese Gruppe ist bereits gestartet oder abgelaufen.',
    'Este grupo ya ha comenzado o ha caducado.',
    'Ce groupe a déjà commencé ou a expiré.',
    'Questo gruppo è già partito o è scaduto.',
    'Este grupo já começou ou expirou.',
    '这个队伍已经出发或已过期。',
    'このグループはすでに出発したか期限切れです。'
  ],
  'This group is full.': [
    'Diese Gruppe ist voll.',
    'Este grupo está completo.',
    'Ce groupe est complet.',
    'Questo gruppo è al completo.',
    'Este grupo está cheio.',
    '这个队伍已满。',
    'このグループは満員です。'
  ],
  'This is only possible before the adventure starts.': [
    'Dies ist nur möglich, bevor das Abenteuer beginnt.',
    'Esto solo es posible antes de que comience la aventura.',
    'Cela n’est possible qu’avant le début de l’aventure.',
    'È possibile farlo solo prima dell’inizio dell’avventura.',
    'Isto só é possível antes de a aventura começar.',
    '只能在冒险开始前进行此操作。',
    'この操作はアドベンチャー開始前のみ可能です。'
  ],
  'Withdraw': [
    'Zurückziehen',
    'Retirarse',
    'Se retirer',
    'Ritirati',
    'Retirar-se',
    '退出',
    '参加を取り消す'
  ],
  'Withdraw from this group?': [
    'Aus dieser Gruppe zurückziehen?',
    '¿Retirarte de este grupo?',
    'Te retirer de ce groupe ?',
    'Ritirarti da questo gruppo?',
    'Retirar-te deste grupo?',
    '要退出这个队伍吗？',
    'このグループへの参加を取り消しますか？'
  ],
  'You already used this weekly Group Adventure.': [
    'Du hast dieses wöchentliche Gruppenabenteuer bereits genutzt.',
    'Ya has usado esta Aventura de grupo semanal.',
    'Tu as déjà utilisé cette Aventure de groupe hebdomadaire.',
    'Hai già usato questa Avventura di gruppo settimanale.',
    'Já usaste esta Aventura de grupo semanal.',
    '你已经参加过本周的组队冒险。',
    '今週のグループアドベンチャーにはすでに参加しています。'
  ],
  "You have already completed this week's Group Adventure.": [
    'Du hast das Gruppenabenteuer dieser Woche bereits abgeschlossen.',
    'Ya has completado la Aventura de grupo de esta semana.',
    'Tu as déjà terminé l’Aventure de groupe de cette semaine.',
    'Hai già completato l’Avventura di gruppo di questa settimana.',
    'Já concluíste a Aventura de grupo desta semana.',
    '你已经完成了本周的组队冒险。',
    '今週のグループアドベンチャーはすでに完了しています。'
  ],
  'Your current weekly Group Adventure is reserved. Its lobby or run is shown under Active.':
      [
    'Dein aktuelles wöchentliches Gruppenabenteuer ist reserviert. Die Gruppe oder Reise wird unter „Aktiv“ angezeigt.',
    'Tu Aventura de grupo semanal está reservada. Su grupo o viaje aparece en Activas.',
    'Ton Aventure de groupe hebdomadaire est réservée. Son groupe ou son trajet apparaît dans Actives.',
    'La tua Avventura di gruppo settimanale è riservata. Il gruppo o il viaggio appare in Attive.',
    'A tua Aventura de grupo semanal está reservada. O grupo ou a viagem aparece em Ativas.',
    '本周的组队冒险已预留，其队伍或旅程会显示在“进行中”。',
    '今週のグループアドベンチャーは予約済みです。グループまたは旅は「進行中」に表示されます。'
  ],
  'Your dragon': [
    'Dein Drache',
    'Tu dragón',
    'Ton dragon',
    'Il tuo drago',
    'O teu dragão',
    '你的龙',
    'あなたのドラゴン'
  ],
  'Your dragon joined the group.': [
    'Dein Drache ist der Gruppe beigetreten.',
    'Tu dragón se ha unido al grupo.',
    'Ton dragon a rejoint le groupe.',
    'Il tuo drago si è unito al gruppo.',
    'O teu dragão entrou no grupo.',
    '你的龙已加入队伍。',
    'ドラゴンがグループに参加しました。'
  ],
  'Your dragon left the group.': [
    'Dein Drache hat die Gruppe verlassen.',
    'Tu dragón ha abandonado el grupo.',
    'Ton dragon a quitté le groupe.',
    'Il tuo drago ha lasciato il gruppo.',
    'O teu dragão saiu do grupo.',
    '你的龙已退出队伍。',
    'ドラゴンがグループを離れました。'
  ],
  'Your offline name, portrait and title are used automatically online.': [
    'Dein Offline-Name, Porträt und Titel werden online automatisch verwendet.',
    'Tu nombre, retrato y título sin conexión se usan automáticamente en línea.',
    'Ton nom, ton portrait et ton titre hors ligne sont utilisés automatiquement en ligne.',
    'Il nome, il ritratto e il titolo offline vengono usati automaticamente online.',
    'O teu nome, retrato e título offline são usados automaticamente online.',
    '你的离线名称、头像和称号会自动用于在线账号。',
    'オフラインの名前、ポートレート、称号がオンラインでも自動的に使われます。'
  ],
  'combined': [
    'kombinierte',
    'combinado',
    'combiné',
    'combinato',
    'combinado',
    '合计',
    '合計'
  ],
  'combined level': [
    'kombiniertes Level',
    'nivel combinado',
    'niveau combiné',
    'livello combinato',
    'nível combinado',
    '总等级',
    '合計レベル'
  ],
  'dragons': [
    'Drachen',
    'dragones',
    'dragons',
    'draghi',
    'dragões',
    '龙',
    'ドラゴン'
  ],
  'participants': [
    'Teilnehmer',
    'participantes',
    'participants',
    'partecipanti',
    'participantes',
    '参与者',
    '参加者'
  ],
  'Confirm your email before signing in.': [
    'Bestätige deine E-Mail-Adresse, bevor du dich anmeldest.',
    'Confirma tu correo electrónico antes de iniciar sesión.',
    'Confirme ton adresse e-mail avant de te connecter.',
    'Conferma la tua e-mail prima di accedere.',
    'Confirme seu e-mail antes de entrar.',
    '登录前请先确认你的电子邮件。',
    'ログイン前にメールアドレスを確認してください。',
  ],
  'Create a verified account to add friends by Keeper ID. You must confirm your email before signing in, and it is never shown to other players.':
      [
    'Erstelle ein bestätigtes Konto, um Freunde per Hüter-ID hinzuzufügen. Du musst deine E-Mail vor der Anmeldung bestätigen; sie wird anderen Spielern nie angezeigt.',
    'Crea una cuenta verificada para añadir amigos por ID de Guardián. Debes confirmar tu correo antes de iniciar sesión y nunca se muestra a otros jugadores.',
    'Crée un compte vérifié pour ajouter des amis par ID de Gardien. Tu dois confirmer ton e-mail avant de te connecter; il n’est jamais montré aux autres joueurs.',
    'Crea un account verificato per aggiungere amici tramite ID Custode. Devi confermare l’e-mail prima di accedere e non viene mai mostrata agli altri giocatori.',
    'Crie uma conta verificada para adicionar amigos pelo ID de Guardião. Você deve confirmar o e-mail antes de entrar, e ele nunca é mostrado a outros jogadores.',
    '创建经过验证的账户，以便通过守护者 ID 添加好友。登录前必须确认电子邮件，且邮件地址永远不会向其他玩家显示。',
    'キーパーIDでフレンドを追加できる認証済みアカウントを作成します。ログイン前にメール確認が必要で、アドレスは他のプレイヤーに表示されません。',
  ],
  'A Mysterious Egg appeared in the tower nest.': [
    'Ein geheimnisvolles Ei ist im Turmnest erschienen.',
    'Un Huevo Misterioso apareció en el nido de la torre.',
    'Un Œuf mystérieux est apparu dans le nid de la tour.',
    'Un Uovo misterioso è apparso nel nido della torre.',
    'Um Ovo Misterioso apareceu no ninho da torre.',
    '塔顶巢穴里出现了一颗神秘龙蛋。',
    '塔の巣に不思議な卵が現れました。',
  ],
  'A chest was opened.': [
    'Eine Truhe wurde geöffnet.',
    'Se abrió un cofre.',
    'Un coffre a été ouvert.',
    'È stato aperto un forziere.',
    'Um baú foi aberto.',
    '打开了一个宝箱。',
    '宝箱を開けました。'
  ],
  'A dragon evolved.': [
    'Ein Drache hat sich entwickelt.',
    'Un dragón ha evolucionado.',
    'Un dragon a évolué.',
    'Un drago si è evoluto.',
    'Um dragão evoluiu.',
    '一只龙进化了。',
    'ドラゴンが進化しました。'
  ],
  'A dragon hatched!': [
    'Ein Drache ist geschlüpft!',
    '¡Ha nacido un dragón!',
    'Un dragon vient d’éclore !',
    'È nato un drago!',
    'Um dragão nasceu!',
    '一只龙孵化了！',
    'ドラゴンが孵化しました！'
  ],
  'A familiar shadow returned': [
    'Ein vertrauter Schatten ist zurückgekehrt',
    'Una sombra familiar ha regresado',
    'Une ombre familière est revenue',
    'È tornata un’ombra familiare',
    'Uma sombra familiar retornou',
    '熟悉的身影回来了',
    '見覚えのある影が戻ってきました'
  ],
  'A global weekly expedition refreshes on Sunday at 12:00 Europe/Amsterdam. Online friends are required.':
      [
    'Eine globale Wochenexpedition wird sonntags um 12:00 Uhr (Europa/Amsterdam) erneuert. Online-Freunde sind erforderlich.',
    'Una expedición semanal global se renueva el domingo a las 12:00 (Europa/Ámsterdam). Se necesitan amigos en línea.',
    'Une expédition hebdomadaire mondiale est renouvelée le dimanche à 12 h (Europe/Amsterdam). Des amis en ligne sont requis.',
    'Una spedizione settimanale globale si aggiorna la domenica alle 12:00 (Europa/Amsterdam). Servono amici online.',
    'Uma expedição semanal global é renovada no domingo às 12:00 (Europa/Amsterdã). Amigos online são necessários.',
    '全球每周远征于周日 12:00（欧洲/阿姆斯特丹）刷新，需要在线好友。',
    '世界共通の週間遠征は日曜12:00（ヨーロッパ／アムステルダム）に更新されます。オンラインのフレンドが必要です。'
  ],
  'A new form awakens!': [
    'Eine neue Form erwacht!',
    '¡Despierta una nueva forma!',
    'Une nouvelle forme s’éveille !',
    'Si risveglia una nuova forma!',
    'Uma nova forma desperta!',
    '新的形态觉醒了！',
    '新たな姿が目覚めました！'
  ],
  'A new form is awakening…': [
    'Eine neue Form erwacht …',
    'Una nueva forma está despertando…',
    'Une nouvelle forme s’éveille…',
    'Una nuova forma si sta risvegliando…',
    'Uma nova forma está despertando…',
    '新的形态正在觉醒……',
    '新たな姿が目覚めようとしています…'
  ],
  'A quiet tower. A mysterious egg. A collection waiting to become legend.': [
    'Ein stiller Turm. Ein geheimnisvolles Ei. Eine Sammlung, die zur Legende werden will.',
    'Una torre silenciosa. Un huevo misterioso. Una colección destinada a convertirse en leyenda.',
    'Une tour paisible. Un œuf mystérieux. Une collection qui ne demande qu’à devenir légendaire.',
    'Una torre silenziosa. Un uovo misterioso. Una collezione pronta a diventare leggenda.',
    'Uma torre tranquila. Um ovo misterioso. Uma coleção esperando para virar lenda.',
    '一座静谧的高塔，一颗神秘的龙蛋，一套等待成为传奇的收藏。',
    '静かな塔。不思議な卵。伝説になる日を待つコレクション。'
  ],
  'A rare Tower moment': [
    'Ein seltener Turmmoment',
    'Un momento especial en la Torre',
    'Un instant rare dans la Tour',
    'Un raro momento nella Torre',
    'Um momento raro na Torre',
    '塔中的珍贵时刻',
    '塔での特別なひととき'
  ],
  'A sanctuary activity was completed.': [
    'Eine Aktivität im Refugium wurde abgeschlossen.',
    'Se completó una actividad del santuario.',
    'Une activité du sanctuaire a été terminée.',
    'È stata completata un’attività del santuario.',
    'Uma atividade do santuário foi concluída.',
    '完成了一项庇护所活动。',
    'サンクチュアリの活動を完了しました。'
  ],
  'A secret life is waiting inside one familiar shell.': [
    'In einer vertrauten Schale wartet ein geheimes Leben.',
    'Una vida secreta espera dentro de una cáscara familiar.',
    'Une vie secrète attend dans une coquille familière.',
    'Una vita segreta attende dentro un guscio familiare.',
    'Uma vida secreta espera dentro de uma casca familiar.',
    '熟悉的蛋壳里，藏着一个未知的生命。',
    '見慣れた殻の中で、秘密の命が待っています。'
  ],
  'A soft glow fills every wellbeing bar.': [
    'Ein sanftes Leuchten füllt alle Wohlfühlleisten.',
    'Un brillo suave llena todas las barras de bienestar.',
    'Une douce lueur remplit toutes les jauges de bien-être.',
    'Un bagliore delicato riempie tutte le barre del benessere.',
    'Um brilho suave preenche todas as barras de bem-estar.',
    '柔和的光芒充满了所有状态条。',
    'やわらかな光がすべてのコンディションゲージを満たします。'
  ],
  'ABOUT THE GAME': [
    'ÜBER DAS SPIEL',
    'ACERCA DEL JUEGO',
    'À PROPOS DU JEU',
    'INFORMAZIONI SUL GIOCO',
    'SOBRE O JOGO',
    '关于游戏',
    'ゲームについて'
  ],
  'About DragonHaven': [
    'Über DragonHaven',
    'Acerca de DragonHaven',
    'À propos de DragonHaven',
    'Informazioni su DragonHaven',
    'Sobre DragonHaven',
    '关于 DragonHaven',
    'DragonHavenについて'
  ],
  'Achievement unlocked!': [
    'Erfolg freigeschaltet!',
    '¡Logro desbloqueado!',
    'Succès débloqué !',
    'Obiettivo sbloccato!',
    'Conquista desbloqueada!',
    '成就已解锁！',
    '実績を解除しました！'
  ],
  'Activate egg': [
    'Ei aktivieren',
    'Activar huevo',
    'Activer l’œuf',
    'Attiva uovo',
    'Ativar ovo',
    '启用龙蛋',
    '卵を育てる'
  ],
  'Active expeditions': [
    'Aktive Expeditionen',
    'Expediciones activas',
    'Expéditions en cours',
    'Spedizioni attive',
    'Expedições ativas',
    '进行中的远征',
    '進行中の遠征'
  ],
  'Add a keeper': [
    'Drachenhüter hinzufügen',
    'Añadir cuidador',
    'Ajouter un gardien',
    'Aggiungi custode',
    'Adicionar guardião',
    '添加龙守护者',
    'キーパーを追加'
  ],
  'Adventure rewards will appear here and on Adventure.': [
    'Abenteuerbelohnungen erscheinen hier und im Bereich Abenteuer.',
    'Las recompensas de aventura aparecerán aquí y en Aventura.',
    'Les récompenses d’aventure apparaîtront ici et dans Aventure.',
    'Le ricompense delle avventure appariranno qui e in Avventura.',
    'As recompensas de aventura aparecerão aqui e em Aventura.',
    '冒险奖励会显示在这里和“冒险”页面中。',
    '冒険の報酬は、ここ及び「冒険」に表示されます。'
  ],
  'Adventure rewards are stored here.': [
    'Abenteuerbelohnungen werden hier aufbewahrt.',
    'Las recompensas de aventura se guardan aquí.',
    'Les récompenses d’aventure sont conservées ici.',
    'Le ricompense delle avventure vengono conservate qui.',
    'As recompensas de aventura ficam guardadas aqui.',
    '冒险奖励会存放在这里。',
    '冒険の報酬はここに保管されます。'
  ],
  'Adventure started.': [
    'Abenteuer gestartet.',
    'Aventura iniciada.',
    'Aventure lancée.',
    'Avventura iniziata.',
    'Aventura iniciada.',
    '冒险已开始。',
    '冒険を開始しました。'
  ],
  'Adventuring': [
    'Auf Abenteuer',
    'De aventura',
    'En aventure',
    'In avventura',
    'Em aventura',
    '冒险中',
    '冒険中'
  ],
  'All': ['Alle', 'Todo', 'Tout', 'Tutto', 'Tudo', '全部', 'すべて'],
  'An egg cannot go adventuring.': [
    'Ein Ei kann nicht auf Abenteuer gehen.',
    'Un huevo no puede ir de aventura.',
    'Un œuf ne peut pas partir à l’aventure.',
    'Un uovo non può partire all’avventura.',
    'Um ovo não pode partir em aventura.',
    '龙蛋不能去冒险。',
    '卵は冒険に出られません。'
  ],
  'Android download link copied.': [
    'Android-Downloadlink kopiert.',
    'Enlace de descarga de Android copiado.',
    'Lien de téléchargement Android copié.',
    'Link per il download Android copiato.',
    'Link de download do Android copiado.',
    'Android 下载链接已复制。',
    'Androidのダウンロードリンクをコピーしました。'
  ],
  'Arcana is currently leading.': [
    'Arcana liegt derzeit vorn.',
    'Arcana está en cabeza.',
    'Arcana est actuellement en tête.',
    'Arcana è attualmente in testa.',
    'Arcana está na frente.',
    '奥术目前领先。',
    '現在はアルカナが優勢です。'
  ],
  'Archived permanently; it may return for weekly visits.': [
    'Dauerhaft archiviert; der Drache kann zu Wochenbesuchen zurückkehren.',
    'Se archivará para siempre, aunque puede volver de visita cada semana.',
    'Archivé définitivement ; il pourra revenir chaque semaine.',
    'Archiviato per sempre; potrà tornare per visite settimanali.',
    'Arquivado permanentemente; poderá voltar em visitas semanais.',
    '永久归档；它可能会每周回来探望。',
    '永久に記録され、週に一度会いに戻ってくることがあります。'
  ],
  'Ascension complete': [
    'Aufstieg abgeschlossen',
    'Ascensión completada',
    'Ascension terminée',
    'Ascensione completata',
    'Ascensão concluída',
    '升华完成',
    '昇華完了'
  ],
  'Ascension paths': [
    'Aufstiegspfade',
    'Sendas de ascensión',
    'Voies d’ascension',
    'Percorsi di ascensione',
    'Caminhos da ascensão',
    '升华之路',
    '昇華の道'
  ],
  'Ascended': [
    'Erhaben',
    'Ascendido',
    'Transcendé',
    'Asceso',
    'Ascendido',
    '升华龙',
    '昇華竜'
  ],
  'Audio': ['Audio', 'Audio', 'Audio', 'Audio', 'Áudio', '音频', 'オーディオ'],
  'Begin hatching': [
    'Schlüpfen beginnen',
    'Iniciar eclosión',
    'Commencer l’éclosion',
    'Inizia la schiusa',
    'Iniciar eclosão',
    '开始孵化',
    '孵化を始める'
  ],
  'Both keepers must offer at least one egg, chest or item and confirm the final trade.':
      [
    'Beide Hüter müssen mindestens ein Ei, eine Truhe oder einen Gegenstand anbieten und den endgültigen Tausch bestätigen.',
    'Ambos cuidadores deben ofrecer al menos un huevo, cofre u objeto y confirmar el intercambio final.',
    'Les deux gardiens doivent proposer au moins un œuf, un coffre ou un objet et confirmer l’échange final.',
    'Entrambi i custodi devono offrire almeno un uovo, un forziere o un oggetto e confermare lo scambio finale.',
    'Os dois guardiões devem oferecer pelo menos um ovo, baú ou item e confirmar a troca final.',
    '双方守护者都必须提供至少一颗龙蛋、一个宝箱或一件物品，并确认最终交易。',
    '双方のキーパーが卵、宝箱、アイテムのいずれかを1つ以上提示し、最終的な交換を承認する必要があります。'
  ],
  'Both settings react immediately and are stored independently for this local account.':
      [
    'Beide Einstellungen wirken sofort und werden für dieses lokale Konto getrennt gespeichert.',
    'Ambos ajustes se aplican al instante y se guardan por separado para esta cuenta local.',
    'Les deux réglages s’appliquent immédiatement et sont enregistrés séparément pour ce compte local.',
    'Entrambe le impostazioni hanno effetto immediato e vengono salvate separatamente per questo account locale.',
    'As duas configurações têm efeito imediato e são salvas separadamente para esta conta local.',
    '两项设置都会立即生效，并分别保存在此本地账户中。',
    'どちらの設定もすぐに反映され、このローカルアカウントに個別に保存されます。'
  ],
  'Build a home that grows with your dragon.': [
    'Baue ein Zuhause, das mit deinem Drachen wächst.',
    'Construye un hogar que crezca con tu dragón.',
    'Construis un foyer qui grandit avec ton dragon.',
    'Costruisci una casa che cresca con il tuo drago.',
    'Construa um lar que cresça com seu dragão.',
    '建造一个与龙共同成长的家。',
    'ドラゴンとともに成長する住まいを作りましょう。'
  ],
  'Build room': [
    'Raum bauen',
    'Construir habitación',
    'Construire la pièce',
    'Costruisci stanza',
    'Construir cômodo',
    '建造房间',
    '部屋を建てる'
  ],
  'Built and ready': [
    'Gebaut und bereit',
    'Construido y listo',
    'Construit et prêt',
    'Costruita e pronta',
    'Construído e pronto',
    '已建成',
    '建築済み'
  ],
  'Built in': [
    'Entstanden',
    'Creada en',
    'Créée en',
    'Realizzata nel',
    'Criado em',
    '构建年份',
    '制作年'
  ],
  'Buy gems': [
    'Edelsteine kaufen',
    'Comprar gemas',
    'Acheter des gemmes',
    'Compra gemme',
    'Comprar gemas',
    '购买宝石',
    'ジェムを購入'
  ],
  'Buy me a coffee': [
    'Spendiere mir einen Kaffee',
    'Invítame a un café',
    'Offrez-moi un café',
    'Offrimi un caffè',
    'Pague-me um café',
    '请我喝杯咖啡',
    'コーヒーで応援'
  ],
  'Cancel': [
    'Abbrechen',
    'Cancelar',
    'Annuler',
    'Annulla',
    'Cancelar',
    '取消',
    'キャンセル'
  ],
  'Chests': ['Truhen', 'Cofres', 'Coffres', 'Forzieri', 'Baús', '宝箱', '宝箱'],
  'Choose a name': [
    'Namen wählen',
    'Elige un nombre',
    'Choisir un nom',
    'Scegli un nome',
    'Escolha um nome',
    '选择名字',
    '名前を選ぶ'
  ],
  'Choose a name first.': [
    'Wähle zuerst einen Namen.',
    'Elige primero un nombre.',
    'Choisis d’abord un nom.',
    'Scegli prima un nome.',
    'Escolha um nome primeiro.',
    '请先选择一个名字。',
    'まず名前を決めてください。'
  ],
  'Choose a room type': [
    'Raumtyp wählen',
    'Elige un tipo de habitación',
    'Choisir un type de pièce',
    'Scegli un tipo di stanza',
    'Escolha um tipo de cômodo',
    '选择房间类型',
    '部屋の種類を選ぶ'
  ],
  'Claim the Starter Egg': [
    'Starter-Ei annehmen',
    'Recoger el Huevo Inicial',
    'Récupérer l’Œuf de départ',
    'Ottieni l’Uovo iniziale',
    'Receber o Ovo Inicial',
    '领取初始龙蛋',
    '最初の卵を受け取る'
  ],
  'Clear search': [
    'Suche löschen',
    'Borrar búsqueda',
    'Effacer la recherche',
    'Cancella ricerca',
    'Limpar pesquisa',
    '清除搜索',
    '検索を消去'
  ],
  'Cloud Sanctuary': [
    'Wolkenrefugium',
    'Santuario de las Nubes',
    'Sanctuaire des Nuages',
    'Santuario delle Nuvole',
    'Santuário das Nuvens',
    '云端圣所',
    '雲の聖域'
  ],
  'Dragon Chest': [
    'Drachentruhe',
    'Cofre de Dragón',
    'Coffre du Dragon',
    'Forziere del Drago',
    'Baú de Dragão',
    '巨龙宝箱',
    'ドラゴンの宝箱'
  ],
  'Coin furniture': [
    'Münzmöbel',
    'Muebles por monedas',
    'Meubles contre des pièces',
    'Mobili con monete',
    'Móveis por moedas',
    '金币家具',
    'コイン家具'
  ],
  'Collect': [
    'Einsammeln',
    'Recoger',
    'Récupérer',
    'Raccogli',
    'Coletar',
    '领取',
    '受け取る'
  ],
  'Collect furniture for every dragon room.': [
    'Sammle Möbel für jedes Drachenzimmer.',
    'Colecciona muebles para todas las habitaciones de dragones.',
    'Collectionne des meubles pour chaque pièce des dragons.',
    'Colleziona mobili per ogni stanza dei draghi.',
    'Colecione móveis para cada cômodo dos dragões.',
    '为每个龙房间收集家具。',
    'すべてのドラゴン部屋に置く家具を集めましょう。'
  ],
  'Comfort': [
    'Komfort',
    'Comodidad',
    'Confort',
    'Comfort',
    'Conforto',
    '舒适',
    '快適さ'
  ],
  'Common': ['Gewöhnlich', 'Común', 'Commun', 'Comune', 'Comum', '普通', 'コモン'],
  'Compact view': [
    'Kompaktansicht',
    'Vista compacta',
    'Vue compacte',
    'Vista compatta',
    'Visualização compacta',
    '紧凑视图',
    'コンパクト表示'
  ],
  'Connect online friends before joining a Group Adventure.': [
    'Verbinde dich mit Online-Freunden, bevor du einem Gruppenabenteuer beitrittst.',
    'Conecta amigos en línea antes de unirte a una aventura grupal.',
    'Connecte des amis en ligne avant de rejoindre une aventure de groupe.',
    'Collega amici online prima di partecipare a un’avventura di gruppo.',
    'Conecte amigos online antes de entrar em uma aventura em grupo.',
    '参加团队冒险前，请先连接在线好友。',
    'グループ冒険に参加する前に、オンラインのフレンドと接続してください。'
  ],
  'Copy download link': [
    'Downloadlink kopieren',
    'Copiar enlace de descarga',
    'Copier le lien de téléchargement',
    'Copia link di download',
    'Copiar link de download',
    '复制下载链接',
    'ダウンロードリンクをコピー'
  ],
  'Copy one permanent Android download link for someone else, or open it to install the latest release over this app. Your progress stays safe.':
      [
    'Kopiere einen dauerhaften Android-Downloadlink für andere oder öffne ihn, um die neueste Version über dieser App zu installieren. Dein Fortschritt bleibt erhalten.',
    'Copia un enlace permanente de descarga para Android o ábrelo para instalar la última versión sobre esta aplicación. Tu progreso se conserva.',
    'Copiez un lien Android permanent ou ouvrez-le pour installer la dernière version par-dessus cette application. Votre progression est conservée.',
    'Copia un link Android permanente oppure aprilo per installare l’ultima versione sopra questa app. I progressi restano al sicuro.',
    'Copie um link permanente de download para Android ou abra-o para instalar a versão mais recente sobre este app. Seu progresso fica seguro.',
    '复制永久 Android 下载链接以便分享，或打开链接安装最新版。你的进度会安全保留。',
    'Android用の固定ダウンロードリンクを共有用にコピーするか、開いて最新版を上書きインストールできます。進行状況は保持されます。'
  ],
  'Created by': [
    'Erstellt von',
    'Creado por',
    'Créé par',
    'Creato da',
    'Criado por',
    '作者',
    '制作者'
  ],
  'Crystal Grotto': [
    'Kristallgrotte',
    'Gruta de Cristal',
    'Grotte de Cristal',
    'Grotta di Cristallo',
    'Gruta de Cristal',
    '水晶洞窟',
    '水晶の洞窟'
  ],
  'Curious': [
    'Neugierig',
    'Curioso',
    'Curieux',
    'Curioso',
    'Curioso',
    '好奇',
    '好奇心旺盛'
  ],
  'Decorate': [
    'Dekorieren',
    'Decorar',
    'Décorer',
    'Decora',
    'Decorar',
    '装饰',
    '飾りつける'
  ],
  'Discard': [
    'Verwerfen',
    'Descartar',
    'Jeter',
    'Scarta',
    'Descartar',
    '丢弃',
    '破棄'
  ],
  'Discard egg': [
    'Ei verwerfen',
    'Descartar huevo',
    'Jeter l’œuf',
    'Scarta uovo',
    'Descartar ovo',
    '丢弃龙蛋',
    '卵を破棄'
  ],
  'Discard one chest': [
    'Eine Truhe verwerfen',
    'Descartar un cofre',
    'Jeter un coffre',
    'Scarta un forziere',
    'Descartar um baú',
    '丢弃一个宝箱',
    '宝箱を1つ破棄'
  ],
  'Discard this Mysterious Egg?': [
    'Dieses geheimnisvolle Ei verwerfen?',
    '¿Descartar este Huevo Misterioso?',
    'Jeter cet Œuf mystérieux ?',
    'Scartare questo Uovo misterioso?',
    'Descartar este Ovo Misterioso?',
    '要丢弃这颗神秘龙蛋吗？',
    'この不思議な卵を破棄しますか？'
  ],
  'Dismiss': [
    'Wegschicken',
    'Descartar',
    'Ignorer',
    'Congeda',
    'Dispensar',
    '取消任务',
    '見送る'
  ],
  'Download or update': [
    'Herunterladen oder aktualisieren',
    'Descargar o actualizar',
    'Télécharger ou mettre à jour',
    'Scarica o aggiorna',
    'Baixar ou atualizar',
    '下载或更新',
    'ダウンロード／更新'
  ],
  'Dragon care': [
    'Drachenpflege',
    'Cuidado del dragón',
    'Soins du dragon',
    'Cura del drago',
    'Cuidados do dragão',
    '龙的照料',
    'ドラゴンのお世話'
  ],
  'Dragon keeper': [
    'Drachenhüter',
    'Cuidador de dragones',
    'Gardien de dragons',
    'Custode dei draghi',
    'Guardião de dragões',
    '龙守护者',
    'ドラゴンキーパー'
  ],
  'Dragon name': [
    'Drachenname',
    'Nombre del dragón',
    'Nom du dragon',
    'Nome del drago',
    'Nome do dragão',
    '龙的名字',
    'ドラゴンの名前'
  ],
  'Dragon room': [
    'Drachenzimmer',
    'Habitación del dragón',
    'Pièce des dragons',
    'Stanza dei draghi',
    'Cômodo dos dragões',
    '龙房间',
    'ドラゴンの部屋'
  ],
  'Dragon sanctuary': [
    'Drachenrefugium',
    'Santuario de dragones',
    'Sanctuaire des dragons',
    'Santuario dei draghi',
    'Santuário dos dragões',
    '龙之庇护所',
    'ドラゴンの聖域'
  ],
  'DragonHaven logo': [
    'DragonHaven-Logo',
    'Logotipo de DragonHaven',
    'Logo de DragonHaven',
    'Logo di DragonHaven',
    'Logo do DragonHaven',
    'DragonHaven 标志',
    'DragonHavenのロゴ'
  ],
  'EDIT MODE': [
    'BEARBEITUNG',
    'MODO EDICIÓN',
    'MODE ÉDITION',
    'MODALITÀ MODIFICA',
    'MODO DE EDIÇÃO',
    '编辑模式',
    '編集モード'
  ],
  'Each room is permanent and can be decorated independently.': [
    'Jeder Raum bleibt dauerhaft bestehen und kann einzeln eingerichtet werden.',
    'Cada habitación es permanente y puede decorarse por separado.',
    'Chaque pièce est permanente et peut être décorée séparément.',
    'Ogni stanza è permanente e può essere decorata separatamente.',
    'Cada cômodo é permanente e pode ser decorado separadamente.',
    '每个房间都会永久保留，并可单独装饰。',
    '各部屋はずっと残り、それぞれ別々に飾れます。'
  ],
  'Edit keeper name': [
    'Hüternamen ändern',
    'Editar nombre del cuidador',
    'Modifier le nom du gardien',
    'Modifica nome del custode',
    'Editar nome do guardião',
    '修改守护者名字',
    'キーパー名を編集'
  ],
  'Edit name': [
    'Namen ändern',
    'Editar nombre',
    'Modifier le nom',
    'Modifica nome',
    'Editar nome',
    '修改名字',
    '名前を編集'
  ],
  'Egg': ['Ei', 'Huevo', 'Œuf', 'Uovo', 'Ovo', '龙蛋', '卵'],
  'Egg moved to the rooftop nest.': [
    'Das Ei wurde ins Dachnest gebracht.',
    'El huevo se trasladó al nido de la azotea.',
    'L’œuf a été déplacé dans le nid du toit.',
    'L’uovo è stato spostato nel nido sul tetto.',
    'O ovo foi levado para o ninho no telhado.',
    '龙蛋已移至屋顶巢穴。',
    '卵を屋上の巣へ移しました。'
  ],
  'Egg inventory': [
    'Eierinventar',
    'Inventario de huevos',
    'Inventaire des œufs',
    'Inventario delle uova',
    'Inventário de ovos',
    '龙蛋库存',
    '卵の所持品'
  ],
  'Eggs': ['Eier', 'Huevos', 'Œufs', 'Uova', 'Ovos', '龙蛋', '卵'],
  'Energy': ['Energie', 'Energía', 'Énergie', 'Energia', 'Energia', '精力', '元気'],
  'Enjoying DragonHaven? You can support its further development through Ko-fi.':
      [
    'Gefällt dir DragonHaven? Über Ko-fi kannst du die weitere Entwicklung unterstützen.',
    '¿Te gusta DragonHaven? Puedes apoyar su desarrollo en Ko-fi.',
    'Vous aimez DragonHaven ? Soutenez son développement sur Ko-fi.',
    'Ti piace DragonHaven? Puoi sostenerne lo sviluppo su Ko-fi.',
    'Está gostando do DragonHaven? Apoie o desenvolvimento pelo Ko-fi.',
    '喜欢 DragonHaven 吗？你可以通过 Ko-fi 支持后续开发。',
    'DragonHavenを楽しんでいますか？Ko-fiから今後の開発を支援できます。'
  ],
  'Event, code and returning-dragon adventures stay available for 48 hours.': [
    'Event-, Code- und Rückkehrer-Abenteuer bleiben 48 Stunden verfügbar.',
    'Las aventuras de evento, código y dragones que regresan duran 48 horas.',
    'Les aventures d’événement, de code et de dragons de retour restent disponibles 48 heures.',
    'Le avventure evento, codice e drago di ritorno restano disponibili per 48 ore.',
    'Aventuras de evento, código e dragão retornando ficam disponíveis por 48 horas.',
    '活动、兑换码和回归龙冒险会保留 48 小时。',
    'イベント、コード、帰還ドラゴンの冒険は48時間有効です。'
  ],
  'Evolve now': [
    'Jetzt entwickeln',
    'Evolucionar ahora',
    'Évoluer maintenant',
    'Evolvi ora',
    'Evoluir agora',
    '立即进化',
    '今すぐ進化'
  ],
  'Expand the sanctuary': [
    'Refugium erweitern',
    'Ampliar el santuario',
    'Agrandir le sanctuaire',
    'Espandi il santuario',
    'Expandir o santuário',
    '扩建庇护所',
    '聖域を拡張'
  ],
  'Finish': ['Fertig', 'Terminar', 'Terminer', 'Fine', 'Concluir', '完成', '完了'],
  'For example: Ember': [
    'Zum Beispiel: Ember',
    'Por ejemplo: Ember',
    'Par exemple : Ember',
    'Per esempio: Ember',
    'Por exemplo: Ember',
    '例如：Ember',
    '例：Ember'
  ],
  'For example: Rick': [
    'Zum Beispiel: Rick',
    'Por ejemplo: Rick',
    'Par exemple : Rick',
    'Per esempio: Rick',
    'Por exemplo: Rick',
    '例如：Rick',
    '例：Rick'
  ],
  'Furniture': ['Möbel', 'Muebles', 'Meubles', 'Mobili', 'Móveis', '家具', '家具'],
  'Gem furniture': [
    'Edelsteinmöbel',
    'Muebles por gemas',
    'Meubles contre des gemmes',
    'Mobili con gemme',
    'Móveis por gemas',
    '宝石家具',
    'ジェム家具'
  ],
  'Gold Chest': [
    'Goldtruhe',
    'Cofre de Oro',
    'Coffre en Or',
    'Forziere d’Oro',
    'Baú de Ouro',
    '黄金宝箱',
    '金の宝箱'
  ],
  'GitHub returned unexpected release data.': [
    'GitHub hat unerwartete Releasedaten zurückgegeben.',
    'GitHub devolvió datos de versión inesperados.',
    'GitHub a renvoyé des données de version inattendues.',
    'GitHub ha restituito dati di versione imprevisti.',
    'O GitHub retornou dados de versão inesperados.',
    'GitHub 返回了异常的版本数据。',
    'GitHubから予期しないリリースデータが返されました。'
  ],
  'Good afternoon': [
    'Guten Tag',
    'Buenas tardes',
    'Bonjour',
    'Buon pomeriggio',
    'Boa tarde',
    '下午好',
    'こんにちは'
  ],
  'Good evening': [
    'Guten Abend',
    'Buenas noches',
    'Bonsoir',
    'Buonasera',
    'Boa noite',
    '晚上好',
    'こんばんは'
  ],
  'Good morning': [
    'Guten Morgen',
    'Buenos días',
    'Bonjour',
    'Buongiorno',
    'Bom dia',
    '早上好',
    'おはようございます'
  ],
  'Greenery': [
    'Grünpflanzen',
    'Vegetación',
    'Verdure',
    'Piante',
    'Plantas',
    '绿植',
    '植物'
  ],
  'Group': ['Gruppe', 'Grupo', 'Groupe', 'Gruppo', 'Grupo', '团队', 'グループ'],
  'HERE': ['HIER', 'AQUÍ', 'ICI', 'QUI', 'AQUI', '当前房间', 'この部屋'],
  'Hearth room': [
    'Feuerzimmer',
    'Sala del Hogar',
    'Salle du Foyer',
    'Sala del Focolare',
    'Sala da Lareira',
    '炉火房',
    '暖炉の間'
  ],
  'Hatchling': [
    'Schlüpfling',
    'Cría',
    'Nouveau-né',
    'Cucciolo',
    'Filhote',
    '幼龙',
    '幼竜'
  ],
  'Hidden chest': [
    'Verborgene Truhe',
    'Cofre oculto',
    'Coffre caché',
    'Forziere nascosto',
    'Baú oculto',
    '隐藏宝箱',
    '隠された宝箱'
  ],
  'House inventory': [
    'Hausinventar',
    'Inventario de la casa',
    'Inventaire de la maison',
    'Inventario della casa',
    'Inventário da casa',
    '房屋库存',
    '家の持ち物'
  ],
  'House item': [
    'Hausgegenstand',
    'Objeto de la casa',
    'Objet de maison',
    'Oggetto per la casa',
    'Item da casa',
    '房屋物品',
    '家のアイテム'
  ],
  'House shop': [
    'Hausladen',
    'Tienda de la casa',
    'Boutique de la maison',
    'Negozio della casa',
    'Loja da casa',
    '家居商店',
    '家具ショップ'
  ],
  'INVENTORY': [
    'INVENTAR',
    'INVENTARIO',
    'INVENTAIRE',
    'INVENTARIO',
    'INVENTÁRIO',
    '库存',
    '持ち物'
  ],
  'In Tower': [
    'Im Turm',
    'En la Torre',
    'Dans la Tour',
    'Nella Torre',
    'Na Torre',
    '在塔中',
    '塔にいる'
  ],
  'Incubate': [
    'Ausbrüten',
    'Incubar',
    'Incuber',
    'Incuba',
    'Incubar',
    '孵化',
    '孵す'
  ],
  'Its unopened contents will be lost.': [
    'Der ungeöffnete Inhalt geht verloren.',
    'Su contenido sin abrir se perderá.',
    'Son contenu non ouvert sera perdu.',
    'Il contenuto non aperto andrà perduto.',
    'O conteúdo fechado será perdido.',
    '其中未开启的内容将会丢失。',
    '未開封の中身は失われます。'
  ],
  'Joy': ['Freude', 'Alegría', 'Joie', 'Gioia', 'Alegria', '快乐', '喜び'],
  'Keep this name': [
    'Namen behalten',
    'Guardar este nombre',
    'Garder ce nom',
    'Conferma questo nome',
    'Manter este nome',
    '保留此名字',
    'この名前にする'
  ],
  'Ko-fi could not be opened or copied.': [
    'Ko-fi konnte weder geöffnet noch kopiert werden.',
    'No se pudo abrir ni copiar Ko-fi.',
    'Impossible d’ouvrir ou de copier Ko-fi.',
    'Impossibile aprire o copiare Ko-fi.',
    'Não foi possível abrir nem copiar o Ko-fi.',
    '无法打开或复制 Ko-fi 链接。',
    'Ko-fiを開くこともコピーすることもできませんでした。'
  ],
  'Ko-fi could not be opened. The link was copied instead.': [
    'Ko-fi konnte nicht geöffnet werden. Der Link wurde stattdessen kopiert.',
    'No se pudo abrir Ko-fi. Se copió el enlace.',
    'Impossible d’ouvrir Ko-fi. Le lien a été copié.',
    'Impossibile aprire Ko-fi. Il link è stato copiato.',
    'Não foi possível abrir o Ko-fi. O link foi copiado.',
    '无法打开 Ko-fi，链接已复制。',
    'Ko-fiを開けなかったため、リンクをコピーしました。'
  ],
  'List view': [
    'Listenansicht',
    'Vista de lista',
    'Vue en liste',
    'Vista elenco',
    'Visualização em lista',
    '列表视图',
    'リスト表示'
  ],
  'Listen to the mysterious egg': [
    'Dem geheimnisvollen Ei lauschen',
    'Escuchar el huevo misterioso',
    'Écouter l’œuf mystérieux',
    'Ascolta l’uovo misterioso',
    'Ouvir o ovo misterioso',
    '倾听神秘龙蛋',
    '不思議な卵に耳を澄ます'
  ],
  'Long': ['Lang', 'Larga', 'Longue', 'Lunga', 'Longa', '长期', 'ロング'],
  'Magic': ['Magie', 'Magia', 'Magie', 'Magia', 'Magia', '魔法', '魔法'],
  'Maximum height reached': [
    'Maximale Höhe erreicht',
    'Altura máxima alcanzada',
    'Hauteur maximale atteinte',
    'Altezza massima raggiunta',
    'Altura máxima alcançada',
    '已达最高层数',
    '最高階に到達'
  ],
  'Might is currently leading.': [
    'Macht liegt derzeit vorn.',
    'Poder está en cabeza.',
    'Puissance est actuellement en tête.',
    'Potenza è attualmente in testa.',
    'Poder está na frente.',
    '力量目前领先。',
    '現在はマイトが優勢です。'
  ],
  'Moon garden': [
    'Mondgarten',
    'Jardín Lunar',
    'Jardin Lunaire',
    'Giardino Lunare',
    'Jardim Lunar',
    '月光花园',
    '月の庭園'
  ],
  'My dragons': [
    'Meine Drachen',
    'Mis dragones',
    'Mes dragons',
    'I miei draghi',
    'Meus dragões',
    '我的龙',
    'マイドラゴン'
  ],
  'Mysterious Egg': [
    'Geheimnisvolles Ei',
    'Huevo Misterioso',
    'Œuf mystérieux',
    'Uovo misterioso',
    'Ovo Misterioso',
    '神秘龙蛋',
    '不思議な卵'
  ],
  'Mythical Chest': [
    'Mythische Truhe',
    'Cofre Mítico',
    'Coffre Mythique',
    'Forziere Mitico',
    'Baú Mítico',
    '神话宝箱',
    '神話の宝箱'
  ],
  'New evolution!': [
    'Neue Entwicklung!',
    '¡Nueva evolución!',
    'Nouvelle évolution !',
    'Nuova evoluzione!',
    'Nova evolução!',
    '新的进化！',
    '新たな進化！'
  ],
  'Name your dragon': [
    'Gib deinem Drachen einen Namen',
    'Ponle nombre a tu dragón',
    'Nomme ton dragon',
    'Dai un nome al tuo drago',
    'Dê um nome ao seu dragão',
    '为你的龙命名',
    'ドラゴンに名前をつける'
  ],
  'Nest room': [
    'Nestzimmer',
    'Sala del Nido',
    'Salle du Nid',
    'Sala del Nido',
    'Sala do Ninho',
    '巢穴房',
    '巣の間'
  ],
  'No Mysterious Eggs in your inventory yet.': [
    'Du hast noch keine geheimnisvollen Eier im Inventar.',
    'Aún no hay Huevos Misteriosos en tu inventario.',
    'Aucun Œuf mystérieux dans votre inventaire pour le moment.',
    'Non ci sono ancora Uova misteriose nel tuo inventario.',
    'Ainda não há Ovos Misteriosos no seu inventário.',
    '你的库存中还没有神秘龙蛋。',
    '所持品にはまだ不思議な卵がありません。'
  ],
  'No internet connection. Please try again later.': [
    'Keine Internetverbindung. Bitte versuche es später erneut.',
    'Sin conexión a Internet. Inténtalo de nuevo más tarde.',
    'Aucune connexion Internet. Réessayez plus tard.',
    'Nessuna connessione Internet. Riprova più tardi.',
    'Sem conexão com a internet. Tente novamente mais tarde.',
    '没有网络连接，请稍后再试。',
    'インターネットに接続できません。後でもう一度お試しください。'
  ],
  'No public GitHub Release has been published yet.': [
    'Es wurde noch kein öffentliches GitHub-Release veröffentlicht.',
    'Aún no se ha publicado ninguna versión pública en GitHub.',
    'Aucune version publique n’a encore été publiée sur GitHub.',
    'Non è ancora stata pubblicata alcuna release pubblica su GitHub.',
    'Nenhuma versão pública foi publicada no GitHub ainda.',
    '尚未发布公开的 GitHub 版本。',
    '公開GitHubリリースはまだありません。'
  ],
  'No waiting eggs. Rare chest drops will appear here.': [
    'Keine wartenden Eier. Seltene Eier aus Truhen erscheinen hier.',
    'No hay huevos en espera. Aquí aparecerán los raros que encuentres en cofres.',
    'Aucun œuf en attente. Les rares œufs trouvés dans des coffres apparaîtront ici.',
    'Nessun uovo in attesa. Le rare uova trovate nei forzieri appariranno qui.',
    'Nenhum ovo em espera. Ovos raros encontrados em baús aparecerão aqui.',
    '没有等待中的龙蛋。宝箱中掉落的稀有龙蛋会出现在这里。',
    '待機中の卵はありません。宝箱から出た珍しい卵がここに並びます。'
  ],
  'Not enough coins for this floor.': [
    'Nicht genug Münzen für diese Etage.',
    'No tienes suficientes monedas para este piso.',
    'Pas assez de pièces pour cet étage.',
    'Monete insufficienti per questo piano.',
    'Moedas insuficientes para este andar.',
    '金币不足，无法建造此楼层。',
    'この階を建てるコインが足りません。'
  ],
  'Not ready yet': [
    'Noch nicht bereit',
    'Aún no está listo',
    'Pas encore prêt',
    'Non ancora pronto',
    'Ainda não está pronto',
    '尚未准备好',
    'まだ準備中'
  ],
  'Not yet': [
    'Noch nicht',
    'Todavía no',
    'Pas encore',
    'Non ancora',
    'Ainda não',
    '暂不',
    'まだしない'
  ],
  'OTHER ROOM': [
    'ANDERER RAUM',
    'OTRA HABITACIÓN',
    'AUTRE PIÈCE',
    'ALTRA STANZA',
    'OUTRO CÔMODO',
    '其他房间',
    '別の部屋'
  ],
  'Open tip form': [
    'Trinkgeldseite öffnen',
    'Abrir página de apoyo',
    'Ouvrir la page de soutien',
    'Apri la pagina di supporto',
    'Abrir página de apoio',
    '打开赞助页面',
    '支援ページを開く'
  ],
  'Opening the latest DragonHaven download…': [
    'Der neueste DragonHaven-Download wird geöffnet …',
    'Abriendo la descarga más reciente de DragonHaven…',
    'Ouverture du dernier téléchargement de DragonHaven…',
    'Apertura dell’ultimo download di DragonHaven…',
    'Abrindo o download mais recente do DragonHaven…',
    '正在打开最新的 DragonHaven 下载……',
    '最新のDragonHavenダウンロードを開いています…'
  ],
  'Open': ['Öffnen', 'Abrir', 'Ouvrir', 'Apri', 'Abrir', '打开', '開く'],
  'Payment via PayPal': [
    'Zahlung über PayPal',
    'Pago mediante PayPal',
    'Paiement via PayPal',
    'Pagamento tramite PayPal',
    'Pagamento via PayPal',
    '通过 PayPal 支付',
    'PayPalで支払う'
  ],
  'Place': [
    'Platzieren',
    'Colocar',
    'Placer',
    'Posiziona',
    'Posicionar',
    '摆放',
    '配置'
  ],
  'Placed': [
    'Platziert',
    'Colocado',
    'Placé',
    'Posizionato',
    'Posicionado',
    '已摆放',
    '配置済み'
  ],
  'Possible hatchling': [
    'Mögliches Jungtier',
    'Posible cría',
    'Nouveau-né possible',
    'Possibile cucciolo',
    'Possível filhote',
    '可能的幼龙',
    '孵化する可能性のある幼竜'
  ],
  'Purchased items are always yours.': [
    'Gekaufte Gegenstände gehören dauerhaft dir.',
    'Los objetos comprados siempre serán tuyos.',
    'Les objets achetés restent toujours à toi.',
    'Gli oggetti acquistati restano sempre tuoi.',
    'Itens comprados são seus para sempre.',
    '已购买的物品会永久归你所有。',
    '購入したアイテムはずっとあなたのものです。'
  ],
  'Purchases are disabled until Google Play product IDs and server-side receipt validation are configured.':
      [
    'Käufe sind deaktiviert, bis Google-Play-Produkt-IDs und die serverseitige Belegprüfung eingerichtet sind.',
    'Las compras están desactivadas hasta configurar los ID de producto de Google Play y la validación de recibos en el servidor.',
    'Les achats sont désactivés jusqu’à la configuration des identifiants Google Play et de la validation des reçus côté serveur.',
    'Gli acquisti sono disattivati finché non saranno configurati gli ID prodotto Google Play e la convalida delle ricevute sul server.',
    'As compras estão desativadas até configurar IDs de produto do Google Play e validação de recibos no servidor.',
    '在配置 Google Play 商品 ID 和服务器收据验证前，购买功能不可用。',
    'Google Playの商品IDとサーバー側のレシート検証が設定されるまで購入は無効です。'
  ],
  'Raise': ['Aufziehen', 'Criar', 'Élever', 'Alleva', 'Criar', '培育', '育てる'],
  'Raise this egg?': [
    'Dieses Ei aufziehen?',
    '¿Criar este huevo?',
    'Élever cet œuf ?',
    'Allevare questo uovo?',
    'Criar este ovo?',
    '要培育这颗龙蛋吗？',
    'この卵を育てますか？'
  ],
  'Raise wonder. Build a home. Fill the Draconomicon.': [
    'Zieh Wunder groß. Bau ein Zuhause. Fülle das Draconomicon.',
    'Cría maravillas. Construye un hogar. Completa el Draconomicon.',
    'Élève l’émerveillement. Bâtis un foyer. Remplis le Draconomicon.',
    'Coltiva la meraviglia. Costruisci una casa. Completa il Draconomicon.',
    'Cultive maravilhas. Construa um lar. Complete o Draconomicon.',
    '培育奇迹，建造家园，填满《龙之秘典》。',
    '驚きを育て、住まいを築き、ドラコノミコンを満たそう。'
  ],
  'Rare': ['Selten', 'Raro', 'Rare', 'Raro', 'Raro', '稀有', 'レア'],
  'Read-only visits can show the favorite dragon, rooms and achievements—including locked ??? secrets.':
      [
    'Bei Besuchen können Lieblingsdrache, Räume und Erfolge nur angesehen werden – auch gesperrte ???-Geheimnisse.',
    'Las visitas de solo lectura muestran el dragón favorito, las habitaciones y los logros, incluidos secretos ??? bloqueados.',
    'Les visites en lecture seule peuvent montrer le dragon favori, les pièces et les succès, y compris les secrets ??? verrouillés.',
    'Le visite in sola lettura mostrano il drago preferito, le stanze e gli obiettivi, compresi i segreti ??? bloccati.',
    'Visitas somente leitura mostram o dragão favorito, cômodos e conquistas, incluindo segredos ??? bloqueados.',
    '只读访问可以展示最喜爱的龙、房间和成就，包括尚未解锁的“???”秘密。',
    '閲覧専用の訪問では、お気に入りのドラゴン、部屋、実績（未解除の「???」も含む）を確認できます。'
  ],
  'Ready': ['Bereit', 'Listo', 'Prêt', 'Pronto', 'Pronto', '可领取', '準備完了'],
  'Ready to hatch': [
    'Bereit zum Schlüpfen',
    'Listo para eclosionar',
    'Prêt à éclore',
    'Pronto a schiudersi',
    'Pronto para chocar',
    '可以孵化',
    '孵化できます'
  ],
  'Redeem': [
    'Einlösen',
    'Canjear',
    'Valider',
    'Riscatta',
    'Resgatar',
    '兑换',
    '引き換える'
  ],
  'Redeem code': [
    'Code einlösen',
    'Canjear código',
    'Utiliser un code',
    'Riscatta codice',
    'Resgatar código',
    '兑换码',
    'コードを引き換える'
  ],
  'Release': [
    'Freilassen',
    'Liberar',
    'Libérer',
    'Libera',
    'Libertar',
    '放归',
    '放す'
  ],
  'Release dragon…': [
    'Drachen freilassen …',
    'Liberar dragón…',
    'Libérer le dragon…',
    'Libera drago…',
    'Libertar dragão…',
    '放归龙……',
    'ドラゴンを放す…'
  ],
  'Remove': [
    'Entfernen',
    'Quitar',
    'Retirer',
    'Rimuovi',
    'Remover',
    '移除',
    '取り外す'
  ],
  'Remove favorite': [
    'Favorit entfernen',
    'Quitar de favoritos',
    'Retirer des favoris',
    'Rimuovi dai preferiti',
    'Remover dos favoritos',
    '取消收藏',
    'お気に入りを解除'
  ],
  'Remove permanently': [
    'Dauerhaft entfernen',
    'Eliminar para siempre',
    'Retirer définitivement',
    'Rimuovi definitivamente',
    'Remover permanentemente',
    '永久移除',
    '完全に削除'
  ],
  'Repair': [
    'Reparieren',
    'Reparar',
    'Réparer',
    'Ripara',
    'Reparar',
    '修复',
    '修理'
  ],
  'Return to inventory': [
    'Ins Inventar zurücklegen',
    'Devolver al inventario',
    'Remettre dans l’inventaire',
    'Rimetti nell’inventario',
    'Devolver ao inventário',
    '放回库存',
    '持ち物に戻す'
  ],
  'Rooftop Nest': [
    'Dachnest',
    'Nido de la Azotea',
    'Nid du Toit',
    'Nido sul Tetto',
    'Ninho no Telhado',
    '屋顶巢穴',
    '屋上の巣'
  ],
  'Rooms': ['Räume', 'Habitaciones', 'Pièces', 'Stanze', 'Cômodos', '房间', '部屋'],
  'Search 200 house items': [
    '200 Hausgegenstände durchsuchen',
    'Buscar entre 200 objetos de la casa',
    'Rechercher parmi 200 objets',
    'Cerca tra 200 oggetti per la casa',
    'Pesquisar 200 itens da casa',
    '搜索 200 件房屋物品',
    '200個の家具を検索'
  ],
  'Search by a stable player code; names are never treated as unique IDs.': [
    'Suche über einen festen Spielercode; Namen gelten nie als eindeutige IDs.',
    'Busca por un código de jugador estable; los nombres nunca se consideran identificadores únicos.',
    'Recherche avec un code joueur stable ; les noms ne sont jamais utilisés comme identifiants uniques.',
    'Cerca tramite un codice giocatore stabile; i nomi non sono mai considerati ID univoci.',
    'Pesquise por um código fixo de jogador; nomes nunca são tratados como IDs exclusivos.',
    '请使用固定的玩家代码搜索；名字不会作为唯一 ID。',
    '固定のプレイヤーコードで検索します。名前は一意のIDとして扱われません。'
  ],
  'Synced with your offline profile': [
    'Mit deinem Offline-Profil synchronisiert',
    'Sincronizado con tu perfil sin conexión',
    'Synchronisé avec ton profil hors ligne',
    'Sincronizzato con il tuo profilo offline',
    'Sincronizado com o teu perfil offline',
    '已与你的离线资料同步',
    'オフラインプロフィールと同期済み'
  ],
  'Secret achievement': [
    'Geheimer Erfolg',
    'Logro secreto',
    'Succès secret',
    'Obiettivo segreto',
    'Conquista secreta',
    '秘密成就',
    '秘密の実績'
  ],
  'Silver Chest': [
    'Silbertruhe',
    'Cofre de Plata',
    'Coffre en Argent',
    'Forziere d’Argento',
    'Baú de Prata',
    '白银宝箱',
    '銀の宝箱'
  ],
  'Sinister Chest': [
    'Unheilvolle Truhe',
    'Cofre Siniestro',
    'Coffre Sinistre',
    'Forziere Sinistro',
    'Baú Sinistro',
    '诡秘宝箱',
    '不吉な宝箱'
  ],
  'Select an item, then tap its new place in the room.': [
    'Wähle einen Gegenstand und tippe dann auf seinen neuen Platz im Raum.',
    'Selecciona un objeto y toca su nueva posición en la habitación.',
    'Sélectionne un objet, puis touche son nouvel emplacement dans la pièce.',
    'Seleziona un oggetto, poi tocca il nuovo punto nella stanza.',
    'Selecione um item e toque no novo lugar dele no cômodo.',
    '选择一件物品，然后点击房间中的新位置。',
    'アイテムを選び、部屋の新しい場所をタップしてください。'
  ],
  'Set as favorite': [
    'Als Favorit markieren',
    'Marcar como favorito',
    'Ajouter aux favoris',
    'Imposta come preferito',
    'Marcar como favorito',
    '设为最爱',
    'お気に入りにする'
  ],
  'Share or update DragonHaven': [
    'DragonHaven teilen oder aktualisieren',
    'Compartir o actualizar DragonHaven',
    'Partager ou mettre à jour DragonHaven',
    'Condividi o aggiorna DragonHaven',
    'Compartilhar ou atualizar DragonHaven',
    '分享或更新 DragonHaven',
    'DragonHavenを共有／更新'
  ],
  'Shop': ['Laden', 'Tienda', 'Boutique', 'Negozio', 'Loja', '商店', 'ショップ'],
  'Mini': ['Mini', 'Mini', 'Mini', 'Mini', 'Mini', '迷你', 'ミニ'],
  'Wood': ['Holz', 'Madera', 'Bois', 'Legno', 'Madeira', '木质', '木製'],
  'Short': ['Kurz', 'Corta', 'Courte', 'Breve', 'Curta', '短途', 'ショート'],
  'Something useful was discovered in the Spire.': [
    'In der Spitze wurde etwas Nützliches entdeckt.',
    'Se descubrió algo útil en la Aguja.',
    'Quelque chose d’utile a été découvert dans la Flèche.',
    'È stato scoperto qualcosa di utile nella Guglia.',
    'Algo útil foi descoberto na Torre.',
    '在尖塔中发现了有用的东西。',
    '塔で役立つものを発見しました。'
  ],
  'Special': [
    'Besonders',
    'Especial',
    'Spécial',
    'Speciale',
    'Especial',
    '特殊',
    'スペシャル'
  ],
  'Spectral': [
    'Spektral',
    'Espectral',
    'Spectral',
    'Spettrale',
    'Espectral',
    '幻彩',
    'スペクトラル'
  ],
  'Spirit is currently leading.': [
    'Geist liegt derzeit vorn.',
    'Espíritu está en cabeza.',
    'Esprit est actuellement en tête.',
    'Spirito è attualmente in testa.',
    'Espírito está na frente.',
    '心灵目前领先。',
    '現在はスピリットが優勢です。'
  ],
  'Star loft': [
    'Sternendachboden',
    'Ático Estelar',
    'Grenier des Étoiles',
    'Soffitta Stellare',
    'Sótão Estelar',
    '星辰阁楼',
    '星のロフト'
  ],
  'Starlight Treat · 3 gems': [
    'Sternenlicht-Leckerli · 3 Edelsteine',
    'Premio de luz estelar · 3 gemas',
    'Friandise astrale · 3 gemmes',
    'Dolcetto stellare · 3 gemme',
    'Petisco estelar · 3 gemas',
    '星光点心 · 3 宝石',
    '星明かりのおやつ・ジェム3個'
  ],
  'Start': ['Starten', 'Empezar', 'Commencer', 'Inizia', 'Iniciar', '开始', '開始'],
  'Sunforge': [
    'Sonnenschmiede',
    'Forja Solar',
    'Forge Solaire',
    'Forgia Solare',
    'Forja Solar',
    '太阳熔炉',
    '太陽の鍛冶場'
  ],
  'Talk to': [
    'Sprich mit',
    'Hablar con',
    'Parler à',
    'Parla con',
    'Falar com',
    '与其交谈',
    '話しかける'
  ],
  'Tap the chest': [
    'Tippe auf die Truhe',
    'Toca el cofre',
    'Touchez le coffre',
    'Tocca il forziere',
    'Toque no baú',
    '点击宝箱',
    '宝箱をタップ'
  ],
  'A tower treasure awaits': [
    'Ein Turmschatz wartet',
    'Te espera un tesoro de la torre',
    'Un trésor de la tour vous attend',
    'Ti aspetta un tesoro della torre',
    'Um tesouro da torre espera por você',
    '一份高塔宝藏正等着你',
    '塔の宝物が待っています'
  ],
  'Treasure claimed': [
    'Schatz geborgen',
    'Tesoro conseguido',
    'Trésor récupéré',
    'Tesoro ottenuto',
    'Tesouro resgatado',
    '宝藏已领取',
    '宝物を受け取りました'
  ],
  'TAP TO CALL YOUR DRAGON': [
    'TIPPEN, UM DEINEN DRACHEN ZU RUFEN',
    'TOCA PARA LLAMAR A TU DRAGÓN',
    'TOUCHEZ POUR APPELER VOTRE DRAGON',
    'TOCCA PER CHIAMARE IL TUO DRAGO',
    'TOQUE PARA CHAMAR SEU DRAGÃO',
    '点击召唤你的龙',
    'タップしてドラゴンを呼ぶ'
  ],
  'TAP TO MOVE YOUR DRAGON': [
    'TIPPEN, UM DEINEN DRACHEN ZU BEWEGEN',
    'TOCA PARA MOVER A TU DRAGÓN',
    'TOUCHEZ POUR DÉPLACER VOTRE DRAGON',
    'TOCCA PER SPOSTARE IL TUO DRAGO',
    'TOQUE PARA MOVER SEU DRAGÃO',
    '点击移动你的龙',
    'タップしてドラゴンを移動'
  ],
  'That dragon is already away.': [
    'Dieser Drache ist bereits unterwegs.',
    'Ese dragón ya está fuera.',
    'Ce dragon est déjà parti.',
    'Quel drago è già fuori.',
    'Esse dragão já está fora.',
    '那只龙已经外出了。',
    'そのドラゴンはすでに外出中です。'
  ],
  'That room cannot be built here.': [
    'Dieser Raum kann hier nicht gebaut werden.',
    'Esa habitación no puede construirse aquí.',
    'Cette pièce ne peut pas être construite ici.',
    'Questa stanza non può essere costruita qui.',
    'Esse cômodo não pode ser construído aqui.',
    '无法在此建造该房间。',
    'ここにはその部屋を建てられません。'
  ],
  'That was insightful': [
    'Das war aufschlussreich',
    'Ha sido revelador',
    'C’était instructif',
    'È stato illuminante',
    'Isso foi esclarecedor',
    '很有启发',
    'いい話でした'
  ],
  'The download could not be opened. The link was copied instead.': [
    'Der Download konnte nicht geöffnet werden. Der Link wurde stattdessen kopiert.',
    'No se pudo abrir la descarga. Se copió el enlace.',
    'Impossible d’ouvrir le téléchargement. Le lien a été copié.',
    'Impossibile aprire il download. Il link è stato copiato.',
    'Não foi possível abrir o download. O link foi copiado.',
    '无法打开下载页面，链接已复制。',
    'ダウンロードを開けなかったため、リンクをコピーしました。'
  ],
  'The download link could not be copied.': [
    'Der Downloadlink konnte nicht kopiert werden.',
    'No se pudo copiar el enlace de descarga.',
    'Impossible de copier le lien de téléchargement.',
    'Impossibile copiare il link di download.',
    'Não foi possível copiar o link de download.',
    '无法复制下载链接。',
    'ダウンロードリンクをコピーできませんでした。'
  ],
  'The download link could not be opened or copied.': [
    'Der Downloadlink konnte weder geöffnet noch kopiert werden.',
    'No se pudo abrir ni copiar el enlace de descarga.',
    'Impossible d’ouvrir ou de copier le lien de téléchargement.',
    'Impossibile aprire o copiare il link di download.',
    'Não foi possível abrir nem copiar o link de download.',
    '无法打开或复制下载链接。',
    'ダウンロードリンクを開くこともコピーすることもできませんでした。'
  ],
  'The future form is still a mystery.': [
    'Die zukünftige Form ist noch ein Geheimnis.',
    'La forma futura aún es un misterio.',
    'La forme future reste un mystère.',
    'La forma futura è ancora un mistero.',
    'A forma futura ainda é um mistério.',
    '未来形态仍是个谜。',
    '未来の姿はまだ謎です。'
  ],
  'The Draconomicon': [
    'Das Draconomicon',
    'El Draconomicon',
    'Le Draconomicon',
    'Il Draconomicon',
    'O Draconomicon',
    '《龙之秘典》',
    'ドラコノミコン'
  ],
  'The group does not meet the requirements.': [
    'Die Gruppe erfüllt die Anforderungen nicht.',
    'El grupo no cumple los requisitos.',
    'Le groupe ne remplit pas les conditions.',
    'Il gruppo non soddisfa i requisiti.',
    'O grupo não atende aos requisitos.',
    '队伍不符合要求。',
    'グループが条件を満たしていません。'
  ],
  'The GitHub repository is not connected yet. Build with --dart-define=DRAGONHAVEN_GITHUB_OWNER=yourname.':
      [
    'Das GitHub-Repository ist noch nicht verbunden. Baue mit --dart-define=DRAGONHAVEN_GITHUB_OWNER=deinname.',
    'El repositorio de GitHub aún no está conectado. Compila con --dart-define=DRAGONHAVEN_GITHUB_OWNER=tunombre.',
    'Le dépôt GitHub n’est pas encore connecté. Compilez avec --dart-define=DRAGONHAVEN_GITHUB_OWNER=votrenom.',
    'Il repository GitHub non è ancora collegato. Compila con --dart-define=DRAGONHAVEN_GITHUB_OWNER=tuonome.',
    'O repositório do GitHub ainda não está conectado. Compile com --dart-define=DRAGONHAVEN_GITHUB_OWNER=seunome.',
    '尚未连接 GitHub 仓库。请使用 --dart-define=DRAGONHAVEN_GITHUB_OWNER=你的名字 构建。',
    'GitHubリポジトリが未接続です。--dart-define=DRAGONHAVEN_GITHUB_OWNER=あなたの名前 を指定してビルドしてください。'
  ],
  'The hidden dragon inside will be lost permanently.': [
    'Der darin verborgene Drache geht für immer verloren.',
    'El dragón oculto en su interior se perderá para siempre.',
    'Le dragon caché à l’intérieur sera perdu définitivement.',
    'Il drago nascosto all’interno andrà perduto per sempre.',
    'O dragão escondido dentro será perdido para sempre.',
    '里面隐藏的龙将永久消失。',
    '中にいるドラゴンは永久に失われます。'
  ],
  'The highest trained path fixes the final form. Activities in Explore raise these values.':
      [
    'Der am stärksten trainierte Pfad bestimmt die endgültige Form. Aktivitäten unter „Erkunden“ erhöhen diese Werte.',
    'La senda más entrenada determina la forma final. Las actividades de Explorar aumentan estos valores.',
    'La voie la plus entraînée détermine la forme finale. Les activités d’Exploration augmentent ces valeurs.',
    'Il percorso più allenato determina la forma finale. Le attività di Esplorazione aumentano questi valori.',
    'O caminho mais treinado define a forma final. Atividades em Explorar aumentam esses valores.',
    '训练最多的路线会决定最终形态。“探索”中的活动可提升这些数值。',
    '最も鍛えた道が最終形態を決めます。「探索」の活動で数値が上がります。'
  ],
  'The inventory is empty. Explore the Spire or visit the furniture market.': [
    'Das Inventar ist leer. Erkunde die Spitze oder besuche den Möbelmarkt.',
    'El inventario está vacío. Explora la Aguja o visita el mercado de muebles.',
    'L’inventaire est vide. Explore la Flèche ou visite le marché aux meubles.',
    'L’inventario è vuoto. Esplora la Guglia o visita il mercato dei mobili.',
    'O inventário está vazio. Explore a Torre ou visite o mercado de móveis.',
    '库存为空。探索尖塔或前往家具市场吧。',
    '持ち物が空です。塔を探索するか、家具市場へ行きましょう。'
  ],
  'The latest release contains no valid version data.': [
    'Das neueste Release enthält keine gültigen Versionsdaten.',
    'La versión más reciente no contiene datos de versión válidos.',
    'La dernière version ne contient aucune donnée de version valide.',
    'L’ultima release non contiene dati di versione validi.',
    'A versão mais recente não contém dados de versão válidos.',
    '最新版本不包含有效的版本数据。',
    '最新リリースに有効なバージョン情報がありません。'
  ],
  'The release check took too long.': [
    'Die Versionsprüfung hat zu lange gedauert.',
    'La comprobación de la versión tardó demasiado.',
    'La vérification de la version a pris trop de temps.',
    'Il controllo della versione ha richiesto troppo tempo.',
    'A verificação da versão demorou demais.',
    '版本检查超时。',
    'リリースの確認に時間がかかりすぎました。'
  ],
  'The secure connection to GitHub failed.': [
    'Die sichere Verbindung zu GitHub ist fehlgeschlagen.',
    'Falló la conexión segura con GitHub.',
    'La connexion sécurisée à GitHub a échoué.',
    'La connessione sicura a GitHub non è riuscita.',
    'A conexão segura com o GitHub falhou.',
    '与 GitHub 的安全连接失败。',
    'GitHubへの安全な接続に失敗しました。'
  ],
  'The shell is trembling...': [
    'Die Schale zittert …',
    'La cáscara está temblando...',
    'La coquille tremble...',
    'Il guscio sta tremando...',
    'A casca está tremendo...',
    '蛋壳在颤动……',
    '殻が震えています…'
  ],
  'The tower already has 20 floors.': [
    'Der Turm hat bereits 20 Etagen.',
    'La torre ya tiene 20 pisos.',
    'La tour compte déjà 20 étages.',
    'La torre ha già 20 piani.',
    'A torre já tem 20 andares.',
    '高塔已经有 20 层。',
    '塔はすでに20階です。'
  ],
  'The tower nest': [
    'Das Turmnest',
    'El nido de la torre',
    'Le nid de la tour',
    'Il nido della torre',
    'O ninho da torre',
    '塔顶巢穴',
    '塔の巣'
  ],
  'This cannot be undone and gives no coins back.': [
    'Dies kann nicht rückgängig gemacht werden und bringt keine Münzen zurück.',
    'Esto no se puede deshacer y no devuelve monedas.',
    'Cette action est irréversible et ne rend aucune pièce.',
    'L’azione non può essere annullata e non restituisce monete.',
    'Isso não pode ser desfeito e não devolve moedas.',
    '此操作无法撤销，也不会返还金币。',
    '元に戻すことはできず、コインも返却されません。'
  ],
  'This build keeps your collection safely on this device. A real friend list needs authenticated accounts and a server, so no local demo person is shown as if they were online.':
      [
    'Diese Version speichert deine Sammlung sicher auf diesem Gerät. Eine echte Freundesliste benötigt angemeldete Konten und einen Server; deshalb werden keine lokalen Demokontakte als online angezeigt.',
    'Esta versión guarda tu colección de forma segura en este dispositivo. Una lista de amigos real necesita cuentas autenticadas y un servidor, así que no se muestran contactos de prueba como si estuvieran en línea.',
    'Cette version conserve votre collection sur cet appareil. Une vraie liste d’amis exige des comptes authentifiés et un serveur ; aucun contact fictif n’est donc affiché comme connecté.',
    'Questa versione conserva la collezione sul dispositivo. Un vero elenco amici richiede account autenticati e un server, quindi non vengono mostrati contatti demo come se fossero online.',
    'Esta versão mantém sua coleção segura no dispositivo. Uma lista real de amigos requer contas autenticadas e um servidor, por isso nenhum contato de demonstração aparece como online.',
    '此版本会将你的收藏安全保存在设备上。真正的好友列表需要账户验证和服务器，因此不会用本地演示角色冒充在线好友。',
    'このビルドではコレクションを端末内に安全に保存します。本物のフレンドリストには認証済みアカウントとサーバーが必要なため、デモの人物をオンラインとして表示しません。'
  ],
  'This dragon leaves your collection and cannot be trained. Its identity, form, alignment and hidden personality are preserved.':
      [
    'Dieser Drache verlässt deine Sammlung und kann nicht mehr trainiert werden. Identität, Form, Ausrichtung und verborgene Persönlichkeit bleiben erhalten.',
    'Este dragón dejará tu colección y no podrá entrenarse. Se conservarán su identidad, forma, afinidad y personalidad oculta.',
    'Ce dragon quittera votre collection et ne pourra plus être entraîné. Son identité, sa forme, son affinité et sa personnalité cachée seront conservées.',
    'Questo drago lascerà la collezione e non potrà essere allenato. Identità, forma, affinità e personalità nascosta resteranno intatte.',
    'Este dragão deixará sua coleção e não poderá ser treinado. Identidade, forma, afinidade e personalidade oculta serão preservadas.',
    '这只龙将离开你的收藏，无法继续训练。其身份、形态、倾向和隐藏性格都会保留。',
    'このドラゴンはコレクションを離れ、訓練できなくなります。個体情報、形態、資質、隠れた性格は保持されます。'
  ],
  'This code is not active.': [
    'Dieser Code ist nicht aktiv.',
    'Este código no está activo.',
    'Ce code n’est pas actif.',
    'Questo codice non è attivo.',
    'Este código não está ativo.',
    '此兑换码未启用。',
    'このコードは有効ではありません。'
  ],
  'This offer is no longer available.': [
    'Dieses Angebot ist nicht mehr verfügbar.',
    'Esta oferta ya no está disponible.',
    'Cette offre n’est plus disponible.',
    'Questa offerta non è più disponibile.',
    'Esta oferta não está mais disponível.',
    '此任务已不可用。',
    'この依頼はもう利用できません。'
  ],
  'This room is already part of the house.': [
    'Dieser Raum gehört bereits zum Haus.',
    'Esta habitación ya forma parte de la casa.',
    'Cette pièce fait déjà partie de la maison.',
    'Questa stanza fa già parte della casa.',
    'Este cômodo já faz parte da casa.',
    '该房间已建造。',
    'この部屋はすでに建築済みです。'
  ],
  'Tidal Library': [
    'Gezeitenbibliothek',
    'Biblioteca de las Mareas',
    'Bibliothèque des Marées',
    'Biblioteca delle Maree',
    'Biblioteca das Marés',
    '潮汐图书馆',
    '潮の図書館'
  ],
  'Tower': ['Turm', 'Torre', 'Tour', 'Torre', 'Torre', '高塔', '塔'],
  'Tower visits': [
    'Turmbesuche',
    'Visitas a torres',
    'Visites de tours',
    'Visite alle torri',
    'Visitas às torres',
    '拜访高塔',
    '塔への訪問'
  ],
  'Two-sided trade': [
    'Beidseitiger Tausch',
    'Intercambio bilateral',
    'Échange bilatéral',
    'Scambio bilaterale',
    'Troca bilateral',
    '双向交易',
    '相互交換'
  ],
  'Undiscovered dragon form': [
    'Unentdeckte Drachenform',
    'Forma de dragón sin descubrir',
    'Forme de dragon non découverte',
    'Forma di drago non scoperta',
    'Forma de dragão não descoberta',
    '未发现的龙形态',
    '未発見のドラゴン形態'
  ],
  'Unique atmosphere and layout': [
    'Einzigartige Stimmung und Raumaufteilung',
    'Ambiente y distribución únicos',
    'Ambiance et agencement uniques',
    'Atmosfera e disposizione uniche',
    'Atmosfera e disposição únicas',
    '独特的氛围与布局',
    '固有の雰囲気とレイアウト'
  ],
  'Unknown lineage': [
    'Unbekannte Familie',
    'Linaje desconocido',
    'Lignée inconnue',
    'Stirpe sconosciuta',
    'Linhagem desconhecida',
    '未知龙族',
    '未知の系統'
  ],
  'Up to 3 offers, refreshed at local midnight.': [
    'Bis zu 3 Angebote, aktualisiert um Mitternacht deiner Ortszeit.',
    'Hasta 3 ofertas, renovadas a medianoche local.',
    'Jusqu’à 3 offres, renouvelées à minuit heure locale.',
    'Fino a 3 offerte, aggiornate a mezzanotte locale.',
    'Até 3 ofertas, atualizadas à meia-noite local.',
    '最多 3 个任务，于当地午夜刷新。',
    '最大3件。現地時間の午前0時に更新されます。'
  ],
  'Up to 3 offers. Open slots refresh every hour; you may dismiss one.': [
    'Bis zu 3 Angebote. Freie Plätze werden stündlich aufgefüllt; du kannst eines wegschicken.',
    'Hasta 3 ofertas. Los huecos se renuevan cada hora; puedes descartar una.',
    'Jusqu’à 3 offres. Les places libres sont renouvelées chaque heure ; tu peux en ignorer une.',
    'Fino a 3 offerte. Gli spazi liberi si aggiornano ogni ora; puoi congedarne una.',
    'Até 3 ofertas. Vagas abertas são renovadas a cada hora; você pode dispensar uma.',
    '最多 3 个任务。空位每小时刷新；你可以取消其中一个。',
    '最大3件。空き枠は1時間ごとに更新され、1件を見送れます。'
  ],
  'Use only connected capital letters.': [
    'Verwende nur zusammenhängende Großbuchstaben.',
    'Usa solo letras mayúsculas seguidas.',
    'Utilisez uniquement des lettres majuscules sans espace.',
    'Usa solo lettere maiuscole consecutive.',
    'Use apenas letras maiúsculas juntas.',
    '仅使用连续的大写字母。',
    '大文字だけを続けて入力してください。'
  ],
  'Version': [
    'Version',
    'Versión',
    'Version',
    'Versione',
    'Versão',
    '版本',
    'バージョン'
  ],
  'Visit towers, lend a friendly dragon and trade eggs, chests or furniture.': [
    'Besuche Türme, leihe einen freundlichen Drachen aus und tausche Eier, Truhen oder Möbel.',
    'Visita torres, presta un dragón amistoso e intercambia huevos, cofres o muebles.',
    'Visite des tours, prête un dragon amical et échange des œufs, coffres ou meubles.',
    'Visita torri, presta un drago amichevole e scambia uova, forzieri o mobili.',
    'Visite torres, empreste um dragão amigável e troque ovos, baús ou móveis.',
    '拜访高塔、借出友好的龙，并交易龙蛋、宝箱或家具。',
    '塔を訪れ、仲良しのドラゴンを貸し、卵・宝箱・家具を交換しましょう。'
  ],
  'Wall': ['Wand', 'Pared', 'Mur', 'Parete', 'Parede', '墙饰', '壁飾り'],
  'Welcome': [
    'Willkommen',
    'Bienvenido',
    'Bienvenue',
    'Benvenuto',
    'Boas-vindas',
    '欢迎',
    'ようこそ'
  ],
  'Wellbeing': [
    'Wohlbefinden',
    'Bienestar',
    'Bien-être',
    'Benessere',
    'Bem-estar',
    '状态',
    'コンディション'
  ],
  'Wooden Chest': [
    'Holztruhe',
    'Cofre de Madera',
    'Coffre en Bois',
    'Forziere di Legno',
    'Baú de Madeira',
    '木制宝箱',
    '木の宝箱'
  ],
  'Wyrmling': [
    'Jungwyrm',
    'Dragón joven',
    'Jeune wyrm',
    'Giovane wyrm',
    'Jovem wyrm',
    '少年龙',
    '若竜'
  ],
  'Your keeper name': [
    'Name deines Hüters',
    'Nombre de tu cuidador',
    'Nom de ton gardien',
    'Nome del tuo custode',
    'Nome do seu guardião',
    '你的守护者名字',
    'キーパーの名前'
  ],
  'Your current dragon moves safely into the sanctuary collection. Coins, gems and discoveries stay yours.':
      [
    'Dein aktueller Drache zieht sicher in die Sammlung des Refugiums. Münzen, Edelsteine und Entdeckungen bleiben erhalten.',
    'Tu dragón actual pasará a salvo a la colección del santuario. Conservarás monedas, gemas y descubrimientos.',
    'Votre dragon actuel rejoint la collection du sanctuaire en toute sécurité. Pièces, gemmes et découvertes sont conservées.',
    'Il drago attuale passerà al sicuro nella collezione del santuario. Monete, gemme e scoperte resteranno tue.',
    'Seu dragão atual irá com segurança para a coleção do santuário. Moedas, gemas e descobertas continuam suas.',
    '当前的龙会安全转入庇护所收藏。金币、宝石和发现记录都会保留。',
    '現在のドラゴンは安全に聖域のコレクションへ移ります。コイン、ジェム、発見記録は残ります。'
  ],
  '✦ SOMETHING IS DIFFERENT...': [
    '✦ ETWAS IST ANDERS …',
    '✦ ALGO ES DIFERENTE...',
    '✦ QUELQUE CHOSE EST DIFFÉRENT...',
    '✦ C’È QUALCOSA DI DIVERSO...',
    '✦ ALGO ESTÁ DIFERENTE...',
    '✦ 有些地方不一样……',
    '✦ 何かが違う…'
  ],
  'Your living record of every dragon form you have raised.': [
    'Dein lebendiges Verzeichnis aller Drachenformen, die du aufgezogen hast.',
    'Tu registro vivo de todas las formas de dragón que has criado.',
    'Le registre vivant de toutes les formes de dragon que tu as élevées.',
    'Il registro vivente di ogni forma di drago che hai allevato.',
    'Seu registro vivo de todas as formas de dragão que você criou.',
    '记录你培育过的每一种龙形态。',
    '育てたすべてのドラゴン形態を記す、生きた記録です。'
  ],
  'Your purchased furniture is stored here.': [
    'Deine gekauften Möbel werden hier aufbewahrt.',
    'Aquí se guardan los muebles que has comprado.',
    'Tes meubles achetés sont rangés ici.',
    'I mobili acquistati sono conservati qui.',
    'Seus móveis comprados ficam guardados aqui.',
    '你购买的家具会存放在这里。',
    '購入した家具はここに保管されます。'
  ],
  'Your sanctuary is not ready for this room yet.': [
    'Dein Refugium ist noch nicht bereit für diesen Raum.',
    'Tu santuario aún no está listo para esta habitación.',
    'Ton sanctuaire n’est pas encore prêt pour cette pièce.',
    'Il tuo santuario non è ancora pronto per questa stanza.',
    'Seu santuário ainda não está pronto para este cômodo.',
    '你的庇护所尚未满足建造该房间的条件。',
    '聖域はまだこの部屋を建てられる段階ではありません。'
  ],
  'coins': ['Münzen', 'monedas', 'pièces', 'monete', 'moedas', '金币', 'コイン'],
  'floors': ['Etagen', 'pisos', 'étages', 'piani', 'andares', '层', '階'],
  'forms': ['Formen', 'formas', 'formes', 'forme', 'formas', '形态', '形態'],
  'locked': [
    'gesperrt',
    'bloqueado',
    'verrouillé',
    'bloccato',
    'bloqueado',
    '未解锁',
    '未解除'
  ],
  'path undecided': [
    'Pfad unentschieden',
    'senda sin decidir',
    'voie indécise',
    'percorso non deciso',
    'caminho indefinido',
    '路线未定',
    '進化の道は未定'
  ],
  'unlocked': [
    'freigeschaltet',
    'desbloqueado',
    'débloqué',
    'sbloccato',
    'desbloqueado',
    '已解锁',
    '解除済み'
  ],
  'training': [
    'Training',
    'entrenamiento',
    'entraînement',
    'allenamento',
    'treino',
    '训练',
    'トレーニング'
  ],
  'Dawn': ['Morgengrauen', 'Amanecer', 'Aube', 'Alba', 'Alvorada', '黎明', '夜明け'],
  'Day': ['Tag', 'Día', 'Jour', 'Giorno', 'Dia', '白昼', '昼'],
  'Deep Night': [
    'Tiefe Nacht',
    'Noche profunda',
    'Nuit profonde',
    'Notte fonda',
    'Noite profunda',
    '深夜',
    '深夜'
  ],
  'Dusk': [
    'Dämmerung',
    'Anochecer',
    'Crépuscule',
    'Tramonto',
    'Anoitecer',
    '黄昏',
    '夕暮れ'
  ],
  'Golden Hour': [
    'Goldene Stunde',
    'Hora dorada',
    'Heure dorée',
    'Ora dorata',
    'Hora dourada',
    '黄金时刻',
    '黄金の時間'
  ],
  'Legendary': [
    'Legendär',
    'Legendario',
    'Légendaire',
    'Leggendario',
    'Lendário',
    '传奇',
    'レジェンダリー'
  ],
  'Morning': ['Morgen', 'Mañana', 'Matin', 'Mattina', 'Manhã', '清晨', '朝'],
  'Mythical': [
    'Mythisch',
    'Mítico',
    'Mythique',
    'Mitico',
    'Mítico',
    '神话',
    'ミシカル'
  ],
  'Night': ['Nacht', 'Noche', 'Nuit', 'Notte', 'Noite', '夜晚', '夜'],
  'Uncommon': [
    'Ungewöhnlich',
    'Poco común',
    'Peu commun',
    'Non comune',
    'Incomum',
    '罕见',
    'アンコモン'
  ],
  'Very Rare': [
    'Sehr selten',
    'Muy raro',
    'Très rare',
    'Molto raro',
    'Muito raro',
    '非常稀有',
    'ベリーレア'
  ],
  'A gentle glow lingers beneath your hand.': [
    'Ein sanftes Leuchten bleibt unter deiner Hand zurück.',
    'Un brillo suave permanece bajo tu mano.',
    'Une douce lueur persiste sous votre main.',
    'Un bagliore delicato resta sotto la tua mano.',
    'Um brilho suave permanece sob sua mão.',
    '柔和的光芒在你的手下久久不散。',
    '手の下にやさしい光がしばらく残ります。'
  ],
  'A strange musical tap answers from within.': [
    'Ein seltsames, musikalisches Klopfen antwortet von innen.',
    'Un extraño golpecito musical responde desde dentro.',
    'Un étrange petit bruit musical répond de l’intérieur.',
    'Dall’interno risponde uno strano colpetto musicale.',
    'Uma estranha batidinha musical responde lá de dentro.',
    '里面传来奇怪而有节奏的敲击回应。',
    '中から不思議な音色のノックが返ってきます。'
  ],
  'A tiny spark skips across the shell.': [
    'Ein winziger Funke tanzt über die Schale.',
    'Una chispa diminuta salta sobre la cáscara.',
    'Une minuscule étincelle court sur la coquille.',
    'Una minuscola scintilla corre sul guscio.',
    'Uma faísca minúscula salta pela casca.',
    '一小点火花从蛋壳上跳过。',
    '小さな火花が殻の上を跳ねました。'
  ],
  'It goes quiet whenever you try to find a pattern.': [
    'Sobald du ein Muster suchst, wird es still.',
    'Se queda quieto cuando intentas encontrar un patrón.',
    'Tout se calme dès que vous cherchez un rythme.',
    'Si ferma ogni volta che cerchi uno schema.',
    'Fica quieto sempre que você tenta encontrar um padrão.',
    '每当你试图寻找规律时，它就安静下来。',
    '動きの規則を探そうとすると、いつも静かになります。'
  ],
  'Something inside seems to listen back.': [
    'Etwas darin scheint aufmerksam zurückzulauschen.',
    'Algo dentro parece escuchar a su vez.',
    'Quelque chose à l’intérieur semble écouter en retour.',
    'Qualcosa dentro sembra ascoltare a sua volta.',
    'Algo lá dentro parece escutar você também.',
    '里面的东西似乎也在认真倾听。',
    '中にいる何かも、こちらの音に耳を澄ませています。'
  ],
  'The egg grows restless when the stars appear.': [
    'Wenn die Sterne erscheinen, wird das Ei unruhig.',
    'El huevo se inquieta cuando aparecen las estrellas.',
    'L’œuf s’agite lorsque les étoiles apparaissent.',
    'L’uovo diventa irrequieto quando compaiono le stelle.',
    'O ovo fica inquieto quando as estrelas aparecem.',
    '星星出现时，龙蛋会变得躁动。',
    '星が現れると、卵がそわそわし始めます。'
  ],
  'The egg rolls a little. Uphill.': [
    'Das Ei rollt ein Stück. Bergauf.',
    'El huevo rueda un poco. Cuesta arriba.',
    'L’œuf roule un peu. Vers le haut de la pente.',
    'L’uovo rotola un po’. In salita.',
    'O ovo rola um pouco. Morro acima.',
    '龙蛋滚了一小段。还是向坡上滚的。',
    '卵が少し転がりました。坂の上へ。'
  ],
  'The movements inside follow a precise rhythm.': [
    'Die Bewegungen darin folgen einem präzisen Rhythmus.',
    'Los movimientos interiores siguen un ritmo preciso.',
    'Les mouvements à l’intérieur suivent un rythme précis.',
    'I movimenti all’interno seguono un ritmo preciso.',
    'Os movimentos lá dentro seguem um ritmo preciso.',
    '里面的动静遵循着精确的节奏。',
    '中の動きは正確なリズムに従っています。'
  ],
  'The nest suddenly smells of rain and moss.': [
    'Das Nest riecht plötzlich nach Regen und Moos.',
    'De pronto, el nido huele a lluvia y musgo.',
    'Le nid sent soudain la pluie et la mousse.',
    'Il nido profuma improvvisamente di pioggia e muschio.',
    'De repente, o ninho cheira a chuva e musgo.',
    '巢穴突然散发出雨水和苔藓的气息。',
    '巣から突然、雨と苔の香りがします。'
  ],
  'The shell feels unusually warm.': [
    'Die Schale fühlt sich ungewöhnlich warm an.',
    'La cáscara está inusualmente caliente.',
    'La coquille semble anormalement chaude.',
    'Il guscio sembra insolitamente caldo.',
    'A casca parece quente demais.',
    '蛋壳摸起来异常温暖。',
    '殻がいつもより温かく感じます。'
  ],
  'You are fairly sure the egg just tapped back.': [
    'Du bist ziemlich sicher, dass das Ei gerade zurückgeklopft hat.',
    'Estás casi seguro de que el huevo acaba de responder con un golpecito.',
    'Vous êtes presque certain que l’œuf vient de répondre.',
    'Sei quasi certo che l’uovo abbia appena risposto con un colpetto.',
    'Você tem quase certeza de que o ovo acabou de bater de volta.',
    '你相当确定，龙蛋刚才敲回来了一下。',
    '卵が今、こちらへノックを返した気がします。'
  ],
  'You hear something almost like distant waves.': [
    'Du hörst etwas, das beinahe wie ferne Wellen klingt.',
    'Oyes algo parecido a olas lejanas.',
    'Vous entendez quelque chose qui ressemble à des vagues lointaines.',
    'Senti qualcosa che somiglia a onde lontane.',
    'Você ouve algo parecido com ondas distantes.',
    '你听见了几乎像远方海浪的声音。',
    '遠くの波のような音が聞こえます。'
  ],
  '{dragon} pulled out a book and looked shocked by chapter three.': [
    '{dragon} zog ein Buch heraus und blickte bei Kapitel drei schockiert.',
    '{dragon} sacó un libro y quedó sorprendido con el capítulo tres.',
    '{dragon} a sorti un livre et a semblé bouleversé par le chapitre trois.',
    '{dragon} ha preso un libro ed è rimasto sconvolto dal terzo capitolo.',
    '{dragon} puxou um livro e ficou chocado com o capítulo três.',
    '{dragon} 抽出一本书，读到第三章时大吃一惊。',
    '{dragon} は本を取り出し、第3章を読んで驚きました。'
  ],
  '{dragon} curled up by the fire and immediately claimed the warmest spot.': [
    '{dragon} rollte sich am Feuer zusammen und beanspruchte sofort den wärmsten Platz.',
    '{dragon} se acurrucó junto al fuego y reclamó el lugar más cálido.',
    '{dragon} s’est blotti près du feu et a aussitôt pris la place la plus chaude.',
    '{dragon} si è raggomitolato accanto al fuoco prendendo subito il posto più caldo.',
    '{dragon} se enrolou perto do fogo e logo ocupou o lugar mais quente.',
    '{dragon} 蜷缩在炉火旁，立刻占据了最暖和的位置。',
    '{dragon} は火のそばで丸くなり、一番暖かい場所を確保しました。'
  ],
  '{dragon} inspected the snacks. One snack is now mysteriously absent.': [
    '{dragon} prüfte die Snacks. Einer fehlt nun auf geheimnisvolle Weise.',
    '{dragon} inspeccionó los aperitivos. Ahora falta uno misteriosamente.',
    '{dragon} a inspecté les friandises. L’une d’elles a mystérieusement disparu.',
    '{dragon} ha ispezionato gli spuntini. Ora ne manca misteriosamente uno.',
    '{dragon} inspecionou os petiscos. Um deles sumiu misteriosamente.',
    '{dragon} 检查了零食。现在有一份神秘地消失了。',
    '{dragon} はおやつを点検しました。一つだけ不思議と消えています。'
  ],
  '{dragon} made one tiny splash and one extremely non-tiny mess.': [
    '{dragon} machte einen winzigen Platscher und ein ganz und gar nicht winziges Durcheinander.',
    '{dragon} dio un pequeño chapuzón y armó un desastre nada pequeño.',
    '{dragon} a fait une petite éclaboussure et un désordre pas petit du tout.',
    '{dragon} ha fatto un piccolo spruzzo e un disastro per niente piccolo.',
    '{dragon} deu um pequeno mergulho e fez uma bagunça nada pequena.',
    '{dragon} 溅起了一小朵水花，也制造了一大团麻烦。',
    '{dragon} は小さく水をはね、とても小さいとは言えない騒ぎを起こしました。'
  ],
  '{dragon} counted every shiny object twice, just to be certain.': [
    '{dragon} zählte jeden glänzenden Gegenstand sicherheitshalber zweimal.',
    '{dragon} contó dos veces cada objeto brillante, por si acaso.',
    '{dragon} a compté deux fois chaque objet brillant, par prudence.',
    '{dragon} ha contato due volte ogni oggetto brillante, per sicurezza.',
    '{dragon} contou cada objeto brilhante duas vezes, só por garantia.',
    '{dragon} 把每件闪亮物品都数了两遍，以防万一。',
    '{dragon} は念のため、光るものをすべて二回数えました。'
  ],
  '{dragon} disappeared between the leaves for a highly strategic nap.': [
    '{dragon} verschwand für ein höchst strategisches Nickerchen zwischen den Blättern.',
    '{dragon} desapareció entre las hojas para una siesta muy estratégica.',
    '{dragon} a disparu entre les feuilles pour une sieste hautement stratégique.',
    '{dragon} è sparito tra le foglie per un pisolino altamente strategico.',
    '{dragon} sumiu entre as folhas para um cochilo altamente estratégico.',
    '{dragon} 消失在叶片之间，进行一次极具战略意义的小睡。',
    '{dragon} は極めて戦略的な昼寝のため、葉の間に消えました。'
  ],
  '{dragon} turned the bedding into a fort. No adults allowed.': [
    '{dragon} baute aus dem Bettzeug eine Festung. Erwachsene verboten.',
    '{dragon} convirtió la ropa de cama en una fortaleza. Prohibidos los adultos.',
    '{dragon} a transformé la literie en fort. Adultes interdits.',
    '{dragon} ha trasformato il letto in un fortino. Adulti vietati.',
    '{dragon} transformou a cama em um forte. Adultos não entram.',
    '{dragon} 把寝具搭成了堡垒。成年人禁止入内。',
    '{dragon} は寝具で砦を作りました。大人は立入禁止です。'
  ],
  '{dragon} tapped the magic ornament. It politely tapped back.': [
    '{dragon} tippte auf den magischen Schmuck. Er tippte höflich zurück.',
    '{dragon} tocó el adorno mágico. Este respondió educadamente.',
    '{dragon} a touché l’ornement magique. Il a poliment répondu.',
    '{dragon} ha toccato l’ornamento magico. Quello ha risposto con educazione.',
    '{dragon} tocou no enfeite mágico. Ele respondeu educadamente.',
    '{dragon} 敲了敲魔法饰品。它很有礼貌地敲了回来。',
    '{dragon} は魔法の飾りを叩きました。飾りも丁寧に叩き返しました。'
  ],
  '{dragon} looked around, nodded once, and declared this room acceptable.': [
    '{dragon} sah sich um, nickte einmal und erklärte den Raum für akzeptabel.',
    '{dragon} miró alrededor, asintió y declaró aceptable la habitación.',
    '{dragon} a regardé autour de lui, hoché la tête et déclaré la pièce acceptable.',
    '{dragon} si è guardato intorno, ha annuito e dichiarato la stanza accettabile.',
    '{dragon} olhou ao redor, assentiu e declarou o cômodo aceitável.',
    '{dragon} 环顾四周，点了一下头，宣布这个房间合格。',
    '{dragon} は周囲を見回し、一度うなずいて、この部屋を合格としました。'
  ],
  'An Adventure reward is ready in DragonHaven.': [
    'In DragonHaven wartet eine Abenteuerbelohnung.',
    'Hay una recompensa de aventura lista en DragonHaven.',
    'Une récompense d’aventure vous attend dans DragonHaven.',
    'Una ricompensa dell’avventura è pronta in DragonHaven.',
    'Uma recompensa de aventura está pronta no DragonHaven.',
    'DragonHaven 中有一份冒险奖励可领取。',
    'DragonHavenで冒険の報酬を受け取れます。'
  ],
  'Something inside wants to hatch in the Rooftop Nest.': [
    'Etwas darin möchte im Dachnest schlüpfen.',
    'Algo dentro quiere eclosionar en el Nido de la Azotea.',
    'Quelque chose à l’intérieur veut éclore dans le Nid du Toit.',
    'Qualcosa dentro vuole schiudersi nel Nido sul Tetto.',
    'Algo lá dentro quer chocar no Ninho do Telhado.',
    '里面的小生命想在屋顶巢穴中孵化。',
    '中にいる何かが屋上の巣で孵化したがっています。'
  ],
  'Your Mysterious Egg is ready': [
    'Dein geheimnisvolles Ei ist bereit',
    'Tu Huevo Misterioso está listo',
    'Votre Œuf mystérieux est prêt',
    'Il tuo Uovo misterioso è pronto',
    'Seu Ovo Misterioso está pronto',
    '你的神秘龙蛋已准备好',
    '不思議な卵の準備ができました'
  ],
  'Treasure revealed': [
    'Schatz enthüllt',
    'Tesoro revelado',
    'Trésor révélé',
    'Tesoro svelato',
    'Tesouro revelado',
    '宝藏已揭晓',
    '宝物が現れました'
  ],
  'The lock is opening...': [
    'Das Schloss öffnet sich...',
    'La cerradura se está abriendo...',
    'La serrure s’ouvre...',
    'La serratura si sta aprendo...',
    'A fechadura está abrindo...',
    '锁正在打开……',
    '鍵が開いています…'
  ],
  'Tap anywhere to return': [
    'Tippe irgendwo, um zurückzukehren',
    'Toca en cualquier lugar para volver',
    'Touchez n’importe où pour revenir',
    'Tocca ovunque per tornare',
    'Toque em qualquer lugar para voltar',
    '点击任意位置返回',
    'どこかをタップして戻る'
  ],
  'A quiet cradle for the next life in your collection.': [
    'Eine stille Wiege für das nächste Leben in deiner Sammlung.',
    'Una cuna tranquila para la próxima vida de tu colección.',
    'Un berceau paisible pour la prochaine vie de votre collection.',
    'Una culla tranquilla per la prossima vita della tua collezione.',
    'Um berço tranquilo para a próxima vida da sua coleção.',
    '为收藏中的下一个生命准备的安静摇篮。',
    'コレクションに加わる次の命のための静かな揺りかご。'
  ],
  'One hidden dragon is growing beneath the shell.': [
    'Unter der Schale wächst ein verborgener Drache.',
    'Un dragón oculto crece bajo el cascarón.',
    'Un dragon caché grandit sous la coquille.',
    'Un drago nascosto cresce sotto il guscio.',
    'Um dragão oculto cresce sob a casca.',
    '蛋壳下正孕育着一条神秘的龙。',
    '殻の下で一体の秘密のドラゴンが育っています。'
  ],
  'Reveal the dragon': [
    'Enthülle den Drachen',
    'Revela el dragón',
    'Révéler le dragon',
    'Rivela il drago',
    'Revelar o dragão',
    '揭晓这条龙',
    'ドラゴンを明らかにする'
  ],
  'No Mysterious Eggs are waiting in your inventory.': [
    'In deinem Inventar warten keine geheimnisvollen Eier.',
    'No hay Huevos Misteriosos esperando en tu inventario.',
    'Aucun Œuf mystérieux n’attend dans votre inventaire.',
    'Non ci sono Uova misteriose nel tuo inventario.',
    'Não há Ovos Misteriosos esperando no seu inventário.',
    '你的库存中没有等待孵化的神秘龙蛋。',
    '所持品に待機中の不思議な卵はありません。'
  ],
  'Choose a Mysterious Egg': [
    'Wähle ein geheimnisvolles Ei',
    'Elige un Huevo Misterioso',
    'Choisissez un Œuf mystérieux',
    'Scegli un Uovo misterioso',
    'Escolha um Ovo Misterioso',
    '选择一枚神秘龙蛋',
    '不思議な卵を選ぶ'
  ],
  'Its identity is already safely hidden inside.': [
    'Seine Identität ist bereits sicher darin verborgen.',
    'Su identidad ya está oculta de forma segura en su interior.',
    'Son identité est déjà bien cachée à l’intérieur.',
    'La sua identità è già nascosta al sicuro al suo interno.',
    'A identidade já está escondida com segurança lá dentro.',
    '它的身份早已安全地隐藏在里面。',
    'その正体はすでに中に大切に隠されています。'
  ],
  'The nest is already occupied.': [
    'Das Nest ist bereits belegt.',
    'El nido ya está ocupado.',
    'Le nid est déjà occupé.',
    'Il nido è già occupato.',
    'O ninho já está ocupado.',
    '巢穴已经被占用了。',
    '巣にはすでに卵があります。'
  ],
  'Tap the nest to choose an egg': [
    'Tippe auf das Nest, um ein Ei auszuwählen',
    'Toca el nido para elegir un huevo',
    'Touchez le nid pour choisir un œuf',
    'Tocca il nido per scegliere un uovo',
    'Toque no ninho para escolher um ovo',
    '点击巢穴选择一枚蛋',
    '巣をタップして卵を選ぶ'
  ],
  'Tap the egg once to begin hatching': [
    'Tippe einmal auf das Ei, um das Schlüpfen zu beginnen',
    'Toca el huevo una vez para comenzar la eclosión',
    'Touchez l’œuf une fois pour lancer l’éclosion',
    'Tocca una volta l’uovo per iniziare la schiusa',
    'Toque no ovo uma vez para iniciar a eclosão',
    '点击龙蛋一次开始孵化',
    '卵を一度タップして孵化を始める'
  ],
  'Something is moving inside...': [
    'Etwas bewegt sich darin...',
    'Algo se mueve dentro...',
    'Quelque chose bouge à l’intérieur...',
    'Qualcosa si muove dentro...',
    'Algo está se mexendo lá dentro...',
    '里面有什么在动……',
    '中で何かが動いています…'
  ],
  'The nest is empty': [
    'Das Nest ist leer',
    'El nido está vacío',
    'Le nid est vide',
    'Il nido è vuoto',
    'O ninho está vazio',
    '巢穴是空的',
    '巣は空です'
  ],
  'Choose one egg from your inventory.': [
    'Wähle ein Ei aus deinem Inventar.',
    'Elige un huevo de tu inventario.',
    'Choisissez un œuf dans votre inventaire.',
    'Scegli un uovo dal tuo inventario.',
    'Escolha um ovo do seu inventário.',
    '从库存中选择一枚蛋。',
    '所持品から卵を一つ選んでください。'
  ],
  'Rare eggs can be found in chests earned on Adventures.': [
    'Seltene Eier können in Truhen aus Abenteuern gefunden werden.',
    'Puedes encontrar huevos raros en cofres ganados en Aventuras.',
    'Des œufs rares peuvent être trouvés dans les coffres gagnés en Aventure.',
    'Puoi trovare uova rare nei forzieri ottenuti nelle Avventure.',
    'Ovos raros podem ser encontrados em baús ganhos nas Aventuras.',
    '稀有龙蛋可能藏在冒险获得的宝箱中。',
    '冒険で獲得した宝箱から珍しい卵が見つかることがあります。'
  ],
  'Choose an egg': [
    'Ei auswählen',
    'Elegir un huevo',
    'Choisir un œuf',
    'Scegli un uovo',
    'Escolher um ovo',
    '选择一枚蛋',
    '卵を選ぶ'
  ],
  'The egg moves to the Rooftop Nest. Your active dragon and the rest of the app stay available.':
      [
    'Das Ei zieht ins Dachnest. Dein aktiver Drache und der Rest der App bleiben verfügbar.',
    'El huevo se traslada al Nido de la Azotea. Tu dragón activo y el resto de la aplicación siguen disponibles.',
    'L’œuf rejoint le Nid du Toit. Votre dragon actif et le reste de l’application restent disponibles.',
    'L’uovo si sposta nel Nido sul Tetto. Il tuo drago attivo e il resto dell’app restano disponibili.',
    'O ovo vai para o Ninho do Telhado. Seu dragão ativo e o restante do aplicativo continuam disponíveis.',
    '龙蛋会移到屋顶巢穴。你的活跃龙和应用的其他功能仍可正常使用。',
    '卵は屋上の巣へ移動します。アクティブなドラゴンとアプリの他の機能は引き続き利用できます。'
  ],
  'Every form you raise leaves its magic on the page.': [
    'Jede Form, die du großziehst, hinterlässt ihre Magie auf der Seite.',
    'Cada forma que crías deja su magia en la página.',
    'Chaque forme que vous élevez laisse sa magie sur la page.',
    'Ogni forma che allevi lascia la sua magia sulla pagina.',
    'Cada forma que você cria deixa sua magia na página.',
    '你培养的每种形态都会在这一页留下魔法。',
    '育てたすべての姿が、このページに魔法を残します。'
  ],
  'Available': [
    'Verfügbar',
    'Disponibles',
    'Disponibles',
    'Disponibili',
    'Disponíveis',
    '可用',
    '利用可能'
  ],
  'Active': ['Aktiv', 'Activas', 'Actives', 'Attive', 'Ativas', '进行中', '進行中'],
  'Choose a path. Bring back stories, training and treasure.': [
    'Wähle einen Pfad. Bring Geschichten, Training und Schätze zurück.',
    'Elige una ruta. Regresa con historias, entrenamiento y tesoros.',
    'Choisissez une voie. Rapportez des histoires, de l’entraînement et des trésors.',
    'Scegli un percorso. Torna con storie, allenamento e tesori.',
    'Escolha um caminho. Traga histórias, treino e tesouros.',
    '选择一条路线，带回故事、训练成果和宝藏。',
    '道を選び、物語と訓練の成果と宝物を持ち帰りましょう。'
  ],
  'No trail is available here right now.': [
    'Hier ist gerade kein Pfad verfügbar.',
    'Ahora mismo no hay ninguna ruta disponible aquí.',
    'Aucune piste n’est disponible ici pour le moment.',
    'Al momento non è disponibile alcun percorso qui.',
    'Nenhuma trilha está disponível aqui agora.',
    '这里目前没有可用路线。',
    'ここには現在利用できる道がありません。'
  ],
  'Mystery chest': [
    'Mysteriöse Truhe',
    'Cofre misterioso',
    'Coffre mystère',
    'Forziere misterioso',
    'Baú misterioso',
    '神秘宝箱',
    '謎の宝箱'
  ],
  'Start adventure': [
    'Abenteuer starten',
    'Iniciar aventura',
    'Commencer l’aventure',
    'Avvia avventura',
    'Iniciar aventura',
    '开始冒险',
    '冒険を始める'
  ],
  'Choose a dragon': [
    'Drachen wählen',
    'Elige un dragón',
    'Choisir un dragon',
    'Scegli un drago',
    'Escolha um dragão',
    '选择一只龙',
    'ドラゴンを選ぶ'
  ],
  'Recommended for this path': [
    'Für diesen Pfad empfohlen',
    'Recomendados para esta ruta',
    'Recommandés pour cette voie',
    'Consigliati per questo percorso',
    'Recomendados para este caminho',
    '推荐用于此路线',
    'この道におすすめ'
  ],
  'Other available dragons': [
    'Andere verfügbare Drachen',
    'Otros dragones disponibles',
    'Autres dragons disponibles',
    'Altri draghi disponibili',
    'Outros dragões disponíveis',
    '其他可用的龙',
    'ほかの利用可能なドラゴン'
  ],
  'Recommended': [
    'Empfohlen',
    'Recomendado',
    'Recommandé',
    'Consigliato',
    'Recomendado',
    '推荐',
    'おすすめ'
  ],
  'No adventures are active': [
    'Keine Abenteuer sind aktiv',
    'No hay aventuras activas',
    'Aucune aventure n’est active',
    'Nessuna avventura è attiva',
    'Nenhuma aventura está ativa',
    '没有进行中的冒险',
    '進行中の冒険はありません'
  ],
  'Send a dragon out and its journey will appear here.': [
    'Schicke einen Drachen los und seine Reise erscheint hier.',
    'Envía un dragón y su viaje aparecerá aquí.',
    'Envoyez un dragon et son voyage apparaîtra ici.',
    'Invia un drago e il suo viaggio apparirà qui.',
    'Envie um dragão e a jornada dele aparecerá aqui.',
    '派出一只龙后，它的旅程会显示在这里。',
    'ドラゴンを送り出すと、その旅がここに表示されます。'
  ],
  'Unknown dragon': [
    'Unbekannter Drache',
    'Dragón desconocido',
    'Dragon inconnu',
    'Drago sconosciuto',
    'Dragão desconhecido',
    '未知的龙',
    '不明なドラゴン'
  ],
  'Ready to return': [
    'Bereit zur Rückkehr',
    'Listo para volver',
    'Prêt à revenir',
    'Pronto a tornare',
    'Pronto para voltar',
    '可以返回',
    '帰還可能'
  ],
  'Dragon': ['Drache', 'Dragón', 'Dragon', 'Drago', 'Dragão', '龙', 'ドラゴン'],
  'Status': ['Status', 'Estado', 'Statut', 'Stato', 'Status', '状态', '状態'],
  'Return in': [
    'Rückkehr in',
    'Regresa en',
    'Retour dans',
    'Ritorno tra',
    'Retorno em',
    '返回倒计时',
    '帰還まで'
  ],
  'Dragon experience': [
    'Drachenerfahrung',
    'Experiencia del dragón',
    'Expérience du dragon',
    'Esperienza del drago',
    'Experiência do dragão',
    '龙的经验',
    'ドラゴン経験値'
  ],
  'Training reward': [
    'Trainingsbelohnung',
    'Recompensa de entrenamiento',
    'Récompense d’entraînement',
    'Ricompensa di allenamento',
    'Recompensa de treino',
    '训练奖励',
    '訓練報酬'
  ],
  'Treasure': ['Schatz', 'Tesoro', 'Trésor', 'Tesoro', 'Tesouro', '宝藏', '宝物'],
  'One sealed chest': [
    'Eine versiegelte Truhe',
    'Un cofre sellado',
    'Un coffre scellé',
    'Un forziere sigillato',
    'Um baú selado',
    '一个封印宝箱',
    '封印された宝箱1個'
  ],
  'Claim rewards': [
    'Belohnungen abholen',
    'Recoger recompensas',
    'Récupérer les récompenses',
    'Ritira ricompense',
    'Coletar recompensas',
    '领取奖励',
    '報酬を受け取る'
  ],
  'Short Adventures': [
    'Kurze Abenteuer',
    'Aventuras cortas',
    'Aventures courtes',
    'Avventure brevi',
    'Aventuras curtas',
    '短途冒险',
    '短い冒険'
  ],
  'Long Adventures': [
    'Lange Abenteuer',
    'Aventuras largas',
    'Aventures longues',
    'Avventure lunghe',
    'Aventuras longas',
    '长途冒险',
    '長い冒険'
  ],
  'Group Adventures': [
    'Gruppenabenteuer',
    'Aventuras de grupo',
    'Aventures de groupe',
    'Avventure di gruppo',
    'Aventuras em grupo',
    '团队冒险',
    'グループ冒険'
  ],
  'Special Adventures': [
    'Besondere Abenteuer',
    'Aventuras especiales',
    'Aventures spéciales',
    'Avventure speciali',
    'Aventuras especiais',
    '特殊冒险',
    '特別な冒険'
  ],
  'Tiny outings, quick training and wooden chests.': [
    'Winzige Ausflüge, schnelles Training und Holzkisten.',
    'Pequeñas salidas, entrenamiento rápido y cofres de madera.',
    'Petites sorties, entraînement rapide et coffres en bois.',
    'Piccole uscite, allenamento rapido e forzieri di legno.',
    'Pequenos passeios, treino rápido e baús de madeira.',
    '短途外出、快速训练和木箱奖励。',
    '小さなお出かけ、手軽な訓練、そして木の宝箱。'
  ],
  'Quick routes that refresh throughout the day.': [
    'Schnelle Routen, die sich im Laufe des Tages erneuern.',
    'Rutas rápidas que se renuevan durante el día.',
    'Des itinéraires rapides renouvelés au fil de la journée.',
    'Percorsi rapidi che si aggiornano durante il giorno.',
    'Rotas rápidas que se renovam ao longo do dia.',
    '全天都会刷新的快速路线。',
    '一日を通して更新される短いルートです。'
  ],
  'Patient journeys with richer returns.': [
    'Geduldige Reisen mit reicheren Erträgen.',
    'Viajes pacientes con mejores recompensas.',
    'Des voyages patients aux gains plus riches.',
    'Viaggi pazienti con ricompense più ricche.',
    'Jornadas pacientes com retornos melhores.',
    '需要耐心、回报更丰厚的旅程。',
    '時間をかけるぶん、実り豊かな旅です。'
  ],
  'Shared discoveries for connected keepers.': [
    'Gemeinsame Entdeckungen für verbundene Hüter.',
    'Descubrimientos compartidos para cuidadores conectados.',
    'Des découvertes partagées pour les gardiens connectés.',
    'Scoperte condivise per custodi collegati.',
    'Descobertas compartilhadas para guardiões conectados.',
    '供已连接守护者共同探索。',
    'つながったキーパーたちで挑む共同発見です。'
  ],
  'Rare trails that only appear at special moments.': [
    'Seltene Pfade, die nur zu besonderen Momenten erscheinen.',
    'Rutas raras que solo aparecen en momentos especiales.',
    'Des pistes rares qui n’apparaissent qu’à des moments particuliers.',
    'Percorsi rari che appaiono solo in momenti speciali.',
    'Trilhas raras que só aparecem em momentos especiais.',
    '只在特殊时刻出现的稀有路线。',
    '特別な瞬間にだけ現れる珍しい道です。'
  ],
  'Might': ['Stärke', 'Fuerza', 'Puissance', 'Potenza', 'Força', '力量', '力'],
  'Arcana': ['Arkana', 'Arcanos', 'Arcanes', 'Arcano', 'Arcana', '奥秘', '秘術'],
  'Spirit': ['Geist', 'Espíritu', 'Esprit', 'Spirito', 'Espírito', '心灵', '精神'],
  'No dragon is available for this adventure.': [
    'Für dieses Abenteuer ist kein Drache verfügbar.',
    'No hay ningún dragón disponible para esta aventura.',
    'Aucun dragon n’est disponible pour cette aventure.',
    'Nessun drago è disponibile per questa avventura.',
    'Nenhum dragão está disponível para esta aventura.',
    '没有龙可参加这次冒险。',
    'この冒険に参加できるドラゴンがいません。'
  ],
  'Roaming in the Tower': [
    'Unterwegs im Turm',
    'Paseando por la Torre',
    'Se promène dans la Tour',
    'Gira per la Torre',
    'Passeando pela Torre',
    '正在塔中漫步',
    '塔を散歩中'
  ],
  'Resting off-stage': [
    'Ruht außerhalb der Räume',
    'Descansa fuera de escena',
    'Se repose hors scène',
    'Riposa fuori scena',
    'Descansando fora de cena',
    '正在场外休息',
    '画面外で休憩中'
  ],
  'Free roaming in the Tower': [
    'Freies Herumlaufen im Turm',
    'Paseo libre por la Torre',
    'Déplacement libre dans la Tour',
    'Libero movimento nella Torre',
    'Livre circulação na Torre',
    '在塔中自由漫步',
    '塔内を自由に歩く'
  ],
  'This dragon may appear and wander through rooms.': [
    'Dieser Drache kann in Räumen erscheinen und umherlaufen.',
    'Este dragón puede aparecer y pasear por las habitaciones.',
    'Ce dragon peut apparaître et se promener dans les pièces.',
    'Questo drago può apparire e girare per le stanze.',
    'Este dragão pode aparecer e passear pelos cômodos.',
    '这只龙可以出现在房间里并四处走动。',
    'このドラゴンは部屋に現れて歩き回れます。'
  ],
  'Zoom out': [
    'Herauszoomen',
    'Alejar',
    'Dézoomer',
    'Riduci zoom',
    'Diminuir zoom',
    '缩小',
    'ズームアウト'
  ],
  'The dragons found cozy places on other floors.': [
    'Die Drachen haben gemütliche Plätze auf anderen Etagen gefunden.',
    'Los dragones encontraron lugares acogedores en otros pisos.',
    'Les dragons ont trouvé des endroits confortables aux autres étages.',
    'I draghi hanno trovato posti accoglienti sugli altri piani.',
    'Os dragões encontraram lugares aconchegantes em outros andares.',
    '龙群在其他楼层找到了舒适的位置。',
    'ドラゴンたちは別の階で居心地のよい場所を見つけました。'
  ],
  'Build another floor before clearing this room.': [
    'Baue eine weitere Etage, bevor du diesen Raum leerst.',
    'Construye otro piso antes de despejar esta habitación.',
    'Construisez un autre étage avant de vider cette pièce.',
    'Costruisci un altro piano prima di liberare questa stanza.',
    'Construa outro andar antes de esvaziar este cômodo.',
    '请先建造另一层，再清空这个房间。',
    'この部屋からドラゴンを移す前に、別の階を建ててください。'
  ],
  'Finish decorating': [
    'Dekorieren beenden',
    'Terminar de decorar',
    'Terminer la décoration',
    'Termina decorazione',
    'Terminar decoração',
    '完成装饰',
    '模様替えを終える'
  ],
  'Clear dragons': [
    'Drachen umquartieren',
    'Mover dragones',
    'Déplacer les dragons',
    'Sposta draghi',
    'Mover dragões',
    '移走龙群',
    'ドラゴンを移動'
  ],
  'TAP TO GUIDE YOUR FAVORITE': [
    'TIPPE, UM DEINEN FAVORITEN ZU LENKEN',
    'TOCA PARA GUIAR A TU FAVORITO',
    'TOUCHEZ POUR GUIDER VOTRE FAVORI',
    'TOCCA PER GUIDARE IL TUO PREFERITO',
    'TOQUE PARA GUIAR SEU FAVORITO',
    '点击引导你的最爱',
    'タップしてお気に入りを導く'
  ],
  'TAP TO CALL YOUR FAVORITE': [
    'TIPPE, UM DEINEN FAVORITEN ZU RUFEN',
    'TOCA PARA LLAMAR A TU FAVORITO',
    'TOUCHEZ POUR APPELER VOTRE FAVORI',
    'TOCCA PER CHIAMARE IL TUO PREFERITO',
    'TOQUE PARA CHAMAR SEU FAVORITO',
    '点击召唤你的最爱',
    'タップしてお気に入りを呼ぶ'
  ],
  'Dragon type': [
    'Drachentyp',
    'Tipo de dragón',
    'Type de dragon',
    'Tipo di drago',
    'Tipo de dragão',
    '龙的种类',
    'ドラゴンの種類'
  ],
  'Maturity': [
    'Reifestufe',
    'Madurez',
    'Maturité',
    'Maturità',
    'Maturidade',
    '成长阶段',
    '成長段階'
  ],
  'Experience': [
    'Erfahrung',
    'Experiencia',
    'Expérience',
    'Esperienza',
    'Experiência',
    '经验',
    '経験値'
  ],
  'Level': ['Level', 'Nivel', 'Niveau', 'Livello', 'Nível', '等级', 'レベル'],
  'Invite to Tower': [
    'In den Turm einladen',
    'Invitar a la Torre',
    'Inviter dans la Tour',
    'Invita nella Torre',
    'Convidar para a Torre',
    '邀请进入龙塔',
    '塔に招待する'
  ],
  'The Tower is full. Build another floor or disable another roaming dragon.': [
    'Der Turm ist voll. Baue eine weitere Etage oder deaktiviere einen anderen umherziehenden Drachen.',
    'La Torre está llena. Construye otro piso o desactiva otro dragón que deambula.',
    'La Tour est pleine. Construisez un autre étage ou désactivez un autre dragon en liberté.',
    'La Torre è piena. Costruisci un altro piano o disattiva un altro drago in giro.',
    'A Torre está cheia. Construa outro andar ou desative outro dragão que circula.',
    '龙塔已满。请再建一层或停止另一只龙的漫游。',
    '塔が満員です。階を増やすか、別のドラゴンの巡回を解除してください。'
  ],
  'Duration': ['Dauer', 'Duración', 'Durée', 'Durata', 'Duração', '时长', '所要時間'],
  'connected keepers': [
    'verbundene Hüter',
    'cuidadores conectados',
    'gardiens connectés',
    'custodi collegati',
    'guardiões conectados',
    '已连接的守护者',
    'つながっているキーパー'
  ],
  'Expertise training': [
    'Expertisentraining',
    'Entrenamiento de pericia',
    'Entraînement d’expertise',
    'Allenamento competenza',
    'Treino de especialidade',
    '专长训练',
    '専門技能トレーニング'
  ],
  'Expertises': [
    'Expertisen',
    'Pericias',
    'Expertises',
    'Competenze',
    'Especialidades',
    '专长',
    '専門技能'
  ],
  'Possible chests': [
    'Mögliche Truhen',
    'Cofres posibles',
    'Coffres possibles',
    'Forzieri possibili',
    'Baús possíveis',
    '可能的宝箱',
    '入手可能な宝箱'
  ],
  'Keeper requirement': [
    'Hüter-Anforderung',
    'Requisito de cuidadores',
    'Condition de gardiens',
    'Requisito dei custodi',
    'Requisito de guardiões',
    '守护者要求',
    'キーパー条件'
  ],
  'shapes a Might Ascension': [
    'prägt eine Stärke-Aszension',
    'moldea una Ascensión de Fuerza',
    'façonne une Ascension de Puissance',
    'plasma un’Ascensione di Potenza',
    'molda uma Ascensão de Força',
    '塑造力量飞升形态',
    '力のアセンションを形作る'
  ],
  'shapes an Arcana Ascension': [
    'prägt eine Arkana-Aszension',
    'moldea una Ascensión Arcana',
    'façonne une Ascension des Arcanes',
    'plasma un’Ascensione Arcana',
    'molda uma Ascensão Arcana',
    '塑造奥秘飞升形态',
    '秘術のアセンションを形作る'
  ],
  'shapes a Spirit Ascension': [
    'prägt eine Geist-Aszension',
    'moldea una Ascensión de Espíritu',
    'façonne une Ascension d’Esprit',
    'plasma un’Ascensione di Spirito',
    'molda uma Ascensão de Espírito',
    '塑造心灵飞升形态',
    '精神のアセンションを形作る'
  ],
  'Lawful': ['Rechtschaffen', 'Legal', 'Loyal', 'Legale', 'Leal', '守序', '秩序'],
  'Neutral': ['Neutral', 'Neutral', 'Neutre', 'Neutrale', 'Neutro', '中立', '中立'],
  'Chaotic': [
    'Chaotisch',
    'Caótico',
    'Chaotique',
    'Caotico',
    'Caótico',
    '混乱',
    '混沌'
  ],
  'Good': ['Gut', 'Bueno', 'Bon', 'Buono', 'Bom', '善良', '善'],
  'Evil': ['Böse', 'Malvado', 'Mauvais', 'Malvagio', 'Mau', '邪恶', '悪'],
  'Moral nature': [
    'Moralische Natur',
    'Naturaleza moral',
    'Nature morale',
    'Natura morale',
    'Natureza moral',
    '道德倾向',
    '道徳的性質'
  ],
  'Order nature': [
    'Ordnungsnatur',
    'Naturaleza de orden',
    'Nature d’ordre',
    'Natura dell’ordine',
    'Natureza de ordem',
    '秩序倾向',
    '秩序的性質'
  ],
  'Personality': [
    'Persönlichkeit',
    'Personalidad',
    'Personnalité',
    'Personalità',
    'Personalidade',
    '性格',
    '性格'
  ],
  'Undiscovered': [
    'Unentdeckt',
    'Sin descubrir',
    'Non découvert',
    'Non scoperto',
    'Não descoberto',
    '尚未发现',
    '未発見'
  ],
  'Highest level reached': [
    'Höchste Stufe erreicht',
    'Nivel máximo alcanzado',
    'Niveau maximal atteint',
    'Livello massimo raggiunto',
    'Nível máximo alcançado',
    '已达到最高等级',
    '最高レベルに到達'
  ],
  'to next level': [
    'bis zur nächsten Stufe',
    'para el siguiente nivel',
    'avant le niveau suivant',
    'al livello successivo',
    'para o próximo nível',
    '距下一级',
    '次のレベルまで'
  ],
  'Final evolution reached': [
    'Letzte Evolution erreicht',
    'Evolución final alcanzada',
    'Évolution finale atteinte',
    'Evoluzione finale raggiunta',
    'Evolução final alcançada',
    '已达到最终进化',
    '最終進化に到達'
  ],
  'Next evolution': [
    'Nächste Evolution',
    'Próxima evolución',
    'Prochaine évolution',
    'Prossima evoluzione',
    'Próxima evolução',
    '下一次进化',
    '次の進化'
  ],
  'Relics': [
    'Relikte',
    'Reliquias',
    'Reliques',
    'Reliquie',
    'Relíquias',
    '圣物',
    '秘宝'
  ],
  'No Relics yet': [
    'Noch keine Relikte',
    'Aún no hay Reliquias',
    'Pas encore de Reliques',
    'Ancora nessuna Reliquia',
    'Ainda não há Relíquias',
    '尚无圣物',
    '秘宝はまだありません'
  ],
  'Incubation after nesting': [
    'Brutzeit nach dem Einsetzen',
    'Incubación tras colocarlo',
    'Incubation après installation',
    'Incubazione dopo il posizionamento',
    'Incubação após colocar no ninho',
    '入巢后的孵化时间',
    '巣に置いた後の孵化時間'
  ],
  'Use this Relic?': [
    'Dieses Relikt benutzen?',
    '¿Usar esta Reliquia?',
    'Utiliser cette Relique ?',
    'Usare questa Reliquia?',
    'Usar esta Relíquia?',
    '使用这件圣物吗？',
    'この秘宝を使いますか？'
  ],
  'This is a consumable item. It disappears after revealing one dragon. Continue?':
      [
    'Dies ist ein Verbrauchsgegenstand. Er verschwindet, nachdem er einen Drachen enthüllt hat. Fortfahren?',
    'Este objeto es consumible. Desaparece tras revelar un dragón. ¿Continuar?',
    'Cet objet est consommable. Il disparaît après avoir révélé un dragon. Continuer ?',
    'Questo oggetto è consumabile. Scompare dopo aver rivelato un drago. Continuare?',
    'Este item é consumível. Ele desaparece após revelar um dragão. Continuar?',
    '这是一次性消耗品。揭示一条龙后便会消失。继续吗？',
    'これは消耗アイテムです。ドラゴンを1体明かすと消えます。続けますか？'
  ],
  'Continue': [
    'Weiter',
    'Continuar',
    'Continuer',
    'Continua',
    'Continuar',
    '继续',
    '続ける'
  ],
  'Claim': [
    'Abholen',
    'Recoger',
    'Récupérer',
    'Riscatta',
    'Coletar',
    '领取',
    '受け取る'
  ],
  'Remove from Tower': [
    'Aus dem Turm entfernen',
    'Retirar de la Torre',
    'Retirer de la Tour',
    'Rimuovi dalla Torre',
    'Remover da Torre',
    '移出龙塔',
    '塔から外す'
  ],
  'Ancient magic awakens': [
    'Uralte Magie erwacht',
    'La magia antigua despierta',
    'Une magie ancienne s’éveille',
    'La magia antica si risveglia',
    'A magia antiga desperta',
    '远古魔法正在苏醒',
    '古の魔法が目覚める'
  ],
  'Sealed treasure': [
    'Versiegelter Schatz',
    'Tesoro sellado',
    'Trésor scellé',
    'Tesoro sigillato',
    'Tesouro selado',
    '封印的宝藏',
    '封印された宝物'
  ],
  'Chest opening': [
    'Truhe öffnet sich',
    'El cofre se abre',
    'Ouverture du coffre',
    'Apertura del forziere',
    'Baú abrindo',
    '宝箱正在开启',
    '宝箱を開封中'
  ],
  'These exceptionally rare treasures can appear in Gold Chests and rarer chests.':
      [
    'Diese außergewöhnlich seltenen Schätze können in Goldtruhen und selteneren Truhen erscheinen.',
    'Estos tesoros excepcionalmente raros pueden aparecer en Cofres Dorados y cofres más raros.',
    'Ces trésors exceptionnellement rares peuvent apparaître dans les Coffres d’or et les coffres plus rares.',
    'Questi tesori eccezionalmente rari possono apparire nei Forzieri d’Oro e in quelli più rari.',
    'Esses tesouros excepcionalmente raros podem aparecer em Baús de Ouro e baús mais raros.',
    '这些极其稀有的宝物可能出现在黄金宝箱及更稀有的宝箱中。',
    'この極めて希少な宝物は、ゴールド宝箱以上の宝箱から出現します。'
  ],
  'Choose carefully: each relic reveals one dragon and is consumed.': [
    'Wähle mit Bedacht: Jedes Relikt enthüllt einen Drachen und wird verbraucht.',
    'Elige con cuidado: cada reliquia revela un dragón y se consume.',
    'Choisissez avec soin : chaque relique révèle un dragon et est consommée.',
    'Scegli con cura: ogni reliquia rivela un drago e viene consumata.',
    'Escolha com cuidado: cada relíquia revela um dragão e é consumida.',
    '请谨慎选择：每件圣物只能揭示一条龙，使用后即会消耗。',
    '慎重に選んでください。秘宝は1体のドラゴンを明かし、使用すると消費されます。'
  ],
  'Use': ['Benutzen', 'Usar', 'Utiliser', 'Usa', 'Usar', '使用', '使う'],
  'Already revealed': [
    'Bereits enthüllt',
    'Ya revelado',
    'Déjà révélé',
    'Già rivelato',
    'Já revelado',
    '已经揭示',
    '確認済み'
  ],
  'Secret still hidden': [
    'Geheimnis noch verborgen',
    'Secreto aún oculto',
    'Secret encore caché',
    'Segreto ancora nascosto',
    'Segredo ainda oculto',
    '秘密仍然隐藏',
    '秘密はまだ隠されています'
  ],
  'Remember this': [
    'Merken',
    'Recordar esto',
    'S’en souvenir',
    'Ricordalo',
    'Lembrar disso',
    '记住它',
    '覚えておく'
  ],
  'Moral Prism': [
    'Moralprisma',
    'Prisma Moral',
    'Prisme Moral',
    'Prisma Morale',
    'Prisma Moral',
    '道德棱镜',
    '道徳のプリズム'
  ],
  'Order Compass': [
    'Ordnungskompass',
    'Brújula del Orden',
    'Boussole de l’Ordre',
    'Bussola dell’Ordine',
    'Bússola da Ordem',
    '秩序罗盘',
    '秩序の羅針盤'
  ],
  'Soul Mirror': [
    'Seelenspiegel',
    'Espejo del Alma',
    'Miroir de l’Âme',
    'Specchio dell’Anima',
    'Espelho da Alma',
    '灵魂之镜',
    '魂の鏡'
  ],
  'Reveals whether one dragon leans toward Good, Neutral or Evil.': [
    'Enthüllt, ob ein Drache zu Gut, Neutral oder Böse neigt.',
    'Revela si un dragón se inclina hacia el Bien, la Neutralidad o el Mal.',
    'Révèle si un dragon penche vers le Bien, la Neutralité ou le Mal.',
    'Rivela se un drago tende al Bene, alla Neutralità o al Male.',
    'Revela se um dragão tende ao Bem, à Neutralidade ou ao Mal.',
    '揭示一条龙倾向于善良、中立还是邪恶。',
    '1体のドラゴンが善・中立・悪のどれに傾くかを明かします。'
  ],
  'Reveals whether one dragon is Lawful, Neutral or Chaotic.': [
    'Enthüllt, ob ein Drache rechtschaffen, neutral oder chaotisch ist.',
    'Revela si un dragón es Legal, Neutral o Caótico.',
    'Révèle si un dragon est Loyal, Neutre ou Chaotique.',
    'Rivela se un drago è Legale, Neutrale o Caotico.',
    'Revela se um dragão é Leal, Neutro ou Caótico.',
    '揭示一条龙是守序、中立还是混乱。',
    '1体のドラゴンが秩序・中立・混沌のどれかを明かします。'
  ],
  'Reveals the hidden personality traits of one dragon.': [
    'Enthüllt die verborgenen Persönlichkeitsmerkmale eines Drachen.',
    'Revela los rasgos de personalidad ocultos de un dragón.',
    'Révèle les traits de personnalité cachés d’un dragon.',
    'Rivela i tratti nascosti della personalità di un drago.',
    'Revela os traços de personalidade ocultos de um dragão.',
    '揭示一条龙隐藏的性格特征。',
    '1体のドラゴンに隠された性格特性を明かします。'
  ],
  'Sleepy': [
    'Schläfrig',
    'Dormilón',
    'Somnolent',
    'Sonnolento',
    'Sonolento',
    '爱困',
    '眠たがり'
  ],
  'Nosy': [
    'Neugierig',
    'Entrometido',
    'Fouineur',
    'Ficcanaso',
    'Intrometido',
    '爱打听',
    '詮索好き'
  ],
  'Hoarder': [
    'Sammler',
    'Acaparador',
    'Collectionneur',
    'Accumulatore',
    'Acumulador',
    '囤积狂',
    'ため込み屋'
  ],
  'Drama Queen': [
    'Dramakönig',
    'Reina del drama',
    'Roi du drame',
    'Re del dramma',
    'Rei do drama',
    '戏精',
    'ドラマ王'
  ],
  'Bookworm': [
    'Bücherwurm',
    'Ratón de biblioteca',
    'Rat de bibliothèque',
    'Topo di biblioteca',
    'Rato de biblioteca',
    '书虫',
    '本の虫'
  ],
  'Food Thief': [
    'Futterdieb',
    'Ladrón de comida',
    'Voleur de nourriture',
    'Ladro di cibo',
    'Ladrão de comida',
    '偷吃鬼',
    '食いしん坊泥棒'
  ],
  'Afraid of Heights': [
    'Höhenangst',
    'Miedo a las alturas',
    'Peur du vide',
    'Paura dell’altezza',
    'Medo de altura',
    '恐高',
    '高所恐怖症'
  ],
  'Restless': [
    'Rastlos',
    'Inquieto',
    'Agité',
    'Irrequieto',
    'Inquieto',
    '坐立不安',
    '落ち着きがない'
  ],
  'Shy': ['Schüchtern', 'Tímido', 'Timide', 'Timido', 'Tímido', '害羞', '恥ずかしがり'],
  'Show-Off': [
    'Angeber',
    'Presumido',
    'Frimeur',
    'Esibizionista',
    'Exibido',
    '爱炫耀',
    '目立ちたがり'
  ],
  'Clumsy': [
    'Tollpatschig',
    'Torpe',
    'Maladroit',
    'Goffo',
    'Desajeitado',
    '笨手笨脚',
    '不器用'
  ],
  'Neat Freak': [
    'Ordnungsfanatiker',
    'Fanático del orden',
    'Maniaque du rangement',
    'Maniaco dell’ordine',
    'Fanático por organização',
    '洁癖',
    'きれい好き'
  ],
  'Messy': [
    'Unordentlich',
    'Desordenado',
    'Désordonné',
    'Disordinato',
    'Bagunceiro',
    '邋遢',
    '散らかし屋'
  ],
  'Stubborn': ['Stur', 'Terco', 'Têtu', 'Testardo', 'Teimoso', '固执', '頑固'],
  'Cuddly': [
    'Kuschelig',
    'Cariñoso',
    'Câlin',
    'Coccolone',
    'Carinhoso',
    '爱撒娇',
    '甘えん坊'
  ],
  'Grumpy': [
    'Mürrisch',
    'Gruñón',
    'Grognon',
    'Brontolone',
    'Rabugento',
    '脾气坏',
    '不機嫌'
  ],
  'Easily Distracted': [
    'Leicht ablenkbar',
    'Se distrae fácilmente',
    'Facilement distrait',
    'Si distrae facilmente',
    'Distrai-se facilmente',
    '容易分心',
    '気が散りやすい'
  ],
  'Night Owl': [
    'Nachteule',
    'Noctámbulo',
    'Oiseau de nuit',
    'Nottambulo',
    'Notívago',
    '夜猫子',
    '夜更かし'
  ],
  'Early Bird': [
    'Frühaufsteher',
    'Madrugador',
    'Lève-tôt',
    'Mattiniero',
    'Madrugador',
    '早起鸟',
    '早起き'
  ],
  'Splash Lover': [
    'Planschfreund',
    'Amante de las salpicaduras',
    'Fan d’éclaboussures',
    'Amante degli spruzzi',
    'Amante de respingos',
    '爱玩水',
    '水遊び好き'
  ],
  'Firebug': [
    'Feuerteufel',
    'Pirómano',
    'Pyromane',
    'Piromane',
    'Incendiário',
    '玩火迷',
    '火遊び好き'
  ],
  'Attention Seeker': [
    'Aufmerksamkeitssucher',
    'Busca atención',
    'En quête d’attention',
    'In cerca di attenzioni',
    'Busca atenção',
    '渴望关注',
    'かまってちゃん'
  ],
  'Startles Easily': [
    'Schreckhaft',
    'Se asusta fácilmente',
    'Facile à effrayer',
    'Si spaventa facilmente',
    'Assusta-se facilmente',
    '容易受惊',
    '驚きやすい'
  ],
  'Tutorial': [
    'Tutorial',
    'Tutorial',
    'Tutoriel',
    'Tutorial',
    'Tutorial',
    '教程',
    'チュートリアル'
  ],
  'Welcome to DragonHaven': [
    'Willkommen in DragonHaven',
    'Te damos la bienvenida a DragonHaven',
    'Bienvenue dans DragonHaven',
    'Benvenuto a DragonHaven',
    'Boas-vindas a DragonHaven',
    '欢迎来到 DragonHaven',
    'DragonHavenへようこそ'
  ],
  'will show you around. You can skip now and replay this tour later from the three-dot menu.':
      [
    'zeigt dir alles. Du kannst jetzt überspringen und diese Führung später über das Dreipunkt-Menü wiederholen.',
    'te enseñará todo. Puedes omitirlo ahora y repetir este recorrido más tarde desde el menú de tres puntos.',
    'va te guider. Tu peux passer maintenant et relancer cette visite plus tard depuis le menu à trois points.',
    'ti farà da guida. Puoi saltare ora e ripetere il tour più tardi dal menu con i tre puntini.',
    'vai guiar você. Você pode pular agora e repetir este passeio depois pelo menu de três pontos.',
    '会带你参观。你现在可以跳过，之后可从三点菜单重新开始导览。',
    'が案内します。今はスキップしても、後で三点メニューからもう一度始められます。'
  ],
  'Online friends': [
    'Online-Freunde',
    'Amigos en línea',
    'Amis en ligne',
    'Amici online',
    'Amigos online',
    '在线好友',
    'オンラインのフレンド'
  ],
  "Create an e-mail-verified online account, then add other keepers by their Keeper ID. Friends can open each other's public profile and see portraits, titles, favorite dragons, discovered forms and Trial records.":
      [
    'Erstelle ein per E-Mail bestätigtes Online-Konto und füge andere Hüter über ihre Hüter-ID hinzu. Freunde können gegenseitig ihre öffentlichen Profile öffnen und Porträts, Titel, Lieblingsdrachen, entdeckte Formen und Prüfungsrekorde sehen.',
    'Crea una cuenta en línea verificada por correo electrónico y añade a otros guardianes mediante su ID. Los amigos pueden abrir sus perfiles públicos y ver retratos, títulos, dragones favoritos, formas descubiertas y récords de Pruebas.',
    'Crée un compte en ligne vérifié par e-mail, puis ajoute d’autres gardiens grâce à leur identifiant. Les amis peuvent consulter leurs profils publics, portraits, titres, dragons favoris, formes découvertes et records d’Épreuves.',
    'Crea un account online verificato via e-mail e aggiungi altri custodi tramite il loro ID. Gli amici possono aprire i profili pubblici e vedere ritratti, titoli, draghi preferiti, forme scoperte e record delle Prove.',
    'Crie uma conta online verificada por e-mail e adicione outros guardiões pelo ID. Amigos podem abrir os perfis públicos uns dos outros e ver retratos, títulos, dragões favoritos, formas descobertas e recordes das Provas.',
    '创建经过电子邮件验证的在线账号，然后通过 Keeper ID 添加其他守护者。好友可以查看彼此的公开资料、头像、称号、最喜欢的龙、已发现形态和试炼纪录。',
    'メール認証済みのオンラインアカウントを作成し、Keeper IDでほかのキーパーを追加できます。フレンド同士で公開プロフィール、ポートレート、称号、お気に入りのドラゴン、発見済み形態、試練記録を確認できます。'
  ],
  'Trade and travel together': [
    'Gemeinsam handeln und reisen',
    'Intercambia y viaja en compañía',
    'Échanger et voyager ensemble',
    'Scambia e viaggia insieme',
    'Troque e viaje em grupo',
    '一起交易与冒险',
    '一緒に交換して冒険'
  ],
  'From a friend you can offer a protected one-to-one Trade: eggs, chests and Relics stay reserved until it completes or expires. Logged-in friends can also enroll dragons together in asynchronous Group Adventures.':
      [
    'Bei einem Freund kannst du einen geschützten Eins-zu-eins-Tausch anbieten: Eier, Truhen und Relikte bleiben reserviert, bis der Tausch abgeschlossen ist oder abläuft. Angemeldete Freunde können ihre Drachen außerdem gemeinsam für asynchrone Gruppenabenteuer anmelden.',
    'Desde el perfil de un amigo puedes ofrecer un intercambio individual protegido: los huevos, cofres y Reliquias quedan reservados hasta que termine o caduque. Los amigos conectados también pueden inscribir dragones juntos en Aventuras grupales asíncronas.',
    'Depuis le profil d’un ami, tu peux proposer un échange individuel sécurisé : œufs, coffres et Reliques restent réservés jusqu’à sa conclusion ou son expiration. Les amis connectés peuvent aussi inscrire ensemble leurs dragons à des Aventures de groupe asynchrones.',
    'Dal profilo di un amico puoi proporre uno scambio uno a uno protetto: uova, scrigni e Reliquie restano riservati finché lo scambio non termina o scade. Gli amici connessi possono anche iscrivere insieme i draghi alle Avventure di gruppo asincrone.',
    'No perfil de um amigo, você pode oferecer uma troca individual protegida: ovos, baús e Relíquias ficam reservados até a conclusão ou expiração. Amigos conectados também podem inscrever dragões juntos em Aventuras em grupo assíncronas.',
    '你可以向好友发起受保护的一对一交易：龙蛋、宝箱和遗物会一直保留到交易完成或过期。已登录的好友还可以一起让龙报名参加异步团队冒险。',
    'フレンドには保護された1対1の交換を提案できます。卵、宝箱、レリックは交換が完了または期限切れになるまで確保されます。ログイン中のフレンド同士で、非同期のグループ冒険にドラゴンを参加させることもできます。'
  ],
  "Mini Adventures take minutes, Short Adventures hours and Long Adventures days. A dragon's matching Expertise shortens the timer. Group Adventures need 2–4 logged-in friends and begin automatically when their requirements are met.":
      [
    'Mini-Abenteuer dauern Minuten, kurze Abenteuer Stunden und lange Abenteuer Tage. Die passende Expertise eines Drachen verkürzt den Timer. Gruppenabenteuer benötigen 2–4 angemeldete Freunde und starten automatisch, sobald ihre Anforderungen erfüllt sind.',
    'Las Aventuras mini duran minutos, las cortas horas y las largas días. La Pericia correspondiente del dragón reduce el tiempo. Las Aventuras grupales necesitan entre 2 y 4 amigos conectados y comienzan automáticamente cuando se cumplen los requisitos.',
    'Les mini-Aventures durent quelques minutes, les Aventures courtes plusieurs heures et les longues plusieurs jours. L’Expertise correspondante du dragon réduit le temps. Les Aventures de groupe nécessitent 2 à 4 amis connectés et commencent automatiquement lorsque leurs conditions sont remplies.',
    'Le Avventure mini durano minuti, quelle brevi ore e quelle lunghe giorni. La Competenza corrispondente del drago riduce il tempo. Le Avventure di gruppo richiedono 2–4 amici connessi e iniziano automaticamente quando i requisiti sono soddisfatti.',
    'Aventuras mini duram minutos, Aventuras curtas duram horas e Aventuras longas duram dias. A Especialidade correspondente do dragão reduz o tempo. Aventuras em grupo precisam de 2–4 amigos conectados e começam automaticamente quando os requisitos são atendidos.',
    '迷你冒险持续数分钟，短途冒险持续数小时，长途冒险持续数天。龙对应的专长会缩短计时。团队冒险需要2至4名已登录好友，并会在满足要求后自动开始。',
    'ミニ冒険は数分、ショート冒険は数時間、ロング冒険は数日かかります。ドラゴンの対応する専門技能で時間が短縮されます。グループ冒険にはログイン中のフレンドが2～4人必要で、条件を満たすと自動で始まります。'
  ],
  'Trials': ['Prüfungen', 'Pruebas', 'Épreuves', 'Prove', 'Provas', '试炼', '試練'],
  'Trials are skill-based minigames and refill every 15 minutes, up to three waiting. Cavern Flight trains Spirit, Ruin Breaker trains Might and Runeweaver trains Arcana; your performance sets the rank, rewards and personal high score.':
      [
    'Prüfungen sind geschicklichkeitsbasierte Minispiele und werden alle 15 Minuten bis zu maximal drei ergänzt. Höhlenflug trainiert Geist, Ruinenbrecher Stärke und Runenweber Arkana; deine Leistung bestimmt Rang, Belohnungen und persönlichen Rekord.',
    'Las Pruebas son minijuegos de habilidad y se reponen cada 15 minutos, hasta un máximo de tres. Vuelo cavernario entrena Espíritu, Romperruinas Poder y Tejerrunas Arcana; tu rendimiento determina el rango, las recompensas y el récord personal.',
    'Les Épreuves sont des mini-jeux d’adresse renouvelés toutes les 15 minutes, jusqu’à trois en attente. Vol cavernicole entraîne l’Esprit, Briseur de ruines la Puissance et Tisseur de runes les Arcanes ; ta performance détermine le rang, les récompenses et le record personnel.',
    'Le Prove sono minigiochi di abilità e si ricaricano ogni 15 minuti, fino a un massimo di tre. Volo nella caverna allena lo Spirito, Spezzarovine la Potenza e Tessirune l’Arcano; la prestazione determina grado, ricompense e record personale.',
    'As Provas são minijogos de habilidade e são renovadas a cada 15 minutos, até três disponíveis. Voo na caverna treina Espírito, Quebra-ruínas Poder e Tecelão de runas Arcano; seu desempenho determina classificação, recompensas e recorde pessoal.',
    '试炼是技巧型小游戏，每15分钟补充一次，最多可等待3个。洞窟飞行训练精神，遗迹破坏者训练力量，符文编织者训练奥术；你的表现决定评级、奖励和个人最高分。',
    '試練は腕前を試すミニゲームで、15分ごとに最大3つまで補充されます。洞窟飛行は精神、ルインブレイカーは力、ルーンウィーバーは神秘を鍛え、成績によってランク、報酬、自己ベストが決まります。'
  ],
  'Use the two large sprites at the top right: My Dragons opens your complete dragon collection, while the Draconomicon shows every discovered dragon form. Below them you can build, visit and decorate Tower floors.':
      [
    'Nutze die beiden großen Symbole oben rechts: Meine Drachen öffnet deine vollständige Drachensammlung, während das Draconomicon jede entdeckte Drachenform zeigt. Darunter kannst du Turmgeschosse bauen, besuchen und dekorieren.',
    'Usa los dos iconos grandes de arriba a la derecha: Mis dragones abre tu colección completa y el Draconomicon muestra cada forma de dragón descubierta. Debajo puedes construir, visitar y decorar pisos de la Torre.',
    'Utilise les deux grandes icônes en haut à droite : Mes dragons ouvre ta collection complète, tandis que le Draconomicon montre chaque forme de dragon découverte. En dessous, tu peux construire, visiter et décorer les étages de la Tour.',
    'Usa le due grandi icone in alto a destra: I miei draghi apre la collezione completa, mentre il Draconomicon mostra ogni forma di drago scoperta. Sotto puoi costruire, visitare e decorare i piani della Torre.',
    'Use os dois ícones grandes no canto superior direito: Meus dragões abre sua coleção completa, enquanto o Draconomicon mostra cada forma de dragão descoberta. Abaixo deles você pode construir, visitar e decorar andares da Torre.',
    '使用右上角的两个大图标：“我的龙”会打开完整的龙收藏，而《龙族图鉴》会显示每个已发现的龙形态。你还可以在下方建造、参观和装饰塔楼楼层。',
    '右上の2つの大きなアイコンを使います。「マイドラゴン」では全ドラゴンを確認でき、ドラコノミコンには発見済みのドラゴン形態が表示されます。その下では塔の階を建築、訪問、装飾できます。'
  ],
  'Eggs, unopened chests, furniture and Relics are stored here. Open chests, start an egg incubation or inspect what you own; items reserved for a Trade cannot be used until released.':
      [
    'Hier werden Eier, ungeöffnete Truhen, Möbel und Relikte aufbewahrt. Öffne Truhen, beginne die Brut eines Eis oder prüfe deinen Besitz; für einen Tausch reservierte Gegenstände bleiben bis zur Freigabe unbenutzbar.',
    'Aquí se guardan huevos, cofres sin abrir, muebles y Reliquias. Abre cofres, inicia la incubación de un huevo o revisa lo que tienes; los objetos reservados para un intercambio no pueden usarse hasta quedar libres.',
    'Tes œufs, coffres non ouverts, meubles et Reliques sont conservés ici. Ouvre des coffres, lance l’incubation d’un œuf ou consulte tes possessions ; les objets réservés pour un échange restent inutilisables jusqu’à leur libération.',
    'Qui vengono conservati uova, scrigni non aperti, mobili e Reliquie. Apri gli scrigni, avvia l’incubazione di un uovo o controlla ciò che possiedi; gli oggetti riservati per uno scambio non possono essere usati finché non vengono liberati.',
    'Ovos, baús fechados, móveis e Relíquias ficam guardados aqui. Abra baús, inicie a incubação de um ovo ou confira o que possui; itens reservados para uma troca não podem ser usados até serem liberados.',
    '龙蛋、未开启的宝箱、家具和遗物都存放在这里。你可以开启宝箱、开始孵蛋或查看藏品；为交易保留的物品在解除保留前无法使用。',
    '卵、未開封の宝箱、家具、レリックはここに保管されます。宝箱を開けたり、卵の孵化を始めたり、所持品を確認できます。交換用に確保されたアイテムは解放されるまで使えません。'
  ],
  'Buy furniture for your Tower with coins or gems. Title Chests cost coins and unlock account titles; Portrait Chests cost gems and unlock profile portraits. Open both from Inventory.':
      [
    'Kaufe mit Münzen oder Edelsteinen Möbel für deinen Turm. Titeltruhen kosten Münzen und schalten Kontotitel frei; Porträttruhen kosten Edelsteine und schalten Profilporträts frei. Beide öffnest du im Inventar.',
    'Compra muebles para tu Torre con monedas o gemas. Los Cofres de títulos cuestan monedas y desbloquean títulos de cuenta; los Cofres de retratos cuestan gemas y desbloquean retratos de perfil. Abre ambos desde el Inventario.',
    'Achète des meubles pour ta Tour avec des pièces ou des gemmes. Les Coffres de titres coûtent des pièces et débloquent des titres de compte ; les Coffres de portraits coûtent des gemmes et débloquent des portraits de profil. Ouvre-les depuis l’Inventaire.',
    'Acquista mobili per la Torre con monete o gemme. Gli Scrigni dei titoli costano monete e sbloccano titoli dell’account; gli Scrigni dei ritratti costano gemme e sbloccano ritratti del profilo. Aprili dall’Inventario.',
    'Compre móveis para a Torre com moedas ou gemas. Baús de títulos custam moedas e desbloqueiam títulos da conta; Baús de retratos custam gemas e desbloqueiam retratos de perfil. Abra ambos no Inventário.',
    '使用金币或宝石为塔楼购买家具。称号宝箱消耗金币并解锁账号称号；头像宝箱消耗宝石并解锁个人头像。两者都可在物品栏中开启。',
    'コインやジェムで塔の家具を購入できます。称号の宝箱はコインでアカウント称号を、ポートレートの宝箱はジェムでプロフィール画像を解放します。どちらもインベントリから開けます。'
  ],
  'The three-dot menu': [
    'Das Dreipunkt-Menü',
    'El menú de tres puntos',
    'Le menu à trois points',
    'Il menu con tre puntini',
    'O menu de três pontos',
    '三点菜单',
    '3点メニュー'
  ],
  'Tap the three dots at the top right for Account info, where you can change your portrait and title and manage Notifications and Audio. The same menu opens Language, Achievements and this Tutorial again.':
      [
    'Tippe oben rechts auf die drei Punkte, um die Kontoinformationen zu öffnen. Dort kannst du Porträt und Titel ändern sowie Benachrichtigungen und Audio verwalten. Dasselbe Menü öffnet Sprache, Erfolge und erneut dieses Tutorial.',
    'Toca los tres puntos de arriba a la derecha para abrir la información de la cuenta, donde puedes cambiar el retrato y el título y gestionar Notificaciones y Audio. El mismo menú abre Idioma, Logros y este Tutorial de nuevo.',
    'Touche les trois points en haut à droite pour ouvrir les informations du compte, où tu peux modifier portrait et titre et gérer Notifications et Audio. Le même menu ouvre aussi Langue, Succès et ce Tutoriel.',
    'Tocca i tre puntini in alto a destra per aprire le informazioni dell’account, dove puoi cambiare ritratto e titolo e gestire Notifiche e Audio. Lo stesso menu apre Lingua, Obiettivi e di nuovo questo Tutorial.',
    'Toque nos três pontos no canto superior direito para abrir as informações da conta, onde você pode mudar retrato e título e gerenciar Notificações e Áudio. O mesmo menu abre Idioma, Conquistas e este Tutorial novamente.',
    '点击右上角的三点菜单打开账号信息，你可以在其中更换头像和称号，并管理通知与音频。同一菜单还可打开语言、成就并重新查看本教程。',
    '右上の3点をタップするとアカウント情報が開き、ポートレートと称号の変更、通知とオーディオの管理ができます。同じメニューから言語、実績、このチュートリアルも開けます。'
  ],
  'This is the future meeting place for linked Dragonkeepers, visits and fair trades.':
      [
    'Dies wird der Treffpunkt für verbundene Drachenhüter, Besuche und faire Tauschgeschäfte.',
    'Este será el punto de encuentro para Guardianes de Dragones conectados, visitas e intercambios justos.',
    'Ce sera le lieu de rencontre des Gardiens de dragons liés, des visites et des échanges équitables.',
    'Questo sarà il punto d’incontro per Custodi di draghi collegati, visite e scambi equi.',
    'Este será o ponto de encontro para Guardiões de Dragões conectados, visitas e trocas justas.',
    '这里将成为已连接的驯龙师互访和公平交易的聚会处。',
    'ここは連携したドラゴンキーパーとの訪問や公正な交換の場になります。'
  ],
  'Send an available dragon on an Adventure to earn XP, Expertises and treasure chests.':
      [
    'Schicke einen verfügbaren Drachen auf ein Abenteuer, um XP, Expertisen und Schatztruhen zu verdienen.',
    'Envía un dragón disponible a una Aventura para ganar XP, Pericias y cofres del tesoro.',
    'Envoie un dragon disponible en Aventure pour gagner de l’XP, des Expertises et des coffres au trésor.',
    'Invia un drago disponibile in un’Avventura per ottenere XP, Competenze e scrigni.',
    'Envie um dragão disponível em uma Aventura para ganhar XP, Especialidades e baús do tesouro.',
    '派一条空闲的龙去冒险，以获得经验、专长和宝箱。',
    '空いているドラゴンを冒険に送り、XP、専門技能、宝箱を獲得しましょう。'
  ],
  'Build unique rooms, decorate them and choose which dragons may roam through their home.':
      [
    'Baue einzigartige Räume, dekoriere sie und wähle, welche Drachen durch ihr Zuhause streifen dürfen.',
    'Construye habitaciones únicas, decóralas y elige qué dragones pueden recorrer su hogar.',
    'Construis des pièces uniques, décore-les et choisis quels dragons peuvent parcourir leur foyer.',
    'Costruisci stanze uniche, decorale e scegli quali draghi possono girare nella loro casa.',
    'Construa cômodos únicos, decore-os e escolha quais dragões podem passear pelo lar.',
    '建造并装饰独特房间，再选择哪些龙可以在家中漫游。',
    '個性的な部屋を建てて飾り、家の中を歩き回れるドラゴンを選びましょう。'
  ],
  'Your eggs, unopened chests, furniture and consumable Relics are safely stored here.':
      [
    'Deine Eier, ungeöffneten Truhen, Möbel und verbrauchbaren Relikte werden hier sicher aufbewahrt.',
    'Aquí se guardan de forma segura tus huevos, cofres sin abrir, muebles y Reliquias consumibles.',
    'Tes œufs, coffres non ouverts, meubles et Reliques consommables sont conservés ici.',
    'Qui sono custoditi uova, scrigni non aperti, mobili e Reliquie consumabili.',
    'Seus ovos, baús fechados, móveis e Relíquias consumíveis ficam guardados aqui.',
    '你的蛋、未开启宝箱、家具和消耗型遗物都安全存放在这里。',
    '卵、未開封の宝箱、家具、消費型のレリックはここに安全に保管されます。'
  ],
  'Spend coins or gems on furniture that makes every Tower room feel like home.':
      [
    'Gib Münzen oder Edelsteine für Möbel aus, die jeden Turmraum wohnlich machen.',
    'Gasta monedas o gemas en muebles que hagan acogedora cada sala de la Torre.',
    'Dépense des pièces ou des gemmes en meubles pour rendre chaque pièce de la Tour accueillante.',
    'Spendi monete o gemme in mobili che rendano accogliente ogni stanza della Torre.',
    'Gaste moedas ou gemas em móveis que deixem cada cômodo da Torre aconchegante.',
    '用金币或宝石购买家具，让塔里的每个房间都有家的感觉。',
    'コインやジェムで家具を買い、塔のどの部屋も居心地のよい家にしましょう。'
  ],
  'Skip tutorial': [
    'Tutorial überspringen',
    'Omitir tutorial',
    'Passer le tutoriel',
    'Salta tutorial',
    'Pular tutorial',
    '跳过教程',
    'チュートリアルをスキップ'
  ],
  'Next': ['Weiter', 'Siguiente', 'Suivant', 'Avanti', 'Próximo', '下一步', '次へ'],
  'Nothing left to reveal': [
    'Nichts mehr zu enthüllen',
    'No queda nada por revelar',
    'Plus rien à révéler',
    'Non resta nulla da rivelare',
    'Não há mais nada para revelar',
    '没有秘密可揭示',
    '明かせる秘密はありません'
  ],
  'This Relic has already revealed its secret for every dragon you own. Hatch or collect another dragon to use it.':
      [
    'Dieses Relikt hat sein Geheimnis bereits für jeden deiner Drachen enthüllt. Brüte einen weiteren Drachen aus oder sammle ihn, um es zu verwenden.',
    'Esta Reliquia ya reveló su secreto para todos tus dragones. Incuba o consigue otro dragón para usarla.',
    'Cette Relique a déjà révélé son secret pour chacun de tes dragons. Fais éclore ou collectionne un autre dragon pour l’utiliser.',
    'Questa Reliquia ha già rivelato il suo segreto per ogni drago che possiedi. Fai schiudere o raccogli un altro drago per usarla.',
    'Esta Relíquia já revelou seu segredo para todos os seus dragões. Choque ou consiga outro dragão para usá-la.',
    '这件遗物已揭示你所有龙的对应秘密。孵化或收集另一条龙后即可使用。',
    'このレリックは所有する全ドラゴンの秘密をすでに明かしています。別のドラゴンを孵化または収集すると使えます。'
  ],
  'Understood': [
    'Verstanden',
    'Entendido',
    'Compris',
    'Capito',
    'Entendido',
    '明白了',
    '了解'
  ],
  'Expertises required': [
    'Benötigte Expertisen',
    'Pericias necesarias',
    'Expertises requises',
    'Competenze richieste',
    'Especialidades necessárias',
    '所需专长',
    '必要な専門技能'
  ],
  'Skip evolution animation': [
    'Evolutionsanimation überspringen',
    'Omitir animación de evolución',
    'Passer l’animation d’évolution',
    'Salta animazione evoluzione',
    'Pular animação de evolução',
    '跳过进化动画',
    '進化アニメーションをスキップ'
  ],
  'Portraits': [
    'Porträts',
    'Retratos',
    'Portraits',
    'Ritratti',
    'Retratos',
    '头像',
    'ポートレート'
  ],
  'Account portrait': [
    'Kontoporträt',
    'Retrato de cuenta',
    'Portrait du compte',
    'Ritratto account',
    'Retrato da conta',
    '账号头像',
    'アカウントポートレート'
  ],
  'No portraits collected yet': [
    'Noch keine Porträts gesammelt',
    'Aún no has conseguido retratos',
    'Aucun portrait collectionné',
    'Nessun ritratto raccolto',
    'Nenhum retrato coletado',
    '尚未收集头像',
    'ポートレートはまだありません'
  ],
  'Portrait Chests cost 99 gems in the Shop and always reveal a portrait you do not own yet.':
      [
    'Porträttruhen kosten im Shop 99 Edelsteine und enthüllen immer ein Porträt, das du noch nicht besitzt.',
    'Los cofres de retrato cuestan 99 gemas en la tienda y siempre revelan un retrato que aún no tienes.',
    'Les coffres de portrait coûtent 99 gemmes dans la boutique et révèlent toujours un portrait inédit.',
    'I forzieri ritratto costano 99 gemme nel negozio e rivelano sempre un ritratto che non possiedi.',
    'Baús de retrato custam 99 gemas na Loja e sempre revelam um retrato que você ainda não possui.',
    '肖像宝箱在商店售价99宝石，并且一定会开出你尚未拥有的头像。',
    'ポートレートチェストはショップで99ジェム。未所持のポートレートが必ず出ます。'
  ],
  'Choose account portrait': [
    'Kontoporträt wählen',
    'Elegir retrato de cuenta',
    'Choisir le portrait du compte',
    'Scegli ritratto account',
    'Escolher retrato da conta',
    '选择账号头像',
    'アカウントポートレートを選択'
  ],
  'Coins': ['Münzen', 'Monedas', 'Pièces', 'Monete', 'Moedas', '金币', 'コイン'],
  'Gems': ['Edelsteine', 'Gemas', 'Gemmes', 'Gemme', 'Gemas', '宝石', 'ジェム'],
  'Buy': ['Kaufen', 'Comprar', 'Acheter', 'Acquista', 'Comprar', '购买', '購入'],
  'No coin chests yet': [
    'Noch keine Münztruhen',
    'Aún no hay cofres de monedas',
    'Pas encore de coffres à pièces',
    'Nessun forziere monete per ora',
    'Ainda não há baús de moedas',
    '暂无金币宝箱',
    'コイン用チェストはまだありません'
  ],
  'Special chests may be added here in a future update.': [
    'In einem zukünftigen Update können hier besondere Truhen erscheinen.',
    'En una futura actualización podrán aparecer cofres especiales aquí.',
    'Des coffres spéciaux pourront être ajoutés ici ultérieurement.',
    'In futuro potranno essere aggiunti forzieri speciali qui.',
    'Baús especiais poderão ser adicionados aqui futuramente.',
    '未来更新可能会在这里加入特殊宝箱。',
    '今後のアップデートで特別なチェストが追加される予定です。'
  ],
  'Contains one random portrait you do not own. Its contents are decided only when opened.':
      [
    'Enthält ein zufälliges Porträt, das du noch nicht besitzt. Der Inhalt wird erst beim Öffnen bestimmt.',
    'Contiene un retrato aleatorio que no tienes. El contenido se decide al abrirlo.',
    'Contient un portrait aléatoire inédit. Son contenu est déterminé à l’ouverture.',
    'Contiene un ritratto casuale che non possiedi. Il contenuto viene deciso solo all’apertura.',
    'Contém um retrato aleatório que você ainda não possui. O conteúdo só é decidido ao abrir.',
    '包含一个随机的未拥有头像，内容只在开启时决定。',
    '未所持のポートレートが1つ入っています。中身は開封時に決まります。'
  ],
  'Collection complete': [
    'Sammlung vollständig',
    'Colección completa',
    'Collection complète',
    'Collezione completa',
    'Coleção completa',
    '收藏完成',
    'コレクション完成'
  ],
  'Portrait Chest added to your Inventory.': [
    'Porträttruhe zum Inventar hinzugefügt.',
    'Cofre de retrato añadido al Inventario.',
    'Coffre de portrait ajouté à l’Inventaire.',
    'Forziere ritratto aggiunto all’Inventario.',
    'Baú de retrato adicionado ao Inventário.',
    '肖像宝箱已加入物品栏。',
    'ポートレートチェストをインベントリに追加しました。'
  ],
  'You already own all 100 portraits.': [
    'Du besitzt bereits alle 100 Porträts.',
    'Ya tienes los 100 retratos.',
    'Tu possèdes déjà les 100 portraits.',
    'Possiedi già tutti e 100 i ritratti.',
    'Você já possui todos os 100 retratos.',
    '你已经拥有全部100个头像。',
    '100種類すべてのポートレートを所持しています。'
  ],
  'You already own all 100 portraits, so another Portrait Chest cannot be purchased.':
      [
    'Du besitzt bereits alle 100 Porträts, daher kann keine weitere Porträttruhe gekauft werden.',
    'Ya tienes los 100 retratos, así que no puedes comprar otro cofre de retrato.',
    'Tu possèdes déjà les 100 portraits, il est donc impossible d’acheter un autre coffre de portrait.',
    'Possiedi già tutti e 100 i ritratti, quindi non puoi acquistare un altro forziere ritratto.',
    'Você já possui todos os 100 retratos, então não pode comprar outro baú de retrato.',
    '你已经拥有全部100个头像，因此无法再购买肖像宝箱。',
    '100種類すべてを所持しているため、追加のポートレートチェストは購入できません。'
  ],
  'Portrait revealed': [
    'Porträt enthüllt',
    'Retrato revelado',
    'Portrait révélé',
    'Ritratto rivelato',
    'Retrato revelado',
    '头像已揭晓',
    'ポートレート出現'
  ],
  'Added to your portrait collection': [
    'Deiner Porträtsammlung hinzugefügt',
    'Añadido a tu colección de retratos',
    'Ajouté à ta collection de portraits',
    'Aggiunto alla tua collezione di ritratti',
    'Adicionado à sua coleção de retratos',
    '已加入头像收藏',
    'ポートレートコレクションに追加しました'
  ],
  'Portrait collection complete': [
    'Porträtsammlung vollständig',
    'Colección de retratos completa',
    'Collection de portraits complète',
    'Collezione ritratti completa',
    'Coleção de retratos completa',
    '头像收藏完成',
    'ポートレートコレクション完成'
  ],
  'You already own all 100 portraits. This Portrait Chest stays safely in your Inventory and cannot be opened.':
      [
    'Du besitzt bereits alle 100 Porträts. Diese Porträttruhe bleibt sicher im Inventar und kann nicht geöffnet werden.',
    'Ya tienes los 100 retratos. Este cofre permanece a salvo en tu Inventario y no puede abrirse.',
    'Tu possèdes déjà les 100 portraits. Ce coffre reste dans ton Inventaire et ne peut pas être ouvert.',
    'Possiedi già tutti e 100 i ritratti. Il forziere rimane al sicuro nell’Inventario e non può essere aperto.',
    'Você já possui todos os 100 retratos. Este baú fica seguro no Inventário e não pode ser aberto.',
    '你已经拥有全部100个头像。该肖像宝箱会安全保留在物品栏中，无法开启。',
    '100種類すべてを所持しているため、このチェストはインベントリに残り、開封できません。'
  ],
  'Portrait Chest': [
    'Porträttruhe',
    'Cofre de retrato',
    'Coffre de portrait',
    'Forziere ritratto',
    'Baú de retrato',
    '肖像宝箱',
    'ポートレートチェスト'
  ],
  'Infernal': [
    'Infernalisch',
    'Infernal',
    'Infernal',
    'Infernale',
    'Infernal',
    '炼狱',
    'インファーナル'
  ],
  'A Portrait Chest is waiting in your Inventory.': [
    'Eine Porträttruhe wartet in deinem Inventar.',
    'Hay un cofre de retrato esperando en tu Inventario.',
    'Un coffre de portrait t’attend dans ton Inventaire.',
    'Un forziere ritratto ti aspetta nell’Inventario.',
    'Um baú de retrato está esperando no seu Inventário.',
    '一个肖像宝箱正在物品栏中等着你。',
    'ポートレートチェストがインベントリで待っています。'
  ],
  'A new account portrait joined your collection.': [
    'Ein neues Kontoporträt wurde deiner Sammlung hinzugefügt.',
    'Un nuevo retrato de cuenta se unió a tu colección.',
    'Un nouveau portrait de compte a rejoint ta collection.',
    'Un nuovo ritratto account si è aggiunto alla collezione.',
    'Um novo retrato de conta entrou na sua coleção.',
    '一个新的账号头像已加入收藏。',
    '新しいアカウントポートレートがコレクションに加わりました。'
  ],
  'Titles': ['Titel', 'Títulos', 'Titres', 'Titoli', 'Títulos', '称号', '称号'],
  'Choose account title': [
    'Kontotitel wählen',
    'Elegir título de cuenta',
    'Choisir le titre du compte',
    'Scegli il titolo dell’account',
    'Escolher título da conta',
    '选择账号称号',
    'アカウント称号を選択'
  ],
  'Title Chest': [
    'Titeltruhe',
    'Cofre de títulos',
    'Coffre de titres',
    'Forziere dei titoli',
    'Baú de títulos',
    '称号宝箱',
    '称号チェスト'
  ],
  'Contains one random account title you do not own. Its contents are decided only when opened.':
      [
    'Enthält einen zufälligen Kontotitel, den du noch nicht besitzt. Der Inhalt wird erst beim Öffnen bestimmt.',
    'Contiene un título de cuenta aleatorio que aún no tienes. El contenido se decide al abrirlo.',
    'Contient un titre de compte aléatoire que tu ne possèdes pas. Son contenu est déterminé à l’ouverture.',
    'Contiene un titolo account casuale che non possiedi. Il contenuto viene deciso solo all’apertura.',
    'Contém um título de conta aleatório que você ainda não possui. O conteúdo é definido apenas ao abrir.',
    '包含一个你尚未拥有的随机账号称号，内容仅在开启时决定。',
    '未所持のアカウント称号が1つランダムで入っています。内容は開封時に決まります。'
  ],
  'Title Chest added to your Inventory.': [
    'Titeltruhe deinem Inventar hinzugefügt.',
    'Cofre de títulos añadido a tu Inventario.',
    'Coffre de titres ajouté à ton Inventaire.',
    'Forziere dei titoli aggiunto all’Inventario.',
    'Baú de títulos adicionado ao Inventário.',
    '称号宝箱已加入物品栏。',
    '称号チェストをインベントリに追加しました。'
  ],
  'You already own all 500 account titles, so another Title Chest cannot be purchased.':
      [
    'Du besitzt bereits alle 500 Kontotitel, daher kann keine weitere Titeltruhe gekauft werden.',
    'Ya tienes los 500 títulos de cuenta, así que no puedes comprar otro cofre de títulos.',
    'Tu possèdes déjà les 500 titres de compte, il est donc impossible d’acheter un autre coffre de titres.',
    'Possiedi già tutti i 500 titoli account, quindi non puoi acquistare un altro forziere dei titoli.',
    'Você já possui todos os 500 títulos de conta, então não pode comprar outro baú de títulos.',
    '你已经拥有全部500个账号称号，因此无法再购买称号宝箱。',
    '500種類すべてのアカウント称号を所持しているため、追加の称号チェストは購入できません。'
  ],
  'Title revealed': [
    'Titel enthüllt',
    'Título revelado',
    'Titre révélé',
    'Titolo rivelato',
    'Título revelado',
    '称号已揭晓',
    '称号出現'
  ],
  'Added to your title collection': [
    'Deiner Titelsammlung hinzugefügt',
    'Añadido a tu colección de títulos',
    'Ajouté à ta collection de titres',
    'Aggiunto alla tua collezione di titoli',
    'Adicionado à sua coleção de títulos',
    '已加入称号收藏',
    '称号コレクションに追加しました'
  ],
  'Title collection complete': [
    'Titelsammlung vollständig',
    'Colección de títulos completa',
    'Collection de titres complète',
    'Collezione titoli completa',
    'Coleção de títulos completa',
    '称号收藏完成',
    '称号コレクション完成'
  ],
  'You already own all 500 account titles. This Title Chest stays safely in your Inventory and cannot be opened.':
      [
    'Du besitzt bereits alle 500 Kontotitel. Diese Titeltruhe bleibt sicher im Inventar und kann nicht geöffnet werden.',
    'Ya tienes los 500 títulos de cuenta. Este cofre permanece a salvo en tu Inventario y no puede abrirse.',
    'Tu possèdes déjà les 500 titres de compte. Ce coffre reste dans ton Inventaire et ne peut pas être ouvert.',
    'Possiedi già tutti i 500 titoli account. Il forziere rimane al sicuro nell’Inventario e non può essere aperto.',
    'Você já possui todos os 500 títulos de conta. Este baú fica seguro no Inventário e não pode ser aberto.',
    '你已经拥有全部500个账号称号。该称号宝箱会安全保留在物品栏中，无法开启。',
    '500種類すべてのアカウント称号を所持しているため、このチェストはインベントリに残り、開封できません。'
  ],
  'A Title Chest is waiting in your Inventory.': [
    'Eine Titeltruhe wartet in deinem Inventar.',
    'Hay un cofre de títulos esperando en tu Inventario.',
    'Un coffre de titres t’attend dans ton Inventaire.',
    'Un forziere dei titoli ti aspetta nell’Inventario.',
    'Um baú de títulos está esperando no seu Inventário.',
    '一个称号宝箱正在物品栏中等着你。',
    '称号チェストがインベントリで待っています。'
  ],
  'A request is already pending.': [
    'Eine Anfrage steht bereits aus.',
    'Ya hay una solicitud pendiente.',
    'Une demande est déjà en attente.',
    'Una richiesta è già in attesa.',
    'Já existe uma solicitação pendente.',
    '已有一个待处理的请求。',
    'すでに保留中の申請があります。'
  ],
  'Accept': [
    'Akzeptieren',
    'Aceptar',
    'Accepter',
    'Accetta',
    'Aceitar',
    '接受',
    '承認'
  ],
  'Add by Keeper ID': [
    'Per Hüter-ID hinzufügen',
    'Añadir por ID de Guardián',
    'Ajouter par ID de Gardien',
    'Aggiungi tramite ID Custode',
    'Adicionar por ID de Guardião',
    '通过守护者 ID 添加',
    'キーパーIDで追加'
  ],
  'An account already exists for this email.': [
    'Für diese E-Mail-Adresse existiert bereits ein Konto.',
    'Ya existe una cuenta para este correo electrónico.',
    'Un compte existe déjà pour cette adresse e-mail.',
    'Esiste già un account per questa e-mail.',
    'Já existe uma conta para este e-mail.',
    '此电子邮箱已注册账户。',
    'このメールアドレスのアカウントはすでに存在します。'
  ],
  'Block': [
    'Blockieren',
    'Bloquear',
    'Bloquer',
    'Blocca',
    'Bloquear',
    '屏蔽',
    'ブロック'
  ],
  'Block keeper': [
    'Hüter blockieren',
    'Bloquear Guardián',
    'Bloquer le Gardien',
    'Blocca Custode',
    'Bloquear Guardião',
    '屏蔽守护者',
    'キーパーをブロック'
  ],
  'Blocked': [
    'Blockiert',
    'Bloqueados',
    'Bloqués',
    'Bloccati',
    'Bloqueados',
    '已屏蔽',
    'ブロック中'
  ],
  'Check your email to confirm the account, then sign in.': [
    'Bestätige das Konto über deine E-Mail und melde dich danach an.',
    'Revisa tu correo para confirmar la cuenta y luego inicia sesión.',
    'Consulte ton e-mail pour confirmer le compte, puis connecte-toi.',
    'Controlla l’e-mail per confermare l’account, poi accedi.',
    'Verifique seu e-mail para confirmar a conta e depois entre.',
    '请查看电子邮件确认账户，然后登录。',
    'メールでアカウントを確認してからログインしてください。'
  ],
  'Connect your keeper': [
    'Verbinde deinen Hüter',
    'Conecta a tu Guardián',
    'Connecte ton Gardien',
    'Collega il tuo Custode',
    'Conecte seu Guardião',
    '连接你的守护者',
    'キーパーを接続'
  ],
  'Copy Keeper ID': [
    'Hüter-ID kopieren',
    'Copiar ID de Guardián',
    'Copier l’ID de Gardien',
    'Copia ID Custode',
    'Copiar ID de Guardião',
    '复制守护者 ID',
    'キーパーIDをコピー'
  ],
  'Create': ['Erstellen', 'Crear', 'Créer', 'Crea', 'Criar', '创建', '作成'],
  'Create a simple account to add friends by Keeper ID. Your email is never shown to other players.':
      [
    'Erstelle ein einfaches Konto, um Freunde per Hüter-ID hinzuzufügen. Deine E-Mail wird anderen Spielern nie angezeigt.',
    'Crea una cuenta sencilla para añadir amigos por ID de Guardián. Tu correo nunca se muestra a otros jugadores.',
    'Crée un compte simple pour ajouter des amis par ID de Gardien. Ton e-mail n’est jamais montré aux autres joueurs.',
    'Crea un account semplice per aggiungere amici tramite ID Custode. La tua e-mail non viene mai mostrata agli altri giocatori.',
    'Crie uma conta simples para adicionar amigos pelo ID de Guardião. Seu e-mail nunca é exibido a outros jogadores.',
    '创建简单账户即可通过守护者 ID 添加好友。你的电子邮箱绝不会向其他玩家显示。',
    'シンプルなアカウントを作成すると、キーパーIDでフレンドを追加できます。メールアドレスが他のプレイヤーに表示されることはありません。'
  ],
  'Create account': [
    'Konto erstellen',
    'Crear cuenta',
    'Créer un compte',
    'Crea account',
    'Criar conta',
    '创建账户',
    'アカウントを作成'
  ],
  'Create online account': [
    'Online-Konto erstellen',
    'Crear cuenta en línea',
    'Créer un compte en ligne',
    'Crea account online',
    'Criar conta online',
    '创建在线账户',
    'オンラインアカウントを作成'
  ],
  'Discovered': [
    'Entdeckt',
    'Descubiertos',
    'Découverts',
    'Scoperti',
    'Descobertos',
    '已发现',
    '発見済み'
  ],
  'Discovered dragons': [
    'Entdeckte Drachen',
    'Dragones descubiertos',
    'Dragons découverts',
    'Draghi scoperti',
    'Dragões descobertos',
    '已发现的龙',
    '発見したドラゴン'
  ],
  'Edit online profile': [
    'Online-Profil bearbeiten',
    'Editar perfil en línea',
    'Modifier le profil en ligne',
    'Modifica profilo online',
    'Editar perfil online',
    '编辑在线资料',
    'オンラインプロフィールを編集'
  ],
  'Edit profile': [
    'Profil bearbeiten',
    'Editar perfil',
    'Modifier le profil',
    'Modifica profilo',
    'Editar perfil',
    '编辑资料',
    'プロフィールを編集'
  ],
  'Enter a name.': [
    'Gib einen Namen ein.',
    'Introduce un nombre.',
    'Saisis un nom.',
    'Inserisci un nome.',
    'Digite um nome.',
    '请输入名称。',
    '名前を入力してください。'
  ],
  'Enter a valid email.': [
    'Gib eine gültige E-Mail-Adresse ein.',
    'Introduce un correo electrónico válido.',
    'Saisis une adresse e-mail valide.',
    'Inserisci un indirizzo e-mail valido.',
    'Digite um e-mail válido.',
    '请输入有效的电子邮箱。',
    '有効なメールアドレスを入力してください。'
  ],
  'Favorite dragon': [
    'Lieblingsdrache',
    'Dragón favorito',
    'Dragon favori',
    'Drago preferito',
    'Dragão favorito',
    '最喜爱的龙',
    'お気に入りのドラゴン'
  ],
  'Find trusted keepers, compare collections and visit their profiles.': [
    'Finde vertrauenswürdige Hüter, vergleiche Sammlungen und besuche ihre Profile.',
    'Encuentra Guardianes de confianza, compara colecciones y visita sus perfiles.',
    'Trouve des Gardiens de confiance, compare les collections et consulte leurs profils.',
    'Trova Custodi fidati, confronta le collezioni e visita i loro profili.',
    'Encontre Guardiões confiáveis, compare coleções e visite seus perfis.',
    '寻找可信的守护者、比较收藏并查看他们的资料。',
    '信頼できるキーパーを見つけ、コレクションを比べてプロフィールを訪問しましょう。'
  ],
  'Friend removed for both keepers.': [
    'Die Freundschaft wurde für beide Hüter entfernt.',
    'La amistad se eliminó para ambos Guardianes.',
    'L’amitié a été supprimée pour les deux Gardiens.',
    'L’amicizia è stata rimossa per entrambi i Custodi.',
    'A amizade foi removida para ambos os Guardiões.',
    '双方守护者的好友关系已移除。',
    '両方のキーパーのフレンド関係を削除しました。'
  ],
  'Friend request sent.': [
    'Freundschaftsanfrage gesendet.',
    'Solicitud de amistad enviada.',
    'Demande d’amitié envoyée.',
    'Richiesta di amicizia inviata.',
    'Solicitação de amizade enviada.',
    '好友请求已发送。',
    'フレンド申請を送信しました。'
  ],
  'Friend requests': [
    'Freundschaftsanfragen',
    'Solicitudes de amistad',
    'Demandes d’amitié',
    'Richieste di amicizia',
    'Solicitações de amizade',
    '好友请求',
    'フレンド申請'
  ],
  'Incorrect email or password.': [
    'E-Mail oder Passwort ist falsch.',
    'Correo o contraseña incorrectos.',
    'E-mail ou mot de passe incorrect.',
    'E-mail o password errati.',
    'E-mail ou senha incorretos.',
    '电子邮箱或密码错误。',
    'メールアドレスまたはパスワードが正しくありません。'
  ],
  'Keeper blocked.': [
    'Hüter blockiert.',
    'Guardián bloqueado.',
    'Gardien bloqué.',
    'Custode bloccato.',
    'Guardião bloqueado.',
    '守护者已屏蔽。',
    'キーパーをブロックしました。'
  ],
  'Keeper ID copied.': [
    'Hüter-ID kopiert.',
    'ID de Guardián copiado.',
    'ID de Gardien copié.',
    'ID Custode copiato.',
    'ID de Guardião copiado.',
    '守护者 ID 已复制。',
    'キーパーIDをコピーしました。'
  ],
  'Keeper name': [
    'Hütername',
    'Nombre del Guardián',
    'Nom du Gardien',
    'Nome Custode',
    'Nome do Guardião',
    '守护者名称',
    'キーパー名'
  ],
  'Keeper unblocked.': [
    'Hüter entsperrt.',
    'Guardián desbloqueado.',
    'Gardien débloqué.',
    'Custode sbloccato.',
    'Guardião desbloqueado.',
    '已取消屏蔽守护者。',
    'キーパーのブロックを解除しました。'
  ],
  'No favorite dragon selected.': [
    'Kein Lieblingsdrache ausgewählt.',
    'No se ha elegido un dragón favorito.',
    'Aucun dragon favori sélectionné.',
    'Nessun drago preferito selezionato.',
    'Nenhum dragão favorito selecionado.',
    '尚未选择最喜爱的龙。',
    'お気に入りのドラゴンが選ばれていません。'
  ],
  'No friends yet. Share your Keeper ID or add someone else.': [
    'Noch keine Freunde. Teile deine Hüter-ID oder füge jemanden hinzu.',
    'Aún no tienes amigos. Comparte tu ID de Guardián o añade a alguien.',
    'Pas encore d’amis. Partage ton ID de Gardien ou ajoute quelqu’un.',
    'Ancora nessun amico. Condividi il tuo ID Custode o aggiungi qualcuno.',
    'Ainda não há amigos. Compartilhe seu ID de Guardião ou adicione alguém.',
    '还没有好友。分享你的守护者 ID 或添加其他人。',
    'まだフレンドはいません。キーパーIDを共有するか、誰かを追加しましょう。'
  ],
  'No keeper with that ID was found.': [
    'Kein Hüter mit dieser ID wurde gefunden.',
    'No se encontró ningún Guardián con ese ID.',
    'Aucun Gardien avec cet ID n’a été trouvé.',
    'Nessun Custode trovato con questo ID.',
    'Nenhum Guardião com esse ID foi encontrado.',
    '未找到使用该 ID 的守护者。',
    'そのIDのキーパーは見つかりませんでした。'
  ],
  'Online account': [
    'Online-Konto',
    'Cuenta en línea',
    'Compte en ligne',
    'Account online',
    'Conta online',
    '在线账户',
    'オンラインアカウント'
  ],
  'Online accounts are ready in this build, but this installation still needs its server URL and publishable key.':
      [
    'Online-Konten sind in diesem Build bereit, aber dieser Installation fehlen noch Server-URL und öffentlicher Schlüssel.',
    'Las cuentas en línea están listas, pero esta instalación aún necesita la URL del servidor y la clave pública.',
    'Les comptes en ligne sont prêts, mais cette installation nécessite encore l’URL du serveur et la clé publique.',
    'Gli account online sono pronti, ma questa installazione richiede ancora l’URL del server e la chiave pubblica.',
    'As contas online estão prontas, mas esta instalação ainda precisa da URL do servidor e da chave pública.',
    '此版本已支持在线账户，但此安装仍需要服务器 URL 和公开密钥。',
    'オンラインアカウントには対応していますが、このインストールにはサーバーURLと公開キーが必要です。'
  ],
  'Password': [
    'Passwort',
    'Contraseña',
    'Mot de passe',
    'Password',
    'Senha',
    '密码',
    'パスワード'
  ],
  'Pending': [
    'Ausstehend',
    'Pendiente',
    'En attente',
    'In attesa',
    'Pendente',
    '待处理',
    '保留中'
  ],
  'Profile saved.': [
    'Profil gespeichert.',
    'Perfil guardado.',
    'Profil enregistré.',
    'Profilo salvato.',
    'Perfil salvo.',
    '资料已保存。',
    'プロフィールを保存しました。'
  ],
  'Reject': [
    'Ablehnen',
    'Rechazar',
    'Refuser',
    'Rifiuta',
    'Recusar',
    '拒绝',
    '拒否'
  ],
  'Remove friend': [
    'Freund entfernen',
    'Eliminar amigo',
    'Retirer l’ami',
    'Rimuovi amico',
    'Remover amigo',
    '删除好友',
    'フレンドを削除'
  ],
  'Remove friend?': [
    'Freund entfernen?',
    '¿Eliminar amigo?',
    'Retirer cet ami ?',
    'Rimuovere l’amico?',
    'Remover amigo?',
    '删除好友？',
    'フレンドを削除しますか？'
  ],
  'Send request': [
    'Anfrage senden',
    'Enviar solicitud',
    'Envoyer la demande',
    'Invia richiesta',
    'Enviar solicitação',
    '发送请求',
    '申請を送信'
  ],
  'Sent requests': [
    'Gesendete Anfragen',
    'Solicitudes enviadas',
    'Demandes envoyées',
    'Richieste inviate',
    'Solicitações enviadas',
    '已发送的请求',
    '送信済み申請'
  ],
  'Server setup required': [
    'Server-Einrichtung erforderlich',
    'Configuración del servidor necesaria',
    'Configuration du serveur requise',
    'Configurazione server necessaria',
    'Configuração do servidor necessária',
    '需要配置服务器',
    'サーバー設定が必要です'
  ],
  'Sign in': [
    'Anmelden',
    'Iniciar sesión',
    'Se connecter',
    'Accedi',
    'Entrar',
    '登录',
    'ログイン'
  ],
  'Sign out': [
    'Abmelden',
    'Cerrar sesión',
    'Se déconnecter',
    'Esci',
    'Sair',
    '退出登录',
    'ログアウト'
  ],
  'The online service could not complete this action. Please try again.': [
    'Der Onlinedienst konnte diese Aktion nicht abschließen. Versuche es erneut.',
    'El servicio en línea no pudo completar esta acción. Inténtalo de nuevo.',
    'Le service en ligne n’a pas pu terminer cette action. Réessaie.',
    'Il servizio online non ha potuto completare l’azione. Riprova.',
    'O serviço online não conseguiu concluir esta ação. Tente novamente.',
    '在线服务无法完成此操作。请重试。',
    'オンラインサービスでこの操作を完了できませんでした。もう一度お試しください。'
  ],
  'This installation has no online server configuration yet.': [
    'Diese Installation hat noch keine Online-Serverkonfiguration.',
    'Esta instalación aún no tiene configuración de servidor en línea.',
    'Cette installation n’a pas encore de configuration de serveur en ligne.',
    'Questa installazione non ha ancora una configurazione server online.',
    'Esta instalação ainda não possui configuração de servidor online.',
    '此安装尚未配置在线服务器。',
    'このインストールにはオンラインサーバー設定がありません。'
  ],
  'This keeper is unavailable.': [
    'Dieser Hüter ist nicht verfügbar.',
    'Este Guardián no está disponible.',
    'Ce Gardien est indisponible.',
    'Questo Custode non è disponibile.',
    'Este Guardião não está disponível.',
    '此守护者不可用。',
    'このキーパーは利用できません。'
  ],
  'This request was recently rejected. Try again later.': [
    'Diese Anfrage wurde kürzlich abgelehnt. Versuche es später erneut.',
    'Esta solicitud se rechazó recientemente. Inténtalo más tarde.',
    'Cette demande a été refusée récemment. Réessaie plus tard.',
    'Questa richiesta è stata rifiutata di recente. Riprova più tardi.',
    'Esta solicitação foi recusada recentemente. Tente novamente mais tarde.',
    '此请求最近被拒绝。请稍后重试。',
    'この申請は最近拒否されました。後でもう一度お試しください。'
  ],
  'Title': ['Titel', 'Título', 'Titre', 'Titolo', 'Título', '称号', '称号'],
  'Too many requests are pending.': [
    'Zu viele Anfragen stehen aus.',
    'Hay demasiadas solicitudes pendientes.',
    'Trop de demandes sont en attente.',
    'Ci sono troppe richieste in attesa.',
    'Há solicitações pendentes demais.',
    '待处理的请求过多。',
    '保留中の申請が多すぎます。'
  ],
  'Unblock': [
    'Entsperren',
    'Desbloquear',
    'Débloquer',
    'Sblocca',
    'Desbloquear',
    '取消屏蔽',
    'ブロック解除'
  ],
  'Use at least 8 characters.': [
    'Verwende mindestens 8 Zeichen.',
    'Usa al menos 8 caracteres.',
    'Utilise au moins 8 caractères.',
    'Usa almeno 8 caratteri.',
    'Use pelo menos 8 caracteres.',
    '请至少使用 8 个字符。',
    '8文字以上使用してください。'
  ],
  'You are already friends.': [
    'Ihr seid bereits Freunde.',
    'Ya sois amigos.',
    'Vous êtes déjà amis.',
    'Siete già amici.',
    'Vocês já são amigos.',
    '你们已经是好友。',
    'すでにフレンドです。'
  ],
  'You cannot add yourself.': [
    'Du kannst dich nicht selbst hinzufügen.',
    'No puedes añadirte a ti mismo.',
    'Tu ne peux pas t’ajouter toi-même.',
    'Non puoi aggiungere te stesso.',
    'Você não pode adicionar a si mesmo.',
    '你不能添加自己。',
    '自分自身を追加することはできません。'
  ],
  'Your online account is ready.': [
    'Dein Online-Konto ist bereit.',
    'Tu cuenta en línea está lista.',
    'Ton compte en ligne est prêt.',
    'Il tuo account online è pronto.',
    'Sua conta online está pronta.',
    '你的在线账户已准备就绪。',
    'オンラインアカウントの準備ができました。'
  ],
  'A new account title joined your collection.': [
    'Ein neuer Kontotitel wurde deiner Sammlung hinzugefügt.',
    'Un nuevo título de cuenta se unió a tu colección.',
    'Un nouveau titre de compte a rejoint ta collection.',
    'Un nuovo titolo account si è aggiunto alla collezione.',
    'Um novo título de conta entrou na sua coleção.',
    '一个新的账号称号已加入收藏。',
    '新しいアカウント称号がコレクションに加わりました。'
  ],
  'Cancel trade': [
    'Handel abbrechen',
    'Cancelar intercambio',
    'Annuler l’échange',
    'Annulla scambio',
    'Cancelar troca',
    '取消交易',
    '交換をキャンセル'
  ],
  'Chest': ['Truhe', 'Cofre', 'Coffre', 'Forziere', 'Baú', '宝箱', '宝箱'],
  'Choose my item': [
    'Meinen Gegenstand wählen',
    'Elegir mi objeto',
    'Choisir mon objet',
    'Scegli il mio oggetto',
    'Escolher meu item',
    '选择我的物品',
    '自分のアイテムを選ぶ'
  ],
  'Choose one item': [
    'Einen Gegenstand wählen',
    'Elige un objeto',
    'Choisis un objet',
    'Scegli un oggetto',
    'Escolha um item',
    '选择一件物品',
    'アイテムを1つ選ぶ'
  ],
  'Complete this trade?': [
    'Diesen Handel abschließen?',
    '¿Completar este intercambio?',
    'Finaliser cet échange ?',
    'Completare questo scambio?',
    'Concluir esta troca?',
    '完成这笔交易吗？',
    'この交換を完了しますか？'
  ],
  'Final confirmation': [
    'Endgültig bestätigen',
    'Confirmación final',
    'Confirmation finale',
    'Conferma finale',
    'Confirmação final',
    '最终确认',
    '最終確認'
  ],
  'New trade proposal': [
    'Neues Handelsangebot',
    'Nueva propuesta de intercambio',
    'Nouvelle proposition d’échange',
    'Nuova proposta di scambio',
    'Nova proposta de troca',
    '新的交易提议',
    '新しい交換提案'
  ],
  'Open trade': [
    'Handel öffnen',
    'Abrir intercambio',
    'Ouvrir l’échange',
    'Apri scambio',
    'Abrir troca',
    '打开交易',
    '交換を開く'
  ],
  'Reject trade': [
    'Handel ablehnen',
    'Rechazar intercambio',
    'Refuser l’échange',
    'Rifiuta scambio',
    'Recusar troca',
    '拒绝交易',
    '交換を拒否'
  ],
  'Relic': [
    'Relikt',
    'Reliquia',
    'Relique',
    'Reliquia',
    'Relíquia',
    '遗物',
    'レリック'
  ],
  'Reserved for trade': [
    'Für Handel reserviert',
    'Reservado para intercambio',
    'Réservé pour un échange',
    'Riservato per lo scambio',
    'Reservado para troca',
    '已为交易保留',
    '交換用に予約済み'
  ],
  'Send': ['Senden', 'Enviar', 'Envoyer', 'Invia', 'Enviar', '发送', '送信'],
  'Send trade proposal?': [
    'Handelsangebot senden?',
    '¿Enviar propuesta de intercambio?',
    'Envoyer la proposition d’échange ?',
    'Inviare la proposta di scambio?',
    'Enviar proposta de troca?',
    '发送交易提议吗？',
    '交換提案を送りますか？'
  ],
  'The completed trade could not be stored locally. Your server items remain safe; please refresh.':
      [
    'Der abgeschlossene Handel konnte lokal nicht gespeichert werden. Deine Servergegenstände sind sicher; bitte aktualisieren.',
    'El intercambio completado no pudo guardarse localmente. Tus objetos del servidor están seguros; actualiza.',
    'L’échange terminé n’a pas pu être enregistré localement. Tes objets serveur restent en sécurité ; actualise.',
    'Lo scambio completato non è stato salvato localmente. Gli oggetti sul server sono al sicuro; aggiorna.',
    'A troca concluída não pôde ser salva localmente. Seus itens no servidor estão seguros; atualize.',
    '已完成的交易无法保存在本地。服务器物品仍然安全；请刷新。',
    '完了した交換を端末に保存できませんでした。サーバー上のアイテムは安全です。更新してください。'
  ],
  'The item is kept safe and cannot be used in another trade.': [
    'Der Gegenstand wird sicher verwahrt und kann nicht in einem anderen Handel verwendet werden.',
    'El objeto queda protegido y no puede usarse en otro intercambio.',
    'L’objet est conservé en sécurité et ne peut pas servir dans un autre échange.',
    'L’oggetto viene custodito e non può essere usato in un altro scambio.',
    'O item fica protegido e não pode ser usado em outra troca.',
    '该物品会被安全保留，不能用于其他交易。',
    'アイテムは安全に確保され、別の交換には使えません。'
  ],
  'This is the final confirmation. Both items will change owner immediately.': [
    'Dies ist die endgültige Bestätigung. Beide Gegenstände wechseln sofort den Besitzer.',
    'Esta es la confirmación final. Ambos objetos cambiarán de dueño inmediatamente.',
    'C’est la confirmation finale. Les deux objets changeront immédiatement de propriétaire.',
    'Questa è la conferma finale. Entrambi gli oggetti cambieranno subito proprietario.',
    'Esta é a confirmação final. Os dois itens mudarão de dono imediatamente.',
    '这是最终确认。两件物品会立即交换所有者。',
    'これが最終確認です。両方のアイテムはすぐに所有者が変わります。'
  ],
  'This item cannot be traded.': [
    'Dieser Gegenstand kann nicht gehandelt werden.',
    'Este objeto no se puede intercambiar.',
    'Cet objet ne peut pas être échangé.',
    'Questo oggetto non può essere scambiato.',
    'Este item não pode ser trocado.',
    '该物品无法交易。',
    'このアイテムは交換できません。'
  ],
  'This item is no longer available or is already reserved.': [
    'Dieser Gegenstand ist nicht mehr verfügbar oder bereits reserviert.',
    'Este objeto ya no está disponible o ya está reservado.',
    'Cet objet n’est plus disponible ou est déjà réservé.',
    'Questo oggetto non è più disponibile o è già riservato.',
    'Este item não está mais disponível ou já está reservado.',
    '该物品已不可用或已被保留。',
    'このアイテムは利用できないか、すでに予約されています。'
  ],
  'This trade has already changed. Refresh and try again.': [
    'Dieser Handel hat sich bereits geändert. Aktualisiere und versuche es erneut.',
    'Este intercambio ya ha cambiado. Actualiza e inténtalo de nuevo.',
    'Cet échange a déjà changé. Actualise et réessaie.',
    'Questo scambio è già cambiato. Aggiorna e riprova.',
    'Esta troca já mudou. Atualize e tente novamente.',
    '该交易已发生变化。请刷新后重试。',
    'この交換はすでに変更されています。更新してもう一度お試しください。'
  ],
  'Trade': [
    'Handeln',
    'Intercambiar',
    'Échanger',
    'Scambia',
    'Trocar',
    '交易',
    '交換'
  ],
  'Trade cancelled': [
    'Handel abgebrochen',
    'Intercambio cancelado',
    'Échange annulé',
    'Scambio annullato',
    'Troca cancelada',
    '交易已取消',
    '交換はキャンセルされました'
  ],
  'Trade cancelled. Reserved items are available again.': [
    'Handel abgebrochen. Reservierte Gegenstände sind wieder verfügbar.',
    'Intercambio cancelado. Los objetos reservados vuelven a estar disponibles.',
    'Échange annulé. Les objets réservés sont de nouveau disponibles.',
    'Scambio annullato. Gli oggetti riservati sono di nuovo disponibili.',
    'Troca cancelada. Os itens reservados estão disponíveis novamente.',
    '交易已取消。保留的物品可再次使用。',
    '交換をキャンセルしました。予約アイテムは再び利用できます。'
  ],
  'Trade completed': [
    'Handel abgeschlossen',
    'Intercambio completado',
    'Échange terminé',
    'Scambio completato',
    'Troca concluída',
    '交易完成',
    '交換完了'
  ],
  'Trade completed. The received item is in your inventory.': [
    'Handel abgeschlossen. Der erhaltene Gegenstand ist in deinem Inventar.',
    'Intercambio completado. El objeto recibido está en tu inventario.',
    'Échange terminé. L’objet reçu est dans ton inventaire.',
    'Scambio completato. L’oggetto ricevuto è nel tuo inventario.',
    'Troca concluída. O item recebido está no seu inventário.',
    '交易完成。收到的物品已放入库存。',
    '交換完了。受け取ったアイテムはインベントリにあります。'
  ],
  'Trade proposal sent.': [
    'Handelsangebot gesendet.',
    'Propuesta de intercambio enviada.',
    'Proposition d’échange envoyée.',
    'Proposta di scambio inviata.',
    'Proposta de troca enviada.',
    '交易提议已发送。',
    '交換提案を送信しました。'
  ],
  'Trade rejected': [
    'Handel abgelehnt',
    'Intercambio rechazado',
    'Échange refusé',
    'Scambio rifiutato',
    'Troca recusada',
    '交易已拒绝',
    '交換は拒否されました'
  ],
  'Trade rejected. Reserved items are available again.': [
    'Handel abgelehnt. Reservierte Gegenstände sind wieder verfügbar.',
    'Intercambio rechazado. Los objetos reservados vuelven a estar disponibles.',
    'Échange refusé. Les objets réservés sont de nouveau disponibles.',
    'Scambio rifiutato. Gli oggetti riservati sono di nuovo disponibili.',
    'Troca recusada. Os itens reservados estão disponíveis novamente.',
    '交易已拒绝。保留的物品可再次使用。',
    '交換を拒否しました。予約アイテムは再び利用できます。'
  ],
  'Trade with this friend': [
    'Mit diesem Freund handeln',
    'Intercambiar con este amigo',
    'Échanger avec cet ami',
    'Scambia con questo amico',
    'Trocar com este amigo',
    '与这位好友交易',
    'このフレンドと交換'
  ],
  'Trades are only available between friends.': [
    'Handel ist nur zwischen Freunden möglich.',
    'Los intercambios solo están disponibles entre amigos.',
    'Les échanges sont réservés aux amis.',
    'Gli scambi sono disponibili solo tra amici.',
    'Trocas estão disponíveis apenas entre amigos.',
    '只有好友之间可以交易。',
    '交換はフレンド同士でのみ利用できます。'
  ],
  'Waiting for a return item.': [
    'Warten auf einen Gegengegenstand.',
    'Esperando un objeto a cambio.',
    'En attente d’un objet en retour.',
    'In attesa di un oggetto in cambio.',
    'Aguardando um item em troca.',
    '正在等待对方提供物品。',
    '相手のアイテムを待っています。'
  ],
  'Waiting for final confirmation': [
    'Warten auf die endgültige Bestätigung',
    'Esperando la confirmación final',
    'En attente de la confirmation finale',
    'In attesa della conferma finale',
    'Aguardando a confirmação final',
    '正在等待最终确认',
    '最終確認を待っています'
  ],
  'Waiting for your friend': [
    'Warten auf deinen Freund',
    'Esperando a tu amigo',
    'En attente de ton ami',
    'In attesa del tuo amico',
    'Aguardando seu amigo',
    '正在等待好友',
    'フレンドを待っています'
  ],
  'You have no unreserved eggs, chests or relics to trade.': [
    'Du hast keine freien Eier, Truhen oder Relikte zum Handeln.',
    'No tienes huevos, cofres ni reliquias sin reservar para intercambiar.',
    'Tu n’as aucun œuf, coffre ou relique libre à échanger.',
    'Non hai uova, forzieri o reliquie liberi da scambiare.',
    'Você não tem ovos, baús ou relíquias livres para trocar.',
    '你没有可交易的未保留蛋、宝箱或遗物。',
    '交換できる未予約の卵、宝箱、レリックがありません。'
  ],
  'You have too many active trades. Finish or cancel one first.': [
    'Du hast zu viele aktive Handel. Schließe zuerst einen ab oder brich ihn ab.',
    'Tienes demasiados intercambios activos. Completa o cancela uno primero.',
    'Tu as trop d’échanges actifs. Termine ou annule-en un d’abord.',
    'Hai troppi scambi attivi. Completane o annullane prima uno.',
    'Você tem trocas ativas demais. Conclua ou cancele uma primeiro.',
    '你的进行中交易过多。请先完成或取消一笔。',
    '進行中の交換が多すぎます。先に1件完了またはキャンセルしてください。'
  ],
  'You offer': [
    'Du bietest an',
    'Tú ofreces',
    'Tu proposes',
    'Tu offri',
    'Você oferece',
    '你提供',
    'あなたの提示'
  ],
  'Your final confirmation is needed': [
    'Deine endgültige Bestätigung ist erforderlich',
    'Se necesita tu confirmación final',
    'Ta confirmation finale est nécessaire',
    'Serve la tua conferma finale',
    'Sua confirmação final é necessária',
    '需要你的最终确认',
    'あなたの最終確認が必要です'
  ],
  'Your item is reserved. Your friend can now confirm the trade.': [
    'Dein Gegenstand ist reserviert. Dein Freund kann den Handel jetzt bestätigen.',
    'Tu objeto está reservado. Tu amigo ya puede confirmar el intercambio.',
    'Ton objet est réservé. Ton ami peut maintenant confirmer l’échange.',
    'Il tuo oggetto è riservato. Il tuo amico può ora confermare lo scambio.',
    'Seu item está reservado. Seu amigo já pode confirmar a troca.',
    '你的物品已保留。好友现在可以确认交易。',
    'アイテムを予約しました。フレンドが交換を確認できます。'
  ],
  'The item is kept safe and cannot be used in another trade. The proposal expires ten minutes after it is created.':
      [
    'Der Gegenstand wird sicher verwahrt und kann nicht in einem anderen Handel verwendet werden. Der Vorschlag verfällt zehn Minuten nach seiner Erstellung.',
    'El objeto queda protegido y no puede usarse en otro intercambio. La propuesta caduca diez minutos después de su creación.',
    'L’objet est conservé en sécurité et ne peut pas servir dans un autre échange. La proposition expire dix minutes après sa création.',
    'L’oggetto viene custodito e non può essere usato in un altro scambio. La proposta scade dieci minuti dopo la creazione.',
    'O item fica protegido e não pode ser usado em outra troca. A proposta expira dez minutos após ser criada.',
    '该物品会被安全保留，不能用于其他交易。提议创建十分钟后过期。',
    'アイテムは安全に確保され、別の交換には使えません。提案は作成から10分後に期限切れになります。'
  ],
  'Only one active trade is allowed per account. Finish, reject or cancel it first.':
      [
    'Pro Konto ist nur ein aktiver Handel erlaubt. Schließe ihn zuerst ab, lehne ihn ab oder brich ihn ab.',
    'Solo se permite un intercambio activo por cuenta. Complétalo, recházalo o cancélalo primero.',
    'Un seul échange actif est autorisé par compte. Termine-le, refuse-le ou annule-le d’abord.',
    'È consentito un solo scambio attivo per account. Prima completalo, rifiutalo o annullalo.',
    'Só é permitida uma troca ativa por conta. Primeiro conclua, recuse ou cancele essa troca.',
    '每个账户同时只能进行一笔交易。请先完成、拒绝或取消当前交易。',
    'アカウントごとに同時進行できる交換は1件だけです。先に完了、拒否、またはキャンセルしてください。'
  ],
  'One of you has already completed three trades today. Try again tomorrow.': [
    'Einer von euch hat heute bereits drei Handelsvorgänge abgeschlossen. Versucht es morgen erneut.',
    'Uno de vosotros ya ha completado tres intercambios hoy. Inténtalo de nuevo mañana.',
    'L’un de vous a déjà terminé trois échanges aujourd’hui. Réessayez demain.',
    'Uno di voi ha già completato tre scambi oggi. Riprova domani.',
    'Um de vocês já concluiu três trocas hoje. Tente novamente amanhã.',
    '你们其中一人今天已经完成了三笔交易。请明天再试。',
    'どちらかが今日すでに3件の交換を完了しています。明日もう一度お試しください。'
  ],
  'This trade expired after ten minutes. The reserved items are available again.':
      [
    'Dieser Handel ist nach zehn Minuten abgelaufen. Die reservierten Gegenstände sind wieder verfügbar.',
    'Este intercambio caducó tras diez minutos. Los objetos reservados vuelven a estar disponibles.',
    'Cet échange a expiré après dix minutes. Les objets réservés sont de nouveau disponibles.',
    'Questo scambio è scaduto dopo dieci minuti. Gli oggetti riservati sono di nuovo disponibili.',
    'Esta troca expirou após dez minutos. Os itens reservados estão disponíveis novamente.',
    '这笔交易已在十分钟后过期。保留的物品现在可以再次使用。',
    'この交換は10分後に期限切れになりました。確保されていたアイテムは再び使用できます。'
  ],
  'Trade expired': [
    'Handel abgelaufen',
    'Intercambio caducado',
    'Échange expiré',
    'Scambio scaduto',
    'Troca expirada',
    '交易已过期',
    '交換期限切れ'
  ],
  'Enter your password.': [
    'Gib dein Passwort ein.',
    'Introduce tu contraseña.',
    'Saisis ton mot de passe.',
    'Inserisci la password.',
    'Digite sua senha.',
    '请输入密码。',
    'パスワードを入力してください。'
  ],
  'Online server is not configured': [
    'Der Online-Server ist nicht konfiguriert.',
    'El servidor en línea no está configurado.',
    'Le serveur en ligne n’est pas configuré.',
    'Il server online non è configurato.',
    'O servidor online não está configurado.',
    '在线服务器尚未配置。',
    'オンラインサーバーが設定されていません。'
  ],
  'This profile is currently stored offline': [
    'Dieses Profil wird derzeit offline gespeichert.',
    'Este perfil se guarda actualmente sin conexión.',
    'Ce profil est actuellement enregistré hors ligne.',
    'Questo profilo è attualmente salvato offline.',
    'Este perfil está armazenado offline no momento.',
    '此档案目前保存在本地。',
    'このプロフィールは現在オフラインで保存されています。'
  ],
  'Trusted keepers, shared adventures and safe trades.': [
    'Vertrauenswürdige Hüter, gemeinsame Abenteuer und sichere Tauschgeschäfte.',
    'Guardianes de confianza, aventuras compartidas e intercambios seguros.',
    'Gardiens de confiance, aventures partagées et échanges sécurisés.',
    'Custodi fidati, avventure condivise e scambi sicuri.',
    'Guardiões confiáveis, aventuras compartilhadas e trocas seguras.',
    '值得信赖的守护者、共享冒险与安全交易。',
    '信頼できるキーパー、協力アドベンチャー、安全な交換。'
  ],
  'friends': ['Freunde', 'amigos', 'amis', 'amici', 'amigos', '好友', 'フレンド'],
  'requests': [
    'Anfragen',
    'solicitudes',
    'demandes',
    'richieste',
    'pedidos',
    '请求',
    'リクエスト'
  ],
  'trades': [
    'Tauschgeschäfte',
    'intercambios',
    'échanges',
    'scambi',
    'trocas',
    '交易',
    '交換'
  ],
  'dragons discovered': [
    'Drachen entdeckt',
    'dragones descubiertos',
    'dragons découverts',
    'draghi scoperti',
    'dragões descobertos',
    '已发现的龙',
    '発見したドラゴン'
  ],
  'Use an uppercase letter, lowercase letter, number and symbol.': [
    'Verwende einen Großbuchstaben, einen Kleinbuchstaben, eine Zahl und ein Symbol.',
    'Usa una mayúscula, una minúscula, un número y un símbolo.',
    'Utilise une majuscule, une minuscule, un chiffre et un symbole.',
    'Usa una lettera maiuscola, una minuscola, un numero e un simbolo.',
    'Use uma letra maiúscula, uma minúscula, um número e um símbolo.',
    '请使用大写字母、小写字母、数字和符号。',
    '大文字、小文字、数字、記号をそれぞれ使用してください。'
  ],
};
