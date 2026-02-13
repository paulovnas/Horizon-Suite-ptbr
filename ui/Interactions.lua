--[[
    Horizon Suite - Focus - Interactions
    Mouse scripts on pool entries (click, tooltip, scroll).
]]

local addon = _G.HorizonSuite

-- INTERACTIONS
-- ============================================================================

local pool = addon.pool

StaticPopupDialogs["HORIZONSUITE_ABANDON_QUEST"] = StaticPopupDialogs["HORIZONSUITE_ABANDON_QUEST"] or {
    text = "Abandon %s?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        if data and data.questID and C_QuestLog and C_QuestLog.AbandonQuest then
            C_QuestLog.AbandonQuest(data.questID)
            addon.ScheduleRefresh()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

for i = 1, addon.POOL_SIZE do
    local e = pool[i]
    e:EnableMouse(true)

    e:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            if self.entryKey then
                local achID = self.entryKey:match("^ach:(%d+)$")
                if achID and self.achievementID then
                    local requireCtrl = addon.GetDB("requireCtrlForQuestClicks", false)
                    if requireCtrl and not IsControlKeyDown() then return end
                    if addon.SetSuperTrackedAchievementID then
                        addon.SetSuperTrackedAchievementID(self.achievementID)
                    end
                    if addon.FullLayout and not InCombatLockdown() then addon.FullLayout() end
                    return
                end
                local vignetteGUID = self.entryKey:match("^vignette:(.+)$")
                if vignetteGUID and C_SuperTrack and C_SuperTrack.SetSuperTrackedVignette then
                    C_SuperTrack.SetSuperTrackedVignette(vignetteGUID)
                end
                if WorldMapFrame and not WorldMapFrame:IsShown() and ToggleWorldMap then
                    ToggleWorldMap()
                end
                return
            end
            if not self.questID then return end

            local requireCtrl = addon.GetDB("requireCtrlForQuestClicks", false)
            local isWorldQuest = addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(self.questID)

            -- Shift+Left: always open quest log & map (safe, read-only). For world quests, optionally add to watch list.
            if IsShiftKeyDown() then
                if isWorldQuest and C_QuestLog.AddWorldQuestWatch then
                    -- With safety enabled, adding to watch for world quests requires Ctrl+Shift+Left.
                    if not requireCtrl or IsControlKeyDown() then
                        C_QuestLog.AddWorldQuestWatch(self.questID)
                        addon.ScheduleRefresh()
                    end
                end
                if addon.OpenQuestDetails then
                    addon.OpenQuestDetails(self.questID)
                end
                return
            end

            -- Non-world quests that are not yet tracked: add to tracker (respect Ctrl safety if enabled).
            if not isWorldQuest and self.isTracked == false then
                if requireCtrl and not IsControlKeyDown() then
                    -- Safety: ignore plain Left-click when Ctrl is required.
                    return
                end
                if C_QuestLog.AddQuestWatch then
                    C_QuestLog.AddQuestWatch(self.questID)
                end
                addon.ScheduleRefresh()
                return
            end

            -- Left (no modifier): focus (set as super-tracked quest).
            if requireCtrl and not IsControlKeyDown() then
                -- Safety: ignore plain Left-click on quests when Ctrl is required.
                return
            end
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
                C_SuperTrack.SetSuperTrackedQuestID(self.questID)
            end
            if addon.FullLayout and not InCombatLockdown() then
                addon.FullLayout()
            end
        elseif button == "RightButton" then
            if self.entryKey then
                local achID = self.entryKey:match("^ach:(%d+)$")
                if achID and self.achievementID then
                    local requireCtrl = addon.GetDB("requireCtrlForQuestClicks", false)
                    if requireCtrl and not IsControlKeyDown() then return end
                    if addon.GetSuperTrackedAchievementID and addon.GetSuperTrackedAchievementID() == self.achievementID then
                        if addon.SetSuperTrackedAchievementID then addon.SetSuperTrackedAchievementID(nil) end
                    end
                    local trackType = (Enum and Enum.ContentTrackingType and Enum.ContentTrackingType.Achievement) or 2
                    local stopType = (Enum and Enum.ContentTrackingStopType and Enum.ContentTrackingStopType.Manual) or 0
                    if C_ContentTracking and C_ContentTracking.StopTracking then
                        C_ContentTracking.StopTracking(trackType, self.achievementID, stopType)
                    elseif RemoveTrackedAchievement then
                        RemoveTrackedAchievement(self.achievementID)
                    end
                    addon.ScheduleRefresh()
                    return
                end
                local vignetteGUID = self.entryKey:match("^vignette:(.+)$")
                if vignetteGUID and C_SuperTrack and C_SuperTrack.GetSuperTrackedVignette then
                    if C_SuperTrack.GetSuperTrackedVignette() == vignetteGUID then
                        C_SuperTrack.SetSuperTrackedVignette(nil)
                    end
                end
                return
            end
            if self.questID then
                -- Shift+Right: abandon quest with confirmation.
                if IsShiftKeyDown() then
                    local questName = C_QuestLog.GetTitleForQuestID(self.questID) or "this quest"
                    StaticPopup_Show("HORIZONSUITE_ABANDON_QUEST", questName, nil, { questID = self.questID })
                    return
                end

                local requireCtrl = addon.GetDB("requireCtrlForQuestClicks", false)
                if requireCtrl and not IsControlKeyDown() then
                    -- Safety: ignore plain Right-click on quests when Ctrl is required.
                    return
                end

                -- Right (no modifier): if this quest is focused, unfocus only; otherwise untrack.
                if C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.SetSuperTrackedQuestID then
                    local focusedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
                    if focusedQuestID and focusedQuestID == self.questID then
                        C_SuperTrack.SetSuperTrackedQuestID(0)
                        if addon.FullLayout and not InCombatLockdown() then
                            addon.FullLayout()
                        end
                        return
                    end
                end

                if addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(self.questID) and addon.RemoveWorldQuestWatch then
                    addon.RemoveWorldQuestWatch(self.questID)
                elseif C_QuestLog.RemoveQuestWatch then
                    C_QuestLog.RemoveQuestWatch(self.questID)
                end
                addon.ScheduleRefresh()
            end
        end
    end)

    e:SetScript("OnEnter", function(self)
        if not self.questID and not self.entryKey then return end
        local r, g, b = self.titleText:GetTextColor()
        self._savedColor = { r, g, b }
        self.titleText:SetTextColor(
            math.min(r * 1.25, 1),
            math.min(g * 1.25, 1),
            math.min(b * 1.25, 1), 1)
        if self.creatureID then
            local link = ("unit:Creature-0-0-0-0-%d-0000000000"):format(self.creatureID)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local ok, err = pcall(GameTooltip.SetHyperlink, GameTooltip, link)
            if not ok and addon.HSPrint then addon.HSPrint("Tooltip SetHyperlink (creature) failed: " .. tostring(err)) end
            local att = _G.AllTheThings
            if att and att.Modules and att.Modules.Tooltip then
                local attach = att.Modules.Tooltip.AttachTooltipSearchResults
                local searchFn = att.SearchForObject or att.SearchForField
                if attach and searchFn then
                    local ok, err = pcall(attach, GameTooltip, searchFn, "npcID", self.creatureID)
                    if not ok and addon.HSPrint then addon.HSPrint("ATT tooltip attach failed: " .. tostring(err)) end
                end
            end
            GameTooltip:Show()
        elseif self.achievementID and GetAchievementLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local link = GetAchievementLink(self.achievementID)
            if link then
                local ok, err = pcall(GameTooltip.SetHyperlink, GameTooltip, link)
                if not ok and addon.HSPrint then addon.HSPrint("Tooltip SetHyperlink (achievement) failed: " .. tostring(err)) end
            else
                GameTooltip:SetText(self.titleText:GetText() or "")
            end
            GameTooltip:Show()
        elseif self.questID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local ok, err = pcall(GameTooltip.SetHyperlink, GameTooltip, "quest:" .. self.questID)
            if not ok and addon.HSPrint then addon.HSPrint("Tooltip SetHyperlink (quest) failed: " .. tostring(err)) end
            addon.AddQuestRewardsToTooltip(GameTooltip, self.questID)
            GameTooltip:Show()
        elseif self.entryKey then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.titleText:GetText() or "")
            GameTooltip:Show()
        end
    end)

    e:SetScript("OnLeave", function(self)
        if self._savedColor then
            local sc = self._savedColor
            self.titleText:SetTextColor(sc[1], sc[2], sc[3], 1)
            self._savedColor = nil
        end
        if GameTooltip:GetOwner() == self then
            GameTooltip:Hide()
        end
    end)

    e:EnableMouseWheel(true)
    e:SetScript("OnMouseWheel", function(_, delta) addon.HandleScroll(delta) end)
end
