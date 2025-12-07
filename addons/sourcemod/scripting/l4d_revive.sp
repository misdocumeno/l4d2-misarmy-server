#include <sourcemod>
#include <left4dhooks>
#include <colors>

#define REPLY_PREFIX "[{orange}!{default}]"


public Plugin myinfo = {
	name = "Revive",
	author = "Mis",
	description = "Keeps track of survivors health, so they can be revived with the"
        ..."same health they had before dying (bc of trolls commiting suicide).",
	version = "0.1.0",
	url = "https://github.com/misdocumeno/l4d2-misarmy-server"
}


enum struct Health {
    int health
    float tempHealth
    int reviveCount
    bool onThirdStrike
    bool incapacitated

    void Save(int client) {
        // keep track of the health only when alive and not incapacitated
        if (!IsPlayerAlive(client) || L4D_IsPlayerIncapacitated(client)) {
            this.incapacitated = IsPlayerAlive(client)

            if (this.incapacitated) {
                this.health = 1
                this.tempHealth = 30.0
            }

            return
        }

        this.health = GetClientHealth(client)
        this.tempHealth = L4D_GetTempHealth(client)
        this.reviveCount = L4D_GetPlayerReviveCount(client)
        this.onThirdStrike = L4D_IsPlayerOnThirdStrike(client)
        this.incapacitated = false
    }

    void Reset() {
        this.health = 0
        this.tempHealth = 0.0
        this.reviveCount = 0
        this.onThirdStrike = false
        this.incapacitated = false
    }

    void ApplyToPlayer(int client) {
        SetEntityHealth(client, this.health)
        L4D_SetTempHealth(client, this.tempHealth)
        L4D_SetPlayerReviveCount(client, this.reviveCount)
        L4D_SetPlayerThirdStrikeState(client, this.onThirdStrike)
    }
}

Health lastHealth[MAXPLAYERS+1]
float survivorDeathLocation[MAXPLAYERS+1][3]


public void OnPluginStart() {
    LoadTranslations("common.phrases")
    RegAdminCmd("sm_revive", OnReviveCmd, ADMFLAG_SLAY, "Revive a player.")
    RegAdminCmd("sm_sethealth", OnSetHealthCmd, ADMFLAG_SLAY, "Set a player's health.")
    RegAdminCmd("sm_settemphealth", OnSetTempHealthCmd, ADMFLAG_SLAY, "Set a player's temporary health.")
    HookEvent("player_death", OnPlayerDeathEvent, EventHookMode_Pre)
}

public void OnGameFrame() {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && L4D_GetClientTeam(i) == L4DTeam_Survivor) {
            lastHealth[i].Save(i)
        } else {
            lastHealth[i].Reset()
        }
    }
}

public void OnPlayerDeathEvent(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"))
    if (0 < client <= MaxClients && IsClientInGame(client) && L4D_GetClientTeam(client) == L4DTeam_Survivor) {
        GetClientAbsOrigin(client, survivorDeathLocation[client])
    }
}

public Action OnReviveCmd(int client, int args) {
    int target = ValidateSurvivorTarget(client, args, "/revive <player>")

    if (target == -1) {
        return Plugin_Handled
    }

    if (IsPlayerAlive(target)) {
        CReplyToCommand(client, "%s {blue}%N {default}is not dead!", REPLY_PREFIX, target)
        return Plugin_Handled
    }

    RevivePlayer(target)
    CReplyToCommand(client, "%s {blue}%N {default}was revived!", REPLY_PREFIX, target)
    return Plugin_Handled
}

public Action OnSetHealthCmd(int client, int args) {
    int target = ValidateSurvivorTarget(client, args, "/sethealth <player> <health>")

    if (target == -1) {
        return Plugin_Handled
    }

    if (!IsPlayerAlive(target)) {
        CReplyToCommand(client, "%s {blue}%N {default}is dead!", REPLY_PREFIX, target)
        return Plugin_Handled
    }

    int newHealth

    if (!GetCmdArgIntEx(2, newHealth)) {
        CReplyToCommand(client, "%s {olive}health {default}must be an integer!", REPLY_PREFIX)
        return Plugin_Handled
    }

    lastHealth[client].health = newHealth
    lastHealth[client].reviveCount = 0
    lastHealth[client].onThirdStrike = false
    lastHealth[client].ApplyToPlayer(target)
    CReplyToCommand(client, "%s {blue}%N{default}'s health changed", REPLY_PREFIX, target)
    return Plugin_Handled
}

public Action OnSetTempHealthCmd(int client, int args) {
    int target = ValidateSurvivorTarget(client, args, "/settemphealth <player> <health>")

    if (target == -1) {
        return Plugin_Handled
    }

    if (!IsPlayerAlive(target)) {
        CReplyToCommand(client, "%s {blue}%N {default}is dead!", REPLY_PREFIX, target)
        return Plugin_Handled
    }

    float newTempHealth

    if (!GetCmdArgFloatEx(2, newTempHealth)) {
        CReplyToCommand(client, "%s {olive}health {default}must be a float!", REPLY_PREFIX)
        return Plugin_Handled
    }

    lastHealth[client].tempHealth = newTempHealth
    lastHealth[client].ApplyToPlayer(target)
    CReplyToCommand(client, "%s {blue}%N{default}'s temp health changed", REPLY_PREFIX, target)
    return Plugin_Handled
}

int ValidateSurvivorTarget(int client, int args, const char[] usage) {
    if (args < 1) {
        CReplyToCommand(client, "%s {default}Usage: {olive}%s", REPLY_PREFIX, usage)
        return -1
    }

    char arg[MAX_NAME_LENGTH]
    GetCmdArg(1, arg, sizeof arg)
    int target = FindTarget(client, arg, false, false)

    if (target == -1) {
        CReplyToCommand(client, "%s {olive}%s {default}not found", REPLY_PREFIX, arg)
        return -1
    }

    if (L4D_GetClientTeam(target) != L4DTeam_Survivor) {
        CReplyToCommand(client, "%s {red}%N {default}is not a survivor!", REPLY_PREFIX, target)
        return -1
    }

    return target
}

stock bool GetCmdArgFloatEx(int argnum, float &value) {
    char str[18]
    int len = GetCmdArg(argnum, str, sizeof(str))
    return StringToFloatEx(str, value) == len && len > 0
}

void RevivePlayer(int client) {
    L4D_RespawnPlayer(client)
    lastHealth[client].ApplyToPlayer(client)
    int nearestSurvivor = GetNearestSurvivor(survivorDeathLocation[client])
    if (nearestSurvivor) {
        float origin[3]
        GetClientAbsOrigin(nearestSurvivor, origin)
        TeleportEntity(client, origin)
    }
}

stock int GetNearestSurvivor(const float vec[3]) {
    int nearestSurvivor
    float nearestDistance

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && L4D_GetClientTeam(i) == L4DTeam_Survivor && IsPlayerAlive(i)) {
            float origin[3]
            GetClientAbsOrigin(i, origin)
            float distance = GetVectorDistance(vec, origin)

            if (!nearestSurvivor || distance < nearestDistance) {
                nearestSurvivor = i
                nearestDistance = distance
            }
        }
    }

    return nearestSurvivor
}