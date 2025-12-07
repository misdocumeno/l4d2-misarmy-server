any Native_GetCurrentCampaign(Handle plugin, int numParams) {
    int maxLength = GetNativeCell(2)

    char current[256]
    GetCurrentMap(current, sizeof current)

    char[] campaignName = new char[maxLength]
    GetCampaignOfChapter(current, campaignName, maxLength)

    SetNativeString(1, campaignName, maxLength, false)
    return 0
}

any Native_GetCampaignOfChapter(Handle plugin, int numParams) {
    char chapterName[256]
    GetNativeString(1, chapterName, sizeof chapterName)

    int maxLength = GetNativeCell(3)

    for (int i = 0; i < campaigns.Length; i++) {
        Campaign campaign
        campaigns.GetArray(i, campaign)

        for (int j = 0; j < campaign.chapters.Length; j++) {
            char chapter[256]
            campaign.chapters.GetString(j, chapter, sizeof chapter)

            if (StrEqual(chapter, chapterName)) {
                SetNativeString(2, campaign.campaign, maxLength, false)
                return true
            }
        }
    }

    SetNativeString(2, "", maxLength, false)
    return false
}

any Native_GetCampaignChapters(Handle plugin, int numParams) {
    char campaignName[256]
    GetNativeString(1, campaignName, sizeof campaignName)
    bool skipFinale = view_as<bool>(GetNativeCell(2))

    for (int i = 0; i < campaigns.Length; i++) {
        Campaign campaign
        campaigns.GetArray(i, campaign)

        if (StrEqual(campaign.campaign, campaignName)) {
            ArrayList chapters = campaign.chapters.Clone()

            if (!skipFinale) {
                return chapters
            }

            chapters.Erase(chapters.Length - 1)
            return chapters
        }
    }

    return INVALID_HANDLE
}

any Native_GetNextChapterOf(Handle plugin, int numParams) {
    char chapterName[256]
    GetNativeString(1, chapterName, sizeof chapterName)

    int maxLength = GetNativeCell(3)
    bool sameCampaign = view_as<bool>(GetNativeCell(4))
    bool skipFinale = view_as<bool>(GetNativeCell(5))

    for (int i = 0; i < campaigns.Length; i++) {
        Campaign campaign
        campaigns.GetArray(i, campaign)

        for (int j = 0; j < campaign.chapters.Length; j++) {
            char chapter[256]
            campaign.chapters.GetString(j, chapter, sizeof chapter)

            if (!StrEqual(chapter, chapterName)) {
                continue
            }

            if (j + 1 < (skipFinale ? campaign.chapters.Length - 1 : campaign.chapters.Length)) {
                char[] nextChapter = new char[maxLength]
                campaign.chapters.GetString(j + 1, nextChapter, maxLength)
                SetNativeString(2, nextChapter, maxLength, false)
                return true
            }

            if (sameCampaign) {
                SetNativeString(2, "", maxLength, false)
                return false
            }

            Campaign nextCampaign
            campaigns.GetArray(i + 1 < campaigns.Length ? i + 1 : 0, nextCampaign)
            char[] nextChapter = new char[maxLength]
            nextCampaign.chapters.GetString(0, nextChapter, maxLength)
            SetNativeString(2, nextChapter, maxLength, false)
            return true
        }
    }

    SetNativeString(2, "", maxLength, false)
    return false
}

any Native_GetPreviousChapterOf(Handle plugin, int numParams) {
    char chapterName[256]
    GetNativeString(1, chapterName, sizeof chapterName)

    int maxLength = GetNativeCell(3)
    bool sameCampaign = view_as<bool>(GetNativeCell(4))
    bool skipFinale = view_as<bool>(GetNativeCell(5))

    for (int i = 0; i < campaigns.Length; i++) {
        Campaign campaign
        campaigns.GetArray(i, campaign)

        for (int j = 0; j < campaign.chapters.Length; j++) {
            char chapter[256]
            campaign.chapters.GetString(j, chapter, sizeof chapter)

            if (!StrEqual(chapter, chapterName)) {
                continue
            }

            if (j - 1 >= 0) {
                char[] prevChapter = new char[maxLength]
                campaign.chapters.GetString(j - 1, prevChapter, maxLength)
                SetNativeString(2, prevChapter, maxLength, false)
                return true
            }

            if (sameCampaign) {
                SetNativeString(2, "", maxLength, false)
                return false
            }

            Campaign prevCampaign
            campaigns.GetArray(i - 1 >= 0 ? i - 1 : campaigns.Length - 1, prevCampaign)
            char[] prevChapter = new char[maxLength]
            prevCampaign.chapters.GetString(prevCampaign.chapters.Length - (skipFinale ? 2 : 1), prevChapter, maxLength)
            SetNativeString(2, prevChapter, maxLength, false)
            return true
        }
    }

    SetNativeString(2, "", maxLength, false)
    return false
}

any Native_GetNextCampaignOf(Handle plugin, int numParams) {
    char campaignName[256]
    GetNativeString(1, campaignName, sizeof campaignName)

    int maxLength = GetNativeCell(3)
    bool officialOnly = view_as<bool>(GetNativeCell(4))

    for (int i = 0; i < campaigns.Length; i++) {
        Campaign campaign
        campaigns.GetArray(i, campaign)

        if (!StrEqual(campaign.campaign, campaignName)) {
            continue
        }

        for (int j = i + 1; j < campaigns.Length; j++) {
            campaigns.GetArray(j, campaign)
            if (!officialOnly || campaign.official) {
                SetNativeString(2, campaign.campaign, maxLength, false)
                return true
            }
        }

        for (int j = 0; j <= i; j++) {
            campaigns.GetArray(j, campaign)
            if (!officialOnly || campaign.official) {
                SetNativeString(2, campaign.campaign, maxLength, false)
                return true
            }
        }
    }

    SetNativeString(2, "", maxLength, false)
    return false
}

any Native_GetPreviousCampaignOf(Handle plugin, int numParams) {
    char campaignName[256]
    GetNativeString(1, campaignName, sizeof campaignName)

    int maxLength = GetNativeCell(3)
    bool officialOnly = view_as<bool>(GetNativeCell(4))

    for (int i = 0; i < campaigns.Length; i++) {
        Campaign campaign
        campaigns.GetArray(i, campaign)

        if (!StrEqual(campaign.campaign, campaignName)) {
            continue
        }

        for (int j = i - 1; j >= 0; j--) {
            campaigns.GetArray(j, campaign)
            if (!officialOnly || campaign.official) {
                SetNativeString(2, campaign.campaign, maxLength, false)
                return true
            }
        }

        for (int j = campaigns.Length - 1; j >= i; j--) {
            campaigns.GetArray(j, campaign)
            if (!officialOnly || campaign.official) {
                SetNativeString(2, campaign.campaign, maxLength, false)
                return true
            }
        }
    }

    SetNativeString(2, "", maxLength, false)
    return false
}

any Native_IsOfficialCampaign(Handle plugin, int numParams) {
    char campaignName[256]
    GetNativeString(1, campaignName, sizeof campaignName)

    for (int i = 0; i < campaigns.Length; i++) {
        Campaign campaign
        campaigns.GetArray(i, campaign)

        if (StrEqual(campaign.campaign, campaignName)) {
            return campaign.official
        }
    }

    return false
}

any Native_IsOfficialChapter(Handle plugin, int numParams) {
    char chapterName[256]
    GetNativeString(1, chapterName, sizeof chapterName)

    for (int i = 0; i < campaigns.Length; i++) {
        Campaign campaign
        campaigns.GetArray(i, campaign)

        if (!campaign.official) {
            continue
        }

        for (int j = 0; j < campaign.chapters.Length; j++) {
            char chapter[256]
            campaign.chapters.GetString(j, chapter, sizeof chapter)

            if (StrEqual(chapter, chapterName)) {
                return true
            }
        }
    }

    return false
}

any Native_IsValidCampaign(Handle plugin, int numParams) {
    char campaignName[256]
    GetNativeString(1, campaignName, sizeof campaignName)

    for (int i = 0; i < campaigns.Length; i++) {
        Campaign campaign
        campaigns.GetArray(i, campaign)

        if (StrEqual(campaign.campaign, campaignName)) {
            return true
        }
    }

    return false
}

any Native_IsValidChapter(Handle plugin, int numParams) {
    char chapterName[256]
    GetNativeString(1, chapterName, sizeof chapterName)

    for (int i = 0; i < campaigns.Length; i++) {
        Campaign campaign
        campaigns.GetArray(i, campaign)

        for (int j = 0; j < campaign.chapters.Length; j++) {
            char chapter[256]
            campaign.chapters.GetString(j, chapter, sizeof chapter)

            if (StrEqual(chapter, chapterName)) {
                return true
            }
        }
    }

    return false
}

// TODO: IsFinale
// TODO: unskipableFinales array, since there are some finales that are played (i.e.: Carried off, probably some more that don't have 5 chapters)
// FIXME: in campaigns.cfg, detour ahead has $DetourAhead_Title as the title. check if that happens in game too, and if there is a way to retrieve that value when reading the vpk file from runner
// TODO: GetNextChapterOf should have an officialOnly parameter too

// FIXME: falta no mercy en campaigns.cfg, ups. fijarse en el juego si falta alguna mas

// TODO: get campaign starting with.
// TODO: get chapter starting with.
// TODO: get campaign containing.
// TODO: get chapter containing.
// TODO: get campaign that matches regex.
// TODO: get chapter that matches regex.
// TODO: get closest campaign levenshtein distance.
// TODO: get closest chapter levenshtein distance.