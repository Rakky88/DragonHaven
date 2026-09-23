import { InfrastructureFailure } from "./core.ts";

export type VerifierKeyLoader = () => Promise<ReadonlyMap<number, CryptoKey>>;

export interface CachedVerifierKeysOptions {
  now?: () => number;
  cacheDurationMs?: number;
  missCooldownMs?: number;
  failureCooldownMs?: number;
  maximumNegativeEntries?: number;
}

/// Caches Google's verifier keys and bounds refreshes caused by attacker-
/// controlled unknown key IDs. A successful load starts a global miss
/// cooldown; distinct random misses therefore cannot each trigger egress.
export class CachedVerifierKeys {
  private keys = new Map<number, CryptoKey>();
  private expiresAt = 0;
  private retryAt = 0;
  private nextMissRefreshAt = 0;
  private readonly missingUntil = new Map<number, number>();
  private loading?: Promise<void>;

  private readonly now: () => number;
  private readonly cacheDurationMs: number;
  private readonly missCooldownMs: number;
  private readonly failureCooldownMs: number;
  private readonly maximumNegativeEntries: number;

  constructor(
    private readonly loader: VerifierKeyLoader,
    options: CachedVerifierKeysOptions = {},
  ) {
    this.now = options.now ?? Date.now;
    this.cacheDurationMs = options.cacheDurationMs ?? 24 * 60 * 60 * 1000;
    this.missCooldownMs = options.missCooldownMs ?? 5 * 60 * 1000;
    this.failureCooldownMs = options.failureCooldownMs ?? 30 * 1000;
    this.maximumNegativeEntries = options.maximumNegativeEntries ?? 256;
  }

  async get(keyId: number): Promise<CryptoKey | null> {
    await this.refresh(false);
    let key = this.keys.get(keyId);
    if (key) return key;

    const now = this.now();
    this.pruneMissing(now);
    if ((this.missingUntil.get(keyId) ?? 0) > now) return null;

    // A cache miss may indicate Google rotated keys. Permit one early refresh
    // per cooldown window globally, rather than one per arbitrary key ID.
    if (now >= this.nextMissRefreshAt) {
      this.nextMissRefreshAt = now + this.missCooldownMs;
      await this.refresh(true);
      key = this.keys.get(keyId);
      if (key) return key;
    }

    this.rememberMissing(keyId, this.now() + this.missCooldownMs);
    return null;
  }

  private async refresh(force: boolean): Promise<void> {
    const now = this.now();
    if (!force && this.expiresAt > now) return;
    if (this.loading) return this.loading;
    if (now < this.retryAt) {
      if (this.keys.size > 0 && !force) return;
      throw new InfrastructureFailure();
    }
    this.loading = this.load();
    try {
      await this.loading;
    } finally {
      this.loading = undefined;
    }
  }

  private async load(): Promise<void> {
    try {
      const loaded = await this.loader();
      if (loaded.size === 0) throw new InfrastructureFailure();
      const now = this.now();
      this.keys = new Map(loaded);
      this.expiresAt = now + this.cacheDurationMs;
      this.retryAt = 0;
      this.nextMissRefreshAt = now + this.missCooldownMs;
      this.missingUntil.clear();
    } catch (error) {
      this.retryAt = this.now() + this.failureCooldownMs;
      if (error instanceof InfrastructureFailure) throw error;
      throw new InfrastructureFailure();
    }
  }

  private pruneMissing(now: number): void {
    for (const [keyId, expiry] of this.missingUntil) {
      if (expiry <= now) this.missingUntil.delete(keyId);
    }
  }

  private rememberMissing(keyId: number, expiry: number): void {
    if (
      !this.missingUntil.has(keyId) &&
      this.missingUntil.size >= this.maximumNegativeEntries
    ) {
      const oldest = this.missingUntil.keys().next().value;
      if (oldest !== undefined) this.missingUntil.delete(oldest);
    }
    this.missingUntil.set(keyId, expiry);
  }
}
