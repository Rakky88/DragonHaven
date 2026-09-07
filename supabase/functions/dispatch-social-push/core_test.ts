import { classifyResponse, dispatchJobs, fcmPayload, PushJob } from "./core.ts";

function assert(value: unknown, message = "assertion failed"): asserts value {
  if (!value) throw new Error(message);
}
function job(index = 1): PushJob {
  const id = `11111111-1111-4111-8111-${String(index).padStart(12, "0")}`;
  return { job_id: id, lease_token: id, notification_id: id,
    token: "synthetic-token-with-no-user-content", language_code: "nl", kind: "friend_message" };
}

Deno.test("payload allowlist excludes source record extras and uses a stable notification tag", () => {
  const unsafe = { ...job(), actor_name: "private-person", body: "secret chat", email: "person@example.org" };
  const payload = fcmPayload(unsafe);
  const encoded = JSON.stringify(payload);
  assert(!encoded.includes("secret chat") && !encoded.includes("private-person") && !encoded.includes("person@example.org"));
  assert(payload.message.android.notification.tag === `friend-message-${unsafe.notification_id}`);
  assert(payload.message.data.kind === "friend_message");
  assert(Object.keys(payload.message.data).length === 2);
});

Deno.test("FCM invalid token is distinct from bad credentials or a bad payload", () => {
  assert(classifyResponse(404, { error: { details: [{ errorCode: "UNREGISTERED" }] } }, null).result === "unregistered");
  assert(classifyResponse(401, {}, null).result === "retry");
  assert(classifyResponse(403, {}, null).retryAfter === 900);
  assert(classifyResponse(400, { error: { details: [{ errorCode: "INVALID_ARGUMENT" }] } }, null).result === "permanent_error");
  assert(classifyResponse(429, {}, "99999").retryAfter === 3600);
  assert(classifyResponse(503, {}, "garbage").retryAfter === 60);
});

Deno.test("retry-after dates are honored and expired dates do not spin", () => {
  const now = Date.UTC(2026, 8, 7);
  assert(classifyResponse(429, {}, new Date(now + 120000).toUTCString(), now).retryAfter === 120);
  assert(classifyResponse(429, {}, new Date(now - 120000).toUTCString(), now).retryAfter === 60);
});

Deno.test("worker bounds concurrency and retains delivery on network/completion failure", async () => {
  let active = 0, peak = 0;
  const seen = new Set<string>();
  const result = await dispatchJobs(Array.from({ length: 30 }, (_, i) => job(i + 1)), {
    send: async () => {
      active++; peak = Math.max(peak, active);
      await new Promise((resolve) => setTimeout(resolve, 1));
      active--;
      throw new Error("synthetic transport failure");
    },
    complete: async (j, status) => {
      assert(status.result === "retry");
      assert(!seen.has(j.job_id)); seen.add(j.job_id);
      if (seen.size === 1) throw new Error("synthetic lost completion");
    },
  });
  assert(peak <= 5 && seen.size === 30);
  assert(result.retry === 30 && result.accepted === 0 && result.completion_errors === 1);
});

Deno.test("deadline releases work for retry without sending late requests", async () => {
  let sends = 0;
  const result = await dispatchJobs([job()], {
    budgetMs: 1000, now: () => 0,
    send: async () => { sends++; return { result: "accepted", retryAfter: 0 }; },
    complete: async (_, result) => { assert(result.result === "retry"); },
  });
  assert(sends === 0 && result.retry === 1);
});

Deno.test("malformed or oversized batches fail before any external delivery", async () => {
  let sends = 0;
  for (const jobs of [[{ ...job(), kind: "arbitrary_private_payload" }],
    Array.from({ length: 31 }, (_, i) => job(i + 1))]) {
    let rejected = false;
    try {
      await dispatchJobs(jobs, {
        send: async () => { sends++; return { result: "accepted", retryAfter: 0 }; },
        complete: async () => {},
      });
    } catch { rejected = true; }
    assert(rejected);
  }
  assert(sends === 0);
});
