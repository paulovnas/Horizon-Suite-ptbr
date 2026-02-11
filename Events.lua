--[[
    Horizon Suite - Focus - Event Dispatch
    Event frame, ScheduleRefresh, table-dispatch OnEvent, world-map cache and WQ indicator,
    global API for Options. Cache helpers use addon.ParseTaskPOIs (Utilities).
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
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
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

-- Cache task-quest (WQ) IDs for a map using shared ParseTaskPOIs. Returns true if any IDs were added.
local function CacheTaskQuestsForMap(cache, mapID)
    if not mapID or not A.GetTaskQuestsForMap then return false end
    local taskPOIs = A.GetTaskQuestsForMap(mapID, mapID) or A.GetTaskQuestsForMap(mapID)
    if not taskPOIs then return false end
    cache[mapID] = cache[mapID] or {}
    local n = A.ParseTaskPOIs and A.ParseTaskPOIs(taskPOIs, cache[mapID]) or 0
    return n > 0
end

-- When the world map is opened, cache quest IDs from GetQuestsOnMap (map pins) and TaskQuest for displayed + player zone.
local function OnWorldMapShown()
    C_Timer.After(0.5, function()
        if not A.enabled or not WorldMapFrame then return end
        A.zoneTaskQuestCache = A.zoneTaskQuestCache or {}
        local didCache = false
        if WorldMapFrame.mapID then
            if CacheQuestsOnMapForMap(A.zoneTaskQuestCache, WorldMapFrame.mapID) then didCache = true end
            if CacheTaskQuestsForMap(A.zoneTaskQuestCache, WorldMapFrame.mapID) then didCache = true end
        end
        local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
        if playerMapID and playerMapID ~= WorldMapFrame.mapID then
            if CacheQuestsOnMapForMap(A.zoneTaskQuestCache, playerMapID) then didCache = true end
            if CacheTaskQuestsForMap(A.zoneTaskQuestCache, playerMapID) then didCache = true end
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

-- Count quests in cache for a map (for the on-map debug indicator).
local function GetCachedWQCount(mapID)
    if not A.zoneTaskQuestCache or not mapID then return 0 end
    local t = A.zoneTaskQuestCache[mapID]
    if not t then return 0 end
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
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

-- Update the debug indicator on the world map (map + player zone cache counts).
local function UpdateWQMapIndicator(fromDelayed, mapID, playerMapID)
    local f = A.WQMapIndicator
    if not f or not f.text then return end
    mapID = mapID or GetWorldMapMapID()
    playerMapID = playerMapID or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
    local label = fromDelayed and " (0.5s)" or " (now)"
    local mapCount = GetCachedWQCount(mapID)
    local playerCount = playerMapID and GetCachedWQCount(playerMapID) or 0
    local indicatorText = format("HS WQ m%s:%d p%s:%d%s",
        tostring(mapID or "?"), mapCount, tostring(playerMapID or "?"), playerCount, label)
    f.text:SetText(indicatorText)
    if f.shadow then f.shadow:SetText(indicatorText) end
    f:Show()
end

local function ShowWQIndicatorScanning()
    if A.WQMapIndicator and A.WQMapIndicator.text then
        A.WQMapIndicator.text:SetText("HS WQ scanning...")
        if A.WQMapIndicator.shadow then A.WQMapIndicator.shadow:SetText("HS WQ scanning...") end
        A.WQMapIndicator:Show()
    end
end

local function HideWQIndicator()
    if A.WQMapIndicator then A.WQMapIndicator:Hide() end
end

-- Run WQT-style cache for displayed map and player zone; refresh objective list if we got data.
local function RunWQTMapCache(fromDelayed)
    if not WorldMapFrame or not WorldMapFrame:IsVisible() then return end
    A.zoneTaskQuestCache = A.zoneTaskQuestCache or {}
    local mapID = GetWorldMapMapID()
    local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    UpdateWQMapIndicator(fromDelayed, mapID, playerMapID)
    if not A.enabled or not mapID then return end
    local didCache = false
    if CacheTaskQuestsForMap(A.zoneTaskQuestCache, mapID) then didCache = true end
    if playerMapID and playerMapID ~= mapID then
        if CacheTaskQuestsForMap(A.zoneTaskQuestCache, playerMapID) then didCache = true end
    end
    if didCache then ScheduleRefresh() end
    UpdateWQMapIndicator(fromDelayed, mapID, playerMapID)
end

-- Run map cache when world map is visible; no-op when map is closed.
local function RunMapCacheTick(fromDelayed)
    if not WorldMapFrame or not WorldMapFrame:IsVisible() then return end
    RunWQTMapCache(fromDelayed)
end

local function CreateWQMapIndicator()
    local f = CreateFrame("Frame", "HorizonSuiteWQMapIndicator", UIParent, "BackdropTemplate")
    f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 14, 14)
    f:SetSize(246, 20)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(1000)
    f:SetClampedToScreen(true)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.10, 0.10, 0.15, 0.72)
    A.CreateBorder(f, { 0.35, 0.38, 0.45, 0.45 })
    local shadow = f:CreateFontString(nil, "BORDER")
    shadow:SetFontObject(A.SectionFont or GameFontNormalSmall)
    shadow:SetPoint("LEFT", f, "LEFT", 6 + (A.SHADOW_OX or 2), (A.SHADOW_OY or -2))
    shadow:SetJustifyH("LEFT")
    shadow:SetTextColor(0, 0, 0, A.SHADOW_A or 0.8)
    local text = f:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(A.SectionFont or GameFontNormalSmall)
    text:SetPoint("LEFT", f, "LEFT", 6, 0)
    text:SetJustifyH("LEFT")
    text:SetTextColor(0.55, 0.65, 0.75, 1)
    text:SetText("HS WQ")
    shadow:SetText("HS WQ")
    f.shadow = shadow
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
    return f
end

local function HookWorldMapIndicator()
    if not WorldMapFrame or WorldMapFrame._HSIndicatorHooked then return end
    WorldMapFrame._HSIndicatorHooked = true
    WorldMapFrame:HookScript("OnShow", function()
        ShowWQIndicatorScanning()
        C_Timer.After(0.1, function() RunMapCacheTick(false) end)
        C_Timer.After(0.6, function() RunMapCacheTick(true) end)
    end)
    WorldMapFrame:HookScript("OnHide", function()
        HideWQIndicator()
    end)
    if WorldMapFrame:IsVisible() then
        ShowWQIndicatorScanning()
        C_Timer.After(0.1, function() RunMapCacheTick(false) end)
        C_Timer.After(0.6, function() RunMapCacheTick(true) end)
    end
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
            -- Map closed: cache player's current zone (and parent maps) so quests show without opening map.
            local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
            if A.enabled and playerMapID then
                local didCache = false
                if CacheTaskQuestsForMap(A.zoneTaskQuestCache, playerMapID) then didCache = true end
                -- Cache GetQuestsOnMap: city (Zone) = player map only; subzone (Micro/Dungeon) = player map + one parent.
                if A.zoneTaskQuestCache and C_Map and C_Map.GetMapInfo then
                    if CacheQuestsOnMapForMap(A.zoneTaskQuestCache, playerMapID) then didCache = true end
                    local myMapInfo = (C_Map.GetMapInfo and C_Map.GetMapInfo(playerMapID)) or nil
                    local myMapType = myMapInfo and myMapInfo.mapType
                    if myMapType ~= nil and myMapType >= 4 then
                        local parentInfo = (C_Map.GetMapInfo and C_Map.GetMapInfo(playerMapID)) or nil
                        local parentMapID = parentInfo and parentInfo.parentMapID and parentInfo.parentMapID ~= 0 and parentInfo.parentMapID or nil
                        if parentMapID then
                            local parentMapInfo = (C_Map.GetMapInfo and C_Map.GetMapInfo(parentMapID)) or nil
                            local mapType = parentMapInfo and parentMapInfo.mapType
                            if mapType == nil or mapType >= 3 then
                                if CacheQuestsOnMapForMap(A.zoneTaskQuestCache, parentMapID) then didCache = true end
                            end
                        end
                    end
                end
                if didCache then ScheduleRefresh() end
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

-- ============================================================================
-- EVENT HANDLERS (table dispatch)
-- ============================================================================

local function OnAddonLoaded(addonName)
        if addonName == "HorizonSuite" then
            A.RestoreSavedPosition()
            A.ApplyTypography()
            A.ApplyDimensions()
            if A.ApplyBackdropOpacity then A.ApplyBackdropOpacity() end
            if A.ApplyBorderVisibility then A.ApplyBorderVisibility() end
            if HorizonDB and HorizonDB.collapsed then
                A.collapsed = true
                A.chevron:SetText("+")
                A.scrollFrame:Hide()
                A.targetHeight  = A.GetCollapsedHeight()
                A.currentHeight = A.GetCollapsedHeight()
            end
            StartMapCacheHeartbeat()
            CreateWQMapIndicator()
            local function tryHookWorldMap()
                HookWorldMapIndicator()
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
            HookWorldMapIndicator()
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
                            if CacheTaskQuestsForMap(A.zoneTaskQuestCache, mapID) then ScheduleRefresh() end
                        end
                    end)
                end)
                if not ok and A and A.HSPrint then A.HSPrint("WorldQuestDataProviderMixin hook failed: " .. tostring(err)) end
            end)
        elseif addonName == "Blizzard_ObjectiveTracker" then
            if A.enabled then A.TrySuppressTracker() end
        end
end

local function OnPlayerRegenDisabled()
    if A.GetDB("hideInCombat", false) and A.enabled then
        local useAnim = A.GetDB("animations", true)
        if useAnim and A.MQT:IsShown() then
            A.combatFadeState = "out"
            A.combatFadeTime  = 0
        else
            A.MQT:Hide()
            if A.UpdateFloatingQuestItem then A.UpdateFloatingQuestItem(nil) end
            if A.UpdateMplusBlock then A.UpdateMplusBlock() end
        end
    end
end

local function OnPlayerRegenEnabled()
    if A.layoutPendingAfterCombat then
        A.layoutPendingAfterCombat = nil
        if A.GetDB("hideInCombat", false) and A.enabled then
            A.combatFadeState = "in"
            A.combatFadeTime  = 0
        end
        A.FullLayout()
    elseif A.GetDB("hideInCombat", false) and A.enabled then
        A.combatFadeState = "in"
        A.combatFadeTime  = 0
        ScheduleRefresh()
    end
end

local function OnPlayerLoginOrEnteringWorld()
    if A.enabled then
        A.zoneJustChanged = true
        A.TrySuppressTracker()
        ScheduleRefresh()
        C_Timer.After(0.4, function() if A.enabled then A.FullLayout() end end)
        C_Timer.After(1.5, function() if A.enabled then ScheduleRefresh() end end)
    end
end

local function OnQuestTurnedIn(questID)
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
end

local function OnQuestWatchUpdate(questID)
    if questID and A.GetDB("objectiveProgressFlash", true) then
        for i = 1, A.POOL_SIZE do
            if A.pool[i].questID == questID then
                A.pool[i].flashTime = A.FLASH_DUR
            end
        end
    end
    ScheduleRefresh()
end

local function OnQuestWatchListChanged(questID, added)
    if questID and A.IsQuestWorldQuest and A.IsQuestWorldQuest(questID) then
        if not A.recentlyUntrackedWorldQuests then A.recentlyUntrackedWorldQuests = {} end
        if added then
            A.recentlyUntrackedWorldQuests[questID] = nil
        else
            A.recentlyUntrackedWorldQuests[questID] = true
        end
    end
    ScheduleRefresh()
end

local function OnZoneChanged(event)
    A.zoneJustChanged = true
    if A.recentlyUntrackedWorldQuests then wipe(A.recentlyUntrackedWorldQuests) end
    if event == "ZONE_CHANGED_NEW_AREA" and A.zoneTaskQuestCache then
        wipe(A.zoneTaskQuestCache)
    end
    ScheduleRefresh()
    C_Timer.After(0.4, function() if A.enabled then A.FullLayout() end end)
    C_Timer.After(1.5, function() if A.enabled then ScheduleRefresh() end end)
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
    ZONE_CHANGED             = function(_, evt) OnZoneChanged(evt) end,
    ZONE_CHANGED_NEW_AREA    = function(_, evt) OnZoneChanged(evt) end,
}

eventFrame:SetScript("OnEvent", function(self, event, ...)
    local fn = eventHandlers[event]
    if fn then
        fn(event, ...)
    else
        ScheduleRefresh()
    end
end)
