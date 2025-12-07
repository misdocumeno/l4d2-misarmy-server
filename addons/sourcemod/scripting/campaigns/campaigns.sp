#include <sourcemod>
#include <campaigns>

#pragma newdecls required
#pragma semicolon 0

#include "keyvalues.sp"
#include "natives.sp"

#include "test.sp"
#include "levenshtein.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    RegPluginLibrary("campaigns")

    CreateNative("GetCurrentCampaign", Native_GetCurrentCampaign)
    CreateNative("GetCampaignOfChapter", Native_GetCampaignOfChapter)
    CreateNative("GetCampaignChapters", Native_GetCampaignChapters)
    CreateNative("GetNextChapterOf", Native_GetNextChapterOf)
    CreateNative("GetPreviousChapterOf", Native_GetPreviousChapterOf)
    CreateNative("GetNextCampaignOf", Native_GetNextCampaignOf)
    CreateNative("GetPreviousCampaignOf", Native_GetPreviousCampaignOf)
    CreateNative("IsOfficialCampaign", Native_IsOfficialCampaign)
    CreateNative("IsOfficialChapter", Native_IsOfficialChapter)
    CreateNative("IsValidCampaign", Native_IsValidCampaign)
    CreateNative("IsValidChapter", Native_IsValidChapter)

    return APLRes_Success
}

public void OnPluginStart() {
    LoadCampaigns()

    RegServerCmd("sm_campaigns", OnCampaignsCmd, "Shows a list of campaigns and chapters")

    RegServerCmd("sm_getcurrentcampaign", OnGetCurrentCampaignCmd)
    RegServerCmd("sm_getcampaignofchapter", OnGetCampaignOfChapterCmd)
    RegServerCmd("sm_getcampaignchapters", OnGetCampaignChaptersCmd)
    RegServerCmd("sm_getnextchapterof", OnGetNextChapterOfCmd)
    RegServerCmd("sm_getpreviouschapterof", OnGetPreviousChapterOfCmd)
    RegServerCmd("sm_getnextcampaignof", OnGetNextCampaignOfCmd)
    RegServerCmd("sm_getpreviouscampaignof", OnGetPreviousCampaignOfCmd)
    RegServerCmd("sm_isofficialcampaign", OnIsOfficialCampaignCmd)
    RegServerCmd("sm_isofficialchapter", OnIsOfficialChapterCmd)
    RegServerCmd("sm_isvalidcampaign", OnIsValidCampaignCmd)
    RegServerCmd("sm_isvalidchapter", OnIsValidChapterCmd)

    // RunTests()
}

public Action OnCampaignsCmd(int args) {
    PrintCampaigns()
    return Plugin_Handled
}

void RunTests() {
    PrintToServer("=== Levenshtein Tests ===")

    RunLevenshteinDistanceTest("kitten", "sitting", 3)
    RunLevenshteinDistanceTest("book", "back", 2)
    RunLevenshteinDistanceTest("flaw", "lawn", 2)
    RunLevenshteinDistanceTest("gumbo", "gambol", 2)
    RunLevenshteinDistanceTest("a", "a", 0)
    RunLevenshteinDistanceTest("a", "b", 1)
    RunLevenshteinDistanceTest("", "abc", 3)
    RunLevenshteinDistanceTest("abc", "", 3)
    RunLevenshteinDistanceTest("command", "commnad", 2)
    RunLevenshteinDistanceTest("hello", "helo", 1)
    RunLevenshteinDistanceTest("abc", "abc", 0)

    PrintToServer("=== Tests Finished ===")
}
