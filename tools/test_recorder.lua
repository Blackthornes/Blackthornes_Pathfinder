-- The recorder keeps what happens while leveling, only while it is on, and
-- never breaks on a client that is missing something or raises.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("recorder")

local clock = 1000
local spot = { 1411, 0.421, 0.683 }
local objectives = {}
local quest, target, targetDead = 0, nil, false

local function Client()
    _G.time = function() return clock end
    _G.UnitGUID = function(unit)
        if unit == "player" then return "Player-1-0ABCDEF0" end
        if unit == "npc" then return "Creature-0-1-2-3-3143-0000ABCD" end
        if unit == "target" then return target end
    end
    _G.UnitRace = function() return "Orc", "Orc" end
    _G.UnitClass = function() return "Warrior", "WARRIOR" end
    _G.UnitFactionGroup = function() return "Horde" end
    _G.UnitLevel = function() return 2 end
    _G.UnitXP = function() return 150 end
    _G.UnitXPMax = function() return 900 end
    _G.UnitName = function() return "Gornek" end
    _G.UnitIsDead = function() return targetDead end
    _G.UnitAffectingCombat = function() return false end
    _G.GetQuestID = function() return quest end
    _G.GetTitleText = function() return "Cutting Teeth" end
    _G.GetBindLocation = function() return "Valley of Trials" end
    _G.C_Map = {
        GetBestMapForUnit = function() return spot[1] end,
        GetPlayerMapPosition = function()
            return { GetXY = function() return spot[2], spot[3] end }
        end,
    }
    _G.C_QuestLog = {
        GetNumQuestLogEntries = function() return 2 end,
        GetInfo = function(i)
            if i == 1 then return { isHeader = true, title = "Durotar" } end
            return { questID = 788 }
        end,
        GetQuestObjectives = function() return objectives end,
    }
end

local function Fire(ns, event, ...)
    ns.eventFrame:GetScript("OnEvent")(ns.eventFrame, event, ...)
end

local function Events(ns)
    local run = ns.db.recorded and ns.db.recorded["Player-1-0ABCDEF0"]
    run = run and run.runs[#run.runs]
    return run and run.events or {}
end

local function Kinds(ns)
    local out = {}
    for _, e in ipairs(Events(ns)) do out[#out + 1] = e[2] end
    return table.concat(out, ",")
end

-- Off by default: nothing is kept.
local ns = env.Load()
Client()
ns.Recorder:OnEnable()
Fire(ns, "QUEST_ACCEPTED", 788)
suite.check("off by default", ns.db.recorder ~= true)
suite.check("keeps nothing while off", ns.db.recorded == nil)
suite.check("is not in the help list", not table.concat(ns.commandOrder, ","):find("record", 1, true))
ns.HandleSlash("record")
suite.check("says it is off", env.ChatText():find("Recorder is off", 1, true), env.ChatText())

-- On: a quest from offer to hand-in.
ns.HandleSlash("record on")
suite.check("turns on", ns.db.recorder == true)
suite.check("starts with a zone mark and a spot", Kinds(ns) == "z,p", Kinds(ns))
local run = ns.db.recorded["Player-1-0ABCDEF0"].runs[1]
suite.check("the run says who", run.race == "Orc" and run.class == "WARRIOR" and run.side == "Horde"
    and run.level == 2)

clock = clock + 5
quest = 788
Fire(ns, "QUEST_DETAIL")
local offer = Events(ns)[#Events(ns)]
suite.check("an offer keeps the quest, the NPC, the spot and the title",
    offer[2] == "o" and offer[3] == 788 and offer[4] == 3143 and offer[5] == "Cutting Teeth"
    and offer[6] == 1411 and offer[7] == 42.1 and offer[8] == 68.3,
    table.concat({ tostring(offer[3]), tostring(offer[4]), tostring(offer[5]), tostring(offer[7]) }, " "))

objectives = { { numFulfilled = 0, numRequired = 10 } }
Fire(ns, "QUEST_ACCEPTED", 788)
suite.check("an accept is kept", Events(ns)[#Events(ns)][2] == "a" and Events(ns)[#Events(ns)][3] == 788)

spot = { 1411, 0.451, 0.659 }
objectives = { { numFulfilled = 3, numRequired = 10 } }
Fire(ns, "QUEST_LOG_UPDATE")
local moved = Events(ns)[#Events(ns)]
suite.check("an objective moving on is kept with where it happened",
    moved[2] == "j" and moved[3] == 788 and moved[4] == 1 and moved[5] == 3 and moved[6] == 10
    and moved[8] == 45.1, Kinds(ns))
local count = #Events(ns)
Fire(ns, "QUEST_LOG_UPDATE")
suite.check("an objective that did not move is not kept again", #Events(ns) == count)

target, targetDead = "Creature-0-1-2-3-3098-0000BEEF", true
Fire(ns, "CHAT_MSG_COMBAT_XP_GAIN", "Mottled Boar dies, you gain 55 experience.")
local kill = Events(ns)[#Events(ns)]
suite.check("a kill keeps the dead target's NPC ID", kill[2] == "k" and kill[3] == 3098, Kinds(ns))
targetDead = false
count = #Events(ns)
Fire(ns, "CHAT_MSG_COMBAT_XP_GAIN", "You gain 150 experience.")
suite.check("XP with no dead target is no kill", #Events(ns) == count)

Fire(ns, "PLAYER_XP_UPDATE", "player")
local xp = Events(ns)[#Events(ns)]
suite.check("XP is kept as the game reports it", xp[2] == "x" and xp[3] == 2 and xp[4] == 150 and xp[5] == 900)

Fire(ns, "QUEST_COMPLETE")
local page = Events(ns)[#Events(ns)]
suite.check("a reward page keeps the quest and who takes it back",
    page[2] == "q" and page[3] == 788 and page[4] == "reward" and page[5] == 3143)
Fire(ns, "QUEST_TURNED_IN", 788, 150, 35)
local turnin = Events(ns)[#Events(ns)]
suite.check("a hand-in keeps the XP and money the game gave",
    turnin[2] == "t" and turnin[3] == 788 and turnin[4] == 150 and turnin[5] == 35)

-- Positions: kept once moved, not while standing still.
count = #Events(ns)
ns.Recorder:Sample()
suite.check("a new spot is kept", #Events(ns) == count + 1 and Events(ns)[#Events(ns)][2] == "p")
ns.Recorder:Sample()
suite.check("standing still keeps nothing", #Events(ns) == count + 1)

-- An innkeeper: the hearthstone set somewhere new.
_G.GetBindLocation = function() return "Razor Hill" end
Fire(ns, "GOSSIP_CLOSED")
suite.check("a new home is kept", Events(ns)[#Events(ns)][2] == "h" and Events(ns)[#Events(ns)][3] == "Razor Hill")

-- The flight map: its paths, and the flight taken by slot.
_G.GetTaxiMapID = function() return 1414 end
_G.C_TaxiMap = { GetAllTaxiNodes = function()
    return { { nodeID = 23, state = 0, slotIndex = 1 }, { nodeID = 25, state = 1, slotIndex = 2 } }
end }
Fire(ns, "TAXIMAP_OPENED")
local paths = Events(ns)[#Events(ns)]
suite.check("the flight map's paths are kept", paths[2] == "f" and type(paths[3]) == "table"
    and paths[3][1] == 23 and paths[3][3] == 25 and paths[3][4] == 1)
suite.check("which slot is which node", ns.Recorder.slots[2] == 25)

-- A client that raises everywhere still records what it can.
_G.C_Map = { GetBestMapForUnit = function() error("secret") end }
_G.UnitGUID = function(unit) if unit == "player" then return "Player-1-0ABCDEF0" end error("secret") end
quest = 790
Fire(ns, "QUEST_DETAIL")
local blind = Events(ns)[#Events(ns)]
suite.check("an offer with no spot or NPC still keeps the quest",
    blind[2] == "o" and blind[3] == 790 and blind[4] == false and blind[6] == false)

-- Off again: what was kept stays.
count = #Events(ns)
ns.HandleSlash("record off")
suite.check("turns off", ns.db.recorder == false)
Fire(ns, "QUEST_ACCEPTED", 790)
suite.check("keeps nothing more once off", #Events(ns) == count + 1)
suite.check("and says what it kept stays", env.ChatText():find("What it kept stays saved", 1, true))

-- A new run starts its own list and keeps the old one.
Client()
ns.HandleSlash("record new")
suite.check("a new run is its own", #ns.db.recorded["Player-1-0ABCDEF0"].runs == 2)

suite.done()
