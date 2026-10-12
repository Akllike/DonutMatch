#if defined _donutmatch_included
 #endinput
#endif
#define _donutmatch_included

#include <sdktools>

/** Режим, в котором проводится матч. */
enum GameMode
{
    MODE_NONE, /**< Режим не задан или матч ещё не начался. */
    MODE_MIX,  /**< Смешанный режим с набором игроков и драфтом. */
    MODE_WAR   /**< Заранее сформированные команды (War). */
};

/**
 * Текущее состояние системы матча.
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

enum MatchDatabaseStatus
{
    MatchDatabase_Disabled = 0, /**< Запись в базу отключена настройками. */
    MatchDatabase_Connecting,   /**< Плагин устанавливает соединение с базой. */
    MatchDatabase_Ready,        /**< База доступна для записи результатов. */
    MatchDatabase_Unavailable   /**< Соединение не удалось или база недоступна. */
};

/**
 * Вызывается, когда меняется статус готовности подключённого игрока-человека.
 * Для ботов и при очистке статуса во время отключения вызов не отправляется.
 *
 * @param client        Индекс игрока
 * @param ready         true — игрок готов; false — не готов.
 */
forward void DonutMatch_OnPlayerReady(int client, bool ready);

/**
 * Вызывается после обновления счёта раунда.
 *
 * @param scoreT        Текущий счёт террористов.
 * @param scoreCT       Текущий счёт спецназа.
 * @param winnerTeam    Номер победившей команды: 2 — террористы, 3 — спецназ.
 */
forward void DonutMatch_OnRoundScore(int scoreT, int scoreCT, int winnerTeam);

/**
 * Вызывается при начале матча.
 *
 * @param data          Массив: [режим, число игроков, индексы игроков[MAXPLAYERS], команды[MAXPLAYERS]].
 *                      Индексы игроков начинаются с data[2], команды — с data[2 + MAXPLAYERS].
 * @param dataSize      Размер массива в ячейках: 2 + MAXPLAYERS * 2.
 */
forward void DonutMatch_OnMatchStart(const any[] data, int dataSize);

/**
 * Вызывается при завершении матча.
 *
 * @param data          Массив результата: [режим, счёт террористов, счёт спецназа].
 * @param dataSize      Размер массива: 3 ячейки.
 */
forward void DonutMatch_OnMatchEnd(const any[] data, int dataSize);

/**
 * Вызывается при сбросе матча, если до сброса система находилась не в State_ReadySystem.
 * Не заменяет DonutMatch_OnMatchEnd: может вызываться при отмене или принудительном сбросе матча.
 *
 * @param reason        Причина сброса
 */
forward void DonutMatch_OnMatchReset(const char[] reason);

/**
 * Вызывается после 15-го раунда основного времени перед сменой сторон.
 *
 * @param scoreT        Счёт террористов перед сменой сторон.
 * @param scoreCT       Счёт спецназа перед сменой сторон.
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
 * @param scoreT        Счёт террористов перед сменой сторон.
 * @param scoreCT       Счёт спецназа перед сменой сторон.
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
 * Вызывается при переходе матча в другое состояние.
 * 
 * @param oldState Предыдущее состояние.
 * @param newState Новое состояние.
 */
forward void DonutMatch_OnStateChanged(MatchState oldState, MatchState newState);

/** 
 * Вызывается при изменении счёта, в том числе при смене сторон или сбросе.
 * 
 * @param scoreT Текущий счёт команды террористов.
 * @param scoreCT Текущий счёт команды спецназа.
 */
forward void DonutMatch_OnScoreChanged(int scoreT, int scoreCT);

/**
 * Вызывается после полной смены сторон команд T и CT.
 * К этому моменту игроки, счёт, названия команд и свободные слоты замен уже обновлены.
 *
 * @param scoreT  Текущий счёт команды T после смены сторон.
 * @param scoreCT Текущий счёт команды CT после смены сторон.
 */
forward void DonutMatch_OnTeamsSwapped(int scoreT, int scoreCT);

/** 
 * Вызывается, когда игрок добавлен в состав или исключён из него.
 * 
 * @param client Индекс игрока.
 * @param team Команда игрока после изменения: 2 — террористы, 3 — спецназ, 0 — игрок исключён.
 * @param added true, если игрок добавлен; false, если исключён.
 */
forward void DonutMatch_OnRosterChanged(int client, int team, bool added);

/** 
 * Вызывается после изменения отображаемого названия команды.
 * 
 * @param team Команда: 2 — террористы, 3 — спецназ.
 * @param name Новое название команды.
 * @param actor Индекс капитана, изменившего название.
 */
forward void DonutMatch_OnTeamNameChanged(int team, const char[] name, int actor);

/** 
 * Вызывается после успешного выбора игрока в драфте Mix.
 * 
 * @param picker Индекс капитана, сделавшего выбор.
 * @param picked Индекс выбранного игрока.
 * @param team Команда, в которую добавлен игрок: 2 — террористы, 3 — спецназ.
 */
forward void DonutMatch_OnDraftPick(int picker, int picked, int team);

/** 
 * Вызывается после завершения голосования за овертайм.
 * 
 * @param yesVotes Количество голосов «Да».
 * @param noVotes Количество голосов «Нет».
 * @param eligibleVotes Количество игроков, допущенных к голосованию.
 * @param passed true, если порог голосов за овертайм достигнут.
 */
forward void DonutMatch_OnOvertimeVoteFinished(int yesVotes, int noVotes, int eligibleVotes, bool passed);

/** 
 * Вызывается для каждой сформированной записи журнала JSONL.
 * 
 * @param eventName Название события.
 * @param timestamp Время события в Unix-формате.
 * @param fields Фрагмент JSON с полями события.
 */
forward void DonutMatch_OnLogEvent(const char[] eventName, int timestamp, const char[] fields);

/** 
 * Вызывается после успешного сохранения результата матча в SQL-базе.
 * 
 * @param map Название карты.
 * @param mode Режим завершённого матча.
 * @param playersPerSide Количество игроков в каждой команде.
 * @param scoreT Итоговый счёт террористов.
 * @param scoreCT Итоговый счёт спецназа.
 * @param durationSeconds Длительность матча в секундах.
 * @param playedAt Время начала матча в Unix-формате.
 */
forward void DonutMatch_OnDatabaseResultSaved(const char[] map, GameMode mode, int playersPerSide,
    int scoreT, int scoreCT, int durationSeconds, int playedAt);


/** Главный интерфейс для получения состояния и управления матчем DonutMatch. */
methodmap DonutMatch < Handle
{
    /** 
     * Создаёт интерфейс главного объекта плагина.
     * 
     * @return Объект доступа к текущему матчу.
     */
    public DonutMatch() { return view_as<DonutMatch>(0); }
    /** 
     * Проверяет, идёт ли сейчас игровой матч.
     * 
     * @return true, если матч находится в игровом состоянии.
     */
    public native bool IsLive();
    /** 
     * Возвращает состояние системы матча.
     * 
     * @return Текущее значение MatchState.
     */
    public native MatchState State();
    /** 
     * Возвращает выбранный режим системы матча.
     * 
     * @return Значение GameMode; MODE_NONE, если режим не задан.
     */
    public native GameMode Mode();
    /** 
     * Проверяет готовность игрока.
     * 
     * @param client Индекс подключённого игрока.
     * @return true, если игрок отметил готовность.
     */
    public native bool IsReady(int client);
    /** 
     * Устанавливает готовность игрока.
     * 
     * @param client Индекс подключённого игрока.
     * @param ready Новое состояние готовности.
     * @return true, если состояние принято; иначе false.
     * @note После изменения проверяет, можно ли перейти к следующему этапу подготовки или начать матч.
     */
    public native bool SetReady(int client, bool ready);
    /** 
     * Получает текущий счёт матча.
     * 
     * @param scoreT На выходе — счёт террористов.
     * @param scoreCT На выходе — счёт спецназа.
     */
    public native void GetScore(int &scoreT, int &scoreCT);
    /** 
     * Немедленно запускает подготовку матча, если состав и состояние позволяют это.
     * 
     * @return true, если запуск принят; иначе false.
     * @note Готовность игроков при этом принудительном запуске не проверяется.
     */
    public native bool Start();
    /** 
     * Останавливает текущий матч и сбрасывает его состояние.
     * 
     * @param reason Причина остановки, передаваемая в событие сброса.
     * @return true после выполнения сброса состояния матча.
     */
    public native bool Stop(const char[] reason);
    /**
     * Меняет местами всех игроков команд T и CT и переставляет счёт и названия команд.
     *
     * @return true, если стороны переключены; false, если сейчас активен выбор игроков
     *         или матч находится в состоянии голосования/перезапуска карты.
     */
    public native bool SwapTeams();
    /** 
     * Возвращает установленный размер одной команды.
     * 
     * @return Число игроков в команде.
     */
    public native int PlayersPerSide();
    /** 
     * Создаёт копию списка участников текущего состава.
     
     * @return Список индексов игроков; вызывающий код должен вызвать Delete().
     */
    public native ArrayList LivePlayers();
    /** 
     * Проверяет, входит ли игрок в подготовленный или активный состав матча.
     * 
     * @param client Индекс игрока.
     * @return true, если игрок входит в состав.
     */
    public native bool IsPlayerInMatch(int client);
    /** 
     * Получает индекс капитана указанной команды.
     * 
     * @param team Команда: 2 — террористы, 3 — спецназ.
     * @return Индекс капитана или 0, если капитан не назначен.
     */
    public native int Captain(int team);
    /** 
     * Возвращает число раундов в матче или овертайме.
     * 
     * @param overtime true — запросить число раундов овертайма.
     * @return Число раундов для выбранного этапа.
     */
    public native int MaxRounds(bool overtime = false);
    /** 
     * Возвращает счёт команды на перерыве указанного этапа.
     * 
     * @param team Команда: 2 — террористы, 3 — спецназ.
     * @param overtime true — запросить счёт на перерыве овертайма.
     * @return Сохранённый счёт команды на перерыве.
     */
    public native int HalftimeScore(int team, bool overtime = false);
    /** 
     * Копирует название команды в буфер.
     * 
     * @param team Команда: 2 — террористы, 3 — спецназ.
     * @param buffer Буфер, в который будет записано название.
     * @param size Размер буфера в ячейках.
     * @return true при успешном копировании; иначе false.
     */
    public native bool TeamName(int team, char[] buffer, int size);
    /** 
     * Изменяет отображаемое название команды.
     * 
     * @param actor Индекс игрока, выполняющего изменение.
     * @param team Команда: 2 — террористы, 3 — спецназ.
     * @param name Новое название.
     * @return true, если название изменено; иначе false.
     * @note Изменять название может только действующий капитан этой команды.
     */
    public native bool SetTeamName(int actor, int team, const char[] name);
    /** 
     * Возвращает текущий счёт указанной команды.
     * 
     * @param team Команда: 2 — террористы, 3 — спецназ.
     * @return Счёт команды.
     */
    public native int TeamScore(int team);
    /** 
     * Создаёт копию списка подключённых игроков указанной команды.
     * 
     * @param team Команда: 2 — террористы, 3 — спецназ.
     * @return Список индексов игроков; вызывающий код должен вызвать Delete().
     */
    public native ArrayList TeamPlayers(int team);
    /** 
     * Создаёт копию очереди подключённых игроков-людей вне активного состава.
     * 
     * @return Список индексов игроков; вызывающий код должен вызвать Delete().
     */
    public native ArrayList QueuedPlayers();
    /** 
     * Возвращает число свободных мест в команде.
     * 
     * @param team Команда: 2 — террористы, 3 — спецназ.
     * @return Число свободных мест, не меньше нуля.
     */
    public native int OpenSlots(int team);
    /** 
     * Возвращает число игроков, которых не хватает до состава для старта.
     * 
     * @return Недостающее число игроков; 0, если нужное количество уже набрано.
     */
    public native int MissingPlayersToStart();
    /** 
     * Проверяет, можно ли запустить матч в текущем состоянии и с текущим составом.
     * 
     * @return true, если запуск возможен прямо сейчас.
     * @note Готовность игроков не учитывается; метод проверки не запускает матч.
     */
    public native bool CanStart();
    /** 
     * Получает текущее состояние голосования за овертайм.
     * 
     * @param yesVotes На выходе — количество голосов «Да».
     * @param noVotes На выходе — количество голосов «Нет».
     * @param eligibleVotes На выходе — число допущенных к голосованию игроков.
     * @return true, если голосование активно; иначе false. Счётчики заполняются в любом случае.
     */
    public native bool GetOvertimeVote(int &yesVotes, int &noVotes, int &eligibleVotes);
    /** 
     * Запускает предусмотренную настройками процедуру овертайма при равном счёте.
     * 
     * @return true, если запуск овертайма или голосования принят; иначе false.
     */
    public native bool StartOvertime();
    /** 
     * Возвращает состояние соединения с базой результатов.
     * 
     * @return Значение MatchDatabaseStatus.
     */
    public native MatchDatabaseStatus DatabaseStatus();
    /** 
     * Добавляет пользовательское событие в журнал JSONL и вызывает соответствующий форвард.
     * 
     * @param source Источник события.
     * @param eventName Название события.
     * @param payload Данные события в виде строки; строка корректно экранируется.
     * @return true, если событие принято системой журнала.
     */
    public native bool LogEvent(const char[] source, const char[] eventName, const char[] payload);
    /** 
     * Проверяет, сохранены ли данные последнего матча.
     * 
     * @return true, если доступны сведения о последнем матче.
     */
    public native bool HasLastMatch();
    /** 
     * Получает режим последнего матча.
     * 
     * @return Значение GameMode последнего матча.
     */
    public native GameMode LastMatchMode();
    /** 
     * Получает итоговый счёт последнего матча.
     * 
     * @param scoreT На выходе — счёт террористов.
     * @param scoreCT На выходе — счёт спецназа.
     * @note Если завершённого матча ещё не было, оба значения равны 0; проверяйте HasLastMatch().
     */
    public native void GetLastMatchScore(int &scoreT, int &scoreCT);
    /** 
     * Копирует название команды последнего матча в буфер.
     * 
     * @param team Команда: 2 — террористы, 3 — спецназ.
     * @param buffer Буфер для названия.
     * @param size Размер буфера в ячейках.
     * @return true при успешном копировании; иначе false.
     */
    public native bool LastTeamName(int team, char[] buffer, int size);
};

/** Объект для управления конкретным игроком матча. */
methodmap MatchPlayer < Handle
{
    /** 
     * Создаёт объект-обёртку для индекса игрока.
     * 
     * @param client Индекс игрока на сервере.
     * @return Объект для чтения данных и управления этим игроком.
     */
    public MatchPlayer(int client) { return view_as<MatchPlayer>(client); }
    /** 
     * Проверяет, подключён ли игрок и является ли он человеком.
     * 
     * @return true, если индекс относится к подключённому игроку; иначе false.
     */
    public native bool IsValid();
    /** 
     * Проверяет, отметил ли игрок готовность.
     * 
     * @return true, если игрок готов; иначе false.
     */
    public native bool IsReady();
    /** 
     * Устанавливает готовность игрока через DonutMatch.
     * 
     * @param ready Новое состояние готовности.
     * @return true, если изменение принято; иначе false.
     * @note При изменении статуса вызывается DonutMatch_OnPlayerReady.
     * @note Затем проверяется, можно ли перейти к следующему этапу подготовки или начать матч.
     */
    public native bool SetReady(bool ready);
    /** 
     * Проверяет, входит ли игрок в выбранный или активный состав.
     * 
     * @return true, если игрок входит в состав; иначе false.
     */
    public native bool IsInRoster();
    /** 
     * Проверяет, назначен ли игрок капитаном.
     * 
     * @return true, если игрок является капитаном; иначе false.
     */
    public native bool IsCaptain();
    /** 
     * Возвращает номер команды игрока.
     * 
     * @return Номер команды SourceMod: 2 — террористы, 3 — спецназ; 0, если команда отсутствует.
     */
    public native int Team();
    /** 
     * Возвращает число убийств игрока в текущей статистике таблицы счёта.
     * 
     * @return Число убийств.
     */
    public native int Frags();
    /** 
     * Возвращает число смертей игрока в текущей статистике таблицы счёта.
     * 
     * @return Число смертей.
     */
    public native int Deaths();
    /** 
     * Добавляет невыбранного игрока из наблюдателей в свободное место команды Mix.
     * 
     * @param team Команда: 2 — террористы, 3 — спецназ.
     * @return true, если игрок добавлен; иначе false.
     * @note Доступно только в фазе набора состава и при наличии свободного места.
     */
    public native bool AssignToTeam(int team);
    /** 
     * Удаляет участника Mix из состава и переводит его в наблюдатели.
     * 
     * @return true, если игрок удалён из состава; иначе false.
     * @note Капитана и игрока уже начавшегося матча удалить этим методом нельзя.
     */
    public native bool RemoveFromRoster();
    /** 
     * Возвращает идентификатор пользователя SourceMod.
     * 
     * @return UserID игрока или 0, если объект недействителен.
     */
    public native int UserId();
    /** 
     * Копирует Steam-идентификатор игрока в формате Steam2.
     * 
     * @param buffer Буфер для идентификатора.
     * @param size Размер буфера в ячейках.
     * @return true, если идентификатор получен и скопирован; иначе false.
     */
    public native bool AuthId(char[] buffer, int size);
    /** 
     * Копирует текущее имя игрока в буфер.
     * 
     * @param buffer Буфер для имени.
     * @param size Размер буфера в ячейках.
     * @return true, если имя получено и скопировано; иначе false.
     */
    public native bool Name(char[] buffer, int size);
    /** 
     * Проверяет, жив ли игрок.
     * 
     * @return true, если игрок жив; иначе false.
     */
    public native bool IsAlive();
    /** 
     * Возвращает количество денег игрока.
     * 
     * @return Баланс игрока или 0, если объект недействителен.
     */
    public native int Money();
    /** 
     * Возвращает урон, нанесённый целевому игроку в текущем игровом раунде.
     * 
     * @param target Игрок, которому был нанесён урон.
     * @return Суммарный урон или 0, если данные недоступны.
     */
    public native int DamageTo(MatchPlayer target);
    /** 
     * Возвращает число попаданий по целевому игроку в текущем игровом раунде.

     * @param target Игрок, по которому стреляли.
     * @return Число попаданий или 0, если данные недоступны.
     */
    public native int HitsTo(MatchPlayer target);
    /** 
     * Получает игрока, запросившего замену этому игроку.
     * 
     * @return Индекс запрашивающего игрока или 0, если активного запроса нет.
     */
    public native int PendingSubstituteRequester();
    /** 
     * Получает игрока, которого этот игрок запросил заменить.
     * 
     * @return Индекс целевого игрока или 0, если запрос не отправлен или уже завершён.
     */
    public native int PendingSubstituteTarget();
    /** 
     * Запускает для игрока стандартную процедуру запроса замены, аналогичную команде !ask.
     * 
     * @return true, если меню выбора замены открыто; иначе false.
     * @note Метод доступен участнику активного матча Mix в подходящем состоянии.
     */
    public native bool AskForSubstitute();
};

/** Объект драфта Mix. */
methodmap MatchDraft < Handle
{
    /** 
     * Создаёт интерфейс текущего драфта.
     * 
     * @return Объект доступа к драфту.
     */
    public MatchDraft() { return view_as<MatchDraft>(0); }
    /** 
     * Проверяет, идёт ли сейчас выбор игроков Mix.
     * 
     * @return true, если активна фаза драфта; иначе false.
     */
    public native bool IsActive();
    /** 
     * Возвращает число доступных кандидатов.
     * 
     * @return Количество кандидатов; 0, если драфт неактивен или кандидатов нет.
     */
    public native int CandidateCount();
    /** 
     * Возвращает капитана, который должен сделать следующий выбор.
     * 
     * @return Объект MatchPlayer текущего выбирающего либо недействительный объект, если драфт неактивен.
     */
    public native MatchPlayer CurrentPicker();
    /** 
     * Создаёт копию списка кандидатов драфта.
     * 
     * @return Список индексов игроков; вызывающий код должен вызвать Delete(). При неактивном драфте список пуст.
     */
    public native ArrayList Candidates();
    /** 
     * Принудительно выбирает кандидата текущим капитаном и продвигает драфт.
     * 
     * @param player Объект игрока-кандидата.
     * @return true, если выбор выполнен; иначе false.
     */
    public native bool ForcePick(MatchPlayer player);
    /** 
     * Немедленно завершает драфт и переводит матч к подтверждению готовности.
     * 
     * @return true, если активный драфт завершён; иначе false.
     * @note Метод может завершить набор с незаполненными местами в командах.
     */
    public native bool Finish();
    /** 
     * Устанавливает выбранную сторону для команды в режиме War.
     * 
     * @param team Выбранная сторона: 2 — террористы, 3 — спецназ.
     * @return true, если выбор стороны принят; иначе false.
     * @note Вызвать метод может только текущий игрок, выбирающий сторону, во время соответствующей фазы.
     */
    public native bool ChooseSide(int team);
};

/**
 * Записывает текстовое название режима игры в буфер.
 *
 * @param mode          Значение GameMode
 * @param buffer        Буфер для названия режима
 * @param size          Размер буфера
 * @return              true, если режим распознан и строка записана; иначе false.
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
 * Записывает текстовое название состояния матча в буфер.
 *
 * @param state         Значение MatchState
 * @param buffer        Буфер для названия состояния
 * @param size          Размер буфера
 * @return              true, если состояние распознано и строка записана; иначе false.
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
 * Разбирает массив данных, переданный в DonutMatch_OnMatchStart.
 *
 * @param data          Исходный массив события: режим, количество игроков, индексы игроков и их команды.
 * @param mode          На выходе — режим матча.
 * @param playerCount   На выходе — число игроков в составе.
 * @param players       На выходе — индексы игроков; массив должен вмещать MAXPLAYERS элементов.
 * @param teams         На выходе — команды соответствующих игроков; массив должен вмещать MAXPLAYERS элементов.
 * @return              true, если количество игроков допустимо и данные разобраны; иначе false.
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
 * Разбирает массив результата, переданный в DonutMatch_OnMatchEnd.
 *
 * @param data          Исходный массив: режим, счёт террористов и счёт спецназа.
 * @param mode          На выходе — режим завершённого матча.
 * @param scoreT        На выходе — итоговый счёт террористов.
 * @param scoreCT       На выходе — итоговый счёт спецназа.
 * @return              true после разбора значений.
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
    MarkNativeAsOptional("DonutMatch.IsLive");
    MarkNativeAsOptional("DonutMatch.State");
    MarkNativeAsOptional("DonutMatch.Mode");
    MarkNativeAsOptional("DonutMatch.IsReady");
    MarkNativeAsOptional("DonutMatch.SetReady");
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
    MarkNativeAsOptional("MatchPlayer.IsValid");
    MarkNativeAsOptional("MatchPlayer.IsReady");
    MarkNativeAsOptional("MatchPlayer.SetReady");
    MarkNativeAsOptional("MatchPlayer.IsInRoster");
    MarkNativeAsOptional("MatchPlayer.IsCaptain");
    MarkNativeAsOptional("MatchPlayer.Team");
    MarkNativeAsOptional("MatchPlayer.Frags");
    MarkNativeAsOptional("MatchPlayer.Deaths");
    MarkNativeAsOptional("MatchPlayer.AskForSubstitute");
    MarkNativeAsOptional("MatchPlayer.UserId");
    MarkNativeAsOptional("MatchPlayer.AssignToTeam");
    MarkNativeAsOptional("MatchPlayer.RemoveFromRoster");
    MarkNativeAsOptional("MatchPlayer.AuthId");
    MarkNativeAsOptional("MatchPlayer.Name");
    MarkNativeAsOptional("MatchPlayer.IsAlive");
    MarkNativeAsOptional("MatchPlayer.Money");
    MarkNativeAsOptional("MatchPlayer.DamageTo");
    MarkNativeAsOptional("MatchPlayer.HitsTo");
    MarkNativeAsOptional("MatchPlayer.PendingSubstituteRequester");
    MarkNativeAsOptional("MatchPlayer.PendingSubstituteTarget");
    MarkNativeAsOptional("MatchDraft.IsActive");
    MarkNativeAsOptional("MatchDraft.CandidateCount");
    MarkNativeAsOptional("MatchDraft.CurrentPicker");
    MarkNativeAsOptional("MatchDraft.Candidates");
    MarkNativeAsOptional("MatchDraft.ForcePick");
    MarkNativeAsOptional("MatchDraft.Finish");
    MarkNativeAsOptional("MatchDraft.ChooseSide");
}
#endif
