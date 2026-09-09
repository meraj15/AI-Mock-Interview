import { ProviderHealth } from './ai.types';

// ============================================================
// ERROR CLASSIFICATION
// ============================================================

export function isTransientError(err: unknown): boolean {
  if (!err) return false;

  const errorObj = err as Record<string, any>;

  const status = Number(
    errorObj?.status ||
      errorObj?.statusCode ||
      errorObj?.code ||
      errorObj?.error?.code ||
      errorObj?.error?.status ||
      0,
  );

  // Transient HTTP Statuses
  if (
    status === 408 || // Request Timeout
    status === 429 || // Too Many Requests / Quota Exceeded
    status === 502 || // Bad Gateway
    status === 503 || // Service Unavailable
    status === 504    // Gateway Timeout
  ) {
    return true;
  }

  // Non-transient Client / Auth / Validation Errors (FAIL FAST)
  if (
    status === 400 || // Bad Request
    status === 401 || // Unauthorized / Invalid API Key
    status === 403 || // Forbidden / Permission Denied
    status === 404 || // Not Found
    status === 422    // Unprocessable Entity / Validation
  ) {
    return false;
  }

  const message = (
    typeof err === 'string'
      ? err
      : errorObj?.message ||
        errorObj?.error?.message ||
        JSON.stringify(err)
  ).toLowerCase();

  // Explicit non-transient message matches
  if (
    message.includes('invalid api key') ||
    message.includes('api key not valid') ||
    message.includes('authentication') ||
    message.includes('permission denied') ||
    message.includes('unauthorized')
  ) {
    return false;
  }

  // Explicit transient message / error code matches
  const transientPatterns = [
    '408',
    '429',
    '502',
    '503',
    '504',
    'rate limit',
    'resource exhausted',
    'quota',
    'unavailable',
    'overloaded',
    'high demand',
    'temporarily unavailable',
    'timed out',
    'timeout',
    'econnreset',
    'econnrefused',
    'etimedout',
    'fetch failed',
    'socket hang up',
    'network error',
  ];

  return transientPatterns.some((pattern) => message.includes(pattern));
}

// ============================================================
// CIRCUIT BREAKER
// ============================================================

export class CircuitBreaker {
  private state: 'CLOSED' | 'OPEN' | 'HALF_OPEN' = 'CLOSED';
  private consecutiveFailures = 0;
  private lastFailureAt: number | undefined = undefined;
  private cooldownUntil = 0;

  constructor(
    public readonly providerId: string,
    private readonly failureThreshold = 3,
    private readonly cooldownMs = 30_000,
  ) {}

  canExecute(): boolean {
    if (this.state === 'CLOSED') {
      return true;
    }

    const now = Date.now();
    if (this.state === 'OPEN') {
      if (now >= this.cooldownUntil) {
        console.log(
          `[CircuitBreaker:${this.providerId}] Cooldown elapsed. Entering HALF_OPEN state to probe provider.`,
        );
        this.state = 'HALF_OPEN';
        return true;
      }
      return false;
    }

    // In HALF_OPEN state, allow the trial request
    return true;
  }

  recordSuccess(): void {
    if (this.state !== 'CLOSED' || this.consecutiveFailures > 0) {
      console.log(
        `[CircuitBreaker:${this.providerId}] Request succeeded. Closing circuit and resetting failure counts.`,
      );
    }
    this.state = 'CLOSED';
    this.consecutiveFailures = 0;
    this.cooldownUntil = 0;
  }

  recordFailure(err: unknown): boolean {
    const transient = isTransientError(err);
    if (!transient) {
      // Non-transient error (e.g. 401, 400) should not trip the circuit for transient failovers,
      // but should be logged.
      return false;
    }

    this.consecutiveFailures += 1;
    this.lastFailureAt = Date.now();

    if (this.state === 'HALF_OPEN' || this.consecutiveFailures >= this.failureThreshold) {
      this.state = 'OPEN';
      this.cooldownUntil = Date.now() + this.cooldownMs;
      console.warn(
        `[CircuitBreaker:${this.providerId}] Circuit OPEN until ${new Date(
          this.cooldownUntil,
        ).toISOString()} after ${this.consecutiveFailures} consecutive transient failures.`,
      );
    } else {
      console.warn(
        `[CircuitBreaker:${this.providerId}] Transient failure (${this.consecutiveFailures}/${this.failureThreshold}):`,
        (err as any)?.message || err,
      );
    }

    return true;
  }

  getHealth(): ProviderHealth {
    const isAvailable = this.canExecute();
    return {
      healthy: isAvailable && this.state === 'CLOSED',
      consecutiveFailures: this.consecutiveFailures,
      lastFailureAt: this.lastFailureAt,
      cooldownUntil: this.cooldownUntil > 0 ? this.cooldownUntil : undefined,
      circuitState: this.state,
    };
  }
}
