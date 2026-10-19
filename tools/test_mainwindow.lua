-- The guide window: it opens and closes, shows the character's level,
-- remembers where it was put, and says the guide is still to come.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("mainwindow")

local ns = env.Load()
local UI = ns.UI

_G.UnitLevel = function() return 12 end
UI:Show()
suite.check("it opens", UI.frame:IsShown())
suite.check("the header shows the level", UI.subtitle:GetText() == "Level 12", UI.subtitle:GetText())
suite.check("and says the guide is still to come",
    UI.emptyLabel:GetText() == "The guide isn't ready yet.")

_G.UnitLevel = function() error("secret value") end
UI:Refresh()
suite.check("an unreadable level is not an error", UI.subtitle:GetText() == "")
_G.UnitLevel = nil

-- The house frame: the name on the plate, the compass in the portrait, and
-- a close gem in place of the old X.
local trim = UI.frame.titan
suite.check("the window wears the house frame", trim ~= nil)
suite.check("its name is on the plate", trim and trim.plate.label:GetText() == "Blackthornes Pathfinder")
suite.check("with the portrait", trim and type(trim.portrait) == "table")
trim.closeButton:GetScript("OnClick")(trim.closeButton)
suite.check("the close gem closes it", not UI.frame:IsShown())

-- /bpath window.
UI:Hide()
ns.HandleSlash("window")
suite.check("/bpath window opens it", UI.frame:IsShown())

-- Its place is remembered.
UI.frame._point = { "TOPLEFT", nil, "TOPLEFT", 120, -80 }
UI:SavePosition()
suite.check("where it was dragged is saved", ns.db.point == "TOPLEFT" and ns.db.x == 120)

suite.done()
