import os
import re
from .modify_cfg import replace_in_file
from runner.args import parse_args
from typing import Literal


server_cfg = os.path.join(os.getcwd(), 'server/left4dead2/cfg/server.cfg')


def append_to_server_cfg(contents: str):
    with open(server_cfg, 'a') as f:
        f.write(contents)


def append_custom_server_cfg():
    with open(f'{os.getcwd()}/cfg/server.cfg', 'r') as f:
        contents = f.read()
    append_to_server_cfg(contents)


def apply_hostname(server_name: str):
    '''get the hostname from an env variable, replace all env variables
    in curly braces with its value, and put it in the server.cfg'''
    hostname = re.sub(r'\{(\w+)\}', lambda m: os.getenv(m.group(1), ''), server_name)
    replace_in_file(server_cfg, r'^\s*hostname\s+".*?"', f'hostname "{hostname}"')


def apply_rcon_password(rcon_password: str):
    replace_in_file(server_cfg, r'^\s*rcon_password\s+".*?"', f'rcon_password "{rcon_password}"')


def apply_steam_group(steam_groups: list[str]):
    replace_in_file(server_cfg, r'^\s*sv_steamgroup\s+".*?"', f'sv_steamgroup "{",".join(steam_groups)}"')


def apply_tickrate(tickrate: int):
    replace_in_file(server_cfg, r'^\s*sm_cvar\s+sv_minrate\s+\S+', f'sm_cvar sv_minrate {tickrate * 1000}')
    replace_in_file(server_cfg, r'^\s*sm_cvar\s+sv_maxrate\s+\S+', f'sm_cvar sv_maxrate {tickrate * 1000}')
    replace_in_file(server_cfg, r'^\s*sm_cvar\s+sv_minupdaterate\s+\S+', f'sm_cvar sv_minupdaterate {tickrate}')
    replace_in_file(server_cfg, r'^\s*sm_cvar\s+sv_maxupdaterate\s+\S+', f'sm_cvar sv_maxupdaterate {tickrate}')
    replace_in_file(server_cfg, r'^\s*sm_cvar\s+sv_mincmdrate\s+\S+', f'sm_cvar sv_mincmdrate {tickrate}')
    replace_in_file(server_cfg, r'^\s*sm_cvar\s+sv_maxcmdrate\s+\S+', f'sm_cvar sv_maxcmdrate {tickrate}')
    replace_in_file(
        server_cfg,
        r'^\s*sm_cvar\s+nb_update_frequency\s+\S+',
        f'sm_cvar nb_update_frequency {round(1 / (tickrate * 0.6), 5)}',
    )
    replace_in_file(
        server_cfg, r'^\s*sm_cvar\s+net_splitpacket_maxrate\s+\S+', f'sm_cvar net_splitpacket_maxrate {tickrate * 500}'
    )


def apply_max_players(max_players: int):
    replace_in_file(server_cfg, r'^\s*sm_cvar\s+mv_maxplayers\s+\S+', f'sm_cvar mv_maxplayers {max_players}')


def apply_motd():
    # TODO: implement
    pass


def apply_autoload_cfg(mode: Literal['none', 'connection', 'lobby'] | None, cfg: str | None):
    if cfg is not None:
        append_to_server_cfg(
            f'\nsm_cvar confogl_match_autoload {1 if mode not in (None, "none") else 0}\n'
            f'sm_cvar confogl_match_autoload_lobby {1 if mode == "lobby" else 0}\n'
            f'sm_cvar confogl_match_autoconfig "{cfg}"\n'
        )
