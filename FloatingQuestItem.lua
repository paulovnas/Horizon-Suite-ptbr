--[[
    Horizon Suite - Focus - Floating Quest Item
    Extra Action style button for super-tracked or first quest item.
]]

local addon = _G.ModernQuestTracker

-- ============================================================================
-- FLOATING QUEST ITEM BUTTON
-- ============================================================================

local floatingQuestItemBtn = CreateFrame("Button", "MQTFloatingQuestItem", UIParent, "SecureActionButtonTemplate")
floatingQuestItemBtn:SetSize(addon.GetDB("floatingQuestItemSize", 36) or 36, addon.GetDB("floatingQuestItemSize", 36) or 36)
floatingQuestItemBtn:SetPoint("RIGHT", addon.MQT, "LEFT", -12, 0)
floatingQuestItemBtn:SetAttribute("type", "item")
floatingQuestItemBtn:RegisterForClicks("AnyUp")
floatingQuestItemBtn:Hide()
local floatingQuestItemIcon = floatingQuestItemBtn:CreateTexture(nil, "ARTWORK")
floatingQuestItemIcon:SetAllPoints()
floatingQuestItemIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
floatingQuestItemBtn.icon = floatingQuestItemIcon
floatingQuestItemBtn.cooldown = CreateFrame("Cooldown", nil, floatingQuestItemBtn, "CooldownFrameTemplate")
floatingQuestItemBtn.cooldown:SetAllPoints()
floatingQuestItemBtn:SetScript("OnEnter", function(self)
    if self._itemLink and GameTooltip then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        pcall(GameTooltip.SetHyperlink, GameTooltip, self._itemLink)
        GameTooltip:Show()
    end
end)
floatingQuestItemBtn:SetScript("OnLeave", function(self)
    if GameTooltip and GameTooltip:GetOwner() == self then GameTooltip:Hide() end
end)

local function UpdateFloatingQuestItem(questsFlat)
    if not addon.GetDB("showFloatingQuestItem", false) then
        floatingQuestItemBtn:Hide()
        return
    end
    local superTracked = (C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID) and C_SuperTrack.GetSuperTrackedQuestID() or 0
    local chosenLink, chosenTex
    for _, q in ipairs(questsFlat or {}) do
        if q.questID and q.itemLink and q.itemTexture then
            if q.questID == superTracked then
                chosenLink, chosenTex = q.itemLink, q.itemTexture
                break
            end
            if not chosenLink then chosenLink, chosenTex = q.itemLink, q.itemTexture end
        end
    end
    if chosenLink and chosenTex then
        floatingQuestItemBtn.icon:SetTexture(chosenTex)
        if not InCombatLockdown() then
            floatingQuestItemBtn:SetAttribute("item", chosenLink)
        end
        floatingQuestItemBtn._itemLink = chosenLink
        local sz = tonumber(addon.GetDB("floatingQuestItemSize", 36)) or 36
        floatingQuestItemBtn:SetSize(sz, sz)
        local anchor = addon.GetDB("floatingQuestItemAnchor", "LEFT") or "LEFT"
        local ox = tonumber(addon.GetDB("floatingQuestItemOffsetX", -12)) or -12
        local oy = tonumber(addon.GetDB("floatingQuestItemOffsetY", 0)) or 0
        floatingQuestItemBtn:ClearAllPoints()
        if anchor == "LEFT" then
            floatingQuestItemBtn:SetPoint("RIGHT", addon.MQT, "LEFT", ox, oy)
        elseif anchor == "RIGHT" then
            floatingQuestItemBtn:SetPoint("LEFT", addon.MQT, "RIGHT", ox, oy)
        elseif anchor == "TOP" then
            floatingQuestItemBtn:SetPoint("BOTTOM", addon.MQT, "TOP", ox, oy)
        else
            floatingQuestItemBtn:SetPoint("TOP", addon.MQT, "BOTTOM", ox, oy)
        end
        floatingQuestItemBtn:Show()
        addon.ApplyItemCooldown(floatingQuestItemBtn.cooldown, chosenLink)
    else
        floatingQuestItemBtn:Hide()
    end
end

addon.UpdateFloatingQuestItem = UpdateFloatingQuestItem
