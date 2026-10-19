-- Blackthornes Pathfinder -- Probe/Probe.lua
-- /bpath probe: ask the running client what it actually supports for a
-- leveling guide (quests, talking to NPCs, flight paths, the hearthstone,
-- trainers and vendors, map positions), rather than trusting documentation
-- written for another version of the game.
--
-- Same idea as Tradeskills' /bts probe, Equipment's /beq probe and Pets'
-- /bpet probe, copied from Pets'. It only reads: nothing is changed, saved or
-- sent anywhere, and no NPC is spoken to. Every call is inside a pcall,
-- because Forever hands out secret values in instances that raise when
-- touched.
--
-- No guide feature leans on any of these yet. The probe is here so the first
-- one can be built on what the client answers, recorded in
-- docs/FOREVER_API_FINDINGS.md, instead of on a guess. Some calls only answer
-- with a window open: run it again at a quest giver, a flight master, an
-- innkeeper and a trainer.

local _, ns = ...

local Probe = ns.NewModule("Probe")

-- The calls a guide might want, in both the classic and the retail shapes,
-- since Forever is a retail engine running classic content.
local APIS = {
    -- Who and where the character is.
    "UnitClass", "UnitLevel", "UnitRace", "UnitFactionGroup", "UnitXP", "UnitXPMax",
    "GetXPExhaustion", "GetZoneText", "GetSubZoneText", "GetRealZoneText",
    "C_Map.GetBestMapForUnit", "C_Map.GetPlayerMapPosition", "C_Map.GetMapInfo",
    -- The quest log and what is already done.
    "GetNumQuestLogEntries", "C_QuestLog.GetNumQuestLogEntries", "C_QuestLog.GetInfo",
    "GetQuestLogTitle", "C_QuestLog.GetQuestIDForLogIndex", "C_QuestLog.GetQuestObjectives",
    "GetQuestLogLeaderBoard", "C_QuestLog.IsQuestFlaggedCompleted", "IsQuestFlaggedCompleted",
    "GetQuestsCompleted", "C_QuestLog.GetAllCompletedQuestIDs", "C_QuestLog.GetMaxNumQuestsCanAccept",
    -- Talking to a quest giver: the gossip list, then the quest window.
    "C_GossipInfo.GetAvailableQuests", "C_GossipInfo.GetActiveQuests", "C_GossipInfo.GetOptions",
    "C_GossipInfo.SelectAvailableQuest", "C_GossipInfo.SelectActiveQuest", "C_GossipInfo.SelectOption",
    "GetGossipAvailableQuests", "GetGossipActiveQuests", "SelectGossipAvailableQuest",
    "GetNumAvailableQuests", "GetNumActiveQuests", "GetQuestID", "AcceptQuest",
    "IsQuestCompletable", "CompleteQuest", "GetNumQuestChoices", "GetNumQuestRewards", "GetQuestReward",
    -- Flight paths.
    "NumTaxiNodes", "TaxiNodeName", "TaxiNodeGetType", "TaxiNodePosition", "TaxiNodeCost",
    "TakeTaxiNode", "GetTaxiMapID",
    "C_TaxiMap.GetAllTaxiNodes", "C_TaxiMap.GetTaxiNodesForMap", "UnitOnTaxi",
    -- The hearthstone and where it is set. Classic's ConfirmBinder is gone on
    -- Forever; retail confirms the innkeeper through C_PlayerInteractionManager.
    "GetBindLocation", "ConfirmBinder", "C_Container.GetItemCooldown", "GetItemCooldown",
    "C_PlayerInteractionManager.ConfirmationInteraction",
    "C_PlayerInteractionManager.IsInteractingWithNpcOfType",
    -- Trainers and vendors. Classic's GetMerchantItemInfo is gone on Forever;
    -- Butler and Equipment read the vendor through the C_MerchantFrame call
    -- and the item link.
    "GetNumTrainerServices", "GetTrainerServiceInfo", "BuyTrainerService",
    "GetMerchantNumItems", "GetMerchantItemInfo", "C_MerchantFrame.GetItemInfo",
    "GetMerchantItemLink", "GetMerchantItemID", "BuyMerchantItem",
    -- The game's own waypoint, which an arrow could hand the way to.
    "C_Map.SetUserWaypoint", "C_SuperTrack.SetSuperTrackedUserWaypoint",
    "UiMapPoint.CreateFromCoordinates", "C_Navigation.GetDistance",
}

-- The events a guide would listen for. Registering one the client does not
-- know raises on Forever, so each is tried in a pcall.
local EVENTS = {
    "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED", "QUEST_LOG_UPDATE",
    "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_GREETING",
    "GOSSIP_SHOW", "GOSSIP_CLOSED", "TAXIMAP_OPENED", "TAXIMAP_CLOSED",
    "CONFIRM_BINDER", "TRAINER_SHOW", "MERCHANT_SHOW", "PLAYER_LEVEL_UP",
    "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "PLAYER_XP_UPDATE",
}

-- Words that mark a call as one a guide might use, found under any name.
-- Quest is left out: C_QuestLog alone would fill the chat window.
local HINTS = { "gossip", "taxi", "binder", "flightpath", "hearth", "playerinteraction" }

-- The kinds of NPC a guide step talks to, by their names in
-- Enum.PlayerInteractionType, for the "talking to" line.
local NPC_KINDS = { "Gossip", "QuestGiver", "Merchant", "Trainer", "TaxiNode", "Binder" }

-- The game's quest window pages, by frame name: an offer, "come back when
-- it's done" (with the Complete Quest button), the reward, and an NPC's list.
-- Turning in needs CompleteQuest on the second and GetQuestReward on the third.
local QUEST_PAGES = {
    { "offer", "QuestFrameDetailPanel" },
    { "progress", "QuestFrameProgressPanel" },
    { "reward", "QuestFrameRewardPanel" },
    { "list", "QuestFrameGreetingPanel" },
}

-- The hearthstone's item ID, for its cooldown.
local HEARTHSTONE = 6948

local function Resolve(path)
    local value = _G
    for part in path:gmatch("[^.]+") do
        if type(value) ~= "table" then return nil end
        value = value[part]
    end
    return value
end

local function Has(path)
    return type(Resolve(path)) == "function"
end

local function Line(label, value)
    local ok, text = pcall(tostring, value)
    ns.PrintRaw(("  |c%s%s|r  %s"):format(ns.COLORS.muted, label, ok and text or "(unreadable)"))
end

--- A client value as plain text. In instances and on some units Forever hands
--- back secret values. tostring of one stays secret, and so does joining it
--- with "..", which the client allows; only table.concat and comparisons
--- raise. So ask the client first, where it can say, and otherwise prove the
--- text survives table.concat before handing it on.
local function Text(value)
    local isSecret = _G.issecretvalue
    if type(isSecret) == "function" then
        local ok, secret = pcall(isSecret, value)
        if not ok or secret then return "(secret)" end
    end
    local ok, text = pcall(function()
        local plain = tostring(value)
        return table.concat({ plain })
    end)
    return ok and text or "(secret)"
end

--- A table a call returned, as its size and up to eight of its fields, so a
--- list of quests or flight paths can be read without a second probe. A
--- list shows its first entry's fields.
local function Summary(tbl)
    local ok, text = pcall(function()
        local count = 0
        for _ in pairs(tbl) do count = count + 1 end
        local sample, label = tbl, "table of " .. count
        if type(tbl[1]) == "table" then
            sample, label = tbl[1], label .. ", first"
        end
        local keys = {}
        for key in pairs(sample) do keys[#keys + 1] = Text(key) end
        table.sort(keys)
        local parts = {}
        for i = 1, math.min(#keys, 8) do
            local value = sample[keys[i]]
            if value == nil then value = sample[tonumber(keys[i])] end
            parts[i] = keys[i] .. "=" .. (type(value) == "table" and "table" or Text(value))
        end
        return label .. (#parts > 0 and (": " .. table.concat(parts, ", ")) or "")
    end)
    return ok and text or "a table (unreadable)"
end

--- Call a global (or a dotted C_ path) inside a pcall and join what it
--- returns, or say why not.
local function Read(name, ...)
    if not Has(name) then return "absent" end
    local results = { pcall(Resolve(name), ...) }
    if not results[1] then return "raised" end
    if #results == 1 then return "nothing" end
    if type(results[2]) == "table" then return Summary(results[2]) end

    local parts = {}
    for i = 2, #results do parts[#parts + 1] = Text(results[i]) end
    return table.concat(parts, ", ")
end

local function Hinted(name)
    local lower = name:lower()
    for _, hint in ipairs(HINTS) do
        if lower:find(hint, 1, true) then return true end
    end
    return false
end

--- Every global function, and every function in a C_ namespace, whose name
--- looks like one a guide might use.
local function GuideCalls()
    local found = {}
    for key, value in pairs(_G) do
        if type(key) == "string" then
            if type(value) == "function" and Hinted(key) then
                found[#found + 1] = key
            elseif type(value) == "table" and key:sub(1, 2) == "C_" then
                for inner, fn in pairs(value) do
                    if type(inner) == "string" and type(fn) == "function"
                        and (Hinted(inner) or Hinted(key)) then
                        found[#found + 1] = key .. "." .. inner
                    end
                end
            end
        end
    end
    table.sort(found)
    return found
end

--- Which of EVENTS the client knows, tried on a frame of the probe's own
--- that is let go of straight away.
local function KnownEvents()
    local known, unknown = {}, {}
    local ok, frame = pcall(CreateFrame, "Frame")
    if not ok or type(frame) ~= "table" then return known, EVENTS end
    for _, event in ipairs(EVENTS) do
        if pcall(frame.RegisterEvent, frame, event) then
            known[#known + 1] = event
        else
            unknown[#unknown + 1] = event
        end
    end
    pcall(frame.UnregisterAllEvents, frame)
    return known, unknown
end

--- The character's place on the zone map, as "map 1411 at 0.512, 0.443".
local function Position()
    local mapID = Read("C_Map.GetBestMapForUnit", "player")
    if not Has("C_Map.GetPlayerMapPosition") then return "map " .. mapID .. ", no position call" end
    local ok, text = pcall(function()
        local point = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
        if not point then return "map " .. mapID .. ", no position here" end
        local x, y = point:GetXY()
        return ("map %s at %.3f, %.3f"):format(mapID, x, y)
    end)
    return ok and Text(text) or ("map " .. mapID .. ", position raised")
end

--- Which kinds of NPC the client says the character is talking to, as
--- "Merchant, Gossip", or why it cannot say.
local function TalkingTo()
    if not Has("C_PlayerInteractionManager.IsInteractingWithNpcOfType") then return "absent" end
    local kinds = type(_G.Enum) == "table" and _G.Enum.PlayerInteractionType
    if type(kinds) ~= "table" then return "no Enum.PlayerInteractionType" end
    local open, unknown = {}, {}
    for _, name in ipairs(NPC_KINDS) do
        local kind = kinds[name]
        if kind == nil then
            unknown[#unknown + 1] = name
        else
            local ok, yes = pcall(C_PlayerInteractionManager.IsInteractingWithNpcOfType, kind)
            if ok and yes == true then open[#open + 1] = name end
        end
    end
    local text = #open > 0 and table.concat(open, ", ") or "nobody"
    if #unknown > 0 then text = text .. "; no kind " .. table.concat(unknown, ", ") end
    return text
end

--- Every gossip option, in the order the window shows them, as
--- "[0] 12345 Trick or Treat! (icon 132053)", so a step can pick one by its
--- ID. The client hands the list back in its own order, not the window's.
local function GossipOptions()
    if not Has("C_GossipInfo.GetOptions") then return "absent" end
    local ok, text = pcall(function()
        local options = C_GossipInfo.GetOptions() or {}
        local sorted = {}
        for _, option in pairs(options) do
            if type(option) == "table" then sorted[#sorted + 1] = option end
        end
        table.sort(sorted, function(a, b)
            return (tonumber(a.orderIndex) or 0) < (tonumber(b.orderIndex) or 0)
        end)
        local parts = {}
        for _, option in ipairs(sorted) do
            parts[#parts + 1] = ("[%s] %s %s (icon %s)"):format(Text(option.orderIndex),
                Text(option.gossipOptionID), Text(option.name), Text(option.icon))
        end
        return #parts .. (#parts > 0 and (": " .. table.concat(parts, "; ")) or "")
    end)
    return ok and text or "raised"
end

--- The flight map's paths: how many of each type, then every one the
--- character can fly to as "Thunder Bluff (REACHABLE, 9 copper)". Names are
--- the client's, in its language, so a step should not find a path by name.
local function FlightPaths()
    if not Has("NumTaxiNodes") then return "absent" end
    local ok, text = pcall(function()
        local count = tonumber(NumTaxiNodes()) or 0
        local byType, open = {}, {}
        for i = 1, count do
            local kind = Text(Has("TaxiNodeGetType") and TaxiNodeGetType(i) or "?")
            byType[kind] = (byType[kind] or 0) + 1
            if kind == "REACHABLE" or kind == "CURRENT" then
                local cost = Has("TaxiNodeCost") and Text(TaxiNodeCost(i)) or "?"
                open[#open + 1] = ("%s (%s, %s copper)"):format(Text(TaxiNodeName(i)), kind, cost)
            end
        end
        local kinds = {}
        for kind, n in pairs(byType) do kinds[#kinds + 1] = kind .. " " .. n end
        table.sort(kinds)
        local head = count .. (#kinds > 0 and (" (" .. table.concat(kinds, ", ") .. ")") or "")
        return head .. (#open > 0 and (": " .. table.concat(open, "; ")) or "")
    end)
    return ok and text or "raised"
end

--- Which page of the game's quest window is showing, as "reward", or
--- "none" when the window is shut.
local function QuestPage()
    local shown, missing = {}, {}
    for _, page in ipairs(QUEST_PAGES) do
        local frame = _G[page[2]]
        if type(frame) ~= "table" then
            missing[#missing + 1] = page[2]
        else
            local ok, yes = pcall(frame.IsShown, frame)
            if ok and yes == true then shown[#shown + 1] = page[1] end
        end
    end
    local text = #shown > 0 and table.concat(shown, ", ") or "none"
    if #missing > 0 then text = text .. "; no frame " .. table.concat(missing, ", ") end
    return text
end

--- How many quests the client says this character has done.
local function CompletedCount()
    for _, name in ipairs({ "C_QuestLog.GetAllCompletedQuestIDs", "GetQuestsCompleted" }) do
        if Has(name) then
            local ok, text = pcall(function()
                local done = Resolve(name)()
                local count = 0
                for _ in pairs(done or {}) do count = count + 1 end
                return name .. ": " .. count
            end)
            return ok and text or (name .. ": raised")
        end
    end
    return "absent"
end

function Probe:Run()
    ns.Print("probe: what this client supports for a leveling guide")

    -- Two lines rather than one per call, so the whole probe fits in the
    -- chat window without scrolling.
    local present, missing = {}, {}
    for _, api in ipairs(APIS) do
        if Has(api) then
            present[#present + 1] = api
        else
            missing[#missing + 1] = api
        end
    end
    Line("has", #present > 0 and table.concat(present, ", ") or "none of them")
    Line("missing", #missing > 0 and table.concat(missing, ", ") or "nothing")

    local known, unknown = KnownEvents()
    Line("events known", #known > 0 and table.concat(known, ", ") or "none of them")
    Line("events unknown", #unknown > 0 and table.concat(unknown, ", ") or "nothing")

    -- The Blizzard window style draws with the game's own art; this says
    -- which pieces the client has (UI/BlizzardLook.lua).
    if ns.BlizzardLook then
        for _, text in ipairs(ns.BlizzardLook.ProbeLines()) do
            local name, value = text:match("^(.-): (.*)$")
            Line(name or "style", value or text)
        end
    end

    -- The long list first, so the readings people look for end up at the
    -- bottom of the chat window.
    local calls = GuideCalls()
    Line("guide-like calls", #calls > 0 and table.concat(calls, ", ") or "none found")

    Line("class", Read("UnitClass", "player"))
    Line("race", Read("UnitRace", "player"))
    Line("faction", Read("UnitFactionGroup", "player"))
    Line("level", Read("UnitLevel", "player"))
    Line("experience", Read("UnitXP", "player") .. " / " .. Read("UnitXPMax", "player")
        .. "; rested " .. Read("GetXPExhaustion"))
    Line("zone", Read("GetZoneText") .. "; " .. Read("GetSubZoneText"))
    Line("position", Position())

    Line("quests in log", Read("C_QuestLog.GetNumQuestLogEntries") .. "; " .. Read("GetNumQuestLogEntries"))
    Line("first quest", Read("C_QuestLog.GetInfo", 1))
    Line("quests done", CompletedCount())
    Line("quest log room", Read("C_QuestLog.GetMaxNumQuestsCanAccept"))

    -- These answer only with the matching window open.
    Line("gossip quests", Read("C_GossipInfo.GetAvailableQuests") .. "; active "
        .. Read("C_GossipInfo.GetActiveQuests"))
    Line("gossip options", GossipOptions())
    Line("quest window", Read("GetQuestID") .. "; completable " .. Read("IsQuestCompletable"))
    Line("quest page", QuestPage() .. "; reward choices " .. Read("GetNumQuestChoices")
        .. ", rewards " .. Read("GetNumQuestRewards"))
    Line("flight paths", FlightPaths())
    local taxiMap = Has("GetTaxiMapID") and select(2, pcall(GetTaxiMapID)) or nil
    Line("flight nodes", "map " .. Text(taxiMap) .. "; "
        .. (taxiMap and Read("C_TaxiMap.GetAllTaxiNodes", taxiMap) or "no map"))
    Line("talking to", TalkingTo())
    Line("trainer", Read("GetNumTrainerServices") .. "; first " .. Read("GetTrainerServiceInfo", 1))
    Line("vendor", Read("GetMerchantNumItems") .. "; first " .. Read("C_MerchantFrame.GetItemInfo", 1)
        .. "; link " .. Read("GetMerchantItemLink", 1) .. "; id " .. Read("GetMerchantItemID", 1))

    Line("hearth set at", Read("GetBindLocation"))
    Line("hearth cooldown", Read("C_Container.GetItemCooldown", HEARTHSTONE) .. "; "
        .. Read("GetItemCooldown", HEARTHSTONE))
    Line("on a flight", Read("UnitOnTaxi", "player"))
end

ns.RegisterCommand("probe", "check what this client supports for a leveling guide (reads only)", function()
    ns.KeepCheck("probe", Probe.Run, Probe)
end)
