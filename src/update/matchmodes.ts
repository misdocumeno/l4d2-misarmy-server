import path from 'path'
import fs from 'node:fs/promises'
import { config } from '../config'
import { logger } from '../logger'

const CFG_OGL = path.join(process.cwd(), 'server/left4dead2/cfg/cfgogl')

const MATCHMODES_DICT: Record<string, string[]> = {
    'ZoneMod Configs': ['zonemod', 'zoneretro', 'zm3v3', 'zm2v2', 'zm1v1'],
    'NeoMod Configs': ['neomod'],
    'NextMod Configs': ['nextmod', 'nextmod3v3', 'nextmod2v2', 'nextmod1v1'],
    'Promod Configs': ['pmelite', 'deadman'],
    'Acemod Revamped Configs': ['acemodrv', 'amrv3v3', 'amrv2v2', 'amrv1v1'],
    'EQ Configs': ['eq', 'eq3v3', 'eq2v2', 'eq1v1'],
    'Apex Configs': ['apex'],
    'Hunters Configs': ['zonehunters', 'zh3v3', 'zh2v2', 'zh1v1'],
    'MisMod Configs': ['mismod'],
    'Practice Configs': ['gauntlet'],
    'Vanilla Configs': ['vanilla', 'vanila'],
}

async function getCfgName(cfg: string): Promise<string> {
    try {
        const file = path.join(CFG_OGL, cfg, 'confogl.cfg')
        const content = await fs.readFile(file, 'utf8')
        const match = content.match(/^\s*(?:confogl_addcvar |sm_cvar )?l4d_ready_cfg_name\s+"(.*?)"/m)
        if (match && match[1]) {
            return match[1]
        }
    } catch (e) {
        logger.warn(`Could not get cfg name for ${cfg}: ${e}`)
    }
    return cfg
}

// TODO: find out if there is a package that can do this
function dictToKeyValues(data: Record<string, any>, indent = 0): string {
    let result = ''
    const indentStr = '\t'.repeat(indent)

    for (const [key, value] of Object.entries(data)) {
        if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
            result += `${indentStr}"${key}"\n${indentStr}{\n${dictToKeyValues(value, indent + 1)}${indentStr}}\n`
        } else {
            result += `${indentStr}"${key}" "${value}"\n`
        }
    }
    return result
}

export async function generateMatchmodes() {
    logger.info('Generating matchmodes.txt...')

    let configs = { ...MATCHMODES_DICT }

    if (config.MATCHMODES_CFGS.length) {
        for (const key in configs) {
            configs[key] = configs[key].filter((cfg) => config.MATCHMODES_CFGS!.includes(cfg))
        }
    }

    if (config.EXCLUDE_MATCHMODES_CFGS.length) {
        for (const key in configs) {
            configs[key] = configs[key].filter((cfg) => !config.EXCLUDE_MATCHMODES_CFGS!.includes(cfg))
        }
    }

    for (const key in configs) {
        if (configs[key].length === 0) {
            delete configs[key]
        }
    }

    const matchmodes: Record<string, Record<string, Record<string, string>>> = {}

    for (const [category, cfgs] of Object.entries(configs)) {
        matchmodes[category] = {}
        for (const cfg of cfgs) {
            const name = await getCfgName(cfg)
            matchmodes[category][cfg] = { name }
        }
    }

    await fs.writeFile(
        path.join(process.cwd(), 'server/left4dead2/addons/sourcemod/configs/matchmodes.txt'),
        dictToKeyValues({ MatchModes: matchmodes }),
    )
}
