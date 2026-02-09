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
    local taskQuestOnlySet = {}
    if not C_Map or not C_Map.GetBestMapForUnit or not C_QuestLog.GetQuestsOnMap then return nearbySet, taskQuestOnlySet end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nearbySet, taskQuestOnlySet end

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
            local taskPOIs = C_TaskQuest.GetQuestsForPlayerByMapID(checkMapID, checkMapID) or C_TaskQuest.GetQuestsForPlayerByMapID(checkMapID)
            if taskPOIs then
                if #taskPOIs > 0 then
                    for _, poi in ipairs(taskPOIs) do
                        local id = (type(poi) == "table" and (poi.questID or poi.questId)) or (type(poi) == "number" and poi)
                        if id then
                            nearbySet[id] = true
                            taskQuestOnlySet[id] = true
                        end
                    end
                end
                for k, v in pairs(taskPOIs) do
                    if type(k) == "number" and k > 0 then
                        nearbySet[k] = true
                        taskQuestOnlySet[k] = true
                    elseif type(v) == "table" then
                        local id = v.questID or v.questId
                        if id then
                            nearbySet[id] = true
                            taskQuestOnlySet[id] = true
                        end
                    end
                end
            end
        end
    end

    -- Use cached zone WQ IDs (from map open or heartbeat) for player map and all checked maps.
    if addon.zoneTaskQuestCache then
        for _, checkMapID in ipairs(mapIDsToCheck) do
            local cached = addon.zoneTaskQuestCache[checkMapID]
            if cached then
                for id, _ in pairs(cached) do
                    if id then
                        nearbySet[id] = true
                        taskQuestOnlySet[id] = true
                    end
                end
            end
        end
    end
    return nearbySet, taskQuestOnlySet
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

-- Returns watch-list WQs plus in-zone *active* world quests/callings so they appear in the objective list.
-- Filter out deprecated/expired WQs: only show if on watch list, or calling, or (world/task and currently active or in quest log).
local function GetWorldAndCallingQuestIDsToShow(nearbySet, taskQuestOnlySet)
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
        local ids = {}
        for questID, _ in pairs(nearbySet) do
            if not seen[questID] and (not recentlyUntracked or not recentlyUntracked[questID]) then
                local isWorld = C_QuestLog.IsWorldQuest(questID)
                local isCalling = C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID)
                local isActiveTask = C_TaskQuest and C_TaskQuest.IsActive and C_TaskQuest.IsActive(questID)
                local fromTaskQuestMap = taskQuestOnlySet and taskQuestOnlySet[questID]
                local inLog = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID)
                -- Callings: always include. World/task: only if currently active or in quest log (avoids deprecated/expired WQs).
                if isCalling then
                    ids[#ids + 1] = questID
                elseif isActiveTask then
                    ids[#ids + 1] = questID
                elseif isWorld and (inLog or isActiveTask) then
                    ids[#ids + 1] = questID
                elseif fromTaskQuestMap and isActiveTask then
                    ids[#ids + 1] = questID
                end
            end
        end
        table.sort(ids)
        for _, questID in ipairs(ids) do
            seen[questID] = true
            if C_TaskQuest and C_TaskQuest.RequestPreloadRewardData then
                C_TaskQuest.RequestPreloadRewardData(questID)
            end
            local isWorld = C_QuestLog.IsWorldQuest(questID)
            local isCalling = C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID)
            local fromTaskQuestMap = taskQuestOnlySet and taskQuestOnlySet[questID]
            local isImportant = C_QuestLog.IsImportantQuest and C_QuestLog.IsImportantQuest(questID)
            local forceCategory = (fromTaskQuestMap and not isWorld and not isCalling and not isImportant) and "WORLD" or nil
            out[#out + 1] = { questID = questID, isTracked = false, forceCategory = forceCategory }
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

addon.zoneTaskQuestCache = addon.zoneTaskQuestCache or {}
addon.GetNearbyQuestIDs = GetNearbyQuestIDs
addon.GetWorldAndCallingQuestIDsToShow = GetWorldAndCallingQuestIDsToShow
addon.GetCurrentWorldQuestWatchSet = GetCurrentWorldQuestWatchSet
addon.RemoveWorldQuestWatch = RemoveWorldQuestWatch
