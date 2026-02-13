--[[
    Horizon Suite - Focus - Achievement Tracking
    GetTrackedAchievements / GetAchievementInfo data provider for tracked achievements.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- ACHIEVEMENT DATA PROVIDER
-- ============================================================================

local TRACKING_TYPE_ACHIEVEMENT = (Enum and Enum.ContentTrackingType and Enum.ContentTrackingType.Achievement) or 2

--- Build tracker rows from WoW tracked achievements.
-- @return table Array of normalized entry tables for the tracker
local function ReadTrackedAchievements()
    local out = {}
    local idList = {}

    -- WoW 10.1.5+: C_ContentTracking replaces GetTrackedAchievements
    if C_ContentTracking and C_ContentTracking.GetTrackedIDs then
        local ids = C_ContentTracking.GetTrackedIDs(TRACKING_TYPE_ACHIEVEMENT)
        if ids and type(ids) == "table" then
            for _, id in ipairs(ids) do
                if type(id) == "number" and id > 0 then
                    idList[#idList + 1] = id
                end
            end
        end
    elseif GetTrackedAchievements then
        -- Legacy: multiple return values
        for i = 1, 10 do
            local id = select(i, GetTrackedAchievements())
            if type(id) == "number" and id > 0 then
                idList[#idList + 1] = id
            end
        end
    end

    local achievementColor = (addon.GetQuestColor and addon.GetQuestColor("ACHIEVEMENT")) or (addon.QUEST_COLORS and addon.QUEST_COLORS.ACHIEVEMENT) or { 0.78, 0.48, 0.22 }

    for _, achievementID in ipairs(idList) do
        if type(achievementID) == "number" and achievementID > 0 then
            local aOk, id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = pcall(GetAchievementInfo, achievementID)
            if not aOk or not name or name == "" then
                name = "Achievement " .. tostring(achievementID)
            end
            local isComplete = (completed == true) or (completed == 1)
            if isComplete and not (addon.GetDB and addon.GetDB("showCompletedAchievements", false)) then
                -- Skip completed achievements unless user opted in
            else
            local achievementIcon = (icon and (type(icon) == "number" or (type(icon) == "string" and icon ~= ""))) and icon or nil

            local objectives = {}
            if GetAchievementCriteriaInfo then
                local numCriteria = 0
                if GetAchievementNumCriteria then
                    local nOk, n = pcall(GetAchievementNumCriteria, achievementID)
                    if nOk and type(n) == "number" then numCriteria = n end
                end
                for criteriaIndex = 1, math.max(numCriteria, 1) do
                    local cOk, criteriaString, criteriaType, completedCrit, quantity, reqQuantity, charName, critFlags, assetID, quantityString, criteriaID, eligible = pcall(GetAchievementCriteriaInfo, achievementID, criteriaIndex)
                    if cOk and criteriaString and criteriaString ~= "" then
                        local percent = nil
                        if quantity and reqQuantity and reqQuantity > 0 then
                            percent = math.floor(100 * math.min(quantity, reqQuantity) / reqQuantity)
                        end
                        objectives[#objectives + 1] = {
                            text = criteriaString,
                            finished = (completedCrit == true) or (completedCrit == 1),
                            percent = percent,
                        }
                    end
                end
            end

            out[#out + 1] = {
                entryKey       = "ach:" .. tostring(achievementID),
                achievementID  = achievementID,
                questID        = nil,
                title         = name or ("Achievement " .. tostring(achievementID)),
                objectives    = objectives,
                color         = achievementColor,
                category      = "ACHIEVEMENT",
                isComplete    = isComplete,
                isSuperTracked = false,
                isNearby      = false,
                zoneName      = nil,
                itemLink      = nil,
                itemTexture   = nil,
                isAchievement = true,
                isTracked     = true,
                achievementIcon = achievementIcon,
            }
            end
        end
    end

    return out
end

addon.ReadTrackedAchievements = ReadTrackedAchievements
