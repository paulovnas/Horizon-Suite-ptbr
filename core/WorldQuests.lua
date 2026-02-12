--[[
    Horizon Suite - Focus - World Quest Tracking
    Quests on map (GetNearbyQuestIDs), world/calling watch list, merge into tracker.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- WORLD QUEST AND QUESTS-ON-MAP LOGIC
-- ============================================================================

--- Build sets of quest IDs visible on the player's current map(s) and from task/WQ APIs.
-- @return table nearbySet Set of questID -> true for quests on player map or parent/children
-- @return table taskQuestOnlySet Set of questID -> true for quests coming only from task/WQ map APIs
local function GetNearbyQuestIDs()
    local nearbySet = {}
    local taskQuestOnlySet = {}
    if not C_Map or not C_Map.GetBestMapForUnit or not C_QuestLog.GetQuestsOnMap then return nearbySet, taskQuestOnlySet end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nearbySet, taskQuestOnlySet end

    local myMapInfo = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID) or nil
    local myMapType = myMapInfo and myMapInfo.mapType
    -- Continent (2) or World (1): API returned too broad a map (e.g. Khaz Algar when in Isle of Dorn).
    -- Only use Zone (3) or more specific so we never show "Current Zone" for the whole continent/world.
    if myMapType ~= nil and myMapType < 3 then
        return nearbySet, taskQuestOnlySet
    end

    -- In a city (Zone type): only that map. In a subzone (Micro/Dungeon): that map + one parent so we see the city's quests (e.g. Foundation Hall + Dornogal).
    local mapIDsToCheck = { mapID }
    local seen = { [mapID] = true }
    if C_Map.GetMapInfo and myMapType ~= nil and myMapType >= 4 then
        local parentInfo = (C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)) or nil
        local parentMapID = parentInfo and parentInfo.parentMapID and parentInfo.parentMapID ~= 0 and parentInfo.parentMapID or nil
        if parentMapID then
            local parentMapInfo = (C_Map.GetMapInfo and C_Map.GetMapInfo(parentMapID)) or nil
            local mapType = parentMapInfo and parentMapInfo.mapType
            if mapType == nil or mapType >= 3 then
                if not seen[parentMapID] then
                    seen[parentMapID] = true
                    mapIDsToCheck[#mapIDsToCheck + 1] = parentMapID
                end
            end
        end
    end
    -- Only add children when player's map is Micro (5) or Dungeon (4); never when in a Zone (city).
    if C_Map.GetMapChildrenInfo and myMapType ~= nil and myMapType >= 4 then
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
        if addon.GetTaskQuestsForMap then
            local taskPOIs = addon.GetTaskQuestsForMap(checkMapID, checkMapID) or addon.GetTaskQuestsForMap(checkMapID)
            if taskPOIs then
                addon.ParseTaskPOIs(taskPOIs, nearbySet)
                addon.ParseTaskPOIs(taskPOIs, taskQuestOnlySet)
            end
        end
    end

    -- Waypoint-based fallback: only when next waypoint is on the player's exact map (not parent), so we don't pull in quests from other zones that share a hub.
    if C_QuestLog.GetNextWaypoint then
        local questIDsToCheck = {}
        if C_QuestLog.GetNumQuestWatches and C_QuestLog.GetQuestIDForQuestWatchIndex then
            for i = 1, C_QuestLog.GetNumQuestWatches() do
                local qid = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
                if qid then questIDsToCheck[qid] = true end
            end
        end
        if C_QuestLog.GetNumQuestLogEntries then
            for i = 1, C_QuestLog.GetNumQuestLogEntries() do
                local info = C_QuestLog.GetInfo(i)
                if info and not info.isHeader and info.questID then
                    questIDsToCheck[info.questID] = true
                end
            end
        end
        for questID, _ in pairs(questIDsToCheck) do
            if not nearbySet[questID] then
                local waypointMapID = C_QuestLog.GetNextWaypoint(questID)
                if waypointMapID == mapID then
                    nearbySet[questID] = true
                end
            end
        end
    end

    -- Use cached zone WQ IDs only for the player's exact map (not parent) to avoid stale or overly-broad data.
    if addon.zoneTaskQuestCache then
        local cached = addon.zoneTaskQuestCache[mapID]
        if cached then
            for id, _ in pairs(cached) do
                if id then
                    nearbySet[id] = true
                    taskQuestOnlySet[id] = true
                end
            end
        end
    end

    -- Post-filter: keep only quests we can verify are on one of our checked maps.
    -- Removes: (1) quests whose zone is known and not in our list, (2) quests whose zone we cannot
    -- determine, (3) quests whose zone name doesn't match (catches same-continent other zones).
    local validMapIDs = {}
    local validZoneNames = {}
    for _, id in ipairs(mapIDsToCheck) do
        validMapIDs[id] = true
        local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
        if info and info.name and info.name ~= "" then
            validZoneNames[string.lower(strtrim(info.name))] = true
        end
    end
    for questID in pairs(nearbySet) do
        local questMapID = nil
        if C_TaskQuest and C_TaskQuest.GetQuestInfoByQuestID then
            local info = C_TaskQuest.GetQuestInfoByQuestID(questID)
            questMapID = info and (info.mapID or info.uiMapID)
        end
        if not questMapID and C_QuestLog.GetNextWaypoint then
            questMapID = C_QuestLog.GetNextWaypoint(questID)
        end
        if not questMapID or not validMapIDs[questMapID] then
            nearbySet[questID] = nil
            taskQuestOnlySet[questID] = nil
        else
            -- Zone-name check: if the quest's zone name is known and doesn't match our maps, remove it
            -- (e.g. quest from Azj-Kahet showing up when we're in Isle of Dorn).
            if addon.GetQuestZoneName then
                local questZone = addon.GetQuestZoneName(questID)
                if questZone and questZone ~= "" then
                    local key = string.lower(strtrim(questZone))
                    if not validZoneNames[key] then
                        nearbySet[questID] = nil
                        taskQuestOnlySet[questID] = nil
                    end
                end
            end
            -- Quest-log header cross-check: for quests in the log, verify their
            -- header zone matches our maps.  Catches quests from another zone that
            -- merely have a waypoint/objective in the current zone (e.g. Twilight
            -- Highlands quest with a turn-in in Isle of Dorn).
            if nearbySet[questID] and C_QuestLog.GetLogIndexForQuestID then
                local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
                if logIndex then
                    for i = logIndex - 1, 1, -1 do
                        local lInfo = C_QuestLog.GetInfo(i)
                        if lInfo and lInfo.isHeader then
                            local headerKey = string.lower(strtrim(lInfo.title or ""))
                            if headerKey ~= "" and not validZoneNames[headerKey] then
                                nearbySet[questID] = nil
                                taskQuestOnlySet[questID] = nil
                            end
                            break
                        end
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
    if nearbySet and (addon.IsQuestWorldQuest or C_QuestLog.IsWorldQuest) then
        local recentlyUntracked = addon.recentlyUntrackedWorldQuests
        local ids = {}
        for questID, _ in pairs(nearbySet) do
            if not seen[questID] and (not recentlyUntracked or not recentlyUntracked[questID]) then
                local isWorld = addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID) or (C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID))
                local isCalling = C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID)
                local isActiveTask = C_TaskQuest and C_TaskQuest.IsActive and C_TaskQuest.IsActive(questID)
                local fromTaskQuestMap = taskQuestOnlySet and taskQuestOnlySet[questID]
                local inLog = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID)
                local qc = C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification and C_QuestInfoSystem.GetQuestClassification(questID)
                local isCampaign = (qc == Enum.QuestClassification.Campaign)
                local isRecurring = (qc == Enum.QuestClassification.Recurring)
                -- Only add actual World Quests or Callings to the WORLD list (no IsActive/fromTaskQuestMap-only).
                if isCampaign or isRecurring then
                    if isCalling then ids[#ids + 1] = questID end
                elseif isCalling then
                    ids[#ids + 1] = questID
                elseif isWorld and (inLog or isActiveTask) then
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
            local isWorld = addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID) or (C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID))
            local isCalling = C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID)
            local fromTaskQuestMap = taskQuestOnlySet and taskQuestOnlySet[questID]
            local qc = C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification and C_QuestInfoSystem.GetQuestClassification(questID)
            local isCampaign = (qc == Enum.QuestClassification.Campaign)
            local isRecurring = (qc == Enum.QuestClassification.Recurring)
            -- Only force WORLD for task-map quests that are not already world/calling/campaign/recurring (should not happen now we only add WQ/Calling).
            local forceCategory = (fromTaskQuestMap and not isWorld and not isCalling and not isCampaign and not isRecurring) and "WORLD" or nil
            out[#out + 1] = { questID = questID, isTracked = false, forceCategory = forceCategory }
        end
    end
    return out
end

-- Returns weeklies and dailies that appear in the zone (nearbySet). Used to auto-add them to the tracker like world quests.
-- Each returned entry has questID and forceCategory ("WEEKLY" or "DAILY"). Quests not yet accepted are "available to collect".
local function GetWeekliesAndDailiesInZone(nearbySet)
    local out = {}
    if not nearbySet or not C_QuestInfoSystem or not C_QuestInfoSystem.GetQuestClassification then return out end
    local ids = {}
    for questID, _ in pairs(nearbySet) do
        if addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID) then
            -- Skip world quests; they are handled by GetWorldAndCallingQuestIDsToShow.
        elseif C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID) then
            -- Skip callings.
        else
            local qc = C_QuestInfoSystem.GetQuestClassification(questID)
            local isRecurring = (qc == Enum.QuestClassification.Recurring)
            local freq = addon.GetQuestFrequency and addon.GetQuestFrequency(questID)
            local isWeekly = isRecurring
                or (freq ~= nil and (freq == 2 or (LE_QUEST_FREQUENCY_WEEKLY and freq == LE_QUEST_FREQUENCY_WEEKLY)))
                or (freq ~= nil and Enum.QuestFrequency and Enum.QuestFrequency.Weekly and freq == Enum.QuestFrequency.Weekly)
            local isDaily = (freq ~= nil and (freq == 1 or (LE_QUEST_FREQUENCY_DAILY and freq == LE_QUEST_FREQUENCY_DAILY)))
                or (freq ~= nil and Enum.QuestFrequency and Enum.QuestFrequency.Daily and freq == Enum.QuestFrequency.Daily)
            if isWeekly then
                ids[#ids + 1] = { questID = questID, forceCategory = "WEEKLY" }
            elseif isDaily then
                ids[#ids + 1] = { questID = questID, forceCategory = "DAILY" }
            end
        end
    end
    table.sort(ids, function(a, b) return a.questID < b.questID end)
    for _, e in ipairs(ids) do
        out[#out + 1] = e
    end
    return out
end

local function RemoveWorldQuestWatch(questID)
    if not questID then return end
    if (addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID)) and C_QuestLog.RemoveWorldQuestWatch then
        C_QuestLog.RemoveWorldQuestWatch(questID)
    end
end

--- Return a table of strings describing current "Nearby" zone state for /horizon nearbydebug.
local MAP_TYPE_NAMES = { [0] = "Cosmic", [1] = "World", [2] = "Continent", [3] = "Zone", [4] = "Dungeon", [5] = "Micro", [6] = "Orphan" }
function addon.GetNearbyDebugInfo()
    local out = {}
    if not C_Map or not C_Map.GetBestMapForUnit then
        out[#out + 1] = "C_Map.GetBestMapForUnit unavailable"
        return out
    end
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        out[#out + 1] = "GetBestMapForUnit returned nil"
        return out
    end
    local myMapInfo = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID) or nil
    local myMapType = myMapInfo and myMapInfo.mapType
    local typeName = (myMapType ~= nil and MAP_TYPE_NAMES[myMapType]) or tostring(myMapType)
    local zoneName = (myMapInfo and myMapInfo.name) or ("map " .. tostring(mapID))
    out[#out + 1] = ("Player map: %s (%s) type=%s (%s)"):format(tostring(mapID), zoneName, tostring(myMapType), typeName)
    if myMapType ~= nil and myMapType < 3 then
        out[#out + 1] = "Nearby: skipped (continent/world - mapType < 3)"
        out[#out + 1] = "nearbySet count: 0"
        return out
    end
    local mapIDsToCheck = { mapID }
    local seen = { [mapID] = true }
    if C_Map.GetMapInfo and myMapType ~= nil and myMapType >= 4 then
        local parentInfo = C_Map.GetMapInfo(mapID)
        local parentMapID = parentInfo and parentInfo.parentMapID and parentInfo.parentMapID ~= 0 and parentInfo.parentMapID or nil
        if parentMapID then
            local parentMapInfo = C_Map.GetMapInfo(parentMapID)
            local pt = parentMapInfo and parentMapInfo.mapType
            if pt == nil or pt >= 3 then
                if not seen[parentMapID] then
                    seen[parentMapID] = true
                    mapIDsToCheck[#mapIDsToCheck + 1] = parentMapID
                end
            end
        end
    end
    if C_Map.GetMapChildrenInfo and myMapType ~= nil and myMapType >= 4 then
        local children = C_Map.GetMapChildrenInfo(mapID, nil, true)
        if children then
            for _, child in ipairs(children) do
                local cid = child and child.mapID
                if cid and not seen[cid] then
                    seen[cid] = true
                    mapIDsToCheck[#mapIDsToCheck + 1] = cid
                end
            end
        end
    end
    local mapLines = {}
    for _, mid in ipairs(mapIDsToCheck) do
        local info = C_Map.GetMapInfo(mid)
        local name = (info and info.name) or ("map " .. tostring(mid))
        mapLines[#mapLines + 1] = ("%s (%s)"):format(tostring(mid), name)
    end
    out[#out + 1] = "Maps checked: " .. table.concat(mapLines, ", ")
    local nearbySet, taskQuestOnlySet = addon.GetNearbyQuestIDs()
    local n = 0
    for _ in pairs(nearbySet) do n = n + 1 end
    out[#out + 1] = ("nearbySet count: %d"):format(n)
    local maxShow = 8
    local shown = 0
    for questID in pairs(nearbySet) do
        if shown < maxShow then
            local title = (C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)) or ("quest " .. tostring(questID))
            if #title > 40 then title = title:sub(1, 37) .. "..." end
            local headerZone = ""
            if C_QuestLog.GetLogIndexForQuestID then
                local li = C_QuestLog.GetLogIndexForQuestID(questID)
                if li then
                    for j = li - 1, 1, -1 do
                        local lInfo = C_QuestLog.GetInfo(j)
                        if lInfo and lInfo.isHeader then
                            headerZone = " [" .. (lInfo.title or "?") .. "]"
                            break
                        end
                    end
                end
            end
            out[#out + 1] = ("  [%d] %s%s"):format(questID, title, headerZone)
            shown = shown + 1
        else
            break
        end
    end
    if n > maxShow then
        out[#out + 1] = ("  ... and %d more"):format(n - maxShow)
    end
    return out
end

addon.zoneTaskQuestCache = addon.zoneTaskQuestCache or {}
addon.GetNearbyQuestIDs = GetNearbyQuestIDs
addon.GetWorldAndCallingQuestIDsToShow = GetWorldAndCallingQuestIDsToShow
addon.GetWeekliesAndDailiesInZone = GetWeekliesAndDailiesInZone
addon.GetCurrentWorldQuestWatchSet = GetCurrentWorldQuestWatchSet
addon.RemoveWorldQuestWatch = RemoveWorldQuestWatch
