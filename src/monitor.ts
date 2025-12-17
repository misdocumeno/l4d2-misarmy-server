import os from 'os'
import dns from 'dns/promises'
import sq from 'source-server-query'
import { serverManager } from './server'
import { config } from './config'
import { logger } from './logger'

export class Monitor {
    private interval: NodeJS.Timeout | null = null
    private emptyCounter = 0
    private playersJoined = false
    private starting = true

    constructor() {}

    public async start() {
        if (this.interval) return

        logger.info('Starting monitor loop...')
        this.checkLoop()
    }

    public stop() {
        if (this.interval) {
            clearTimeout(this.interval)
            this.interval = null
        }
    }

    private async checkLoop() {
        await this.check()
        this.interval = setTimeout(() => this.checkLoop(), 10000)
    }

    private async check() {
        try {
            logger.debug('Querying server status...')
            const localhost = (await dns.lookup(os.hostname(), { family: 4 })).address
            const currentPlayers = await sq.players(localhost, config.PORT, 3000)

            logger.debug(`Player count: ${currentPlayers.length}`)

            if (this.starting) {
                logger.info('Server started (detected by monitor).')
                this.starting = false
            }

            if (currentPlayers.length > 0) {
                this.playersJoined = true
                this.emptyCounter = 0
            } else {
                this.emptyCounter++
            }

            logger.debug({ currentPlayers, playersJoined: this.playersJoined, emptyCounter: this.emptyCounter })

            // restart if empty for 6 checks (60 seconds) AND players had joined before
            if (this.playersJoined && this.emptyCounter >= 6) {
                logger.info('Server empty for too long. Restarting...')
                await serverManager.stop()
                this.emptyCounter = 0
                this.starting = true
                this.playersJoined = false
                serverManager.start()
            }
        } catch (e) {
            logger.debug(`Monitor query failed: ${e}`)
        }
    }
}

export const monitor = new Monitor()
