import path from 'path'
import fs from 'node:fs/promises'
import { CFG, CFG_OGL, replaceInFile } from '../../configs'
import { addPlugin, removePlugin, setCvar } from '../utils'

export async function generateMismod() {
    await fs.cp(path.join(CFG_OGL, 'zonemod'), path.join(CFG_OGL, 'mismod'), { recursive: true })
    await fs.cp(path.join(CFG, 'stripper/zonemod'), path.join(CFG, 'stripper/mismod'), {
        recursive: true,
        force: true,
    })

    await fs.rename(path.join(CFG_OGL, 'mismod/zonemod.cfg'), path.join(CFG_OGL, 'mismod/mismod.cfg'))

    await replaceInFile(
        path.join(CFG_OGL, 'mismod/mismod.cfg'),
        'exec cfgogl/zonemod/shared_settings.cfg',
        'exec cfgogl/mismod/shared_settings.cfg',
    )
    await replaceInFile(
        path.join(CFG_OGL, 'mismod/confogl.cfg'),
        'exec cfgogl/zonemod/shared_cvars.cfg',
        'exec cfgogl/mismod/shared_cvars.cfg',
    )
    await replaceInFile(
        path.join(CFG_OGL, 'mismod/confogl.cfg'),
        'exec cfgogl/zonemod/zonemod.cfg',
        'exec cfgogl/mismod/mismod.cfg',
    )
    await replaceInFile(
        path.join(CFG_OGL, 'mismod/confogl_plugins.cfg'),
        'exec cfgogl/zonemod/shared_plugins.cfg',
        'exec cfgogl/mismod/shared_plugins.cfg',
    )
    await replaceInFile(
        path.join(CFG_OGL, 'mismod/shared_settings.cfg'),
        'exec cvar_tracking.cfg',
        '// exec cvar_tracking.cfg',
    )

    await replaceInFile(path.join(CFG_OGL, 'mismod', 'shared_cvars.cfg'), /l4d_ready_enabled 1/g, '')
    await replaceInFile(
        path.join(CFG_OGL, 'mismod', 'confogl.cfg'),
        /l4d_ready_cfg_name ".*?"/g,
        `l4d_ready_cfg_name "MisMod T1 ${process.env.MISMOD_VERSION}"`,
    )

    await removePlugin('mismod', 'optional/l4d_thirdpersonshoulderblock.smx')
    await removePlugin('mismod', 'optional/l4d_weapon_limits.smx')
    await removePlugin('mismod', 'optional/l4d2_nobackjumps.smx')
    await removePlugin('mismod', 'optional/pause.smx')
    await removePlugin('mismod', 'optional/autopause.smx')

    await addPlugin('mismod', 'optional/c5m3_ammo_pile.smx') // TODO: edit stripper files for mismod
    await addPlugin('mismod', 'optional/l4d2_bots_dont_resist_jockeys.smx')
    await addPlugin('mismod', 'optional/l4d_weapon_giver.smx')
    await addPlugin('mismod', 'optional/l4d_witch_damage_announce.smx')
    await addPlugin('mismod', 'optional/skeet_database.smx')
    await addPlugin('mismod', 'optional/hardcoop/AI_HardSI.smx')
    await addPlugin('mismod', 'optional/hardcoop/ai_targeting.smx')

    await setCvar('mismod', 'l4d_ready_autostart_min', '0.1')
    await setCvar('mismod', 'l4d_ready_autostart_delay', '30')
    await setCvar('mismod', 'l4d_ready_autostart_wait', '1')
    await setCvar('mismod', 'l4d_ready_autostart_delay_2nd_round', '15')
    await setCvar('mismod', 'l4d_ready_enable_sound', '0')
    await setCvar('mismod', 'l4d_ready_show_panel', '0')
    await setCvar('mismod', 'l4d_ready_tp_on_countdown', '0')
    await setCvar('mismod', 'l4d_ready_live_countdown', '0')
    await setCvar('mismod', 'l4d_ready_freeze_countdown', '0')
    await setCvar('mismod', 'l4d_ready_enabled', '2')
    await setCvar('mismod', 'sm_witch_can_spawn', '1')
    await setCvar('mismod', 'l4d_witch_percent', '1')
    await setCvar('mismod', 'l4d_no_tank_rush_block_safe_door', '1')
    await setCvar('mismod', 'l4d_no_tank_rush_close_safe_door', '1')
    await setCvar('mismod', 'director_allow_infected_bots', '1')
    await setCvar('mismod', 'sb_all_bot_game', '1')
    await setCvar('mismod', 'l4d2_melee_damage_charger', '0.0')
    await setCvar('mismod', 'sm_max_lerp', '0.100')
    await setCvar('mismod', 'tankcontrol_pass_menu', '1')
    await setCvar('mismod', 'stripper_cfg_path', 'cfg/stripper/mismod')
}
