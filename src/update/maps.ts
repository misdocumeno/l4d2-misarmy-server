import path from 'path'
import fs from 'node:fs/promises'
import { $ } from 'execa'
import { readJson, writeJson } from '../utils/fs'
import { config } from '../config'
import { logger } from '../logger'

const ADDONS_DIR = path.join(process.cwd(), 'server', 'left4dead2', 'addons')
const MAPS_JSON_URL = 'https://l4d2center.com/maps/servers/index.json'
const MAPS_JSON_LOCAL = path.join(ADDONS_DIR, 'maps.json')

type MapEntry = {
    name: string
    size: number
    md5: string
    download_link: string
}

/**
 * Syncs maps from L4D2Center.
 * @param exclude maps that should not be synced.
 */
export async function syncL4D2CenterMaps(exclude: string[] = []) {
    if (!config.UPDATE_MAPS || process.env.BUILD_HAS_CUSTOM_MAPS !== 'true') {
        return
    }

    const localJson = await readJson<MapEntry[]>(MAPS_JSON_LOCAL)

    let l4d2CenterJson: MapEntry[]

    try {
        l4d2CenterJson = await (await fetch(MAPS_JSON_URL)).json()
    } catch (e) {
        logger.error('Failed to fetch L4D2Center maps:', e)
        return
    }

    if (localJson.length === l4d2CenterJson.length && localJson.every((m, i) => m.md5 === l4d2CenterJson[i].md5)) {
        logger.info('Maps are up to date.')
        return
    }

    logger.info('Syncing L4D2Center maps...')

    // delete maps that are not in l4d2center anymore
    for (const map of localJson) {
        if (!l4d2CenterJson.find((m) => m.name === map.name)) {
            await fs.rm(path.join(ADDONS_DIR, map.name))
        }
    }

    // download new or updated maps
    for (const map of l4d2CenterJson) {
        if (exclude.includes(map.name) || localJson.find((m) => m.name === map.name)?.md5 === map.md5) {
            continue
        }

        const archivePath = path.join(ADDONS_DIR, map.name + '.7z')

        try {
            await downloadFile(map.download_link, archivePath)
        } catch {
            // next time it will try again
            map.md5 = 'failed'
            continue
        }

        await $({ cwd: ADDONS_DIR })`7z x ${archivePath} -y`
        await fs.rm(archivePath)
    }

    await writeJson(MAPS_JSON_LOCAL, l4d2CenterJson, { spaces: 4 })
}

async function downloadFile(url: string, dest: string, retries = 5) {
    for (let i = 0; i < retries; i++) {
        try {
            logger.info(`Downloading ${url}... (Attempt ${i + 1}/${retries})`)
            const response = await fetch(url)
            if (!response.ok) throw new Error(`Status ${response.status}`)
            const buffer = await response.arrayBuffer()
            await fs.writeFile(dest, Buffer.from(buffer))
            return
        } catch (e) {
            logger.warn(`Download failed: ${e}. Retrying...`)
            await new Promise((r) => setTimeout(r, 2000 * (i + 1)))
        }
    }
    throw new Error(`Failed to download ${url} after ${retries} attempts`)
}
