--[[
    Horizon Suite - Focus - Quest Data
    State, quest/rare/zone helpers, ReadTrackedQuests, SortAndGroupQuests.
]]

local addon = _G.ModernQuestTracker

-- ============================================================================
-- QUEST DATA
-- ============================================================================

addon.enabled            = true
addon.collapsed          = false
addon.refreshPending     = false
addon.prevRareKeys       = {}
addon.rareTrackingInit   = false
addon.zoneJustChanged    = false
addon.collapseAnimating  = false  -- panel-wide collapse
addon.collapseAnimStart  = 0
addon.groupCollapses     = {}     -- per-group collapses: [groupKey] = startTime
addon.lastPlayerMapID    = nil
addon.lastMapCheckTime   = 0

local function GetQuestCategory(questID)
    if C_QuestLog.IsComplete(questID) then
        return "COMPLETE"
    end
    if C_QuestLog.IsLegendaryQuest and C_QuestLog.IsLegendaryQuest(questID) then
        return "LEGENDARY"
    end
    if C_QuestLog.IsImportantQuest and C_QuestLog.IsImportantQuest(questID) then
        return "IMPORTANT"
    end
    if C_TaskQuest and C_TaskQuest.IsActive and C_TaskQuest.IsActive(questID) then
        return "WORLD"
    end
    if C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID) then
        return "WORLD"
    end
    if C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID) then
        return "CALLING"
    end
    if C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification then
        local qc = C_QuestInfoSystem.GetQuestClassification(questID)
        if qc == Enum.QuestClassification.Campaign then
            return "CAMPAIGN"
        end
    end
    return "DEFAULT"
end

local function GetQuestColor(category)
    local db = HorizonSuiteDB and HorizonSuiteDB.questColors
    if db then
        if db[category] then return db[category] end
        if category == "IMPORTANT" and db.CAMPAIGN then return db.CAMPAIGN end
        if category == "CALLING" and db.WORLD then return db.WORLD end
    end
    return addon.QUEST_COLORS[category] or addon.QUEST_COLORS.DEFAULT
end

local function GetSectionColor(groupKey)
    if HorizonSuiteDB and HorizonSuiteDB.sectionColors and HorizonSuiteDB.sectionColors[groupKey] then
        return HorizonSuiteDB.sectionColors[groupKey]
    end
    local questCategory = (groupKey == "RARES") and "RARE" or groupKey
    if questCategory == "CAMPAIGN" or questCategory == "LEGENDARY" or questCategory == "WORLD" or questCategory == "COMPLETE" or questCategory == "RARE" or questCategory == "DEFAULT" then
        return GetQuestColor(questCategory)
    end
    return addon.SECTION_COLORS[groupKey] or addon.SECTION_COLORS.DEFAULT
end

local function GetQuestTypeAtlas(questID, category)
    if not questID or questID <= 0 then return nil end
    if C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(questID) then
        return "QuestTurnin"
    end
    if C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification then
        local qc = C_QuestInfoSystem.GetQuestClassification(questID)
        if qc then
            local atlas = (qc == Enum.QuestClassification.Important and "importantavailablequesticon")
                or (qc == Enum.QuestClassification.Campaign and "Quest-Campaign-Available")
                or (qc == Enum.QuestClassification.Legendary and "UI-QuestPoiLegendary-QuestBang")
                or (qc == Enum.QuestClassification.Calling and "Quest-DailyCampaign-Available")
                or (qc == Enum.QuestClassification.Recurring and "quest-recurring-available")
                or (qc == Enum.QuestClassification.Meta and "quest-wrapper-available")
            if atlas then return atlas end
        end
    end
    if category == "COMPLETE" then return "QuestTurnin" end
    if category == "IMPORTANT" then return "importantavailablequesticon" end
    if category == "CAMPAIGN" then return "Quest-Campaign-Available" end
    if category == "LEGENDARY" then return "UI-QuestPoiLegendary-QuestBang" end
    if category == "CALLING" then return "Quest-DailyCampaign-Available" end
    if category == "WORLD" then return "quest-recurring-available" end
    if C_QuestLog.GetQuestTagInfo then
        local tagInfo = C_QuestLog.GetQuestTagInfo(questID)
        if tagInfo and tagInfo.tagID then
            local tagAtlas = (tagInfo.tagID == 41 and "questlog-questtypeicon-pvp")
                or (tagInfo.tagID == 81 and "questlog-questtypeicon-dungeon")
                or (tagInfo.tagID == 62 and "questlog-questtypeicon-raid")
                or (tagInfo.tagID == 1 and "questlog-questtypeicon-group")
            if tagAtlas then return tagAtlas end
        end
    end
    return "QuestNormal"
end

local function GetQuestZoneName(questID)
    -- For world quests / task quests, prefer the task-quest APIs which usually carry a uiMapID.
    if C_TaskQuest and C_TaskQuest.GetQuestInfoByQuestID then
        local info = C_TaskQuest.GetQuestInfoByQuestID(questID)
        local mapID = info and (info.mapID or info.uiMapID)
        if mapID and C_Map and C_Map.GetMapInfo then
            local mapInfo = C_Map.GetMapInfo(mapID)
            if mapInfo and mapInfo.name then
                return mapInfo.name
            end
        end
    end
    if C_QuestLog.GetNextWaypoint then
        local mapID = C_QuestLog.GetNextWaypoint(questID)
        if mapID and C_Map and C_Map.GetMapInfo then
            local mapInfo = C_Map.GetMapInfo(mapID)
            if mapInfo and mapInfo.name then
                return mapInfo.name
            end
        end
    end
    if C_QuestLog.GetLogIndexForQuestID then
        local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
        if logIndex then
            for i = logIndex - 1, 1, -1 do
                local info = C_QuestLog.GetInfo(i)
                if info and info.isHeader then
                    return info.title
                end
            end
        end
    end
    return nil
end

local function IsInMythicDungeon()
    local _, instanceType, difficultyID = GetInstanceInfo()
    return instanceType == "party" and (difficultyID == 8 or difficultyID == 23)
end

local function GetMythicDungeonName()
    local name = GetInstanceInfo()
    return name or nil
end

local function ReadTrackedQuests()
    -- Allow test data injection from Slash.lua for /horizon test.
    if addon.testQuests then
        return addon.testQuests
    end

    local quests = {}
    local seen = {}
    local numWatches = C_QuestLog.GetNumQuestWatches()
    local superTracked = (C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID) and C_SuperTrack.GetSuperTrackedQuestID() or 0
    local nearbySet, taskQuestOnlySet = addon.GetNearbyQuestIDs()

    local function addQuest(questID, opts)
        opts = opts or {}
        if not questID or questID <= 0 or seen[questID] then return end
        seen[questID] = true
        local category   = opts.forceCategory or GetQuestCategory(questID)
        local title      = C_QuestLog.GetTitleForQuestID(questID) or "..."
        local objectives = C_QuestLog.GetQuestObjectives(questID) or {}
        local color      = GetQuestColor(category)
        local isComplete = C_QuestLog.IsComplete(questID)
        local isSuper    = (questID == superTracked)
        local isNearby   = nearbySet[questID] or false
        local zoneName   = GetQuestZoneName(questID)
        local isDungeonQuest = opts.isDungeonQuest or (IsInMythicDungeon() and isNearby)
        local isTracked  = opts.isTracked ~= false

        local itemLink, itemTexture
        local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
        local isAccepted = (logIndex ~= nil)
        if logIndex and GetQuestLogSpecialItemInfo then
            local link, tex = GetQuestLogSpecialItemInfo(logIndex)
            if tex then
                itemLink    = link
                itemTexture = tex
            end
        end

        local questLevel
        if logIndex then
            if C_QuestLog.GetInfo then
                local ok, info = pcall(C_QuestLog.GetInfo, logIndex)
                if ok and info and info.level then questLevel = info.level end
            end
            if not questLevel and GetQuestLogTitle then
                local ok, _, level = pcall(GetQuestLogTitle, logIndex)
                if ok and level then questLevel = level end
            end
        end

        local questTypeAtlas = GetQuestTypeAtlas(questID, category)

        quests[#quests + 1] = {
            entryKey       = questID,
            questID        = questID,
            title          = title,
            objectives     = objectives,
            color          = color,
            category       = category,
            isComplete     = isComplete,
            isSuperTracked = isSuper,
            isNearby       = isNearby,
            isAccepted     = isAccepted,
            zoneName       = zoneName,
            itemLink       = itemLink,
            itemTexture    = itemTexture,
            questTypeAtlas = questTypeAtlas,
            isDungeonQuest = isDungeonQuest,
            isTracked      = isTracked,
            level          = questLevel,
        }
    end

    local filterByZone = addon.GetDB("filterByZone", false)
    for i = 1, numWatches do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        if questID then
            -- When \"Filter by current zone\" is enabled, we *still* want tracked WORLD quests
            -- to remain visible while you're in the broader zone (even if the child map
            -- changes and they momentarily fall out of nearbySet).
            local isWorld = C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID)
            if (not filterByZone or nearbySet[questID] or isWorld) then
                addQuest(questID)
            end
        end
    end

    -- Active zone world quests and callings are automatically included from GetNearbyQuestIDs/GetWorldAndCallingQuestIDsToShow.
    for _, entry in ipairs(addon.GetWorldAndCallingQuestIDsToShow(nearbySet, taskQuestOnlySet)) do
        if not seen[entry.questID] then
            addQuest(entry.questID, { isTracked = entry.isTracked, forceCategory = entry.forceCategory })
        end
    end

    if IsInMythicDungeon() and C_QuestLog.IsWorldQuest then
        for questID, _ in pairs(nearbySet) do
            if not seen[questID] and not C_QuestLog.IsWorldQuest(questID) then
                if not (C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID)) then
                    addQuest(questID, { isDungeonQuest = true, isTracked = false })
                end
            end
        end
    end

    -- Always show super-tracked world quest in the list even if not on current map or watch list (e.g. super-tracked from map only).
    if superTracked and superTracked > 0 and not seen[superTracked] and C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(superTracked) then
        addQuest(superTracked, { isTracked = true })
    end

    return quests
end

local function SortAndGroupQuests(quests)
    local groups = {}
    for _, key in ipairs(addon.GetGroupOrder()) do
        groups[key] = {}
    end

    for _, q in ipairs(quests) do
        if q.isRare or q.category == "RARE" then
            groups["RARES"][#groups["RARES"] + 1] = q
        elseif q.isDungeonQuest then
            groups["DUNGEON"][#groups["DUNGEON"] + 1] = q
        elseif q.category == "WORLD" or q.category == "CALLING" then
            groups["WORLD"][#groups["WORLD"] + 1] = q
        elseif q.isNearby and not q.isAccepted then
            -- Non-accepted quests tied to the current zone map.
            groups["AVAILABLE"][#groups["AVAILABLE"] + 1] = q
        elseif q.isNearby and q.isAccepted then
            -- Accepted quests that are in the current zone.
            groups["NEARBY"][#groups["NEARBY"] + 1] = q
        else
            local grp = addon.CATEGORY_TO_GROUP[q.category] or "DEFAULT"
            groups[grp][#groups[grp] + 1] = q
        end
    end

    local result = {}
    for _, key in ipairs(addon.GetGroupOrder()) do
        if #groups[key] > 0 then
            result[#result + 1] = { key = key, quests = groups[key] }
        end
    end
    return result
end

addon.GetQuestCategory   = GetQuestCategory
addon.GetQuestColor      = GetQuestColor
addon.GetSectionColor    = GetSectionColor
addon.GetQuestTypeAtlas  = GetQuestTypeAtlas
addon.GetQuestZoneName   = GetQuestZoneName
addon.IsInMythicDungeon  = IsInMythicDungeon
addon.GetMythicDungeonName = GetMythicDungeonName
addon.ReadTrackedQuests  = ReadTrackedQuests
addon.SortAndGroupQuests = SortAndGroupQuests
