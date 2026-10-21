#include <sourcemod>
#include <cstrike>
#include <donutmatch>
#include <ripext>

#define PLUGIN_VERSION "0.2.3"
#define MAX_SERIES_MAPS 32
#define MAX_MAP_NAME 64

public Plugin myinfo =
{
    name = "DonutMatch Web Bridge",
    author = "phenom",
    description = "Publishes the current DonutMatch API state to the web dashboard",
    version = PLUGIN_VERSION,
    url = "https://t.me/phenom1337"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("DonutMatch.IsLive");
    MarkNativeAsOptional("DonutMatch.State");
    MarkNativeAsOptional("DonutMatch.Mode");
    MarkNativeAsOptional("DonutMatch.TeamName");
    MarkNativeAsOptional("DonutMatch.LastTeamName");
    MarkNativeAsOptional("DonutMatch.TeamScore");
    MarkNativeAsOptional("DonutMatch.TeamPlayers");
    MarkNativeAsOptional("DonutMatch.WarMatchFormat");
    MarkNativeAsOptional("DonutMatch.LastWarMatchFormat");
    MarkNativeAsOptional("DonutMatch.WarSeriesMode");
    MarkNativeAsOptional("DonutMatch.IsWarSeriesActive");
    MarkNativeAsOptional("DonutMatch.WarSeriesWins");
    MarkNativeAsOptional("DonutMatch.WarSeriesMapsToWin");
    MarkNativeAsOptional("DonutMatch.WarSeriesMapIndex");
    MarkNativeAsOptional("DonutMatch.WarSeriesMaps");
    MarkNativeAsOptional("DonutMatch.CurrentWarVetoAction");
    MarkNativeAsOptional("DonutMatch.CurrentWarVetoTeam");
    MarkNativeAsOptional("DonutMatch.GetWarVetoProgress");
    MarkNativeAsOptional("DonutMatch.WarSeriesAvailableMaps");
    MarkNativeAsOptional("DonutMatch.WarSeriesBannedMaps");
    MarkNativeAsOptional("DonutMatch.WarSeriesPickedMaps");
    MarkNativeAsOptional("MatchPlayer.IsValid");
    MarkNativeAsOptional("MatchPlayer.Name");
    MarkNativeAsOptional("MatchPlayer.AuthId");
    MarkNativeAsOptional("MatchPlayer.Frags");
    MarkNativeAsOptional("MatchPlayer.Deaths");
    return APLRes_Success;
}

ConVar g_CvarApiUrl;
ConVar g_CvarToken;
ConVar g_CvarServerId;
DonutMatch g_Match;

char g_sApiUrl[256];
char g_sToken[256];
char g_sServerId[64];
char g_sMatchId[128];
char g_sStatus[24] = "warmup";
char g_sEndReason[128];

int g_iGameMode = 0;
int g_iWarFormat = -1;
int g_iRound;
int g_iLastScoreT;
int g_iLastScoreCT;
int g_iMatchSequence;

bool g_bMatchActive;
bool g_bSeriesActive;
bool g_bSeriesVetoPreview;
bool g_bSeriesScoreAvailable;
bool g_bHasVetoData;
bool g_bVetoActive;
bool g_bLastVetoAutomatic;
bool g_bRequestPending;
bool g_bSnapshotDirty;

int g_iSeriesWinsA;
int g_iSeriesWinsB;
int g_iSeriesBestOf;
int g_iSeriesMapsToWin;
int g_iSeriesMapIndex; // 1-based for the API/frontend
char g_sSeriesTeamAName[128];
char g_sSeriesTeamBName[128];
char g_sCachedTeamCTName[128];
char g_sCachedTeamTName[128];
char g_sSeriesMaps[MAX_SERIES_MAPS][MAX_MAP_NAME];
int g_iSeriesMapCount;

int g_iVetoStep;
int g_iVetoStepCount;
int g_iVetoAction = -1;
int g_iVetoTeam = -1;
char g_sLastVetoMap[MAX_MAP_NAME];
char g_sVetoAvailable[MAX_SERIES_MAPS][MAX_MAP_NAME];
char g_sVetoBanned[MAX_SERIES_MAPS][MAX_MAP_NAME];
char g_sVetoPicked[MAX_SERIES_MAPS][MAX_MAP_NAME];
int g_iVetoAvailableCount;
int g_iVetoBannedCount;
int g_iVetoPickedCount;

int g_iSeriesResultCount;
int g_iResultMapIndex[MAX_SERIES_MAPS];
char g_sResultMap[MAX_SERIES_MAPS][MAX_MAP_NAME];
int g_iResultScoreT[MAX_SERIES_MAPS];
int g_iResultScoreCT[MAX_SERIES_MAPS];
int g_iResultTeamAScore[MAX_SERIES_MAPS];
int g_iResultTeamBScore[MAX_SERIES_MAPS];
int g_iResultWinner[MAX_SERIES_MAPS];
int g_iResultTeamAWins[MAX_SERIES_MAPS];
int g_iResultTeamBWins[MAX_SERIES_MAPS];
Handle g_hStartupSyncTimer;
Handle g_hStatsSnapshotTimer;

public void OnPluginStart()
{
    g_CvarApiUrl = CreateConVar("sm_donutmatch_web_url", "", "DonutMatch API event endpoint", FCVAR_PROTECTED);
    g_CvarToken = CreateConVar("sm_donutmatch_web_token", "", "DonutMatch API ingest token", FCVAR_PROTECTED);
    g_CvarServerId = CreateConVar("sm_donutmatch_web_server_id", "css-server-1", "Stable unique ID for this game server", FCVAR_PROTECTED);
    AutoExecConfig(true, "donutmatch_web");
    ReadConfig();
    RegAdminCmd("sm_donutmatch_web_sync", Command_ForceSync, ADMFLAG_ROOT, "Publish the current DonutMatch snapshot to the website");
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    LogMessage("DonutMatch Web Bridge %s loaded; waiting for the DonutMatch API", PLUGIN_VERSION);
    ScheduleStartupSync(2.0);
}

public void OnConfigsExecuted()
{
    ReadConfig();
    ScheduleStartupSync(2.0);
}

public void OnMapStart()
{
    ScheduleStartupSync(4.0);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bMatchActive || g_hStatsSnapshotTimer != null)
        return;
    g_hStatsSnapshotTimer = CreateTimer(0.25, TimerPublishPlayerStats, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerPublishPlayerStats(Handle timer)
{
    if (timer == g_hStatsSnapshotTimer)
        g_hStatsSnapshotTimer = null;
    if (g_bMatchActive)
        PublishSnapshot();
    return Plugin_Stop;
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "donutmatch"))
    {
        LogMessage("DonutMatch library detected");
        ScheduleStartupSync(1.0);
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "donutmatch"))
        LogMessage("DonutMatch library removed; waiting for it to return");
}

void ReadConfig()
{
    g_CvarApiUrl.GetString(g_sApiUrl, sizeof(g_sApiUrl));
    g_CvarToken.GetString(g_sToken, sizeof(g_sToken));
    g_CvarServerId.GetString(g_sServerId, sizeof(g_sServerId));
    TrimString(g_sApiUrl);
    TrimString(g_sToken);
    TrimString(g_sServerId);
}

bool NativeAvailable(const char[] name)
{
    return GetFeatureStatus(FeatureType_Native, name) == FeatureStatus_Available;
}

bool IsGenericSideName(const char[] name)
{
    return StrEqual(name, "Спецназ", false)
        || StrEqual(name, "Террористы", false)
        || StrEqual(name, "Terrorists", false)
        || StrEqual(name, "Counter-Terrorists", false)
        || StrEqual(name, "CT", false)
        || StrEqual(name, "T", false)
        || StrEqual(name, "Team A", false)
        || StrEqual(name, "Team B", false);
}

void RememberTeamName(int team, const char[] name)
{
    if ((team != CS_TEAM_CT && team != CS_TEAM_T) || name[0] == '\0' || IsGenericSideName(name))
        return;

    if (team == CS_TEAM_CT)
        strcopy(g_sCachedTeamCTName, sizeof(g_sCachedTeamCTName), name);
    else
        strcopy(g_sCachedTeamTName, sizeof(g_sCachedTeamTName), name);
}

void CaptureCurrentTeamNames()
{
    if (!NativeAvailable("DonutMatch.TeamName"))
        return;

    char name[128];
    if (g_Match.TeamName(CS_TEAM_CT, name, sizeof(name)))
        RememberTeamName(CS_TEAM_CT, name);
    if (g_Match.TeamName(CS_TEAM_T, name, sizeof(name)))
        RememberTeamName(CS_TEAM_T, name);
}

void CaptureLastMatchTeamNames()
{
    if (!NativeAvailable("DonutMatch.LastTeamName"))
        return;

    char name[128];
    if (g_Match.LastTeamName(CS_TEAM_CT, name, sizeof(name)))
        RememberTeamName(CS_TEAM_CT, name);
    if (g_Match.LastTeamName(CS_TEAM_T, name, sizeof(name)))
        RememberTeamName(CS_TEAM_T, name);
}

void ResolveTeamNames(char[] ctName, int ctMax, char[] tName, int tMax)
{
    CaptureCurrentTeamNames();
    if (StrEqual(g_sStatus, "finished") || StrEqual(g_sStatus, "cancelled"))
        CaptureLastMatchTeamNames();

    ctName[0] = '\0';
    tName[0] = '\0';
    if (g_sCachedTeamCTName[0] != '\0')
        strcopy(ctName, ctMax, g_sCachedTeamCTName);
    if (g_sCachedTeamTName[0] != '\0')
        strcopy(tName, tMax, g_sCachedTeamTName);

    if (IsBestOfFormat(g_iWarFormat))
    {
        CaptureSeriesTeamNames();
        if (g_sSeriesTeamAName[0] != '\0' && g_sSeriesTeamBName[0] != '\0')
        {
            // Team A starts T on map 1; sides alternate on each successive map.
            if (g_iSeriesMapIndex <= 1 || (g_iSeriesMapIndex % 2) == 1)
            {
                strcopy(tName, tMax, g_sSeriesTeamAName);
                strcopy(ctName, ctMax, g_sSeriesTeamBName);
            }
            else
            {
                strcopy(ctName, ctMax, g_sSeriesTeamAName);
                strcopy(tName, tMax, g_sSeriesTeamBName);
            }
        }
    }
}

bool IsKnownWarFormat(int format)
{
    return format == view_as<int>(WarSeries_Classic)
        || format == view_as<int>(WarSeries_BO1)
        || format == view_as<int>(WarSeries_BO3)
        || format == view_as<int>(WarSeries_BO5);
}

bool IsBestOfFormat(int format)
{
    return format == view_as<int>(WarSeries_BO1)
        || format == view_as<int>(WarSeries_BO3)
        || format == view_as<int>(WarSeries_BO5);
}

int BestOfFromFormat(int format)
{
    if (format == view_as<int>(WarSeries_BO1)) return 1;
    if (format == view_as<int>(WarSeries_BO3)) return 3;
    if (format == view_as<int>(WarSeries_BO5)) return 5;
    return 0;
}

void NewMatchId()
{
    g_iMatchSequence++;
    FormatEx(g_sMatchId, sizeof(g_sMatchId), "%s-%d-%d", g_sServerId, GetTime(), g_iMatchSequence);
}

void SetModeAndFormat(int mode, int format)
{
    g_iGameMode = mode;
    if (g_iGameMode != view_as<int>(MODE_WAR))
    {
        g_iWarFormat = view_as<int>(WarSeries_Unknown);
        return;
    }

    if (IsKnownWarFormat(format))
    {
        g_iWarFormat = format;
        return;
    }

    RefreshFormatFromCore();
}

void RefreshModeAndFormatFromCore()
{
    if (NativeAvailable("DonutMatch.Mode"))
        g_iGameMode = view_as<int>(g_Match.Mode());
    RefreshFormatFromCore();
}

void RefreshFormatFromCore()
{
    if (g_iGameMode != view_as<int>(MODE_WAR))
    {
        g_iWarFormat = view_as<int>(WarSeries_Unknown);
        return;
    }

    // New API: this is the actual format selected for the current War match.
    // Do not substitute WarSeriesMode(), which is only the active/next-series setting.
    if (NativeAvailable("DonutMatch.WarMatchFormat"))
    {
        int actualFormat = view_as<int>(g_Match.WarMatchFormat());
        if (IsKnownWarFormat(actualFormat))
        {
            g_iWarFormat = actualFormat;
            return;
        }
    }

    // Compatibility with the older core API, which had no WarMatchFormat native.
    if (IsWarSeriesActiveSafe() && NativeAvailable("DonutMatch.WarSeriesMode"))
    {
        int seriesFormat = view_as<int>(g_Match.WarSeriesMode());
        if (IsBestOfFormat(seriesFormat))
        {
            g_iWarFormat = seriesFormat;
            return;
        }
    }

    // Under the old API, a War match outside a multi-map series is Classic.
    if (!IsWarSeriesActiveSafe())
        g_iWarFormat = view_as<int>(WarSeries_Classic);
}

bool IsWarSeriesActiveSafe()
{
    if (!NativeAvailable("DonutMatch.IsWarSeriesActive"))
        return false;
    return g_Match.IsWarSeriesActive();
}

void ClearSeriesState()
{
    g_bSeriesActive = false;
    g_bSeriesScoreAvailable = false;
    g_bSeriesVetoPreview = false;
    g_bHasVetoData = false;
    g_bVetoActive = false;
    g_bLastVetoAutomatic = false;
    g_iSeriesWinsA = 0;
    g_iSeriesWinsB = 0;
    g_iSeriesBestOf = 0;
    g_iSeriesMapsToWin = 0;
    g_iSeriesMapIndex = 0;
    g_iSeriesMapCount = 0;
    g_sSeriesTeamAName[0] = '\0';
    g_sSeriesTeamBName[0] = '\0';
    g_iVetoStep = 0;
    g_iVetoStepCount = 0;
    g_iVetoAction = -1;
    g_iVetoTeam = -1;
    g_sLastVetoMap[0] = '\0';
    g_iVetoAvailableCount = 0;
    g_iVetoBannedCount = 0;
    g_iVetoPickedCount = 0;
    g_iSeriesResultCount = 0;
    for (int i = 0; i < MAX_SERIES_MAPS; i++)
    {
        g_iResultMapIndex[i] = 0;
        g_sResultMap[i][0] = '\0';
        g_iResultScoreT[i] = 0;
        g_iResultScoreCT[i] = 0;
        g_iResultTeamAScore[i] = 0;
        g_iResultTeamBScore[i] = 0;
        g_iResultWinner[i] = view_as<int>(WarSeries_None);
        g_iResultTeamAWins[i] = 0;
        g_iResultTeamBWins[i] = 0;
    }
    for (int i = 0; i < MAX_SERIES_MAPS; i++)
    {
        g_sSeriesMaps[i][0] = '\0';
        g_sVetoAvailable[i][0] = '\0';
        g_sVetoBanned[i][0] = '\0';
        g_sVetoPicked[i][0] = '\0';
    }
}

void CaptureSeriesTeamNames()
{
    if (!NativeAvailable("DonutMatch.TeamName"))
        return;

    int teamASide = CS_TEAM_T;
    if (g_iSeriesMapIndex > 1 && (g_iSeriesMapIndex % 2) == 0)
        teamASide = CS_TEAM_CT;
    int teamBSide = (teamASide == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T;
    char name[128];

    if (g_sSeriesTeamAName[0] == '\0' && g_Match.TeamName(teamASide, name, sizeof(name))
        && name[0] != '\0' && !IsGenericSideName(name))
        strcopy(g_sSeriesTeamAName, sizeof(g_sSeriesTeamAName), name);
    if (g_sSeriesTeamBName[0] == '\0' && g_Match.TeamName(teamBSide, name, sizeof(name))
        && name[0] != '\0' && !IsGenericSideName(name))
        strcopy(g_sSeriesTeamBName, sizeof(g_sSeriesTeamBName), name);

    // Prefer the side-name cache captured during the match if the core currently
    // exposes generic labels (for example during the changelevel/reset callback).
    if (teamASide == CS_TEAM_T)
    {
        if (g_sSeriesTeamAName[0] == '\0' && g_sCachedTeamTName[0] != '\0')
            strcopy(g_sSeriesTeamAName, sizeof(g_sSeriesTeamAName), g_sCachedTeamTName);
        if (g_sSeriesTeamBName[0] == '\0' && g_sCachedTeamCTName[0] != '\0')
            strcopy(g_sSeriesTeamBName, sizeof(g_sSeriesTeamBName), g_sCachedTeamCTName);
    }
    else
    {
        if (g_sSeriesTeamAName[0] == '\0' && g_sCachedTeamCTName[0] != '\0')
            strcopy(g_sSeriesTeamAName, sizeof(g_sSeriesTeamAName), g_sCachedTeamCTName);
        if (g_sSeriesTeamBName[0] == '\0' && g_sCachedTeamTName[0] != '\0')
            strcopy(g_sSeriesTeamBName, sizeof(g_sSeriesTeamBName), g_sCachedTeamTName);
    }
}
void RefreshWarSeriesData()
{
    if (!IsWarSeriesActiveSafe())
        return;

    g_bSeriesActive = true;
    g_bSeriesScoreAvailable = IsBestOfFormat(g_iWarFormat);
    if (NativeAvailable("DonutMatch.WarSeriesWins"))
    {
        g_iSeriesWinsA = g_Match.WarSeriesWins(WarSeries_TeamA);
        g_iSeriesWinsB = g_Match.WarSeriesWins(WarSeries_TeamB);
    }
    if (NativeAvailable("DonutMatch.WarSeriesMapsToWin"))
        g_iSeriesMapsToWin = g_Match.WarSeriesMapsToWin();
    if (NativeAvailable("DonutMatch.WarSeriesMapIndex"))
        g_iSeriesMapIndex = g_Match.WarSeriesMapIndex() + 1;
    if (g_iSeriesBestOf == 0)
        g_iSeriesBestOf = BestOfFromFormat(g_iWarFormat);
    CaptureSeriesTeamNames();
}

void StoreMapList(ArrayList source, char destination[MAX_SERIES_MAPS][MAX_MAP_NAME], int &count)
{
    count = 0;
    if (source == null)
        return;

    for (int i = 0; i < source.Length && count < MAX_SERIES_MAPS; i++)
    {
        source.GetString(i, destination[count], MAX_MAP_NAME);
        if (destination[count][0] != '\0')
            count++;
    }
    delete source;
}

void RefreshVetoLists()
{
    if (!IsWarSeriesActiveSafe())
        return;

    if (NativeAvailable("DonutMatch.CurrentWarVetoAction"))
    {
        g_iVetoAction = view_as<int>(g_Match.CurrentWarVetoAction());
        g_bVetoActive = (g_iVetoAction != view_as<int>(WarVeto_None));
    }
    if (NativeAvailable("DonutMatch.CurrentWarVetoTeam"))
        g_iVetoTeam = view_as<int>(g_Match.CurrentWarVetoTeam());
    if (NativeAvailable("DonutMatch.GetWarVetoProgress"))
        g_Match.GetWarVetoProgress(g_iVetoStep, g_iVetoStepCount);

    if (NativeAvailable("DonutMatch.WarSeriesAvailableMaps"))
        StoreMapList(g_Match.WarSeriesAvailableMaps(), g_sVetoAvailable, g_iVetoAvailableCount);
    if (NativeAvailable("DonutMatch.WarSeriesBannedMaps"))
        StoreMapList(g_Match.WarSeriesBannedMaps(), g_sVetoBanned, g_iVetoBannedCount);
    if (NativeAvailable("DonutMatch.WarSeriesPickedMaps"))
        StoreMapList(g_Match.WarSeriesPickedMaps(), g_sVetoPicked, g_iVetoPickedCount);
}

void CaptureSeriesMaps()
{
    if (!NativeAvailable("DonutMatch.WarSeriesMaps"))
        return;
    StoreMapList(g_Match.WarSeriesMaps(), g_sSeriesMaps, g_iSeriesMapCount);
}

bool IsContinuingSeries()
{
    return g_sMatchId[0] != '\0'
        && IsBestOfFormat(g_iWarFormat)
        && g_bSeriesActive
        && IsWarSeriesActiveSafe();
}

void ScheduleStartupSync(float delay)
{
    if (g_hStartupSyncTimer != null)
        delete g_hStartupSyncTimer;
    g_hStartupSyncTimer = CreateTimer(delay, TimerStartupSync, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerStartupSync(Handle timer)
{
    if (timer == g_hStartupSyncTimer)
        g_hStartupSyncTimer = null;
    SyncCurrentCoreState();
    return Plugin_Stop;
}

void SyncCurrentCoreState()
{
    if (!LibraryExists("donutmatch"))
        return;

    RefreshModeAndFormatFromCore();
    MatchState state = State_ReadySystem;
    if (NativeAvailable("DonutMatch.State"))
        state = g_Match.State();

    bool live = false;
    if (NativeAvailable("DonutMatch.IsLive"))
        live = g_Match.IsLive();
    live = live || state == State_Live || state == State_Overtime;

    if (IsWarSeriesActiveSafe())
    {
        RefreshWarSeriesData();
        RefreshVetoLists();
    }

    if (live)
    {
        if (g_sMatchId[0] == '\0' || (!g_bMatchActive && !g_bSeriesVetoPreview && !IsContinuingSeries()))
            NewMatchId();
        g_bSeriesVetoPreview = false;
        g_bMatchActive = true;
        SetStatusFromState(state);
        ReadScoreFromCore();
        PublishSnapshot();
        return;
    }

    if (IsWarSeriesActiveSafe() && g_bVetoActive)
    {
        if (!g_bSeriesVetoPreview)
        {
            NewMatchId();
            g_bSeriesVetoPreview = true;
        }
        strcopy(g_sStatus, sizeof(g_sStatus), "veto");
        g_bHasVetoData = true;
        PublishSnapshot();
    }
}

void ReadScoreFromCore()
{
    if (!NativeAvailable("DonutMatch.TeamScore"))
        return;
    g_iLastScoreT = g_Match.TeamScore(CS_TEAM_T);
    g_iLastScoreCT = g_Match.TeamScore(CS_TEAM_CT);
}

void SetStatusFromState(MatchState state)
{
    if (state == State_Overtime)
        strcopy(g_sStatus, sizeof(g_sStatus), "overtime");
    else if (state == State_Live)
        strcopy(g_sStatus, sizeof(g_sStatus), "live");
    else if (state == State_Warmup)
        strcopy(g_sStatus, sizeof(g_sStatus), "warmup");
    else if (state == State_Starting)
        strcopy(g_sStatus, sizeof(g_sStatus), "starting");
    else if (state == State_CaptainKnife || state == State_KnifeRound_WAR)
        strcopy(g_sStatus, sizeof(g_sStatus), "knife");
    else if (state == State_PickingPlayers)
        strcopy(g_sStatus, sizeof(g_sStatus), "draft");
    else if (state == State_ReadySystem)
        strcopy(g_sStatus, sizeof(g_sStatus), "ready");
}

public void DonutMatch_OnMatchStart(const any[] data, int dataSize)
{
    int mode = view_as<int>(MODE_NONE);
    if (dataSize > 0)
        mode = data[0];

    int warFormat = view_as<int>(WarSeries_Unknown);
    int formatIndex = 2 + MAXPLAYERS * 2;
    if (dataSize > formatIndex)
        warFormat = data[formatIndex];
    SetModeAndFormat(mode, warFormat);

    bool useVetoPreviewId = g_bSeriesVetoPreview && g_sMatchId[0] != '\0';
    bool continuingSeries = IsBestOfFormat(g_iWarFormat) && g_bSeriesActive
        && IsWarSeriesActiveSafe() && g_sMatchId[0] != '\0';
    if (!useVetoPreviewId && !continuingSeries)
    {
        NewMatchId();
        g_sCachedTeamCTName[0] = '\0';
        g_sCachedTeamTName[0] = '\0';
    }
    g_bSeriesVetoPreview = false;
    g_bVetoActive = false;
    g_bMatchActive = true;
    g_iRound = 0;
    g_iLastScoreT = 0;
    g_iLastScoreCT = 0;
    g_sEndReason[0] = '\0';
    strcopy(g_sStatus, sizeof(g_sStatus), "live");
    CaptureCurrentTeamNames();

    if (IsWarSeriesActiveSafe())
    {
        RefreshWarSeriesData();
    }
    else
    {
        ClearSeriesState();
        // For old core binaries, no active War series means a Classic War match.
        if (g_iGameMode == view_as<int>(MODE_WAR) && !NativeAvailable("DonutMatch.WarMatchFormat"))
            g_iWarFormat = view_as<int>(WarSeries_Classic);
    }
    PublishSnapshot();
}

public void DonutMatch_OnMatchEnd(const any[] data, int dataSize)
{
    if (dataSize > 0)
        g_iGameMode = data[0];
    if (dataSize > 1)
        g_iLastScoreT = data[1];
    if (dataSize > 2)
        g_iLastScoreCT = data[2];
    if (dataSize > 3)
        SetModeAndFormat(g_iGameMode, data[3]);
    else
        RefreshFormatFromCore();

    CaptureCurrentTeamNames();
    CaptureLastMatchTeamNames();
    strcopy(g_sStatus, sizeof(g_sStatus), "finished");
    g_sEndReason[0] = '\0';
    g_bMatchActive = false;
    PublishSnapshot();
}

public void DonutMatch_OnTeamNameChanged(int team, const char[] name, int actor)
{
    RememberTeamName(team, name);
    if (g_bSeriesActive && name[0] != '\0' && !IsGenericSideName(name))
    {
        int teamASide = ((g_iSeriesMapIndex <= 1) || (g_iSeriesMapIndex % 2) == 1) ? CS_TEAM_T : CS_TEAM_CT;
        if (team == teamASide)
            strcopy(g_sSeriesTeamAName, sizeof(g_sSeriesTeamAName), name);
        else if (team == ((teamASide == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T))
            strcopy(g_sSeriesTeamBName, sizeof(g_sSeriesTeamBName), name);
    }
    if (g_bMatchActive || g_bSeriesVetoPreview)
        PublishSnapshot();
}

public void DonutMatch_OnMatchReset(const char[] reason)
{
    // The core fires a reset while loading the next map of a BO series.
    // The map result was already published by OnWarSeriesMapEnd, so don't
    // turn the ongoing series into a cancelled archive entry during changelevel.
    if (g_bSeriesActive && StrEqual(reason, "Смена карты."))
    {
        g_bMatchActive = false;
        return;
    }

    if (!g_bMatchActive && !g_bSeriesVetoPreview)
    {
        // A real core reset may cancel/clear a series; don't leave our cached flag set.
        if (!IsWarSeriesActiveSafe())
            g_bSeriesActive = false;
        return;
    }

    CaptureCurrentTeamNames();
    CaptureLastMatchTeamNames();
    strcopy(g_sStatus, sizeof(g_sStatus), "cancelled");
    strcopy(g_sEndReason, sizeof(g_sEndReason), reason);
    g_bMatchActive = false;
    g_bSeriesVetoPreview = false;
    PublishSnapshot();
}

public void DonutMatch_OnRoundScore(int scoreT, int scoreCT, int winnerTeam)
{
    if (!g_bMatchActive)
        return;
    g_iRound++;
    g_iLastScoreT = scoreT;
    g_iLastScoreCT = scoreCT;
    PublishSnapshot();
}

public void DonutMatch_OnScoreChanged(int scoreT, int scoreCT)
{
    if (!g_bMatchActive)
        return;
    g_iLastScoreT = scoreT;
    g_iLastScoreCT = scoreCT;
    PublishSnapshot();
}

public void DonutMatch_OnTeamsSwapped(int scoreT, int scoreCT)
{
    if (!g_bMatchActive)
        return;
    g_iLastScoreT = scoreT;
    g_iLastScoreCT = scoreCT;
    PublishSnapshot();
}

public void DonutMatch_OnStateChanged(MatchState oldState, MatchState newState)
{
    if (!g_bMatchActive && !g_bSeriesVetoPreview)
        return;

    if (g_bSeriesVetoPreview)
        strcopy(g_sStatus, sizeof(g_sStatus), "veto");
    else
        SetStatusFromState(newState);
    PublishSnapshot();
}

public void DonutMatch_OnWarSeriesStart(WarSeriesMode mode, int mapsToWin, int mapCount)
{
    ClearSeriesState();
    g_iGameMode = view_as<int>(MODE_WAR);
    g_iWarFormat = view_as<int>(mode);
    g_bSeriesActive = true;
    g_bSeriesScoreAvailable = IsBestOfFormat(g_iWarFormat);
    g_iSeriesBestOf = mapCount;
    g_iSeriesMapsToWin = mapsToWin;
    g_iSeriesMapIndex = 1;
    g_sCachedTeamCTName[0] = '\0';
    g_sCachedTeamTName[0] = '\0';
    CaptureCurrentTeamNames();
    CaptureSeriesTeamNames();

    NewMatchId();
    g_bSeriesVetoPreview = true;
    g_bMatchActive = false;
    strcopy(g_sStatus, sizeof(g_sStatus), "veto");
    g_sEndReason[0] = '\0';
    PublishSnapshot();
}

public void DonutMatch_OnWarVetoChoice(WarSeriesTeam team, WarVetoAction action, const char[] mapName, int step, int stepCount, int client, bool automatic)
{
    g_bHasVetoData = true;
    g_bVetoActive = true;
    g_iVetoTeam = view_as<int>(team);
    g_iVetoAction = view_as<int>(action);
    g_iVetoStep = step;
    g_iVetoStepCount = stepCount;
    g_bLastVetoAutomatic = automatic;
    strcopy(g_sLastVetoMap, sizeof(g_sLastVetoMap), mapName);
    RefreshVetoLists();
    if (g_bSeriesVetoPreview && g_sMatchId[0] != '\0')
        PublishSnapshot();
}

public void DonutMatch_OnWarSeriesVetoComplete()
{
    g_bVetoActive = false;
    g_bHasVetoData = true;
    CaptureSeriesMaps();
    RefreshVetoLists();
    if (g_bSeriesVetoPreview && g_sMatchId[0] != '\0')
        PublishSnapshot();
}

public void DonutMatch_OnWarSeriesMapEnd(int mapIndex, const char[] mapName, WarSeriesTeam winner, int scoreT, int scoreCT, int teamAWins, int teamBWins)
{
    g_bSeriesScoreAvailable = IsBestOfFormat(g_iWarFormat);
    g_iSeriesWinsA = teamAWins;
    g_iSeriesWinsB = teamBWins;
    g_iSeriesMapIndex = mapIndex + 1;
    g_iLastScoreT = scoreT;
    g_iLastScoreCT = scoreCT;

    if (mapIndex >= 0 && mapIndex < MAX_SERIES_MAPS)
    {
        int slot = mapIndex;
        if (slot >= g_iSeriesResultCount)
            g_iSeriesResultCount = slot + 1;
        g_iResultMapIndex[slot] = mapIndex + 1;
        strcopy(g_sResultMap[slot], sizeof(g_sResultMap[]), mapName);
        g_iResultScoreT[slot] = scoreT;
        g_iResultScoreCT[slot] = scoreCT;
        // CS side is not a stable team identity: captain side-pick/knife can alter
        // which War team plays CT/T. The core's winner enum is the authoritative
        // identity, so map the high/low score to Team A/B via that winner.
        if (winner == WarSeries_TeamA)
        {
            g_iResultTeamAScore[slot] = (scoreT >= scoreCT) ? scoreT : scoreCT;
            g_iResultTeamBScore[slot] = (scoreT >= scoreCT) ? scoreCT : scoreT;
        }
        else if (winner == WarSeries_TeamB)
        {
            g_iResultTeamAScore[slot] = (scoreT <= scoreCT) ? scoreT : scoreCT;
            g_iResultTeamBScore[slot] = (scoreT <= scoreCT) ? scoreCT : scoreT;
        }
        else
        {
            // Tied map: there is no winner to identify the sides; preserve raw score order.
            bool teamAOnT = (mapIndex % 2) == 0;
            g_iResultTeamAScore[slot] = teamAOnT ? scoreT : scoreCT;
            g_iResultTeamBScore[slot] = teamAOnT ? scoreCT : scoreT;
        }
        g_iResultWinner[slot] = view_as<int>(winner);
        g_iResultTeamAWins[slot] = teamAWins;
        g_iResultTeamBWins[slot] = teamBWins;
    }

    g_bMatchActive = false;
    g_bSeriesActive = IsWarSeriesActiveSafe();
    if (g_bSeriesActive)
        RefreshWarSeriesData();
    strcopy(g_sStatus, sizeof(g_sStatus), "finished");
    PublishSnapshot();
}

public void DonutMatch_OnWarSeriesEnd(WarSeriesTeam winner, int teamAWins, int teamBWins)
{
    g_bSeriesScoreAvailable = IsBestOfFormat(g_iWarFormat);
    g_iSeriesWinsA = teamAWins;
    g_iSeriesWinsB = teamBWins;
    g_bSeriesActive = false;
    g_bMatchActive = false;
    strcopy(g_sStatus, sizeof(g_sStatus), "finished");
    CaptureSeriesTeamNames();
    PublishSnapshot();
}

public Action Command_ForceSync(int client, int args)
{
    SyncCurrentCoreState();
    if (!g_bMatchActive && !g_bSeriesVetoPreview)
    {
        ReplyToCommand(client, "[DonutMatch Web] Нет активного матча или veto серии для отправки.");
        return Plugin_Handled;
    }
    PublishSnapshot();
    ReplyToCommand(client, "[DonutMatch Web] Снимок DonutMatch отправляется в API.");
    return Plugin_Handled;
}

void PublishSnapshot()
{
    if (g_sApiUrl[0] == '\0' || g_sToken[0] == '\0')
    {
        LogError("Web bridge is not configured: set sm_donutmatch_web_url and sm_donutmatch_web_token in cfg/sourcemod/donutmatch_web.cfg");
        return;
    }
    if (g_bRequestPending)
    {
        g_bSnapshotDirty = true;
        return;
    }

    char map[PLATFORM_MAX_PATH], ctName[128], tName[128], timestamp[32];
    GetCurrentMap(map, sizeof(map));
    ResolveTeamNames(ctName, sizeof(ctName), tName, sizeof(tName));

    // The core clears its active-series state before/while the terminal forwards run.
    // Preserve the format captured from DonutMatch_OnMatchEnd / OnWarSeriesEnd so a
    // completed BO3/BO5 snapshot cannot be downgraded to Classic during serialization.
    bool terminalSnapshot = StrEqual(g_sStatus, "finished") || StrEqual(g_sStatus, "cancelled");
    if (g_iGameMode == view_as<int>(MODE_WAR) && !terminalSnapshot)
        RefreshFormatFromCore();
    if (g_bSeriesActive && !terminalSnapshot)
        RefreshWarSeriesData();
    if (g_bHasVetoData && (g_bSeriesVetoPreview || g_bSeriesActive))
        RefreshVetoLists();
    FormatApiTimestamp(timestamp, sizeof(timestamp));
    if (g_sMatchId[0] == '\0')
        NewMatchId();

    JSONObject match = new JSONObject();
    match.SetString("id", g_sMatchId);
    if (IsBestOfFormat(g_iWarFormat) || g_bSeriesActive || g_bSeriesVetoPreview || g_iSeriesResultCount > 0)
        match.SetString("series_id", g_sMatchId);
    match.SetString("status", g_sStatus);
    match.SetString("map", map);
    match.SetString("mode", FormatGameMode(g_iGameMode));
    char matchType[16];
    FormatMatchType(g_iGameMode, g_iWarFormat, matchType, sizeof(matchType));
    match.SetString("match_type", matchType);
    match.SetString("end_reason", g_sEndReason);

    JSONObject teamCT = new JSONObject();
    teamCT.SetString("name", ctName);
    teamCT.SetInt("score", g_iLastScoreCT);
    match.Set("team_ct", teamCT);
    delete teamCT;

    JSONObject teamT = new JSONObject();
    teamT.SetString("name", tName);
    teamT.SetInt("score", g_iLastScoreT);
    match.Set("team_t", teamT);
    delete teamT;

    JSONArray playersCT = BuildTeamPlayers(CS_TEAM_CT);
    match.Set("players_ct", playersCT);
    delete playersCT;
    JSONArray playersT = BuildTeamPlayers(CS_TEAM_T);
    match.Set("players_t", playersT);
    delete playersT;

    match.SetInt("round", g_iRound);
    match.SetString("updated_at", timestamp);
    match.SetBool("series_active", g_bSeriesActive);
    if (g_sSeriesTeamAName[0] != '\0')
        match.SetString("series_team_a_name", g_sSeriesTeamAName);
    if (g_sSeriesTeamBName[0] != '\0')
        match.SetString("series_team_b_name", g_sSeriesTeamBName);
    if (g_bSeriesScoreAvailable && IsBestOfFormat(g_iWarFormat))
    {
        match.SetInt("series_map_index", g_iSeriesMapIndex);
        match.SetInt("series_best_of", g_iSeriesBestOf > 0 ? g_iSeriesBestOf : BestOfFromFormat(g_iWarFormat));
        match.SetInt("series_maps_to_win", g_iSeriesMapsToWin);

        // A score object must never contain invented labels.
        if (g_sSeriesTeamAName[0] != '\0' && g_sSeriesTeamBName[0] != '\0')
        {
            JSONObject seriesScore = new JSONObject();
            JSONObject seriesTeamA = new JSONObject();
            seriesTeamA.SetString("name", g_sSeriesTeamAName);
            seriesTeamA.SetInt("wins", g_iSeriesWinsA);
            JSONObject seriesTeamB = new JSONObject();
            seriesTeamB.SetString("name", g_sSeriesTeamBName);
            seriesTeamB.SetInt("wins", g_iSeriesWinsB);
            seriesScore.Set("team_a", seriesTeamA);
            seriesScore.Set("team_b", seriesTeamB);
            match.Set("series_score", seriesScore);
            delete seriesTeamA;
            delete seriesTeamB;
            delete seriesScore;
        }

        JSONArray seriesMaps = BuildMapArray(g_sSeriesMaps, g_iSeriesMapCount);
        match.Set("series_maps", seriesMaps);
        delete seriesMaps;
    }

    if (g_iSeriesResultCount > 0)
    {
        JSONArray results = new JSONArray();
        for (int i = 0; i < g_iSeriesResultCount && i < MAX_SERIES_MAPS; i++)
        {
            if (g_sResultMap[i][0] == '\0')
                continue;
            JSONObject item = new JSONObject();
            item.SetInt("map_index", g_iResultMapIndex[i]);
            item.SetString("map", g_sResultMap[i]);
            item.SetInt("score_t", g_iResultScoreT[i]);
            item.SetInt("score_ct", g_iResultScoreCT[i]);
            item.SetInt("team_a_score", g_iResultTeamAScore[i]);
            item.SetInt("team_b_score", g_iResultTeamBScore[i]);
            if (g_iResultWinner[i] == view_as<int>(WarSeries_TeamA))
                item.SetString("winner", "team_a");
            else if (g_iResultWinner[i] == view_as<int>(WarSeries_TeamB))
                item.SetString("winner", "team_b");
            else
                item.SetString("winner", "draw");
            item.SetInt("team_a_wins", g_iResultTeamAWins[i]);
            item.SetInt("team_b_wins", g_iResultTeamBWins[i]);
            results.Push(item);
            delete item;
        }
        match.Set("series_results", results);
        delete results;
    }

    if (g_bHasVetoData)
    {
        JSONObject veto = new JSONObject();
        veto.SetBool("active", g_bVetoActive && g_bSeriesVetoPreview);
        veto.SetInt("step", g_iVetoStep);
        veto.SetInt("step_count", g_iVetoStepCount);
        veto.SetString("action", FormatVetoAction(g_iVetoAction));
        veto.SetString("team", FormatVetoTeam(g_iVetoTeam));
        veto.SetString("last_map", g_sLastVetoMap);
        veto.SetBool("automatic", g_bLastVetoAutomatic);
        JSONArray available = BuildMapArray(g_sVetoAvailable, g_iVetoAvailableCount);
        JSONArray banned = BuildMapArray(g_sVetoBanned, g_iVetoBannedCount);
        JSONArray picked = BuildMapArray(g_sVetoPicked, g_iVetoPickedCount);
        veto.Set("available_maps", available);
        veto.Set("banned_maps", banned);
        veto.Set("picked_maps", picked);
        match.Set("veto", veto);
        delete available;
        delete banned;
        delete picked;
        delete veto;
    }

    JSONObject body = new JSONObject();
    body.SetString("type", "match.updated");
    body.Set("match", match);
    delete match;

    HTTPRequest request = new HTTPRequest(g_sApiUrl);
    request.SetHeader("Authorization", "Bearer %s", g_sToken);
    request.SetHeader("Content-Type", "application/json");
    request.Timeout = 8;
    request.ConnectTimeout = 3;
    g_bRequestPending = true;
    request.Post(body, OnHttpComplete);
    delete body;
}

JSONArray BuildTeamPlayers(int team)
{
    JSONArray result = new JSONArray();
    if (!NativeAvailable("DonutMatch.TeamPlayers") || !NativeAvailable("MatchPlayer.IsValid")
        || !NativeAvailable("MatchPlayer.Name") || !NativeAvailable("MatchPlayer.Frags")
        || !NativeAvailable("MatchPlayer.Deaths"))
        return result;

    ArrayList clients = g_Match.TeamPlayers(team);
    if (clients == null)
        return result;

    for (int i = 0; i < clients.Length; i++)
    {
        int client = clients.Get(i);
        MatchPlayer player = new MatchPlayer(client);
        if (!player.IsValid())
            continue;

        char playerName[MAX_NAME_LENGTH];
        if (!player.Name(playerName, sizeof(playerName)) || playerName[0] == '\0')
            continue;

        JSONObject item = new JSONObject();
        item.SetString("name", playerName);
        if (NativeAvailable("MatchPlayer.AuthId"))
        {
            char authId[40];
            if (player.AuthId(authId, sizeof(authId)) && authId[0] != '\0')
                item.SetString("auth_id", authId);
        }
        item.SetInt("kills", player.Frags());
        item.SetInt("deaths", player.Deaths());
        item.SetBool("stats_available", true);
        result.Push(item);
        delete item;
    }
    delete clients;
    return result;
}

JSONArray BuildMapArray(char maps[MAX_SERIES_MAPS][MAX_MAP_NAME], int count)
{
    JSONArray result = new JSONArray();
    for (int i = 0; i < count && i < MAX_SERIES_MAPS; i++)
    {
        if (maps[i][0] != '\0')
            result.PushString(maps[i]);
    }
    return result;
}

void FormatApiTimestamp(char[] buffer, int maxlen)
{
    int now = GetTime();
    char localTime[24], timezone[8];
    FormatTime(localTime, sizeof(localTime), "%Y-%m-%dT%H:%M:%S", now);
    FormatTime(timezone, sizeof(timezone), "%z", now);
    if (strlen(timezone) == 5 && (timezone[0] == '+' || timezone[0] == '-'))
    {
        FormatEx(buffer, maxlen, "%s%c%c%c:%c%c", localTime,
            timezone[0], timezone[1], timezone[2], timezone[3], timezone[4]);
        return;
    }
    FormatEx(buffer, maxlen, "%sZ", localTime);
}

void FormatMatchType(int mode, int format, char[] buffer, int maxlen)
{
    if (mode != view_as<int>(MODE_WAR))
    {
        buffer[0] = '\0';
        return;
    }
    switch (format)
    {
        case view_as<int>(WarSeries_Classic): strcopy(buffer, maxlen, "Classic");
        case view_as<int>(WarSeries_BO1): strcopy(buffer, maxlen, "BO1");
        case view_as<int>(WarSeries_BO3): strcopy(buffer, maxlen, "BO3");
        case view_as<int>(WarSeries_BO5): strcopy(buffer, maxlen, "BO5");
        default: buffer[0] = '\0';
    }
}

char[] FormatGameMode(int mode)
{
    static char buffer[16];
    if (mode == view_as<int>(MODE_WAR)) strcopy(buffer, sizeof(buffer), "War");
    else if (mode == view_as<int>(MODE_MIX)) strcopy(buffer, sizeof(buffer), "Mix");
    else strcopy(buffer, sizeof(buffer), "Unknown");
    return buffer;
}

char[] FormatVetoAction(int action)
{
    static char buffer[16];
    if (action == view_as<int>(WarVeto_Ban)) strcopy(buffer, sizeof(buffer), "ban");
    else if (action == view_as<int>(WarVeto_Pick)) strcopy(buffer, sizeof(buffer), "pick");
    else buffer[0] = '\0';
    return buffer;
}

char[] FormatVetoTeam(int team)
{
    static char buffer[128];
    if (team == view_as<int>(WarSeries_TeamA))
        strcopy(buffer, sizeof(buffer), g_sSeriesTeamAName);
    else if (team == view_as<int>(WarSeries_TeamB))
        strcopy(buffer, sizeof(buffer), g_sSeriesTeamBName);
    else
        buffer[0] = '\0';
    return buffer;
}

public void OnHttpComplete(HTTPResponse response, any value, const char[] error)
{
    g_bRequestPending = false;
    bool requestFailed = false;
    if (error[0] != '\0')
    {
        requestFailed = true;
        LogError("Dashboard request failed: %s", error);
        CreateTimer(5.0, TimerRetrySnapshot, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        int status = view_as<int>(response.Status);
        if (status < 200 || status >= 300)
        {
            requestFailed = true;
            LogError("Dashboard API returned HTTP %d", status);
            CreateTimer(5.0, TimerRetrySnapshot, _, TIMER_FLAG_NO_MAPCHANGE);
        }
        else
        {
            LogMessage("Dashboard updated (HTTP %d)", status);
        }
    }

    if (g_bSnapshotDirty)
    {
        g_bSnapshotDirty = false;
        if (!requestFailed)
            PublishSnapshot();
    }
}

public Action TimerRetrySnapshot(Handle timer)
{
    PublishSnapshot();
    return Plugin_Stop;
}
