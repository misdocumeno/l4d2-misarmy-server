import os
import re
from .modify_cfg import replace_in_file

databases_cfg = os.path.join(os.getcwd(), 'server/left4dead2/addons/sourcemod/configs/databases.cfg')


def add_database(section: str, host: str, database: str, user: str, pass_: str, port: int, driver='default'):
    replace_in_file(
        databases_cfg,
        r'}\s*$',
        f'\n\t"{section}"\n'
        '\t{\n'
        f'\t\t"driver"     "{driver}"\n'
        f'\t\t"host"       "{host}"\n'
        f'\t\t"database"   "{database}"\n'
        f'\t\t"user"       "{user}"\n'
        f'\t\t"pass"       "{pass_}"\n'
        f'\t\t"port"       "{port}"\n'
        '\t}\n'
        '}\n',
        flags=None,
    )
