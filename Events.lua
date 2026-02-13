--[[
    Horizon Suite - Focus - Event Dispatch
    Event frame, ScheduleRefresh, table-dispatch OnEvent, world-map watch-list sync,
    global API for Options.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- EVENT DISPATCH
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
eventFrame:RegisterEvent("QUEST_WATCH_UPDATE")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_REMOVED")
eventFrame:RegisterEvent("QUEST_TURNED_IN")
eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
eventFrame:RegisterEvent("SUPER_TRACKING_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
eventFrame:RegisterEvent("VIGNETTES_UPDATED")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("SCENARIO_UPDATE")
eventFrame:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
eventFrame:RegisterEvent("SCENARIO_CRITERIA_SHOW_STATE_UPDATE")
eventFrame:RegisterEvent("SCENARIO_COMPLETED")
eventFrame:RegisterEvent("SCENARIO_SPELL_UPDATE")
eventFrame:RegisterEvent("CRITERIA_COMPLETE")
eventFrame:RegisterEvent("TRACKED_ACHIEVEMENT_UPDATE")
eventFrame:RegisterEvent("CRITERIA_UPDATE")
eventFrame:RegisterEvent("ACHIEVEMENT_EARNED")
eventFrame:RegisterEvent("CONTENT_TRACKING_UPDATE")
pcall(function() eventFrame:RegisterEvent("ACTIVE_DELVE_DATA_UPDATE") end)

local function ScheduleRefresh()
    if addon.refreshPending then return end
    addon.refreshPending = true
    C_Timer.After(0.05, function()
        addon.refreshPending = false
        addon.FullLayout()
    end)
end

addon.ScheduleRefresh = ScheduleRefresh

-- On map close: sync world quest watch list so untracked-on-map quests drop from tracker.
local function OnWorldMapClosed()
    if not addon.GetCurrentWorldQuestWatchSet then return end
    local currentSet = addon.GetCurrentWorldQuestWatchSet()
    local lastSet = addon.lastWorldQuestWatchSet
    if lastSet and next(lastSet) then
        if not addon.recentlyUntrackedWorldQuests then addon.recentlyUntrackedWorldQuests = {} end
        for questID, _ in pairs(lastSet) do
            if not currentSet[questID] then
                addon.recentlyUntrackedWorldQuests[questID] = true
            end
        end
    end
    addon.lastWorldQuestWatchSet = currentSet
    ScheduleRefresh()
end

local function HookWorldMapOnHide()
    if WorldMapFrame and not WorldMapFrame._HSOnHideHooked then
        WorldMapFrame._HSOnHideHooked = true
        WorldMapFrame:HookScript("OnHide", OnWorldMapClosed)
    end
end

-- When the world map is opened, refresh the objective list (live APIs; no cache).
local function OnWorldMapShown()
    C_Timer.After(0.5, function()
        if not addon.enabled or not WorldMapFrame then return end
        ScheduleRefresh()
    end)
end

local function HookWorldMapOnShow()
    if WorldMapFrame and not WorldMapFrame._HSOnShowHooked then
        WorldMapFrame._HSOnShowHooked = true
        WorldMapFrame:HookScript("OnShow", OnWorldMapShown)
    end
end

local function StartScenarioTimerHeartbeat()
    if addon._scenarioTimerHeartbeat then return end
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(1, 1)
    f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -1000, -1000)
    f:Show()
    f._elapsed = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        if not addon.enabled or addon.collapsed then return end
        if addon.ShouldHideInCombat and addon.ShouldHideInCombat() then return end
        if not addon.GetDB("showScenarioEvents", true) then return end
        self._elapsed = (self._elapsed or 0) + elapsed
        if self._elapsed < 5 then return end
        self._elapsed = 0
        if addon.IsScenarioActive and addon.IsScenarioActive() then
            ScheduleRefresh()
        end
    end)
    addon._scenarioTimerHeartbeat = f
end

_G.HorizonSuite_ApplyTypography  = addon.ApplyTypography
_G.HorizonSuite_ApplyDimensions  = addon.ApplyDimensions
_G.HorizonSuite_RequestRefresh   = ScheduleRefresh
_G.HorizonSuite_FullLayout       = addon.FullLayout

-- ============================================================================
-- EVENT HANDLERS (table dispatch)
-- ============================================================================

local function OnAddonLoaded(addonName)
        if addonName == "HorizonSuite" then
            addon.RestoreSavedPosition()
            addon.ApplyTypography()
            addon.ApplyDimensions()
            if addon.ApplyBackdropOpacity then addon.ApplyBackdropOpacity() end
            if addon.ApplyBorderVisibility then addon.ApplyBorderVisibility() end
            if HorizonDB and HorizonDB.collapsed then
                addon.collapsed = true
                addon.chevron:SetText("+")
                addon.scrollFrame:Hide()
                addon.targetHeight  = addon.GetCollapsedHeight()
                addon.currentHeight = addon.GetCollapsedHeight()
            end
            StartScenarioTimerHeartbeat()
            local function tryHookWorldMap()
                HookWorldMapOnHide()
                HookWorldMapOnShow()
            end
            C_Timer.After(0.5, tryHookWorldMap)
            for attempt = 1, 5 do
                C_Timer.After(1 + attempt, tryHookWorldMap)
            end
            C_Timer.After(1, function()
                HookWorldMapOnHide()
                HookWorldMapOnShow()
            end)
        elseif addonName == "Blizzard_WorldMap" then
            HookWorldMapOnHide()
            HookWorldMapOnShow()
        elseif addonName == "Blizzard_ObjectiveTracker" then
            if addon.enabled then addon.TrySuppressTracker() end
            ScheduleRefresh()
        end
end

local function OnPlayerRegenDisabled()
    if addon.GetDB("hideInCombat", false) and addon.enabled then
        local useAnim = addon.GetDB("animations", true)
        if useAnim and addon.HS:IsShown() then
            addon.combatFadeState = "out"
            addon.combatFadeTime  = 0
        else
            addon.HS:Hide()
            if addon.UpdateFloatingQuestItem then addon.UpdateFloatingQuestItem(nil) end
            if addon.UpdateMplusBlock then addon.UpdateMplusBlock() end
        end
    end
end

local function OnPlayerRegenEnabled()
    if addon.layoutPendingAfterCombat then
        addon.layoutPendingAfterCombat = nil
        if addon.GetDB("hideInCombat", false) and addon.enabled then
            addon.combatFadeState = "in"
            addon.combatFadeTime  = 0
        end
        addon.FullLayout()
    elseif addon.GetDB("hideInCombat", false) and addon.enabled then
        addon.combatFadeState = "in"
        addon.combatFadeTime  = 0
        ScheduleRefresh()
    end
end

local function OnPlayerLoginOrEnteringWorld()
    if addon.enabled then
        addon.zoneJustChanged = true
        addon.TrySuppressTracker()
        ScheduleRefresh()
        C_Timer.After(0.4, function() if addon.enabled then addon.FullLayout() end end)
        C_Timer.After(1.5, function() if addon.enabled then ScheduleRefresh() end end)
    end
end

local function OnQuestTurnedIn(questID)
    for i = 1, addon.POOL_SIZE do
        if addon.pool[i].questID == questID and addon.pool[i].animState ~= "fadeout" then
            local e = addon.pool[i]
            e.titleText:SetTextColor(addon.QUEST_COLORS.COMPLETE[1], addon.QUEST_COLORS.COMPLETE[2], addon.QUEST_COLORS.COMPLETE[3], 1)
            e.animState = "completing"
            e.animTime  = 0
            addon.activeMap[questID] = nil
        end
    end
    ScheduleRefresh()
end

local function OnQuestWatchUpdate(questID)
    if questID and addon.GetDB("objectiveProgressFlash", true) then
        for i = 1, addon.POOL_SIZE do
            if addon.pool[i].questID == questID then
                addon.pool[i].flashTime = addon.FLASH_DUR
            end
        end
    end
    ScheduleRefresh()
end

local function OnQuestWatchListChanged(questID, added)
    if questID and addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID) then
        if not addon.recentlyUntrackedWorldQuests then addon.recentlyUntrackedWorldQuests = {} end
        if added then
            addon.recentlyUntrackedWorldQuests[questID] = nil
        else
            addon.recentlyUntrackedWorldQuests[questID] = true
        end
    end
    ScheduleRefresh()
end

local function OnZoneChanged(event)
    addon.zoneJustChanged = true
    addon.lastPlayerMapID = nil
    if addon.recentlyUntrackedWorldQuests then wipe(addon.recentlyUntrackedWorldQuests) end
    if addon.zoneTaskQuestCache then wipe(addon.zoneTaskQuestCache) end
    ScheduleRefresh()
    C_Timer.After(0.4, function() if addon.enabled then addon.FullLayout() end end)
    C_Timer.After(1.5, function() if addon.enabled then ScheduleRefresh() end end)
    if event == "ZONE_CHANGED_NEW_AREA" then
        C_Timer.After(2.5, function() if addon.enabled then ScheduleRefresh() end end)
    end
end

local eventHandlers = {
    ADDON_LOADED             = function(_, addonName) OnAddonLoaded(addonName) end,
    PLAYER_REGEN_DISABLED    = function() OnPlayerRegenDisabled() end,
    PLAYER_REGEN_ENABLED     = function() OnPlayerRegenEnabled() end,
    PLAYER_LOGIN             = function() OnPlayerLoginOrEnteringWorld() end,
    PLAYER_ENTERING_WORLD    = function() OnPlayerLoginOrEnteringWorld() end,
    QUEST_TURNED_IN          = function(_, questID) OnQuestTurnedIn(questID) end,
    QUEST_WATCH_UPDATE       = function(_, questID) OnQuestWatchUpdate(questID) end,
    QUEST_WATCH_LIST_CHANGED = function(_, questID, added) OnQuestWatchListChanged(questID, added) end,
    VIGNETTE_MINIMAP_UPDATED = function() ScheduleRefresh() end,
    VIGNETTES_UPDATED        = function() ScheduleRefresh() end,
    ZONE_CHANGED             = function(evt) OnZoneChanged(evt) end,
    ZONE_CHANGED_NEW_AREA    = function(evt) OnZoneChanged(evt) end,
    SCENARIO_UPDATE          = function() ScheduleRefresh() end,
    SCENARIO_CRITERIA_UPDATE = function() ScheduleRefresh() end,
    SCENARIO_CRITERIA_SHOW_STATE_UPDATE = function() ScheduleRefresh() end,
    SCENARIO_COMPLETED       = function() ScheduleRefresh() end,
    SCENARIO_SPELL_UPDATE    = function() ScheduleRefresh() end,
    CRITERIA_COMPLETE        = function() ScheduleRefresh() end,
    TRACKED_ACHIEVEMENT_UPDATE = function() ScheduleRefresh() end,
    CRITERIA_UPDATE          = function() ScheduleRefresh() end,
    ACHIEVEMENT_EARNED       = function() ScheduleRefresh() end,
    CONTENT_TRACKING_UPDATE  = function(_, trackableType)
        local achType = (Enum and Enum.ContentTrackingType and Enum.ContentTrackingType.Achievement) or 2
        if trackableType == achType then ScheduleRefresh() end
    end,
    ACTIVE_DELVE_DATA_UPDATE = function() ScheduleRefresh() end,
}

--- OnEvent: table-dispatch to eventHandlers[event]; falls back to ScheduleRefresh for unhandled events.
-- @param self table Event frame
-- @param event string WoW event name (e.g. QUEST_WATCH_LIST_CHANGED, ADDON_LOADED)
-- @param ... any Event payload (varargs)
eventFrame:SetScript("OnEvent", function(self, event, ...)
    local fn = eventHandlers[event]
    if fn then
        fn(event, ...)
    else
        ScheduleRefresh()
    end
end)
