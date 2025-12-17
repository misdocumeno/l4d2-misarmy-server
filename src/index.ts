import { serverManager } from './server'
import { monitor } from './monitor'
import { logger } from './logger'
import { updateServer } from './update'

async function main() {
    await updateServer()

    logger.info('Starting SRCDS...')
    serverManager.start()
    monitor.start()

    const shutdown = async (signal: string) => {
        logger.info(`Received ${signal}. Shutting down...`)
        monitor.stop()
        await serverManager.stop()
        process.exit(0)
    }

    process.on('SIGINT', () => shutdown('SIGINT'))
    process.on('SIGTERM', () => shutdown('SIGTERM'))
}

main().catch((err) => {
    logger.error('Fatal error:', err)
    process.exit(1)
})
