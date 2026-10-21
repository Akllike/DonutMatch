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
    State_ReadySystem,      /**< Сбор состава и ожидание готовности игроков. */
    State_Warmup,           /**< Фаза разминки. */
    State_CaptainKnife,     /**< Ножевой раунд капитанов в режиме Mix. */
    State_PickingPlayers,   /**< Выбор игроков капитанами в режиме Mix. */
    State_KnifeRound_WAR,   /**< Ножевой раунд выбора стороны в режиме War. */
    State_Starting,         /**< Матч запускается. */
    State_Live,             /**< Идёт основное время матча. */
    State_Overtime,         /**< Идёт овертайм. */
    State_MapVoteWait,      /**< Матч завершён; ожидается результат голосования за карту. */
    State_MapRestartDelay   /**< Перезапуск Mix отложен после выбора текущей карты. */
};

enum MatchDatabaseStatus
{
    MatchDatabase_Disabled = 0, /**< Запись в базу отключена настройками. */
    MatchDatabase_Connecting,   /**< Плагин устанавливает соединение с базой. */
    MatchDatabase_Ready,        /**< База доступна для записи результатов. */
    MatchDatabase_Unavailable   /**< Соединение не удалось или база недоступна. */
};

/** Причина текущей паузы матча. */
enum MatchPauseReason
{
    Pause_Tactical = 0, /**< Запрошена игроком командой !pause. */
    Pause_OvertimeVote, /**< Пауза для голосования за овертайм. */
    Pause_API           /**< Запрошена через DonutMatch.SetPaused(). */
};

/** Формат War-матча или серии карт. */
enum WarSeriesMode
{
    WarSeries_Unknown = -1, /**< Матч не War или формат ещё не выбран. */
    WarSeries_BO1 = 0,      /**< Серия из одной карты. */
    WarSeries_BO3,          /**< Серия до двух побед. */
    WarSeries_BO5,          /**< Серия до трёх побед. */
    WarSeries_Classic       /**< Обычный матч War без серии карт. */
};

/** Идентификатор команды серии War. */
enum WarSeriesTeam
{
    WarSeries_None = -1, /**< Команда не определена. */
    WarSeries_TeamA = 0, /**< Команда A, определённая при начале серии. */
    WarSeries_TeamB      /**< Команда B, определённая при начале серии. */
};

/** Действие на текущем шаге выбора карт серии War. */
enum WarVetoAction
{
    WarVeto_None = -1, /**< Выбор карт сейчас не выполняется. */
    WarVeto_Ban = 0,   /**< Бан карты. */
    WarVeto_Pick       /**< Выбор карты. */
};

/**
 * Вызывается при изменении готовности подключённого игрока-человека.
 * Для ботов и при очистке готовности во время отключения вызов не отправляется.
 *
 * @param client        Индекс игрока.
 * @param ready         true — игрок готов; false — не готов.
 */
forward void DonutMatch_OnPlayerReady(int client, bool ready);

/** Вызывается при начале или завершении активной паузы. */
forward void DonutMatch_OnPauseChanged(bool paused, MatchPauseReason reason, int team, int requesterUserId);

/** Вызывается при постановке tactical pause в очередь на следующий раунд.
 *
 * @param team Команда: 2 — T, 3 — CT; 0 при запросе через API.
 * @param requesterUserId UserID игрока; 0 при запросе через API.
 * @param apiRequest true, если пауза запрошена через native.
 * @param pausesRemaining Сколько тактических пауз осталось у команды после этой заявки; 0 для API.
 */
forward void DonutMatch_OnPauseRequested(int team, int requesterUserId, bool apiRequest, int pausesRemaining);

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
 * @param data          Массив: [режим, число игроков, игроки[MAXPLAYERS], команды[MAXPLAYERS], формат War].
 *                      Индексы игроков начинаются с data[2], команды — с data[2 + MAXPLAYERS].
 *                      Формат находится в data[2 + MAXPLAYERS * 2]: WarSeries_Unknown для Mix,
 *                      либо WarSeries_Classic/BO1/BO3/BO5 для War.
 * @param dataSize      Размер массива в ячейках: 3 + MAXPLAYERS * 2.
 */
forward void DonutMatch_OnMatchStart(const any[] data, int dataSize);

/**
 * Вызывается при завершении матча.
 *
 * @param data          Массив результата: [режим, счёт T, счёт CT, формат War].
 *                      Формат находится в data[3]: WarSeries_Unknown для Mix,
 *                      либо WarSeries_Classic/BO1/BO3/BO5 для War.
 * @param dataSize      Размер массива: 4 ячейки.
 */
forward void DonutMatch_OnMatchEnd(const any[] data, int dataSize);

/**
 * Вызывается при сбросе матча, если до сброса система находилась не в State_ReadySystem.
 * Не заменяет DonutMatch_OnMatchEnd: может вызываться при отмене или принудительном сбросе матча.
 *
 * @param reason        Причина сброса.
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
 * @param mode          Режим матча.
 * @param players       Массив индексов активных игроков состава.
 * @param playerCount   Количество игроков в массиве.
 * @param overtime      true для перерыва овертайма; false для основного времени.
 * @param scoreT        Счёт террористов перед сменой сторон.
 * @param scoreCT       Счёт спецназа перед сменой сторон.
 */
forward void DonutMatch_OnMatchHalfTime(GameMode mode, const int[] players, int playerCount, bool overtime, int scoreT, int scoreCT);

/**
 * Вызывается после того, как игрок согласился на замену, но до смены команд.
 * Верните Plugin_Continue, чтобы разрешить замену; любое другое значение Action отменит её.
 *
 * @param client        Игрок, запросивший замену и покидающий состав.
 * @param target        Игрок, входящий в состав.
 */
forward Action DonutMatch_OnPlayerReplacePre(int client, int target);

/**
 * Вызывается после успешной замены и обновления внутреннего состава.
 *
 * @param client        Игрок, запросивший замену и покинувший состав.
 * @param target        Игрок, вошедший в состав.
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
forward void DonutMatch_OnDatabaseResultSaved(const char[] map, GameMode mode, int playersPerSide, int scoreT, int scoreCT, int durationSeconds, int playedAt);

/**
 * Вызывается после успешной проверки пула карт и до первого шага veto.
 *
 * @param mode          Формат серии.
 * @param mapsToWin     Количество победных карт, необходимое для завершения серии.
 * @param bestOf        Максимальное количество карт в серии (1, 3 или 5).
 */
forward void DonutMatch_OnWarSeriesStart(WarSeriesMode mode, int mapsToWin, int bestOf);

/**
 * Вызывается после каждого успешного выбора или бана карты.
 *
 * @param team          Команда, сделавшая выбор.
 * @param action        Выполненное действие.
 * @param mapName       Название выбранной или забаненной карты.
 * @param step          Номер шага veto, начиная с 1.
 * @param stepCount     Общее количество шагов veto.
 * @param client        Индекс капитана; 0, если действие выполнено автоматически.
 * @param automatic     true, если решение принято автоматически.
 */
forward void DonutMatch_OnWarVetoChoice(WarSeriesTeam team, WarVetoAction action, const char[] mapName, int step, int stepCount, int client, bool automatic);

/** Вызывается после формирования порядка карт; итоговый список доступен через DonutMatch.WarSeriesMaps(). */
forward void DonutMatch_OnWarSeriesVetoComplete();

/**
 * Вызывается после завершения карты серии.
 *
 * @param mapIndex      Нулевой индекс завершённой карты.
 * @param mapName       Название карты.
 * @param winner        Победитель карты или WarSeries_None при ничьей.
 * @param scoreT        Итоговый счёт террористов.
 * @param scoreCT       Итоговый счёт спецназа.
 * @param teamAWins     Победы команды A после завершения карты.
 * @param teamBWins     Победы команды B после завершения карты.
 */
forward void DonutMatch_OnWarSeriesMapEnd(int mapIndex, const char[] mapName, WarSeriesTeam winner, int scoreT, int scoreCT, int teamAWins, int teamBWins);

/**
 * Вызывается после завершения серии, до очистки её состояния.
 *
 * @param winner        Победитель серии.
 * @param teamAWins     Количество побед команды A.
 * @param teamBWins     Количество побед команды B.
 */
forward void DonutMatch_OnWarSeriesEnd(WarSeriesTeam winner, int teamAWins, int teamBWins);


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
     * Возвращает выбранный формат текущего War-матча.
     * @return WarSeries_Classic или WarSeries_BO1/BO3/BO5; Unknown, если формат ещё не выбран или режим не War.
     */
    public native WarSeriesMode WarMatchFormat();
    /**
     * Возвращает формат последнего завершённого матча War.
     * @return WarSeries_Classic, WarSeries_BO1/3/5 или WarSeries_Unknown.
     */
    public native WarSeriesMode LastWarMatchFormat();
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
     * @note Возвращает false во время голосования капитанов за формат War.
     */
    public native bool Start();
    /**
     * Останавливает текущий матч и сбрасывает его состояние.
     *
     * @param reason Причина остановки, передаваемая в событие сброса.
    * @return true, если запрос сброса обработан; результат не указывает, был ли активен матч.
     */
    public native bool Stop(const char[] reason);
    /**
     * Меняет местами игроков команд T и CT, счёт и названия команд.
     *
     * @return true, если стороны переключены; иначе false.
     * @note Возвращает false, если режим не задан, идёт драфт Mix или голосование за формат War,
     *       либо выполняется переход/голосование за карту.
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
     *
     * @return Список индексов игроков-людей; после использования вызовите Delete().
     */
    public native ArrayList LivePlayers();
    /**
     * Проверяет, входит ли игрок в подготовленный или активный состав матча.
     *
     * @param client Индекс игрока.
     * @return true, если игрок входит в состав.
     * @note Эквивалентно MatchPlayer(client).IsInRoster(); этот метод оставлен как форма с явным client.
     */
    public native bool IsPlayerInMatch(int client);
    /**
     * Получает индекс капитана указанной команды.
     *
     * @param team Команда: 2 — террористы, 3 — спецназ.
     * @return Индекс капитана или 0, если капитан не назначен. В режимах Mix и War у каждой стороны есть свой капитан.
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
     * @note Изменять название может только действующий капитан этой команды в состояниях ReadySystem, PickingPlayers, Starting, Live или Overtime.
     * @note В серии BO название сохраняется за командой до завершения серии.
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
     * @return Список индексов подключённых игроков-людей; после использования вызовите Delete().
     */
    public native ArrayList TeamPlayers(int team);
    /**
     * Создаёт копию очереди игроков-наблюдателей, не входящих в подготовленный или активный состав.
     *
     * @return Список индексов подключённых игроков-людей; после использования вызовите Delete().
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
     * @note Возвращает false во время голосования капитанов за формат War.
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
    /** Проверяет, активна ли сейчас пауза матча. */
    public native bool IsPaused();
    /** Проверяет, ожидается ли тактическая/API пауза на следующий раунд. */
    public native bool IsPausePending();
    /**
     * Ставит 30-секундную паузу в очередь на следующий раунд или отменяет API-заявку.
     *
     * @param paused true — поставить паузу в очередь; false — отменить ожидающую API-заявку.
     * @return true, если действие принято; false, если запрос конфликтует с текущим состоянием.
     */
    public native bool SetPaused(bool paused);
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
     * @param payload Данные события; строка корректно экранируется при записи.
     * @return true, если событие принято; иначе false при недопустимых символах или превышении лимита.
     * @note source и eventName должны быть непустыми и содержать только латинские буквы, цифры, '_', '-' или '.'.
     * @note Максимальная длина без завершающего нуля: source/eventName — 63 ячейки, payload — 255 ячеек.
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
    /**
        * Возвращает формат активной серии или следующий формат War, если серия неактивна.
        * @return WarSeries_Classic по умолчанию, либо WarSeries_BO1, WarSeries_BO3 или WarSeries_BO5.
        * @note Не определяет формат выбранного матча War; для этого используйте WarMatchFormat().
     */
    public native WarSeriesMode WarSeriesMode();
    /**
     * Проверяет, активна ли серия War, включая veto и переходы между картами.
     * @return true, если серия активна; иначе false.
     */
    public native bool IsWarSeriesActive();
    /**
     * Возвращает количество выигранных карт указанной команды.
     * @param team Команда серии: WarSeries_TeamA или WarSeries_TeamB.
     * @return Количество побед команды.
     */
    public native int WarSeriesWins(WarSeriesTeam team);
    /**
     * Возвращает число победных карт, необходимое для завершения серии.
     * @return Требуемое число побед.
     */
    public native int WarSeriesMapsToWin();
    /**
     * Возвращает нулевой индекс текущей карты серии.
     * @return Индекс карты в серии.
     */
    public native int WarSeriesMapIndex();
    /**
     * Возвращает действие текущего шага выбора карт.
     * @return WarVeto_Ban, WarVeto_Pick или WarVeto_None, если выбор не активен.
     */
    public native WarVetoAction CurrentWarVetoAction();
    /**
     * Возвращает команду серии, чей ход в выборе карт.
     * @return WarSeries_TeamA, WarSeries_TeamB или WarSeries_None, если выбор не активен.
     */
    public native WarSeriesTeam CurrentWarVetoTeam();
    /**
     * Возвращает индекс капитана, который должен сделать текущий выбор.
     * @return Индекс клиента или 0, если выбор не активен.
     */
    public native int CurrentWarVetoCaptain();
    /**
     * Возвращает текущий номер шага veto и общее число шагов.
     * @param step На выходе — номер шага, начиная с 1; 0, если veto неактивно.
     * @param stepCount На выходе — общее число шагов.
     */
    public native void GetWarVetoProgress(int &step, int &stepCount);
    /**
     * Создаёт копию проверенного исходного пула карт серии.
     * @return ArrayList названий карт; после использования вызовите Delete().
     */
    public native ArrayList WarSeriesMapPool();
    /**
     * Создаёт копию карт, доступных для текущего veto.
     * @return ArrayList названий карт; после использования вызовите Delete().
     */
    public native ArrayList WarSeriesAvailableMaps();
    /**
     * Создаёт копию забаненных карт серии.
     * @return ArrayList названий карт; после использования вызовите Delete().
     */
    public native ArrayList WarSeriesBannedMaps();
    /**
     * Создаёт копию карт, выбранных капитанами, в порядке выбора.
     * @return ArrayList названий карт; после использования вызовите Delete().
     */
    public native ArrayList WarSeriesPickedMaps();
    /**
     * Создаёт копию полного порядка карт серии после завершения veto.
     * @return ArrayList названий карт; до завершения veto список может быть пустым; после использования вызовите Delete().
     */
    public native ArrayList WarSeriesMaps();
    /**
     * Задаёт формат следующей серии War и пропускает голосование капитанов за формат.
     * @param mode Формат серии: WarSeries_BO1, WarSeries_BO3 или WarSeries_BO5.
     * @return true, если формат задан; иначе false.
     * @note Возвращает false во время активной серии или голосования за формат.
     */
    public native bool SetWarSeriesMode(WarSeriesMode mode);
    /**
     * Задаёт строку пула карт для следующей серии War.
     * @param mapPool Список названий карт через запятую.
     * @return true, если строка принята; иначе false.
     * @note Изменение запрещено во время активной серии.
     */
    public native bool SetWarSeriesMapPool(const char[] mapPool);
    /**
     * Принимает veto-выбор текущего капитана для доступной карты.
     * @param client Индекс подключённого капитана, которому принадлежит текущий ход.
     * @param mapName Название карты из списка доступных карт.
     * @return true, если выбор принят; иначе false.
     */
    public native bool ChooseWarVetoMap(int client, const char[] mapName);
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
     * Добавляет игрока, ещё не входящего в состав, в свободное место команды Mix.
     *
     * @param team Команда: 2 — террористы, 3 — спецназ.
     * @return true, если игрок добавлен; иначе false.
     * @note Доступно человеку в фазе подтверждения состава Mix, если в указанной команде есть место.
     * @note Игрок может находиться не только в наблюдателях: метод переведёт его в указанную команду.
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
     * @param size Размер буфера в ячейках; для полного Steam2-идентификатора рекомендуется не менее 34.
     * @return true, если полный идентификатор получен и скопирован; иначе false. При недостаточном размере буфера строка не обрезается.
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
     *
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
    * @return Список индексов игроков; после использования вызовите Delete(). При неактивном драфте список пуст.
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
     * @note Метод принимает выбор за текущего игрока, которому передано право выбрать сторону.
     * @note Вызывающий плагин сам отвечает за проверку своих прав.
     */
    public native bool ChooseSide(int team);
};

/**
 * Записывает текстовое название режима игры в буфер.
 *
 * @param mode          Значение GameMode.
 * @param buffer        Буфер для названия режима.
 * @param size          Размер буфера в ячейках.
 * @return true, если режим распознан и строка записана; иначе false.
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
 * @param state         Значение MatchState.
 * @param buffer        Буфер для названия состояния.
 * @param size          Размер буфера в ячейках.
 * @return true, если состояние распознано и строка записана; иначе false.
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
 * @param data          Массив DonutMatch_OnMatchStart размером не менее 3 + MAXPLAYERS * 2 ячеек.
 * @param mode          На выходе — режим матча.
 * @param playerCount   На выходе — число игроков в составе.
 * @param players       Массив для индексов игроков; должен вмещать MAXPLAYERS элементов.
 * @param teams         Массив для команд игроков; должен вмещать MAXPLAYERS элементов.
 * @return true, если число игроков находится в диапазоне 1..MAXPLAYERS; иначе false.
 * @note Формат War расположен в data[2 + MAXPLAYERS * 2]; функция его не копирует.
 * @note Размер входного и выходных массивов должен быть достаточным; функция его не проверяет.
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
 * @param data          Массив DonutMatch_OnMatchEnd размером не менее 4 ячеек.
 * @param mode          На выходе — режим завершённого матча.
 * @param scoreT        На выходе — итоговый счёт террористов.
 * @param scoreCT       На выходе — итоговый счёт спецназа.
 * @return true после копирования значений.
 * @note Формат War расположен в data[3]; функция его не копирует.
 * @note Размер входного массива должен быть не менее 4 ячеек; функция его не проверяет.
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
    MarkNativeAsOptional("DonutMatch.IsPaused");
    MarkNativeAsOptional("DonutMatch.IsPausePending");
    MarkNativeAsOptional("DonutMatch.SetPaused");
    MarkNativeAsOptional("DonutMatch.StartOvertime");
    MarkNativeAsOptional("DonutMatch.DatabaseStatus");
    MarkNativeAsOptional("DonutMatch.LogEvent");
    MarkNativeAsOptional("DonutMatch.HasLastMatch");
    MarkNativeAsOptional("DonutMatch.LastMatchMode");
    MarkNativeAsOptional("DonutMatch.GetLastMatchScore");
    MarkNativeAsOptional("DonutMatch.LastTeamName");
    MarkNativeAsOptional("DonutMatch.WarMatchFormat");
    MarkNativeAsOptional("DonutMatch.LastWarMatchFormat");
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
