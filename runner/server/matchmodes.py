import os
from .configs.modify_cfg import get_cfg_name
from runner.args import parse_args


sm_configs = os.path.join(os.getcwd(), 'server/left4dead2/addons/sourcemod/configs')


def generate_matchmodes():
    '''Generates a matchmodes.txt file with the updated cfg names,
    getting the l4d_ready_cfg_name from confogl.cfg'''

    args, _ = parse_args()
    include: list[str] | None = args.matchmodes_cfgs
    exclude: list[str] | None = args.exclude_matchmodes_cfgs

    file = os.path.join(sm_configs, 'matchmodes.txt')

    configs = {
        'ZoneMod Configs': ['zonemod', 'zoneretro', 'zm3v3', 'zm2v2', 'zm1v1'],
        'NeoMod Configs': ['neomod'],
        'NextMod Configs': ['nextmod', 'nextmod3v3', 'nextmod2v2', 'nextmod1v1'],
        'Promod Configs': ['pmelite', 'deadman'],
        'Acemod Revamped Configs': ['acemodrv', 'amrv3v3', 'amrv2v2', 'amrv1v1'],
        'EQ Configs': ['eq', 'eq3v3', 'eq2v2', 'eq1v1'],
        'Apex Configs': ['apex'],
        'Hunters Configs': ['zonehunters', 'zh3v3', 'zh2v2', 'zh1v1'],
        'MisMod Configs': ['mismod'],
        # 'Practice Configs': ['gauntlet', 'zonepractice'],
        'Practice Configs': ['gauntlet'],
        'Vanilla Configs': ['vanilla', 'vanila'],
    }

    if include is not None:
        configs = {k: [cfg for cfg in v if cfg in include] for k, v in configs.items()}

    if exclude is not None:
        configs = {k: [cfg for cfg in v if cfg not in exclude] for k, v in configs.items()}

    configs = {k: v for k, v in configs.items() if len(v) != 0}

    matchmodes = {k: {cfg: {'name': get_cfg_name(cfg)} for cfg in v} for k, v in configs.items()}

    with open(file, 'w') as f:
        f.write(dict_to_key_values({'MatchModes': matchmodes}))


def dict_to_key_values(data: dict, indent: int = 0) -> str:
    '''Convert a dictionary to a string of Valve's KeyValues format.'''
    result = ""
    indent_str = "\t" * indent

    for key, value in data.items():
        if isinstance(value, dict):
            result += f'{indent_str}"{key}"\n{indent_str}{{\n{dict_to_key_values(value, indent + 1)}{indent_str}}}\n'
        else:
            result += f'{indent_str}"{key}" "{value}"\n'

    return result
