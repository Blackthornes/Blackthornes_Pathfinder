-- Blackthornes Pathfinder -- Logic/Recorder.lua
-- The recorder: what really happens while leveling, kept so the route
-- planner can plan from it (docs/STEP_FORMAT.md, "Where the facts come
-- from").
--
-- The owner levels with it on (2026-10-19); it is not offered to players
-- yet, so `/bpath record` is typed only: set straight in ns.commands, it is
-- in neither the help list nor Settings. Its chat lines are for us and stay
-- in English, like the probe's.
--
-- While it is on, every character that plays keeps a run, account wide, in
-- BlackthornesPathfinderDB.recorded[guid] = { runs = { run, ... } }, where
-- a run is { race, class, side, level, started, events = { ... } } and
-- each event is a list that starts with the second it happened (time())
-- and its kind:
--
--   { t, "p", map, x, y }                     where the character is, every
--                                             few seconds once it has moved
--   { t, "o", quest, npc, title, map, x, y }  a quest offered (the window
--                                             with Accept)
--   { t, "a", quest, map, x, y }              a quest accepted
--   { t, "j", quest, n, have, need, map, x, y }  an objective moved on
--   { t, "q", quest, page, npc, map, x, y }   a hand-in window ("progress"
--                                             or "reward") and who shows it
--   { t, "t", quest, xp, money, map, x, y }   a quest turned in
--   { t, "x", level, xp, max }                XP as the game reports it
--   { t, "l", level }                         a level gained
--   { t, "k", npc, map, x, y }                a kill that gave XP, the mob
--                                             being the dead target
--   { t, "n", kind, npc, name, map, x, y }    an NPC's window: gossip,
--                                             merchant, trainer or taxi
--   { t, "f", { node, state, ... } }          the flight map's paths
--   { t, "y", node }                          a flight taken
--   { t, "d", map, x, y }                     landed
--   { t, "h", place }                         the hearthstone set to a new place
--   { t, "c", spell }                         a spell cast out of a fight
--   { t, "z", map }                           a new zone or a loading screen
--   { t, "r", alive }                         died (false) or alive again
--
-- An event with a spot always ends with it. Spots are uiMap IDs with 0 to
-- 100 coordinates, as routes use them, and false where the game keeps the
-- spot back. NPC
-- IDs come from the unit's GUID; nothing names or keys a player but the
-- run's own GUID, which tools/fold_recording.py leaves out of anything it
-- writes. Never rename `recorder` or `recorded`.
--
-- Smooth play first: events are kept as they come, the quest log is read
-- once, half a second after a burst of quest events, and only for the
-- quests in it, and position is read every SAMPLE seconds. Every client
-- value is read inside a pcall and copied: in an instance the game hands out
-- secret values that raise when touched.

local _, ns = ...

local Recorder = ns.NewModule("Recorder")

-- Seconds between position readings, and how far (map units, 0 to 100) the
-- character must have gone for one to be kept.
Recorder.SAMPLE = 5
Recorder.MOVED = 0.15
-- A run stops keeping positions past this many events (quest events go on).
Recorder.MOST = 40000
-- Seconds after a quest event before the log is read.
Recorder.SETTLE = 0.5

local NPC_EVENTS = {
    GOSSIP_SHOW = "gossip",
    MERCHANT_SHOW = "merchant",
    TRAINER_SHOW = "trainer",
    TAXIMAP_OPENED = "taxi",
}

--------------------------------------------------------------------------------
-- Reading the client
--------------------------------------------------------------------------------

local function Plain(value)
    local isSecret = _G.issecretvalue
    if type(isSecret) == "function" then
        local ok, secret = pcall(isSecret, value)
        if not ok or secret then return nil end
    end
    local ok, copy = pcall(function()
        if type(value) == "number" then return value + 0 end
        if type(value) == "string" then return table.concat({ value }) end
        if type(value) == "boolean" then return value == true end
        return nil
    end)
    return ok and copy or nil
end

local function Read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local result = { pcall(fn, ...) }
    if not result[1] then return nil end
    return unpack(result, 2)
end

local function Round(n)
    return math.floor(n * 10 + 0.5) / 10
end

--- The character's map and spot, or nil where the game keeps it back.
function Recorder.Spot()
    local maps = _G.C_Map
    if type(maps) ~= "table" then return nil end
    local map = Plain(Read(maps.GetBestMapForUnit, "player"))
    if not map then return nil end
    local point = Read(maps.GetPlayerMapPosition, map, "player")
    if type(point) ~= "table" or type(point.GetXY) ~= "function" then return nil end
    local x, y = Read(point.GetXY, point)
    x, y = Plain(x), Plain(y)
    if not (x and y) then return nil end
    return map, Round(x * 100), Round(y * 100)
end

--- The NPC ID in a unit's GUID ("Creature-0-1-2-3-3143-0000"), or nil.
function Recorder.NpcID(unit)
    local guid = Plain(Read(_G.UnitGUID, unit))
    if not guid then return nil end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
    if kind == "Creature" or kind == "Vehicle" or kind == "GameObject" then
        return tonumber(id)
    end
    return nil
end

--------------------------------------------------------------------------------
-- The run
--------------------------------------------------------------------------------

function Recorder:IsOn()
    return ns.db and ns.db.recorder == true
end

local function Now()
    return type(time) == "function" and time() or 0
end

--- The run this character is keeping, made the first time it is needed.
function Recorder:Run(fresh)
    if not ns.db then return nil end
    local guid = Plain(Read(_G.UnitGUID, "player"))
    if not guid then return nil end
    ns.db.recorded = ns.db.recorded or {}
    local mine = ns.db.recorded[guid]
    if type(mine) ~= "table" then
        mine = { runs = {} }
        ns.db.recorded[guid] = mine
    end
    mine.runs = mine.runs or {}
    local run = mine.runs[#mine.runs]
    if fresh or type(run) ~= "table" then
        local _, race = Read(_G.UnitRace, "player")
        local _, class = Read(_G.UnitClass, "player")
        run = {
            race = Plain(race), class = Plain(class),
            side = Plain(Read(_G.UnitFactionGroup, "player")),
            level = Plain(Read(_G.UnitLevel, "player")),
            started = Now(), events = {},
        }
        mine.runs[#mine.runs + 1] = run
    end
    return run
end

--- Keep one event: { now, kind, ... }. Positions stop once a run is full.
function Recorder:Keep(kind, ...)
    if not self:IsOn() then return end
    local run = self:Run()
    if not run then return end
    local events = run.events
    if kind == "p" and #events >= self.MOST then return end
    local event = { Now(), kind }
    for i = 1, select("#", ...) do
        event[i + 2] = Plain((select(i, ...))) or (type((select(i, ...))) == "table" and (select(i, ...))) or false
    end
    events[#events + 1] = event
    return event
end

--- Keep an event with where the character stands added at its end.
function Recorder:KeepHere(kind, ...)
    local map, x, y = self.Spot()
    local args = { ... }
    local n = select("#", ...)
    args[n + 1], args[n + 2], args[n + 3] = map or false, x or false, y or false
    return self:Keep(kind, unpack(args, 1, n + 3))
end

--------------------------------------------------------------------------------
-- Watching
--------------------------------------------------------------------------------

--- Where the character is, kept when it has moved far enough.
function Recorder:Sample()
    if not self:IsOn() then return end
    local map, x, y = self.Spot()
    if not map then return end
    local last = self.lastSpot
    if last and last[1] == map and math.abs(last[2] - x) < self.MOVED and math.abs(last[3] - y) < self.MOVED then
        return
    end
    self.lastSpot = { map, x, y }
    self:Keep("p", map, x, y)
end

--- Every objective of every quest in the log, as [quest] = { have, ... }.
local function Objectives()
    local log = _G.C_QuestLog
    if type(log) ~= "table" then return {} end
    local out = {}
    local entries = Plain(Read(log.GetNumQuestLogEntries)) or 0
    for i = 1, entries do
        local info = Read(log.GetInfo, i)
        local quest = type(info) == "table" and not info.isHeader and Plain(info.questID)
        if quest then
            local list = Read(log.GetQuestObjectives, quest)
            local have = {}
            if type(list) == "table" then
                for n, objective in ipairs(list) do
                    if type(objective) == "table" then
                        have[n] = { Plain(objective.numFulfilled) or 0, Plain(objective.numRequired) or 0 }
                    end
                end
            end
            out[quest] = have
        end
    end
    return out
end

--- Read the log and keep each objective that moved on since the last read.
function Recorder:ReadLog()
    self.logPending = false
    if not self:IsOn() then return end
    local now = Objectives()
    local before = self.objectives
    if before then
        for quest, list in pairs(now) do
            local old = before[quest] or {}
            for n, pair in ipairs(list) do
                local was = old[n] and old[n][1] or 0
                if pair[1] > was then
                    self:KeepHere("j", quest, n, pair[1], pair[2])
                end
            end
        end
    end
    self.objectives = now
end

function Recorder:LogChanged()
    if self.logPending or not self:IsOn() then return end
    self.logPending = true
    if _G.C_Timer and C_Timer.After then
        C_Timer.After(self.SETTLE, function() Recorder:ReadLog() end)
    else
        self:ReadLog()
    end
end

--- The flight map's paths as { node, state, node, state, ... }, and which
--- slot is which node, for the flight taken.
function Recorder:ReadFlightMap()
    local taxi = _G.C_TaxiMap
    local map = Plain(Read(_G.GetTaxiMapID))
    local nodes = type(taxi) == "table" and map and Read(taxi.GetAllTaxiNodes, map)
    local flat, slots = {}, {}
    if type(nodes) == "table" then
        for _, node in ipairs(nodes) do
            local id = type(node) == "table" and Plain(node.nodeID)
            if id then
                flat[#flat + 1] = id
                flat[#flat + 1] = Plain(node.state) or -1
                local slot = Plain(node.slotIndex)
                if slot then slots[slot] = id end
            end
        end
    end
    self.slots = slots
    return flat
end

function Recorder:CheckHome()
    local home = Plain(Read(_G.GetBindLocation))
    if home and self.home and home ~= self.home then
        self:Keep("h", home)
    end
    self.home = home or self.home
end

function Recorder:OnEvent(event, ...)
    if not self:IsOn() then return end
    if event == "QUEST_DETAIL" then
        local quest = Plain(Read(_G.GetQuestID))
        if quest and quest > 0 then
            self:KeepHere("o", quest, self.NpcID("npc") or false, Plain(Read(_G.GetTitleText)) or false)
        end
    elseif event == "QUEST_ACCEPTED" then
        -- (questID) on this engine; (log index, questID) on older ones.
        local a, b = ...
        local quest = Plain(b) or Plain(a)
        if quest then self:KeepHere("a", quest) end
        self:LogChanged()
    elseif event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then
        local quest = Plain(Read(_G.GetQuestID))
        if quest and quest > 0 then
            self:KeepHere("q", quest, event == "QUEST_PROGRESS" and "progress" or "reward",
                self.NpcID("npc") or false)
        end
    elseif event == "QUEST_TURNED_IN" then
        local quest, xp, money = ...
        self:KeepHere("t", Plain(quest) or false, Plain(xp) or false, Plain(money) or false)
        self:LogChanged()
    elseif event == "QUEST_LOG_UPDATE" or event == "UNIT_QUEST_LOG_CHANGED" then
        self:LogChanged()
    elseif event == "PLAYER_XP_UPDATE" then
        self:Keep("x", Plain(Read(_G.UnitLevel, "player")) or false,
            Plain(Read(_G.UnitXP, "player")) or false, Plain(Read(_G.UnitXPMax, "player")) or false)
    elseif event == "PLAYER_LEVEL_UP" then
        self:Keep("l", Plain((...)) or false)
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        -- XP for a kill: the mob is the target, if it lies dead. Quest XP
        -- comes with QUEST_TURNED_IN instead.
        if Read(_G.UnitIsDead, "target") then
            local npc = self.NpcID("target")
            if npc then self:KeepHere("k", npc) end
        end
    elseif NPC_EVENTS[event] then
        local name = Plain(Read(_G.UnitName, "npc"))
        self:KeepHere("n", NPC_EVENTS[event], self.NpcID("npc") or false, name or false)
        if event == "TAXIMAP_OPENED" then self:Keep("f", self:ReadFlightMap()) end
    elseif event == "GOSSIP_CLOSED" or event == "HEARTHSTONE_BOUND" then
        self:CheckHome()
    elseif event == "PLAYER_CONTROL_GAINED" then
        if self.flying then
            self.flying = false
            self:KeepHere("d")
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spell = ...
        if unit == "player" and not Read(_G.UnitAffectingCombat, "player") then
            self:Keep("c", Plain(spell) or false)
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
        local map = Plain(Read(_G.C_Map and C_Map.GetBestMapForUnit, "player"))
        self:Keep("z", map or false)
        self:CheckHome()
    elseif event == "PLAYER_DEAD" then
        self:KeepHere("r", false)
    elseif event == "PLAYER_UNGHOST" or event == "PLAYER_ALIVE" then
        self:KeepHere("r", true)
    end
end

local EVENTS = {
    "QUEST_DETAIL", "QUEST_ACCEPTED", "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_TURNED_IN",
    "QUEST_LOG_UPDATE", "UNIT_QUEST_LOG_CHANGED", "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP",
    "CHAT_MSG_COMBAT_XP_GAIN", "GOSSIP_SHOW", "MERCHANT_SHOW", "TRAINER_SHOW", "TAXIMAP_OPENED",
    "GOSSIP_CLOSED", "HEARTHSTONE_BOUND", "PLAYER_CONTROL_GAINED", "UNIT_SPELLCAST_SUCCEEDED",
    "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD", "PLAYER_DEAD", "PLAYER_UNGHOST", "PLAYER_ALIVE",
}

function Recorder:OnEnable()
    for _, event in ipairs(EVENTS) do
        ns.RegisterEvent(self, event, self.OnEvent)
    end
    -- A flight taken: which node the slot is, read when the map opened.
    if type(hooksecurefunc) == "function" and type(_G.TakeTaxiNode) == "function" then
        pcall(hooksecurefunc, "TakeTaxiNode", function(slot)
            if not Recorder:IsOn() then return end
            local node = Recorder.slots and Recorder.slots[Plain(slot) or -1]
            Recorder.flying = true
            Recorder:Keep("y", node or false)
        end)
    end
    if _G.C_Timer and C_Timer.NewTicker then
        self.ticker = C_Timer.NewTicker(self.SAMPLE, function() Recorder:Sample() end)
    end
    self.home = Plain(Read(_G.GetBindLocation))
    if self:IsOn() then self:Started() end
end

--- Read what the run compares against, so the first reading is not taken
--- as a change, and keep where the run picks up.
function Recorder:Started()
    self.objectives = Objectives()
    self.lastSpot = nil
    self:KeepHere("z")
    self:Sample()
end

--------------------------------------------------------------------------------
-- /bpath record
--------------------------------------------------------------------------------

function Recorder:Status()
    local run = self:Run()
    if not self:IsOn() then
        ns.Print("Recorder is off. /bpath record on starts it.")
        return
    end
    local events = run and run.events or {}
    local minutes = run and run.started and math.floor((Now() - run.started) / 60) or 0
    ns.Print(("Recorder is on: %d events over %d minutes for this character."):format(#events, minutes))
end

function Recorder:Command(text)
    local word = (text or ""):lower():match("^(%S*)")
    if word == "on" or word == "new" then
        ns.db.recorder = true
        self:Run(word == "new")
        self:Started()
        ns.Print(word == "new" and "Recorder is on, in a new run." or "Recorder is on.")
    elseif word == "off" then
        self:Keep("z", false)
        ns.db.recorder = false
        ns.Print("Recorder is off. What it kept stays saved.")
    else
        self:Status()
    end
end

ns.commands.record = {
    usage = "on, off or new: keep what happens while leveling, for the planner",
    fn = function(text) Recorder:Command(text) end,
}
