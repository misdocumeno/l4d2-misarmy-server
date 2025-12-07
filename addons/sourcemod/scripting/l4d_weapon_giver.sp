#include <sourcemod>
#include <left4dhooks>
#include <colors>

#define REPLY_PREFIX "{blue}[{default}!{blue}]{default}"
#define ERROR_REPLY_PREFIX "{red}[{default}!{red}]{default}"


public Plugin myinfo = {
	name = "Weapon giver",
	author = "Mis",
	description = "Survivors can get weapons with commands and menu.",
	version = "0.1.0",
	url = "https://github.com/misdocumeno/l4d2-misarmy-server"
}

bool weaponAllowed[view_as<int>(L4D2WeaponId_MAX)]
ArrayList allowedWeapons


public void OnPluginStart() {
    allowedWeapons = new ArrayList()

    char allowedWeaponsValue[] = "smg,smg_silenced,pumpshotgun,shotgun_chrome"
    ConVar allowedWeaponsCvar = CreateConVar(
        "weapon_giver_allowed_weapons",
        allowedWeaponsValue,
        "The names of the weapons to allow players to get, separated by commas (without the weapon_ prefix)"
    )
    allowedWeaponsCvar.AddChangeHook(OnWeaponsCvarChange)
    OnWeaponsCvarChange(allowedWeaponsCvar, "", allowedWeaponsValue)

    RegConsoleCmd("sm_weapons", OnWeaponCmd, "Get a weapon.")
    RegConsoleCmd("sm_gun", OnWeaponCmd, "Get a weapon.")
    RegConsoleCmd("sm_guns", OnWeaponCmd, "Get a weapon.")
    RegConsoleCmd("sm_t1", OnWeaponCmd, "Get a weapon.")
}

public void OnWeaponsCvarChange(ConVar convar, const char[] oldValue, const char[] newValue) {
    char weaponsString[view_as<int>(L4D2WeaponId_MAX)][64]
    ExplodeString(newValue, ",", weaponsString, sizeof weaponsString, sizeof weaponsString[])

    for (int i = 0; i < sizeof weaponAllowed; i++) {
        weaponAllowed[i] = false
    }

    for (int i = 0; i < sizeof weaponsString; i++) {
        if (!strlen(weaponsString[i])) break

        char buffer[64]
        Format(buffer, sizeof buffer, "weapon_%s", weaponsString[i])
        L4D2WeaponId weapon = L4D2_GetWeaponIdByWeaponName(buffer)

        if (weapon == L4D2WeaponId_None) {
            ThrowError("Invalid weapon %s", weaponsString[i])
        }

        weaponAllowed[view_as<int>(weapon)] = true
        allowedWeapons.Push(view_as<int>(weapon))
    }
}

public Action OnWeaponCmd(int client, int args) {
    if (L4D_GetClientTeam(client) != L4DTeam_Survivor) {
        CPrintToChat(client, "%s Only {olive}survivors {default}can get weapons!", ERROR_REPLY_PREFIX)
        return Plugin_Handled
    }

    if (!args) {
        OpenWeaponMenu(client)
        return Plugin_Handled
    }

    char arg[64], weaponName[64]
    GetCmdArg(1, arg, sizeof arg)
    Format(weaponName, sizeof weaponName, "weapon_%s", arg)
    GiveWeapon(client, weaponName)
    return Plugin_Handled
}

void OpenWeaponMenu(int client) {
    Menu menu = new Menu(OpenWeaponMenuHandler)
    menu.SetTitle("Select a weapon")

    for (int i = 0; i < allowedWeapons.Length; i++) {
        L4D2WeaponId weapon = view_as<L4D2WeaponId>(allowedWeapons.Get(i))
        char weaponName[128], nameNoPrefix[128]
        L4D2_GetWeaponNameByWeaponId(weapon, weaponName, sizeof weaponName)
        strcopy(nameNoPrefix, sizeof nameNoPrefix, weaponName)
        ReplaceString(nameNoPrefix, sizeof nameNoPrefix, "weapon_", "")
        menu.AddItem(weaponName, nameNoPrefix)
    }

    menu.ExitButton = false
    menu.Display(client, 10)
}

public int OpenWeaponMenuHandler(Menu menu, MenuAction action, int client, int option) {
    if (action == MenuAction_Select) {
        char weaponName[128]
        menu.GetItem(option, weaponName, sizeof weaponName)
        GiveWeapon(client, weaponName)
    } else if (action == MenuAction_End) {
        delete menu
    }
    return 0
}

bool GiveWeapon(int client, const char[] weaponName) {
    if (L4D_GetClientTeam(client) != L4DTeam_Survivor) {
        CPrintToChat(client, "%s Only {olive}survivors {default}can get weapons!", ERROR_REPLY_PREFIX)
        return false
    }

    L4D2WeaponId weapon = L4D2_GetWeaponIdByWeaponName(weaponName)
    char buffer[128]
    strcopy(buffer, sizeof buffer, weaponName)
    ReplaceString(buffer, sizeof buffer, "weapon_", "")

    if (weapon == L4D2WeaponId_None || !weaponAllowed[view_as<int>(weapon)]) {
        CPrintToChat(client, "%s {orange}%s {default}is not a valid weapon!", ERROR_REPLY_PREFIX, buffer)
        return false
    }

    GivePlayerItem(client, weaponName)
    CPrintToChat(client, "%s Take your {olive}%s{default}!", REPLY_PREFIX, buffer)
    return true
}