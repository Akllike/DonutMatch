<p align="center">
  <img width="300" alt="DonutMatch" src="https://github.com/user-attachments/assets/e23ba4f5-5091-40af-ba7c-89d365da4420" />
</p>

<h1 align="center">DonutMatch</h1>
<h3 align="center">Полноценная система организации матчей — от ready-up до финального результата.</h3>

<p align="center"><code>v1.2.2-latest</code> · <code>SourceMod 1.11</code> · <code>CS:S | СS:S v34</code></p>

---

## Возможности

| Функция | Что даёт |
|---|---|
| **Mix / War** | Два формата: подбор игроков на сервере или матч готовыми составами |
| **Ready System** | Контроль готовности, таймер подтверждения и автоматический запуск |
| **Captains & Pick** | Ножевой раунд, выбор капитанов и поочерёдный набор игроков в Mix |
| **Knife Round** | Выбор стороны перед матчем в War |
| **Live Match** | Управляемый старт, счёт, смена сторон и сохранение статистики половин |
| **Overtime** | Отключённый, голосуемый или принудительный овертайм |
| **Player Substitutions** | Запрос замены и выбор игрока во время Mix |
| **Match Information** | Готовность игроков, текущий/последний счёт, урон и деньги команды |
| **SourceTV Demo** | Автоматическая запись матчей при включённой SourceTV |
| **Match Logs** | Журнал событий в JSONL и отдельный лог плагина |
| **Database** | Опциональное сохранение результатов через SourceMod Database API |
| **Server Configs** | Автоматическое применение конфигов на этапах матча |
| **Integration API** | Natives и forwards для взаимодействия с другими плагинами |

## Игровые режимы

### Mix — подбор состава

Игроки отмечают готовность, после чего система организует матч: капитаны, ножевой раунд, выбор игроков и запуск Live. Во время матча поддерживаются запросы замен и названия команд.


### War — готовые составы

Режим для заранее сформированных команд. Капитан может запустить ножевой раунд или продолжить без него. Поддерживаются счёт, смена сторон и овертайм.


## Команды игроков

Команды можно вводить в чат с префиксом `!` или в консоль с префиксом `sm_`.

| Команда | Назначение |
|---|---|
| `!ready`, `!r` | Изменить статус готовности |
| `!info` | Посмотреть готовность игроков в фазе ожидания |
| `!score`, `!scores` | Текущий счёт или результат последнего матча |
| `!lastscore` | Результат последнего матча с указанием режима |
| `!damage` | Урон и попадания за текущий Live-раунд |
| `!money` | Показать деньги команды |
| `!teamname` | Задать название команды капитану Mix |
| `!ask` | Запросить замену в Mix |
| `!knife` | Начать ножевой раунд в War |
| `!stay` | Начать War без ножевого раунда |

## Команды администраторов

| Команда | Доступ | Действие |
|---|---|---|
| `sm_donut_forceallready` | Root | Отметить всех игроков готовыми |
| `sm_donut_forceallunready` | Root | Снять готовность со всех игроков |
| `sm_forcemix` | Root | Принудительно запустить Mix |
| `sm_forcewar` | Root | Принудительно запустить War |
| `sm_forcevote` | Change Map | Запустить голосование за карту через mapchooser |

> Принудительный запуск всё равно проверяет режим, состояние матча и корректность состава.

## Параметры плагина

Настройки сохраняются в `cfg/sourcemod/donutmatch/donutmatch.cfg`.

| ConVar | По умолчанию | Описание |
|---|---:|---|
| `sm_donut_mode` | `1` | Режим: `1` — Mix, `2` — War |
| `sm_donut_players_per_side` | `5` | Игроков на сторону: `1–5` |
| `sm_donut_restart_delay` | `3.5` | Задержка старта после готовности, секунды (`1–10`) |
| `sm_donut_auto_ready` | `0` | Автоматически отмечать новых игроков готовыми |
| `sm_donut_sub_time` | `10` | Время на ответ по замене, секунды (`5–30`) |
| `sm_donut_auto_record` | `1` | Автоматическая запись SourceTV-демо |
| `sm_donut_log_matches` | `1` | Запись событий матча в JSONL |
| `sm_donut_database_enabled` | `0` | Сохранять результаты в БД `donutmatch` |
| `sm_donut_block_warmup_grenades` | `1` | Блокировать гранаты и `autobuy`/`rebuy` до Live |
| `sm_donut_round_money` | `1` | Показывать деньги команды игроку в Live |
| `sm_donut_preserve_halftime_score` | `1` | Сохранять счёт и статистику при смене сторон |
| `donut_overtime_mode` | `2` | Овертайм: `0` — выкл., `1` — голосование, `2` — принудительно |
| `donut_default_overtime_rounds` | `3` | Раундов за сторону в блоке овертайма (`1–15`) |
| `donut_ready_timer` | `20` | Время подтверждения готовности, секунды; `0` отключает кик за неготовность |
| `sm_donut_log_level` | `1` | Логирование: `0` — Debug, `1` — Info, `2` — Warn, `3` — Error |

## Установка

1. Поместите предоставленный `donut_match.smx` в `addons/sourcemod/plugins/`.
2. Установите необходимые runtime-зависимости, перечисленные ниже.
3. Поместите `donut_match.phrases.txt` в `addons/sourcemod/translations/`.
4. Разместите конфиги фаз в `cfg/donutmatch/`.
5. Перезапустите плагин или сервер и проверьте журнал SourceMod.

### Конфиги фаз

Плагин применяет эти файлы, если они существуют:

| Файл | Когда применяется |
|---|---|
| `cfg/donutmatch/donut_server_start.cfg` | При запуске плагина |
| `cfg/donutmatch/donut_warmup.cfg` | Подготовительная фаза |
| `cfg/donutmatch/donut_mix_start.cfg` | Старт Mix |
| `cfg/donutmatch/donut_war_start.cfg` | Старт War |
| `cfg/donutmatch/donut_mix_end.cfg` | Завершение Mix |
| `cfg/donutmatch/donut_war_end.cfg` | Завершение War |
| `cfg/donutmatch/donut_war_overtime_start.cfg` | Старт овертайма War |

### Runtime-зависимости

- SourceMod и стандартные модули `cstrike`, `sdktools`.
- `mapchooser` — интеграция с голосованием за карту.
- ClientMod и `clientmod/multicolors` — цветные сообщения.
- `tools/CBasePlayers` — вспомогательная библиотека, используемая плагином.
- `donut_match.phrases.txt` и поставляемые конфиги фаз.

### База данных

Сохранение результатов выключено по умолчанию. Для его включения установите `sm_donut_database_enabled 1` и настройте в `addons/sourcemod/configs/databases.cfg` подключение с именем `donutmatch`. Используйте поставляемую схему таблиц, если она входит в комплект.

## Файлы и результаты

| Файл / каталог | Назначение |
|---|---|
| `cfg/sourcemod/donutmatch/donutmatch.cfg` | Основные параметры плагина |
| `cfg/donutmatch/*.cfg` | Конфиги игровых фаз |
| `addons/sourcemod/translations/donut_match.phrases.txt` | Переводы сообщений |
| `addons/sourcemod/logs/donutmatch.log` | Журнал плагина |
| JSONL-журнал матчей | События матча построчно в JSON |
| SourceTV `.dem` | Запись матча, если функция включена и SourceTV доступна |

## API для интеграций

DonutMatch предоставляет библиотеку SourceMod `donutmatch`, natives и forwards. Для подключения сторонних плагинов используйте поставляемый API/include-файл — исходный код DonutMatch для интеграции не требуется.

**Основные natives**

`DonutMatch_IsMatchLive` · `DonutMatch_GetMatchState` · `DonutMatch_GetGameMode` · `DonutMatch_GetPlayerReady` · `DonutMatch_SetPlayerReady` · `DonutMatch_GetScore` · `DonutMatch_ForceStart` · `DonutMatch_ForceStop` · `DonutMatch_GetPlayersPerSide` · `DonutMatch_GetLivePlayers` · `DonutMatch_IsPlayerInMatch` · `DonutMatch_GetCaptain` · `DonutMatch_GetMaxRounds` · `DonutMatch_GetHalftimeScore` · `DonutMatch_GetTeamName`

**Основные forwards**

`DonutMatch_OnMatchStart` · `DonutMatch_OnMatchEnd` · `DonutMatch_OnMatchReset` · `DonutMatch_OnHalfTime` · `DonutMatch_OnPlayerReady` · `DonutMatch_OnRoundScore` · `DonutMatch_OnRestartsCompleted` · `DonutMatch_OnOvertime` · `DonutMatch_OnMatchHalfTime` · `DonutMatch_OnPlayerReplacePre` · `DonutMatch_OnPlayerReplacePost`

Для корректной интеграции сверяйте сигнатуры и параметры с поставляемым include-файлом. Перед вызовом natives проверяйте, что библиотека `donutmatch` доступна.

## Логирование и диагностика

- `sm_donut_log_matches 1` — включить журнал событий матчей в JSONL.
- `sm_donut_log_level 0–3` — изменить подробность `donutmatch.log`.
- `sm_donut_auto_record 1` — включить автоматическую запись SourceTV-демо.

Если функция не работает, сначала проверьте значения ConVars, наличие конфигов и переводов, runtime-зависимости и сообщения в логах SourceMod.

---

**DonutMatch** · War & Mix system for Counter-Strike: Source  
Автор: [phenom](https://t.me/phenom1337)
