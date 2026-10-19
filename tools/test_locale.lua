-- The translations: on a German, Simplified Chinese, French, Spanish or
-- Russian client the windows and settings speak that language, on any other
-- English, and a word with no line falls back to its English key. L.Format
-- puts values named by place ("%2$s ... %1$d") in order, which the tests'
-- Lua 5.1 cannot do itself.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("locale")

--- Every row label on every settings page, as one lookup.
local function SettingsLabels(ns)
    for _, module in ipairs(ns.moduleOrder) do
        if module.OnEnable then module:OnEnable() end
    end
    ns.SettingsUI:Show()
    local labels = {}
    for _, page in pairs(ns.SettingsUI.pages.pages) do
        for _, row in ipairs(page.rows or {}) do
            if row.labelText then labels[row.labelText] = true end
        end
    end
    return labels
end

-- English first.
local ns = env.Load()
local L = ns.L
suite.check("English shows English", L["Settings"] == "Settings")
suite.check("and formats as before", L.Format("Level %d", 12) == "Level 12")
_G.UnitLevel = function() return 12 end
ns.UI:Show()
suite.check("the guide window in English", ns.UI.subtitle:GetText() == "Level 12", ns.UI.subtitle:GetText())
suite.check("its empty line in English", ns.UI.emptyLabel:GetText() == "The guide isn't ready yet.")
suite.check("the settings rows in English", SettingsLabels(ns)["Window Position:"] == true)

-- Each translated client: the window, a settings row, and English for a
-- word with no line.
local CLIENTS = {
    { locale = "deDE", name = "Deutsch", level = "Stufe 12",
      empty = "Der Leitfaden ist noch nicht fertig.", row = "Fensterposition:" },
    { locale = "zhCN", name = "Simplified Chinese", level = "等级 12",
      empty = "指南还没有准备好。", row = "窗口位置：" },
    { locale = "frFR", name = "French", level = "Niveau 12",
      empty = "Le guide n'est pas encore prêt.", row = "Position des fenêtres :" },
    { locale = "esES", name = "Spanish (Spain)", level = "Nivel 12",
      empty = "La guía aún no está lista.", row = "Posición de ventanas:" },
    { locale = "esMX", name = "Spanish (Latin America)", level = "Nivel 12",
      empty = "La guía aún no está lista.", row = "Posición de ventanas:" },
    { locale = "ruRU", name = "Russian", level = "Уровень 12",
      empty = "Руководство ещё не готово.", row = "Положение окон:" },
}

for _, client in ipairs(CLIENTS) do
    ns = env.Load(client.locale)
    L = ns.L
    _G.UnitLevel = function() return 12 end
    ns.UI:Show()
    suite.check("the guide window speaks " .. client.name,
        ns.UI.subtitle:GetText() == client.level, ns.UI.subtitle:GetText())
    suite.check("its empty line in " .. client.name,
        ns.UI.emptyLabel:GetText() == client.empty, ns.UI.emptyLabel:GetText())
    local labels = SettingsLabels(ns)
    suite.check("the settings rows in " .. client.name, labels[client.row] == true)
    suite.check("and none is left in English (" .. client.name .. ")", labels["Window Position:"] == nil)
    suite.check("a word with no " .. client.name .. " line falls back to English",
        L["A string nobody translated"] == "A string nobody translated")
end

-- Values named by place go where a translation puts them.
ns = env.Load("deDE")
L = ns.L
L["%d quests in %s"] = "In %2$s: %1$d Quests"
suite.check("values named by place go where German puts them",
    L.Format("%d quests in %s", 4, "Durotar") == "In Durotar: 4 Quests",
    L.Format("%d quests in %s", 4, "Durotar"))
suite.check("and formats in English with no line", L.Format("%d wolves, %s", 3, "grey") == "3 wolves, grey")

-- Another language that has no file shows English.
ns = env.Load("itIT")
suite.check("a client in a language with no file shows English", ns.L["Settings"] == "Settings")

_G.UnitLevel, _G.GetLocale = nil, nil
suite.done()
