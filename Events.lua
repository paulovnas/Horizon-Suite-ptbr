--[[
    Horizon Suite - Focus - Event Dispatch
    Event frame, ScheduleRefresh, OnEvent, global API for Options.
]]

local A = _G.ModernQuestTracker

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
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

local function ScheduleRefresh()
    if A.refreshPending then return end
    A.refreshPending = true
    C_Timer.After(0.05, function()
        A.refreshPending = false
        A.FullLayout()
    end)
end

A.ScheduleRefresh = ScheduleRefresh

-- On map close: sync world quest watch list so untracked-on-map quests drop from tracker.
local function OnWorldMapClosed()
    if not A.GetCurrentWorldQuestWatchSet then return end
    local currentSet = A.GetCurrentWorldQuestWatchSet()
    local lastSet = A.lastWorldQuestWatchSet
    if lastSet and next(lastSet) then
        if not A.recentlyUntrackedWorldQuests then A.recentlyUntrackedWorldQuests = {} end
        for questID, _ in pairs(lastSet) do
            if not currentSet[questID] then
                A.recentlyUntrackedWorldQuests[questID] = true
            end
        end
    end
    A.lastWorldQuestWatchSet = currentSet
    ScheduleRefresh()
end

local function HookWorldMapOnHide()
    if WorldMapFrame and not WorldMapFrame._MQTOnHideHooked then
        WorldMapFrame._MQTOnHideHooked = true
        WorldMapFrame:HookScript("OnHide", OnWorldMapClosed)
    end
end

_G.ModernQuestTracker_ApplyTypography  = A.ApplyTypography
_G.ModernQuestTracker_ApplyDimensions  = A.ApplyDimensions
_G.ModernQuestTracker_RequestRefresh   = ScheduleRefresh
_G.ModernQuestTracker_FullLayout       = A.FullLayout

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "ModernQuestTracker" then
            A.RestoreSavedPosition()
            A.ApplyTypography()
            A.ApplyDimensions()
            if ModernQuestTrackerDB and ModernQuestTrackerDB.collapsed then
                A.collapsed = true
                A.chevron:SetText("+")
                A.scrollFrame:Hide()
                A.targetHeight  = A.GetCollapsedHeight()
                A.currentHeight = A.GetCollapsedHeight()
            end
            C_Timer.After(1, HookWorldMapOnHide)
        elseif addonName == "Blizzard_WorldMap" then
            HookWorldMapOnHide()
        elseif addonName == "Blizzard_ObjectiveTracker" then
            if A.enabled then A.TrySuppressTracker() end
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        if A.layoutPendingAfterCombat then
            A.layoutPendingAfterCombat = nil
            A.FullLayout()
        end

    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        if A.enabled then
            A.zoneJustChanged = true
            A.TrySuppressTracker()
            ScheduleRefresh()
            C_Timer.After(0.4, function() if A.enabled then A.FullLayout() end end)
        end

    elseif event == "QUEST_TURNED_IN" then
        local questID = ...
        for i = 1, A.POOL_SIZE do
            if A.pool[i].questID == questID and A.pool[i].animState ~= "fadeout" then
                local e = A.pool[i]
                e.titleText:SetTextColor(A.QUEST_COLORS.COMPLETE[1], A.QUEST_COLORS.COMPLETE[2], A.QUEST_COLORS.COMPLETE[3], 1)
                e.animState = "completing"
                e.animTime  = 0
                A.activeMap[questID] = nil
            end
        end
        ScheduleRefresh()

    elseif event == "QUEST_WATCH_UPDATE" then
        local questID = ...
        if questID and A.GetDB("objectiveProgressFlash", true) then
            for i = 1, A.POOL_SIZE do
                if A.pool[i].questID == questID then
                    A.pool[i].flashTime = A.FLASH_DUR
                end
            end
        end
        ScheduleRefresh()

    elseif event == "QUEST_WATCH_LIST_CHANGED" then
        local questID, added = ...
        if questID and C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID) then
            if not A.recentlyUntrackedWorldQuests then A.recentlyUntrackedWorldQuests = {} end
            if added then
                A.recentlyUntrackedWorldQuests[questID] = nil
            else
                A.recentlyUntrackedWorldQuests[questID] = true
            end
        end
        ScheduleRefresh()

    elseif event == "VIGNETTE_MINIMAP_UPDATED" or event == "VIGNETTES_UPDATED" then
        ScheduleRefresh()

    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
        A.zoneJustChanged = true
        if A.recentlyUntrackedWorldQuests then
            wipe(A.recentlyUntrackedWorldQuests)
        end
        ScheduleRefresh()
        C_Timer.After(0.4, function() if A.enabled then A.FullLayout() end end)

    else
        ScheduleRefresh()
    end
end)
