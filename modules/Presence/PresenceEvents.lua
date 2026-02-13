--[[
    Horizon Suite - Presence - Event Dispatch
    Zone changes, level up, boss emotes, achievements, quest events.
]]

local addon = _G.HorizonSuite
if not addon or not addon.Presence then return end

-- ============================================================================
-- QUEST TEXT DETECTION (used by PresenceErrors and here)
-- ============================================================================

local function IsQuestText(msg)
    if not msg then return false end
    return msg:find("%d+/%d+")
        or msg:find("%%")
        or msg:find("slain")
        or msg:find("destroyed")
        or msg:find("Quest Accepted")
        or msg:find("Complete")
end

addon.Presence.IsQuestText = IsQuestText

-- ============================================================================
-- EVENT FRAME
-- ============================================================================

local eventFrame = CreateFrame("Frame")
local eventsRegistered = false

local PRESENCE_EVENTS = {
    "ADDON_LOADED",
    "ZONE_CHANGED",
    "ZONE_CHANGED_INDOORS",
    "ZONE_CHANGED_NEW_AREA",
    "PLAYER_LEVEL_UP",
    "RAID_BOSS_EMOTE",
    "ACHIEVEMENT_EARNED",
    "QUEST_ACCEPTED",
    "QUEST_TURNED_IN",
    "UI_INFO_MESSAGE",
}

local function OnAddonLoaded(addonName)
    if addonName == "Blizzard_WorldQuestComplete" and addon.Presence.KillWorldQuestBanner then
        -- Defer so the addon has time to create WorldQuestCompleteBannerFrame
        C_Timer.After(0, function()
            addon.Presence.KillWorldQuestBanner()
        end)
        C_Timer.After(0.5, function()
            addon.Presence.KillWorldQuestBanner()
            eventFrame:UnregisterEvent("ADDON_LOADED")
        end)
    end
end

local function OnPlayerLevelUp(_, level)
    addon.Presence.QueueOrPlay("LEVEL_UP", "LEVEL UP", "You have reached level " .. (level or "??"))
end

local function OnRaidBossEmote(_, msg, unitName)
    local bossName = unitName or "Boss"
    local formatted = msg or ""
    formatted = formatted:gsub("|T.-|t", "")
    formatted = formatted:gsub("|c%x%x%x%x%x%x%x%x", "")
    formatted = formatted:gsub("|r", "")
    formatted = formatted:gsub("%%s", bossName)
    formatted = strtrim(formatted)
    addon.Presence.QueueOrPlay("BOSS_EMOTE", bossName, formatted)
end

local function OnAchievementEarned(_, achID)
    local _, name = GetAchievementInfo(achID)
    addon.Presence.QueueOrPlay("ACHIEVEMENT", "ACHIEVEMENT EARNED", name or "")
end

local function OnQuestAccepted(_, questID)
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local title = C_QuestLog.GetTitleForQuestID(questID) or "New Quest"
        addon.Presence.QueueOrPlay("QUEST_ACCEPT", "QUEST ACCEPTED", title)
    else
        addon.Presence.QueueOrPlay("QUEST_ACCEPT", "QUEST ACCEPTED", "New Quest")
    end
end

local function OnQuestTurnedIn(_, questID)
    local title = "Objective"
    if C_QuestLog then
        if C_QuestLog.GetTitleForQuestID then
            title = C_QuestLog.GetTitleForQuestID(questID) or title
        end
        if C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID) then
            addon.Presence.QueueOrPlay("WORLD_QUEST", "WORLD QUEST", title)
            return
        end
    end
    addon.Presence.QueueOrPlay("QUEST_COMPLETE", "QUEST COMPLETE", title)
end

local function OnUIInfoMessage(_, msgType, msg)
    if IsQuestText(msg) and not (msg and (msg:find("Quest Accepted") or msg:find("Accepted"))) then
        addon.Presence.QueueOrPlay("QUEST_UPDATE", "QUEST UPDATE", msg or "")
    end
end

local function OnZoneChangedNewArea()
    local zone = GetZoneText() or "Unknown Zone"
    local sub  = GetSubZoneText() or ""
    local wait = addon.Presence.DISCOVERY_WAIT or 0.15
    C_Timer.After(wait, function()
        if not addon:IsModuleEnabled("presence") then return end
        local active = addon.Presence.active and addon.Presence.active()
        local activeTitle = addon.Presence.activeTitle and addon.Presence.activeTitle()
        local phase = addon.Presence.animPhase and addon.Presence.animPhase()
        if active and activeTitle == zone and (phase == "hold" or phase == "entrance") then
            addon.Presence.SoftUpdateSubtitle(sub)
            if addon.Presence.pendingDiscovery then
                addon.Presence.ShowDiscoveryLine()
                addon.Presence.pendingDiscovery = nil
            end
        else
            addon.Presence.QueueOrPlay("ZONE_CHANGE", zone, sub)
        end
    end)
end

local function OnZoneChanged()
    local sub = GetSubZoneText()
    if sub and sub ~= "" then
        local zone = GetZoneText() or ""
        local wait = addon.Presence.DISCOVERY_WAIT or 0.15
        C_Timer.After(wait, function()
            if not addon:IsModuleEnabled("presence") then return end
            local active = addon.Presence.active and addon.Presence.active()
            local activeTitle = addon.Presence.activeTitle and addon.Presence.activeTitle()
            local phase = addon.Presence.animPhase and addon.Presence.animPhase()
            if active and activeTitle == zone and (phase == "hold" or phase == "entrance") then
                addon.Presence.SoftUpdateSubtitle(sub)
                if addon.Presence.pendingDiscovery then
                    addon.Presence.ShowDiscoveryLine()
                    addon.Presence.pendingDiscovery = nil
                end
            else
                addon.Presence.QueueOrPlay("SUBZONE_CHANGE", zone, sub)
            end
        end)
    end
end

local eventHandlers = {
    ADDON_LOADED             = function(_, addonName) OnAddonLoaded(addonName) end,
    PLAYER_LEVEL_UP          = function(_, level) OnPlayerLevelUp(_, level) end,
    RAID_BOSS_EMOTE          = function(_, msg, unitName) OnRaidBossEmote(_, msg, unitName) end,
    ACHIEVEMENT_EARNED       = function(_, achID) OnAchievementEarned(_, achID) end,
    QUEST_ACCEPTED           = function(_, questID) OnQuestAccepted(_, questID) end,
    QUEST_TURNED_IN          = function(_, questID) OnQuestTurnedIn(_, questID) end,
    UI_INFO_MESSAGE          = function(_, msgType, msg) OnUIInfoMessage(_, msgType, msg) end,
    ZONE_CHANGED_NEW_AREA    = function() OnZoneChangedNewArea() end,
    ZONE_CHANGED             = function() OnZoneChanged() end,
    ZONE_CHANGED_INDOORS     = function() OnZoneChanged() end,
}

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if not addon:IsModuleEnabled("presence") then return end
    local fn = eventHandlers[event]
    if fn then fn(event, ...) end
end)

function addon.Presence.EnableEvents()
    if eventsRegistered then return end
    for _, evt in ipairs(PRESENCE_EVENTS) do
        eventFrame:RegisterEvent(evt)
    end
    eventsRegistered = true
end

function addon.Presence.DisableEvents()
    if not eventsRegistered then return end
    for _, evt in ipairs(PRESENCE_EVENTS) do
        eventFrame:UnregisterEvent(evt)
    end
    eventsRegistered = false
end

addon.Presence.eventFrame = eventFrame
