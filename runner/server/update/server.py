import os
import shutil
from .repo import update_repo, copy_repo_files
from .mods import update_mods
from ..matchmodes import generate_matchmodes
from ..configs.modify_cfg import add_plugin, set_cfg_names_with_confogl, replace_in_file
from ..configs.generate.mismod import generate_mismod
from ..configs.generate.zonepractice import generate_zonepractice
from ..configs.server_cfg import (
    append_custom_server_cfg,
    apply_hostname,
    apply_rcon_password,
    apply_steam_group,
    apply_tickrate,
    apply_autoload_cfg,
    apply_max_players,
)
from ..configs.databases import add_database
from ..configs.server_cfg import append_to_server_cfg
from .maps.sync_l4d2center import sync_l4d2center_maps
from .maps.generate_kv import generate_campaigns_kv
from runner.args import parse_args
from runner.logger import logger


def update_server():
    args, _ = parse_args()

    if args.auto_update:
        logger.info('Deleting old files.')
        clean_addons_directory(f'{os.getcwd()}/server/left4dead2/addons', preserve_vpks=True, preserve_logs=True)
        shutil.rmtree(f'{os.getcwd()}/server/left4dead2/cfg/cfgogl', ignore_errors=True)
        shutil.rmtree(f'{os.getcwd()}/server/left4dead2/cfg/sourcemod', ignore_errors=True)

        logger.info('Updating srcds.')
        os.system(f'steamcmd +force_install_dir {os.getcwd()}/server +login anonymous +app_update 222860 +quit')

        print('args.update_maps is', args.update_maps)

        if args.update_maps and os.getenv('BUILD_HAS_CUSTOM_MAPS') == 'true':
            logger.info('Updating maps.')
            # TODO: add extra_maps/ at the root or something,
            # and exclude those .vpk files from being deleted
            sync_l4d2center_maps()

        logger.info('Generating campaigns.cfg.')
        generate_campaigns_kv()

        logger.info('Updating repo and copying files.')
        update_repo()
        copy_repo_files()

        # TODO: check if update is needed before downloading
        logger.info('Updating metamod and sourcemod.')
        update_mods(args.metamod_version, args.sourcemod_version)

        logger.info('Copying custom files.')
        shutil.copytree(
            f'{os.getcwd()}/cfg/',
            f'{os.getcwd()}/server/left4dead2/cfg/',
            dirs_exist_ok=True,
            ignore=lambda dir, _: (
                ['server.cfg'] if args.server_cfg_mode == 'append' and dir == f'{os.getcwd()}/cfg/' else []
            ),
        )
        shutil.copytree(f'{os.getcwd()}/addons/', f'{os.getcwd()}/server/left4dead2/addons/', dirs_exist_ok=True)

        for file in ('host.txt', 'motd.txt', 'myhost.txt', 'mymotd.txt'):
            if os.path.exists(f'{os.getcwd()}/{file}'):
                shutil.copy(f'{os.getcwd()}/{file}', f'{os.getcwd()}/server/left4dead2/{file}')

    os.remove(f'{os.getcwd()}/server/left4dead2/addons/sourcemod/plugins/nextmap.smx')

    logger.info('Generating server.cfg.')
    if args.server_cfg_mode == 'append':
        append_custom_server_cfg()
    apply_hostname(args.server_name)
    apply_rcon_password(args.rcon_password)
    apply_steam_group(args.steam_group)
    apply_tickrate(args.tickrate)
    apply_autoload_cfg(args.auto_load_mode, args.auto_load_cfg)
    apply_max_players(args.max_players)
    if args.tv_name:
        append_to_server_cfg(f'\nsm_cvar tv_name "{args.tv_name}"\n')

    # TODO: add to other configs, and make it like l4d1, with sound and all that.
    # TODO: do pounce tops too, and other stuff maybe
    logger.info('Adding top skeets plugins to 1v1 hunter configs.')
    add_plugin('zh1v1', 'optional/skeet_database.smx')
    add_plugin('nextmod1v1', 'optional/skeet_database.smx')

    logger.info('Adding sourcebans database.')
    add_database('sourcebans', args.sb_host, args.sb_database, args.sb_user, args.sb_pass, args.sb_port, 'mysql')

    logger.info('Applying sourcebans server id and website.')
    replace_in_file(
        f'{os.getcwd()}/server/left4dead2/addons/sourcemod/configs/sourcebans/sourcebans.cfg',
        r'"ServerID"\s+".*"',
        f'"ServerID" "{args.sb_server_id}"',
    )
    replace_in_file(
        f'{os.getcwd()}/server/left4dead2/addons/sourcemod/configs/sourcebans/sourcebans.cfg',
        r'"Website"\s+".*"',
        f'"Website" "{args.sb_website}"',
    )

    logger.info('Applying demos api endpoint.')
    replace_in_file(
        f'{os.getcwd()}/server/left4dead2/addons/sourcemod/configs/autorecorder.cfg',
        r'"api_endpoint"\s+".*"',
        f'"api_endpoint" "{args.demos_api_endpoint}"',
    )
    replace_in_file(
        f'{os.getcwd()}/server/left4dead2/addons/sourcemod/configs/autorecorder.cfg',
        r'"api_token"\s+".*"',
        f'"api_token" "{args.demos_api_token}"',
    )

    logger.info('Generating mismod.')
    generate_mismod()

    logger.info('Generating ZonePractice.')
    generate_zonepractice()

    logger.info('Setting cfg names with confogl_addcvar.')
    set_cfg_names_with_confogl()

    logger.info('Generating matchmodes.txt file with up to date cfg names.')
    generate_matchmodes()


def clean_addons_directory(path: str, preserve_vpks=False, preserve_logs=False):
    logs_path = os.path.normpath(os.path.join(path, 'sourcemod', 'logs'))

    for root, dirs, files in os.walk(path, topdown=False):
        current_path = os.path.normpath(root)

        if preserve_logs and current_path.startswith(logs_path):
            continue

        for file in files:
            file_path = os.path.join(root, file)

            if preserve_vpks and file.lower().endswith('.vpk'):
                continue

            if preserve_logs and os.path.normpath(file_path).startswith(logs_path):
                continue

            try:
                os.remove(os.path.join(root, file))
            except Exception as e:
                logger.error(f'Failed to delete file {file}: {e}')

        for dir in dirs:
            dir_path = os.path.join(root, dir)

            if preserve_logs and os.path.normpath(dir_path).startswith(logs_path):
                continue

            try:
                if not os.listdir(dir_path):
                    os.rmdir(dir_path)
            except Exception as e:
                logger.error(f'Failed to delete directory {dir}: {e}')
