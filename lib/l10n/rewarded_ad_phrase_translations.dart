/// Rewarded-ad phrases. Order: German, Spanish, French, Italian, Portuguese,
/// Japanese.
const rewardedAdPhraseTranslations = <String, List<String>>{
  'Ad privacy choices': [
    'Datenschutzoptionen für Werbung',
    'Opciones de privacidad de anuncios',
    'Choix de confidentialité publicitaire',
    'Scelte sulla privacy degli annunci',
    'Opções de privacidade dos anúncios',
    '広告のプライバシー設定',
  ],
  'Review or change your advertising consent.': [
    'Einwilligung für Werbung prüfen oder ändern.',
    'Revisa o cambia tu consentimiento para anuncios.',
    'Consultez ou modifiez votre consentement publicitaire.',
    'Controlla o modifica il consenso per gli annunci.',
    'Reveja ou altere o seu consentimento para anúncios.',
    '広告への同意を確認または変更します。',
  ],
  'Verifying reward…': [
    'Belohnung wird überprüft…',
    'Verificando la recompensa…',
    'Vérification de la récompense…',
    'Verifica della ricompensa…',
    'A verificar a recompensa…',
    '報酬を確認中…',
  ],
  'Reward pending': [
    'Belohnung ausstehend',
    'Recompensa pendiente',
    'Récompense en attente',
    'Ricompensa in attesa',
    'Recompensa pendente',
    '報酬を確認中',
  ],
  'Preparing ads…': [
    'Werbung wird vorbereitet…',
    'Preparando anuncios…',
    'Préparation des publicités…',
    'Preparazione degli annunci…',
    'A preparar anúncios…',
    '広告を準備中…',
  ],
  'Daily limit reached': [
    'Tageslimit erreicht',
    'Límite diario alcanzado',
    'Limite quotidienne atteinte',
    'Limite giornaliero raggiunto',
    'Limite diário atingido',
    '1日の上限に達しました',
  ],
  'Not available yet': [
    'Noch nicht verfügbar',
    'Aún no disponible',
    'Pas encore disponible',
    'Non ancora disponibile',
    'Ainda não disponível',
    'まだ利用できません',
  ],
  'The ad was closed before a reward was earned.': [
    'Die Werbung wurde geschlossen, bevor eine Belohnung verdient wurde.',
    'El anuncio se cerró antes de obtener una recompensa.',
    'La publicité a été fermée avant l’obtention d’une récompense.',
    'L’annuncio è stato chiuso prima di ottenere una ricompensa.',
    'O anúncio foi fechado antes de receber uma recompensa.',
    '報酬を獲得する前に広告が閉じられました。',
  ],
  'Your reward is still being verified. It will appear automatically.': [
    'Deine Belohnung wird noch überprüft. Sie erscheint automatisch.',
    'Tu recompensa aún se está verificando. Aparecerá automáticamente.',
    'Votre récompense est encore en cours de vérification. Elle apparaîtra automatiquement.',
    'La tua ricompensa è ancora in fase di verifica. Apparirà automaticamente.',
    'A sua recompensa ainda está a ser verificada. Aparecerá automaticamente.',
    '報酬を確認しています。確認後、自動的に反映されます。',
  ],
  'The ad could not be completed. Please try again later.': [
    'Die Werbung konnte nicht abgeschlossen werden. Bitte versuche es später erneut.',
    'No se pudo completar el anuncio. Inténtalo de nuevo más tarde.',
    'La publicité n’a pas pu être terminée. Veuillez réessayer plus tard.',
    'Non è stato possibile completare l’annuncio. Riprova più tardi.',
    'Não foi possível concluir o anúncio. Tente novamente mais tarde.',
    '広告を完了できませんでした。後でもう一度お試しください。',
  ],
  'Your verified reward has been saved.': [
    'Deine bestätigte Belohnung wurde gespeichert.',
    'Tu recompensa verificada se ha guardado.',
    'Votre récompense vérifiée a été enregistrée.',
    'La ricompensa verificata è stata salvata.',
    'A sua recompensa verificada foi guardada.',
    '確認済みの報酬が保存されました。',
  ],
};

String? translatedRewardedAdPhrase(String text, int languageIndex) {
  final button = RegExp(r'^Watch an ad (\d+)/(\d+)$').firstMatch(text);
  if (button != null) {
    final count = '${button.group(1)}/${button.group(2)}';
    return [
      'Werbung ansehen $count',
      'Ver un anuncio $count',
      'Regarder une publicité $count',
      'Guarda un annuncio $count',
      'Ver um anúncio $count',
      '広告を見る $count',
    ][languageIndex];
  }

  final description = RegExp(
          r'^Watch an ad to receive (\d+) (gems|coins)\. Up to (\d+) per UTC day in this shop\.$')
      .firstMatch(text);
  if (description == null) return null;
  final amount = description.group(1)!;
  final gems = description.group(2) == 'gems';
  final limit = description.group(3)!;
  return [
    'Sieh dir eine Werbung an, um $amount ${gems ? 'Edelsteine' : 'Münzen'} zu erhalten. Bis zu $limit-mal pro UTC-Tag in diesem Shop.',
    'Mira un anuncio para recibir $amount ${gems ? 'gemas' : 'monedas'}. Hasta $limit veces por día UTC en esta tienda.',
    'Regardez une publicité pour recevoir $amount ${gems ? 'gemmes' : 'pièces'}. Jusqu’à $limit fois par jour UTC dans cette boutique.',
    'Guarda un annuncio per ricevere $amount ${gems ? 'gemme' : 'monete'}. Fino a $limit volte per giorno UTC in questo negozio.',
    'Veja um anúncio para receber $amount ${gems ? 'gemas' : 'moedas'}. Até $limit vezes por dia UTC nesta loja.',
    '広告を見て${gems ? 'ジェム' : 'コイン'}$amount個を受け取ります。このショップではUTC日ごとに最大$limit回。',
  ][languageIndex];
}
