export type PushJob = {
  job_id: string;
  lease_token: string;
  notification_id: string;
  token: string;
  language_code: string;
  kind: string;
};
export type PushResult = {
  result: "accepted" | "unregistered" | "retry" | "permanent_error";
  retryAfter: number;
};

const kinds = new Set([
  "friend_request", "friend_accepted", "friend_message", "trade_request",
  "trade_return", "trade_completed", "seasonal_pair_invite",
  "seasonal_pair_accepted", "seasonal_pair_ready",
]);
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

export function validJob(value: unknown): value is PushJob {
  if (!value || typeof value !== "object") return false;
  const job = value as PushJob;
  return [job.job_id, job.lease_token, job.notification_id].every(
    (id) => typeof id === "string" && uuid.test(id),
  ) && typeof job.token === "string" && job.token.length >= 20 &&
    job.token.length <= 4096 && !/\s/.test(job.token) && kinds.has(job.kind) &&
    ["en", "nl", "de", "es", "fr", "it", "pt", "ja"].includes(job.language_code);
}

const bodies: Record<string, [string, string, string]> = {
  en: ["You have a new private message. Open DragonHaven to read it.", "There is an update in Friends. Open DragonHaven to view it.", "A shared Adventure has an update. Open DragonHaven to view it."],
  nl: ["Je hebt een nieuw privébericht. Open DragonHaven om het te lezen.", "Er is een update bij Vrienden. Open DragonHaven om die te bekijken.", "Er is een update voor een gedeeld avontuur. Open DragonHaven om die te bekijken."],
  de: ["Du hast eine neue private Nachricht. Öffne DragonHaven, um sie zu lesen.", "Bei Freunde gibt es Neuigkeiten. Öffne DragonHaven.", "Es gibt Neuigkeiten zu einem gemeinsamen Abenteuer. Öffne DragonHaven."],
  es: ["Tienes un mensaje privado nuevo. Abre DragonHaven para leerlo.", "Hay novedades en Amigos. Abre DragonHaven.", "Hay novedades en una aventura compartida. Abre DragonHaven."],
  fr: ["Vous avez un nouveau message privé. Ouvrez DragonHaven pour le lire.", "Il y a du nouveau dans Amis. Ouvrez DragonHaven.", "Une aventure partagée a du nouveau. Ouvrez DragonHaven."],
  it: ["Hai un nuovo messaggio privato. Apri DragonHaven per leggerlo.", "Ci sono novità in Amici. Apri DragonHaven.", "Ci sono novità per un'avventura condivisa. Apri DragonHaven."],
  pt: ["Tens uma nova mensagem privada. Abre DragonHaven para a ler.", "Há novidades em Amigos. Abre DragonHaven.", "Há novidades numa aventura partilhada. Abre DragonHaven."],
  ja: ["新しいプライベートメッセージがあります。DragonHavenを開いて確認してください。", "フレンドに更新があります。DragonHavenを開いてください。", "共同冒険に更新があります。DragonHavenを開いてください。"],
};

export function notificationTag(job: PushJob): string {
  const prefix = job.kind === "friend_message" ? "friend-message" :
    job.kind === "friend_request" ? "friend-request" :
    job.kind === "friend_accepted" ? "friend-accepted" :
    job.kind.startsWith("trade_") ? "trade" : "seasonal-pair";
  return `${prefix}-${job.notification_id}`;
}

export function fcmPayload(job: PushJob) {
  if (!validJob(job)) throw new Error("push_job_invalid");
  const group = job.kind === "friend_message" ? 0 :
    job.kind.startsWith("seasonal_pair_") ? 2 : 1;
  return {
    message: {
      token: job.token,
      notification: { title: "DragonHaven", body: bodies[job.language_code][group] },
      data: { kind: job.kind, notification_id: job.notification_id },
      android: {
        priority: "HIGH",
        ttl: "3600s",
        notification: { tag: notificationTag(job), default_sound: true },
      },
    },
  };
}

export function classifyResponse(status: number, body: unknown,
  retryAfter: string | null, nowMs = Date.now()): PushResult {
  if (status >= 200 && status < 300) {
    const name = (body as { name?: unknown })?.name;
    return typeof name === "string" && /^projects\/[^/]+\/messages\/[^/]+$/.test(name)
      ? { result: "accepted", retryAfter: 0 }
      : { result: "retry", retryAfter: 60 };
  }
  const error = (body as { error?: { details?: { errorCode?: string }[] } })?.error;
  if (status === 404 && Array.isArray(error?.details) &&
    error.details.some((detail) => detail.errorCode === "UNREGISTERED")) {
    return { result: "unregistered", retryAfter: 0 };
  }
  // A permissions/configuration failure must not destroy device registrations.
  if ([401, 403, 408, 429].includes(status) || status >= 500) {
    let seconds = retryAfter && /^\d+$/.test(retryAfter) ? Number(retryAfter) :
      retryAfter ? Math.ceil((Date.parse(retryAfter) - nowMs) / 1000) : 0;
    if (!Number.isFinite(seconds)) seconds = 0;
    return { result: "retry", retryAfter: Math.min(3600,
      Math.max(status === 401 || status === 403 ? 900 : 60, seconds)) };
  }
  return { result: "permanent_error", retryAfter: 0 };
}

export async function dispatchJobs(jobs: PushJob[], dependencies: {
  send: (job: PushJob) => Promise<PushResult>;
  complete: (job: PushJob, result: PushResult) => Promise<void>;
  now?: () => number;
  budgetMs?: number;
}) {
  if (jobs.length > 30 || jobs.some((job) => !validJob(job))) {
    throw new Error("push_batch_invalid");
  }
  const now = dependencies.now ?? Date.now;
  const deadline = now() + (dependencies.budgetMs ?? 35000);
  let index = 0;
  const counts = { leased: jobs.length, accepted: 0, retry: 0, invalid: 0,
    failed: 0, completion_errors: 0 };
  await Promise.all(Array.from({ length: Math.min(5, jobs.length) }, async () => {
    while (index < jobs.length) {
      const job = jobs[index++];
      let result: PushResult = { result: "retry", retryAfter: 60 };
      if (now() < deadline - 6500) {
        try { result = await dependencies.send(job); } catch { /* bounded retry */ }
      }
      if (result.result === "accepted") counts.accepted++;
      else if (result.result === "unregistered") counts.invalid++;
      else if (result.result === "retry") counts.retry++;
      else counts.failed++;
      try { await dependencies.complete(job, result); } catch { counts.completion_errors++; }
    }
  }));
  return counts;
}
