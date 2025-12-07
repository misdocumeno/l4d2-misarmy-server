#include <ripext>
#include <colors>

char g_sAPIEndpoint[256];
char g_sAPIToken[256];

enum struct PlayerInfo {
    int steamId;
    char name[MAX_NAME_LENGTH];
}

enum struct DemoInfo {
    bool recording;
    ArrayList players;
    char demoFile[PLATFORM_MAX_PATH];
    char cfgName[PLATFORM_MAX_PATH];
    int start;
}

DemoInfo g_CurrentDemo;

void InitDemoInfo(char[] demoFile) {
    ClearDemoInfo();
    g_CurrentDemo.recording = true;
    g_CurrentDemo.players = new ArrayList(sizeof PlayerInfo);

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {
            AddPlayerToDemo(i);
        }
    }

    LGO_GetConfigName(g_CurrentDemo.cfgName, sizeof g_CurrentDemo.cfgName);
    strcopy(g_CurrentDemo.demoFile, sizeof g_CurrentDemo.demoFile, demoFile);
    g_CurrentDemo.start = GetTime();
}

void ClearDemoInfo() {
    if (g_CurrentDemo.players != null) {
        delete g_CurrentDemo.players;
    }
    g_CurrentDemo.players = null;
    g_CurrentDemo.recording = false;
    g_CurrentDemo.demoFile[0] = '\0';
    g_CurrentDemo.cfgName[0] = '\0';
}

void AddPlayerToDemo(int client) {
    PlayerInfo playerInfo;
    playerInfo.steamId = GetSteamAccountID(client);
    GetClientName(client, playerInfo.name, sizeof playerInfo.name);

    for (int i = 0; i < g_CurrentDemo.players.Length; i++) {
        PlayerInfo existing;
        g_CurrentDemo.players.GetArray(i, existing);
        if (existing.steamId == playerInfo.steamId && StrEqual(existing.name, playerInfo.name)) {
            return;
        }
    }

    g_CurrentDemo.players.PushArray(playerInfo);
}

void SendDemoInfo() {
    if (!g_CurrentDemo.recording) {
        return;
    }

    JSONObject demo = new JSONObject();

    demo.SetString("file", GetFileName(g_CurrentDemo.demoFile));
    demo.SetString("cfg", g_CurrentDemo.cfgName);
    demo.SetInt("start", g_CurrentDemo.start);
    demo.SetInt("end", GetTime());
    char serverName[1024];
    FindConVar("hostname").GetString(serverName, sizeof serverName);
    demo.SetString("server", serverName);

    JSONArray players = new JSONArray();

    for (int i = 0; i < g_CurrentDemo.players.Length; i++) {
        PlayerInfo playerInfo;
        g_CurrentDemo.players.GetArray(i, playerInfo);
        JSONObject player = new JSONObject();
        player.SetInt("steamId", playerInfo.steamId);
        player.SetString("name", playerInfo.name);
        players.Push(player);
        delete player;
    }

    demo.Set("players", players);

    char stringified[8192];
    demo.ToString(stringified, sizeof stringified);

    char url[1024];
    Format(url, sizeof url, "%s/meta", g_sAPIEndpoint);
    LogMessage("Posting demo info to %s: %s", url, stringified);
    HTTPRequest req = new HTTPRequest(url);
    req.SetHeader("x-api-token", g_sAPIToken);
    DataPack pack = new DataPack();
    req.Post(demo, OnDemoInfoSent, pack);
    pack.WriteString(g_CurrentDemo.demoFile);

    delete demo;
    delete players;
    ClearDemoInfo();
}

void OnDemoInfoSent(HTTPResponse response, DataPack demo) {
    demo.Reset();
    char demoFile[PLATFORM_MAX_PATH];
    demo.ReadString(demoFile, sizeof demoFile);

    if (response.Status != HTTPStatus_OK) {
        LogError("Failed to upload demo info: %s. status code: %d", demoFile, response.Status);
        char error[256];
        response.Data.ToString(error, sizeof error);
        LogError(error);
        return;
    }

    char url[1024];
    Format(url, sizeof url, "%s/%s", g_sAPIEndpoint, GetFileName(demoFile));
    LogMessage("Uploading demo file to %s", url);
    HTTPRequest req = new HTTPRequest(url);
    req.SetHeader("x-api-token", g_sAPIToken);
    req.SetHeader("Content-Type", "application/octet-stream");
    req.UploadFile(demoFile, OnDemoFileUploaded, demo);
}

void OnDemoFileUploaded(HTTPStatus status, DataPack demo, char[] errors) {
    demo.Reset();
    char demoFile[PLATFORM_MAX_PATH];
    demo.ReadString(demoFile, sizeof demoFile);

    if (status == HTTPStatus_OK) {
        LogMessage("Uploaded demo file: %s. Deleting local copy.", demoFile);
        DeleteFile(demoFile);
    } else {
        LogError("Failed to upload demo file: %s. Status code: %d. Preserving local copy.", demoFile, status);
        LogError("Errors: %s", errors);
    }
}

char[] GetFileName(char[] path) {
    char pieces[PLATFORM_MAX_PATH][PLATFORM_MAX_PATH];
    int count = ExplodeString(path, "/", pieces, sizeof pieces, PLATFORM_MAX_PATH);
    return pieces[count - 1];
}

void Server_Init() {
    char configPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, configPath, sizeof configPath, "configs/autorecorder.cfg");
    KeyValues config = new KeyValues("config");
    config.ImportFromFile(configPath);
    config.GetString("api_endpoint", g_sAPIEndpoint, sizeof g_sAPIEndpoint);
    config.GetString("api_token", g_sAPIToken, sizeof g_sAPIToken);
    delete config;
}