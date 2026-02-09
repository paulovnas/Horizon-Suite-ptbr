--[[
    Horizon Suite - Focus - Layout Engine
    PopulateEntry, FullLayout, ToggleCollapse, AcquireEntry, section headers, header button, keybind, floating item, M+ block.
]]

local addon = _G.ModernQuestTracker

-- ============================================================================
-- LAYOUT ENGINE
-- ============================================================================

addon.targetHeight  = addon.MIN_HEIGHT
addon.currentHeight = addon.MIN_HEIGHT

local pool       = addon.pool
local activeMap  = addon.activeMap
local sectionPool = addon.sectionPool
local scrollChild = addon.scrollChild
local scrollFrame = addon.scrollFrame

local function PopulateEntry(entry, questData)
    local hasItem = questData.itemTexture and true or false
    local showItemBtn = hasItem and addon.GetDB("showQuestItemButtons", true)
    local showQuestIcons = addon.GetDB("showQuestTypeIcons", true)
    local hasIcon = questData.questTypeAtlas and showQuestIcons

    local textWidth = addon.GetPanelWidth() - addon.PADDING * 2 - (addon.CONTENT_RIGHT_PADDING or 0)
    if showItemBtn then
        textWidth = textWidth - addon.ITEM_BTN_SIZE - addon.ITEM_BTN_OFFSET
    end

    if hasIcon then
        entry.questTypeIcon:SetAtlas(questData.questTypeAtlas)
        entry.questTypeIcon:Show()
    else
        entry.questTypeIcon:Hide()
    end

    entry.titleText:ClearAllPoints()
    entry.titleText:SetPoint("TOPLEFT", entry, "TOPLEFT", 0, 0)
    entry.titleShadow:ClearAllPoints()
    entry.titleShadow:SetPoint("CENTER", entry.titleText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

    entry.titleText:SetWidth(textWidth)
    entry.titleShadow:SetWidth(textWidth)

    entry.titleText:SetText(questData.title)
    entry.titleShadow:SetText(questData.title)
    local c = questData.color
    if questData.isDungeonQuest and not questData.isTracked then
        c = { c[1] * 0.65, c[2] * 0.65, c[3] * 0.65 }
    end
    entry.titleText:SetTextColor(c[1], c[2], c[3], 1)

    local rawHighlight = addon.GetDB("activeQuestHighlight", "bar")
    local highlightStyle = (rawHighlight == "bar") and "bar" or "highlight"
    local hc = addon.GetDB("highlightColor", nil)
    if not hc or #hc < 3 then hc = { 0.40, 0.70, 1.00 } end
    local ha = tonumber(addon.GetDB("highlightAlpha", 0.25)) or 0.25
    local function hideHighlightBorders()
        entry.highlightBorderT:Hide()
        entry.highlightBorderB:Hide()
        entry.highlightBorderL:Hide()
        entry.highlightBorderR:Hide()
    end
    if questData.isSuperTracked then
        if highlightStyle == "bar" then
            entry.trackBar:SetColorTexture(hc[1], hc[2], hc[3], 0.80)
            entry.trackBar:Show()
            entry.highlightBg:Hide()
            if entry.highlightTop then entry.highlightTop:Hide() end
            hideHighlightBorders()
        else
            -- Highlight style: inset bg + border + top strip
            entry.trackBar:Hide()
            entry.highlightBg:SetColorTexture(hc[1], hc[2], hc[3], ha)
            entry.highlightBg:Show()
            if entry.highlightTop then
                local topAlpha = math.min(1, ha + 0.2)
                entry.highlightTop:SetColorTexture(hc[1], hc[2], hc[3], topAlpha)
                entry.highlightTop:Show()
            end
            local borderAlpha = math.min(1, (ha + 0.35))
            for _, tex in ipairs({ entry.highlightBorderT, entry.highlightBorderB, entry.highlightBorderL, entry.highlightBorderR }) do
                tex:SetColorTexture(hc[1], hc[2], hc[3], borderAlpha)
                tex:Show()
            end
        end
    else
        entry.trackBar:Hide()
        entry.highlightBg:Hide()
        if entry.highlightTop then entry.highlightTop:Hide() end
        hideHighlightBorders()
    end

    if showItemBtn then
        entry.itemLink = questData.itemLink
        entry.itemBtn.icon:SetTexture(questData.itemTexture)
        if not InCombatLockdown() then
            entry.itemBtn:SetAttribute("type", "item")
            entry.itemBtn:SetAttribute("item", questData.itemLink)
        end
        entry.itemBtn:Show()
        addon.ApplyItemCooldown(entry.itemBtn.cooldown, questData.itemLink)
    else
        entry.itemLink = nil
        entry.itemBtn:Hide()
        if not InCombatLockdown() then
            entry.itemBtn:SetAttribute("item", nil)
        end
    end

    local titleH = entry.titleText:GetStringHeight()
    if not titleH or titleH < 1 then titleH = addon.TITLE_SIZE + 4 end
    local totalH = titleH

    local prevAnchor = entry.titleText
    if addon.GetDB("showZoneLabels", true) and questData.zoneName and not questData.isNearby then
        entry.zoneText:SetText(questData.zoneName)
        entry.zoneShadow:SetText(questData.zoneName)
        local zoneColor = addon.GetDB("zoneColor", nil)
        if not zoneColor or #zoneColor < 3 then zoneColor = addon.ZONE_COLOR end
        entry.zoneText:SetTextColor(zoneColor[1], zoneColor[2], zoneColor[3], 1)
        entry.zoneText:ClearAllPoints()
        entry.zoneText:SetPoint("TOPLEFT", entry.titleText, "BOTTOMLEFT", addon.OBJ_INDENT, -addon.OBJ_SPACING)
        entry.zoneText:Show()
        entry.zoneShadow:Show()
        local zoneH = entry.zoneText:GetStringHeight()
        if not zoneH or zoneH < 1 then zoneH = addon.ZONE_SIZE + 2 end
        totalH = totalH + addon.OBJ_SPACING + zoneH
        prevAnchor = entry.zoneText
    else
        entry.zoneText:Hide()
        entry.zoneShadow:Hide()
    end

    local shownObjs  = 0
    local objTextWidth = textWidth - addon.OBJ_INDENT
    if objTextWidth < 1 then objTextWidth = addon.GetPanelWidth() - addon.PADDING * 2 - addon.OBJ_INDENT - (addon.CONTENT_RIGHT_PADDING or 0) end

    local objColor = addon.GetDB("objectiveColor", nil)
    if not objColor or #objColor < 3 then objColor = c end
    local doneColor = addon.GetDB("objectiveDoneColor", nil)
    if not doneColor or #doneColor < 3 then doneColor = addon.OBJ_DONE_COLOR end

    for j = 1, addon.MAX_OBJECTIVES do
        local obj = entry.objectives[j]
        local oData = questData.objectives[j]

        obj.text:SetWidth(objTextWidth)
        obj.shadow:SetWidth(objTextWidth)

        if oData then
            obj.text:SetText(oData.text or "")
            obj.shadow:SetText(oData.text or "")

            if oData.finished then
                obj.text:SetTextColor(doneColor[1], doneColor[2], doneColor[3], 1)
            else
                obj.text:SetTextColor(objColor[1], objColor[2], objColor[3], 1)
            end

            obj.text:ClearAllPoints()
            local indent = (shownObjs == 0 and prevAnchor == entry.titleText) and addon.OBJ_INDENT or 0
            obj.text:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", indent, -addon.OBJ_SPACING)
            obj.text:Show()
            obj.shadow:Show()

            local objH = obj.text:GetStringHeight()
            if not objH or objH < 1 then objH = addon.OBJ_SIZE + 2 end
            totalH = totalH + addon.OBJ_SPACING + objH

            prevAnchor = obj.text
            shownObjs  = shownObjs + 1
        else
            obj.text:Hide()
            obj.shadow:Hide()
        end
    end

    if questData.isComplete and shownObjs == 0 then
        local obj = entry.objectives[1]
        obj.text:SetText("Ready to turn in")
        obj.shadow:SetText("Ready to turn in")
        obj.text:SetTextColor(doneColor[1], doneColor[2], doneColor[3], 1)
        obj.text:ClearAllPoints()
        local turnInIndent = (prevAnchor == entry.titleText) and addon.OBJ_INDENT or 0
        obj.text:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", turnInIndent, -addon.OBJ_SPACING)
        obj.text:Show()
        obj.shadow:Show()
        local objH = obj.text:GetStringHeight()
        if not objH or objH < 1 then objH = addon.OBJ_SIZE + 2 end
        totalH = totalH + addon.OBJ_SPACING + objH
    end

    entry.trackBar:SetHeight(math.max(totalH, 1))
    entry.entryHeight = totalH
    entry:SetHeight(totalH)
    if questData.isRare then
        entry.questID    = nil
        entry.entryKey   = questData.entryKey
        entry.creatureID = questData.creatureID
        entry.itemLink   = nil
        entry.isTracked  = nil
    else
        entry.questID    = questData.questID
        entry.entryKey   = nil
        entry.creatureID = nil
        entry.isTracked  = questData.isTracked
    end
    return totalH
end

local function AcquireEntry()
    for i = 1, addon.POOL_SIZE do
        if pool[i].animState == "idle" and not pool[i].questID and not pool[i].entryKey then
            return pool[i]
        end
    end
    for i = 1, addon.POOL_SIZE do
        if pool[i].animState == "fadeout" then
            addon.ClearEntry(pool[i])
            return pool[i]
        end
    end
    return nil
end

local function HideAllSectionHeaders()
    for i = 1, addon.SECTION_POOL_SIZE do
        sectionPool[i].active = false
        sectionPool[i]:Hide()
        sectionPool[i]:SetAlpha(0)
    end
end

addon.sectionIdx = 0
local function AcquireSectionHeader(groupKey)
    addon.sectionIdx = addon.sectionIdx + 1
    if addon.sectionIdx > addon.SECTION_POOL_SIZE then return nil end
    local s = sectionPool[addon.sectionIdx]
    local label = addon.SECTION_LABELS[groupKey] or groupKey
    if groupKey == "DUNGEON" and addon.IsInMythicDungeon() then
        local dungeonName = addon.GetMythicDungeonName()
        if dungeonName and dungeonName ~= "" then
            label = label .. " — " .. dungeonName
        end
    end
    local color = addon.GetSectionColor(groupKey)
    s.text:SetText(label)
    s.shadow:SetText(label)
    s.text:SetTextColor(color[1], color[2], color[3], addon.SECTION_COLOR_A)
    s.active = true
    s:SetAlpha(1)
    s:Show()
    return s
end

local function ToggleCollapse()
    if addon.collapseAnimating then
        if (GetTime() - addon.collapseAnimStart) < 2 then return end
        addon.collapseAnimating = false
        for i = 1, addon.POOL_SIZE do
            if pool[i].animState == "collapsing" then
                addon.ClearEntry(pool[i])
            end
        end
        wipe(activeMap)
        scrollFrame:Hide()
        addon.targetHeight = addon.GetCollapsedHeight()
    end

    addon.collapsed = not addon.collapsed
    if addon.collapsed then
        addon.chevron:SetText("+")

        local visibleEntries = {}
        for i = 1, addon.POOL_SIZE do
            local e = pool[i]
            if (e.questID or e.entryKey) and (e.animState == "active" or e.animState == "fadein") then
                visibleEntries[#visibleEntries + 1] = e
            end
        end

        table.sort(visibleEntries, function(a, b) return a.finalY < b.finalY end)

        for idx, e in ipairs(visibleEntries) do
            e.animState     = "collapsing"
            e.animTime      = 0
            e.collapseDelay = 0
        end

        for i = 1, addon.SECTION_POOL_SIZE do
            if sectionPool[i].active then
                sectionPool[i]:SetAlpha(0)
                sectionPool[i]:Hide()
                sectionPool[i].active = false
            end
        end

        addon.collapseAnimating = #visibleEntries > 0
        addon.collapseAnimStart = GetTime()
        if not addon.collapseAnimating then
            scrollFrame:Hide()
            addon.targetHeight = addon.GetCollapsedHeight()
        end
    else
        addon.chevron:SetText("-")
        scrollFrame:Show()
        addon.FullLayout()
    end
    addon.EnsureDB()
    ModernQuestTrackerDB.collapsed = addon.collapsed
end

local headerBtn = CreateFrame("Button", nil, addon.MQT)
headerBtn:SetPoint("TOPLEFT", addon.MQT, "TOPLEFT", 0, 0)
headerBtn:SetPoint("TOPRIGHT", addon.MQT, "TOPRIGHT", 0, 0)
headerBtn:SetHeight(addon.PADDING + addon.HEADER_HEIGHT)
headerBtn:RegisterForClicks("LeftButtonUp")
headerBtn:SetScript("OnClick", function()
    ToggleCollapse()
end)
headerBtn:RegisterForDrag("LeftButton")
headerBtn:SetScript("OnDragStart", function()
    if ModernQuestTrackerDB and ModernQuestTrackerDB.lockPosition then return end
    addon.MQT:StartMoving()
end)
headerBtn:SetScript("OnDragStop", function()
    if ModernQuestTrackerDB and ModernQuestTrackerDB.lockPosition then return end
    addon.MQT:StopMovingOrSizing()
    addon.MQT:SetUserPlaced(false)
    addon.SavePanelPosition()
end)

local collapseKeybindBtn = CreateFrame("Button", "MQTCollapseButton", nil)
collapseKeybindBtn:SetScript("OnClick", function()
    ToggleCollapse()
end)
collapseKeybindBtn:RegisterForClicks("AnyUp")


local function ShouldShowInInstance()
    local inType = select(2, GetInstanceInfo())
    if inType == "none" then return true end
    if inType == "party"  then return addon.GetDB("showInDungeon", false) end
    if inType == "raid"   then return addon.GetDB("showInRaid", false) end
    if inType == "pvp"    then return addon.GetDB("showInBattleground", false) end
    if inType == "arena"  then return addon.GetDB("showInArena", false) end
    return true
end

local function FullLayout()
    if not addon.enabled then return end
    if InCombatLockdown() then
        addon.layoutPendingAfterCombat = true
        return
    end
    addon.layoutPendingAfterCombat = false

    if not ShouldShowInInstance() then
        addon.MQT:Hide()
        addon.UpdateFloatingQuestItem(nil)
        addon.UpdateMplusBlock()
        return
    end

    if addon.GetDB("growUp", false) then
        addon.ApplyGrowUpAnchor()
    end

    local minimal = addon.GetDB("hideObjectivesHeader", false)
    if minimal then
        addon.headerText:Hide()
        addon.headerShadow:Hide()
        addon.countText:Hide()
        addon.countShadow:Hide()
        addon.chevron:Hide()
        addon.optionsBtn:Hide()
        addon.divider:Hide()
        headerBtn:SetHeight(8)
    else
        addon.headerText:Show()
        addon.headerShadow:Show()
        if addon.GetDB("showQuestCount", true) then addon.countText:Show(); addon.countShadow:Show() else addon.countText:Hide(); addon.countShadow:Hide() end
        addon.chevron:Show()
        addon.optionsBtn:Show()
        addon.divider:SetShown(addon.GetDB("showHeaderDivider", true))
        headerBtn:SetHeight(addon.PADDING + addon.HEADER_HEIGHT)
    end
    scrollFrame:ClearAllPoints()
    scrollFrame:SetPoint("TOPLEFT", addon.MQT, "TOPLEFT", 0, addon.GetContentTop())
    scrollFrame:SetPoint("BOTTOMRIGHT", addon.MQT, "BOTTOMRIGHT", 0, addon.PADDING)

    addon.UpdateMplusBlock()

    local rares = addon.GetDB("showRareBosses", true) and addon.GetRaresOnMap() or {}
    if #rares > 0 then
        local currentRareKeys = {}
        for _, r in ipairs(rares) do currentRareKeys[r.entryKey or r.questID] = true end
        if addon.rareTrackingInit and not addon.zoneJustChanged then
            for key in pairs(currentRareKeys) do
                if not addon.prevRareKeys[key] and PlaySound and addon.GetDB("rareAddedSound", true) then
                    pcall(PlaySound, addon.RARE_ADDED_SOUND)
                    break
                end
            end
        end
        if addon.zoneJustChanged then addon.zoneJustChanged = false end
        addon.rareTrackingInit = true
        addon.prevRareKeys = currentRareKeys
    else
        addon.prevRareKeys = {}
    end

    if addon.collapsed then
        scrollFrame:Hide()
        addon.targetHeight = addon.GetCollapsedHeight()
        local quests = addon.ReadTrackedQuests()
        for _, r in ipairs(rares) do quests[#quests + 1] = r end
        addon.UpdateFloatingQuestItem(quests)
        addon.UpdateHeaderQuestCount(#quests)
        if #quests > 0 then addon.MQT:Show() end
        return
    end

    scrollFrame:Show()

    local quests  = addon.ReadTrackedQuests()
    for _, r in ipairs(rares) do quests[#quests + 1] = r end
    addon.UpdateFloatingQuestItem(quests)
    local grouped = addon.SortAndGroupQuests(quests)

    local currentIDs = {}
    for _, q in ipairs(quests) do
        currentIDs[q.entryKey or q.questID] = true
    end

    for key, entry in pairs(activeMap) do
        if not currentIDs[key] then
            if entry.animState ~= "completing" and entry.animState ~= "fadeout" then
                entry.animState = "fadeout"
                entry.animTime  = 0
            end
            activeMap[key] = nil
        end
    end

    for _, grp in ipairs(grouped) do
        for _, qData in ipairs(grp.quests) do
            local key = qData.entryKey or qData.questID
            local entry = activeMap[key]
            if not entry then
                entry = AcquireEntry()
                if entry then
                    entry.animState = "fadein"
                    entry.animTime  = 0
                    activeMap[key] = entry
                end
            end
            if entry then
                PopulateEntry(entry, qData)
            end
        end
    end

    HideAllSectionHeaders()
    addon.sectionIdx = 0

    local yOff = 0
    local entryIndex = 0

    local showSections = #grouped > 1 and addon.GetDB("showSectionHeaders", true)

    for gi, grp in ipairs(grouped) do
        if showSections then
            if gi > 1 then
                yOff = yOff - addon.SECTION_SPACING
            end
            local sec = AcquireSectionHeader(grp.key)
            if sec then
                sec:ClearAllPoints()
                sec:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", addon.PADDING + addon.ICON_COLUMN_WIDTH, yOff)
                yOff = yOff - (addon.SECTION_SIZE + 4) - 2
            end
        end

        for _, qData in ipairs(grp.quests) do
            local key = qData.entryKey or qData.questID
            local entry = activeMap[key]
            if entry then
                entry.finalX = addon.PADDING + addon.ICON_COLUMN_WIDTH
                entry.finalY = yOff
                entry.staggerDelay = entryIndex * addon.ENTRY_STAGGER
                entryIndex = entryIndex + 1

                entry:ClearAllPoints()
                entry:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", addon.PADDING + addon.ICON_COLUMN_WIDTH, yOff)
                entry:Show()
                yOff = yOff - entry.entryHeight - addon.TITLE_SPACING
            end
        end
    end

    addon.UpdateHeaderQuestCount(#quests)

    local totalContentH = math.max(-yOff, 1)
    scrollChild:SetHeight(totalContentH)

    addon.scrollOffset = 0
    scrollFrame:SetVerticalScroll(0)

    local headerArea    = addon.PADDING + addon.HEADER_HEIGHT + addon.DIVIDER_HEIGHT + 6
    local visibleH      = math.min(totalContentH, addon.GetMaxContentHeight())
    addon.targetHeight  = math.max(addon.MIN_HEIGHT, headerArea + visibleH + addon.PADDING)

    if #quests > 0 then
        addon.MQT:Show()
    end
end

addon.PopulateEntry       = PopulateEntry
addon.AcquireEntry       = AcquireEntry
addon.HideAllSectionHeaders = HideAllSectionHeaders
addon.AcquireSectionHeader = AcquireSectionHeader
addon.ToggleCollapse      = ToggleCollapse
addon.FullLayout         = FullLayout
