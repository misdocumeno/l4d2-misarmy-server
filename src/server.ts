import { execa } from 'execa'
import path from 'path'
import { config, extraArgs } from './config'
import { logger } from './logger'

// TODO: use srcds_linux directly, instead of srcds_run

export class ServerManager {
    private process: ReturnType<typeof execa> | null = null

    constructor() {}

    public start() {
        if (this.process) {
            logger.info('Server already running.')
            return
        }

        logger.info(`Starting server on port ${config.PORT}`)

        const serverDir = path.resolve(process.cwd(), 'server')
        const executable = path.join(serverDir, 'srcds_run')

        const args = [
            '-tickrate',
            `${config.TICKRATE}`,
            '-port',
            `${config.PORT}`,
            '-maxplayers',
            `${config.MAX_PLAYERS}`,
            '+sv_clockcorrection_msecs',
            '25',
            '-timeout',
            '10',
        ]

        if (!extraArgs.includes('+map')) {
            args.push('+map', 'c2m1_highway')
        }

        if (config.TV_ENABLE) {
            args.push('+tv_enable', '1')

            if (config.TV_NAME) {
                args.push('+tv_name', config.TV_NAME)
            }
        }

        args.push(...extraArgs)

        logger.debug(`SRCDS Args: ${args.join(' ')}`)

        this.process = execa(executable, args, {
            cwd: serverDir,
            stdio: 'inherit',

            detached: true,
            shell: false,

            reject: false,
            forceKillAfterTimeout: 10000,
        })

        this.process.on('exit', (code: number | null, signal: NodeJS.Signals | null) => {
            logger.info(`Server exited with code ${code} and signal ${signal}`)
            this.process = null
        })
    }

    public async stop() {
        if (!this.process) return

        logger.info('Stopping server...')

        try {
            // kill the entire process group
            process.kill(-this.process.pid!, 'SIGTERM')
            await this.process
            process.kill(-this.process.pid!, 'SIGKILL')
        } catch {}

        this.process = null
    }

    public get isRunning() {
        return this.process !== null
    }

    public onExit(callback: (code: number | null, signal: NodeJS.Signals | null) => void) {
        if (this.process) {
            this.process.on('exit', callback)
        }
    }
}

export const serverManager = new ServerManager()
