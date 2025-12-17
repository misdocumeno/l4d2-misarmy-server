import { $ } from 'execa'
import fs from 'node:fs/promises'
import path from 'path'
import { logger } from '../logger'

// TODO: check somehow if the installed version is older, otherwise, don't update
export async function updateMods(mmVersion: string, smVersion: string) {
    logger.info(`Updating Metamod ${mmVersion} and SourceMod ${smVersion}...`)

    try {
        const mmLatest = await (
            await fetch(`https://mms.alliedmods.net/mmsdrop/${mmVersion}/mmsource-latest-linux`)
        ).text()
        const smLatest = await (
            await fetch(`https://sm.alliedmods.net/smdrop/${smVersion}/sourcemod-latest-linux`)
        ).text()

        const cwd = path.resolve(process.cwd())
        const targetDir = path.join(cwd, 'server', 'left4dead2')

        await downloadAndExtract(`https://mms.alliedmods.net/mmsdrop/${mmVersion}/${mmLatest.trim()}`, targetDir)
        await downloadAndExtract(`https://sm.alliedmods.net/smdrop/${smVersion}/${smLatest.trim()}`, targetDir)
    } catch (e) {
        logger.error('Failed to update mods:', e)
    }
}

async function downloadAndExtract(url: string, targetDir: string) {
    const filename = path.basename(url)
    logger.info(`Downloading ${filename}...`)

    const response = await fetch(url)
    if (!response.ok) throw new Error(`Failed to download ${url}: ${response.statusText}`)

    const buffer = await response.arrayBuffer()
    await fs.writeFile(filename, Buffer.from(buffer))

    logger.info(`Extracting ${filename}...`)
    try {
        await $({ cwd: targetDir })`tar -xzf ${path.resolve(process.cwd(), filename)}`
    } finally {
        await fs.rm(filename, { force: true })
    }
}
