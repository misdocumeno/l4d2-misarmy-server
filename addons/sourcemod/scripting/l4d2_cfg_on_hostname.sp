#include <sourcemod>
#include <regex>
#include <confogl>

// TODO: general bug: the l4d_readyup_cfg_name cvar isn't being properly set sometimes, idk why, debug that

#pragma newdecls required

ConVar g_cvarHostname
char g_sHostname[1024]

public void OnPluginStart() {
    g_sHostname = GetHostname()

    g_cvarHostname = FindConVar("hostname")
    HookConVarChange(g_cvarHostname, OnHostnameChanged)

    CreateTimer(1.0, TimerSetHostname, _, TIMER_REPEAT)

    // to show the real hostname on the readyup panel
    ConVar readyUpHostname = CreateConVar("sn_main_name", "")
    readyUpHostname.SetString(g_sHostname)
}

void OnHostnameChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    PersistCfgOnHostname()
}

// dumb but reliable way of persisting the cfg name in the hostname,
// since executing configs can change the hostname and whatnot
Action TimerSetHostname(Handle timer) {
    PersistCfgOnHostname()
    return Plugin_Continue
}

// we are in 2025, don't be afraid of messing with a bunch of strings, please
void PersistCfgOnHostname() {
    char currentHostname[1024], properHostname[1024]
    g_cvarHostname.GetString(currentHostname, sizeof(currentHostname))
    properHostname = g_sHostname
    ConVar cfgNameCvar = FindConVar("l4d_ready_cfg_name")

    if (cfgNameCvar != null && LGO_IsMatchModeLoaded()) {
        char cfgName[1024]
        cfgNameCvar.GetString(cfgName, sizeof(cfgName))
        Format(properHostname, sizeof(properHostname), "%s | %s", g_sHostname, cfgName)
    }

    if (!StrEqual(currentHostname, properHostname)) {
        PrintToServer("[l4d2_cfg_on_hostname] changing hostname to: %s", properHostname)
        g_cvarHostname.SetString(properHostname)
    }
}

public void OnPluginEnd() {
    g_cvarHostname.SetString(g_sHostname)
}

char[] GetHostname() {
    Regex hostnameRegex = new Regex("^\\s*hostname\\s+\"(.*?)\"")
    File serverCfg = OpenFile("cfg/server.cfg", "r")
    char line[1024], hostname[1024] = "Left 4 Dead 2"

    while (serverCfg.ReadLine(line, sizeof(line))) {
        if (StrContains(line, "hostname") != -1 && hostnameRegex.Match(line)) {
            hostnameRegex.GetSubString(1, hostname, sizeof(hostname))
            break
        }
    }

    serverCfg.Close()
    return hostname
}