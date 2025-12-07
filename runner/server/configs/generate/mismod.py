import os
import shutil
from ..modify_cfg import replace_in_file, add_plugin, remove_plugin, set_cvar


cfgogl = os.path.join(os.getcwd(), 'server/left4dead2/cfg/cfgogl')
cfg = os.path.join(os.getcwd(), 'server/left4dead2/cfg')


def generate_mismod():
    shutil.copytree(os.path.join(cfgogl, 'zonemod'), os.path.join(cfgogl, 'mismod'), dirs_exist_ok=True)
    shutil.copytree(os.path.join(cfg, 'stripper', 'zonemod'),
                    os.path.join(cfg, 'stripper', 'mismod'), dirs_exist_ok=True)

    shutil.move(os.path.join(cfgogl, 'mismod', 'zonemod.cfg'), os.path.join(cfgogl, 'mismod', 'mismod.cfg'))

    replace_in_file(os.path.join(cfgogl, 'mismod', 'mismod.cfg'),
                    r'exec cfgogl/zonemod/shared_settings\.cfg', 'exec cfgogl/mismod/shared_settings.cfg')
    replace_in_file(os.path.join(cfgogl, 'mismod', 'confogl.cfg'),
                    r'exec cfgogl/zonemod/shared_cvars\.cfg', 'exec cfgogl/mismod/shared_cvars.cfg')
    replace_in_file(os.path.join(cfgogl, 'mismod', 'confogl.cfg'),
                    r'exec cfgogl/zonemod/zonemod\.cfg', 'exec cfgogl/mismod/mismod.cfg')
    replace_in_file(os.path.join(cfgogl, 'mismod', 'confogl_plugins.cfg'),
                    r'exec cfgogl/zonemod/shared_plugins\.cfg', 'exec cfgogl/mismod/shared_plugins.cfg')
    replace_in_file(os.path.join(cfgogl, 'mismod', 'shared_settings.cfg'),
                    r'exec cvar_tracking\.cfg', '// exec cvar_tracking.cfg')

    replace_in_file(os.path.join(cfgogl, 'mismod', 'shared_cvars.cfg'), 'l4d_ready_enabled 1', '')
    replace_in_file(os.path.join(cfgogl, 'mismod', 'confogl.cfg'),
                    r'l4d_ready_cfg_name "ZoneMod .*?"', f'l4d_ready_cfg_name "MisMod T1 {os.environ["MISMOD_VERSION"]}"')

    replace_in_file(os.path.join(os.getcwd(), 'server/left4dead2/addons/sourcemod/configs/matchmodes.txt'),
                    r'{MISMOD_VERSION}', os.environ["MISMOD_VERSION"])

    remove_plugin('mismod', 'optional/l4d_thirdpersonshoulderblock.smx')
    remove_plugin('mismod', 'optional/l4d_weapon_limits.smx')
    remove_plugin('mismod', 'optional/l4d2_nobackjumps.smx')
    remove_plugin('mismod', 'optional/pause.smx')
    remove_plugin('mismod', 'optional/autopause.smx')

    add_plugin('mismod', 'optional/c5m3_ammo_pile.smx')  # TODO: edit stripper files for mismod with this script
    add_plugin('mismod', 'optional/l4d2_bots_dont_resist_jockeys.smx')
    add_plugin('mismod', 'optional/l4d_weapon_giver.smx')
    add_plugin('mismod', 'optional/l4d_witch_damage_announce.smx')
    add_plugin('mismod', 'optional/skeet_database.smx')
    add_plugin('mismod', 'optional/hardcoop/AI_HardSI.smx')
    add_plugin('mismod', 'optional/hardcoop/ai_targeting.smx')

    set_cvar('mismod', 'l4d_ready_autostart_min', '0.1')
    set_cvar('mismod', 'l4d_ready_autostart_delay', '30')
    set_cvar('mismod', 'l4d_ready_autostart_wait', '1')
    set_cvar('mismod', 'l4d_ready_autostart_delay_2nd_round', '15')
    set_cvar('mismod', 'l4d_ready_enable_sound', '0')
    set_cvar('mismod', 'l4d_ready_show_panel', '0')
    set_cvar('mismod', 'l4d_ready_tp_on_countdown', '0')
    set_cvar('mismod', 'l4d_ready_live_countdown', '0')
    set_cvar('mismod', 'l4d_ready_freeze_countdown', '0')
    set_cvar('mismod', 'l4d_ready_enabled', '2')
    set_cvar('mismod', 'sm_witch_can_spawn', '1')
    set_cvar('mismod', 'l4d_witch_percent', '1')
    set_cvar('mismod', 'l4d_no_tank_rush_block_safe_door', '1')
    set_cvar('mismod', 'l4d_no_tank_rush_close_safe_door', '1')
    set_cvar('mismod', 'director_allow_infected_bots', '1')
    set_cvar('mismod', 'sb_all_bot_game', '1')
    set_cvar('mismod', 'l4d2_melee_damage_charger', '0.0')
    set_cvar('mismod', 'sm_max_lerp', '0.100')
    set_cvar('mismod', 'tankcontrol_pass_menu', '1')
    set_cvar('mismod', 'stripper_cfg_path', 'cfg/stripper/mismod')

    # TODO: poner en el confogl_off.cfg poner ready_enabled otra vez o no se bien como es,
    # por que carajo al cambiar de cfg sigue sin aparecer el panel? hacer debug
    # parece que l4d_ready_show_panel es default 0 en el plugin?? ver.
    # las demas cvars, las de tp en ready, la de countdown, etc, tambien siguen sin cambiarse, por que? ver
