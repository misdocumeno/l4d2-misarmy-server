#include <sourcemod>
#include <left4dhooks>


// TODO: que la inmunidad al m2 dure unos segundos mas luego de tocar el piso tambien

bool canDeadStopWithWeapon[L4D2WeaponId_MAX] = {true, ...}
ConVar cvarNoDeadStopWeapons

public void OnPluginStart() {
    char noDeadStopWeaponsDefault[] = "weapon_pumpshotgun,weapon_shotgun_chrome,weapon_hunting_rifle"
    cvarNoDeadStopWeapons = CreateConVar(
            "no_jockey_deadstops_weapon",
            noDeadStopWeaponsDefault,
            "Players using these weapons won't be able to deadstop jockeys"
        )
    cvarNoDeadStopWeapons.AddChangeHook(OnDeadStopWeaponsChange)
    OnDeadStopWeaponsChange(cvarNoDeadStopWeapons, "", noDeadStopWeaponsDefault)
}

void OnDeadStopWeaponsChange(ConVar convar, const char[] oldValue, const char[] newValue) {
    char weaponsString[view_as<int>(L4D2WeaponId_MAX)][64]
    ExplodeString(newValue, ",", weaponsString, sizeof weaponsString, sizeof weaponsString[])

    for (int i = 0; i < sizeof canDeadStopWithWeapon; i++) {
        canDeadStopWithWeapon[i] = true
    }

    for (int i = 0; i < sizeof weaponsString; i++) {
        if (!strlen(weaponsString[i])) break

        L4D2WeaponId weapon = L4D2_GetWeaponIdByWeaponName(weaponsString[i])

        if (weapon == L4D2WeaponId_None) {
            ThrowError("Invalid weapon %s", weaponsString[i])
        }

        canDeadStopWithWeapon[view_as<int>(weapon)] = false
    }
}

public Action L4D_OnShovedBySurvivor(int shover, int shovee, const float vector[3]) {
    return HandleJockeyDeadStop(shover, shovee)
}

public Action L4D2_OnEntityShoved(int shover, int shovee_ent, int weapon, float vector[3], bool bIsHunterDeadstop) {
    return HandleJockeyDeadStop(shover, shovee_ent, weapon)
}

Action HandleJockeyDeadStop(int survivor, int jockey, int weapon = -1) {
    if (
        survivor < 1 ||
        survivor > MaxClients ||
        !IsClientInGame(survivor) ||
        L4D_GetClientTeam(survivor) != L4DTeam_Survivor ||
        !IsPlayerAlive(survivor)
    ) {
        return Plugin_Continue
    }

    if (
        jockey < 1 ||
        jockey > MaxClients ||
        !IsClientInGame(jockey) ||
        L4D_GetClientTeam(jockey) != L4DTeam_Infected ||
        !IsPlayerAlive(jockey) ||
        GetEntityFlags(jockey) & FL_ONGROUND
    ) {
        return Plugin_Continue
    }

    char weaponName[128]

    if (weapon != -1) {
        GetEntityClassname(weapon, weaponName, sizeof weaponName)
    } else {
        GetClientWeapon(survivor, weaponName, sizeof weaponName)
    }

    if (!canDeadStopWithWeapon[view_as<int>(L4D2_GetWeaponIdByWeaponName(weaponName))]) {
        PrintToServer("preventing deadstop!!")
        return Plugin_Handled
    }

    return Plugin_Continue
}