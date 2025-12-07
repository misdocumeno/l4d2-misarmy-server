#include <sourcemod>
#include <left4dhooks>
#include <colors>

#define REPLY_PREFIX "[{orange}!{default}]"


public Plugin myinfo = {
	name = "Tank loss announce",
	author = "Mis",
	description = "Adds the sm_loss command to know who's visible by the tank (when they shouldn't!).",
	version = "0.1.0",
	url = "https://github.com/misdocumeno/l4d2-misarmy-server"
}


public void OnPluginStart() {
    RegConsoleCmd("sm_loss", OnLossCmd, "Check who's visible by the tank.")
}

public Action OnLossCmd(int client, int args) {
    int tank = FindTank()

    if (tank == -1) {
        CReplyToCommand(client, "%s There is no {red}tank {default}in play!", REPLY_PREFIX)
        return Plugin_Handled
    }

    float tankEyes[3]
    GetClientEyePosition(tank, tankEyes)
    ArrayList visible = new ArrayList()

    for (int i = 1; i <= MaxClients; i++) {
        if (
            IsClientInGame(i) &&
            L4D_GetClientTeam(i) == L4DTeam_Survivor &&
            IsPlayerAlive(i) &&
            L4D2_IsVisibleToPlayer(i, view_as<int>(L4DTeam_Survivor), view_as<int>(L4DTeam_Infected), 0, tankEyes)
        ) {
            visible.Push(i)
        }
    }

    if (!visible.Length) {
        CReplyToCommand(client, "%s No one is visible by the {red}tank", REPLY_PREFIX)
        delete visible
        return Plugin_Handled
    }

    char players[512]
    Format(players, sizeof players, "{blue}%N{default}", visible.Get(0))

    for (int i = 2; i < visible.Length - 1; i++) {
        Format(players, sizeof players, "%s, {blue}%N{default}", players, visible.Get(i))
    }

    if (visible.Length > 1) {
        Format(players, sizeof players, "%s and {blue}%N{default}", players, visible.Get(visible.Length - 1))
    }

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i) && L4D_GetClientTeam(i) == L4D_GetClientTeam(client)) {
            CReplyToCommand(
                i,
                "%s %s %s visible to the {orange}tank{default}!",
                REPLY_PREFIX,
                players,
                visible.Length == 1 ? "is" : "are"
            )
        }
    }

    delete visible
    return Plugin_Handled
}

int FindTank() {
    for (int i = 1; i <= MaxClients; i++) {
        if (
            IsClientInGame(i) &&
            L4D_GetClientTeam(i) == L4DTeam_Infected &&
            IsPlayerAlive(i) &&
            !L4D_IsPlayerGhost(i) &&
            L4D2_GetPlayerZombieClass(i) == L4D2ZombieClass_Tank
        ) {
            return i
        }
    }
    return -1
}