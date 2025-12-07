import os
import vpk
import vdf
import json
from runner.logger import logger


with open('runner/server/update/maps/official_maps.json', 'r') as f:
    official_maps = json.load(f)


def generate_campaigns_kv():
    addons_dir = os.path.join(os.getcwd(), 'server', 'left4dead2', 'addons')
    addons = [addon for addon in os.listdir(addons_dir) if addon.endswith('.vpk')]
    mission_files: list[str] = []

    for addon in addons:
        try:
            with vpk.open(os.path.join(addons_dir, addon)) as vpk_file:
                mission = [f for f in vpk_file if f.startswith('missions/') and f.endswith('.txt')][0]
                mission_files.append(vpk_file[mission].read().decode())
        except:
            logger.error(f'Error extracting levels from {addon}. skipping...')

    custom_campaigns: list[dict] = []

    for mission in mission_files:
        kv = vdf.loads(mission)
        chapters: list[str] = []
        for map in kv['mission']['modes']['versus'].values():
            chapters.append(map.get('Map') or map.get('map'))
        custom_campaigns.append({'campaign': kv['mission']['DisplayTitle'], 'chapters': chapters})

    official = [campaign['campaign'] for campaign in official_maps]

    kv_data = {
        'Campaigns': {
            str(i): {
                'Campaign': entry['campaign'],
                'Chapters': {str(j): chapter for j, chapter in enumerate(entry['chapters'])},
                'Official': int(entry['campaign'] in official),
            }
            for i, entry in enumerate([*official_maps, *custom_campaigns])
        }
    }

    campaigns_file = os.path.join(addons_dir, 'sourcemod', 'configs', 'campaigns.cfg')
    os.makedirs(os.path.dirname(campaigns_file), exist_ok=True)

    with open(campaigns_file, 'w') as f:
        f.write(vdf.dumps(kv_data, pretty=True))
