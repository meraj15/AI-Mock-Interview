import dotenv from 'dotenv';

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
} as const;
