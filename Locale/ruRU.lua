-- Blackthornes Pathfinder -- Locale/ruRU.lua
-- Russian: the words players see, on a Russian client.
--
-- Each line is the English key (exactly as the code writes it) and its
-- Russian. A key with no line here shows in English. The Russian speaks to
-- the player as "ты" and uses the game's own words (задание,
-- распорядитель полетов, камень возвращения, наставник, торговец, уровень, м). A line may name its values
-- by place ("%2$s ... %1$s") where Russian word order needs it; L.Format
-- puts them in order.
--
-- Quest, NPC, zone and item names stay as the data or the client gives
-- them. tools/check_locale.py lists keys with no line here and lines no
-- longer used.

local _, ns = ...
local L = ns.L

local ok, locale = pcall(function() return GetLocale() end)
if not (ok and locale == "ruRU") then return end

-- Core
L["Saved for Claude, /reload to write it."] = "Сохранено для Claude, набери /reload, чтобы записать."
L["module %s:%s failed"] = "модуль %s:%s дал сбой"
L["show this list"] = "показать этот список"
L["unknown command: %s"] = "неизвестная команда: %s"
L["/bpath %s failed: %s"] = "/bpath %s не сработала: %s"

-- The sister note
L["and"] = "и"
L["works with other Blackthornes addons you don't have yet: %s. %s on CurseForge."] = "работает с другими аддонами Blackthornes, которых у тебя ещё нет: %s. %s на CurseForge."
L["It's"] = "Его можно найти"
L["They're"] = "Их можно найти"
L["This note shows once."] = "Эта заметка показывается один раз."
L["turn the once-only note about the other Blackthornes addons on or off"] =
    "включить или выключить разовую заметку о других аддонах Blackthornes"
L["the note about the other Blackthornes addons is on. It shows once for any you don't have."] =
    "заметка о других аддонах Blackthornes включена. Она покажется один раз для каждого, которого у тебя нет."
L["the note about the other Blackthornes addons is off, in all of them."] =
    "заметка о других аддонах Blackthornes выключена во всех аддонах."
L["where to farm any material"] = "где добыть любой материал"
L["auction prices, crafting profits and a craft queue"] =
    "цены аукциона, доход от ремесла и очередь заказов"
L["which gear is an upgrade for you, and where to get it"] =
    "какие вещи лучше твоих и где их взять"
L["feeding and taming for hunter and warlock pets"] =
    "корм и приручение для питомцев охотника и чернокнижника"
L["what to do with every item in your bags"] = "что делать с каждой вещью в сумках"

-- Diets

-- The beast arrow

-- The compendium's data

-- Food

-- The pet's status

-- Tames and pet skills

-- TomTom

-- Map pins

-- The arrow's window

-- The compendium window
L["Settings"] = "Настройки"
L["Also in %s"] = "Ещё в: %s"

-- The Feed buttons

-- The Pet care key

-- The pets window

-- The minimap button
L["Click to open"] = "Щёлкни, чтобы открыть"
L["Right-click for settings"] = "Правый щелчок: настройки"
L["Click for settings"] = "Щёлкни, чтобы открыть настройки"
L["Drag to move it round the minimap"] = "Перетащи, чтобы двигать вокруг миникарты"

-- Settings
L["Changes save as you make them."] = "Изменения сохраняются сразу."
L["Reload"] = "Перезагрузить"
L["Check"] = "Проверить"
L["WINDOWS"] = "ОКНА"
L["ADVANCED"] = "ДОПОЛНИТЕЛЬНО"
L["GENERAL"] = "ОБЩЕЕ"
L["Or type /bpath settings, or click the minimap button."] =
    "Или набери /bpath settings, или щёлкни кнопку у миникарты."
L["open the settings window"] = "открыть окно настроек"

-- The settings pages
L["Show descriptions"] = "Показывать описания"
L["Find a setting"] = "Найти настройку"
L["Normal"] = "Обычный"
L["Large"] = "Крупный"
L["Larger"] = "Ещё крупнее"

-- The taming tooltip

-- The house frame
L["Close"] = "Закрыть"

-- UI/WhatsNew.lua (the same lines in every addon) and its Settings rows.
L["What's New"] = "Что нового"
L["BLACKTHORNES ADDONS"] = "АДДОНЫ BLACKTHORNES"
L["Here's what changed since you last played."] = "Вот что изменилось с твоей прошлой игры."
L["The newest changes in each of your Blackthornes addons."] = "Свежие изменения в каждом твоём аддоне Blackthornes."
L["Show after updates"] = "Показывать после обновлений"
L["Motion"] = "Анимация"
L["Got it"] = "Понятно"
L["there is no news to show yet."] = "пока нет новостей."
L["open the What's New window for every Blackthornes addon"] = "открыть окно «Что нового» для всех аддонов Blackthornes"

-- ======================================================================
-- Settings rows
L["On"] = "Вкл."
L["Open"] = "Открыть"
L["Window Position:"] = "Положение окон:"
L["Reset the UI windows to their defaults."] = "Вернуть окна на их обычные места."
L["Set Default"] = "По умолчанию"
L["UI windows set to defaults."] = "Окна возвращены на обычные места."
L["Text Size:"] = "Размер текста:"
L["Window Style:"] = "Стиль окон:"
L["Debug:"] = "Отладка:"
L["Extra chat messages to help track down a problem."] = "Лишние сообщения в чате, чтобы найти проблему."
L["Sister Addons:"] = "Другие аддоны:"
L["Says once in chat which Blackthornes addons you don't have."] = "Один раз пишет в чат, каких аддонов Blackthornes у тебя нет."
L["What's New:"] = "Что нового:"
L["What's New After Updates:"] = "Что нового после обновлений:"
L["Opens What's New the first time you play after an update."] = "Открывает «Что нового», когда ты впервые играешь после обновления."
L["What's New Motion:"] = "Анимация «Что нового»:"
L["Client Check:"] = "Проверка игры:"
L["Window position, text size and debug output"] = "Положение окон, размер текста и отладка"

-- About (UI/About.lua) and the note in What's New
-- ======================================================================
L["A few of you have asked if AI is used in the creation of my AddOns. It is."] = "Некоторые из вас спрашивали, использую ли я ИИ, когда делаю свои аддоны. Да, использую."
L["I've spent 25 years developing software and working in IT, and I recommend developers today use it, but with care and intention. For me that means I decide what gets built, I set the rules the code has to follow, I review the code, and I test changes in game myself. AI helps me write the code, run the tests and track down bugs."] = "Я 25 лет занимаюсь разработкой программ и работаю в IT, и я советую разработчикам сегодня пользоваться ИИ, но с умом и осознанно. Для меня это значит, что я решаю, что делать, я задаю правила, которым должен следовать код, я проверяю код и сам тестирую изменения в игре. ИИ помогает мне писать код, запускать тесты и искать ошибки."
L["Used well, it means more features, faster bug fixes and quicker turnaround on your requests. A lot of what's in these addons started as an idea or a bug report from a player."] = "Если пользоваться им с умом, это значит больше функций, более быстрые исправления и быстрее выполненные ваши просьбы. Многое в этих аддонах началось с идеи или сообщения об ошибке от игрока."
L["If you have an idea or something isn't working, come find me on my Discord at discord.gg/f2geDecrw2. I read every comment and report."] = "Если у тебя есть идея или что-то не работает, найди меня в моём Discord: discord.gg/f2geDecrw2. Я читаю каждый комментарий и каждое сообщение."
L["%s, version %s"] = "%s, версия %s"
L["DISCORD"] = "DISCORD"
L["Click the box, then press Ctrl+C to copy the link."] = "Щёлкни по полю, затем нажми Ctrl+C, чтобы скопировать ссылку."
L["REPORT A BUG"] = "СООБЩИТЬ ОБ ОШИБКЕ"
L["Post it on my Discord with what you were doing when it happened. I read every comment and report."] = "Напиши об этом в моём Discord и расскажи, что ты делал, когда это случилось. Я читаю каждый комментарий и каждое сообщение."
L["THANK YOU"] = "СПАСИБО"
L["A lot of what's here started as a player's idea or bug report. Thank you to everyone who sent one in."] = "Многое здесь началось с идеи игрока или сообщения об ошибке. Спасибо всем, кто их прислал."
L["installed"] = "установлен"
L["turned off"] = "выключен"
L["not installed"] = "не установлен"
L["%s (%s)"] = "%s (%s)"
L["How these addons are made"] = "Как делаются эти аддоны"
L["A note from Blackthornes."] = "Пара слов от Blackthornes."
L["ABOUT"] = "ОБ АДДОНЕ"
L["HOW THESE ADDONS ARE MADE"] = "КАК ДЕЛАЮТСЯ ЭТИ АДДОНЫ"
L["How these addons are made, the version, the Discord and the other Blackthornes addons"] = "Как делаются эти аддоны, версия, Discord и другие аддоны Blackthornes"

-- Off, Shift or Always for a tooltip line (UI/TooltipShift.lua).

-- Pathfinder's own words.
L["Guide:"] = "Руководство:"
L["Level %d"] = "Уровень %d"
L["Lists in chat what the game tells Pathfinder about quests and travel."] = "Показывает в чате, что игра сообщает Pathfinder о заданиях и путешествиях."
L["Open Pathfinder settings"] = "Открыть настройки Pathfinder"
L["Pathfinder's settings have a window of their own."] = "У настроек Pathfinder есть своё окно."
L["The guide isn't ready yet."] = "Руководство ещё не готово."
L["open the guide window (so does /bpath on its own)"] = "открыть окно руководства (так же работает просто /bpath)"
L["a step-by-step leveling guide"] = "пошаговое руководство по прокачке"
