import os
import py7zr
import hashlib
import requests
from pathlib import Path
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from runner.logger import logger


session = requests.Session()
retries = Retry(total=5, backoff_factor=2, status_forcelist=[500, 502, 503, 504])
session.mount('http://', HTTPAdapter(max_retries=retries))
session.mount('https://', HTTPAdapter(max_retries=retries))


def sync_l4d2center_maps(extra_maps: list[str] | None = None, except_: list[str] | None = None):
    extra_maps = extra_maps or []
    except_ = except_ or []
    json = session.get('https://l4d2center.com/maps/servers/index.json').json()

    addons_dir = os.path.join(os.getcwd(), 'server', 'left4dead2', 'addons')
    addon_files = [file for file in os.listdir(addons_dir) if file.endswith('.vpk') and file not in extra_maps]

    for file in addon_files:
        if file not in [map['name'] for map in json]:
            logger.debug(f'Deleting extra file {file}.')
            os.remove(os.path.join(addons_dir, file))
            addon_files.remove(file)

        checksum = [map['md5'] for map in json if map['name'] == file][0]

        if file_checksum(os.path.join(addons_dir, file)) != checksum:
            logger.debug(f'Deleting different file {file}.')
            os.remove(os.path.join(addons_dir, file))
            addon_files.remove(file)

    updated = 0

    for map in json:
        if map['name'] in addon_files or map['name'] in except_:
            continue

        logger.debug(f'Downloading {map["download_link"]}.')
        target = os.path.join(addons_dir, Path(map['name']).stem + '.7z')

        with session.get(map['download_link'], stream=True, timeout=10) as r:
            r.raise_for_status()

            with open(target, 'wb') as f:
                for chunk in r.iter_content(chunk_size=1024 * 1024):
                    if chunk:
                        f.write(chunk)

        with py7zr.SevenZipFile(target, 'r') as z:
            z.extractall(addons_dir)

        os.remove(target)

        updated += 1

    logger.info(f'Updated {updated} maps.')


def file_checksum(path: str):
    with open(path, 'rb') as f:
        return hashlib.md5(f.read()).hexdigest()
