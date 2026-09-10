import { boundedJson, handleCommand, object, RpcFailure } from "./core.ts";
import { evaluate, project, prepareImport, ruleset } from "./bundle.generated.ts";

const base = Deno.env.get("SUPABASE_URL") ?? "";
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
if (!/^https:\/\/[a-z0-9]{20}\.supabase\.co$/.test(base) || serviceKey.length < 32) {
  throw new Error("game_configuration_missing");
}

async function fetchJson(path: string, init: RequestInit, maximum: number) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 8000);
  try {
    const result = await fetch(`${base}${path}`, { ...init, signal: controller.signal });
    return { status: result.status, body: await boundedJson(result.body, maximum) };
  } finally { clearTimeout(timeout); }
}

Deno.serve((request) => handleCommand(request, {
  ruleset, evaluate, project, prepareImport,
  authenticate: async (authorization) => {
    // Validate the token against Supabase Auth; never trust a decoded client
    // JWT, a caller-provided owner, or user-editable app/user metadata.
    const result = await fetchJson("/auth/v1/user", { headers: { authorization, apikey: serviceKey } }, 65536);
    if (result.status === 401 || result.status === 403) return null;
    if (result.status !== 200) throw new Error("game_auth_unavailable");
    const user = result.body;
    if (!object(user) || typeof user.id !== "string" || user.role !== "authenticated" ||
      typeof user.email_confirmed_at !== "string" || !Number.isFinite(Date.parse(user.email_confirmed_at))) return null;
    return user.id;
  },
  rpc: async (name, payload) => {
    const result = await fetchJson(`/rest/v1/rpc/${name}`, {
      method: "POST", headers: { "content-type": "application/json", apikey: serviceKey,
        authorization: `Bearer ${serviceKey}` }, body: JSON.stringify(payload),
    }, 10 * 1024 * 1024);
    if (result.status < 200 || result.status >= 300) {
      const code = object(result.body) && typeof result.body.message === "string" ? result.body.message : "unknown";
      throw new RpcFailure(code);
    }
    return result.body;
  },
}));
