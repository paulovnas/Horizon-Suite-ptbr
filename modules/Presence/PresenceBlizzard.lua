--[[
    Horizon Suite - Presence - Blizzard Suppression
    Hide default zone text, level-up, boss emotes, achievements, event toasts.
    Restore all when Presence is disabled.
]]

local addon = _G.HorizonSuite
if not addon or not addon.Presence then return end

-- ============================================================================
-- BLIZZARD SUPPRESSION
-- ============================================================================

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local suppressedFrames = {}
local originalParents = {}
local originalPoints = {}
local originalAlphas = {}
local addonLoadedUnregistered = false

local function KillBlizzardFrame(frame)
    if not frame then return end
    local ok1, err1 = pcall(function()
        frame:UnregisterAllEvents()
        suppressedFrames[frame] = true
        originalParents[frame] = frame:GetParent()
        local p, r, rp, x, y = frame:GetPoint(1)
        originalPoints[frame] = p and { p, r, rp, x, y } or nil
        originalAlphas[frame] = frame:GetAlpha()
        frame:SetParent(hiddenParent)
        frame:Hide()
        frame:SetAlpha(0)
    end)
    if not ok1 and addon.HSPrint then addon.HSPrint("Presence KillBlizzardFrame hide failed: " .. tostring(err1)) end
    local ok2, err2 = pcall(function()
        frame:SetScript("OnShow", function(self) self:Hide() end)
    end)
    if not ok2 and addon.HSPrint then addon.HSPrint("Presence KillBlizzardFrame OnShow hook failed: " .. tostring(err2)) end
end

local function RestoreBlizzardFrame(frame)
    if not frame or not suppressedFrames[frame] then return end
    local ok, err = pcall(function()
        frame:SetScript("OnShow", nil)
        frame:SetParent(originalParents[frame] or UIParent)
        frame:SetAlpha(originalAlphas[frame] or 1)
        local pt = originalPoints[frame]
        frame:ClearAllPoints()
        if pt and pt[1] then
            frame:SetPoint(pt[1], pt[2] or UIParent, pt[3] or "CENTER", pt[4] or 0, pt[5] or 0)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        frame:Show()
    end)
    if not ok and addon.HSPrint then addon.HSPrint("Presence RestoreBlizzardFrame failed: " .. tostring(err)) end
    suppressedFrames[frame] = nil
    originalParents[frame] = nil
    originalPoints[frame] = nil
    originalAlphas[frame] = nil
end

local function SuppressBlizzard()
    KillBlizzardFrame(ZoneTextFrame)
    KillBlizzardFrame(SubZoneTextFrame)
    KillBlizzardFrame(RaidBossEmoteFrame)
    KillBlizzardFrame(LevelUpDisplay)
    KillBlizzardFrame(BossBanner)
    KillBlizzardFrame(ObjectiveTrackerBonusBannerFrame)
    KillBlizzardFrame(EventToastManagerFrame)

    local wqFrame = WorldQuestCompleteBannerFrame or _G["WorldQuestCompleteBannerFrame"]
    if wqFrame then
        KillBlizzardFrame(wqFrame)
    end
end

local function RestoreBlizzard()
    RestoreBlizzardFrame(ZoneTextFrame)
    RestoreBlizzardFrame(SubZoneTextFrame)
    RestoreBlizzardFrame(RaidBossEmoteFrame)
    RestoreBlizzardFrame(LevelUpDisplay)
    RestoreBlizzardFrame(BossBanner)
    RestoreBlizzardFrame(ObjectiveTrackerBonusBannerFrame)
    local wqFrame = WorldQuestCompleteBannerFrame or _G["WorldQuestCompleteBannerFrame"]
    if wqFrame then RestoreBlizzardFrame(wqFrame) end
end

local function KillWorldQuestBanner()
    local frame = WorldQuestCompleteBannerFrame or _G["WorldQuestCompleteBannerFrame"]
    if frame then
        KillBlizzardFrame(frame)
    end
end

addon.Presence.SuppressBlizzard = SuppressBlizzard
addon.Presence.RestoreBlizzard = RestoreBlizzard
addon.Presence.KillWorldQuestBanner = KillWorldQuestBanner
