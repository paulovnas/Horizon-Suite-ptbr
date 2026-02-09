--[[
    Horizon Suite - Focus - Blizzard Suppression
    Hide default objective tracker when MQT is enabled.
]]

local addon = _G.ModernQuestTracker

-- ============================================================================
-- BLIZZARD SUPPRESSION
-- ============================================================================

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local function KillBlizzardFrame(frame)
    if not frame then return end
    pcall(function()
        frame:UnregisterAllEvents()
        frame:SetParent(hiddenParent)
        frame:Hide()
        frame:SetAlpha(0)
    end)
    pcall(function()
        frame:SetScript("OnShow", function(self) self:Hide() end)
    end)
end

local trackerSuppressed = false

local function TrySuppressTracker()
    if trackerSuppressed then return end
    if ObjectiveTrackerFrame then
        KillBlizzardFrame(ObjectiveTrackerFrame)
        trackerSuppressed = true
    end
end

local function RestoreTracker()
    if not trackerSuppressed then return end
    if ObjectiveTrackerFrame then
        pcall(function()
            ObjectiveTrackerFrame:SetParent(UIParent)
            ObjectiveTrackerFrame:ClearAllPoints()
            ObjectiveTrackerFrame:SetPoint("TOPRIGHT", MinimapCluster or UIParent, "BOTTOMRIGHT", 0, 0)
            ObjectiveTrackerFrame:SetAlpha(1)
            ObjectiveTrackerFrame:Show()
            ObjectiveTrackerFrame:SetScript("OnShow", nil)
        end)
        trackerSuppressed = false
    end
end

addon.TrySuppressTracker = TrySuppressTracker
addon.RestoreTracker    = RestoreTracker
