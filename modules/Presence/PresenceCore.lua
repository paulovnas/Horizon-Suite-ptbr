--[[
    Horizon Suite - Presence - Core
    Cinematic zone text and notification display. Frame, layers, animation engine,
    and public QueueOrPlay API. Ported from ModernZoneText.
]]

local addon = _G.HorizonSuite
if not addon then return end

addon.Presence = addon.Presence or {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local FONT_PATH    = "Fonts\\FRIZQT__.TTF"
local MAIN_SIZE    = 48
local SUB_SIZE     = 24
local FRAME_WIDTH  = 800
local FRAME_HEIGHT = 250
local FRAME_Y      = -180
local DIVIDER_W    = 400
local DIVIDER_H    = 2
local MAX_QUEUE    = 5

local ENTRANCE_DUR  = 0.7
local EXIT_DUR      = 0.8
local CROSSFADE_DUR = 0.4
local ELEMENT_DUR   = 0.4

local DISCOVERY_SIZE  = 16
local DISCOVERY_COLOR = {0.4, 1, 0.5}
local DELAY_TITLE     = 0.0
local DELAY_DIVIDER   = 0.15
local DELAY_SUBTITLE  = 0.30
local DELAY_DISCOVERY = 0.45

local TYPES = {
    LEVEL_UP       = { pri = 4, color = {0.1, 1, 0.2},   sub = {1, 1, 1},    sz = 48, dur = 5.0 },
    BOSS_EMOTE     = { pri = 4, color = {1, 0.2, 0.2},   sub = {1, 1, 1},    sz = 48, dur = 5.0 },
    ACHIEVEMENT    = { pri = 3, color = {1, 0.6, 0},     sub = {1, 1, 1},    sz = 48, dur = 4.5 },
    QUEST_COMPLETE = { pri = 2, color = {0, 0.8, 1},     sub = {1, 1, 1},    sz = 48, dur = 4.0 },
    WORLD_QUEST    = { pri = 2, color = {0.6, 0.2, 1},   sub = {1, 1, 1},    sz = 48, dur = 4.0 },
    ZONE_CHANGE    = { pri = 2, color = {1, 1, 1},       sub = {1, 0.82, 0}, sz = 48, dur = 4.0 },
    QUEST_ACCEPT   = { pri = 1, color = {1, 0.85, 0.3},   sub = {1, 1, 1},    sz = 36, dur = 3.0 },
    QUEST_UPDATE   = { pri = 1, color = {0.4, 0.8, 1},   sub = {1, 1, 1},    sz = 20, dur = 2.5 },
    SUBZONE_CHANGE = { pri = 1, color = {0.9, 0.9, 0.9}, sub = {1, 0.82, 0}, sz = 36, dur = 3.0 },
}

-- ============================================================================
-- FRAME & LAYER CREATION
-- ============================================================================

local function CreateLayer(parent)
    local L = {}

    L.titleShadow = parent:CreateFontString(nil, "BORDER")
    L.titleShadow:SetFont(FONT_PATH, MAIN_SIZE, "OUTLINE")
    L.titleShadow:SetTextColor(0, 0, 0, 0.8)
    L.titleShadow:SetJustifyH("CENTER")

    L.titleText = parent:CreateFontString(nil, "OVERLAY")
    L.titleText:SetFont(FONT_PATH, MAIN_SIZE, "OUTLINE")
    L.titleText:SetTextColor(1, 1, 1, 1)
    L.titleText:SetJustifyH("CENTER")
    L.titleText:SetPoint("TOP", 0, 0)
    L.titleShadow:SetPoint("CENTER", L.titleText, "CENTER", 2, -2)

    L.divider = parent:CreateTexture(nil, "ARTWORK")
    L.divider:SetSize(DIVIDER_W, DIVIDER_H)
    L.divider:SetPoint("TOP", 0, -65)
    L.divider:SetColorTexture(1, 1, 1, 1)
    L.divider:SetAlpha(0)

    L.subShadow = parent:CreateFontString(nil, "BORDER")
    L.subShadow:SetFont(FONT_PATH, SUB_SIZE, "OUTLINE")
    L.subShadow:SetTextColor(0, 0, 0, 0.8)
    L.subShadow:SetJustifyH("CENTER")

    L.subText = parent:CreateFontString(nil, "OVERLAY")
    L.subText:SetFont(FONT_PATH, SUB_SIZE, "OUTLINE")
    L.subText:SetTextColor(1, 0.82, 0, 1)
    L.subText:SetJustifyH("CENTER")
    L.subText:SetPoint("TOP", L.divider, "BOTTOM", 0, -10)
    L.subShadow:SetPoint("CENTER", L.subText, "CENTER", 1, -1)

    L.discoveryShadow = parent:CreateFontString(nil, "BORDER")
    L.discoveryShadow:SetFont(FONT_PATH, DISCOVERY_SIZE, "OUTLINE")
    L.discoveryShadow:SetTextColor(0, 0, 0, 0.8)
    L.discoveryShadow:SetJustifyH("CENTER")

    L.discoveryText = parent:CreateFontString(nil, "OVERLAY")
    L.discoveryText:SetFont(FONT_PATH, DISCOVERY_SIZE, "OUTLINE")
    L.discoveryText:SetTextColor(DISCOVERY_COLOR[1], DISCOVERY_COLOR[2], DISCOVERY_COLOR[3], 1)
    L.discoveryText:SetJustifyH("CENTER")
    L.discoveryText:SetPoint("TOP", L.subText, "BOTTOM", 0, -5)
    L.discoveryShadow:SetPoint("CENTER", L.discoveryText, "CENTER", 1, -1)
    L.discoveryText:SetAlpha(0)
    L.discoveryShadow:SetAlpha(0)

    return L
end

local F, layerA, layerB, curLayer, oldLayer
local anim
local active, activeTitle
local queue, crossfadeStartAlpha
local PlayCinematic

-- ============================================================================
-- EASING & ANIMATION HELPERS
-- ============================================================================

local function easeOut(t) return 1 - (1 - t) * (1 - t) end
local function easeIn(t)  return t * t end

local function entEase(elapsed, delay)
    if elapsed < delay then return 0 end
    return easeOut(math.min((elapsed - delay) / ELEMENT_DUR, 1))
end

local function resetLayer(L)
    L.titleText:SetAlpha(0)
    L.titleShadow:SetAlpha(0)
    L.divider:SetAlpha(0)
    L.subText:SetAlpha(0)
    L.subShadow:SetAlpha(0)
    L.discoveryText:SetAlpha(0)
    L.discoveryShadow:SetAlpha(0)
    L.discoveryText:SetText("")
    L.discoveryShadow:SetText("")
end

local function updateEntrance()
    local L  = curLayer
    local e  = anim.elapsed
    local te = entEase(e, DELAY_TITLE)
    local de = entEase(e, DELAY_DIVIDER)
    local se = entEase(e, DELAY_SUBTITLE)

    L.titleText:SetAlpha(te)
    L.titleShadow:SetAlpha(te * 0.8)
    L.titleText:ClearAllPoints()
    L.titleText:SetPoint("TOP", 0, (1 - te) * 20)

    L.divider:SetAlpha(de * 0.5)
    L.divider:SetSize(math.max(DIVIDER_W * de, 0.01), DIVIDER_H)

    L.subText:SetAlpha(se)
    L.subShadow:SetAlpha(se * 0.8)
    L.subText:ClearAllPoints()
    L.subText:SetPoint("TOP", L.divider, "BOTTOM", 0, -10 + (1 - se) * (-10))

    if (L.discoveryText:GetText() or "") ~= "" then
        local dse = entEase(e, DELAY_DISCOVERY)
        L.discoveryText:SetAlpha(dse)
        L.discoveryShadow:SetAlpha(dse * 0.8)
    end
end

local function updateCrossfade()
    local fadeT = math.min(anim.elapsed / CROSSFADE_DUR, 1)
    local fade  = crossfadeStartAlpha * (1 - easeIn(fadeT))
    oldLayer.titleText:SetAlpha(fade)
    oldLayer.titleShadow:SetAlpha(fade * 0.8)
    oldLayer.divider:SetAlpha(fade * 0.5)
    oldLayer.subText:SetAlpha(fade)
    oldLayer.subShadow:SetAlpha(fade * 0.8)
    if (oldLayer.discoveryText:GetText() or "") ~= "" then
        oldLayer.discoveryText:SetAlpha(fade)
        oldLayer.discoveryShadow:SetAlpha(fade * 0.8)
    end
    updateEntrance()
end

local function updateExit()
    local L   = curLayer
    local e   = easeIn(math.min(anim.elapsed / EXIT_DUR, 1))
    local inv = 1 - e

    L.titleText:SetAlpha(inv)
    L.titleShadow:SetAlpha(inv * 0.8)
    L.titleText:ClearAllPoints()
    L.titleText:SetPoint("TOP", 0, e * 15)

    L.divider:SetAlpha(0.5 * inv)
    L.divider:SetSize(math.max(DIVIDER_W * inv, 0.01), DIVIDER_H)

    L.subText:SetAlpha(inv)
    L.subShadow:SetAlpha(inv * 0.8)
    L.subText:ClearAllPoints()
    L.subText:SetPoint("TOP", L.divider, "BOTTOM", 0, -10 + e * (-10))

    if (L.discoveryText:GetText() or "") ~= "" then
        L.discoveryText:SetAlpha(inv)
        L.discoveryShadow:SetAlpha(inv * 0.8)
    end
end

local function finalizeEntrance()
    local L = curLayer
    L.titleText:SetAlpha(1)
    L.titleShadow:SetAlpha(0.8)
    L.titleText:ClearAllPoints()
    L.titleText:SetPoint("TOP", 0, 0)
    L.divider:SetAlpha(0.5)
    L.divider:SetSize(DIVIDER_W, DIVIDER_H)
    L.subText:SetAlpha(1)
    L.subShadow:SetAlpha(0.8)
    L.subText:ClearAllPoints()
    L.subText:SetPoint("TOP", L.divider, "BOTTOM", 0, -10)
    if (L.discoveryText:GetText() or "") ~= "" then
        L.discoveryText:SetAlpha(1)
        L.discoveryShadow:SetAlpha(0.8)
    end
end

local function onComplete()
    anim.phase  = "idle"
    active      = nil
    activeTitle = nil
    resetLayer(curLayer)
    resetLayer(oldLayer)
    F:Hide()

    if #queue > 0 then
        local best = 1
        for i = 2, #queue do
            if TYPES[queue[i][1]].pri > TYPES[queue[best][1]].pri then
                best = i
            end
        end
        local nxt = table.remove(queue, best)
        PlayCinematic(nxt[1], nxt[2], nxt[3])
    end
end

-- ============================================================================
-- INIT & PUBLIC API
-- ============================================================================

function addon.Presence.Init()
    if F then return end

    F = CreateFrame("Frame", "HorizonSuitePresenceFrame", UIParent)
    F:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    F:SetPoint("TOP", 0, FRAME_Y)
    F:Hide()

    layerA   = CreateLayer(F)
    layerB   = CreateLayer(F)
    curLayer = layerA
    oldLayer = layerB

    anim = { phase = "idle", elapsed = 0, holdDur = 4 }
    active = nil
    activeTitle = nil
    queue = {}
    crossfadeStartAlpha = 1
    addon.Presence.pendingDiscovery = nil

    F:SetScript("OnUpdate", function(_, dt)
        if anim.phase == "idle" then return end
        anim.elapsed = anim.elapsed + dt

        if anim.phase == "entrance" then
            updateEntrance()
            if anim.elapsed >= ENTRANCE_DUR then
                finalizeEntrance()
                anim.phase   = "hold"
                anim.elapsed = 0
            end
        elseif anim.phase == "crossfade" then
            updateCrossfade()
            if anim.elapsed >= ENTRANCE_DUR then
                finalizeEntrance()
                resetLayer(oldLayer)
                anim.phase   = "hold"
                anim.elapsed = 0
            end
        elseif anim.phase == "hold" then
            if anim.elapsed >= anim.holdDur then
                anim.phase   = "exit"
                anim.elapsed = 0
            end
        elseif anim.phase == "exit" then
            updateExit()
            if anim.elapsed >= EXIT_DUR then
                onComplete()
            end
        end
    end)

    addon.Presence.frame = F
    addon.Presence.anim = anim
    addon.Presence.active = function() return active end
    addon.Presence.activeTitle = function() return activeTitle end
    addon.Presence.animPhase = function() return anim.phase end
end

PlayCinematic = function(typeName, title, subtitle)
    local cfg = TYPES[typeName]
    if not cfg then return end

    local L = curLayer
    local c, sc = cfg.color, cfg.sub
    local mainSz = cfg.sz
    local subSz  = (cfg.sz >= SUB_SIZE) and SUB_SIZE or cfg.sz

    L.titleText:SetFont(FONT_PATH, mainSz, "OUTLINE")
    L.titleShadow:SetFont(FONT_PATH, mainSz, "OUTLINE")
    L.subText:SetFont(FONT_PATH, subSz, "OUTLINE")
    L.subShadow:SetFont(FONT_PATH, subSz, "OUTLINE")

    L.titleText:SetTextColor(c[1], c[2], c[3], 1)
    L.subText:SetTextColor(sc[1], sc[2], sc[3], 1)
    L.divider:SetVertexColor(c[1], c[2], c[3])

    L.titleText:SetText(title or "")
    L.titleShadow:SetText(title or "")
    L.subText:SetText(subtitle or "")
    L.subShadow:SetText(subtitle or "")

    resetLayer(L)
    L.divider:SetSize(0.01, DIVIDER_H)

    L.titleText:ClearAllPoints()
    L.titleText:SetPoint("TOP", 0, 20)
    L.subText:ClearAllPoints()
    L.subText:SetPoint("TOP", L.divider, "BOTTOM", 0, -20)

    if addon.Presence.pendingDiscovery and (typeName == "ZONE_CHANGE" or typeName == "SUBZONE_CHANGE") then
        L.discoveryText:SetText("Discovered")
        L.discoveryShadow:SetText("Discovered")
        addon.Presence.pendingDiscovery = nil
    end

    active       = cfg
    activeTitle  = title
    anim.elapsed = 0
    anim.holdDur = cfg.dur

    if oldLayer.titleText:GetAlpha() > 0 then
        anim.phase = "crossfade"
    else
        anim.phase = "entrance"
    end

    F:SetAlpha(1)
    F:Show()
end

function addon.Presence.SoftUpdateSubtitle(newSub)
    if not curLayer then return end
    curLayer.subText:SetText(newSub or "")
    curLayer.subShadow:SetText(newSub or "")
    if anim.phase == "hold" then
        anim.elapsed = 0
    end
end

function addon.Presence.ShowDiscoveryLine()
    if not curLayer then return end
    curLayer.discoveryText:SetText("Discovered")
    curLayer.discoveryShadow:SetText("Discovered")
    if anim.phase == "hold" then
        curLayer.discoveryText:SetAlpha(1)
        curLayer.discoveryShadow:SetAlpha(0.8)
    end
end

function addon.Presence.SetPendingDiscovery()
    addon.Presence.pendingDiscovery = true
end

local function interruptCurrent()
    crossfadeStartAlpha = curLayer.titleText:GetAlpha()
    oldLayer, curLayer = curLayer, oldLayer
    active      = nil
    activeTitle = nil
end

function addon.Presence.QueueOrPlay(typeName, title, subtitle)
    if not F then addon.Presence.Init() end
    local cfg = TYPES[typeName]
    if not cfg then return end

    if InCombatLockdown() and cfg.pri < 4 then return end

    if active then
        if cfg.pri >= active.pri then
            interruptCurrent()
            PlayCinematic(typeName, title, subtitle)
        else
            if #queue < MAX_QUEUE then
                queue[#queue + 1] = { typeName, title, subtitle }
            end
        end
    else
        PlayCinematic(typeName, title, subtitle)
    end
end

function addon.Presence.HideAndClear()
    if not F then return end
    anim.phase  = "idle"
    active      = nil
    activeTitle = nil
    queue = {}
    addon.Presence.pendingDiscovery = nil
    resetLayer(curLayer)
    resetLayer(oldLayer)
    F:Hide()
end

addon.Presence.DISCOVERY_WAIT = 0.15
