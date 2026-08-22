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
  final values = uiPhraseTranslations[english];
  if (index == null) return null;
  if (values != null && values.length == 7) return values[index];
  return _translatedDynamicUiPhrase(english, languageCode);
}

String _localized(String languageCode, List<String> values) =>
    values[_languageIndex[languageCode]!];

String? _translatedDynamicUiPhrase(String text, String languageCode) {
  String? capture(RegExp expression, [int group = 1]) =>
      expression.firstMatch(text)?.group(group);

  var value = capture(RegExp(r'^(.+) already has a place in the house\.$'));
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
  final unlockedCount = RegExp(r'^(\d+) / 20 unlocked$').firstMatch(text);
  if (unlockedCount != null) {
    final count = unlockedCount.group(1);
    return _localized(languageCode, [
      '$count / 20 freigeschaltet',
      '$count / 20 desbloqueados',
      '$count / 20 débloqués',
      '$count / 20 sbloccati',
      '$count / 20 desbloqueadas',
      '已解锁 $count / 20',
      '解除済み $count / 20'
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
  return null;
}

const uiPhraseTranslations = <String, List<String>>{
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
  'Egg stash': [
    'Eivorrat',
    'Reserva de huevos',
    'Réserve d’œufs',
    'Scorta di uova',
    'Reserva de ovos',
    '龙蛋储藏',
    '卵の保管庫'
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
  'No Mysterious Eggs in your stash yet.': [
    'Du hast noch keine geheimnisvollen Eier im Vorrat.',
    'Aún no hay Huevos Misteriosos en tu almacén.',
    'Aucun Œuf mystérieux dans ta réserve pour le moment.',
    'Non ci sono ancora Uova misteriose nella scorta.',
    'Ainda não há Ovos Misteriosos na sua reserva.',
    '你的储藏中还没有神秘龙蛋。',
    '保管庫にはまだ不思議な卵がありません。'
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
  'Short': ['Kurz', 'Corta', 'Courte', 'Breve', 'Curta', '短途', 'ショート'],
  'Something is moving inside… · Incubates 2–14 days once placed.': [
    'Etwas bewegt sich darin … · Nach dem Platzieren dauert das Brüten 2–14 Tage.',
    'Algo se mueve dentro… · Tarda entre 2 y 14 días en eclosionar tras colocarlo.',
    'Quelque chose bouge à l’intérieur… · L’incubation dure de 2 à 14 jours après placement.',
    'Qualcosa si muove all’interno… · Dopo il posizionamento si schiude in 2–14 giorni.',
    'Algo está se movendo lá dentro… · Leva de 2 a 14 dias para chocar após ser colocado.',
    '里面有东西在动……放入巢穴后需孵化 2–14 天。',
    '中で何かが動いています…・巣に置いてから2～14日で孵化します。'
  ],
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
  'minimum time complete': [
    'Mindestzeit erfüllt',
    'tiempo mínimo completado',
    'durée minimale atteinte',
    'tempo minimo completato',
    'tempo mínimo concluído',
    '已满足最短时间',
    '最低時間を達成'
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
};
