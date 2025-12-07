#include <sourcemod>
#include <sdktools>
#include <colors>
#include <custom_fakelag>

#pragma newdecls required

stock bool GetCmdArgFloatEx(int argnum, float &value) {
    char str[18]
    int len = GetCmdArg(argnum, str, sizeof(str))
    return StringToFloatEx(str, value) == len && len > 0
}

ConVar defaultCommonLimit
ConVar commonLimit

int commons = -1

public void OnPluginStart() {
    defaultCommonLimit = CreateConVar("gauntlet_default_common_limit", "15", "Default z_common_limit value.")

    commonLimit = FindConVar("z_common_limit")

    RegConsoleCmd("sm_commons", OnCommonsCmd)
    RegConsoleCmd("sm_fakelag", OnFakeLagCmd)
}

public void OnPluginEnd() {
    commonLimit.SetInt(defaultCommonLimit.IntValue)

    for (int i = 1; i <= MaxClients; ++i) {
        CFakeLag_SetPlayerLatency(i, 0.0)
    }
}

public void OnConfigsExecuted() {
    RequestFrame(SetConVars)
}

void SetConVars() {
    if (commons != -1) {
        commonLimit.SetInt(commons)
        LimitCommonsTo(commons)
    }
}

public Action OnCommonsCmd(int client, int args) {
    if (args < 1) {
        CPrintToChat(client, "{red}[{default}!{red}] Usage: {olive}/common <limit>")
        return Plugin_Handled
    }

    int limit

    if (!GetCmdArgIntEx(1, limit) || limit < 0) {
        CPrintToChat(client, "{red}[{default}!{red}] {default}Invalid common limit.")
        return Plugin_Handled
    }

    commons = limit
    commonLimit.SetInt(limit)
    LimitCommonsTo(limit)
    CPrintToChat(client, "{blue}[{default}!{blue}] {default}Common limit set to {olive}%d", limit)
    return Plugin_Handled
}

public Action OnFakeLagCmd(int client, int args) {
    if (args < 1) {
        CPrintToChat(client, "{red}[{default}!{red}] Usage: {olive}/fakelag <ping>")
        return Plugin_Handled
    }

    float ping

    if (!GetCmdArgFloatEx(1, ping) || ping < 0.0) {
        CPrintToChat(client, "{red}[{default}!{red}] {default}Invalid ping.")
        return Plugin_Handled
    }

    CFakeLag_SetPlayerLatency(client, ping)
    CPrintToChat(client, "{blue}[{default}!{blue}] {default}Fake ping set to {olive}%.1fms", ping)
    return Plugin_Handled
}

void LimitCommonsTo(int limit) {
    int found, common = -1;

    while((common = FindEntityByClassname(common, "infected")) != INVALID_ENT_REFERENCE) {
        found++
        if (found > limit) {
            RemoveEntity(common)
        }
    }
}