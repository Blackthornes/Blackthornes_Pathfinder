-- Blackthornes Pathfinder -- UI/MainWindow.lua
-- The guide window. Empty for now: the steps of the leveling guide (go
-- here, take this quest, buy this, fly there, train) will fill it.
--
-- It is what a click on the minimap button and a bare /bpath open. Built like
-- the settings window (same header, palette and row heights) so the two read
-- as one set, and like Pets' window, which it was copied from.

local _, ns = ...
local L = ns.L

local UI = ns.NewModule("UI")

local Theme = ns.Theme
local Widgets = ns.Widgets

local PADDING = 18
-- From the window's top to the gold rule under the header row.
local HEADER = 44
-- The metal rim sits on the window's edge and reaches this far inward, with
-- room to spare (UI/Titanforged.lua).
local EDGE_PAD = 11
local WIDTH = 420
local HEIGHT = 300

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

function UI:Build()
    if self.frame then return self.frame end

    local frame = CreateFrame("Frame", "BlackthornesPathfinderWindow", UIParent)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    Theme.Fill(frame, "window")

    -- The house frame (UI/Titanforged.lua): a gold rim with corner gems, the
    -- compass in a round portrait, the name on a plate and a red close gem.
    if ns.Titanforged then
        local trim = ns.Titanforged:Dress(frame, {
            title = "Blackthornes Pathfinder",
            portrait = true,
            close = function() UI:Hide() end,
        })
        self.trim = trim

        -- Kept on the screen whole: the portrait and plate reach out past
        -- the top left, and the corner gems past every edge.
        local left, right, top, bottom = ns.Titanforged.Reach(trim)
        if frame.SetClampRectInsets then
            frame:SetClampRectInsets(-left, right, top, -bottom)
        end
    else
        Theme.Border(frame, "borderLit")
    end

    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        UI:SavePosition()
    end)

    -- Escape closes it, like the game's own windows.
    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "BlackthornesPathfinderWindow")
    end

    self.frame = frame
    self:BuildHeader()

    local empty = Theme.CreateLabel(frame, "normal", "muted")
    empty:SetPoint("CENTER", 0, 0)
    empty:SetText(L["The guide isn't ready yet."])
    self.emptyLabel = empty

    -- The installed version, small and faint in the bottom right corner, so
    -- a player can see at a glance which one they run.
    local version = Theme.CreateLabel(frame, "tiny", "dim", "RIGHT")
    version:SetPoint("BOTTOMRIGHT", -PADDING, 14)
    version:SetText(ns.VersionLabel())
    self.versionLabel = version

    local footer = Theme.CreateLabel(frame, "small", "muted")
    footer:SetPoint("BOTTOMLEFT", PADDING, 14)
    footer:SetPoint("BOTTOMRIGHT", version, "BOTTOMLEFT", -12, 0)
    self.footer = footer

    frame:Hide()
    return frame
end

--- The header row. The window's name is on the plate across the top edge
--- and the close gem sits on the top right corner (UI/Titanforged.lua), so
--- the row holds the character's level and the Settings button, clear of
--- the portrait on the left.
function UI:BuildHeader()
    local frame = self.frame

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", EDGE_PAD, -EDGE_PAD)
    header:SetPoint("TOPRIGHT", -EDGE_PAD, -EDGE_PAD)
    header:SetHeight(HEADER - EDGE_PAD)

    -- A gold rule under it, bright at the left and fading out to the right.
    local rule = header:CreateTexture(nil, "ARTWORK")
    rule:SetPoint("BOTTOMLEFT")
    rule:SetPoint("BOTTOMRIGHT")
    rule:SetHeight(1)
    Theme.SetGradientAlpha(rule, "HORIZONTAL", "accent", 0.6, 0.05)

    -- Past the portrait, which reaches 48 pixels into the window.
    local subtitle = Theme.CreateLabel(header, "small", "muted")
    subtitle:SetPoint("LEFT", header, "LEFT", 48, -4)
    self.subtitle = subtitle

    -- Below the close gem on the corner.
    local settings = Widgets.CreateButton(header, L["Settings"], function()
        if ns.SettingsUI then ns.SettingsUI:Toggle() end
    end, { width = 70, height = 20 })
    settings:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -10, 4)
end

--------------------------------------------------------------------------------
-- Filling it in
--------------------------------------------------------------------------------

--- The character's level, or nil if unreadable.
function UI:PlayerLevel()
    if type(UnitLevel) ~= "function" then return nil end
    local ok, level = pcall(UnitLevel, "player")
    if ok and type(level) == "number" then return level end
    return nil
end

--- Bring the window up to date with the character.
function UI:Refresh()
    if not (self.frame and self.frame:IsShown()) then return end

    local level = self:PlayerLevel()
    if level then
        self.subtitle:SetText(L.Format("Level %d", level))
    else
        self.subtitle:SetText("")
    end
end

--------------------------------------------------------------------------------
-- Position and visibility
--------------------------------------------------------------------------------

function UI:SavePosition()
    if not (ns.db and self.frame) then return end
    local point, _, relativePoint, x, y = self.frame:GetPoint()
    ns.db.point, ns.db.relativePoint, ns.db.x, ns.db.y = point, relativePoint, x, y
end

function UI:RestorePosition()
    if not self.frame then return end
    local db = ns.db or {}
    self.frame:ClearAllPoints()
    self.frame:SetPoint(db.point or "CENTER", UIParent, db.relativePoint or "CENTER",
        db.x or 0, db.y or 40)
end

function UI:Show()
    self:Build()
    if not self.frame:IsShown() then
        self:RestorePosition()
        self.frame:Show()
        ns.Motion:Open(self.frame)
        -- A light runs round the portrait as it opens.
        if ns.Titanforged then ns.Titanforged:Opened(self.frame) end
    end
    self:Refresh()
end

function UI:Hide()
    if self.frame then self.frame:Hide() end
end

function UI:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

ns.RegisterCommand("window", L["open the guide window (so does /bpath on its own)"], function()
    UI:Toggle()
end)
