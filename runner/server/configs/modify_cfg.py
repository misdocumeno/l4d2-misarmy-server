import os
import re
from typing import Optional


cfgogl = os.path.join(os.getcwd(), 'server/left4dead2/cfg/cfgogl')


def get_configs() -> list[str]:
    return [d for d in os.listdir(cfgogl) if os.path.isdir(os.path.join(cfgogl, d))]


def replace_in_file(file: str, pattern: str, new: str, flags: Optional[re.RegexFlag] = re.RegexFlag.MULTILINE):
    with open(file, 'r') as f:
        content = f.read()
    new_content = re.sub(pattern, new, content, **({} if flags is None else {'flags': flags}))
    with open(file, 'w') as f:
        f.write(new_content)
    return content != new_content


def add_to_file(file: str, content: str):
    with open(file, 'a') as f:
        f.write(content)


def set_cvar(cfg_name: str, cvar: str, value: str):
    set = replace_in_file(
        os.path.join(cfgogl, cfg_name, 'confogl.cfg'), f'confogl_addcvar {cvar} .*', f'confogl_addcvar {cvar} "{value}"'
    )
    set = (
        replace_in_file(
            os.path.join(cfgogl, cfg_name, 'shared_cvars.cfg'),
            f'confogl_addcvar {cvar} .*',
            f'confogl_addcvar {cvar} "{value}"',
        )
        or set
    )
    set = (
        replace_in_file(
            os.path.join(cfgogl, cfg_name, f'{cfg_name}.cfg'),
            f'confogl_addcvar {cvar} .*',
            f'confogl_addcvar {cvar} "{value}"',
        )
        or set
    )
    set = (
        replace_in_file(
            os.path.join(cfgogl, cfg_name, 'shared_settings.cfg'),
            f'confogl_addcvar {cvar} .*',
            f'confogl_addcvar {cvar} "{value}"',
        )
        or set
    )
    if not set:
        replace_in_file(
            os.path.join(cfgogl, cfg_name, 'shared_settings.cfg'),
            r'(?<=exec confogl_personalize\.cfg\n)',
            f'confogl_addcvar {cvar} {value}\n',
        )


def set_cvar_with_confogl(cfg_name: str, cvar: str):
    file = os.path.join(cfgogl, cfg_name, 'confogl.cfg')
    with open(file, 'r') as f:
        content = f.read()
    new_content = re.sub(
        fr'^\s*{cvar}\s+(.*)', lambda m: f'confogl_addcvar {cvar} {m.group(1)}', content, flags=re.MULTILINE
    )
    with open(file, 'w') as f:
        f.write(new_content)


def add_plugin(cfg_name: str, plugin: str, shared=False):
    file = os.path.join(cfgogl, cfg_name, 'shared_plugins.cfg' if shared else 'confogl_plugins.cfg')
    with open(file, 'r') as f:
        content = re.sub(r'//.*', '', f.read())
    if re.search(rf'sm\s+plugins\s+load\s+{re.escape(plugin)}\b', content) is None:
        add_to_file(file, f'\nsm plugins load {plugin}\n')


def remove_plugin(cfg_name: str, plugin: str):
    replace_in_file(os.path.join(cfgogl, cfg_name, 'shared_plugins.cfg'), f'sm plugins load {plugin}', '')
    replace_in_file(os.path.join(cfgogl, cfg_name, 'confogl_plugins.cfg'), f'sm plugins load {plugin}', '')


def set_cfg_names_with_confogl():
    '''Sets l4d_ready_cfg_name with confogl_addcvar to avoid it being set to the wrong value'''
    for cfg in get_configs():
        set_cvar_with_confogl(cfg, 'l4d_ready_cfg_name')


def get_cfg_name(cfg: str) -> str:
    with open(os.path.join(cfgogl, cfg, 'confogl.cfg'), 'r') as f:
        content = f.read()
    cfg_name = re.search(r'^\s*(:?confogl_addcvar |sm_cvar )?l4d_ready_cfg_name\s+"(.*?)"', content, flags=re.MULTILINE)
    assert (
        cfg_name is not None and len(cfg_name.groups()) == 2
    ), f'Could not find cfg name for {cfg}.\ncfg_name: {cfg_name}\ncontent:\n{content}'
    return cfg_name.group(2)
