<p align="center">
  <img width="400" height="400" alt="DonutMatch" src="https://github.com/user-attachments/assets/e23ba4f5-5091-40af-ba7c-89d365da4420" />
</p>

# DonutMatch - Система Mix и War матчей для CS:S

![Version](https://img.shields.io/badge/6.1-global-test--load-blue)
![SourceMod](https://img.shields.io/badge/sourcemod-1.10+-green)
![CS:S](https://img.shields.io/badge/CS:Source-v34-orange)

Профессиональная система для организации Mix и War матчей на серверах Counter-Strike: Source. Полная автоматизация всех этапов игры - от сбора готовности до финального счета.

## 🚀 Возможности

### 🎮 Режимы игры
- **Mix режим** - Классический микс с выбором капитанов и пикингом игроков
- **War режим** - Команда на команду с ножевым раундом за выбор стороны

### ⚙️ Автоматизация
- ✅ Автоматический сбор готовности (`!ready`)
- ✅ Ножевые раунды капитанов (Mix)
- ✅ Пикинг игроков через меню
- ✅ Ведение счета и определение победителя
- ✅ Овертаймы при ничьей 15:15 (War)
- ✅ Система замен игроков (`!ask`)
- ✅ Автоподбор замен при дисконнектах

### 🎯 Команды
| Команда | Описание | Доступность |
|---------|----------|-------------|
| `!ready` / `!r` | Готовность к матчу | Все игроки |
| `!info` | Статус готовности | Все игроки |
| `!knife` | Запуск ножевого раунда | War режим |
| `!stay` | Начать без ножевого | War режим |
| `!ask` | Предложить замену | Mix режим |
| `!forcemix` | Принудительный старт Mix | Админы |
| `!forcewar` | Принудительный старт War | Админы |

## 📦 Установка

1. **Скачайте последнюю версию** со [страницы релизов](https://github.com/Akllike/DonutMatch/releases)
2. **Установите файлы** в соответствующие папки:
   - `donut_match.smx` → `addons/sourcemod/plugins/`
   - `donutmatch.inc` → `addons/sourcemod/scripting/include/`
3. **Установите папку конфигов** → `cfg/donutmatch/`
4. **Настройте конфигурационные файлы** (см. ниже)
5. **Перезапустите сервер** или выполните `sm plugins load donut_match.smx`

## ⚙️ Конфигурация

### Основные настройки
```sourcemod
// cfg/sourcemod/donutmatch.cfg
sm_donut_mode "1"                // 1 - Mix, 2 - War
sm_donut_players_per_side "5"    // 5v5, 4v4, etc
sm_donut_restart_delay "3.5"     // Задержка перед стартом
sm_donut_auto_ready "0"          // Авто-готовность новых игроков
sm_donut_sub_time "10"           // Время на ответ для замены
```

### Файлы конфигурации матча
Переместите папку `cfg/donutmatch/`:

- `donut_warmup.cfg` - Настройки для режима готовности
- `donut_mix_start.cfg` - Настройки для начала Mix матча  
- `donut_war_start.cfg` - Настройки для начала War матча
- `donut_mix_end.cfg` - Настройки после Mix матча
- `donut_war_end.cfg` - Настройки после War матча
- `donut_war_overtime_start.cfg` - Настройки для овертайма

## 🛠️ API для разработчиков

Плагин предоставляет полное API для интеграции:

### Forwards (События)
```sourcepawn
DonutMatch_OnPlayerReady(int client, bool ready)
DonutMatch_OnRoundScore(int scoreT, int scoreCT, int winnerTeam) 
DonutMatch_OnMatchStart(const any[] data, int dataSize)
DonutMatch_OnMatchEnd(const any[] data, int dataSize)
```

### Natives (Функции)
```sourcepawn
bool DonutMatch_IsMatchLive()
MatchState DonutMatch_GetMatchState()
bool DonutMatch_GetPlayerReady(int client)
bool DonutMatch_SetPlayerReady(int client, bool ready)
void DonutMatch_GetScore(int &scoreT, int &scoreCT)
bool DonutMatch_ForceStart()
bool DonutMatch_ForceStop(const char[] reason)
```

### Пример использования
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
        // Ваша логика здесь
    }
}
```

## 🎨 Состояния матча

Плагин управляет 8 состояниями:
1. **ReadySystem** - Ожидание готовности
2. **Warmup** - Разминка (только War)
3. **CaptainKnife** - Ножевой капитанов (только Mix)
4. **PickingPlayers** - Выбор игроков (только Mix)
5. **KnifeRound_WAR** - Ножевой за сторону (только War)
6. **Starting** - Запуск матча
7. **Live** - Матч идет
8. **Overtime** - Овертайм

## 🔧 Требования

- **SourceMod 1.10+**
- **Counter-Strike: Source** (проверено на v34)
- **MapChooser** (для смены карт в конце матчей)

## 📁 Структура проекта

```
addons/sourcemod/
├── scripting/
│   ├── include/
│       └── donutmatch.inc    # API для разработчиков
├── plugins/
│   └── donut_match.smx    # Скомпилированный плагин
cfg/
└── server.cfg
├── donutmatch/       # Пользовательские конфиги
    ├── donut_warmup.cfg
    ├── donut_mix_start.cfg
    └── ... etc
```

## 🐛 Поддержка и баги

Нашли ошибку или есть предложение? 
1. Проверьте [существующие issues](https://github.com/Akllike/DonutMatch/issues)
2. Создайте новое issue с подробным описанием
3. Укажите версию плагина и условия воспроизведения

## 👥 Авторы

- **phenom**(Akllike) - Разработчик и идеолог
- **root** - Тестирование и предложения

## 💬 Поддержка

- **VK группа**: [DonutMatch](https://vk.com/jquerry)
- **Telegram**: [DonutMatchTg](https://t.me/donutmatch)

---

⭐ Если вам нравится этот плагин, поставьте звезду на GitHub!

Плагин может быть нестабилен и работать неправильно, потому что он в стадии разработки. Если есть вопросы и предложения, можете задавать их в Issues.
