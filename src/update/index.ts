import { config } from '../config'
import path from 'path'
import fs from 'node:fs/promises'
import { exists } from '../utils/fs'
import { execa } from 'execa'
import { updateRepo, copyRepoFiles } from './repo'
import { updateMods } from './mods'
import { syncL4D2CenterMaps } from './maps'
import { generateKv } from './kv'
import {
    appendCustomServerCfg,
    applyHostname,
    applyRconPassword,
    applySteamGroup,
    applyTickrate,
    applyAutoloadCfg,
    applyMaxPlayers,
    addDatabase,
    replaceInFile,
} from './configs'
import { generateMatchmodes } from './matchmodes'

import { logger } from '../logger'
import { addPlugin } from './confogl/utils'
import { generateMismod } from './confogl/cfgs/mismod'
import { generateZonePractice } from './confogl/cfgs/zonepractice'
import { setCfgNamesWithConfogl } from './confogl/names'

// big TODO:
// do not update if there are no changes
// somehow check if there are repo updates, map updates, game updates, etc
// if there are no updates, do nothing
// if there are, use rsync or something to minimize the work'
// TODO: confirm that steamcmd doesn't write any file to disk when there is no updates available
// if it does, hit some api or something, to prevent running it if there are no updates
// TODO: do a simple git pull for the repos, and only force it if it fails

const CWD = process.cwd()

export async function updateServer() {
    logger.info('Starting Server Update...')

    if (config.AUTO_UPDATE) {
        await updateFiles()
    }

    await generateFiles()

    logger.info('Update finished.')
}

async function updateFiles() {
    logger.info('Deleting old files...')
    await cleanAddonsDirectory(path.join(CWD, 'server/left4dead2/addons'), { preserveVpks: true, preserveLogs: true })
    await fs.rm(path.join(CWD, 'server/left4dead2/cfg/cfgogl'), { recursive: true, force: true })
    await fs.rm(path.join(CWD, 'server/left4dead2/cfg/sourcemod'), { recursive: true, force: true })

    logger.info('Updating SRCDS via SteamCMD...')
    try {
        // TODO: try using $`steamcmd ...`
        await execa(
            'steamcmd',
            ['+force_install_dir', path.join(CWD, 'server'), '+login', 'anonymous', '+app_update', '222860', '+quit'],
            { stdio: 'inherit' },
        )
    } catch (e) {
        logger.error('SteamCMD update failed:', e)
    }

    if (config.UPDATE_MAPS && process.env.BUILD_HAS_CUSTOM_MAPS === 'true') {
        logger.info('Updating custom maps...')
        await syncL4D2CenterMaps()
    }

    await updateRepo()
    await copyRepoFiles()

    await updateMods(config.METAMOD_VERSION, config.SOURCEMOD_VERSION)

    logger.info('Copying custom files...')
    await fs.cp(path.join(CWD, 'cfg'), path.join(CWD, 'server/left4dead2/cfg'), {
        recursive: true,
        force: true,
        filter: (src) =>
            // do not copy server.cfg if we have to append to it
            config.SERVER_CFG_MODE !== 'append' ||
            path.basename(src) !== 'server.cfg' ||
            src !== path.join(path.join(CWD, 'cfg'), 'server.cfg'),
    })

    await fs.cp(path.join(CWD, 'addons'), path.join(CWD, 'server/left4dead2/addons'), { recursive: true, force: true })

    for (const file of ['host.txt', 'motd.txt', 'myhost.txt', 'mymotd.txt']) {
        const srcFile = path.join(CWD, file)
        if (await exists(srcFile)) {
            await fs.cp(srcFile, path.join(CWD, 'server/left4dead2', file), { force: true })
        }
    }
}

async function generateFiles() {
    logger.info('Generating campaigns.cfg...')
    await generateKv()

    await fs.rm(path.join(CWD, 'server/left4dead2/addons/sourcemod/plugins/nextmap.smx'), { force: true })

    if (config.SERVER_CFG_MODE === 'append') {
        await appendCustomServerCfg()
    }

    await applyHostname(config.SERVER_NAME)
    await applyRconPassword(config.RCON_PASSWORD)
    await applySteamGroup(config.STEAM_GROUP)
    await applyTickrate(config.TICKRATE)
    await applyAutoloadCfg(config.AUTO_LOAD_MODE, config.AUTO_LOAD_CFG)
    await applyMaxPlayers(config.MAX_PLAYERS)

    if (config.TV_NAME) {
        await fs.appendFile(
            path.join(CWD, 'server/left4dead2/cfg/server.cfg'),
            `\nsm_cvar tv_name "${config.TV_NAME}"\n`,
        )
    }

    logger.info('Adding plugins...')
    await addPlugin('zh1v1', 'optional/skeet_database.smx')
    await addPlugin('nextmod1v1', 'optional/skeet_database.smx')

    logger.info('Adding databases...')
    await addDatabase(
        'sourcebans',
        config.SB_HOST,
        config.SB_DATABASE,
        config.SB_USER,
        config.SB_PASS,
        config.SB_PORT,
        'mysql',
    )

    logger.info('Configuring sourcebans...')
    const sbCfg = path.join(CWD, 'server/left4dead2/addons/sourcemod/configs/sourcebans/sourcebans.cfg')
    await replaceInFile(sbCfg, /"ServerID"\s+".*"/, `"ServerID" "${config.SB_SERVER_ID}"`)
    await replaceInFile(sbCfg, /"Website"\s+".*"/, `"Website" "${config.SB_WEBSITE}"`)

    logger.info('Configuring autorecorder...')
    const recorderCfg = path.join(CWD, 'server/left4dead2/addons/sourcemod/configs/autorecorder.cfg')
    await replaceInFile(recorderCfg, /"api_endpoint"\s+".*"/, `"api_endpoint" "${config.DEMOS_API_ENDPOINT}"`)
    await replaceInFile(recorderCfg, /"api_token"\s+".*"/, `"api_token" "${config.DEMOS_API_TOKEN}"`)

    logger.info('Generating confogl configs...')
    await generateMismod()
    await generateZonePractice()

    logger.info('Setting cfg names with confogl_addcvar...')
    await setCfgNamesWithConfogl()

    logger.info('Generating matchmodes.txt...')
    await generateMatchmodes()
}

async function cleanAddonsDirectory(
    dirPath: string,
    { preserveVpks = false, preserveLogs = false }: { preserveVpks?: boolean; preserveLogs?: boolean } = {},
) {
    const logsPath = path.join(dirPath, 'sourcemod', 'logs')
    const mapsJson = path.join(dirPath, 'maps.json')

    if (!(await exists(dirPath))) return

    const entries = await fs.readdir(dirPath, {
        recursive: true,
        withFileTypes: true,
    })

    for (const entry of entries) {
        const fullPath = path.join(entry.parentPath, entry.name)

        if (
            fullPath === mapsJson ||
            (preserveLogs && fullPath.startsWith(logsPath)) ||
            (preserveVpks && entry.isFile() && entry.name.toLowerCase().endsWith('.vpk'))
        ) {
            continue
        }

        await fs.rm(fullPath, { recursive: true, force: true })
    }
}
