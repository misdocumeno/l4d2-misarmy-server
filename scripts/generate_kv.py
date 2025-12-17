import os
import vpk
import vdf

official_maps = [
    {"campaign": "Dead Center", "chapters": ["c1m1_hotel", "c1m2_streets", "c1m3_mall", "c1m4_atrium"]},
    {
        "campaign": "Dark Carnival",
        "chapters": ["c2m1_highway", "c2m2_fairgrounds", "c2m3_coaster", "c2m4_barns", "c2m5_concert"],
    },
    {"campaign": "Swamp Fever", "chapters": ["c3m1_plankcountry", "c3m2_swamp", "c3m3_shantytown", "c3m4_plantation"]},
    {
        "campaign": "Hard Rain",
        "chapters": [
            "c4m1_milltown_a",
            "c4m2_sugarmill_a",
            "c4m3_sugarmill_b",
            "c4m4_milltown_b",
            "c4m5_milltown_escape",
        ],
    },
    {
        "campaign": "The Parish",
        "chapters": ["c5m1_waterfront", "c5m2_park", "c5m3_cemetery", "c5m4_quarter", "c5m5_bridge"],
    },
    {
        "campaign": "The Passifice",
        "chapters": ["c6m1_riverbank", "c6m2_bedlam", "c7m1_docks", "c7m2_barge", "c7m3_port"],
    },
    {
        "campaign": "Cold Stream",
        "chapters": ["c13m1_alpinecreek", "c13m2_southpinestream", "c13m3_memorialbridge", "c13m4_cutthroatcreek"],
    },
    {
        "campaign": "Death Toll",
        "chapters": ["c10m1_caves", "c10m2_drainage", "c10m3_ranchhouse", "c10m4_mainstreet", "c10m5_houseboat"],
    },
    {
        "campaign": "Dead Air",
        "chapters": ["c11m1_greenhouse", "c11m2_offices", "c11m3_garage", "c11m4_terminal", "c11m5_runway"],
    },
    {
        "campaign": "Blood Harvest",
        "chapters": ["c12m1_hilltop", "c12m2_traintunnel", "c12m3_bridge", "c12m4_barn", "c12m5_cornfield"],
    },
    {"campaign": "Crash Stand", "chapters": ["c9m1_alleys", "c9m2_lots", "c14m1_junkyard", "c14m2_lighthouse"]},
]


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
            print(f'Error extracting levels from {addon}. skipping...')

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


if __name__ == '__main__':
    generate_campaigns_kv()
