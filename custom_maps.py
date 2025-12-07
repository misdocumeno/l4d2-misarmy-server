import os
import json
import py7zr
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

session = requests.Session()
retries = Retry(total=5, backoff_factor=2, status_forcelist=[500, 502, 503, 504])
session.mount('http://', HTTPAdapter(max_retries=retries))
session.mount('https://', HTTPAdapter(max_retries=retries))


maps = session.get('https://l4d2center.com/maps/servers/index.json').json()

with open('server/left4dead2/addons/maps.json', 'w') as f:
    json.dump(maps, f, indent=4)

for i, map in enumerate(maps, 1):
    name = map["name"][:-4]
    target = f'server/left4dead2/addons/{name}.7z'

    print(f'({i}/{len(maps)}) Downloading {map["name"]}...')

    with session.get(map['download_link'], stream=True, timeout=10) as r:
        r.raise_for_status()

        with open(target, 'wb') as f:
            for chunk in r.iter_content(chunk_size=1024 * 1024):
                if chunk:
                    f.write(chunk)

    with py7zr.SevenZipFile(target, 'r') as z:
        z.extractall('server/left4dead2/addons')

    os.remove(target)
