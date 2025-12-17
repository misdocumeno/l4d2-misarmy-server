import path from 'path'
import fs from 'node:fs/promises'
import { exists } from '../utils/fs'
import { logger } from '../logger'
import escapeStringRegexp from 'escape-string-regexp'

const CWD = process.cwd()
export const SERVER_CFG = path.join(CWD, 'server/left4dead2/cfg/server.cfg')
export const CFG = path.join(CWD, 'server/left4dead2/cfg')
export const CFG_OGL = path.join(CWD, 'server/left4dead2/cfg/cfgogl')

export async function replaceInFile(file: string, pattern: RegExp | string, replacement: string) {
    try {
        if (!(await exists(file))) return false
        const content = await fs.readFile(file, 'utf8')
        const newContent = content.replace(
            pattern instanceof RegExp ? pattern : new RegExp(escapeStringRegexp(pattern), 'g'),
            replacement,
        )
        if (content !== newContent) {
            await fs.writeFile(file, newContent, 'utf8')
            return true
        }
    } catch (e) {
        logger.error(`Error replacing in file ${file}:`, e)
    }
    return false
}

export async function appendToFile(file: string, content: string) {
    try {
        await fs.appendFile(file, content, 'utf8')
    } catch (e) {
        logger.error(`Error appending to file ${file}:`, e)
    }
}

export async function appendCustomServerCfg() {
    const content = await fs.readFile(path.join(CWD, 'cfg/server.cfg'), 'utf8')
    await appendToFile(SERVER_CFG, `\n${content}\n`)
}

export async function applyHostname(serverName: string) {
    if (!serverName) return
    const hostname = serverName.replace(/\{(\w+)\}/g, (_, key) => process.env[key] ?? '')
    await replaceInFile(SERVER_CFG, /^\s*hostname\s+".*?"/m, `hostname "${hostname}"`)
}

export async function applyRconPassword(password: string) {
    await replaceInFile(SERVER_CFG, /^\s*rcon_password\s+".*?"/m, `rcon_password "${password}"`)
}

export async function applySteamGroup(groups: string[]) {
    await replaceInFile(SERVER_CFG, /^\s*sv_steamgroup\s+".*?"/m, `sv_steamgroup "${groups.join(',')}"`)
}

export async function applyTickrate(tickrate: number) {
    replaceInFile(SERVER_CFG, /^\s*sm_cvar\s+sv_minrate\s+\S+/, `sm_cvar sv_minrate ${tickrate * 1000}`)
    replaceInFile(SERVER_CFG, /^\s*sm_cvar\s+sv_maxrate\s+\S+/, `sm_cvar sv_maxrate ${tickrate * 1000}`)
    replaceInFile(SERVER_CFG, /^\s*sm_cvar\s+sv_minupdaterate\s+\S+/, `sm_cvar sv_minupdaterate ${tickrate}`)
    replaceInFile(SERVER_CFG, /^\s*sm_cvar\s+sv_maxupdaterate\s+\S+/, `sm_cvar sv_maxupdaterate ${tickrate}`)
    replaceInFile(SERVER_CFG, /^\s*sm_cvar\s+sv_mincmdrate\s+\S+/, `sm_cvar sv_mincmdrate ${tickrate}`)
    replaceInFile(SERVER_CFG, /^\s*sm_cvar\s+sv_maxcmdrate\s+\S+/, `sm_cvar sv_maxcmdrate ${tickrate}`)
    replaceInFile(
        SERVER_CFG,
        /^\s*sm_cvar\s+nb_update_frequency\s+\S+/,
        `sm_cvar nb_update_frequency ${(1 / (tickrate * 0.6)).toFixed(5)}`,
    )
    replaceInFile(
        SERVER_CFG,
        /^\s*sm_cvar\s+net_splitpacket_maxrate\s+\S+/,
        `sm_cvar net_splitpacket_maxrate ${tickrate * 500}`,
    )
}

export async function applyAutoloadCfg(mode: 'none' | 'connection' | 'lobby', cfg?: string) {
    if (!cfg) return
    await appendToFile(
        SERVER_CFG,
        `\nsm_cvar confogl_match_autoload ${mode !== 'none' ? 1 : 0}` +
            `\nsm_cvar confogl_match_autoload_lobby ${mode === 'lobby' ? 1 : 0}` +
            `\nsm_cvar confogl_match_autoconfig "${cfg}"\n`,
    )
}

export async function applyMaxPlayers(maxPlayers: number) {
    await replaceInFile(SERVER_CFG, /^\s*sm_cvar\s+mv_maxplayers\s+\S+/m, `sm_cvar mv_maxplayers ${maxPlayers}`)
    await appendToFile(
        SERVER_CFG,
        `\nsm_cvar sv_maxplayers ${maxPlayers}\nsm_cvar sv_visiblemaxplayers ${maxPlayers}\n`,
    )
}

export async function addDatabase(
    name: string,
    host: string,
    database: string,
    user: string,
    pass: string,
    port: number,
    driver: string,
) {
    const dbCfg = path.join(CWD, 'server/left4dead2/addons/sourcemod/configs/databases.cfg')

    let content = await fs.readFile(dbCfg, 'utf8')
    const lastBrace = content.lastIndexOf('}')

    const newDb =
        `\t"${name}"\n\t{\n` +
        `\t\t"driver"    "${driver}"\n` +
        `\t\t"host"      "${host}"\n` +
        `\t\t"database"  "${database}"\n` +
        `\t\t"user"      "${user}"\n` +
        `\t\t"pass"      "${pass}"\n` +
        `\t\t"port"      "${port}"\n` +
        '\n\t}\n'

    content = content.slice(0, lastBrace) + newDb + content.slice(lastBrace)
    await fs.writeFile(dbCfg, content, 'utf8')
}
