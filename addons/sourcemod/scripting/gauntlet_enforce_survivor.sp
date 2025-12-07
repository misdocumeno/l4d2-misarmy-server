#include <sourcemod>
#include <left4dhooks>

#pragma newdecls required

public void OnPluginStart() {
    HookEvent("player_team", OnPlayerTeamEvent)
}

public void OnPlayerTeamEvent(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"))

    if (IsFakeClient(client)) return

    L4DTeam team = view_as<L4DTeam>(event.GetInt("team"))
    L4DTeam oldTeam = view_as<L4DTeam>(event.GetInt("oldteam"))

    if (oldTeam == L4DTeam_Unassigned && team == L4DTeam_Infected) {
        PrintToServer("forcing %N from infected to survivor team", client)
        CreateTimer(0.1, MoveOutOfInfected, client)
    }
}

Action MoveOutOfInfected(Handle timer, int client) {
    int bot = GetSurvivorBot()

    if (!bot) {
        ChangeClientTeam(client, view_as<int>(L4DTeam_Spectator))
        return Plugin_Handled
    }

    ChangeClientTeam(client, view_as<int>(L4DTeam_Unassigned))
    L4D_SetHumanSpec(bot, client)
    L4D_TakeOverBot(client)

    return Plugin_Handled
}

int GetSurvivorBot() {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2) {
            return i
        }
    }
    return 0
}