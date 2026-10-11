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
    State_ReadySystem,      /**< Сбор состава и ожидание готовности игроков */
    State_Warmup,           /**< Фаза разминки */
    State_CaptainKnife,     /**< Ножевой раунд капитанов (только Mix) */
    State_PickingPlayers,   /**< Фаза выбора игроков (только Mix) */
    State_KnifeRound_WAR,   /**< Ножевой раунд выбора стороны (только War) */
    State_Starting,         /**< Матч запускается */
    State_Live,             /**< Матч идет */
    State_Overtime,         /**< Овертайм */
    State_MapVoteWait,      /**< Матч завершен, ожидается результат голосования за карту */
    State_MapRestartDelay   /**< Перезапуск Mix задержан после выбора той же карты */
};

/**
 * Вызывается, когда статус готовности меняется у игрока, находящегося в игре.
 * Для ботов и очистки статуса при отключении callback не отправляется.
 *
 * @param client        Индекс игрока
 * @param ready         true - готов, false - не готов
 */
forward void DonutMatch_OnPlayerReady(int client, bool ready);

/**
 * Вызывается при обновлении счета раунда
 *
 * @param scoreT        Счет террористов
 * @param scoreCT       Счет спецназа  
 * @param winnerTeam    Победившая команда (2 = T, 3 = CT)
 */
forward void DonutMatch_OnRoundScore(int scoreT, int scoreCT, int winnerTeam);

/**
 * Вызывается при начале матча
 *
 * @param data          Массив: [mode, playerCount, players[MAXPLAYERS], teams[MAXPLAYERS]].
 *                      Индексы игроков начинаются с data[2], команды - с data[2 + MAXPLAYERS].
 * @param dataSize      Размер массива: 2 + MAXPLAYERS * 2
 */
forward void DonutMatch_OnMatchStart(const any[] data, int dataSize);

/**
 * Вызывается при окончании матча
 *
 * @param data          Массив данных о результате [mode, scoreT, scoreCT]
 * @param dataSize      Размер массива данных  
 */
forward void DonutMatch_OnMatchEnd(const any[] data, int dataSize);

/**
 * Вызывается при Reset матча, если до сброса система была не в State_ReadySystem.
 * Не заменяет DonutMatch_OnMatchEnd и может вызываться при отмене/сбросе матча.
 *
 * @param reason        Причина сброса
 */
forward void DonutMatch_OnMatchReset(const char[] reason);

/**
 * Вызывается после 15-го раунда основного времени перед сменой сторон.
 *
 * @param scoreT        Счёт T перед сменой сторон
 * @param scoreCT       Счёт CT перед сменой сторон
 */
forward void DonutMatch_OnHalfTime(int scoreT, int scoreCT);

/**
 * Вызывается после завершения серии из трех рестартов в начале матча
 * и после смены сторон на перерыве.
 */
forward void DonutMatch_OnRestartsCompleted();

/**
 * Вызывается при начале каждого блока овертайма.
 */
forward void DonutMatch_OnOvertime();

/**
 * Подробное событие перерыва основного времени или овертайма. Вызывается до смены сторон.
 *
 * @param mode          Режим матча
 * @param players       Массив индексов активных игроков состава
 * @param playerCount   Количество игроков в массиве
 * @param overtime      true для перерыва овертайма, false для основного времени
 * @param scoreT        Счет сторон до смены сторон
 * @param scoreCT       Счет сторон до смены сторон
 */
forward void DonutMatch_OnMatchHalfTime(GameMode mode, const int[] players, int playerCount, bool overtime, int scoreT, int scoreCT);

/**
 * Вызывается после того, как игрок согласился на замену, но до смены команд.
 * Верните Plugin_Continue, чтобы разрешить замену; любое другое значение Action отменит ее.
 *
 * @param client        Игрок, запросивший замену и покидающий состав
 * @param target        Игрок, входящий в состав
 */
forward Action DonutMatch_OnPlayerReplacePre(int client, int target);

/**
 * Вызывается после успешной замены и обновления внутреннего состава.
 *
 * @param client        Игрок, запросивший замену и покинувший состав
 * @param target        Игрок, вошедший в состав
 */
forward void DonutMatch_OnPlayerReplacePost(int client, int target);


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
 * Проверяет сохраненный статус готовности игрока
 *
 * @param client        Индекс игрока для проверки
 * @return              true если готов; false если не готов или client вне диапазона 1..MaxClients
 */
native bool DonutMatch_GetPlayerReady(int client);

/**
 * Устанавливает статус готовности игрока
 *
 * @param client        Индекс игрока
 * @param ready         true - готов, false - не готов
 * @return              true если client находится в игре и вызов обработан; false при неверном
 *                      индексе или если клиент не находится в игре. Повторная установка того же значения
 *                      возвращает true, но не вызывает DonutMatch_OnPlayerReady повторно.
 * @note                В State_ReadySystem установка ready=false запускает таймер из donut_ready_timer,
 *                      если от игрока ожидается подтверждение готовности. Установка ready=true отменяет
 *                      его. Значение donut_ready_timer=0 отключает кик по таймеру.
 */
native bool DonutMatch_SetPlayerReady(int client, bool ready);

/**
 * Получает текущий счет матча
 *
 * @param scoreT        Переменная для счета террористов
 * @param scoreCT       Переменная для счета спецназа
 */
native void DonutMatch_GetScore(int &scoreT, int &scoreCT);

/**
 * Принудительно запускает матч, минуя готовность игроков и обычные предстартовые этапы.
 * Плагин должен быть в State_ReadySystem, и в T/CT должен находиться точный настроенный состав.
 *
 * @return              true если успешно, false если ошибка
 */
native bool DonutMatch_ForceStart();

/**
 * Сбрасывает состояние матча с причиной, очищает сохраненный плагином состав и счет и запускает
 * рестарт раунда. Не переводит игроков в другие команды и не вызывает DonutMatch_OnMatchEnd.
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
 * Получает копию внутреннего списка участников матча.
 * Во время драфта и до State_Starting в Mix содержит выбранных игроков, но капитаны
 * добавляются только при запуске матча. В State_Starting/State_Live/State_Overtime
 * содержит полный активный состав. Не включает кандидатов на драфте или очередь спектаторов.
 *
 * @return              ArrayList с индексами игроков в матче
 * @note                закрыть с delete или CloseHandle()
 */
native ArrayList DonutMatch_GetLivePlayers();

/**
 * Проверяет, находится ли client во внутреннем списке участников матча.
 * В Mix капитаны попадают в этот список при переходе к запуску матча.
 *
 * @param client        Индекс игрока для проверки
 * @return              true если входит в состав; false если нет или client вне диапазона
 *                      1..MaxClients
 */
native bool DonutMatch_IsPlayerInMatch(int client);

/**
 * Получает капитана команды в Mix.
 *
 * @param team          Номер команды (2 = T, 3 = CT)
 * @return              Индекс капитана либо 0, если капитан для команды не определен
 */
native int DonutMatch_GetCaptain(int team);

/**
 * Получает максимальное число раундов сегмента матча.
 * Основное время рассчитано максимум на 30 раундов. Для овертайма возвращается
 * две половины по donut_default_overtime_rounds плюс один возможный решающий раунд.
 *
 * @param overtime      true для овертайма, false для основного времени
 * @return              Максимальное число раундов
 */
native int DonutMatch_GetMaxRounds(bool overtime = false);

/**
 * Получает сохраненный счет на последнем завершенном перерыве.
 * Значения относятся к сторонам T/CT до смены сторон.
 * Для овертайма возвращает счет последнего завершенного перерыва текущего блока.
 *
 * @param team          Номер стороны (2 = T, 3 = CT)
 * @param overtime      false для основного времени, true для текущего блока овертайма
 * @return              Счет стороны; 0, если перерыв еще не наступил или team некорректен
 */
native int DonutMatch_GetHalftimeScore(int team, bool overtime = false);

/**
 * Получает текущее название команды по номеру. В Mix название можно задать капитану
 * командой !teamname; при смене сторон оно остается с составом команды.
 *
 * @param team          Номер команды (2 = T, 3 = CT)
 * @param buffer        Буфер для названия команды
 * @param size          Размер буфера
 * @return              true если название получено, false при неверной команде или маленьком буфере
 */
native bool DonutMatch_GetTeamName(int team, char[] buffer, int size);

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
        case State_MapVoteWait: strcopy(buffer, size, "MapVoteWait");
        case State_MapRestartDelay: strcopy(buffer, size, "MapRestartDelay");
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
    MarkNativeAsOptional("DonutMatch_GetCaptain");
    MarkNativeAsOptional("DonutMatch_GetMaxRounds");
    MarkNativeAsOptional("DonutMatch_GetHalftimeScore");
    MarkNativeAsOptional("DonutMatch_GetTeamName");
}
#endif
