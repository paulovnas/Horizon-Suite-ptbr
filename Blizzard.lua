--[[
    Horizon Suite - Focus - Blizzard Suppression
    Hide default objective tracker when Horizon Suite is enabled.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- BLIZZARD SUPPRESSION
-- ============================================================================

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local function KillBlizzardFrame(frame)
    if not frame then return end
    local ok1, err1 = pcall(function()
        frame:UnregisterAllEvents()
        frame:SetParent(hiddenParent)
        frame:Hide()
        frame:SetAlpha(0)
    end)
    if not ok1 and addon.HSPrint then addon.HSPrint("KillBlizzardFrame hide failed: " .. tostring(err1)) end
    local ok2, err2 = pcall(function()
        frame:SetScript("OnShow", function(self) self:Hide() end)
    end)
    if not ok2 and addon.HSPrint then addon.HSPrint("KillBlizzardFrame OnShow hook failed: " .. tostring(err2)) end
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
        local ok, err = pcall(function()
            ObjectiveTrackerFrame:SetParent(UIParent)
            ObjectiveTrackerFrame:ClearAllPoints()
            ObjectiveTrackerFrame:SetPoint("TOPRIGHT", MinimapCluster or UIParent, "BOTTOMRIGHT", 0, 0)
            ObjectiveTrackerFrame:SetAlpha(1)
            ObjectiveTrackerFrame:Show()
            ObjectiveTrackerFrame:SetScript("OnShow", nil)
        end)
        if not ok and addon.HSPrint then addon.HSPrint("RestoreTracker failed: " .. tostring(err)) end
        trackerSuppressed = false
    end
end

addon.TrySuppressTracker = TrySuppressTracker
addon.RestoreTracker    = RestoreTracker
