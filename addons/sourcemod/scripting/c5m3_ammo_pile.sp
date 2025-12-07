#include <sourcemod>
#include <sdktools>


public void OnPluginStart() {
    // doing it on map start, round start, first put in server, etc, sometimes doesn't work
    // I guess because of stripper? idk, but this works, whatever
    HookEvent("player_left_start_area", OnPlayerLeftStartAreaEvent, EventHookMode_PostNoCopy)
}

public void OnPlayerLeftStartAreaEvent(Event event, const char[] name, bool dontBroadcast) {
    char map[64]
    GetCurrentMap(map, sizeof map)
    if (StrEqual(map, "c5m3_cemetery")) {
        int pile = CreateEntityByName("weapon_ammo_spawn")
        SetEntityModel(pile, "models/props/terror/ammo_stack.mdl")
        TeleportEntity(pile, {1964.0, 935.0, 32.5})
        DispatchSpawn(pile)
    }
}
