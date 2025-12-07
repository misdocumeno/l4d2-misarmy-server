enum struct Campaign {
    char campaign[256]
    ArrayList chapters
    bool official
}

ArrayList campaigns

void LoadCampaigns() {
    campaigns = new ArrayList(sizeof Campaign)
    KeyValues kv = new KeyValues("Campaigns")

    if (!kv.ImportFromFile("addons/sourcemod/configs/campaigns.cfg")) {
        SetFailState("Failed to load campaigns.cfg")
    }

    if (!kv.GotoFirstSubKey()) {
        SetFailState("No campaigns found")
    }

    do {
        char campaignName[256]
        kv.GetString("Campaign", campaignName, sizeof campaignName)

        bool official = view_as<bool>(kv.GetNum("Official", 0))

        if (!kv.JumpToKey("Chapters")) {
            SetFailState("Campaign %s has no chapters", campaignName)
        }

        if (!kv.GotoFirstSubKey(false)) {
            kv.GoBack()
            continue
        }

        char chapter[256]
        ArrayList chapters = new ArrayList(ByteCountToCells(sizeof chapter))

        do {
            kv.GetString(NULL_STRING, chapter, sizeof(chapter))
            chapters.PushString(chapter)
        } while (kv.GotoNextKey(false))

        Campaign campaign
        strcopy(campaign.campaign, sizeof campaign.campaign, campaignName)
        campaign.chapters = chapters
        campaign.official = official
        campaigns.PushArray(campaign)

        kv.GoBack()
        kv.GoBack()
    } while (kv.GotoNextKey())

    delete kv
}

void PrintCampaigns() {
    for (int i = 0; i < campaigns.Length; i++) {
        Campaign campaign
        campaigns.GetArray(i, campaign)
        PrintToServer("Campaign %d: %s (official: %s)", i, campaign.campaign, campaign.official ? "true" : "false")
        for (int j = 0; j < campaign.chapters.Length; j++) {
            char chapter[256]
            campaign.chapters.GetString(j, chapter, sizeof chapter)
            PrintToServer(" - Chapter %d: %s", j, chapter)
        }
    }
}