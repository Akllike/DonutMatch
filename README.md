<p align="center">
  <img width="300" alt="DonutMatch" src="https://github.com/user-attachments/assets/e23ba4f5-5091-40af-ba7c-89d365da4420" />
</p>

<h1 align="center">DonutMatch</h1>
<p align="center">Mix и War матчи для Counter-Strike: Source — от сбора игроков до финального счёта.</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-6.1--global--test-blue" alt="Version 6.1-global-test">
  <img src="https://img.shields.io/badge/SourceMod-1.10%2B-green" alt="SourceMod 1.10+">
  <img src="https://img.shields.io/badge/game-Counter--Strike%3A%20Source-orange" alt="Counter-Strike: Source">
</p>

---

## Что умеет плагин

| **Mix** | **War** |
|---|---|
| Собирает игроков, проводит ножевой раунд капитанов и помогает выбрать команды. | После сбора игроков позволяет выбрать ножевой раунд за сторону или сразу начать матч. |
| Поддерживает замены во время матча. | При счёте 15:15 запускает овертайм. |

**Для обоих режимов:** форматы от 2×2 до 5×5, автоматический подсчёт раундов, смена сторон и определение победителя. По желанию можно включить запись SourceTV, журналы матчей и сохранение результатов в базе данных.

## Быстрый старт

1. Убедитесь, что на сервере установлены **SourceMod 1.10+** и стандартный плагин **MapChooser**. MapChooser обязателен: без него DonutMatch не загрузится.
2. Возьмите `donut_match.smx` из [`addons/sourcemod/plugins`](addons/sourcemod/plugins).
3. Поместите файл плагина в `addons/sourcemod/plugins/`.
4. Запустите сервер или загрузите плагин командой:

   ```text
   sm plugins load donut_match
   ```

5. Откройте созданный плагином файл `cfg/sourcemod/donutmatch/donutmatch.cfg` и задайте режим и формат матча.
6. Игроки переходят в T и CT, затем отмечаются готовыми командой `!ready`.

> Include для разработчиков [`donutmatch.inc`](scripting/include/donutmatch.inc) устанавливайте отдельно, только если другие плагины будут использовать API DonutMatch.

## Как начать матч

### Игрокам

Введите команду в чате:

| Команда | Что делает |
|---|---|
| `!ready` или `!r` | Отметиться готовым или снять готовность. Доступно игрокам в T/CT во время сбора. |
| `!info` | Посмотреть, кто уже готов. |
| `!knife` | В режиме War начать ножевой раунд за выбор стороны. |
| `!stay` | В режиме War начать матч без ножевого раунда. |
| `!score` или `!scores` | Посмотреть текущий счёт или результат последнего матча. |
| `!lastscore` | Посмотреть счёт последнего завершённого матча. |
| `!ask` | В Mix предложить наблюдателю заменить вас. |
| `!damage` | Посмотреть нанесённый и полученный урон за текущий раунд. |
| `!money` | Показать деньги и основное оружие команды. |

Команды также можно вводить в консоли с префиксом `sm_`: например, `sm_ready`.

**Замена в Mix:** используйте `!ask`, выберите игрока-наблюдателя и дождитесь ответа. Если приглашённый игрок откажется или не ответит за отведённое время, он будет кикнут.

### Администраторам

| Команда | Назначение | Доступ |
|---|---|---|
| `sm_forcemix` | Принудительно начать Mix, минуя обычную подготовку. | Root (`z`) |
| `sm_forcewar` | Принудительно начать War, минуя обычную подготовку. | Root (`z`) |
| `sm_donut_forceallready` | Отметить готовыми всех игроков в T/CT. | Root (`z`) |
| `sm_donut_forceallunready` | Снять готовность у игроков в T/CT. | Root (`z`) |
| `sm_forcevote` | Запустить голосование за следующую карту. | Change Map (`c`) |

Для принудительного старта нужен полный состав, поровну распределённый между командами. Принудительный Mix начинает матч сразу — без ножевого раунда капитанов и выбора игроков.

## Настройки

Основные параметры находятся в `cfg/sourcemod/donutmatch/donutmatch.cfg`. Плагин создаёт этот файл при первом запуске.

| Параметр | По умолчанию | Значение |
|---|---:|---|
| `sm_donut_mode` | `1` | Режим: `1` — Mix, `2` — War |
| `sm_donut_players_per_side` | `5` | Игроков в каждой команде: от 2 до 5 |
| `sm_donut_restart_delay` | `3.5` | Задержка перед стартом, в секундах |
| `sm_donut_auto_ready` | `0` | Автоматически отмечать новых игроков готовыми: `0` — нет, `1` — да |
| `sm_donut_sub_time` | `10` | Сколько секунд дать на ответ по замене |
| `sm_donut_auto_record` | `1` | Записывать SourceTV-демо матчей |
| `sm_donut_log_matches` | `1` | Записывать события матча в JSONL-файл |
| `sm_donut_database_enabled` | `0` | Сохранять результаты в базу данных |
| `sm_donut_block_warmup_grenades` | `1` | Блокировать гранаты и autobuy/rebuy до live-раунда |
| `sm_donut_round_money` | `1` | Показывать деньги и основное оружие в начале раунда |
| `sm_donut_log_level` | `1` | Подробность лога: `0` — Debug, `1` — Info, `2` — Warn, `3` — Error |

> Изменение режима или формата сбрасывает текущую подготовку или матч.

<details>
<summary><strong>Дополнительно: конфиги режимов, база данных и логи</strong></summary>

### Конфиги режимов

Дополнительные конфиги создаются вручную в `cfg/donutmatch/`:

| Файл | Когда применяется |
|---|---|
| `donut_server_start.cfg` | При загрузке плагина |
| `donut_warmup.cfg` | При сбросе матча и возврате к ожиданию |
| `donut_mix_start.cfg` | При подготовке Mix |
| `donut_war_start.cfg` | При подготовке War и перед второй половиной |
| `donut_mix_end.cfg` | После Mix |
| `donut_war_end.cfg` | После War |
| `donut_war_overtime_start.cfg` | В начале каждого War-овертайма |

### Сохранение результатов

Для базы данных установите `sm_donut_database_enabled 1` и добавьте подключение с именем `donutmatch` в `addons/sourcemod/configs/databases.cfg`. Таблица `donutmatch_results` создаётся автоматически.

- Журналы событий матчей: `addons/sourcemod/logs/donutmatch/`.
- Диагностический лог: `donutmatch.log` в каталоге логов SourceMod.
- Для записи демо включите SourceTV (`tv_enable 1`).

</details>

## Требования

- Counter-Strike: Source.
- SourceMod 1.10 или новее.
- Стандартный SourceMod MapChooser.
- SourceTV — только если нужна запись демо.

## Поддержка

Нашли ошибку или хотите предложить улучшение? [Создайте Issue](https://github.com/Akllike/DonutMatch/issues) и укажите версию плагина и шаги для воспроизведения.

- [Группа ВКонтакте](https://vk.com/jquerry)
- [Telegram](https://t.me/donutmatch)

> Плагин находится в разработке. Возможны ошибки и нестабильная работа.

## Для разработчиков: SourcePawn API

Установите [`donutmatch.inc`](scripting/include/donutmatch.inc) в `addons/sourcemod/scripting/include/`, затем подключите его в плагине:

```sourcepawn
#include <donutmatch>
```

Include предоставляет перечисления `GameMode`, `MatchState`, natives и forwards.

### События (forwards)

```sourcepawn
forward void DonutMatch_OnPlayerReady(int client, bool ready);
forward void DonutMatch_OnRoundScore(int scoreT, int scoreCT, int winnerTeam);
forward void DonutMatch_OnMatchStart(const any[] data, int dataSize);
forward void DonutMatch_OnMatchEnd(const any[] data, int dataSize);
forward void DonutMatch_OnMatchReset(const char[] reason);
forward void DonutMatch_OnHalfTime(int scoreT, int scoreCT);
```

`OnMatchStart` передаёт массив `[mode, playerCount, players[MAXPLAYERS], teams[MAXPLAYERS]]`; `OnMatchEnd` — `[mode, scoreT, scoreCT]`. Для разбора используйте `DonutMatch_ParseMatchStartData` и `DonutMatch_ParseMatchEndData`. В `OnRoundScore` команда-победитель обозначается `2` (T) или `3` (CT). `OnMatchReset` не является событием завершения матча.

### Функции (natives)

```sourcepawn
bool DonutMatch_IsMatchLive();
MatchState DonutMatch_GetMatchState();
GameMode DonutMatch_GetGameMode();
bool DonutMatch_GetPlayerReady(int client);
bool DonutMatch_SetPlayerReady(int client, bool ready);
void DonutMatch_GetScore(int &scoreT, int &scoreCT);
bool DonutMatch_ForceStart();
bool DonutMatch_ForceStop(const char[] reason);
int DonutMatch_GetPlayersPerSide();
ArrayList DonutMatch_GetLivePlayers();
bool DonutMatch_IsPlayerInMatch(int client);
```

`DonutMatch_ForceStart` работает только в состоянии ожидания при полном составе. `DonutMatch_GetLivePlayers` возвращает копию `ArrayList` — освободите её после использования. Также доступны вспомогательные функции `DonutMatch_GetTeamName`, `DonutMatch_GetModeName` и `DonutMatch_GetStateName`.

### Пример: получить состав при старте

```sourcepawn
#include <donutmatch>

public void DonutMatch_OnMatchStart(const any[] data, int dataSize)
{
    GameMode mode;
    int playerCount;
    int players[MAXPLAYERS];
    int teams[MAXPLAYERS];

    if (DonutMatch_ParseMatchStartData(data, mode, playerCount, players, teams))
    {
        // Здесь доступны режим и состав матча.
    }
}
```

---

<p align="center">Если DonutMatch оказался полезен — поставьте ⭐ репозиторию!</p>
