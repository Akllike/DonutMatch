#include <sourcemod>
#include <donutmatch>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "DonutMatch API examples",
    author = "phenom",
    description = "Примеры использования methodmap API и форвардов DonutMatch",
    version = "1.0.0",
    url = "https://t.me/phenom1337"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("DonutMatch.IsLive");
    MarkNativeAsOptional("DonutMatch.State");
    MarkNativeAsOptional("DonutMatch.Mode");
    MarkNativeAsOptional("DonutMatch.IsReady");
    MarkNativeAsOptional("DonutMatch.GetScore");
    MarkNativeAsOptional("DonutMatch.Start");
    MarkNativeAsOptional("DonutMatch.Stop");
    MarkNativeAsOptional("DonutMatch.SwapTeams");
    MarkNativeAsOptional("DonutMatch.PlayersPerSide");
    MarkNativeAsOptional("DonutMatch.LivePlayers");
    MarkNativeAsOptional("DonutMatch.IsPlayerInMatch");
    MarkNativeAsOptional("DonutMatch.Captain");
    MarkNativeAsOptional("DonutMatch.MaxRounds");
    MarkNativeAsOptional("DonutMatch.HalftimeScore");
    MarkNativeAsOptional("DonutMatch.TeamName");
    MarkNativeAsOptional("DonutMatch.SetTeamName");
    MarkNativeAsOptional("DonutMatch.TeamScore");
    MarkNativeAsOptional("DonutMatch.TeamPlayers");
    MarkNativeAsOptional("DonutMatch.QueuedPlayers");
    MarkNativeAsOptional("DonutMatch.OpenSlots");
    MarkNativeAsOptional("DonutMatch.MissingPlayersToStart");
    MarkNativeAsOptional("DonutMatch.CanStart");
    MarkNativeAsOptional("DonutMatch.GetOvertimeVote");
    MarkNativeAsOptional("DonutMatch.StartOvertime");
    MarkNativeAsOptional("DonutMatch.DatabaseStatus");
    MarkNativeAsOptional("DonutMatch.LogEvent");
    MarkNativeAsOptional("DonutMatch.HasLastMatch");
    MarkNativeAsOptional("DonutMatch.LastMatchMode");
    MarkNativeAsOptional("DonutMatch.GetLastMatchScore");
    MarkNativeAsOptional("DonutMatch.LastTeamName");
    MarkNativeAsOptional("DonutMatch.WarSeriesMode");
    MarkNativeAsOptional("DonutMatch.IsWarSeriesActive");
    MarkNativeAsOptional("DonutMatch.WarSeriesWins");
    MarkNativeAsOptional("DonutMatch.WarSeriesMapsToWin");
    MarkNativeAsOptional("DonutMatch.WarSeriesMapIndex");
    MarkNativeAsOptional("DonutMatch.CurrentWarVetoAction");
    MarkNativeAsOptional("DonutMatch.CurrentWarVetoTeam");
    MarkNativeAsOptional("DonutMatch.CurrentWarVetoCaptain");
    MarkNativeAsOptional("DonutMatch.GetWarVetoProgress");
    MarkNativeAsOptional("DonutMatch.WarSeriesMapPool");
    MarkNativeAsOptional("DonutMatch.WarSeriesAvailableMaps");
    MarkNativeAsOptional("DonutMatch.WarSeriesBannedMaps");
    MarkNativeAsOptional("DonutMatch.WarSeriesPickedMaps");
    MarkNativeAsOptional("DonutMatch.WarSeriesMaps");
    MarkNativeAsOptional("DonutMatch.SetWarSeriesMode");
    MarkNativeAsOptional("DonutMatch.SetWarSeriesMapPool");
    MarkNativeAsOptional("DonutMatch.ChooseWarVetoMap");
    MarkNativeAsOptional("MatchPlayer.IsValid");
    MarkNativeAsOptional("MatchPlayer.IsReady");
    MarkNativeAsOptional("MatchPlayer.SetReady");
    MarkNativeAsOptional("MatchPlayer.IsInRoster");
    MarkNativeAsOptional("MatchPlayer.IsCaptain");
    MarkNativeAsOptional("MatchPlayer.Team");
    MarkNativeAsOptional("MatchPlayer.Frags");
    MarkNativeAsOptional("MatchPlayer.Deaths");
    MarkNativeAsOptional("MatchPlayer.AssignToTeam");
    MarkNativeAsOptional("MatchPlayer.RemoveFromRoster");
    MarkNativeAsOptional("MatchPlayer.UserId");
    MarkNativeAsOptional("MatchPlayer.AuthId");
    MarkNativeAsOptional("MatchPlayer.Name");
    MarkNativeAsOptional("MatchPlayer.IsAlive");
    MarkNativeAsOptional("MatchPlayer.Money");
    MarkNativeAsOptional("MatchPlayer.DamageTo");
    MarkNativeAsOptional("MatchPlayer.HitsTo");
    MarkNativeAsOptional("MatchPlayer.PendingSubstituteRequester");
    MarkNativeAsOptional("MatchPlayer.PendingSubstituteTarget");
    MarkNativeAsOptional("MatchPlayer.AskForSubstitute");
    MarkNativeAsOptional("MatchDraft.IsActive");
    MarkNativeAsOptional("MatchDraft.CandidateCount");
    MarkNativeAsOptional("MatchDraft.CurrentPicker");
    MarkNativeAsOptional("MatchDraft.Candidates");
    MarkNativeAsOptional("MatchDraft.ForcePick");
    MarkNativeAsOptional("MatchDraft.Finish");
    MarkNativeAsOptional("MatchDraft.ChooseSide");
    return APLRes_Success;
}

bool g_bDonutMatchAvailable;
DonutMatch g_DonutMatch;

public void OnPluginStart()
{
    g_DonutMatch = new DonutMatch();
    // API подключен как необязательный: пример может загрузиться раньше DonutMatch.
    g_bDonutMatchAvailable = LibraryExists("donutmatch");

    RegConsoleCmd("sm_dm_example_status", Command_ExampleStatus, "Показать пример чтения состояния и данных матча DonutMatch");
    RegConsoleCmd("sm_dm_example_readyinfo", Command_ExampleReadyInfo, "Проверить статус готовности: sm_dm_example_readyinfo <игрок>");
    RegAdminCmd("sm_dm_example_setready", Command_ExampleSetReady, ADMFLAG_GENERIC, "Пример установки готовности: sm_dm_example_setready <игрок> <0|1>");
    RegConsoleCmd("sm_dm_example_roster", Command_ExampleRoster, "Показать пример чтения состава матча");
    RegAdminCmd("sm_dm_example_swap", Command_ExampleSwapTeams, ADMFLAG_GENERIC, "Пример смены сторон через DonutMatch API");
    RegConsoleCmd("sm_dm_example_war", Command_ExampleWar, "Показать состояние War-серии и veto");
    RegAdminCmd("sm_dm_example_setseries", Command_ExampleSetWarSeriesMode, ADMFLAG_GENERIC, "Установить формат War: sm_dm_example_setseries <0|1|2>");
    RegAdminCmd("sm_dm_example_mappool", Command_ExampleSetWarMapPool, ADMFLAG_GENERIC, "Задать пул карт: sm_dm_example_mappool <map1,map2,...>");
    RegAdminCmd("sm_dm_example_veto", Command_ExampleChooseWarVetoMap, ADMFLAG_GENERIC, "Пример выбора текущего шага veto: sm_dm_example_veto <map>");
    RegAdminCmd("sm_dm_example_forcestart", Command_ExampleForceStart, ADMFLAG_GENERIC, "Пример вызова DonutMatch_ForceStart");
    RegAdminCmd("sm_dm_example_forcestop", Command_ExampleForceStop, ADMFLAG_GENERIC, "Пример вызова DonutMatch_ForceStop");
    RegConsoleCmd("sm_dm_example_draft", Command_ExampleDraft, "Показать состояние Mix-драфта и кандидатов");
    RegAdminCmd("sm_dm_example_draftpick", Command_ExampleDraftPick, ADMFLAG_GENERIC, "Принудительно выбрать кандидата: sm_dm_example_draftpick <игрок>");
    RegAdminCmd("sm_dm_example_draftfinish", Command_ExampleDraftFinish, ADMFLAG_GENERIC, "Принудительно завершить драфт Mix");
    RegAdminCmd("sm_dm_example_chooseside", Command_ExampleChooseSide, ADMFLAG_GENERIC, "Выбрать сторону после ножевого раунда: sm_dm_example_chooseside <2|3>");
    RegAdminCmd("sm_dm_example_teamname", Command_ExampleTeamName, ADMFLAG_GENERIC, "Задать имя своей команды: sm_dm_example_teamname <2|3> <name>");
    RegAdminCmd("sm_dm_example_overtime", Command_ExampleOvertime, ADMFLAG_GENERIC, "Запустить настроенное голосование/начало OT, если матч завершился вничью");
    RegAdminCmd("sm_dm_example_logevent", Command_ExampleLogEvent, ADMFLAG_GENERIC, "Добавить демонстрационное событие в лог DonutMatch");
    RegAdminCmd("sm_dm_example_assign", Command_ExampleAssign, ADMFLAG_GENERIC, "Добавить игрока на команду: sm_dm_example_assign <игрок> <2|3>");
    RegAdminCmd("sm_dm_example_remove", Command_ExampleRemove, ADMFLAG_GENERIC, "Убрать игрока из состава до матча: sm_dm_example_remove <игрок>");
    RegConsoleCmd("sm_dm_example_ask", Command_ExampleAsk, "Открыть штатный запрос замены через MatchPlayer.AskForSubstitute");
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "donutmatch"))
    {
        g_bDonutMatchAvailable = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "donutmatch"))
    {
        g_bDonutMatchAvailable = false;
    }
}

bool RequireDonutMatch(int client)
{
    if (g_bDonutMatchAvailable)
    {
        return true;
    }

    ReplyToCommand(client, "[DonutMatch API examples] Плагин donut_match.smx не загружен.");
    return false;
}

public Action Command_ExampleStatus(int client, int args)
{
    if (!RequireDonutMatch(client))
    {
        return Plugin_Handled;
    }

    // Простые нативы состояния и режима матча.
    bool live = g_DonutMatch.IsLive();
    MatchState state = g_DonutMatch.State();
    GameMode mode = g_DonutMatch.Mode();
    int playersPerSide = g_DonutMatch.PlayersPerSide();

    char stateName[32], modeName[16];
    DonutMatch_GetStateName(state, stateName, sizeof(stateName));
    DonutMatch_GetModeName(mode, modeName, sizeof(modeName));

    // Получение счета передает значения через ссылки на переменные.
    int scoreT, scoreCT;
    g_DonutMatch.GetScore(scoreT, scoreCT);

    // Капитаны возвращаются как индекс клиента; 0 означает, что капитан не определён.
    int captainT = g_DonutMatch.Captain(2);
    int captainCT = g_DonutMatch.Captain(3);

    // Пример получения названий команд. Для стандартных имен API также вернет строку.
    char teamT[64], teamCT[64];
    bool hasTeamT = g_DonutMatch.TeamName(2, teamT, sizeof(teamT));
    bool hasTeamCT = g_DonutMatch.TeamName(3, teamCT, sizeof(teamCT));
    int teamScoreT = g_DonutMatch.TeamScore(2);
    int teamScoreCT = g_DonutMatch.TeamScore(3);
    char captainNameT[MAX_NAME_LENGTH] = "не определен";
    char captainNameCT[MAX_NAME_LENGTH] = "не определен";
    if (captainT > 0 && IsClientInGame(captainT))
    {
        GetClientName(captainT, captainNameT, sizeof(captainNameT));
    }
    if (captainCT > 0 && IsClientInGame(captainCT))
    {
        GetClientName(captainCT, captainNameCT, sizeof(captainNameCT));
    }

    // Максимум основного времени и овертайма; у OT есть дополнительный решающий раунд.
    int regulationMaxRounds = g_DonutMatch.MaxRounds();
    int overtimeMaxRounds = g_DonutMatch.MaxRounds(true);

    // Счет последнего перерыва до смены сторон; для OT передаем true.
    int halfT = g_DonutMatch.HalftimeScore(2);
    int halfCT = g_DonutMatch.HalftimeScore(3);
    int overtimeHalfT = g_DonutMatch.HalftimeScore(2, true);
    int overtimeHalfCT = g_DonutMatch.HalftimeScore(3, true);
    int waiting = g_DonutMatch.MissingPlayersToStart();
    bool canStart = g_DonutMatch.CanStart();
    int openT = g_DonutMatch.OpenSlots(2), openCT = g_DonutMatch.OpenSlots(3);
    int yesVotes, noVotes, eligibleVotes;
    bool voting = g_DonutMatch.GetOvertimeVote(yesVotes, noVotes, eligibleVotes);
    MatchDatabaseStatus database = g_DonutMatch.DatabaseStatus();

    ReplyToCommand(client, "[DM API] live=%d mode=%s state=%s format=%dv%d score=%d:%d", live, modeName, stateName, playersPerSide, playersPerSide, scoreT, scoreCT);
    ReplyToCommand(client, "[DM API] captains T='%s' CT='%s' | teams T='%s' CT='%s'", captainNameT, captainNameCT, hasTeamT ? teamT : "?", hasTeamCT ? teamCT : "?");
    ReplyToCommand(client, "[DM API] TeamScore T/CT=%d/%d", teamScoreT, teamScoreCT);
    ReplyToCommand(client, "[DM API] max rounds regulation=%d OT=%d | last half=%d:%d OT half=%d:%d", regulationMaxRounds, overtimeMaxRounds, halfT, halfCT, overtimeHalfT, overtimeHalfCT);
    ReplyToCommand(client, "[DM API] missing=%d canStart=%d openSlots T/CT=%d/%d dbStatus=%d OT vote=%d (%d yes, %d no / %d eligible)",
        waiting, canStart, openT, openCT, database, voting, yesVotes, noVotes, eligibleVotes);

    ArrayList teamPlayers = g_DonutMatch.TeamPlayers(2);
    ArrayList queuedPlayers = g_DonutMatch.QueuedPlayers();
    ReplyToCommand(client, "[DM API] team T players=%d queued spectators=%d", teamPlayers.Length, queuedPlayers.Length);
    delete teamPlayers;
    delete queuedPlayers;

    if (g_DonutMatch.HasLastMatch())
    {
        int lastT, lastCT;
        char lastTeamT[64], lastTeamCT[64];
        g_DonutMatch.GetLastMatchScore(lastT, lastCT);
        bool hasLastTeamT = g_DonutMatch.LastTeamName(2, lastTeamT, sizeof(lastTeamT));
        bool hasLastTeamCT = g_DonutMatch.LastTeamName(3, lastTeamCT, sizeof(lastTeamCT));
        ReplyToCommand(client, "[DM API] last match mode=%d score=%d:%d names T='%s' CT='%s'",
            g_DonutMatch.LastMatchMode(), lastT, lastCT,
            hasLastTeamT ? lastTeamT : "?", hasLastTeamCT ? lastTeamCT : "?");
    }

    // Native DonutMatch_GetPlayerReady показан отдельной командой ниже, потому что
    // для него нужен индекс конкретного игрока.
    return Plugin_Handled;
}

public Action Command_ExampleSwapTeams(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;
    ReplyToCommand(client, "[DM API] SwapTeams() => %d", g_DonutMatch.SwapTeams());
    return Plugin_Handled;
}

public Action Command_ExampleWar(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;

    int vetoStep, vetoStepCount;
    g_DonutMatch.GetWarVetoProgress(vetoStep, vetoStepCount);
    ReplyToCommand(client, "[DM API] War active=%d mode=%d wins A/B=%d/%d mapsToWin=%d mapIndex=%d",
        g_DonutMatch.IsWarSeriesActive(), g_DonutMatch.WarSeriesMode(),
        g_DonutMatch.WarSeriesWins(WarSeries_TeamA), g_DonutMatch.WarSeriesWins(WarSeries_TeamB),
        g_DonutMatch.WarSeriesMapsToWin(), g_DonutMatch.WarSeriesMapIndex());
    ReplyToCommand(client, "[DM API] veto action=%d team=%d captain=%d step=%d/%d",
        g_DonutMatch.CurrentWarVetoAction(), g_DonutMatch.CurrentWarVetoTeam(),
        g_DonutMatch.CurrentWarVetoCaptain(), vetoStep, vetoStepCount);

    ArrayList mapPool = g_DonutMatch.WarSeriesMapPool();
    ArrayList availableMaps = g_DonutMatch.WarSeriesAvailableMaps();
    ArrayList bannedMaps = g_DonutMatch.WarSeriesBannedMaps();
    ArrayList pickedMaps = g_DonutMatch.WarSeriesPickedMaps();
    ArrayList seriesMaps = g_DonutMatch.WarSeriesMaps();
    ReplyToCommand(client, "[DM API] maps pool/available/banned/picked/order=%d/%d/%d/%d/%d",
        mapPool.Length, availableMaps.Length, bannedMaps.Length, pickedMaps.Length, seriesMaps.Length);
    PrintExampleMapList(client, "pool", mapPool);
    PrintExampleMapList(client, "available", availableMaps);
    PrintExampleMapList(client, "banned", bannedMaps);
    PrintExampleMapList(client, "picked", pickedMaps);
    PrintExampleMapList(client, "series", seriesMaps);
    delete mapPool;
    delete availableMaps;
    delete bannedMaps;
    delete pickedMaps;
    delete seriesMaps;
    return Plugin_Handled;
}

void PrintExampleMapList(int client, const char[] label, ArrayList maps)
{
    char mapName[PLATFORM_MAX_PATH];
    for (int i = 0; i < maps.Length; i++)
    {
        maps.GetString(i, mapName, sizeof(mapName));
        ReplyToCommand(client, "  %s[%d]=%s", label, i, mapName);
    }
}

public Action Command_ExampleSetWarSeriesMode(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_dm_example_setseries <0|1|2>");
        return Plugin_Handled;
    }

    char modeArg[8];
    GetCmdArg(1, modeArg, sizeof(modeArg));
    int mode = StringToInt(modeArg);
    if (mode < view_as<int>(WarSeries_BO1) || mode > view_as<int>(WarSeries_BO5))
    {
        ReplyToCommand(client, "[DM API] Формат должен быть 0 (BO1), 1 (BO3) или 2 (BO5).");
        return Plugin_Handled;
    }
    ReplyToCommand(client, "[DM API] SetWarSeriesMode(%d) => %d",
        mode, g_DonutMatch.SetWarSeriesMode(view_as<WarSeriesMode>(mode)));
    return Plugin_Handled;
}

public Action Command_ExampleSetWarMapPool(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_dm_example_mappool <map1,map2,...>");
        return Plugin_Handled;
    }

    char mapPool[256];
    GetCmdArg(1, mapPool, sizeof(mapPool));
    ReplyToCommand(client, "[DM API] SetWarSeriesMapPool => %d",
        g_DonutMatch.SetWarSeriesMapPool(mapPool));
    return Plugin_Handled;
}

public Action Command_ExampleChooseWarVetoMap(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_dm_example_veto <map>");
        return Plugin_Handled;
    }

    int captain = g_DonutMatch.CurrentWarVetoCaptain();
    if (captain <= 0)
    {
        ReplyToCommand(client, "[DM API] Сейчас нет активного выбора veto.");
        return Plugin_Handled;
    }
    char mapName[PLATFORM_MAX_PATH];
    GetCmdArg(1, mapName, sizeof(mapName));
    ReplyToCommand(client, "[DM API] ChooseWarVetoMap(captain=%d, map=%s) => %d",
        captain, mapName, g_DonutMatch.ChooseWarVetoMap(captain, mapName));
    return Plugin_Handled;
}

public Action Command_ExampleReadyInfo(int client, int args)
{
    if (!RequireDonutMatch(client))
    {
        return Plugin_Handled;
    }

    int target;
    if (args == 0 && client > 0)
    {
        target = client;
    }
    else if (args > 0)
    {
        char targetArg[MAX_TARGET_LENGTH];
        GetCmdArg(1, targetArg, sizeof(targetArg));
        target = FindTarget(client, targetArg, true, false);
    }
    else
    {
        ReplyToCommand(client, "Использование: sm_dm_example_readyinfo <игрок>");
        return Plugin_Handled;
    }

    if (target <= 0)
    {
        return Plugin_Handled;
    }

    // Проверяем готовность конкретного игрока.
    MatchPlayer player = new MatchPlayer(target);
    bool ready = player.IsReady();
    bool matchReady = g_DonutMatch.IsReady(target);
    ReplyToCommand(client, "[DM API] %N valid=%d ready=%d/%d team=%d roster=%d captain=%d K/D=%d/%d",
        target, player.IsValid(), ready, matchReady, player.Team(), player.IsInRoster(), player.IsCaptain(), player.Frags(), player.Deaths());
    char name[MAX_NAME_LENGTH], auth[64];
    player.Name(name, sizeof(name));
    bool hasAuth = player.AuthId(auth, sizeof(auth));
    ReplyToCommand(client, "[DM API] name='%s' userid=%d auth='%s' alive=%d money=%d pendingRequester=%d",
        name, player.UserId(), hasAuth ? auth : "unavailable", player.IsAlive(), player.Money(), player.PendingSubstituteRequester());
    ReplyToCommand(client, "[DM API] pending substitute target=%d", player.PendingSubstituteTarget());
    if (args >= 2)
    {
        char otherArg[MAX_TARGET_LENGTH];
        GetCmdArg(2, otherArg, sizeof(otherArg));
        int other = FindTarget(client, otherArg, true, false);
        if (other > 0)
        {
            MatchPlayer targetPlayer = new MatchPlayer(other);
            ReplyToCommand(client, "[DM API] damage=%d hits=%d toward %N",
                player.DamageTo(targetPlayer), player.HitsTo(targetPlayer), other);
        }
    }
    return Plugin_Handled;
}

public Action Command_ExampleAsk(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;
    if (client < 1)
    {
        ReplyToCommand(client, "Эту команду должен вызвать игрок.");
        return Plugin_Handled;
    }

    MatchPlayer player = new MatchPlayer(client);
    ReplyToCommand(client, "[DM API] AskForSubstitute() => %d", player.AskForSubstitute());
    return Plugin_Handled;
}

public Action Command_ExampleSetReady(int client, int args)
{
    if (!RequireDonutMatch(client))
    {
        return Plugin_Handled;
    }

    if (args < 2)
    {
        ReplyToCommand(client, "Использование: sm_dm_example_setready <игрок> <0|1>");
        return Plugin_Handled;
    }

    char targetArg[MAX_TARGET_LENGTH], readyArg[8];
    GetCmdArg(1, targetArg, sizeof(targetArg));
    GetCmdArg(2, readyArg, sizeof(readyArg));
    int target = FindTarget(client, targetArg, true, false);
    if (target <= 0)
    {
        return Plugin_Handled;
    }

    bool ready = StringToInt(readyArg) != 0;
    // Возвращаемое значение false означает неверный индекс или игрок не в игре.
    MatchPlayer player = new MatchPlayer(target);
    bool changed = player.SetReady(ready);
    ReplyToCommand(client, "[DM API] SetPlayerReady(%N, %d) => %d", target, ready, changed);
    return Plugin_Handled;
}

public Action Command_ExampleDraft(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;

    MatchDraft draft = new MatchDraft();
    int picker = view_as<int>(draft.CurrentPicker());
    ReplyToCommand(client, "[DM API] active=%d candidates=%d currentPicker=%d",
        draft.IsActive(), draft.CandidateCount(), picker);

    ArrayList candidates = draft.Candidates();
    for (int i = 0; i < candidates.Length; i++)
    {
        int candidate = candidates.Get(i);
        if (IsClientInGame(candidate)) ReplyToCommand(client, "  candidate: %N", candidate);
    }
    delete candidates;
    return Plugin_Handled;
}

public Action Command_ExampleDraftPick(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_dm_example_draftpick <player>");
        return Plugin_Handled;
    }

    char targetArg[MAX_TARGET_LENGTH];
    GetCmdArg(1, targetArg, sizeof(targetArg));
    int target = FindTarget(client, targetArg, true, false);
    if (target <= 0) return Plugin_Handled;

    MatchDraft draft = new MatchDraft();
    MatchPlayer player = new MatchPlayer(target);
    ReplyToCommand(client, "[DM API] ForcePick(%N) => %d", target, draft.ForcePick(player));
    return Plugin_Handled;
}

public Action Command_ExampleDraftFinish(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;
    MatchDraft draft = new MatchDraft();
    ReplyToCommand(client, "[DM API] Finish() => %d", draft.Finish());
    return Plugin_Handled;
}

public Action Command_ExampleChooseSide(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_dm_example_chooseside <2|3>");
        return Plugin_Handled;
    }

    char teamArg[8];
    GetCmdArg(1, teamArg, sizeof(teamArg));
    int team = StringToInt(teamArg);
    MatchDraft draft = new MatchDraft();
    ReplyToCommand(client, "[DM API] ChooseSide(%d) => %d", team, draft.ChooseSide(team));
    return Plugin_Handled;
}

public Action Command_ExampleTeamName(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;
    if (args < 2)
    {
        ReplyToCommand(client, "Usage: sm_dm_example_teamname <2|3> <name>");
        return Plugin_Handled;
    }
    char teamArg[8], teamName[128];
    GetCmdArg(1, teamArg, sizeof(teamArg));
    GetCmdArg(2, teamName, sizeof(teamName));
    bool changed = g_DonutMatch.SetTeamName(client, StringToInt(teamArg), teamName);
    ReplyToCommand(client, "[DM API] SetTeamName => %d", changed);
    return Plugin_Handled;
}

public Action Command_ExampleOvertime(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;
    ReplyToCommand(client, "[DM API] StartOvertime() => %d", g_DonutMatch.StartOvertime());
    return Plugin_Handled;
}

public Action Command_ExampleLogEvent(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;
    char eventName[64], payload[256];
    if (args < 2)
    {
        ReplyToCommand(client, "Usage: sm_dm_example_logevent <event-name> <payload>");
        return Plugin_Handled;
    }
    GetCmdArg(1, eventName, sizeof(eventName));
    GetCmdArg(2, payload, sizeof(payload));
    ReplyToCommand(client, "[DM API] LogEvent => %d",
        g_DonutMatch.LogEvent("donut-examples", eventName, payload));
    return Plugin_Handled;
}

public Action Command_ExampleAssign(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;
    if (args < 2)
    {
        ReplyToCommand(client, "Usage: sm_dm_example_assign <player> <2|3>");
        return Plugin_Handled;
    }
    char targetArg[MAX_TARGET_LENGTH], teamArg[8];
    GetCmdArg(1, targetArg, sizeof(targetArg));
    GetCmdArg(2, teamArg, sizeof(teamArg));
    int target = FindTarget(client, targetArg, true, false);
    if (target <= 0) return Plugin_Handled;
    MatchPlayer player = new MatchPlayer(target);
    ReplyToCommand(client, "[DM API] AssignToTeam(%d) => %d", StringToInt(teamArg),
        player.AssignToTeam(StringToInt(teamArg)));
    return Plugin_Handled;
}

public Action Command_ExampleRemove(int client, int args)
{
    if (!RequireDonutMatch(client)) return Plugin_Handled;
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_dm_example_remove <player>");
        return Plugin_Handled;
    }
    char targetArg[MAX_TARGET_LENGTH];
    GetCmdArg(1, targetArg, sizeof(targetArg));
    int target = FindTarget(client, targetArg, true, false);
    if (target <= 0) return Plugin_Handled;
    MatchPlayer player = new MatchPlayer(target);
    ReplyToCommand(client, "[DM API] RemoveFromRoster() => %d", player.RemoveFromRoster());
    return Plugin_Handled;
}

public Action Command_ExampleRoster(int client, int args)
{
    if (!RequireDonutMatch(client))
    {
        return Plugin_Handled;
    }

    // Натив возвращает принадлежащую вызывающему плагину копию ArrayList.
    ArrayList players = g_DonutMatch.LivePlayers();
    ReplyToCommand(client, "[DM API] В списке состава: %d игроков", players.Length);
    for (int i = 0; i < players.Length; i++)
    {
        int player = players.Get(i);
        if (IsClientInGame(player))
        {
            // Дополнительно проверяем отдельного игрока через IsPlayerInMatch.
            ReplyToCommand(client, "  %N: inMatch=%d", player, g_DonutMatch.IsPlayerInMatch(player));
        }
    }
    delete players;
    return Plugin_Handled;
}

public Action Command_ExampleForceStart(int client, int args)
{
    if (!RequireDonutMatch(client))
    {
        return Plugin_Handled;
    }

    // ForceStart минует готовность и предстартовые этапы, но требует точный состав T/CT.
    bool started = g_DonutMatch.Start();
    ReplyToCommand(client, "[DM API] ForceStart => %d", started);
    return Plugin_Handled;
}

public Action Command_ExampleForceStop(int client, int args)
{
    if (!RequireDonutMatch(client))
    {
        return Plugin_Handled;
    }

    char reason[192];
    if (args > 0)
    {
        GetCmdArgString(reason, sizeof(reason));
    }
    else
    {
        strcopy(reason, sizeof(reason), "Остановка через пример API");
    }

    // ForceStop сбрасывает состояние матча, но не вызывает OnMatchEnd.
    bool stopped = g_DonutMatch.Stop(reason);
    ReplyToCommand(client, "[DM API] ForceStop => %d", stopped);
    return Plugin_Handled;
}

public void DonutMatch_OnPlayerReady(int client, bool ready)
{
    // Форвард приходит при изменении готовности подключённого игрока-человека.
    PrintToServer("[DM API forward] PlayerReady: client=%d ready=%d", client, ready);
}

public void DonutMatch_OnRoundScore(int scoreT, int scoreCT, int winnerTeam)
{
    // winnerTeam: 2 = T, 3 = CT.
    PrintToServer("[DM API forward] RoundScore: %d:%d winnerTeam=%d", scoreT, scoreCT, winnerTeam);
}

public void DonutMatch_OnMatchStart(const any[] data, int dataSize)
{
    // Используем stock-парсер API: он раскладывает фиксированный массив на поля.
    if (dataSize != 2 + MAXPLAYERS * 2)
    {
        PrintToServer("[DM API forward] MatchStart: неверный размер массива: %d", dataSize);
        return;
    }
    GameMode mode;
    int playerCount;
    int players[MAXPLAYERS], teams[MAXPLAYERS];
    if (!DonutMatch_ParseMatchStartData(data, mode, playerCount, players, teams))
    {
        PrintToServer("[DM API forward] MatchStart: некорректные данные, size=%d", dataSize);
        return;
    }

    char modeName[16];
    DonutMatch_GetModeName(mode, modeName, sizeof(modeName));
    PrintToServer("[DM API forward] MatchStart: mode=%s players=%d", modeName, playerCount);
    for (int i = 0; i < playerCount; i++)
    {
        PrintToServer("  player=%d team=%d", players[i], teams[i]);
    }
}

public void DonutMatch_OnMatchEnd(const any[] data, int dataSize)
{
    // Парсим результат матча: режим и финальный счет T:CT.
    if (dataSize != 3)
    {
        PrintToServer("[DM API forward] MatchEnd: неверный размер массива: %d", dataSize);
        return;
    }
    GameMode mode;
    int scoreT, scoreCT;
    if (!DonutMatch_ParseMatchEndData(data, mode, scoreT, scoreCT))
    {
        PrintToServer("[DM API forward] MatchEnd: некорректные данные, size=%d", dataSize);
        return;
    }

    char modeName[16];
    DonutMatch_GetModeName(mode, modeName, sizeof(modeName));
    PrintToServer("[DM API forward] MatchEnd: mode=%s score=%d:%d", modeName, scoreT, scoreCT);
}

public void DonutMatch_OnMatchReset(const char[] reason)
{
    // Reset отдельно от нормального окончания матча: не используйте его как MatchEnd.
    PrintToServer("[DM API forward] MatchReset: %s", reason);
}

public void DonutMatch_OnHalfTime(int scoreT, int scoreCT)
{
    // Старый краткий forward основного перерыва, до смены сторон.
    PrintToServer("[DM API forward] HalfTime: %d:%d", scoreT, scoreCT);
}

public void DonutMatch_OnRestartsCompleted()
{
    // Срабатывает после серии из трех рестартов в начале матча или после перерыва.
    PrintToServer("[DM API forward] Тройной рестарт завершен");
}

public void DonutMatch_OnOvertime()
{
    // Срабатывает при старте каждого блока овертайма.
    PrintToServer("[DM API forward] Начался блок овертайма");
}

public void DonutMatch_OnMatchHalfTime(GameMode mode, const int[] players, int playerCount, bool overtime, int scoreT, int scoreCT)
{
    // Расширенный callback содержит игроков, счет и тип перерыва до смены сторон.
    char modeName[16];
    DonutMatch_GetModeName(mode, modeName, sizeof(modeName));
    PrintToServer("[DM API forward] DetailedHalfTime: mode=%s OT=%d score=%d:%d players=%d", modeName, overtime, scoreT, scoreCT, playerCount);
    for (int i = 0; i < playerCount; i++)
    {
        PrintToServer("  halftime player=%d", players[i]);
    }
}

public Action DonutMatch_OnPlayerReplacePre(int client, int target)
{
    // Plugin_Continue разрешает замену. Возврат любого другого Action отменит ее.
    PrintToServer("[DM API forward] ReplacePre: %d -> %d", client, target);
    return Plugin_Continue;
}

public void DonutMatch_OnPlayerReplacePost(int client, int target)
{
    // Этот callback приходит только после успешного обновления состава.
    PrintToServer("[DM API forward] ReplacePost: %d -> %d", client, target);
}

public void DonutMatch_OnStateChanged(MatchState oldState, MatchState newState)
{
    PrintToServer("[DM API forward] StateChanged: %d -> %d", oldState, newState);
}

public void DonutMatch_OnScoreChanged(int scoreT, int scoreCT)
{
    PrintToServer("[DM API forward] ScoreChanged: %d:%d", scoreT, scoreCT);
}

public void DonutMatch_OnTeamsSwapped(int scoreT, int scoreCT)
{
    // Срабатывает после смены T/CT и обновления счёта; приходит и при автоматическом переходе сторон.
    PrintToServer("[DM API forward] TeamsSwapped: score=%d:%d", scoreT, scoreCT);
}

public void DonutMatch_OnRosterChanged(int client, int team, bool added)
{
    PrintToServer("[DM API forward] RosterChanged: client=%d team=%d added=%d", client, team, added);
}

public void DonutMatch_OnTeamNameChanged(int team, const char[] name, int actor)
{
    PrintToServer("[DM API forward] TeamNameChanged: team=%d name='%s' actor=%d", team, name, actor);
}

public void DonutMatch_OnDraftPick(int picker, int picked, int team)
{
    PrintToServer("[DM API forward] DraftPick: picker=%d picked=%d team=%d", picker, picked, team);
}

public void DonutMatch_OnOvertimeVoteFinished(int yesVotes, int noVotes, int eligibleVotes, bool passed)
{
    PrintToServer("[DM API forward] OvertimeVoteFinished: yes=%d no=%d eligible=%d passed=%d",
        yesVotes, noVotes, eligibleVotes, passed);
}

public void DonutMatch_OnLogEvent(const char[] eventName, int timestamp, const char[] fields)
{
    PrintToServer("[DM API forward] LogEvent: %s at %d %s", eventName, timestamp, fields);
}

public void DonutMatch_OnDatabaseResultSaved(const char[] map, GameMode mode, int playersPerSide,
    int scoreT, int scoreCT, int durationSeconds, int playedAt)
{
    PrintToServer("[DM API forward] DatabaseResultSaved: %s mode=%d %dv%d score=%d:%d duration=%ds at=%d",
        map, mode, playersPerSide, playersPerSide, scoreT, scoreCT, durationSeconds, playedAt);
}

public void DonutMatch_OnWarSeriesStart(WarSeriesMode mode, int mapsToWin, int mapCount)
{
    PrintToServer("[DM API forward] WarSeriesStart: mode=%d mapsToWin=%d maps=%d", mode, mapsToWin, mapCount);
}

public void DonutMatch_OnWarVetoChoice(WarSeriesTeam team, WarVetoAction action,
    const char[] mapName, int step, int stepCount, int client, bool automatic)
{
    PrintToServer("[DM API forward] WarVetoChoice: team=%d action=%d map=%s step=%d/%d client=%d auto=%d",
        team, action, mapName, step, stepCount, client, automatic);
}

public void DonutMatch_OnWarSeriesVetoComplete()
{
    PrintToServer("[DM API forward] WarSeriesVetoComplete");
}

public void DonutMatch_OnWarSeriesMapEnd(int mapIndex, const char[] mapName,
    WarSeriesTeam winner, int scoreT, int scoreCT, int teamAWins, int teamBWins)
{
    PrintToServer("[DM API forward] WarSeriesMapEnd: index=%d map=%s winner=%d score=%d:%d series=%d:%d",
        mapIndex, mapName, winner, scoreT, scoreCT, teamAWins, teamBWins);
}

public void DonutMatch_OnWarSeriesEnd(WarSeriesTeam winner, int teamAWins, int teamBWins)
{
    PrintToServer("[DM API forward] WarSeriesEnd: winner=%d score=%d:%d", winner, teamAWins, teamBWins);
}
