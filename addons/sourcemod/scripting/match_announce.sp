#include <sourcemod>
#include <left4dhooks>
#include <confogl>
#include <colors>


int lastMessageTick[MAXPLAYERS + 1]


public Action L4D_OnFirstSurvivorLeftSafeArea(int client) {
    if (LGO_IsMatchModeLoaded()) {
        return Plugin_Continue
    }

    int commandFlags = GetCommandFlags("warp_to_start_area")
    SetCommandFlags("warp_to_start_area", commandFlags & ~FCVAR_CHEAT)
    FakeClientCommand(client, "warp_to_start_area")
    SetCommandFlags("warp_to_start_area", commandFlags)

    // without this, the message is spammed, for some reason
    if (lastMessageTick[client] < GetGameTickCount() - 5) {
        lastMessageTick[client] = GetGameTickCount()
        CPrintToChat(client, "{blue}[{orange}!{blue}] {default}Use {olive}!match {default}to load a config!")
    }

    return Plugin_Handled
}