import dotenv from 'dotenv';

// Reload environment variables (updated to gemini-3.7-flash)
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
  email: {
    smtpHost: process.env.SMTP_HOST ?? 'smtp-relay.brevo.com',
    smtpPort: parseInt(process.env.SMTP_PORT ?? '587', 10),
    smtpUser: process.env.SMTP_USER ?? '',
    smtpPassword: process.env.SMTP_PASSWORD ?? '',
    from: process.env.EMAIL_FROM ?? 'khanmeraj1542005@gmail.com',
    fromName: process.env.EMAIL_FROM_NAME ?? 'Mock Interview',
  },
  ai: {
    livePrimaryProvider: (process.env.AI_LIVE_PRIMARY_PROVIDER ?? 'gemini').toLowerCase(),
    livePrimaryModel: process.env.GEMINI_MODEL ?? process.env.AI_LIVE_PRIMARY_MODEL ?? 'gemini-3.8-flash',

    evalPrimaryProvider: (process.env.AI_EVAL_PRIMARY_PROVIDER ?? 'gemini').toLowerCase(),
    evalPrimaryModel: process.env.GEMINI_MODEL ?? process.env.AI_EVAL_PRIMARY_MODEL ?? 'gemini-3.8-flash',

    /** Optional secondary Gemini fallback model (e.g. gemini-2.5-flash or gemini-2.0-flash). Disabled if empty. */
    fallbackModel: (process.env.GEMINI_FALLBACK_MODEL ?? process.env.AI_FALLBACK_MODEL ?? '').trim(),

    /** Thinking level for live conversational turns ('minimal' | 'low' | 'medium' | 'high'). Default: 'low'. */
    liveThinkingLevel: (process.env.GEMINI_LIVE_THINKING_LEVEL ?? 'low') as 'minimal' | 'low' | 'medium' | 'high',

    circuitFailureThreshold: parseInt(process.env.AI_CIRCUIT_FAILURE_THRESHOLD ?? '3', 10),
    circuitCooldownMs: parseInt(process.env.AI_CIRCUIT_COOLDOWN_MS ?? '30000', 10),
    /** Live interview turn hard timeout. Target: ~10-12 s. Default: 12 000 ms. */
    liveTimeoutMs: parseInt(process.env.AI_LIVE_TIMEOUT_MS ?? '12000', 10),
    /** Final evaluation timeout. Larger because the prompt is substantially bigger. */
    evalTimeoutMs: parseInt(process.env.AI_EVAL_TIMEOUT_MS ?? '60000', 10),
    /** Set AI_ENABLE_TELEMETRY=false to disable structured [TELEMETRY] log lines in production. */
    enableTelemetry: (process.env.AI_ENABLE_TELEMETRY ?? 'true') !== 'false',
  },
} as const;
