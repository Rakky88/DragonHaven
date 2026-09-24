export const workerResponseBudgetMs = 7500;

/**
 * Give every upstream call one shared budget.  On expiry the shared signal
 * aborts whichever Auth/PostgREST request is active before the fixed fallback
 * is returned to the client.
 */
export async function runBeforeWorkerDeadline<T>(
  operation: (signal: AbortSignal) => Promise<T>,
  fallback: () => T,
  budgetMs = workerResponseBudgetMs,
): Promise<T> {
  if (!Number.isSafeInteger(budgetMs) || budgetMs < 1) {
    throw new RangeError("invalid_worker_response_budget");
  }
  const controller = new AbortController();
  let timer: ReturnType<typeof setTimeout> | undefined;
  const expired = new Promise<T>((resolve, reject) => {
    timer = setTimeout(() => {
      controller.abort();
      try {
        resolve(fallback());
      } catch (error) {
        reject(error);
      }
    }, budgetMs);
  });
  try {
    return await Promise.race([
      Promise.resolve().then(() => operation(controller.signal)),
      expired,
    ]);
  } finally {
    clearTimeout(timer);
  }
}
