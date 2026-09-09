import dotenv from 'dotenv';

// Reload environment variables
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT ?? '3000', 10),
  nodeEnv: process.env.NODE_ENV ?? 'development',
  isDevelopment: process.env.NODE_ENV !== 'production',
  database: {
    url: process.env.DATABASE_URL ?? '',
  },
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET ?? 'default_access_secret_for_dev_min_32_chars',
    refreshSecret: process.env.JWT_REFRESH_SECRET ?? 'default_refresh_secret_for_dev_min_32_chars',
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN ?? '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN ?? '7d',
  },
  openai: {
    apiKey: process.env.OPENAI_API_KEY ?? '',
  },
  gemini: {
    apiKey: process.env.GEMINI_API_KEY ?? '',
  },
  ai: {
    livePrimaryProvider: (process.env.AI_LIVE_PRIMARY_PROVIDER ?? 'gemini').toLowerCase(),
    livePrimaryModel: process.env.AI_LIVE_PRIMARY_MODEL ?? 'gemini-3.7-flash',
    liveFallbackProvider: (process.env.AI_LIVE_FALLBACK_PROVIDER ?? 'openai').toLowerCase(),
    liveFallbackModel: process.env.AI_LIVE_FALLBACK_MODEL ?? 'gpt-4o-mini',

    evalPrimaryProvider: (process.env.AI_EVAL_PRIMARY_PROVIDER ?? 'gemini').toLowerCase(),
    evalPrimaryModel: process.env.AI_EVAL_PRIMARY_MODEL ?? 'gemini-3.7-flash',
    evalFallbackProvider: (process.env.AI_EVAL_FALLBACK_PROVIDER ?? 'openai').toLowerCase(),
    evalFallbackModel: process.env.AI_EVAL_FALLBACK_MODEL ?? 'gpt-4o',

    circuitFailureThreshold: parseInt(process.env.AI_CIRCUIT_FAILURE_THRESHOLD ?? '3', 10),
    circuitCooldownMs: parseInt(process.env.AI_CIRCUIT_COOLDOWN_MS ?? '30000', 10),
    liveTimeoutMs: parseInt(process.env.AI_LIVE_TIMEOUT_MS ?? '8000', 10),
    evalTimeoutMs: parseInt(process.env.AI_EVAL_TIMEOUT_MS ?? '60000', 10),
  },
} as const;

