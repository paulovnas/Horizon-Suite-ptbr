--[[
    Horizon Suite - Focus - Mythic+ Block
    Timer, completion %, affixes when in M+ dungeon.
]]

local addon = _G.ModernQuestTracker

-- ============================================================================
-- MYTHIC+ BLOCK (TIMER, COMPLETION %, AFFIXES)
-- ============================================================================

local scrollFrame = addon.scrollFrame
local mplusBlock = CreateFrame("Frame", nil, addon.MQT)
mplusBlock:SetSize(addon.GetPanelWidth() - addon.PADDING * 2, 40)
mplusBlock:SetPoint("BOTTOM", scrollFrame, "TOP", 0, -4)
mplusBlock:Hide()
local mplusTimerText = mplusBlock:CreateFontString(nil, "OVERLAY")
mplusTimerText:SetFontObject(addon.ObjFont)
mplusTimerText:SetTextColor(0.9, 0.9, 0.9, 1)
mplusTimerText:SetPoint("TOPLEFT", mplusBlock, "TOPLEFT", 0, 0)
local mplusPctText = mplusBlock:CreateFontString(nil, "OVERLAY")
mplusPctText:SetFontObject(addon.ObjFont)
mplusPctText:SetTextColor(0.6, 0.8, 1, 1)
mplusPctText:SetPoint("TOPLEFT", mplusTimerText, "BOTTOMLEFT", 0, -2)
local mplusAffixesText = mplusBlock:CreateFontString(nil, "OVERLAY")
mplusAffixesText:SetFontObject(addon.SectionFont)
mplusAffixesText:SetTextColor(0.7, 0.7, 0.8, 1)
mplusAffixesText:SetPoint("TOPLEFT", mplusPctText, "BOTTOMLEFT", 0, -2)
mplusAffixesText:SetWordWrap(true)
mplusAffixesText:SetWidth(addon.GetPanelWidth() - addon.PADDING * 2)

addon.mplusTimerText   = mplusTimerText
addon.mplusPctText     = mplusPctText
addon.mplusAffixesText = mplusAffixesText

local function UpdateMplusBlock()
    if not addon.GetDB("showMythicPlusBlock", false) or not addon.IsInMythicDungeon() then
        mplusBlock:Hide()
        return
    end
    mplusBlock:SetWidth(addon.GetPanelWidth() - addon.PADDING * 2)
    mplusAffixesText:SetWidth(addon.GetPanelWidth() - addon.PADDING * 2)
    local pos = addon.GetDB("mplusBlockPosition", "top") or "top"
    mplusBlock:ClearAllPoints()
    if pos == "bottom" then
        mplusBlock:SetPoint("TOP", scrollFrame, "BOTTOM", 0, 4)
    else
        mplusBlock:SetPoint("BOTTOM", scrollFrame, "TOP", 0, -4)
    end
    local timerStr, pctStr, affixStr = "", "", ""
    if C_Scenario and C_Scenario.GetScenarioInfo then
        local ok, info = pcall(C_Scenario.GetScenarioInfo)
        if ok and info and info.name then
            if info.currentStage and info.numStages and info.numStages > 0 then
                pctStr = string.format("%d/%d", info.currentStage or 0, info.numStages or 0)
            end
        end
    end
    if C_Scenario and C_Scenario.GetScenarioStepInfo then
        local ok, stepInfo = pcall(function()
            return C_Scenario.GetScenarioStepInfo()
        end)
        if ok and stepInfo then
            local progress = (type(stepInfo) == "table" and stepInfo.progress) or (type(stepInfo) == "number" and stepInfo)
            if progress then pctStr = tostring(progress) .. "%" end
        end
    end
    if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneLevel then
        local ok, level = pcall(C_ChallengeMode.GetActiveKeystoneLevel)
        if ok and level and level > 0 then
            timerStr = "Keystone +" .. tostring(level)
        end
    end
    if C_MythicPlus and C_MythicPlus.GetCurrentAffixes then
        local ok, affixes = pcall(C_MythicPlus.GetCurrentAffixes)
        if ok and affixes and #affixes > 0 then
            local names = {}
            for _, a in ipairs(affixes) do
                if a and a.name then names[#names + 1] = a.name end
            end
            affixStr = table.concat(names, "  ")
        end
    end
    if timerStr == "" and C_Scenario and C_Scenario.GetScenarioInfo then
        timerStr = "M+"
    end
    mplusTimerText:SetText(timerStr ~= "" and timerStr or "Mythic+")
    mplusPctText:SetText(pctStr ~= "" and pctStr or "—")
    mplusAffixesText:SetText(affixStr ~= "" and affixStr or "—")
    mplusBlock:Show()
end

addon.UpdateMplusBlock = UpdateMplusBlock
