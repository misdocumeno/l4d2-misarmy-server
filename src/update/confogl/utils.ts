import path from 'path'
import fs from 'node:fs/promises'
import escapeStringRegexp from 'escape-string-regexp'
import { appendToFile, CFG_OGL, replaceInFile } from '../configs'

export async function setCvar(cfgName: string, cvar: string, value: string) {
    const files = [
        path.join(CFG_OGL, cfgName, 'confogl.cfg'),
        path.join(CFG_OGL, cfgName, 'shared_cvars.cfg'),
        path.join(CFG_OGL, cfgName, `${cfgName}.cfg`),
        path.join(CFG_OGL, cfgName, 'shared_settings.cfg'),
    ]

    const pattern = new RegExp(`confogl_addcvar ${cvar} .*`, 'g')
    const replacement = `confogl_addcvar ${cvar} "${value}"`

    let set = false
    for (const file of files) {
        if (await replaceInFile(file, pattern, replacement)) {
            set = true
        }
    }

    if (!set) {
        const settingsFile = path.join(CFG_OGL, cfgName, 'shared_settings.cfg')
        await replaceInFile(
            settingsFile,
            'exec confogl_personalize.cfg',
            `confogl_addcvar ${cvar} "${value}"\nexec confogl_personalize.cfg`,
        )
    }
}

export async function addPlugin(cfgName: string, plugin: string, shared = false) {
    const file = path.join(CFG_OGL, cfgName, shared ? 'shared_plugins.cfg' : 'confogl_plugins.cfg')
    const content = (await fs.readFile(file, 'utf8')).replace(/\/\/.*$/gm, '')
    const pattern = new RegExp(String.raw`sm\s+plugins\s+load\s+${escapeStringRegexp(plugin)}\b`, 'g')
    if (!pattern.test(content)) {
        await appendToFile(file, `\nsm plugins load ${plugin}\n`)
    }
}

export async function removePlugin(cfgName: string, plugin: string) {
    await replaceInFile(path.join(CFG_OGL, cfgName, 'shared_plugins.cfg'), `sm plugins load ${plugin}`, '')
    await replaceInFile(path.join(CFG_OGL, cfgName, 'confogl_plugins.cfg'), `sm plugins load ${plugin}`, '')
}
