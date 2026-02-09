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

-- Cache quest IDs from C_QuestLog.GetQuestsOnMap (same source as map pins; returns data when map is open).
local function CacheQuestsOnMapForMap(cache, mapID)
    if not mapID or not C_QuestLog or not C_QuestLog.GetQuestsOnMap then return false end
    local onMap = C_QuestLog.GetQuestsOnMap(mapID)
    if not onMap or #onMap == 0 then return false end
    cache[mapID] = cache[mapID] or {}
    for _, info in ipairs(onMap) do
        if info and info.questID then
            cache[mapID][info.questID] = true
        end
    end
    return next(cache[mapID]) ~= nil
end

local function CacheZoneTaskQuestsForMap(cache, mapID)
    if not mapID or not C_TaskQuest or not C_TaskQuest.GetQuestsForPlayerByMapID then return false end
    local taskPOIs = C_TaskQuest.GetQuestsForPlayerByMapID(mapID, mapID) or C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
    if not taskPOIs then return false end
    cache[mapID] = cache[mapID] or {}
    local count = 0
    if #taskPOIs > 0 then
        for _, poi in ipairs(taskPOIs) do
            local id = poi.questID or poi.questId or (type(poi) == "number" and poi)
            if id then
                cache[mapID][id] = true
                count = count + 1
            end
        end
    end
    for k, v in pairs(taskPOIs) do
        if type(k) == "number" and k > 0 and not cache[mapID][k] then
            cache[mapID][k] = true
            count = count + 1
        elseif type(v) == "table" then
            local id = v.questID or v.questId
            if id and not cache[mapID][id] then
                cache[mapID][id] = true
                count = count + 1
            end
        end
    end
    return count > 0
end

-- When the world map is opened, cache quest IDs from GetQuestsOnMap (map pins) and TaskQuest for displayed + player zone.
local function OnWorldMapShown()
    C_Timer.After(0.5, function()
        if not A.enabled or not WorldMapFrame then return end
        A.zoneTaskQuestCache = A.zoneTaskQuestCache or {}
        local didCache = false
        if WorldMapFrame.mapID then
            if CacheQuestsOnMapForMap(A.zoneTaskQuestCache, WorldMapFrame.mapID) then didCache = true end
            if C_TaskQuest and C_TaskQuest.GetQuestsForPlayerByMapID and CacheZoneTaskQuestsForMap(A.zoneTaskQuestCache, WorldMapFrame.mapID) then didCache = true end
        end
        local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
        if playerMapID and playerMapID ~= WorldMapFrame.mapID then
            if CacheQuestsOnMapForMap(A.zoneTaskQuestCache, playerMapID) then didCache = true end
            if C_TaskQuest and C_TaskQuest.GetQuestsForPlayerByMapID and CacheZoneTaskQuestsForMap(A.zoneTaskQuestCache, playerMapID) then didCache = true end
        end
        if didCache then ScheduleRefresh() end
    end)
end

local function HookWorldMapOnShow()
    if WorldMapFrame and not WorldMapFrame._MQTOnShowHooked then
        WorldMapFrame._MQTOnShowHooked = true
        WorldMapFrame:HookScript("OnShow", OnWorldMapShown)
    end
end

-- WQT uses two-arg form: GetQuestsForPlayerByMapID(mapID, mapID). Returns true if any quests cached.
-- Parse both array and keyed table returns; some clients return { [questID] = info } or mixed.
local function CacheWQDataWQT(mapID)
    local api = C_TaskQuest and (C_TaskQuest.GetQuestsForPlayerByMapID or C_TaskQuest.GetQuestsOnMap)
    if not mapID or not api then return false end
    local taskInfo = api(mapID, mapID) or api(mapID)
    if not taskInfo then return false end
    A.zoneTaskQuestCache = A.zoneTaskQuestCache or {}
    A.zoneTaskQuestCache[mapID] = A.zoneTaskQuestCache[mapID] or {}
    local count = 0
    if #taskInfo > 0 then
        for _, poi in ipairs(taskInfo) do
            local id = (type(poi) == "table" and (poi.questID or poi.questId)) or (type(poi) == "number" and poi)
            if id then
                A.zoneTaskQuestCache[mapID][id] = true
                count = count + 1
            end
        end
    end
    for k, v in pairs(taskInfo) do
        if type(k) == "number" and k > 0 and not A.zoneTaskQuestCache[mapID][k] then
            A.zoneTaskQuestCache[mapID][k] = true
            count = count + 1
        elseif type(v) == "table" then
            local id = v.questID or v.questId
            if id and not A.zoneTaskQuestCache[mapID][id] then
                A.zoneTaskQuestCache[mapID][id] = true
                count = count + 1
            end
        end
    end
    return count > 0
end

-- Count quests in cache for a map (for the on-map debug indicator).
local function GetCachedWQCount(mapID)
    if not A.zoneTaskQuestCache or not mapID then return 0 end
    local t = A.zoneTaskQuestCache[mapID]
    if not t then return 0 end
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

-- Update the debug indicator on the world map (map + player zone cache counts).
local function UpdateWQMapIndicator(fromDelayed, mapID, playerMapID)
    local f = A.WQMapIndicator
    if not f or not f.text then return end
    mapID = mapID or GetWorldMapMapID()
    playerMapID = playerMapID or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
    local label = fromDelayed and " (0.5s)" or " (now)"
    local mapCount = GetCachedWQCount(mapID)
    local playerCount = playerMapID and GetCachedWQCount(playerMapID) or 0
    f.text:SetText(format("HS WQ: map %s -> %d  player %s -> %d%s",
        tostring(mapID or "?"), mapCount, tostring(playerMapID or "?"), playerCount, label))
    f:Show()
end

local function GetWorldMapMapID()
    if not WorldMapFrame then return nil end
    if WorldMapFrame.mapID then return WorldMapFrame.mapID end
    if WorldMapFrame.GetMapID and type(WorldMapFrame.GetMapID) == "function" then
        return WorldMapFrame:GetMapID()
    end
    if WorldMapFrame.GetMap and WorldMapFrame:GetMap() then
        local map = WorldMapFrame:GetMap()
        if map and map.GetMapID then return map:GetMapID() end
        if map and map.GetMapID and type(map.GetMapID) == "function" then return map:GetMapID() end
        if map and type(map) == "table" and map.mapID then return map.mapID end
    end
    return nil
end

-- Run WQT-style cache for displayed map and player zone; refresh objective list if we got data.
local function RunWQTMapCache(fromDelayed)
    if not WorldMapFrame or not WorldMapFrame:IsVisible() then return end
    local mapID = GetWorldMapMapID()
    local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    UpdateWQMapIndicator(fromDelayed, mapID, playerMapID)
    if not A.enabled or not mapID then return end
    local didCache = false
    if CacheWQDataWQT(mapID) then didCache = true end
    if playerMapID and playerMapID ~= mapID then
        if CacheWQDataWQT(playerMapID) then didCache = true end
    end
    if didCache then ScheduleRefresh() end
    UpdateWQMapIndicator(fromDelayed, mapID, playerMapID)
end

-- Hidden heartbeat: when map is open run cache for map + player zone; when map is closed run cache for player zone only so WQs appear without opening map.
local function StartMapCacheHeartbeat()
    if A._mapCacheHeartbeat then return end
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(1, 1)
    f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -1000, -1000)
    f:Hide()
    f._elapsed = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        self._elapsed = (self._elapsed or 0) + elapsed
        if self._elapsed < 0.5 then return end
        self._elapsed = 0
        if WorldMapFrame and WorldMapFrame:IsVisible() then
            RunWQTMapCache(false)
        else
            -- Map closed: still cache player's current zone so world quests show without opening map.
            local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
            if A.enabled and playerMapID and CacheWQDataWQT(playerMapID) then
                ScheduleRefresh()
            end
        end
    end)
    A._mapCacheHeartbeat = f
end

-- Mirror WQT: OnMapChanged runs immediately, then 0.5s delayed (like WQT's check_for_quests_on_unknown_map).
local function OnMapChanged()
    RunWQTMapCache(false)
    C_Timer.After(0.5, function()
        if WorldMapFrame and WorldMapFrame:IsVisible() then RunWQTMapCache(true) end
    end)
end

local function HookWorldMapOnMapChanged()
    if WorldMapFrame and not WorldMapFrame._MQTOnMapChangedHooked then
        WorldMapFrame._MQTOnMapChangedHooked = true
        hooksecurefunc(WorldMapFrame, "OnMapChanged", OnMapChanged)
    end
end

_G.ModernQuestTracker_ApplyTypography  = A.ApplyTypography
_G.ModernQuestTracker_ApplyDimensions  = A.ApplyDimensions
_G.ModernQuestTracker_RequestRefresh   = ScheduleRefresh
_G.ModernQuestTracker_FullLayout       = A.FullLayout

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "HorizonSuite" then
            A.RestoreSavedPosition()
            A.ApplyTypography()
            A.ApplyDimensions()
            if HorizonSuiteDB and HorizonSuiteDB.collapsed then
                A.collapsed = true
                A.chevron:SetText("+")
                A.scrollFrame:Hide()
                A.targetHeight  = A.GetCollapsedHeight()
                A.currentHeight = A.GetCollapsedHeight()
            end
            StartMapCacheHeartbeat()
            -- WQ map debug indicator: visible when world map is open.
            do
                local f = CreateFrame("Frame", "HorizonSuiteWQMapIndicator", UIParent, "BackdropTemplate")
                f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 20)
                f:SetSize(380, 32)
                f:SetFrameStrata("FULLSCREEN_DIALOG")
                f:SetFrameLevel(1000)
                f:SetClampedToScreen(true)
                local bg = f:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(0.1, 0.1, 0.35, 0.95)
                local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                text:SetPoint("LEFT", f, "LEFT", 8, 0)
                text:SetJustifyH("LEFT")
                text:SetTextColor(1, 0.95, 0.75, 1)
                text:SetText("HS WQ: (close)")
                f.text = text
                f:Hide()
                f._elapsed = 0
                f:SetScript("OnUpdate", function(self, elapsed)
                    if not self:IsShown() then return end
                    self._elapsed = (self._elapsed or 0) + elapsed
                    if self._elapsed < 0.5 then return end
                    self._elapsed = 0
                    if WorldMapFrame and WorldMapFrame:IsVisible() then
                        UpdateWQMapIndicator(false, GetWorldMapMapID(), C_Map and C_Map.GetBestMapForUnit("player"))
                        RunWQTMapCache(false)
                    end
                end)
                A.WQMapIndicator = f
            end
            -- If Blizzard_WorldMap loads later (e.g. on first map open), retry until WorldMapFrame exists.
            local function tryHookWorldMap()
                if not WorldMapFrame or (WorldMapFrame._HSIndicatorHooked) then return end
                WorldMapFrame._HSIndicatorHooked = true
                WorldMapFrame:HookScript("OnShow", function()
                    if A.WQMapIndicator and A.WQMapIndicator.text then
                        A.WQMapIndicator.text:SetText("HS WQ: (map open...)")
                        A.WQMapIndicator:Show()
                    end
                    local function tick()
                        if not WorldMapFrame or not WorldMapFrame:IsVisible() then return end
                        UpdateWQMapIndicator(false, GetWorldMapMapID(), C_Map and C_Map.GetBestMapForUnit("player"))
                        RunWQTMapCache(false)
                    end
                    local function tickDelayed()
                        if not WorldMapFrame or not WorldMapFrame:IsVisible() then return end
                        UpdateWQMapIndicator(true, GetWorldMapMapID(), C_Map and C_Map.GetBestMapForUnit("player"))
                        RunWQTMapCache(true)
                    end
                    C_Timer.After(0.1, tick)
                    C_Timer.After(0.6, tickDelayed)
                end)
                WorldMapFrame:HookScript("OnHide", function()
                    if A.WQMapIndicator then A.WQMapIndicator:Hide() end
                end)
                if WorldMapFrame:IsVisible() then
                    if A.WQMapIndicator and A.WQMapIndicator.text then
                        A.WQMapIndicator.text:SetText("HS WQ: (map open...)")
                        A.WQMapIndicator:Show()
                    end
                    local function tick()
                        if not WorldMapFrame or not WorldMapFrame:IsVisible() then return end
                        UpdateWQMapIndicator(false, GetWorldMapMapID(), C_Map and C_Map.GetBestMapForUnit("player"))
                        RunWQTMapCache(false)
                    end
                    C_Timer.After(0.1, tick)
                    C_Timer.After(0.6, function()
                        if not WorldMapFrame or not WorldMapFrame:IsVisible() then return end
                        UpdateWQMapIndicator(true, GetWorldMapMapID(), C_Map and C_Map.GetBestMapForUnit("player"))
                        RunWQTMapCache(true)
                    end)
                end
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
            StartMapCacheHeartbeat()
            HookWorldMapOnHide()
            HookWorldMapOnShow()
            HookWorldMapOnMapChanged()
            -- Show debug indicator when map is shown, hide when hidden; run cache on show.
            if WorldMapFrame and not WorldMapFrame._HSIndicatorHooked then
                WorldMapFrame._HSIndicatorHooked = true
                WorldMapFrame:HookScript("OnShow", function()
                    if A.WQMapIndicator and A.WQMapIndicator.text then
                        A.WQMapIndicator.text:SetText("HS WQ: (map open...)")
                        A.WQMapIndicator:Show()
                    end
                    local function tick()
                        if not WorldMapFrame or not WorldMapFrame:IsVisible() then return end
                        UpdateWQMapIndicator(false, GetWorldMapMapID(), C_Map and C_Map.GetBestMapForUnit("player"))
                        RunWQTMapCache(false)
                    end
                    local function tickDelayed()
                        if not WorldMapFrame or not WorldMapFrame:IsVisible() then return end
                        UpdateWQMapIndicator(true, GetWorldMapMapID(), C_Map and C_Map.GetBestMapForUnit("player"))
                        RunWQTMapCache(true)
                    end
                    C_Timer.After(0.1, tick)
                    C_Timer.After(0.6, tickDelayed)
                end)
                WorldMapFrame:HookScript("OnHide", function()
                    if A.WQMapIndicator then A.WQMapIndicator:Hide() end
                end)
                if WorldMapFrame:IsVisible() then
                    if A.WQMapIndicator and A.WQMapIndicator.text then
                        A.WQMapIndicator.text:SetText("HS WQ: (map open...)")
                        A.WQMapIndicator:Show()
                    end
                    C_Timer.After(0.1, function()
                        if not WorldMapFrame or not WorldMapFrame:IsVisible() then return end
                        UpdateWQMapIndicator(false, GetWorldMapMapID(), C_Map and C_Map.GetBestMapForUnit("player"))
                        RunWQTMapCache(false)
                    end)
                    C_Timer.After(0.6, function()
                        if not WorldMapFrame or not WorldMapFrame:IsVisible() then return end
                        UpdateWQMapIndicator(true, GetWorldMapMapID(), C_Map and C_Map.GetBestMapForUnit("player"))
                        RunWQTMapCache(true)
                    end)
                end
            end
            -- When the map refreshes its world quest data (same source as the pins on the map), cache that list so our objective list can show it.
            C_Timer.After(0.5, function()
                local ok, err = pcall(function()
                    if not (WorldQuestDataProviderMixin and WorldQuestDataProviderMixin.RefreshAllData and A and A.zoneTaskQuestCache) then return end
                    hooksecurefunc(WorldQuestDataProviderMixin, "RefreshAllData", function(self, fromOnShow)
                        local mapID
                        if self.GetMap and self:GetMap() and self:GetMap().GetMapID then
                            mapID = self:GetMap():GetMapID()
                        end
                        if not mapID and WorldMapFrame and WorldMapFrame.GetMap and WorldMapFrame:GetMap() then
                            local map = WorldMapFrame:GetMap()
                            if map and map.GetMapID then mapID = map:GetMapID() end
                        end
                        if not mapID and WorldMapFrame then mapID = WorldMapFrame.mapID or GetWorldMapMapID() end
                        if mapID and A.enabled then
                            if CacheWQDataWQT(mapID) then ScheduleRefresh() end
                        end
                    end)
                end)
            end)
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
            -- World and C_TaskQuest data often aren't ready at login; run layout again so GetNearbyQuestIDs / zone WQ loop can see them.
            C_Timer.After(1.5, function() if A.enabled then ScheduleRefresh() end end)
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
        -- Clear \"recently untracked\" markers on any zone change so untracked WQs can reappear
        -- naturally the next time they are discovered.
        if A.recentlyUntrackedWorldQuests then
            wipe(A.recentlyUntrackedWorldQuests)
        end
        -- Only wipe the world-quest cache when we truly move to a different area (continent/instance),
        -- not when moving between child maps of the same zone. This helps keep WQs from disappearing
        -- when you move between subzones until the map is reopened.
        if event == "ZONE_CHANGED_NEW_AREA" and A.zoneTaskQuestCache then
            wipe(A.zoneTaskQuestCache)
        end
        ScheduleRefresh()
        C_Timer.After(0.4, function() if A.enabled then A.FullLayout() end end)
        -- Zone and C_TaskQuest data can be delayed; run again so zone WQ loop gets data.
        C_Timer.After(1.5, function() if A.enabled then ScheduleRefresh() end end)

    else
        ScheduleRefresh()
    end
end)
