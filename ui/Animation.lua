--[[
    Horizon Suite - Focus - Animation Engine
    HS OnUpdate: height lerp, entry fade/slide/collapse, objective flash, auto-hide.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- ANIMATION ENGINE
-- ============================================================================

local HS          = addon.HS
local pool         = addon.pool
local scrollChild  = addon.scrollChild
local scrollFrame  = addon.scrollFrame

local function SetPanelHeight(h)
    if InCombatLockdown() then return end
    if addon.GetDB("growUp", false) then
        HS:SetHeight(h)
        return
    end
    local topBefore = HS:GetTop()
    if not topBefore then return end
    HS:SetHeight(h)
    local topAfter = HS:GetTop()
    if not topAfter then return end
    local drift = topAfter - topBefore
    if math.abs(drift) < 0.1 then return end
    local uiTop   = UIParent:GetTop()   or 0
    local uiRight = UIParent:GetRight() or 0
    local right   = HS:GetRight()      or 0
    HS:ClearAllPoints()
    HS:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", right - uiRight, topBefore - uiTop)
end

local function UpdateMapCheck(dt)
    if not addon.enabled or not C_Map or not C_Map.GetBestMapForUnit then return end
    addon.lastMapCheckTime = addon.lastMapCheckTime + dt
    if addon.lastMapCheckTime >= 0.5 then
        addon.lastMapCheckTime = 0
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID and mapID ~= addon.lastPlayerMapID then
            addon.lastPlayerMapID = mapID
            if addon.ScheduleRefresh then addon.ScheduleRefresh() end
        elseif not addon.lastPlayerMapID and mapID then
            addon.lastPlayerMapID = mapID
        end
    end
end

local function UpdatePanelHeight(dt)
    local targetHeight  = addon.targetHeight
    local currentHeight = addon.currentHeight
    if math.abs(currentHeight - targetHeight) > 0.5 then
        addon.currentHeight = currentHeight + (targetHeight - currentHeight) * math.min(addon.HEIGHT_SPEED * dt, 1)
        SetPanelHeight(addon.currentHeight)
    elseif currentHeight ~= targetHeight then
        addon.currentHeight = targetHeight
        SetPanelHeight(addon.currentHeight)
    end
end

local function UpdateCombatFade(dt, useAnim)
    local combatState = addon.combatFadeState
    if not combatState then return end
    local dur = addon.COMBAT_FADE_DUR or 0.4
    addon.combatFadeTime = addon.combatFadeTime + dt
    local floatingBtn = _G.HSFloatingQuestItem

    if combatState == "out" then
        if not useAnim then
            HS:Hide()
            if floatingBtn then floatingBtn:Hide() end
            if addon.UpdateFloatingQuestItem then addon.UpdateFloatingQuestItem(nil) end
            if addon.UpdateMplusBlock then addon.UpdateMplusBlock() end
            addon.combatFadeState = nil
            addon.combatFadeTime = 0
        else
            local p = math.min(addon.combatFadeTime / dur, 1)
            HS:SetAlpha(1 - p)
            if floatingBtn and floatingBtn:IsShown() then floatingBtn:SetAlpha(1 - p) end
            if p >= 1 then
                HS:Hide()
                if floatingBtn then floatingBtn:Hide() end
                if addon.UpdateFloatingQuestItem then addon.UpdateFloatingQuestItem(nil) end
                if addon.UpdateMplusBlock then addon.UpdateMplusBlock() end
                addon.combatFadeState = nil
                addon.combatFadeTime = 0
            end
        end
    elseif combatState == "in" then
        if not useAnim then
            HS:SetAlpha(1)
            if floatingBtn and floatingBtn:IsShown() then floatingBtn:SetAlpha(1) end
            addon.combatFadeState = nil
            addon.combatFadeTime = 0
        else
            local p = math.min(addon.combatFadeTime / dur, 1)
            if HS:IsShown() then HS:SetAlpha(p) end
            if floatingBtn and floatingBtn:IsShown() then floatingBtn:SetAlpha(p) end
            if p >= 1 then
                HS:SetAlpha(1)
                if floatingBtn and floatingBtn:IsShown() then floatingBtn:SetAlpha(1) end
                addon.combatFadeState = nil
                addon.combatFadeTime = 0
            end
        end
    end
end

local function UpdateEntryAnimations(dt, useAnim)
    local anyAnimating = false
    for i = 1, addon.POOL_SIZE do
        local e = pool[i]

        if e.animState == "fadein" then
            e.animTime = e.animTime + dt
            if not useAnim then
                e:SetAlpha(1)
                if not InCombatLockdown() then
                    e:ClearAllPoints()
                    e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX, e.finalY)
                end
                e.animState = "active"
            elseif e.animTime < e.staggerDelay then
                e:SetAlpha(0)
            else
                local t = e.animTime - e.staggerDelay
                local p = math.min(t / addon.FADE_IN_DUR, 1)
                local ep = addon.easeOut(p)
                e:SetAlpha(ep)
                if not InCombatLockdown() then
                    local slideX = (1 - ep) * addon.SLIDE_IN_X
                    e:ClearAllPoints()
                    e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX + slideX, e.finalY)
                end
                if p >= 1 then
                    e:SetAlpha(1)
                    if not InCombatLockdown() then
                        e:ClearAllPoints()
                        e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX, e.finalY)
                    end
                    e.animState = "active"
                end
            end
            anyAnimating = true

        elseif e.animState == "completing" then
            e.animTime = e.animTime + dt
            if e.animTime >= addon.COMPLETE_HOLD then
                e.animState = "fadeout"
                e.animTime  = 0
            end
            anyAnimating = true

        elseif e.animState == "fadeout" then
            e.animTime = e.animTime + dt
            if not useAnim then
                addon.ClearEntry(e)
            else
                local p  = math.min(e.animTime / addon.FADE_OUT_DUR, 1)
                local ep = addon.easeIn(p)
                e:SetAlpha(1 - ep)
                if not InCombatLockdown() then
                    local driftY = ep * addon.DRIFT_OUT_Y
                    e:ClearAllPoints()
                    e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX, e.finalY + driftY)
                end
                if p >= 1 then
                    addon.ClearEntry(e)
                end
            end
            anyAnimating = true

        elseif e.animState == "collapsing" then
            e.animTime = e.animTime + dt
            if not useAnim and e.animTime >= (e.collapseDelay or 0) then
                addon.ClearEntry(e)
            elseif e.animTime < e.collapseDelay then
                -- waiting
            else
                local t = e.animTime - e.collapseDelay
                local p = math.min(t / addon.COLLAPSE_DUR, 1)
                local ep = addon.easeIn(p)
                e:SetAlpha(1 - ep)
                if not InCombatLockdown() then
                    local slideX = ep * addon.SLIDE_OUT_X
                    e:ClearAllPoints()
                    e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX + slideX, e.finalY)
                end
                if p >= 1 then
                    addon.ClearEntry(e)
                end
            end
            anyAnimating = true
        end

        if e.flashTime > 0 then
            e.flashTime = e.flashTime - dt
            local fp = math.max(e.flashTime / addon.FLASH_DUR, 0)
            e.flash:SetColorTexture(1, 1, 1, fp * 0.12)
            anyAnimating = true
        end
    end
    return anyAnimating
end

local function UpdateCollapseAnimations()
    if not addon.collapseAnimating then return end
    local stillCollapsing = false
    for i = 1, addon.POOL_SIZE do
        if pool[i].animState == "collapsing" then
            stillCollapsing = true
            break
        end
    end
    if not stillCollapsing then
        addon.collapseAnimating = false
        for i = 1, addon.POOL_SIZE do
            if pool[i].animState == "idle" and (pool[i].questID or pool[i].entryKey) then
                addon.ClearEntry(pool[i], false)
            end
        end
        wipe(addon.activeMap)
        if addon.GetDB("showSectionHeadersWhenCollapsed", false) then
            if addon.FullLayout then addon.FullLayout() end
        else
            scrollFrame:Hide()
            addon.targetHeight = addon.GetCollapsedHeight()
        end
    end
end

-- Group collapse completion: when no entries in a group are collapsing anymore,
-- mark that group as collapsed and trigger a layout refresh.
local function UpdateGroupCollapseCompletion()
    if not addon.groupCollapses then return end
    for groupKey, startTime in pairs(addon.groupCollapses) do
            local stillCollapsing = false
            for i = 1, addon.POOL_SIZE do
                local e = pool[i]
                if e.groupKey == groupKey and e.animState == "collapsing" then
                    stillCollapsing = true
                    break
                end
            end

            -- Safety timeout in case something goes wrong with anim state.
            local timedOut = (GetTime() - startTime) > 2

            if not stillCollapsing or timedOut then
                addon.groupCollapses[groupKey] = nil

                -- Clean up any lingering collapsing entries for this group.
                for i = 1, addon.POOL_SIZE do
                    local e = pool[i]
                    if e.groupKey == groupKey and e.animState == "collapsing" then
                        addon.ClearEntry(e)
                    end
                end

                -- Re-run layout so remaining groups close up the gap.
                if addon.FullLayout then
                    addon.FullLayout()
                end

                -- Only handle one group per frame; others will be processed next tick.
                break
            end
        end
end

--- OnUpdate: map check, panel height lerp, combat fade, entry/collapse animations, auto-hide when empty.
-- @param _ table Frame (unused)
-- @param dt number Elapsed time since last frame
HS:SetScript("OnUpdate", function(_, dt)
    local useAnim = addon.GetDB("animations", true)
    UpdateMapCheck(dt)
    UpdatePanelHeight(dt)
    UpdateCombatFade(dt, useAnim)
    local anyAnimating = UpdateEntryAnimations(dt, useAnim)
    UpdateCollapseAnimations()
    UpdateGroupCollapseCompletion()

    if not anyAnimating then
        local hasActive = false
        for i = 1, addon.POOL_SIZE do
            if pool[i].questID or pool[i].entryKey then hasActive = true; break end
        end
        if not hasActive and not addon.collapsed then
            HS:Hide()
        end
    end
end)
