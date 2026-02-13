--[[
    Horizon Suite - Focus - Mythic+ Block
    Cinematic banner: dungeon name, keystone level, timer/progress, affixes.
    Hover tooltip shows detailed dungeon and modifier info.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- MYTHIC+ BANNER (CINEMATIC, ALWAYS-VISIBLE ABOVE / BELOW LIST)
-- ============================================================================

local MPLUS_BANNER_HEIGHT = 46
local mplusBlock = CreateFrame("Frame", nil, addon.HS)
mplusBlock:SetSize(addon.GetPanelWidth() - addon.PADDING * 2, MPLUS_BANNER_HEIGHT)
mplusBlock:Hide()

-- Cinematic gradient background (dark top, slightly lighter center, dark bottom).
local mplusBg = mplusBlock:CreateTexture(nil, "BACKGROUND")
mplusBg:SetAllPoints()
if mplusBg.SetGradient and CreateColor then
    -- Two-stop vertical gradient for cinematic vignette feel.
    mplusBg:SetGradient("VERTICAL", CreateColor(0.02, 0.02, 0.06, 0.88), CreateColor(0.05, 0.05, 0.12, 0.72))
else
    mplusBg:SetColorTexture(0.02, 0.02, 0.06, 0.78)
end

-- Left accent aligned with quest entry highlight bar (bar-left position).
local accent = mplusBlock:CreateTexture(nil, "BORDER")
local dungeonColor = (addon.QUEST_COLORS and addon.QUEST_COLORS.DUNGEON) or { 0.6, 0.4, 1.0 }
accent:SetColorTexture(dungeonColor[1], dungeonColor[2], dungeonColor[3], 0.65)

local contentOffsetX = 8
local iconSize = addon.QUEST_TYPE_ICON_SIZE or 16
local iconGap = addon.QUEST_TYPE_ICON_GAP or 4

-- Dungeon/keystone icon (same as DUNGEON category).
local mplusIcon = mplusBlock:CreateTexture(nil, "OVERLAY")
mplusIcon:SetSize(iconSize, iconSize)
mplusIcon:SetAtlas("questlog-questtypeicon-dungeon")

-- Hero text (left): dungeon name + keystone level.
local mplusHeroText = mplusBlock:CreateFontString(nil, "OVERLAY")
mplusHeroText:SetFontObject(addon.TitleFont)
mplusHeroText:SetTextColor(0.96, 0.96, 1.0, 1)
mplusHeroText:SetWordWrap(true)
mplusHeroText:SetJustifyH("LEFT")

-- Progress pill (right): timer • completion.
local mplusPillText = mplusBlock:CreateFontString(nil, "OVERLAY")
mplusPillText:SetFontObject(addon.ObjFont)
mplusPillText:SetTextColor(0.6, 0.88, 1.0, 1)
mplusPillText:SetPoint("TOPLEFT", mplusBlock, "CENTER", contentOffsetX, -2)
mplusPillText:SetPoint("TOPRIGHT", mplusBlock, "TOPRIGHT", -contentOffsetX, -2)
mplusPillText:SetJustifyH("RIGHT")

-- Affixes row (bottom, subdued).
local mplusAffixesText = mplusBlock:CreateFontString(nil, "OVERLAY")
mplusAffixesText:SetFontObject(addon.SectionFont)
mplusAffixesText:SetTextColor(0.72, 0.76, 0.88, 1)
mplusAffixesText:SetPoint("TOPLEFT", mplusHeroText, "BOTTOMLEFT", 0, -4)
mplusAffixesText:SetPoint("TOPRIGHT", mplusBlock, "TOPRIGHT", -contentOffsetX, -8)
mplusAffixesText:SetWordWrap(true)
mplusAffixesText:SetJustifyH("LEFT")

addon.mplusBlock       = mplusBlock
addon.mplusTimerText   = mplusHeroText  -- backward compat
addon.mplusPctText     = mplusPillText  -- backward compat
addon.mplusAffixesText = mplusAffixesText

addon.MPLUS_BANNER_HEIGHT = MPLUS_BANNER_HEIGHT

local function GetMplusTimer()
    if not C_ScenarioInfo or not C_ScenarioInfo.GetCriteriaInfo then return nil, nil end
    local maxIdx = 20
    for i = 0, maxIdx do
        local ok, info = pcall(C_ScenarioInfo.GetCriteriaInfo, i)
        if ok and info and info.duration and info.duration > 0 and info.elapsed and type(info.elapsed) == "number" then
            if not info.complete and not info.completed and not info.failed then
                local startTime = GetTime() - math.max(0, math.min(info.elapsed, info.duration))
                return info.duration, startTime
            end
        end
    end
    return nil, nil
end

local function ApplyMplusAlignment()
    -- Align with quest entry layout: bar at BAR_LEFT_OFFSET left of content, text at GetContentLeftOffset().
    local contentLeft = addon.GetContentLeftOffset and addon.GetContentLeftOffset() or (addon.PADDING + addon.ICON_COLUMN_WIDTH)
    local barLeft = addon.BAR_LEFT_OFFSET or 9
    local accentX = contentLeft - addon.PADDING - barLeft
    local heroLeft = contentLeft - addon.PADDING
    local barW = math.max(2, math.min(6, tonumber(addon.GetDB("highlightBarWidth", 2)) or 2))

    accent:SetWidth(barW)
    accent:ClearAllPoints()
    accent:SetPoint("TOPLEFT", mplusBlock, "TOPLEFT", accentX, 0)
    accent:SetPoint("BOTTOMLEFT", mplusBlock, "BOTTOMLEFT", accentX, 0)

    -- Match quest entry: icon right edge at BAR_LEFT_OFFSET+2 left of content (no overlap with bar).
    local iconRightEdge = contentLeft - addon.PADDING - ((addon.BAR_LEFT_OFFSET or 9) + 2)
    mplusIcon:ClearAllPoints()
    mplusIcon:SetPoint("TOPRIGHT", mplusBlock, "TOPLEFT", iconRightEdge, -2)

    mplusHeroText:ClearAllPoints()
    mplusHeroText:SetPoint("TOPLEFT", mplusBlock, "TOPLEFT", heroLeft, -2)
    mplusHeroText:SetPoint("TOPRIGHT", mplusBlock, "CENTER", -contentOffsetX, -2)

    local blockW = addon.GetPanelWidth() - addon.PADDING * 2
    mplusAffixesText:SetWidth(blockW - contentOffsetX - heroLeft)
end

local function PositionMplusBlock(pos)
    mplusBlock:SetWidth(addon.GetPanelWidth() - addon.PADDING * 2)
    ApplyMplusAlignment()
    mplusBlock:ClearAllPoints()
    if pos == "bottom" then
        mplusBlock:SetPoint("BOTTOMLEFT", addon.HS, "BOTTOMLEFT", addon.PADDING, addon.PADDING)
        mplusBlock:SetPoint("BOTTOMRIGHT", addon.HS, "BOTTOMRIGHT", -addon.PADDING, addon.PADDING)
    else
        local topOffset = addon.GetContentTop()
        mplusBlock:SetPoint("TOPLEFT", addon.HS, "TOPLEFT", addon.PADDING, topOffset)
        mplusBlock:SetPoint("TOPRIGHT", addon.HS, "TOPRIGHT", -addon.PADDING, topOffset)
    end
end

local function ShowMplusTooltip()
    local show = addon.GetDB("showMythicPlusBlock", false)
    local inMplus = addon.IsInMythicDungeon and addon.IsInMythicDungeon()
    if not show or (not inMplus and not addon.mplusDebugPreview) then return end

    if not GameTooltip then return end
    GameTooltip:SetOwner(mplusBlock, "ANCHOR_RIGHT", 0, 0)
    GameTooltip:ClearLines()

    local dc = dungeonColor
    local hex = string.format("|cFF%02x%02x%02x", dc[1] * 255, dc[2] * 255, dc[3] * 255)

    local dungeonName, level, pctStr, timerStr, affixList = "Mythic+ Dungeon", "+15", "—", "—", {}

    if addon.mplusDebugPreview then
        dungeonName = "Darkheart Thicket"
        level = "+15"
        pctStr = "67%"
        timerStr = "18:32"
        affixList = {
            { name = "Fortified", desc = "Non-boss enemies have 20% more health and deal 30% more damage." },
            { name = "Bursting", desc = "When slain, non-boss enemies explode, dealing damage over 4 sec." },
            { name = "Sanguine", desc = "When slain, non-boss enemies leave a pool of blood." },
        }
    else
        if addon.GetMythicDungeonName then
            local ok, name = pcall(addon.GetMythicDungeonName)
            if ok and name and name ~= "" then dungeonName = name end
        end
        if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneLevel then
            local ok, lvl = pcall(C_ChallengeMode.GetActiveKeystoneLevel)
            if ok and lvl and lvl > 0 then level = "+" .. tostring(lvl) end
        end
        if C_Scenario and C_Scenario.GetScenarioStepInfo then
            local ok, stepInfo = pcall(C_Scenario.GetScenarioStepInfo)
            if ok and stepInfo then
                local p = (type(stepInfo) == "table" and stepInfo.progress) or (type(stepInfo) == "number" and stepInfo)
                if p then pctStr = tostring(p) .. "%" end
            end
        end
        if C_Scenario and C_Scenario.GetScenarioInfo then
            local ok, info = pcall(C_Scenario.GetScenarioInfo)
            if ok and info and info.currentStage and info.numStages and info.numStages > 0 then
                pctStr = string.format("%d/%d", info.currentStage or 0, info.numStages or 0)
            end
        end
        local dur, start = GetMplusTimer()
        if dur and start then
            local rem = math.max(0, dur - (GetTime() - start))
            timerStr = string.format("%d:%02d", math.floor(rem / 60), math.floor(rem % 60))
        end
        if C_MythicPlus and C_MythicPlus.GetCurrentAffixes then
            local ok, affixes = pcall(C_MythicPlus.GetCurrentAffixes)
            if ok and affixes then
                for _, a in ipairs(affixes) do
                    local id = a
                    local name = nil
                    if type(a) == "table" then
                        id = a.id or a
                        name = a.name
                    end
                    local desc = nil
                    if C_ChallengeMode and C_ChallengeMode.GetAffixInfo and type(id) == "number" then
                        local dOk, info = pcall(C_ChallengeMode.GetAffixInfo, id)
                        if dOk and info then
                            name = name or info.name
                            desc = info.description
                        end
                    end
                    affixList[#affixList + 1] = { name = name or "Affix", desc = desc or "" }
                end
            end
        end
    end

    GameTooltip:AddLine(hex .. dungeonName .. " (" .. level .. ")|r", 1, 1, 1, true)
    GameTooltip:AddLine(hex .. "Progress: " .. pctStr .. "  |  Time: " .. timerStr .. "|r", 0.9, 0.9, 0.9, false)
    GameTooltip:AddLine(" ")

    for _, a in ipairs(affixList) do
        GameTooltip:AddLine(hex .. (a.name or "Affix") .. "|r", 0.95, 0.95, 1, true)
        if a.desc and a.desc ~= "" then
            GameTooltip:AddLine("  " .. a.desc, 0.75, 0.78, 0.85, true)
        end
    end

    GameTooltip:Show()
end

local function HideMplusTooltip()
    if GameTooltip and GameTooltip:GetOwner() == mplusBlock then
        GameTooltip:Hide()
    end
end

mplusBlock:SetScript("OnEnter", function()
    if mplusBlock:IsShown() then ShowMplusTooltip() end
end)
mplusBlock:SetScript("OnLeave", HideMplusTooltip)

local function UpdateMplusBlock()
    local pos = addon.GetDB("mplusBlockPosition", "top") or "top"

    if addon.mplusDebugPreview then
        PositionMplusBlock(pos)
        mplusHeroText:SetText("Darkheart Thicket (+15)")
        mplusPillText:SetText("18:32 • 67%")
        mplusAffixesText:SetText("Fortified  Bursting  Sanguine")
        mplusBlock:Show()
        return
    end

    if not addon.GetDB("showMythicPlusBlock", false) or not addon.IsInMythicDungeon() then
        mplusBlock:Hide()
        return
    end

    PositionMplusBlock(pos)

    local dungeonName = (addon.GetMythicDungeonName and addon.GetMythicDungeonName()) or ""
    local level = 0
    if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneLevel then
        local ok, lvl = pcall(C_ChallengeMode.GetActiveKeystoneLevel)
        if ok and lvl and lvl > 0 then level = lvl end
    end
    local heroStr = (dungeonName ~= "" and dungeonName or "Mythic+") .. (level > 0 and (" (+" .. level .. ")") or "")

    local pctStr = ""
    if C_Scenario and C_Scenario.GetScenarioStepInfo then
        local ok, stepInfo = pcall(C_Scenario.GetScenarioStepInfo)
        if ok and stepInfo then
            local p = (type(stepInfo) == "table" and stepInfo.progress) or (type(stepInfo) == "number" and stepInfo)
            if p then pctStr = tostring(p) .. "%" end
        end
    end
    if pctStr == "" and C_Scenario and C_Scenario.GetScenarioInfo then
        local ok, info = pcall(C_Scenario.GetScenarioInfo)
        if ok and info and info.currentStage and info.numStages and info.numStages > 0 then
            pctStr = string.format("%d/%d", info.currentStage or 0, info.numStages or 0)
        end
    end
    if pctStr == "" then pctStr = "—" end

    local timerStr = ""
    local dur, start = GetMplusTimer()
    if dur and start then
        local rem = math.max(0, dur - (GetTime() - start))
        timerStr = string.format("%d:%02d", math.floor(rem / 60), math.floor(rem % 60))
    end
    if timerStr == "" then timerStr = "—" end

    local pillStr = timerStr .. " • " .. pctStr

    local affixStr = ""
    if C_MythicPlus and C_MythicPlus.GetCurrentAffixes then
        local ok, affixes = pcall(C_MythicPlus.GetCurrentAffixes)
        if ok and affixes and #affixes > 0 then
            local names = {}
            for _, a in ipairs(affixes) do
                if type(a) == "table" and a.name then
                    names[#names + 1] = a.name
                elseif type(a) == "number" and C_ChallengeMode and C_ChallengeMode.GetAffixInfo then
                    local dOk, info = pcall(C_ChallengeMode.GetAffixInfo, a)
                    if dOk and info and info.name then names[#names + 1] = info.name end
                end
            end
            affixStr = table.concat(names, "  ")
        end
    end
    if affixStr == "" then affixStr = "—" end

    mplusHeroText:SetText(heroStr)
    mplusPillText:SetText(pillStr)
    mplusAffixesText:SetText(affixStr)
    mplusBlock:Show()
end

addon.UpdateMplusBlock = UpdateMplusBlock
