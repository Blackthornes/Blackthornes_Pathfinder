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
    "IsQuestCompletable", "CompleteQuest", "GetNumQuestChoices", "GetQuestReward",
    -- Flight paths.
    "NumTaxiNodes", "TaxiNodeName", "TaxiNodeGetType", "TaxiNodePosition", "TakeTaxiNode",
    "C_TaxiMap.GetAllTaxiNodes", "C_TaxiMap.GetTaxiNodesForMap", "UnitOnTaxi",
    -- The hearthstone and where it is set.
    "GetBindLocation", "ConfirmBinder", "C_Container.GetItemCooldown", "GetItemCooldown",
    -- Trainers and vendors.
    "GetNumTrainerServices", "GetTrainerServiceInfo", "BuyTrainerService",
    "GetMerchantNumItems", "GetMerchantItemInfo", "BuyMerchantItem",
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
local HINTS = { "gossip", "taxi", "binder", "flightpath", "hearth" }

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
    Line("gossip options", Read("C_GossipInfo.GetOptions"))
    Line("quest window", Read("GetQuestID") .. "; completable " .. Read("IsQuestCompletable"))
    Line("flight paths", Read("NumTaxiNodes") .. "; first " .. Read("TaxiNodeName", 1)
        .. ", " .. Read("TaxiNodeGetType", 1))
    Line("trainer", Read("GetNumTrainerServices") .. "; first " .. Read("GetTrainerServiceInfo", 1))
    Line("vendor", Read("GetMerchantNumItems"))

    Line("hearth set at", Read("GetBindLocation"))
    Line("hearth cooldown", Read("C_Container.GetItemCooldown", HEARTHSTONE) .. "; "
        .. Read("GetItemCooldown", HEARTHSTONE))
    Line("on a flight", Read("UnitOnTaxi", "player"))
end

ns.RegisterCommand("probe", "check what this client supports for a leveling guide (reads only)", function()
    ns.KeepCheck("probe", Probe.Run, Probe)
end)
