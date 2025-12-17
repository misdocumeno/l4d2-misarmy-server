import path from 'path'
import fs from 'node:fs/promises'
import { logger } from '../../logger'
import { CFG_OGL, replaceInFile } from '../configs'

export async function setCfgNamesWithConfogl() {
    logger.info('Setting cfg names with confogl_addcvar...')

    for (const cfg of await fs.readdir(CFG_OGL)) {
        const cfgPath = path.join(CFG_OGL, cfg)
        const stat = await fs.stat(cfgPath)
        if (stat.isDirectory()) {
            const file = path.join(cfgPath, 'confogl.cfg')
            await replaceInFile(file, /^\s*l4d_ready_cfg_name\b.*/gm, 'confogl_addcvar $&')
        }
    }
}
