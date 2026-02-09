--[[
    Horizon Suite - Focus - World Quest Tracking
    Quests on map (GetNearbyQuestIDs), world/calling watch list, merge into tracker.
]]

local addon = _G.ModernQuestTracker

-- ============================================================================
-- WORLD QUEST AND QUESTS-ON-MAP LOGIC
-- ============================================================================

local function GetNearbyQuestIDs()
    local nearbySet = {}
    if not C_Map or not C_Map.GetBestMapForUnit or not C_QuestLog.GetQuestsOnMap then return nearbySet end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nearbySet end

    local mapIDsToCheck = { mapID }
    local seen = { [mapID] = true }
    if C_Map.GetMapParentInfo then
        local current = mapID
        for _ = 1, 20 do
            local parentInfo = C_Map.GetMapParentInfo(current)
            if not parentInfo or not parentInfo.parentMapID or parentInfo.parentMapID == 0 then break end
            current = parentInfo.parentMapID
            if not seen[current] then
                seen[current] = true
                mapIDsToCheck[#mapIDsToCheck + 1] = current
            end
        end
    end
    local numMapsAfterParentWalk = #mapIDsToCheck
    if C_Map.GetMapChildrenInfo then
        local children = C_Map.GetMapChildrenInfo(mapID, nil, true)
        if children then
            for _, child in ipairs(children) do
                local childID = child and child.mapID
                if childID and not seen[childID] then
                    seen[childID] = true
                    mapIDsToCheck[#mapIDsToCheck + 1] = childID
                end
            end
        end
        for i = 2, numMapsAfterParentWalk do
            local parentMapID = mapIDsToCheck[i]
            local parentChildren = C_Map.GetMapChildrenInfo(parentMapID, nil, true)
            if parentChildren then
                for _, child in ipairs(parentChildren) do
                    local childID = child and child.mapID
                    if childID and not seen[childID] then
                        seen[childID] = true
                        mapIDsToCheck[#mapIDsToCheck + 1] = childID
                    end
                end
            end
        end
    end

    for _, checkMapID in ipairs(mapIDsToCheck) do
        local onMap = C_QuestLog.GetQuestsOnMap(checkMapID)
        if onMap then
            for _, info in ipairs(onMap) do
                if info.questID then
                    nearbySet[info.questID] = true
                end
            end
        end
        if C_TaskQuest and C_TaskQuest.GetQuestsForPlayerByMapID then
            local taskPOIs = C_TaskQuest.GetQuestsForPlayerByMapID(checkMapID)
            if taskPOIs then
                for _, poi in ipairs(taskPOIs) do
                    if poi.questId then
                        nearbySet[poi.questId] = true
                    end
                end
            end
        end
    end
    return nearbySet
end

-- World quest watch set for map-close diff.
local function GetCurrentWorldQuestWatchSet()
    local set = {}
    if C_QuestLog.GetNumWorldQuestWatches and C_QuestLog.GetQuestIDForWorldQuestWatchIndex then
        for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
            local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
            if questID then set[questID] = true end
        end
    end
    return set
end

-- World/calling entries to show: tracked from watch list, or in-zone from nearbySet (isTracked false).
local function GetWorldAndCallingQuestIDsToShow(nearbySet)
    local out = {}
    local seen = {}
    if C_QuestLog.GetNumWorldQuestWatches and C_QuestLog.GetQuestIDForWorldQuestWatchIndex then
        addon.lastWorldQuestWatchSet = addon.lastWorldQuestWatchSet or {}
        wipe(addon.lastWorldQuestWatchSet)
        local numWorldWatches = C_QuestLog.GetNumWorldQuestWatches()
        for i = 1, numWorldWatches do
            local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
            if questID and not seen[questID] then
                seen[questID] = true
                addon.lastWorldQuestWatchSet[questID] = true
                out[#out + 1] = { questID = questID, isTracked = true }
            end
        end
    end
    if nearbySet and C_QuestLog.IsWorldQuest then
        local recentlyUntracked = addon.recentlyUntrackedWorldQuests
        for questID, _ in pairs(nearbySet) do
            if not seen[questID] and (not recentlyUntracked or not recentlyUntracked[questID]) then
                local isWorld = C_QuestLog.IsWorldQuest(questID)
                local isCalling = C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID)
                if isWorld or isCalling then
                    seen[questID] = true
                    out[#out + 1] = { questID = questID, isTracked = false }
                end
            end
        end
    end
    return out
end

local function RemoveWorldQuestWatch(questID)
    if not questID then return end
    if C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID) and C_QuestLog.RemoveWorldQuestWatch then
        C_QuestLog.RemoveWorldQuestWatch(questID)
    end
end

addon.GetNearbyQuestIDs = GetNearbyQuestIDs
addon.GetWorldAndCallingQuestIDsToShow = GetWorldAndCallingQuestIDsToShow
addon.GetCurrentWorldQuestWatchSet = GetCurrentWorldQuestWatchSet
addon.RemoveWorldQuestWatch = RemoveWorldQuestWatch
