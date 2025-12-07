#include <sourcemod>
#include <left4dhooks>

#undef REQUIRE_PLUGIN
#include <readyup>

#undef REQUIRE_PLUGIN
#include <confogl>

#define REQUIRE_EXTENSIONS
#include <sourcetvmanager>


// QUE HACER:
// en round is live:
//  - ver si estamos en el primer capitulo de un mapa. FIN
//  como saber eso: leyendo un json que vamos a generar en runner
// - si no lo estamos, chequear que estemos en el siguiente del anterior (segun el json, en realidad kv)
//   Y que los scores actuales sean los mismos que los que eran al finalizar el anterior.
//
//  (si la cfg es distinta el plugin se reinicia asique supongo que da igual chequear eso)
//
//  el json debe generarse leyendo los vpk de los mapas custom, (ademas de mapas de l4d2)
//  para esto, arreglar la sincronizacion de mapas con l4d2center, y ver que hacer con el mapa chino



// L4D_OnClearTeamScores deberia invalidar el match id
// match id deberia obtenerse en caso de no tener uno
// al tener uno, usar ese
//
// TODO: pero, fijarse si L4D_OnClearTeamScores se llama al cambiar de mapa con voto (de c2m3 a c2m1 por ej)
// y que no se llame al avanzar de cap, obvio
// pero, fijarse si l4d2_map_transitions lo bloquea (no creo). asique probablemente agregar
// una condicion, usando el native de l4d2_map_transitions. si se acaba de trancisionar, no invalidar, o algo aso

// TODO: hacer native para que al banear con sourcebans, se pueda obtener la id de la demo, o algo asi
// y asi servir la demo del ban en el frontend de alguna forma. o, al revez, escuchar desde aca el ban?
// o mejor, hacer plugin misarmy_website o algo asi, y ahi escuchar el ban, y a la vez usar el native de esto

// L4D_OnClearTeamScores
public Action L4D_OnClearTeamScores(bool newCampaign) {
    char time[256];
    FormatTime(time, sizeof(time), "%H:%M:%S");
    PrintToServer("[%s] L4D_OnClearTeamScores called with newCampaign = %s", time, newCampaign ? "true" : "false");
    LogToFile("addons/sourcemod/logs/demo_recorder_test.log", "[%s] L4D_OnClearTeamScores called with newCampaign = %s", time, newCampaign ? "true" : "false");
    return Plugin_Continue;
}


public void OnPluginStart() {
    PrintToServer("Demo Recorder Plugin loaded");
}