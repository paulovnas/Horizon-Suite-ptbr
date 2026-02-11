--[[
    Horizon Suite - Focus - Interactions
    Mouse scripts on pool entries (click, tooltip, scroll).
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- INTERACTIONS
-- ============================================================================

local DOUBLE_CLICK_WINDOW = 0.30
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
    e._lastClickTime = 0
    e._lastClickQuest = nil
    e._lastRightClickTime = 0
    e._lastRightClickQuest = nil

    e:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            if self.entryKey then
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

            local isWorldQuest = addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(self.questID)
            -- World quests: left-click = set active (super-track) only; position does not change. Shift+click = add to watch list for other zones.
            if isWorldQuest then
                if IsShiftKeyDown() and C_QuestLog.AddWorldQuestWatch then
                    C_QuestLog.AddWorldQuestWatch(self.questID)
                    addon.ScheduleRefresh()
                    return
                end
                -- Single/double click: set super-tracked or open details; do NOT AddWorldQuestWatch so list order stays the same.
            elseif self.isTracked == false then
                if C_QuestLog.AddQuestWatch then
                    C_QuestLog.AddQuestWatch(self.questID)
                end
                addon.ScheduleRefresh()
                return
            end

            local clickOpensLog = addon.GetDB("clickTitleOpensQuestLog", false)
            local now = GetTime()
            local isDoubleClick = self._lastClickQuest == self.questID
                and (now - self._lastClickTime) <= DOUBLE_CLICK_WINDOW

            if isDoubleClick then
                self._lastClickTime = 0
                self._lastClickQuest = nil
                addon.OpenQuestDetails(self.questID)
            elseif clickOpensLog then
                self._lastClickTime = now
                self._lastClickQuest = self.questID
                addon.OpenQuestDetails(self.questID)
            else
                self._lastClickTime = now
                self._lastClickQuest = self.questID
                if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
                    C_SuperTrack.SetSuperTrackedQuestID(self.questID)
                end
                if addon.FullLayout and not InCombatLockdown() then
                    addon.FullLayout()
                end
            end
        elseif button == "RightButton" then
            if self.entryKey then
                local vignetteGUID = self.entryKey:match("^vignette:(.+)$")
                if vignetteGUID and C_SuperTrack and C_SuperTrack.GetSuperTrackedVignette then
                    if C_SuperTrack.GetSuperTrackedVignette() == vignetteGUID then
                        C_SuperTrack.SetSuperTrackedVignette(nil)
                    end
                end
                return
            end
            if self.questID then
                local now = GetTime()
                local rightDoubleClick = addon.GetDB("doubleClickToAbandon", true)
                    and self._lastRightClickQuest == self.questID
                    and (now - self._lastRightClickTime) <= DOUBLE_CLICK_WINDOW

                if rightDoubleClick then
                    self._lastRightClickTime = 0
                    self._lastRightClickQuest = nil
                    local questName = C_QuestLog.GetTitleForQuestID(self.questID) or "this quest"
                    StaticPopup_Show("HORIZONSUITE_ABANDON_QUEST", questName, nil, { questID = self.questID })
                else
                    self._lastRightClickTime = now
                    self._lastRightClickQuest = self.questID
                    if addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(self.questID) and addon.RemoveWorldQuestWatch then
                        addon.RemoveWorldQuestWatch(self.questID)
                    elseif C_QuestLog.RemoveQuestWatch then
                        C_QuestLog.RemoveQuestWatch(self.questID)
                    end
                    addon.ScheduleRefresh()
                end
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
        elseif self.questID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local ok, err = pcall(GameTooltip.SetHyperlink, GameTooltip, "quest:" .. self.questID)
            if not ok and addon.HSPrint then addon.HSPrint("Tooltip SetHyperlink (quest) failed: " .. tostring(err)) end
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
