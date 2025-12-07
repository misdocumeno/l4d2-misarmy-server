#include <sourcemod>

public void OnPluginStart() {
    RegAdminCmd("sm_silent_cvar", OnSilentCvarCmd, ADMFLAG_ROOT, "sm_cvar <cvar> <value>")
}

public Action OnSilentCvarCmd(int client, int args) {
    if (args < 2) {
        ReplyToCommand(client, "[SM] Usage: sm_silent_cvar <cvar> <value>")
        return Plugin_Handled
    }

    char cvarName[64], value[255]
    GetCmdArg(1, cvarName, sizeof(cvarName))
    GetCmdArg(2, value, sizeof(value))

    ConVar cvar = FindConVar(cvarName)

    if (cvar == null) {
        ReplyToCommand(client, "[SM] Unable to find cvar: %s", cvarName)
        return Plugin_Handled
    }

    cvar.SetString(value, true)
    ReplyToCommand(client, "[SM] Changed cvar \"%s\" to \"%s\"", cvarName, value)
    return Plugin_Handled
}