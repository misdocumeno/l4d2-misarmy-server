#pragma semicolon 1
#define AUTOSLAYER_DEBUG 0
#define NO_COUNTDOWN -1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>
#include "includes/hardcoop_util.sp"

int iAutoslayerCountdown[MAXPLAYERS + 1]; // track how much longer to allow an SI to pin a survivor before slaying them.

new Handle:hAutoSlayerTimer; 
new Handle:hCvarPinTime;

public Plugin:myinfo = {
	name = "AutoSlayer",
	author = "Breezy",
	description = "Applies configurable lifespans to attacking special infected, to allow survivors to handle more spawns",
	version = "3.0"
};

public OnPluginStart() 
{
	hCvarPinTime = CreateConVar("autoslayer_pintime", "7", "How long an SI is allowed to pin a survivor");
	// Event hooks
	HookEvent("choke_start", EventHook:OnPlayerPinned, EventHookMode_PostNoCopy);
	HookEvent("lunge_pounce", EventHook:OnPlayerPinned, EventHookMode_PostNoCopy);
	HookEvent("charger_pummel_start", EventHook:OnPlayerPinned, EventHookMode_PostNoCopy); 
	HookEvent("jockey_ride", EventHook:OnPlayerPinned, EventHookMode_PostNoCopy);	
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	// Prevent AutoSlayer activating between maps
	HookEvent("map_transition", EventHook:OnGameOver, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", EventHook:OnGameOver, EventHookMode_PostNoCopy);
	HookEvent("finale_win", EventHook:OnGameOver, EventHookMode_PostNoCopy);
}

public OnPluginEnd() 
{
	StopAutoslayer();
}

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax) 
{
	return APLRes_Success;
}

public Action:L4D_OnFirstSurvivorLeftSafeArea(client) 
{ 
	for (int i = 0; i < (MAXPLAYERS + 1); ++i) 
	{	
		iAutoslayerCountdown[i] = NO_COUNTDOWN;
	}
	hAutoSlayerTimer = CreateTimer(1.0, Timer_AutoSlayer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

// char L4D2_InfectedNames[][] = {
// 	"Normal",
// 	"Smoker",
// 	"Boomer",
// 	"Hunter",
// 	"Spitter",
// 	"Jockey",
// 	"Charger",
// 	"Witch",
// 	"Tank",
// 	"Survivor"
// };

public OnPlayerPinned(Handle:event, String:name[], bool:dontBroadcast) {
	int attackingSI = GetClientOfUserId(GetEventInt(event, "userid"));
	int iVictim = GetClientOfUserId(GetEventInt(event, "victim"));
	int iRemainingHealth = GetClientHealth(attackingSI);
	char infectedName[MAX_NAME_LENGTH];
	GetClientName(attackingSI, infectedName, sizeof(infectedName));

	CPrintToChat(
		iVictim,
		"[{olive}!{default}] {red}AI{default} ({green}%s{default}) had {olive}%d{default} health remaining!",
		infectedName,
		iRemainingHealth
	);

	if (iRemainingHealth == 1) {
		CPrintToChat(iVictim, "You don't have to be mad...");
	}

	if (iAutoslayerCountdown[attackingSI] == NO_COUNTDOWN)
	{
		if (GetConVarInt(FindConVar("survivor_limit")) == 1 ) // instant clear in single player mode
		{
			// KickClient(attackingSI);
			ForcePlayerSuicide(attackingSI);
			iAutoslayerCountdown[attackingSI] = NO_COUNTDOWN;
		}
		else // delayed clear otherwise
		{
			iAutoslayerCountdown[attackingSI] = GetConVarInt(hCvarPinTime);
			if (IsTeamImmobilised()) // in case any of the pinning SI are not dealing any damage
			{
				//SlaySurvivors();
			}
		}
	}

	if (FindConVar("survivor_limit").IntValue == 1) {
		int weapon = GetPlayerWeaponSlot(iVictim, 0);

		if (weapon == INVALID_ENT_REFERENCE) {
			return;
		}

		char weaponName[56];
		GetEdictClassname(weapon, weaponName, sizeof(weaponName));
		SetEntProp(weapon, Prop_Send, "m_iClip1", L4D2_GetIntWeaponAttribute(weaponName, L4D2IWA_ClipSize));

		CreateTimer(0.1, CancelGetUpAnimationDelayed, iVictim);
	}
}

Action CancelGetUpAnimationDelayed(Handle timer, any client) {
	SetEntPropFloat(client, Prop_Send, "m_flCycle", 1000.0);
	return Plugin_Handled;
}


// Reset countdown array for SI that have died
public OnPlayerDeath(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId( GetEventInt(event, "userid") );
	if (IsInfected(client)) {
		iAutoslayerCountdown[client] = NO_COUNTDOWN; 
	}
}

public OnGameOver(Event event, const char[] name, bool dontBroadcast)
{
	StopAutoslayer();
}

public Action:Timer_AutoSlayer(Handle:timer, any:none) // Timer repeats every second; countsdown to clear pinned survivors
{
	for (int client = 0; client < (MAXPLAYERS + 1); ++client) 
	{
		if (iAutoslayerCountdown[client] > 0)
		{
			--iAutoslayerCountdown[client]; // keep counting down
		} 
		else if (iAutoslayerCountdown[client] == 0 && IsClientInGame(client) && !IsClientInKickQueue(client)) // time to slay
		{
			KickClient(client);
			iAutoslayerCountdown[client] = NO_COUNTDOWN; 
		}
	}
}

void StopAutoslayer()
{
	CloseHandle(hAutoSlayerTimer);
	hAutoSlayerTimer = INVALID_HANDLE;
}

/**
 * @return: true if all survivors are either incapacitated or pinned
**/
bool:IsTeamImmobilised() {
	new bool:bIsTeamImmobilised = true;
	for (new client = 1; client < MaxClients; client++) {
		if (IsSurvivor(client) && IsPlayerAlive(client)) {
			if ( !IsPinned(client) && !IsIncapacitated(client) ) {		
				bIsTeamImmobilised = false;				
				break;
			} 
		} 
	}
	return bIsTeamImmobilised;
}

// SlaySurvivors() { //incap everyone
// 	for (new client = 1; client < (MAXPLAYERS + 1); client++) {
// 		if (IsSurvivor(client) && IsPlayerAlive(client)) {
// 			ForcePlayerSuicide(client);
// 		}
// 	}
// }