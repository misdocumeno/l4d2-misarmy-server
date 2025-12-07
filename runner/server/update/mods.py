import os
import shutil
import requests
import tarfile
from urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter


def update_mods(mm_version: str, sm_version: str):
    latest_mm = requests.get(f'https://mms.alliedmods.net/mmsdrop/{mm_version}/mmsource-latest-linux').text
    latest_sm = requests.get(f'https://sm.alliedmods.net/smdrop/{sm_version}/sourcemod-latest-linux').text

    mm_file = download_file(f'https://mms.alliedmods.net/mmsdrop/{mm_version}/{latest_mm}')
    extract_tar(mm_file, f'{os.getcwd()}/server/left4dead2/')
    os.remove(mm_file)

    sm_file = download_file(f'https://sm.alliedmods.net/smdrop/{sm_version}/{latest_sm}')
    extract_tar(sm_file, f'{os.getcwd()}/server/left4dead2/')
    os.remove(sm_file)


def download_file(url: str):
    session = requests.Session()
    retry = Retry(total=5, backoff_factor=0.5, status_forcelist=[500, 502, 503, 504], allowed_methods=['GET'])
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('http://', adapter)
    session.mount('https://', adapter)

    file = os.path.basename(url)

    with session.get(url, stream=True, timeout=10) as data:
        data.raise_for_status()
        with open(file, 'wb') as f:
            shutil.copyfileobj(data.raw, f)

    return file


def extract_tar(file: str, path: str):
    with tarfile.open(file, 'r') as tar:
        tar.extractall(path)
