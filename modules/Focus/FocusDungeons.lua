--[[
    Horizon Suite - Focus - Dungeon Provider
    Instance detection (GetInstanceInfo) and dungeon quest collection. Isolated API boundary.
]]

local addon = _G.HorizonSuite

--- True when the player is in any party dungeon (Normal, Heroic, Mythic, or Mythic+). Guarded.
local function IsInPartyDungeon()
    local ok, _, instanceType = pcall(GetInstanceInfo)
    return ok and instanceType == "party"
end

local function IsInMythicDungeon()
    local _, instanceType, difficultyID = GetInstanceInfo()
    return instanceType == "party" and (difficultyID == 8 or difficultyID == 23)
end

local function GetMythicDungeonName()
    local name = GetInstanceInfo()
    return name or nil
end

--- Returns nearby non-WQ, non-Calling quests when in a party dungeon. Each has questID and opts.
local function CollectDungeonQuests(ctx)
    if not IsInPartyDungeon() then return {} end
    local out = {}
    local nearbySet = ctx.nearbySet or {}
    local seen = ctx.seen or {}
    for questID, _ in pairs(nearbySet) do
        if not seen[questID] and not addon.IsQuestWorldQuest(questID) then
            if not (C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID)) then
                out[#out + 1] = { questID = questID, opts = { isDungeonQuest = true, isTracked = false, forceCategory = "DUNGEON" } }
            end
        end
    end
    return out
end

addon.IsInPartyDungeon     = IsInPartyDungeon
addon.IsInMythicDungeon    = IsInMythicDungeon
addon.GetMythicDungeonName = GetMythicDungeonName
addon.CollectDungeonQuests = CollectDungeonQuests
