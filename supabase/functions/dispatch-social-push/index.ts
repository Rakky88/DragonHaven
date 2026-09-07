import { classifyResponse, dispatchJobs, fcmPayload, PushJob, PushResult } from "./core.ts";

const encoder = new TextEncoder();
const base64url = (data: Uint8Array) => btoa(String.fromCharCode(...data))
  .replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
const encodedJson = (value: unknown) => base64url(encoder.encode(JSON.stringify(value)));
let cachedToken: { value: string; expiresAt: number } | undefined;

async function jsonRequest(url: string, init: RequestInit) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 6000);
  try {
    const response = await fetch(url, { ...init, signal: controller.signal });
    const reader = response.body?.getReader();
    const chunks: Uint8Array[] = [];
    let length = 0;
    if (reader) {
      try {
        while (true) {
          const part = await reader.read();
          if (part.done) break;
          length += part.value.length;
          if (length > 256000) throw new Error("push_response_too_large");
          chunks.push(part.value);
        }
      } finally { await reader.cancel().catch(() => {}); }
    }
    const bytes = new Uint8Array(length);
    let offset = 0;
    for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
    let body: unknown = null;
    try { body = JSON.parse(new TextDecoder().decode(bytes)); } catch { /* fixed error below */ }
    return { status: response.status, body, retryAfter: response.headers.get("retry-after") };
  } finally { clearTimeout(timeout); }
}

async function googleToken(projectId: string): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 120000) return cachedToken.value;
  const account = JSON.parse(Deno.env.get("FIREBASE_MESSAGING_SERVICE_ACCOUNT") ?? "{}");
  if (account.project_id !== projectId || typeof account.private_key !== "string" ||
    typeof account.client_email !== "string" ||
    !/^[a-zA-Z0-9._-]+@[a-z0-9-]+\.iam\.gserviceaccount\.com$/.test(account.client_email)) {
    throw new Error("push_sender_configuration_missing");
  }
  const pem = account.private_key.replace(/-----[^-]+-----/g, "").replace(/\s/g, "");
  const key = await crypto.subtle.importKey("pkcs8",
    Uint8Array.from(atob(pem), (c) => c.charCodeAt(0)),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${encodedJson({ alg: "RS256", typ: "JWT" })}.${encodedJson({
    iss: account.client_email, scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token", iat: now, exp: now + 3600,
  })}`;
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, encoder.encode(unsigned));
  const token = await jsonRequest("https://oauth2.googleapis.com/token", {
    method: "POST", headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${base64url(new Uint8Array(signature))}` }),
  });
  const body = token.body as { access_token?: string; expires_in?: number };
  if (token.status !== 200 || typeof body?.access_token !== "string" ||
    typeof body.expires_in !== "number") throw new Error("push_sender_unavailable");
  cachedToken = { value: body.access_token, expiresAt: Date.now() +
    Math.min(3600, Math.max(0, body.expires_in)) * 1000 };
  return cachedToken.value;
}

async function authorized(request: Request, secret: string): Promise<boolean> {
  if (secret.length < 32) return false;
  const actual = request.headers.get("authorization") ?? "";
  if (actual.length > 512) return false;
  const [a, b] = await Promise.all([actual, `Bearer ${secret}`].map(
    async (value) => new Uint8Array(await crypto.subtle.digest("SHA-256", encoder.encode(value))),
  ));
  return a.reduce((difference, value, i) => difference | (value ^ b[i]), 0) === 0;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return new Response(null, { status: 405 });
  if (!await authorized(request, Deno.env.get("PUSH_DISPATCH_SECRET") ?? "")) {
    return new Response(null, { status: 401 });
  }
  const project = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
  const base = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/.test(project) ||
    !/^https:\/\/[a-z0-9]{20}\.supabase\.co$/.test(base) || !serviceKey) {
    return Response.json({ error: "push_configuration_missing" }, { status: 503 });
  }
  const rpc = async (name: string, body: unknown) => {
    const response = await jsonRequest(`${base}/rest/v1/rpc/${name}`, {
      method: "POST", headers: { "content-type": "application/json",
        apikey: serviceKey, authorization: `Bearer ${serviceKey}` },
      body: JSON.stringify(body),
    });
    if (response.status < 200 || response.status >= 300) throw new Error("push_worker_rpc_failed");
    return response.body;
  };
  try {
    const jobs = await rpc("lease_social_pushes", { p_limit: 30 });
    if (!Array.isArray(jobs)) throw new Error("push_batch_invalid");
    if (jobs.length === 0) return Response.json({ leased: 0 });
    let accessToken: string | null = null;
    try { accessToken = await googleToken(project); } catch { /* retain jobs and retry */ }
    const counts = await dispatchJobs(jobs, {
      send: async (job: PushJob): Promise<PushResult> => {
        if (!accessToken) return { result: "retry", retryAfter: 900 };
        const response = await jsonRequest(`https://fcm.googleapis.com/v1/projects/${project}/messages:send`, {
          method: "POST", headers: { "content-type": "application/json",
            authorization: `Bearer ${accessToken}` }, body: JSON.stringify(fcmPayload(job)),
        });
        if (response.status === 401) cachedToken = undefined;
        return classifyResponse(response.status, response.body, response.retryAfter);
      },
      complete: async (job, result) => {
        await rpc("complete_social_push", { p_job_id: job.job_id,
          p_lease_token: job.lease_token, p_result: result.result,
          p_retry_after_seconds: result.retryAfter });
      },
    });
    // Only aggregate operational counts leave the worker. No token, recipient,
    // Firebase response, service-account value or request body is logged.
    return Response.json(counts);
  } catch {
    return Response.json({ error: "push_dispatch_unavailable" }, { status: 503 });
  }
});
