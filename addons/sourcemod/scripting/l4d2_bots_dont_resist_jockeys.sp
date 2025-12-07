#include <sourcemod>
#include <left4dhooks>


public Plugin myinfo = {
	name = "Bots, don't resist the jockey",
	author = "Mis",
	description = "Prevents survivor bots from resisting being moved by a jockey, just like real players.",
	version = "0.1.0",
	url = "https://github.com/misdocumeno/l4d2-misarmy-server"
}


public Action OnPlayerRunCmd(int client, int& buttons) {
    if (
        IsFakeClient(client) &&
        L4D_GetClientTeam(client) == L4DTeam_Survivor &&
        GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") != -1
    ) {
        buttons = buttons & ~(IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT)
        return Plugin_Changed
    }

    return Plugin_Continue
}
