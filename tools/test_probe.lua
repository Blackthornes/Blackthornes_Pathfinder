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

-- At a vendor, read the retail way: classic's GetMerchantItemInfo is gone on
-- Forever, and the client says which kind of NPC is open.
ns = env.Load()
_G.GetMerchantNumItems = function() return 11 end
_G.C_MerchantFrame = { GetItemInfo = function() return { name = "Refreshing Spring Water", price = 25 } end }
_G.GetMerchantItemLink = function() return "|Hitem:159::|h[Refreshing Spring Water]|h" end
_G.Enum = { PlayerInteractionType = { Gossip = 3, QuestGiver = 4, Merchant = 5, Trainer = 7, TaxiNode = 6 } }
_G.C_PlayerInteractionManager = { IsInteractingWithNpcOfType = function(kind) return kind == 5 end }
ns.HandleSlash("probe")
text = env.ChatText()
suite.check("reads the vendor's first item",
    text:find("vendor|r  11; first table of 2: name=Refreshing Spring Water, price=25;", 1, true), text)
suite.check("and its link", text:find("link |Hitem:159::|h[Refreshing Spring Water]|h; id absent", 1, true), text)
suite.check("says which kind of NPC is open, and which kinds the client lacks",
    text:find("talking to|r  Merchant; no kind Binder", 1, true), text)
_G.C_PlayerInteractionManager.IsInteractingWithNpcOfType = function() error("secret value") end
ns.HandleSlash("probe")
text = env.ChatText()
suite.check("a kind that raises reads as not open", text:find("talking to|r  nobody; no kind Binder", 1, true), text)
_G.GetMerchantNumItems, _G.C_MerchantFrame, _G.GetMerchantItemLink = nil, nil, nil
_G.Enum, _G.C_PlayerInteractionManager = nil, nil

-- At an innkeeper, every gossip option in the window's order, by ID.
ns = env.Load()
_G.C_GossipInfo = { GetOptions = function()
    return {
        { orderIndex = 4, gossipOptionID = 95572, name = "Tell me about dungeons I could explore.", icon = 132053 },
        { orderIndex = 1, gossipOptionID = 30001, name = "Make this inn your home.", icon = 132052 },
    }
end }
ns.HandleSlash("probe")
text = env.ChatText()
suite.check("lists every gossip option in the window's order",
    text:find("gossip options|r  2: [1] 30001 Make this inn your home. (icon 132052); "
        .. "[4] 95572 Tell me about dungeons I could explore. (icon 132053)", 1, true), text)
_G.C_GossipInfo.GetOptions = function() error("secret value") end
ns.HandleSlash("probe")
text = env.ChatText()
suite.check("a gossip list that raises says so", text:find("gossip options|r  raised", 1, true), text)
_G.C_GossipInfo = nil

-- At a flight map: each path the character can fly to, with its cost.
ns = env.Load()
local nodes = {
    { "Thunder Bluff, Mulgore", "REACHABLE", 120 },
    { "Orgrimmar, Durotar", "CURRENT", 0 },
    { "Ratchet, The Barrens", "DISTANT", 50 },
}
_G.NumTaxiNodes = function() return #nodes end
_G.TaxiNodeName = function(i) return nodes[i][1] end
_G.TaxiNodeGetType = function(i) return nodes[i][2] end
_G.TaxiNodeCost = function(i) return nodes[i][3] end
_G.GetTaxiMapID = function() return 1414 end
_G.C_TaxiMap = { GetAllTaxiNodes = function() return { { nodeID = 23, name = "Orgrimmar, Durotar" } } end }
ns.HandleSlash("probe")
text = env.ChatText()
suite.check("counts the paths by type and lists the ones it can fly to",
    text:find("flight paths|r  3 (CURRENT 1, DISTANT 1, REACHABLE 1): Thunder Bluff, Mulgore (REACHABLE, 120 copper); "
        .. "Orgrimmar, Durotar (CURRENT, 0 copper)", 1, true), text)
suite.check("reads the flight nodes for the map",
    text:find("flight nodes|r  map 1414; table of 1, first: name=Orgrimmar, Durotar, nodeID=23", 1, true), text)
_G.NumTaxiNodes = function() error("secret value") end
ns.HandleSlash("probe")
text = env.ChatText()
suite.check("a flight map that raises says so", text:find("flight paths|r  raised", 1, true), text)
_G.NumTaxiNodes, _G.TaxiNodeName, _G.TaxiNodeGetType, _G.TaxiNodeCost = nil, nil, nil, nil
_G.GetTaxiMapID, _G.C_TaxiMap = nil, nil

-- At a turn-in, which page of the quest window shows.
ns = env.Load()
local function Panel(shown) return { IsShown = function() return shown end } end
_G.QuestFrameDetailPanel, _G.QuestFrameProgressPanel = Panel(false), Panel(false)
_G.QuestFrameRewardPanel = Panel(true)
_G.GetNumQuestChoices = function() return 2 end
ns.HandleSlash("probe")
text = env.ChatText()
suite.check("says which quest page shows, and which frames the client lacks",
    text:find("quest page|r  reward; no frame QuestFrameGreetingPanel; reward choices 2, rewards absent", 1, true), text)
_G.QuestFrameRewardPanel = { IsShown = function() error("secret value") end }
ns.HandleSlash("probe")
text = env.ChatText()
suite.check("a page that raises reads as not shown", text:find("quest page|r  none; no frame", 1, true), text)
_G.QuestFrameDetailPanel, _G.QuestFrameProgressPanel, _G.QuestFrameRewardPanel = nil, nil, nil
_G.GetNumQuestChoices = nil

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
