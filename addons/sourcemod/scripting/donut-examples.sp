#include <sourcemod>
#include <donutmatch>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "DonutMatch API examples",
    author = "phenom",
    description = "Примеры использования нативов и форвардов DonutMatch",
    version = "1.0.0",
    url = "https://t.me/phenom1337"
};

bool g_bDonutMatchAvailable;

public void OnPluginStart()
{
    // API подключен как необязательный: пример может загрузиться раньше DonutMatch.
    g_bDonutMatchAvailable = LibraryExists("donutmatch");

    RegConsoleCmd("sm_dm_example_status", Command_ExampleStatus, "Показать пример чтения состояния и данных матча DonutMatch");
    RegConsoleCmd("sm_dm_example_readyinfo", Command_ExampleReadyInfo, "Проверить статус готовности: sm_dm_example_readyinfo <игрок>");
    RegAdminCmd("sm_dm_example_setready", Command_ExampleSetReady, ADMFLAG_GENERIC, "Пример установки готовности: sm_dm_example_setready <игрок> <0|1>");
    RegConsoleCmd("sm_dm_example_roster", Command_ExampleRoster, "Показать пример чтения состава матча");
    RegAdminCmd("sm_dm_example_forcestart", Command_ExampleForceStart, ADMFLAG_GENERIC, "Пример вызова DonutMatch_ForceStart");
    RegAdminCmd("sm_dm_example_forcestop", Command_ExampleForceStop, ADMFLAG_GENERIC, "Пример вызова DonutMatch_ForceStop");
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
    bool live = DonutMatch_IsMatchLive();
    MatchState state = DonutMatch_GetMatchState();
    GameMode mode = DonutMatch_GetGameMode();
    int playersPerSide = DonutMatch_GetPlayersPerSide();

    char stateName[32], modeName[16];
    DonutMatch_GetStateName(state, stateName, sizeof(stateName));
    DonutMatch_GetModeName(mode, modeName, sizeof(modeName));

    // Получение счета передает значения через ссылки на переменные.
    int scoreT, scoreCT;
    DonutMatch_GetScore(scoreT, scoreCT);

    // Капитаны возвращаются как client index; 0 означает, что капитан не определен.
    int captainT = DonutMatch_GetCaptain(2);
    int captainCT = DonutMatch_GetCaptain(3);

    // Пример получения названий команд. Для стандартных имен API также вернет строку.
    char teamT[64], teamCT[64];
    bool hasTeamT = DonutMatch_GetTeamName(2, teamT, sizeof(teamT));
    bool hasTeamCT = DonutMatch_GetTeamName(3, teamCT, sizeof(teamCT));
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
    int regulationMaxRounds = DonutMatch_GetMaxRounds();
    int overtimeMaxRounds = DonutMatch_GetMaxRounds(true);

    // Счет последнего перерыва до смены сторон; для OT передаем true.
    int halfT = DonutMatch_GetHalftimeScore(2);
    int halfCT = DonutMatch_GetHalftimeScore(3);
    int overtimeHalfT = DonutMatch_GetHalftimeScore(2, true);
    int overtimeHalfCT = DonutMatch_GetHalftimeScore(3, true);

    ReplyToCommand(client, "[DM API] live=%d mode=%s state=%s format=%dv%d score=%d:%d", live, modeName, stateName, playersPerSide, playersPerSide, scoreT, scoreCT);
    ReplyToCommand(client, "[DM API] captains T='%s' CT='%s' | teams T='%s' CT='%s'", captainNameT, captainNameCT, hasTeamT ? teamT : "?", hasTeamCT ? teamCT : "?");
    ReplyToCommand(client, "[DM API] max rounds regulation=%d OT=%d | last half=%d:%d OT half=%d:%d", regulationMaxRounds, overtimeMaxRounds, halfT, halfCT, overtimeHalfT, overtimeHalfCT);

    // Native DonutMatch_GetPlayerReady показан отдельной командой ниже, потому что
    // для него нужен индекс конкретного игрока.
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
    bool ready = DonutMatch_GetPlayerReady(target);
    ReplyToCommand(client, "[DM API] %N ready=%d", target, ready);
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
    bool changed = DonutMatch_SetPlayerReady(target, ready);
    ReplyToCommand(client, "[DM API] SetPlayerReady(%N, %d) => %d", target, ready, changed);
    return Plugin_Handled;
}

public Action Command_ExampleRoster(int client, int args)
{
    if (!RequireDonutMatch(client))
    {
        return Plugin_Handled;
    }

    // Натив возвращает принадлежащую вызывающему плагину копию ArrayList.
    ArrayList players = DonutMatch_GetLivePlayers();
    ReplyToCommand(client, "[DM API] В списке состава: %d игроков", players.Length);
    for (int i = 0; i < players.Length; i++)
    {
        int player = players.Get(i);
        if (IsClientInGame(player))
        {
            // Дополнительно проверяем отдельного игрока через IsPlayerInMatch.
            ReplyToCommand(client, "  %N: inMatch=%d", player, DonutMatch_IsPlayerInMatch(player));
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
    bool started = DonutMatch_ForceStart();
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
    bool stopped = DonutMatch_ForceStop(reason);
    ReplyToCommand(client, "[DM API] ForceStop => %d", stopped);
    return Plugin_Handled;
}

public void DonutMatch_OnPlayerReady(int client, bool ready)
{
    // Форвард приходит при изменении готовности активного игрового клиента.
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
