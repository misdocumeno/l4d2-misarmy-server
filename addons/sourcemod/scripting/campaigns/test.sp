public Action OnGetCurrentCampaignCmd(int args) {
    char campaignName[256]
    GetCurrentCampaign(campaignName, sizeof campaignName)
    PrintToServer("Current campaign: %s", campaignName)
    return Plugin_Handled
}

public Action OnGetCampaignOfChapterCmd(int args) {
    char chapterName[256]
    GetCmdArg(1, chapterName, sizeof chapterName)
    char campaignName[256]
    GetCampaignOfChapter(chapterName, campaignName, sizeof campaignName)
    PrintToServer("Campaign of chapter %s: %s", chapterName, campaignName)
    return Plugin_Handled
}

public Action OnGetCampaignChaptersCmd(int args) {
    char campaignName[256]
    GetCmdArg(1, campaignName, sizeof campaignName)
    char skipFinaleArg[16]
    GetCmdArg(2, skipFinaleArg, sizeof skipFinaleArg)
    bool skipFinale = args > 1 && StrEqual(skipFinaleArg, "true")

    ArrayList chapters = GetCampaignChapters(campaignName, skipFinale)

    if (chapters == INVALID_HANDLE) {
        PrintToServer("Invalid campaign")
        return Plugin_Handled
    }

    PrintToServer("Chapters of %s (skipFinale = %s):", campaignName, skipFinale ? "true" : "false")

    for (int i = 0; i < chapters.Length; i++) {
        char chapter[256]
        chapters.GetString(i, chapter, sizeof chapter)
        PrintToServer(" - %s", chapter)
    }

    return Plugin_Handled
}

public Action OnGetNextChapterOfCmd(int args) {
    char chapterName[256]
    GetCmdArg(1, chapterName, sizeof chapterName)
    char sameCampaignArg[16]
    GetCmdArg(2, sameCampaignArg, sizeof sameCampaignArg)
    char skipFinaleArg[16]
    GetCmdArg(3, skipFinaleArg, sizeof skipFinaleArg)
    bool sameCampaign = args < 2 || StrEqual(sameCampaignArg, "true")
    bool skipFinale = args > 2 && StrEqual(skipFinaleArg, "true")

    char nextChapterName[256]
    GetNextChapterOf(chapterName, nextChapterName, sizeof nextChapterName, sameCampaign, skipFinale)

    PrintToServer("Next chapter of %s (sameCampaign = %s, skipFinale = %s): %s",
        chapterName, sameCampaign ? "true" : "false", skipFinale ? "true" : "false", nextChapterName)
    return Plugin_Handled
}

public Action OnGetPreviousChapterOfCmd(int args) {
    char chapterName[256]
    GetCmdArg(1, chapterName, sizeof chapterName)
    char sameCampaignArg[16]
    GetCmdArg(2, sameCampaignArg, sizeof sameCampaignArg)
    char skipFinaleArg[16]
    GetCmdArg(3, skipFinaleArg, sizeof skipFinaleArg)
    bool sameCampaign = args < 2 || StrEqual(sameCampaignArg, "true")
    bool skipFinale = args > 2 && StrEqual(skipFinaleArg, "true")

    char prevChapterName[256]
    GetPreviousChapterOf(chapterName, prevChapterName, sizeof prevChapterName, sameCampaign, skipFinale)

    PrintToServer("Previous chapter of %s (sameCampaign = %s, skipFinale = %s): %s",
        chapterName, sameCampaign ? "true" : "false", skipFinale ? "true" : "false", prevChapterName)
    return Plugin_Handled
}

public Action OnGetNextCampaignOfCmd(int args) {
    char campaignName[256]
    GetCmdArg(1, campaignName, sizeof campaignName)
    char officialOnlyArg[16]
    GetCmdArg(2, officialOnlyArg, sizeof officialOnlyArg)
    bool officialOnly = args < 2 || StrEqual(officialOnlyArg, "true")

    char nextCampaignName[256]
    GetNextCampaignOf(campaignName, nextCampaignName, sizeof nextCampaignName, officialOnly)

    PrintToServer("Next campaign of %s (officialOnly = %s): %s",
        campaignName, officialOnly ? "true" : "false", nextCampaignName)
    return Plugin_Handled
}

public Action OnGetPreviousCampaignOfCmd(int args) {
    char campaignName[256]
    GetCmdArg(1, campaignName, sizeof campaignName)
    char officialOnlyArg[16]
    GetCmdArg(2, officialOnlyArg, sizeof officialOnlyArg)
    bool officialOnly = args < 2 || StrEqual(officialOnlyArg, "true")

    char prevCampaignName[256]
    GetPreviousCampaignOf(campaignName, prevCampaignName, sizeof prevCampaignName, officialOnly)

    PrintToServer("Previous campaign of %s (officialOnly = %s): %s",
        campaignName, officialOnly ? "true" : "false", prevCampaignName)
    return Plugin_Handled
}

public Action OnIsOfficialCampaignCmd(int args) {
    char campaignName[256]
    GetCmdArg(1, campaignName, sizeof campaignName)

    bool official = IsOfficialCampaign(campaignName)

    PrintToServer("Is %s official: %s", campaignName, official ? "true" : "false")
    return Plugin_Handled
}

public Action OnIsOfficialChapterCmd(int args) {
    char chapterName[256]
    GetCmdArg(1, chapterName, sizeof chapterName)

    bool official = IsOfficialChapter(chapterName)

    PrintToServer("Is %s official: %s", chapterName, official ? "true" : "false")
    return Plugin_Handled
}

public Action OnIsValidCampaignCmd(int args) {
    char campaignName[256]
    GetCmdArg(1, campaignName, sizeof campaignName)

    bool valid = IsValidCampaign(campaignName)

    PrintToServer("Is %s valid: %s", campaignName, valid ? "true" : "false")
    return Plugin_Handled
}

public Action OnIsValidChapterCmd(int args) {
    char chapterName[256]
    GetCmdArg(1, chapterName, sizeof chapterName)

    bool valid = IsValidChapter(chapterName)

    PrintToServer("Is %s valid: %s", chapterName, valid ? "true" : "false")
    return Plugin_Handled
}
