--[[
    Horizon Suite - Focus - Event Dispatch
    Event frame, ScheduleRefresh, table-dispatch OnEvent, world-map cache and WQ indicator,
    global API for Options. Cache helpers use addon.ParseTaskPOIs (Utilities).
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
    if not mapID or not addon.GetTaskQuestsForMap then return false end
    local taskPOIs = addon.GetTaskQuestsForMap(mapID, mapID) or addon.GetTaskQuestsForMap(mapID)
    if not taskPOIs then return false end
    cache[mapID] = cache[mapID] or {}
    local n = addon.ParseTaskPOIs and addon.ParseTaskPOIs(taskPOIs, cache[mapID]) or 0
    return n > 0
end

-- When the world map is opened, cache quest IDs from GetQuestsOnMap (map pins) and TaskQuest for displayed + player zone.
local function OnWorldMapShown()
    C_Timer.After(0.5, function()
        if not addon.enabled or not WorldMapFrame then return end
        addon.zoneTaskQuestCache = addon.zoneTaskQuestCache or {}
        local didCache = false
        if WorldMapFrame.mapID then
            if CacheQuestsOnMapForMap(addon.zoneTaskQuestCache, WorldMapFrame.mapID) then didCache = true end
            if CacheTaskQuestsForMap(addon.zoneTaskQuestCache, WorldMapFrame.mapID) then didCache = true end
        end
        local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
        if playerMapID and playerMapID ~= WorldMapFrame.mapID then
            if CacheQuestsOnMapForMap(addon.zoneTaskQuestCache, playerMapID) then didCache = true end
            if CacheTaskQuestsForMap(addon.zoneTaskQuestCache, playerMapID) then didCache = true end
        end
        if didCache then ScheduleRefresh() end
    end)
end

local function HookWorldMapOnShow()
    if WorldMapFrame and not WorldMapFrame._HSOnShowHooked then
        WorldMapFrame._HSOnShowHooked = true
        WorldMapFrame:HookScript("OnShow", OnWorldMapShown)
    end
end

-- Count quests in cache for a map (for the on-map debug indicator).
local function GetCachedWQCount(mapID)
    if not addon.zoneTaskQuestCache or not mapID then return 0 end
    local t = addon.zoneTaskQuestCache[mapID]
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
    local f = addon.WQMapIndicator
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
    if addon.WQMapIndicator and addon.WQMapIndicator.text then
        addon.WQMapIndicator.text:SetText("HS WQ scanning...")
        if addon.WQMapIndicator.shadow then addon.WQMapIndicator.shadow:SetText("HS WQ scanning...") end
        addon.WQMapIndicator:Show()
    end
end

local function HideWQIndicator()
    if addon.WQMapIndicator then addon.WQMapIndicator:Hide() end
end

-- Run WQT-style cache for displayed map and player zone; refresh objective list if we got data.
local function RunWQTMapCache(fromDelayed)
    if not WorldMapFrame or not WorldMapFrame:IsVisible() then return end
    addon.zoneTaskQuestCache = addon.zoneTaskQuestCache or {}
    local mapID = GetWorldMapMapID()
    local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    UpdateWQMapIndicator(fromDelayed, mapID, playerMapID)
    if not addon.enabled or not mapID then return end
    local didCache = false
    if CacheTaskQuestsForMap(addon.zoneTaskQuestCache, mapID) then didCache = true end
    if playerMapID and playerMapID ~= mapID then
        if CacheTaskQuestsForMap(addon.zoneTaskQuestCache, playerMapID) then didCache = true end
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
    addon.CreateBorder(f, { 0.35, 0.38, 0.45, 0.45 })
    local shadow = f:CreateFontString(nil, "BORDER")
    shadow:SetFontObject(addon.SectionFont or GameFontNormalSmall)
    shadow:SetPoint("LEFT", f, "LEFT", 6 + (addon.SHADOW_OX or 2), (addon.SHADOW_OY or -2))
    shadow:SetJustifyH("LEFT")
    shadow:SetTextColor(0, 0, 0, addon.SHADOW_A or 0.8)
    local text = f:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(addon.SectionFont or GameFontNormalSmall)
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
    addon.WQMapIndicator = f
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
    if addon._mapCacheHeartbeat then return end
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
            if addon.enabled and playerMapID then
                local didCache = false
                if CacheTaskQuestsForMap(addon.zoneTaskQuestCache, playerMapID) then didCache = true end
                -- Cache GetQuestsOnMap: city (Zone) = player map only; subzone (Micro/Dungeon) = player map + one parent.
                if addon.zoneTaskQuestCache and C_Map and C_Map.GetMapInfo then
                    if CacheQuestsOnMapForMap(addon.zoneTaskQuestCache, playerMapID) then didCache = true end
                    local myMapInfo = (C_Map.GetMapInfo and C_Map.GetMapInfo(playerMapID)) or nil
                    local myMapType = myMapInfo and myMapInfo.mapType
                    if myMapType ~= nil and myMapType >= 4 then
                        local parentInfo = (C_Map.GetMapInfo and C_Map.GetMapInfo(playerMapID)) or nil
                        local parentMapID = parentInfo and parentInfo.parentMapID and parentInfo.parentMapID ~= 0 and parentInfo.parentMapID or nil
                        if parentMapID then
                            local parentMapInfo = (C_Map.GetMapInfo and C_Map.GetMapInfo(parentMapID)) or nil
                            local mapType = parentMapInfo and parentMapInfo.mapType
                            if mapType == nil or mapType >= 3 then
                                if CacheQuestsOnMapForMap(addon.zoneTaskQuestCache, parentMapID) then didCache = true end
                            end
                        end
                    end
                end
                if didCache then ScheduleRefresh() end
            end
        end
    end)
    addon._mapCacheHeartbeat = f
end

-- Mirror WQT: OnMapChanged runs immediately, then 0.5s delayed (like WQT's check_for_quests_on_unknown_map).
local function OnMapChanged()
    RunWQTMapCache(false)
    C_Timer.After(0.5, function()
        if WorldMapFrame and WorldMapFrame:IsVisible() then RunWQTMapCache(true) end
    end)
end

local function HookWorldMapOnMapChanged()
    if WorldMapFrame and not WorldMapFrame._HSOnMapChangedHooked then
        WorldMapFrame._HSOnMapChangedHooked = true
        hooksecurefunc(WorldMapFrame, "OnMapChanged", OnMapChanged)
    end
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
                    if not (WorldQuestDataProviderMixin and WorldQuestDataProviderMixin.RefreshAllData and A and addon.zoneTaskQuestCache) then return end
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
                        if mapID and addon.enabled then
                            if CacheTaskQuestsForMap(addon.zoneTaskQuestCache, mapID) then ScheduleRefresh() end
                        end
                    end)
                end)
                if not ok and A and addon.HSPrint then addon.HSPrint("WorldQuestDataProviderMixin hook failed: " .. tostring(err)) end
            end)
        elseif addonName == "Blizzard_ObjectiveTracker" then
            if addon.enabled then addon.TrySuppressTracker() end
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
    if addon.recentlyUntrackedWorldQuests then wipe(addon.recentlyUntrackedWorldQuests) end
    if event == "ZONE_CHANGED_NEW_AREA" and addon.zoneTaskQuestCache then
        wipe(addon.zoneTaskQuestCache)
    end
    ScheduleRefresh()
    C_Timer.After(0.4, function() if addon.enabled then addon.FullLayout() end end)
    C_Timer.After(1.5, function() if addon.enabled then ScheduleRefresh() end end)
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
