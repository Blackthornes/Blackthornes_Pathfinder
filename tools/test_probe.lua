-- /bpath probe reads the client and reports; it must never break on a client
-- that is missing something or raises.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("probe")

local ns = env.Load()
ns.HandleSlash("probe")
suite.check("runs on a client with none of the calls",
    env.ChatText():find("has|r  none of them", 1, true), env.ChatText())
suite.check("and lists them as missing on one line",
    env.ChatText():find("missing|r  UnitClass, UnitLevel,", 1, true), env.ChatText())
suite.check("a missing call reads as absent",
    env.ChatText():find("hearth set at|r  absent", 1, true), env.ChatText())
suite.check("it is kept for Claude", ns.db.lastProbe and ns.db.lastProbe.check == "probe")

ns = env.Load()
_G.UnitClass = function() return "Warrior", "WARRIOR" end
_G.UnitLevel = function() return 12 end
_G.UnitName = function() error("secret value") end
_G.GetBindLocation = function() return "Razor Hill" end
_G.GetZoneText = function() return "Durotar" end
_G.GetSubZoneText = function() error("secret value") end
_G.C_QuestLog = {
    GetNumQuestLogEntries = function() return 7, 5 end,
    GetInfo = function() return { title = "Sarkoth", questID = 790, level = 4 } end,
    GetAllCompletedQuestIDs = function() return { 788, 789, 790 } end,
}
_G.C_GossipInfo = { GetAvailableQuests = function() return {} end }
_G.TakeTaxiNode = function() end
ns.HandleSlash("probe")
local text = env.ChatText()
suite.check("lists the calls it has", text:find("has|r  UnitClass, UnitLevel", 1, true), text)
suite.check("reads the class", text:find("class|r  Warrior, WARRIOR", 1, true), text)
suite.check("reads where the hearth is set", text:find("hearth set at|r  Razor Hill", 1, true), text)
suite.check("a call that raises says so", text:find("zone|r  Durotar; raised", 1, true), text)
suite.check("reads a dotted C_ call", text:find("quests in log|r  7, 5; absent", 1, true), text)
suite.check("summarises a quest by its fields",
    text:find("first quest|r  table of 3: level=4, questID=790, title=Sarkoth", 1, true), text)
suite.check("counts the quests done", text:find("quests done|r  C_QuestLog.GetAllCompletedQuestIDs: 3", 1, true), text)
suite.check("finds guide calls under any name",
    text:find("TakeTaxiNode", 1, true) and text:find("C_GossipInfo.GetAvailableQuests", 1, true), text)
_G.UnitClass, _G.UnitLevel, _G.UnitName, _G.GetBindLocation = nil, nil, nil, nil
_G.GetZoneText, _G.GetSubZoneText, _G.C_QuestLog, _G.C_GossipInfo, _G.TakeTaxiNode = nil, nil, nil, nil, nil

-- The map position, read the retail way.
ns = env.Load()
_G.C_Map = {
    GetBestMapForUnit = function() return 1411 end,
    GetPlayerMapPosition = function() return { GetXY = function() return 0.5123, 0.4432 end } end,
}
ns.HandleSlash("probe")
text = env.ChatText()
suite.check("reads the map position", text:find("position|r  map 1411 at 0.512, 0.443", 1, true), text)
_G.C_Map.GetPlayerMapPosition = function() return nil end
ns.HandleSlash("probe")
text = env.ChatText()
suite.check("a place with no position says so", text:find("position|r  map 1411, no position here", 1, true), text)
_G.C_Map = nil

-- A secret value: tostring hands back the value itself, ".." hands back a
-- secret too, and only table.concat raises, which is what the client did.
ns = env.Load()
local secret = newproxy(true)
getmetatable(secret).__tostring = function(self) return self end
getmetatable(secret).__concat = function() return secret end
_G.UnitXP = function() return secret end
_G.UnitXPMax = function() return 100 end
ns.HandleSlash("probe")
text = env.ChatText()
suite.check("a secret value reads as secret instead of raising",
    text:find("experience|r  (secret) / 100", 1, true), text)

-- Where the client can say a value is secret, the probe asks it.
ns = env.Load()
_G.issecretvalue = function(value) return value == 42 end
_G.UnitXP = function() return 42 end
ns.HandleSlash("probe")
text = env.ChatText()
_G.issecretvalue, _G.UnitXP, _G.UnitXPMax = nil, nil, nil
suite.check("asks issecretvalue when the client has it",
    text:find("experience|r  (secret) / 100", 1, true), text)

suite.done()
