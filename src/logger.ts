import winston from 'winston'
import { config } from './config'

const logFormat = winston.format.printf(({ level, message, timestamp }) => {
    return `${timestamp} [${level}]: ${message}`
})

export const logger = winston.createLogger({
    level: config.LOG_LEVEL.toLowerCase(),
    format: winston.format.combine(
        winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        winston.format.colorize(),
        logFormat,
    ),
    transports: [new winston.transports.Console()],
})
