-- The /bpath routing and the saved data it starts from.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("slash")

local ns = env.Load()

suite.check("the global is the namespace", _G.BlackthornesPathfinder == ns)
suite.check("/bpath is registered", SLASH_BLACKTHORNESPATHFINDER1 == "/bpath")
suite.check("so is /pathfinder", SLASH_BLACKTHORNESPATHFINDER2 == "/pathfinder")
suite.check("and routes to the handler",
    SlashCmdList["BLACKTHORNESPATHFINDER"] == ns.HandleSlash)

suite.check("account settings exist", type(ns.db) == "table")
suite.check("character settings exist", type(ns.charDB) == "table")

ns.HandleSlash("")
suite.check("a bare /bpath opens the guide window", ns.UI.frame and ns.UI.frame:IsShown())
ns.HandleSlash("")
suite.check("and a second one closes it", not ns.UI.frame:IsShown())

env.chat = {}
ns.HandleSlash("  HELP  ")
suite.check("commands ignore case and spaces",
    env.ChatText():find("Blackthornes Pathfinder", 1, true), env.ChatText())

env.chat = {}
ns.HandleSlash("nonsense")
suite.check("an unknown command says so",
    env.ChatText():find("unknown command: nonsense", 1, true), env.ChatText())

env.chat = {}
ns.RegisterCommand("boom", "fails on purpose", function() error("kaboom") end)
local ok = pcall(ns.HandleSlash, "boom")
suite.check("a failing command reaches the error handler", not ok)
suite.check("and says so in chat first",
    env.ChatText():find("/bpath boom failed", 1, true), env.ChatText())

-- Saved data already on disk is kept; only missing keys are filled in.
_G.BlackthornesPathfinderCharDB = { kept = "yes" }
_G.BlackthornesPathfinderDB = { x = 120 }
ns.LoadSavedVariables()
suite.check("character data survives a reload", ns.charDB.kept == "yes")
suite.check("a moved window stays moved", ns.db.x == 120)
suite.check("missing settings get their default", ns.db.debug == false)

suite.done()
