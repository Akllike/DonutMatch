#if defined _donutmatch_included
 #endinput
#endif
#define _donutmatch_included

#include <sdktools>

enum GameMode
{
    MODE_NONE,
    MODE_MIX,
    MODE_WAR
};

/**
 * Состояния матча
 */
enum MatchState
{
    State_ReadySystem,      /**< Ожидание готовности игроков */
    State_Warmup,           /**< Фаза разминки */
    State_CaptainKnife,     /**< Ножевой раунд капитанов (только Mix) */
    State_PickingPlayers,   /**< Фаза выбора игроков (только Mix) */
    State_KnifeRound_WAR,   /**< Ножевой раунд выбора стороны (только War) */
    State_Starting,         /**< Матч запускается */
    State_Live,             /**< Матч идет */
    State_Overtime          /**< Овертайм */
};

/**
 * Вызывается когда игрок меняет статус готовности
 *
 * @param client        Индекс игрока
 * @param ready         true - готов, false - не готов
 * @noreturn
 */
forward void DonutMatch_OnPlayerReady(int client, bool ready);

/**
 * Вызывается при обновлении счета раунда
 *
 * @param scoreT        Счет террористов
 * @param scoreCT       Счет спецназа  
 * @param winnerTeam    Победившая команда (2 = T, 3 = CT)
 * @noreturn
 */
forward void DonutMatch_OnRoundScore(int scoreT, int scoreCT, int winnerTeam);

/**
 * Вызывается при начале матча
 *
 * @param data          Массив данных о матче [mode, playerCount, players[], teams[]]
 * @param dataSize      Размер массива данных
 * @noreturn
 */
forward void DonutMatch_OnMatchStart(const any[] data, int dataSize);

/**
 * Вызывается при окончании матча
 *
 * @param data          Массив данных о результате [mode, scoreT, scoreCT]
 * @param dataSize      Размер массива данных  
 * @noreturn
 */
forward void DonutMatch_OnMatchEnd(const any[] data, int dataSize);


/**
 * Проверяет идет ли сейчас матч (включая овертайм)
 *
 * @return              true если матч идет или в овертайме, false если нет
 */
native bool DonutMatch_IsMatchLive();

/**
 * Получает текущее состояние матча
 *
 * @return              Текущее состояние MatchState
 */
native MatchState DonutMatch_GetMatchState();

/**
 * Получает текущий режим игры
 *
 * @return              Текущий режим GameMode  
 */
native GameMode DonutMatch_GetGameMode();

/**
 * Проверяет готовность игрока
 *
 * @param client        Индекс игрока для проверки
 * @return              true если готов, false если не готов
 * @error               Неверный индекс игрока
 */
native bool DonutMatch_GetPlayerReady(int client);

/**
 * Устанавливает статус готовности игрока
 *
 * @param client        Индекс игрока
 * @param ready         true - готов, false - не готов
 * @return              true если успешно, false если ошибка
 * @error               Неверный игрок или не в игре
 */
native bool DonutMatch_SetPlayerReady(int client, bool ready);

/**
 * Получает текущий счет матча
 *
 * @param scoreT        Переменная для счета террористов
 * @param scoreCT       Переменная для счета спецназа
 * @noreturn
 */
native void DonutMatch_GetScore(int &scoreT, int &scoreCT);

/**
 * Принудительно запускает матч если в состоянии готовности
 *
 * @return              true если успешно, false если ошибка
 */
native bool DonutMatch_ForceStart();

/**
 * Принудительно останавливает матч с причиной
 *
 * @param reason        Причина остановки матча
 * @return              true если успешно, false если ошибка
 */
native bool DonutMatch_ForceStop(const char[] reason);

/**
 * Получает количество игроков на сторону
 *
 * @return              Игроков в команде (например, 5 для 5v5)
 */
native int DonutMatch_GetPlayersPerSide();

/**
 * Получает массив игроков в текущем матче
 *
 * @return              ArrayList с индексами игроков в матче
 * @note                закрыть с delete или CloseHandle()
 */
native ArrayList DonutMatch_GetLivePlayers();

/**
 * Проверяет участвует ли игрок в текущем матче
 *
 * @param client        Индекс игрока для проверки
 * @return              true если участвует в матче, false если нет
 * @error               Неверный индекс игрока
 */
native bool DonutMatch_IsPlayerInMatch(int client);

/**
 * Получает название команды по номеру
 *
 * @param team          Номер команды (2 = T, 3 = CT)
 * @param buffer        Буфер для названия команды
 * @param size          Размер буфера
 * @return              true если успешно, false если ошибка
 */
stock bool DonutMatch_GetTeamName(int team, char[] buffer, int size)
{
    if (team == 2)
    {
        strcopy(buffer, size, "Террористы");
        return true;
    }
    else if (team == 3)
    {
        strcopy(buffer, size, "Спецназ");
        return true;
    }
    return false;
}

/**
 * Получает название режима игры
 *
 * @param mode          Значение GameMode
 * @param buffer        Буфер для названия режима
 * @param size          Размер буфера
 * @return              true если успешно, false если ошибка
 */
stock bool DonutMatch_GetModeName(GameMode mode, char[] buffer, int size)
{
    switch (mode)
    {
        case MODE_MIX: strcopy(buffer, size, "Mix");
        case MODE_WAR: strcopy(buffer, size, "War");
        default: return false;
    }
    return true;
}

/**
 * Получает название состояния матча
 *
 * @param state         Значение MatchState
 * @param buffer        Буфер для названия состояния
 * @param size          Размер буфера
 * @return              true если успешно, false если ошибка
 */
stock bool DonutMatch_GetStateName(MatchState state, char[] buffer, int size)
{
    switch (state)
    {
        case State_ReadySystem: strcopy(buffer, size, "ReadySystem");
        case State_Warmup: strcopy(buffer, size, "Warmup");
        case State_CaptainKnife: strcopy(buffer, size, "CaptainKnife");
        case State_PickingPlayers: strcopy(buffer, size, "PickingPlayers");
        case State_KnifeRound_WAR: strcopy(buffer, size, "KnifeRound_WAR");
        case State_Starting: strcopy(buffer, size, "Starting");
        case State_Live: strcopy(buffer, size, "Live");
        case State_Overtime: strcopy(buffer, size, "Overtime");
        default: return false;
    }
    return true;
}

/**
 * Парсит данные из OnMatchStart
 *
 * @param data          Массив данных
 * @param mode          Переменная для режима игры
 * @param playerCount   Переменная для количества игроков
 * @param players       Массив для индексов игроков (размером MAXPLAYERS)
 * @param teams         Массив для команд игроков (размером MAXPLAYERS)
 * @return              true если успешно, false если ошибка
 */
stock bool DonutMatch_ParseMatchStartData(const any[] data, GameMode &mode, int &playerCount, int[] players, int[] teams)
{
    if (data[1] <= 0 || data[1] > MAXPLAYERS)
        return false;
    
    mode = view_as<GameMode>(data[0]);
    playerCount = data[1];
    
    for (int i = 0; i < playerCount && i < MAXPLAYERS; i++)
    {
        players[i] = data[2 + i];
        teams[i] = data[2 + MAXPLAYERS + i];
    }
    
    return true;
}

/**
 * Парсит данные из OnMatchEnd  
 *
 * @param data          Массив данных
 * @param mode          Переменная для режима игры
 * @param scoreT        Переменная для счета террористов
 * @param scoreCT       Переменная для счета спецназа
 * @return              true если успешно, false если ошибка
 */
stock bool DonutMatch_ParseMatchEndData(const any[] data, GameMode &mode, int &scoreT, int &scoreCT)
{
    mode = view_as<GameMode>(data[0]);
    scoreT = data[1];
    scoreCT = data[2];
    return true;
}

public SharedPlugin __pl_donutmatch = 
{
    name = "donutmatch",
    file = "donut_match.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_donutmatch_SetNTVOptional()
{
    MarkNativeAsOptional("DonutMatch_IsMatchLive");
    MarkNativeAsOptional("DonutMatch_GetMatchState");
    MarkNativeAsOptional("DonutMatch_GetGameMode");
    MarkNativeAsOptional("DonutMatch_GetPlayerReady");
    MarkNativeAsOptional("DonutMatch_SetPlayerReady");
    MarkNativeAsOptional("DonutMatch_GetScore");
    MarkNativeAsOptional("DonutMatch_ForceStart");
    MarkNativeAsOptional("DonutMatch_ForceStop");
    MarkNativeAsOptional("DonutMatch_GetPlayersPerSide");
    MarkNativeAsOptional("DonutMatch_GetLivePlayers");
    MarkNativeAsOptional("DonutMatch_IsPlayerInMatch");
}
#endif