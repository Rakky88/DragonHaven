import { runBeforeWorkerDeadline, workerResponseBudgetMs } from "./deadline.ts";

function assert(
  condition: unknown,
  message = "assertion failed",
): asserts condition {
  if (!condition) throw new Error(message);
}

Deno.test("worker budget remains below the client transport deadline", () => {
  assert(workerResponseBudgetMs > 0);
  assert(workerResponseBudgetMs < 10000);
});

Deno.test("one deadline aborts unfinished upstream work and returns the fallback", async () => {
  let observedAbort = false;
  const started = performance.now();
  const result = await runBeforeWorkerDeadline(
    (signal) =>
      new Promise<string>((_resolve, reject) => {
        signal.addEventListener("abort", () => {
          observedAbort = true;
          reject(new Error("aborted upstream"));
        }, { once: true });
      }),
    () => "game_command_unavailable",
    10,
  );
  assert(result === "game_command_unavailable");
  assert(observedAbort);
  assert(performance.now() - started < 500);
});

Deno.test("a completed worker response clears the deadline without aborting it", async () => {
  let signal: AbortSignal | undefined;
  const result = await runBeforeWorkerDeadline(
    async (value) => {
      signal = value;
      return "ok";
    },
    () => "timeout",
    100,
  );
  assert(result === "ok");
  await new Promise((resolve) => setTimeout(resolve, 120));
  assert(signal?.aborted === false);
});
