import winston from 'winston';
import { config } from '../config';

const { combine, timestamp, colorize, printf, json } = winston.format;

const devFormat = combine(
  colorize(),
  timestamp({ format: 'HH:mm:ss' }),
  printf(({ level, message, timestamp: ts }) => `${ts} [${level}] ${message}`)
);

const prodFormat = combine(timestamp(), json());

export const logger = winston.createLogger({
  level: config.isDevelopment ? 'debug' : 'info',
  format: config.isDevelopment ? devFormat : prodFormat,
  transports: [new winston.transports.Console()],
});
