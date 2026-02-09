--[[
    Horizon Suite - Focus - Animation Engine
    MQT OnUpdate: height lerp, entry fade/slide/collapse, objective flash, auto-hide.
]]

local addon = _G.ModernQuestTracker

-- ============================================================================
-- ANIMATION ENGINE
-- ============================================================================

local MQT         = addon.MQT
local pool         = addon.pool
local scrollChild  = addon.scrollChild
local scrollFrame  = addon.scrollFrame

local function SetPanelHeight(h)
    if InCombatLockdown() then return end
    if addon.GetDB("growUp", false) then
        MQT:SetHeight(h)
        return
    end
    local topBefore = MQT:GetTop()
    if not topBefore then return end
    MQT:SetHeight(h)
    local topAfter = MQT:GetTop()
    if not topAfter then return end
    local drift = topAfter - topBefore
    if math.abs(drift) < 0.1 then return end
    local uiTop   = UIParent:GetTop()   or 0
    local uiRight = UIParent:GetRight() or 0
    local right   = MQT:GetRight()      or 0
    MQT:ClearAllPoints()
    MQT:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", right - uiRight, topBefore - uiTop)
end

MQT:SetScript("OnUpdate", function(self, dt)
    if addon.enabled and C_Map and C_Map.GetBestMapForUnit then
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

    local targetHeight  = addon.targetHeight
    local currentHeight = addon.currentHeight
    if math.abs(currentHeight - targetHeight) > 0.5 then
        addon.currentHeight = currentHeight + (targetHeight - currentHeight) * math.min(addon.HEIGHT_SPEED * dt, 1)
        SetPanelHeight(addon.currentHeight)
    elseif currentHeight ~= targetHeight then
        addon.currentHeight = targetHeight
        SetPanelHeight(addon.currentHeight)
    end

    local anyAnimating = false
    local useAnim = addon.GetDB("animations", true)
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

    if addon.collapseAnimating then
        local stillCollapsing = false
        for i = 1, addon.POOL_SIZE do
            if pool[i].animState == "collapsing" then
                stillCollapsing = true
                break
            end
        end
        if not stillCollapsing then
            addon.collapseAnimating = false
            scrollFrame:Hide()
            addon.targetHeight = addon.GetCollapsedHeight()
            for i = 1, addon.POOL_SIZE do
                if pool[i].animState == "idle" and (pool[i].questID or pool[i].entryKey) then
                    addon.ClearEntry(pool[i], false)
                end
            end
            wipe(addon.activeMap)
        end
    end

    if not anyAnimating then
        local hasActive = false
        for i = 1, addon.POOL_SIZE do
            if pool[i].questID or pool[i].entryKey then hasActive = true; break end
        end
        if not hasActive and not addon.collapsed then
            MQT:Hide()
        end
    end
end)
