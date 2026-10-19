-- The settings window.
--
-- What matters is that every way in opens it, that each control changes the
-- same saved value its chat command does, and that the page shows what is
-- saved rather than what it last drew.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("settings")

local ns = env.Load()

local SettingsUI = ns.SettingsUI

-- A client with retail's Settings API, recording what is registered.
local registered = {}
_G.Settings = {
    RegisterCanvasLayoutCategory = function(panel, name) return { panel = panel, name = name } end,
    RegisterAddOnCategory = function(category) registered[#registered + 1] = category end,
}

for _, module in ipairs(ns.moduleOrder) do
    if module.OnEnable then module:OnEnable() end
end

suite.check("it is listed under the game's AddOns options",
    registered[1] and registered[1].name == "Blackthornes Pathfinder")

-- Ways in.
ns.HandleSlash("settings")
suite.check("/bpath settings opens it", SettingsUI.frame:IsShown())
ns.HandleSlash("settings")
suite.check("and closes it", not SettingsUI.frame:IsShown())
ns.HandleSlash("options")
suite.check("/bpath options works too", SettingsUI.frame:IsShown())
suite.check("options is not listed twice in help",
    not (function()
        for _, name in ipairs(ns.commandOrder) do
            if name == "options" or name == "config" then return true end
        end
    end)())

-- The house frame: the plate and close gem, without the portrait.
local trim = SettingsUI.frame.titan
suite.check("settings wears the house frame", trim ~= nil)
suite.check("with the name on the plate", trim and trim.plate.label:GetText() == "Blackthornes Pathfinder")
-- A stub answers any field it lacks with a function, so "no portrait"
-- means no portrait frame.
suite.check("and no portrait", trim and type(trim.portrait) ~= "table")
trim.closeButton:GetScript("OnClick")(trim.closeButton)
suite.check("the close gem closes it", not SettingsUI.frame:IsShown())
SettingsUI:Show()

local controls = SettingsUI.controls

suite.check("there is no minimap row", controls.minimap == nil)

-- Debug.
controls.debug:GetScript("OnClick")(controls.debug)
suite.check("the debug box sets debug", ns.db.debug == true)

-- The sister note (Core/SisterNote.lua).
suite.check("the sister addons box starts ticked", controls.sisters:GetChecked())
controls.sisters:GetScript("OnClick")(controls.sisters)
suite.check("unticking it turns the note off", ns.db.sisterNote == false)
ns.HandleSlash("sisters")
suite.check("/bpath sisters turns it back on", ns.db.sisterNote == true and controls.sisters:GetChecked())

-- The pages along the top, as Tradeskills' Settings tab has them.
local pages = SettingsUI.pages
suite.check("it opens on the first page", pages.shown == "general")
suite.check("with the general rows showing", pages.pages.general.content:IsShown()
    and not pages.pages.about.content:IsShown())
local aboutPart
for _, part in ipairs(pages.switch) do
    if part.key == "about" then aboutPart = part end
end
aboutPart.button:GetScript("OnClick")(aboutPart.button)
suite.check("a click on the switch shows that page", pages.pages.about.content:IsShown()
    and not pages.pages.general.content:IsShown())
suite.check("and the page is remembered", ns.db.settingsPage == "about")
suite.check("the page picked is gold", aboutPart.label._color[1] == ns.Theme.colors.accent[1])
SettingsUI:Hide()
SettingsUI:Show()
suite.check("it opens again on the page left", pages.shown == "about")

-- What a setting does is a tooltip until Show descriptions is ticked.
local debugRow
for _, row in ipairs(pages.pages.general.rows) do
    if row.labelText == "Debug:" then debugRow = row end
end
suite.check("descriptions start hidden", ns.db.settingsDescriptions == false
    and not debugRow.hint:IsShown())
GameTooltip._lines = {}
debugRow:GetScript("OnEnter")(debugRow)
suite.check("a row lights under the mouse", debugRow.hover:IsShown())
suite.check("and says what it does in a tooltip", GameTooltip._lines[1] and
    GameTooltip._lines[1]:find("track down a problem") ~= nil)
local before = SettingsUI.frame:GetHeight()
pages.describe:GetScript("OnClick")(pages.describe)
suite.check("Show descriptions is saved", ns.db.settingsDescriptions == true)
suite.check("and puts the words under the rows", debugRow.hint:IsShown())
-- The window fits its fullest page, which may already have room for them.
suite.check("and the row grows to fit them", debugRow:GetHeight() > debugRow.compactHeight
    and SettingsUI.frame:GetHeight() >= before)
pages.describe:GetScript("OnClick")(pages.describe)
suite.check("unticked, the window goes back", SettingsUI.frame:GetHeight() == before)

-- Find a setting.
pages.find:SetText("debug")
pages:Search("debug")
suite.check("the search shows the page that has it", pages.shown == "general")
local lit = 0
for _, entry in ipairs(pages.searchables) do
    if entry.glow:IsShown() then lit = lit + 1 end
end
suite.check("and lights only what matches", lit == 1)
pages:Search("")
lit = 0
for _, entry in ipairs(pages.searchables) do
    if entry.glow:IsShown() then lit = lit + 1 end
end
suite.check("an empty search lights nothing", lit == 0)

-- Text size, saved as a word, waits for a reload.
controls.textSize.plus:GetScript("OnClick")(controls.textSize.plus)
suite.check("Text size saves Large", ns.db.textSize == "large")
suite.check("and offers Reload", controls.textSize.reload:IsShown())
suite.check("under the stepper, at its right edge", controls.textSize.reload._point[1] == "TOPRIGHT"
    and controls.textSize.reload._point[2] == controls.textSize
    and controls.textSize.reload._point[3] == "BOTTOMRIGHT")
suite.check("the Window style's Reload sits the same way", controls.windowStyle.reload._point[1] == "TOPRIGHT"
    and controls.windowStyle.reload._point[2] == controls.windowStyle
    and controls.windowStyle.reload._point[3] == "BOTTOMRIGHT")
do
    local width = controls.windowStyle:GetWidth()
    local word = ns.Theme.TextWidth("small", "Titanforged")
    suite.check("the style's box holds Titanforged", width - 22 * 2 - 4 * 2 >= word, width)
end
controls.textSize.minus:GetScript("OnClick")(controls.textSize.minus)
suite.check("back to Normal needs no reload", ns.db.textSize == "normal"
    and not controls.textSize.reload:IsShown())

-- Every /bpath command has a button here.
local ran = {}
local realSlash = ns.HandleSlash
ns.HandleSlash = function(text) ran[#ran + 1] = text end
for _, key in ipairs({ "openWindow", "probe", "whatsnew" }) do
    controls[key]:GetScript("OnClick")(controls[key])
end
ns.HandleSlash = realSlash
suite.check("the command buttons run their commands",
    table.concat(ran, ",") == "window,probe,whatsnew")

-- Chat-only commands are typed only (the owner, 2026-10-15): the ones
-- that just list things in chat have no button here, but still work.
for _, key in ipairs({ "help" }) do
    suite.check("no button for /bpath " .. key, controls[key] == nil)
    suite.check("and /bpath " .. key .. " is still a command", ns.commands[key] ~= nil)
end

-- A row with nothing to say has no tooltip, and nothing under it.
local guideRow
for _, row in ipairs(pages.pages.general.rows) do
    if row.labelText == "Guide:" then guideRow = row end
end
GameTooltip._lines = {}
guideRow:GetScript("OnEnter")(guideRow)
suite.check("an empty row shows no tooltip", #GameTooltip._lines == 0)
pages.describe:GetScript("OnClick")(pages.describe)
suite.check("and nothing under it with descriptions on", guideRow.description == ""
    and guideRow.fullHeight == guideRow.compactHeight)
pages.describe:GetScript("OnClick")(pages.describe)

-- Window position says so in chat.
local printed = {}
local realPrint = ns.Print
ns.Print = function(...) printed[#printed + 1] = table.concat({ ... }, " ") end
controls.resetPositions:GetScript("OnClick")(controls.resetPositions)
ns.Print = realPrint
suite.check("Set Default says so in chat", printed[1] == "UI windows set to defaults.", printed[1])

-- Position.
ns.db.settingsX = 400
SettingsUI:ResetPositions()
suite.check("putting it back forgets where it was dragged", ns.db.settingsX == nil)

-- A client with neither options API still loads.
local ns2 = env.Load()
suite.check("no options API is not an error", ns2.SettingsUI:RegisterGameOptions() == false)

suite.done()
