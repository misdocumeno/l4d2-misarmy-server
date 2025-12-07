#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <readyup>
#include <sourcemod>
#include <left4dhooks>
#include <sdktools>

#define TEAM_SPECTATOR          1
#define TEAM_INFECTED           3
#define ZOMBIECLASS_TANK        8
#define IS_SPECTATOR(%1)        (GetClientTeam(%1) == TEAM_SPECTATOR)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == TEAM_INFECTED)
#define IS_VALID_INFECTED(%1)   (IsClientInGame(%1) && IS_INFECTED(%1))
#define IS_VALID_SPECTATOR(%1)  (IsClientInGame(%1) && IS_SPECTATOR(%1))

ArrayList h_whosHadTank;
ArrayList h_tankQueue;

ConVar
    hTankPrint,
    hTankWindow,
    hPassMenu,
    hMaxPasses,
    hTankDebug;

GlobalForward
    hForwardOnTryOfferingTankBot,
    hForwardOnTankSelection;

char
    queuedTankSteamId[64],
    tankInitiallyChosen[64],
    pendingFromCommand[64];

float
    fTankGrace,
    initialTankLeft,
    gotTankAt;

int dcedTankFrustration = -1;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("GetTankSelection", Native_GetTankSelection);

    hForwardOnTryOfferingTankBot = new GlobalForward("TankControl_OnTryOfferingTankBot", ET_Ignore, Param_String);
    hForwardOnTankSelection = new GlobalForward("TankControl_OnTankSelection", ET_Ignore, Param_String);

    return APLRes_Success;
}

int Native_GetTankSelection(Handle plugin, int numParams) { return getInfectedPlayerBySteamId(queuedTankSteamId); }

public Plugin myinfo =
{
    name = "L4D2 Tank Control",
    author = "arti, (Contributions by: Sheo, Sir, Altair-Sossai, Mis)",
    description = "Distributes the role of the tank evenly throughout the team, allows for overrides. (Includes forwards)",
    version = "0.0.25",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{

    LoadTranslation("l4d_tank_control_eq.phrases");
    LoadTranslations("common.phrases");

    // Event hooks
    HookEvent("player_left_start_area", PlayerLeftStartArea_Event, EventHookMode_PostNoCopy);
    HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
    HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("player_team", PlayerTeam_Event, EventHookMode_Post);
    HookEvent("tank_killed", TankKilled_Event, EventHookMode_PostNoCopy);
    HookEvent("player_death", PlayerDeath_Event, EventHookMode_Post);

    // Initialise the tank arrays/data values
    h_whosHadTank = new ArrayList(ByteCountToCells(64));
    h_tankQueue = new ArrayList(ByteCountToCells(64));

    // Admin commands
    RegAdminCmd("sm_tankshuffle", TankShuffle_Cmd, ADMFLAG_SLAY, "Re-picks at random someone to become tank.");
    RegAdminCmd("sm_givetank", GiveTank_Cmd, ADMFLAG_SLAY, "Gives the tank to a selected player");
    RegAdminCmd("sm_taketank", TakeTank_Cmd, ADMFLAG_SLAY, "Takes the tank");

    // Register the boss commands
    RegConsoleCmd("sm_tank", Tank_Cmd, "Shows who is becoming the tank.");
    RegConsoleCmd("sm_boss", Tank_Cmd, "Shows who is becoming the tank.");
    RegConsoleCmd("sm_witch", Tank_Cmd, "Shows who is becoming the tank.");
    RegConsoleCmd("sm_pass", Pass_Cmd, "Pass the tank.");
    RegConsoleCmd("sm_passtank", Pass_Cmd, "Pass the tank.");
    RegConsoleCmd("sm_tankpass", Pass_Cmd, "Pass the tank.");

    // Cvars
    hTankPrint  = CreateConVar("tankcontrol_print_all", "0", "Who gets to see who will become the tank? (0 = Infected, 1 = Everyone)");
    hTankWindow = CreateConVar("tankcontrol_force_window", "0.0", "Give player that was initially going to be Tank (or was Tank and dced) back the Tank this long after Tank was given to somebody else (0 = Off)");
    hPassMenu   = CreateConVar("tankcontrol_pass_menu", "0", "Show a menu to the tank to pass control to someone else?");
    hMaxPasses  = CreateConVar("tankcontrol_max_menu_passes", "1", "How many times should the players be able to pass the tank using the menu?");
    hTankDebug  = CreateConVar("tankcontrol_debug", "0", "Whether or not to debug to console");
}


/*=========================================================================
|                            Left4Dhooks                                  |
=========================================================================*/

int g_iMenuPasses;

public void L4D2_OnTankPassControl(int iOldTank, int iNewTank, int iPassCount)
{
    /*
    * As the Player switches to AI on disconnect/team switch, we have to make sure we're only checking this if the old Tank was AI.
    * Then apply the previous' Tank's Frustration and Grace Period (if it still had Grace)
    * We'll also be keeping the same Tank pass, which resolves Tanks that dc on 1st pass resulting into the Tank instantly going to 2nd pass.
    */
    if (dcedTankFrustration != -1 && IsFakeClient(iOldTank))
    {
        SetTankFrustration(iNewTank, dcedTankFrustration);
        CTimer_Start(GetFrustrationTimer(iNewTank), fTankGrace);
        L4D2Direct_SetTankPassedCount(L4D2Direct_GetTankPassedCount() - 1);
    } else if (!IsFakeClient(iOldTank) && !IsFakeClient(iNewTank)) {
        L4D2Direct_SetTankPassedCount(1);
        // for some reason, the passed count is incremented to 2 immediately after this sometimes,
        // so we set it back to 1 after half a second. unless the tank frustration lasts just
        // half a second, this should be fine.
        CreateTimer(0.5, SetTankPassedCountTimer);
    }

    gotTankAt = GetGameTime();
    if (hTankDebug.BoolValue)
        PrintToConsoleAll("[TC] gotTankAt set to %f (iOldTank: %N - iNewTank: %N)", GetGameTime(), iOldTank, iNewTank);

    if (IsFakeClient(iNewTank) || !hPassMenu.BoolValue) {
        return;
    }

    if (g_iMenuPasses < hMaxPasses.IntValue) {
        PrintToServer("showing tank pass menu bc %d is less than %d", g_iMenuPasses, hMaxPasses.IntValue);
        ShowTankPassMenu(iNewTank);
    }
}

Action SetTankPassedCountTimer(Handle timer) {
    L4D2Direct_SetTankPassedCount(1);
    return Plugin_Handled;
}

void ShowTankPassMenu(int client) {
    Menu menu = new Menu(PassTankMenuHandler);
    menu.SetTitle("Pass the tank?");

    for (int i = 1; i <= MaxClients; i++) {
        if (i != client && IsClientInGame(i) && !IsFakeClient(i) && L4D_GetClientTeam(i) == L4DTeam_Infected) {
            char userId[8], name[MAX_NAME_LENGTH];
            IntToString(GetClientUserId(i), userId, sizeof userId);
            GetClientName(i, name, sizeof name);
            menu.AddItem(userId, name);
        }
    }

    if (!menu.ItemCount) {
        return;
    }

    FakeClientCommand(client, "sm_tankhud");
    menu.Display(client, 20);
}

public int PassTankMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        char userId[8];
        menu.GetItem(param2, userId, sizeof userId);
        int passTo = GetClientOfUserId(StringToInt(userId));

        if (
            passTo &&
            L4D_GetClientTeam(param1) == L4DTeam_Infected &&
            IsPlayerAlive(param1) &&
            !L4D_IsPlayerGhost(param1) &&
            L4D2_GetPlayerZombieClass(param1) == L4D2ZombieClass_Tank &&
            g_iMenuPasses < hMaxPasses.IntValue
        ) {
            PrintToServer("passing tank bc %d is less than %d", g_iMenuPasses, hMaxPasses.IntValue);
            PassTank(param1, passTo);
            g_iMenuPasses++;
        }
    } else if (action == MenuAction_End) {
        delete menu;
    }

    if (param1 > 0) {
        FakeClientCommand(param1, "sm_tankhud");
    }

    return 0;
}

bool g_bManuallyPassingTank;

/**
 * Make sure we give the tank to our queued player.
 */
public Action L4D_OnTryOfferingTankBot(int tank_index, bool &enterStatis)
{
    // Reset the tank's frustration if need be
    if (!IsFakeClient(tank_index) && !g_bManuallyPassingTank)
    {
        PrintHintText(tank_index, "%t", "HintText");
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IS_VALID_INFECTED(i) && !IS_VALID_SPECTATOR(i))
                continue;

            if (tank_index == i)
                CPrintToChat(i, "%t %t", "TagRage", "RefilledBot");
            else
                CPrintToChat(i, "%t %t", "TagRage", "Refilled", tank_index);
        }

        SetTankFrustration(tank_index, 100);
        L4D2Direct_SetTankPassedCount(L4D2Direct_GetTankPassedCount() + 1);

        return Plugin_Handled;
    }

    g_bManuallyPassingTank = false;

    // Allow third party plugins to override tank selection
    char sOverrideTank[64];
    sOverrideTank[0] = '\0';
    Call_StartForward(hForwardOnTryOfferingTankBot);
    Call_PushStringEx(sOverrideTank, sizeof(sOverrideTank), SM_PARAM_STRING_UTF8, SM_PARAM_COPYBACK);
    Call_Finish();

    if (!StrEqual(sOverrideTank, ""))
        strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), sOverrideTank);

    // If we don't have a queued tank, choose one
    if (StrEqual(queuedTankSteamId, ""))
        chooseTank(0);

    // Mark the player as having had tank
    if (!StrEqual(queuedTankSteamId, ""))
    {
        setTankTickets(queuedTankSteamId, 20000);

        if (h_whosHadTank.FindString(queuedTankSteamId) == -1)
            h_whosHadTank.PushString(queuedTankSteamId);

        int index = h_tankQueue.FindString(queuedTankSteamId);
        if (index != -1)
            h_tankQueue.Erase(index);
    }

    return Plugin_Continue;
}


/*=========================================================================
|                                 Events                                  |
=========================================================================*/


/**
 * When a new game starts, reset the tank pool.
 */
void RoundStart_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    CreateTimer(10.0, newGame);
    dcedTankFrustration = -1;
    tankInitiallyChosen = "";
    pendingFromCommand = "";
    g_bManuallyPassingTank = false;
    g_iMenuPasses = 0;
}

Action newGame(Handle timer)
{
    int teamAScore = L4D2Direct_GetVSCampaignScore(0);
    int teamBScore = L4D2Direct_GetVSCampaignScore(1);

    // If it's a new game, reset the tank pool
    if (teamAScore == 0 && teamBScore == 0)
    {
        h_whosHadTank.Clear();
        h_tankQueue.Clear();
        queuedTankSteamId = "";
        tankInitiallyChosen = "";
    }

    return Plugin_Stop;
}

/**
 * When the round ends, reset the active tank.
 */
void RoundEnd_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    queuedTankSteamId = "";
    tankInitiallyChosen = "";
}

/**
 * When a player leaves the start area, choose a tank and output to all.
 */
void PlayerLeftStartArea_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    tankInitiallyChosen = "";
    chooseTank(0);

    if (strlen(pendingFromCommand)) {
        strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), pendingFromCommand);
        pendingFromCommand = "";
    }

    outputTankToAll(0);
}

/**
 * When the queued tank switches teams, choose a new one
 */
void PlayerTeam_Event(Event hEvent, const char[] name, bool dontBroadcast)
{
    int team = hEvent.GetInt("team");
    int oldTeam = hEvent.GetInt("oldteam");
    int client = GetClientOfUserId(hEvent.GetInt("userid"));
    char tmpSteamId[64];

    if (client < 1 || client > MaxClients)
        return;

    if (oldTeam == TEAM_INFECTED)
    {
        /*
        * Triggers for disconnects as well as forced-swaps and whatnot.
        * Allows us to always reliably detect when the current Tank player loses control due to unnatural reasons.
        */
        if (!IsFakeClient(client))
        {
            int zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
            if (zombieClass == ZOMBIECLASS_TANK)
            {
                dcedTankFrustration = GetTankFrustration(client);
                fTankGrace = CTimer_GetRemainingTime(GetFrustrationTimer(client));

                // Slight fix due to the timer seemingly always getting stuck between 0.5s~1.2s even after Grace period has passed.
                // CTimer_IsElapsed still returns false as well.
                if (fTankGrace < 0.0 || dcedTankFrustration < 100)
                    fTankGrace = 0.0;
            }
        }

        GetClientAuthId(client, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId));

        if (StrEqual(tankInitiallyChosen, tmpSteamId))
            initialTankLeft = GetGameTime();

        if (StrEqual(queuedTankSteamId, tmpSteamId))
        {
            RequestFrame(chooseTank, 0);
            RequestFrame(outputTankToAll, 0);
        }
    }

    if (team == TEAM_INFECTED && !IsFakeClient(client) && !StrEqual(tankInitiallyChosen, ""))
    {
        GetClientAuthId(client, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId));
        if (StrEqual(tankInitiallyChosen, tmpSteamId))
        {
            /* Not touching multiple tanks with a ten-foot pole.
            Could technically be done though.. TODO? */
            int tank = getTankPlayer();

            if (hTankDebug.BoolValue)
                PrintToConsoleAll("[TC] Tank: %N - L4D2_GetTankCount: %i - initialTankLeft: %f - gotTankAt: %f", tank, L4D2_GetTankCount(), initialTankLeft, gotTankAt);

            float window = hTankWindow.FloatValue;
            if (window > 0.0 && L4D2_GetTankCount() == 1 && tank != -1 && (gotTankAt - initialTankLeft) < window)
            {
                // Delay by a frame as player needs to "settle in"
                RequestFrame(ReplaceTank, client);
            }
            else
            {
                strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), tankInitiallyChosen);
                RequestFrame(outputTankToAll, 0);
            }
        }
    }
}

/**
 * Replaces the current tank with the initially chosen Tank.
 * And requeues the old Tank.
 *
 * @param deservingTank
 *      The player to give the Tank to.
 */
void ReplaceTank(int deservingTank)
{
    int oldTank = getTankPlayer();

    if (oldTank != -1 && IS_INFECTED(deservingTank))
    {
        if (hTankDebug.BoolValue)
            PrintToConsoleAll("[TC] Tank: %N being replaced by %N", oldTank, deservingTank);

        L4D_ReplaceTank(oldTank, deservingTank);

        char steamId[64];

        // Requeue the old tank
        GetClientAuthId(oldTank, AuthId_Steam2, steamId, sizeof(steamId));
        if (h_tankQueue.FindString(steamId) == -1)
        {
            h_tankQueue.ShiftUp(0);
            h_tankQueue.SetString(0, steamId);
        }

        int index = h_whosHadTank.FindString(steamId);
        if (index != -1)
            h_whosHadTank.Erase(index);

        // Remove the deserving tank from the queue if they're in it
        GetClientAuthId(deservingTank, AuthId_Steam2, steamId, sizeof(steamId));
        index = h_tankQueue.FindString(steamId);
        if (index != -1)
            h_tankQueue.Erase(index);

        index = h_whosHadTank.FindString(steamId);
        if (index == -1)
            h_whosHadTank.PushString(steamId);
    }
    else if (hTankDebug.BoolValue)
        PrintToConsoleAll("[TC] oldTank: %i and deservingTank: is%s valid", oldTank, IS_INFECTED(deservingTank) ? "" : " NOT");
}

/**
 * When the tank dies, requeue a player to become tank (for finales)
 */
void PlayerDeath_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    int victim = GetClientOfUserId(hEvent.GetInt("userid"));

    if (victim && IS_VALID_INFECTED(victim))
    {
        int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
        if (zombieClass == ZOMBIECLASS_TANK)
        {
            if (hTankDebug.BoolValue)
                PrintToConsoleAll("[TC] Tank died(1), choosing a new tank");

            tankInitiallyChosen = "";
            chooseTank(0);
            g_iMenuPasses = 0;
        }
    }
}

void TankKilled_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    if (hTankDebug.BoolValue)
        PrintToConsoleAll("[TC] Tank died(2), choosing a new tank");

    tankInitiallyChosen = "";
    chooseTank(0);
    dcedTankFrustration = -1;
}


/*=========================================================================
|                               Commands                                  |
=========================================================================*/


/**
 * When a player wants to find out whos becoming tank,
 * output to them.
 */
Action Tank_Cmd(int client, int args)
{
    // Only output if client is in-game and we have a queued tank
    if (!IsClientInGame(client) || StrEqual(queuedTankSteamId, ""))
        return Plugin_Handled;

    int tankClientId = getInfectedPlayerBySteamId(queuedTankSteamId);

    if (tankClientId != -1 && (hTankPrint.BoolValue || IS_INFECTED(client) || IS_SPECTATOR(client)))
    {
        if (client == tankClientId)
            CPrintToChat(client, "%t %t", "TagSelection", "YouBecomeTank");
        else
            CPrintToChat(client, "%t %t", "TagSelection", "BecomeTank", tankClientId);
    }

    return Plugin_Handled;
}

Action Pass_Cmd(int client, int args) {
    if (!hPassMenu.BoolValue) {
        CPrintToChat(client, "%t {default}Passing the tank is not enabled", "TagSelection");
        return Plugin_Handled;
    }

    if (g_iMenuPasses >= hMaxPasses.IntValue) {
        CPrintToChat(client, "%t You can't pass the tank!", "TagControl");
        return Plugin_Handled;
    }

    if (
        L4D_GetClientTeam(client) != L4DTeam_Infected ||
        !IsPlayerAlive(client) ||
        L4D_IsPlayerGhost(client) ||
        L4D2_GetPlayerZombieClass(client) != L4D2ZombieClass_Tank
    ) {
        CPrintToChat(client, "%t {default}You are not a {orange}tank{default}!", "TagSelection");
        return Plugin_Handled;
    }

    ShowTankPassMenu(client);
    return Plugin_Handled;
}

/**
 * Shuffle the tank (randomly give to another player in
 * the pool.
 */
Action TankShuffle_Cmd(int client, int args)
{
    tankInitiallyChosen = "";

    chooseTank(0);
    outputTankToAll(0);

    return Plugin_Handled;
}

/**
 * Give the tank to a specific player.
 */
Action GiveTank_Cmd(int client, int args)
{
    // Who are we targetting?
    char arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));

    // Try and find a matching player
    int target = FindTarget(client, arg1, true, false);

    if (target == -1 || !IsClientInGame(target) || IsFakeClient(target))
    {
        CPrintToChat(client, "%t %t", "TagControl", "InvalidTarget");
        return Plugin_Handled;
    }

    // Checking if on our desired team
    if (!IS_INFECTED(target))
    {
        CPrintToChat(client, "%t %t", "TagControl", "NoInfected", target);
        return Plugin_Handled;
    }

    // Set the tank
    char steamId[64];
    GetClientAuthId(target, AuthId_Steam2, steamId, sizeof(steamId));

    strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), steamId);
    strcopy(tankInitiallyChosen, sizeof(tankInitiallyChosen), steamId);
    strcopy(pendingFromCommand, sizeof(pendingFromCommand), steamId);

    if (L4D_HasAnySurvivorLeftSafeArea()) {
        outputTankToAll(0);
    } else {
        CPrintToChat(target, "%t %t", "TagSelection", "YouBecomeTank");

        if (client != target) {
            CPrintToChat(client, "%t %t", "TagSelection", "BecomeTank", target);
        }
    }

    return Plugin_Handled;
}


Action TakeTank_Cmd(int client, int args)
{
    // Who are we targetting?
    char arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));

    // Try and find a matching player
    int target = args ? FindTarget(client, arg1, true, false) : client;

    if (target == -1 || !IsClientInGame(target) || IsFakeClient(target))
    {
        CPrintToChat(client, "%t %t", "TagControl", "InvalidTarget");
        return Plugin_Handled;
    }

    // Checking if on our desired team
    if (!IS_INFECTED(target))
    {
        CPrintToChat(client, "%t %t", "TagControl", "NoInfected", target);
        return Plugin_Handled;
    }

    int tank = FindClientPlayingTank();

    if (tank == -1) {
        CPrintToChat(client, "%t {default}No tank in play!", "TagControl");
        return Plugin_Handled;
    }

    if (tank == target) {
        CPrintToChat(client, "%t {red}%N {default}is already the tank!", "TagControl", tank);
        return Plugin_Handled;
    }

    PassTank(tank, target);
    CPrintToChat(client, "%t {default}Giving tank to {red}%N{default}!", "TagControl", target);
    return Plugin_Handled;
}

void PassTank(int from, int to) {
    float origin[3], angles[3];
    GetClientAbsOrigin(from, origin);
    GetClientAbsAngles(from, angles);
    L4D_ReplaceWithBot(to);
    L4D_ReplaceTank(from, to);
    TeleportEntity(to, origin, angles);
    L4D2Direct_SetTankPassedCount(1);

    DataPack data = new DataPack();
    data.WriteCell(to);
    data.WriteFloat(GetGameTime());
    data.WriteFloatArray(origin, 3);
    RequestFrame(FixTankPosition, data);

    // L4D2Direct_SetTankTickets(to, 10000);

    // for (int i = 1; i <= MaxClients; i++) {
    //     if (i != to && IsClientInGame(i) && !IsFakeClient(i) && L4D_GetClientTeam(i) == L4DTeam_Infected) {
    //         L4D2Direct_SetTankTickets(i, 0);
    //     }
    // }

    // g_bManuallyPassingTank = true;
    // L4D2Direct_TryOfferingTankBot(from, false);
}

#define FIX_TANK_POSITION_DURATION 2.0
#define FIX_TANK_POSITION_MAX_DISTANCE 15.0

// since the new player sometimes gets teleported outside of the map,
// for some reason, we need to keep track of it's position for a few seconds
void FixTankPosition(DataPack data) {
    data.Reset();
    int tank = data.ReadCell();
    float passedTime = data.ReadFloat();
    float lastFrameOrigin[3];
    data.ReadFloatArray(lastFrameOrigin, 3);

    float currentOrigin[3];
    GetClientAbsOrigin(tank, currentOrigin);

    if (GetVectorDistance(currentOrigin, lastFrameOrigin) > FIX_TANK_POSITION_MAX_DISTANCE) {
        float angles[3];
        GetClientAbsAngles(tank, angles);
        TeleportEntity(tank, lastFrameOrigin, angles);
        PrintToServer("Fixing %N's tank position from {%f, %f, %f} to {%f, %f, %f} after %f seconds of passing the tank.",
            tank, currentOrigin[0], currentOrigin[1], currentOrigin[2],
            lastFrameOrigin[0], lastFrameOrigin[1], lastFrameOrigin[2]
        );
    } else {
        data.Position = view_as<DataPackPos>(view_as<int>(data.Position) - 1);
        data.WriteFloatArray(currentOrigin, 3, true);
    }

    if (GetGameTime() - passedTime < FIX_TANK_POSITION_DURATION) {
        RequestFrame(FixTankPosition, data);
    } else {
        delete data;
    }
}


/*=========================================================================
|                                 Stocks                                  |
=========================================================================*/


int FindClientPlayingTank() {
    for (int i = 1; i <= MaxClients; i++) {
        if (
            IsClientInGame(i) &&
            GetClientTeam(i) == 3 &&
            IsPlayerAlive(i) &&
            !L4D_IsPlayerGhost(i) &&
            GetEntProp(i, Prop_Send, "m_zombieClass") == 8
        ) {
            return i;
        }
    }
    return -1;
}


/**
 * Selects a player on the infected team from random who hasn't been
 * tank and gives it to them.
 */
void chooseTank(any data)
{
    // Allow other plugins to override tank selection.
    char sOverrideTank[64];
    sOverrideTank[0] = '\0';
    Call_StartForward(hForwardOnTankSelection);
    Call_PushStringEx(sOverrideTank, sizeof(sOverrideTank), SM_PARAM_STRING_UTF8, SM_PARAM_COPYBACK);
    Call_Finish();

    if (!StrEqual(sOverrideTank, ""))
    {
        strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), sOverrideTank);
        return;
    }

    queuedTankSteamId = "";

    int nextTankIndex = PeekNextTankIndexInTheQueue();

    if (nextTankIndex == -1)
    {
        EnqueueNewInfectedPlayers();
        nextTankIndex = PeekNextTankIndexInTheQueue();
    }

    if (nextTankIndex == -1)
    {
        RemoveAllInfectedFrom(h_tankQueue);
        RemoveAllInfectedFrom(h_whosHadTank);
        EnqueueNewInfectedPlayers();
        nextTankIndex = PeekNextTankIndexInTheQueue();
    }

    if (nextTankIndex == -1)
        return;

    char steamId[64];

    h_tankQueue.GetString(nextTankIndex, steamId, sizeof(steamId));

    strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), steamId);

    if (StrEqual(tankInitiallyChosen, ""))
        strcopy(tankInitiallyChosen, sizeof(tankInitiallyChosen), steamId);
}

/**
 * Sets the amount of tickets for a particular player, essentially giving them tank.
 */
void setTankTickets(const char[] steamId, int tickets)
{
    int tankClientId = getInfectedPlayerBySteamId(steamId);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IS_VALID_INFECTED(i) && !IsFakeClient(i))
            L4D2Direct_SetTankTickets(i, (i == tankClientId) ? tickets : 0);
    }
}

/**
 * Output who will become tank
 */
void outputTankToAll(any data)
{
    int tankClientId = getInfectedPlayerBySteamId(queuedTankSteamId);

    if (tankClientId != -1)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || (!hTankPrint.BoolValue && !IS_INFECTED(i) && !IS_SPECTATOR(i)))
                continue;

            if (tankClientId == i)
                CPrintToChat(i, "%t %t", "TagSelection", "YouBecomeTank");
            else
                CPrintToChat(i, "%t %t", "TagSelection", "BecomeTank", tankClientId);
        }
    }
}

/**
 * Retrieves the current Tank player.
 *
 * @return
 *     The tank's client index or -1 if not found.
 */
int getTankPlayer()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IS_INFECTED(i) || IsFakeClient(i))
            continue;

        int zombieClass = GetEntProp(i, Prop_Send, "m_zombieClass");

        if (zombieClass == ZOMBIECLASS_TANK)
            return i;
    }

    return -1;
}

/**
 * Retrieves a player's client index by their steam id.
 *
 * @param steamId
 *     The steam id string to look for.
 *
 * @return
 *     The player's client index or -1 if not found.
 */
int getInfectedPlayerBySteamId(const char[] steamId)
{
    char tmpSteamId[64];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IS_VALID_INFECTED(i))
            continue;

        GetClientAuthId(i, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId));

        if (StrEqual(steamId, tmpSteamId))
            return i;
    }

    return -1;
}

void SetTankFrustration(int iTankClient, int iFrustration)
{
    if (iFrustration >= 0 && iFrustration <= 100)
        SetEntProp(iTankClient, Prop_Send, "m_frustration", 100-iFrustration);
}

int GetTankFrustration(int iTankClient)
{
    return 100 - GetEntProp(iTankClient, Prop_Send, "m_frustration");
}

CountdownTimer GetFrustrationTimer(int client)
{
    static int s_iOffs_m_frustrationTimer = -1;

    if (s_iOffs_m_frustrationTimer == -1)
        s_iOffs_m_frustrationTimer = FindSendPropInfo("CTerrorPlayer", "m_frustration") + 4;

    return view_as<CountdownTimer>(GetEntityAddress(client) + view_as<Address>(s_iOffs_m_frustrationTimer));
}

int PeekNextTankIndexInTheQueue()
{
    if (h_tankQueue.Length == 0)
        return -1;

    char steamId[64];

    for (int i = 0; i < h_tankQueue.Length; i++)
    {
        h_tankQueue.GetString(i, steamId, sizeof(steamId));

        int client = getInfectedPlayerBySteamId(steamId);
        if (client != -1)
            return i;
    }

    return -1;
}

void EnqueueNewInfectedPlayers()
{
    char steamId[64];

    int start = h_tankQueue.Length;
    int end = -1;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != TEAM_INFECTED)
            continue;

        GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

        if (h_tankQueue.FindString(steamId) != -1 || h_whosHadTank.FindString(steamId) != -1)
            continue;

        h_tankQueue.PushString(steamId);

        end = h_tankQueue.Length - 1;
    }

    if (end != -1)
        ShuffleArray(h_tankQueue, start, end);
}

void RemoveAllInfectedFrom(ArrayList arrayList)
{
    char steamId[64];

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != TEAM_INFECTED)
            continue;

        GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

        int index = arrayList.FindString(steamId);
        if (index != -1)
            arrayList.Erase(index);
    }
}

void ShuffleArray(ArrayList arrayList, int start, int end)
{
    if (start == end)
        return;

    int swaps = (end - start + 1) * 2;

    for (int i = 0; i < swaps; i++)
    {
        int index1 = GetRandomInt(start, end);
        int index2 = GetRandomInt(start, end);

        if (index1 == index2)
            continue;

        arrayList.SwapAt(index1, index2);
    }
}

/**
 * Check if the translation file exists
 *
 * @param translation	Translation name.
 * @noreturn
 */
stock void LoadTranslation(const char[] translation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}