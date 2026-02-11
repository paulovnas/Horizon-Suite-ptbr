--[[
    Horizon Suite - Focus - Options Panel
    Main panel frame, title bar, search bar, sidebar, content scroll, BuildCategory, FilterBySearch, animations.
]]

local addon = _G.HorizonSuite
if not addon or not addon.OptionCategories then return end

local Def = addon.OptionsWidgetsDef or {}
local PAGE_WIDTH = 700
local PAGE_HEIGHT = 580
local SIDEBAR_WIDTH = 160
local PADDING = 14
local SCROLL_STEP = 40
local HEADER_HEIGHT = PADDING + (Def.HeaderSize or 16) + 6 + 2
local DIVIDER_HEIGHT = 2
local OptionGap = 10
local SectionGap = 16
local CardPadding = 12
local RowHeights = { sectionLabel = 14, toggle = 36, slider = 40, dropdown = 52, colorRow = 28, reorder = 24 }

local SetTextColor = addon.SetTextColor or function(obj, color)
    if not color or not obj then return end
    obj:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local function getDB(k, d) return addon.OptionsData_GetDB(k, d) end
local function setDB(k, v) return addon.OptionsData_SetDB(k, v) end
local function notifyMainAddon() return addon.OptionsData_NotifyMainAddon() end

-- ---------------------------------------------------------------------------
-- Panel frame
-- ---------------------------------------------------------------------------
local panel = CreateFrame("Frame", "HorizonSuiteOptionsPanel", UIParent)
panel.name = "Horizon Suite - Focus"
panel:SetSize(PAGE_WIDTH, PAGE_HEIGHT)
panel:SetFrameStrata("DIALOG")
panel:SetClampedToScreen(true)
panel:SetMovable(true)
panel:RegisterForDrag("LeftButton")
panel:Hide()

local bg = panel:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(panel)
bg:SetColorTexture(Def.SectionCardBg and Def.SectionCardBg[1] or 0.10, Def.SectionCardBg and Def.SectionCardBg[2] or 0.10, Def.SectionCardBg and Def.SectionCardBg[3] or 0.15, Def.SectionCardBg and Def.SectionCardBg[4] or 0.95)
local bc = Def.BorderColor or Def.SectionCardBorder
addon.CreateBorder(panel, bc)

-- Title bar
local titleBar = CreateFrame("Frame", nil, panel)
titleBar:SetPoint("TOPLEFT", 0, 0)
titleBar:SetPoint("TOPRIGHT", 0, 0)
titleBar:SetHeight(HEADER_HEIGHT)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function() panel:StartMoving() end)
titleBar:SetScript("OnDragStop", function()
    panel:StopMovingOrSizing()
    if HorizonDB then
        local x, y = panel:GetCenter()
        local uix, uiy = UIParent:GetCenter()
        HorizonDB.optionsLeft = x - uix
        HorizonDB.optionsTop = y - uiy
    end
end)
local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
titleBg:SetAllPoints(titleBar)
titleBg:SetColorTexture(0.06, 0.06, 0.10, 0.95)
local titleText = titleBar:CreateFontString(nil, "OVERLAY")
titleText:SetFont(Def.FontPath or "Fonts\\FRIZQT__.TTF", Def.HeaderSize or 16, "OUTLINE")
SetTextColor(titleText, Def.TextColorTitleBar or Def.TextColorNormal)
titleText:SetPoint("TOPLEFT", titleBar, "TOPLEFT", PADDING, -PADDING)
titleText:SetText("HORIZON SUITE")
local closeBtn = CreateFrame("Button", nil, panel)
closeBtn:SetSize(44, 22)
closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PADDING, -PADDING)
closeBtn:SetFrameLevel(titleBar:GetFrameLevel() + 2)  -- above title bar so clicks reach the button
local closeLabel = closeBtn:CreateFontString(nil, "OVERLAY")
closeLabel:SetFont(Def.FontPath or "Fonts\\FRIZQT__.TTF", Def.LabelSize or 13, "OUTLINE")
SetTextColor(closeLabel, Def.TextColorLabel)
closeLabel:SetText("Close")
closeLabel:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
closeBtn:SetScript("OnClick", function()
    if _G.HorizonSuite_OptionsRequestClose then _G.HorizonSuite_OptionsRequestClose() else panel:Hide() end
end)
closeBtn:SetScript("OnEnter", function() SetTextColor(closeLabel, Def.TextColorHighlight) end)
closeBtn:SetScript("OnLeave", function() SetTextColor(closeLabel, Def.TextColorLabel) end)
local divider = panel:CreateTexture(nil, "ARTWORK")
divider:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
divider:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
divider:SetHeight(DIVIDER_HEIGHT)
divider:SetColorTexture(Def.AccentColor[1], Def.AccentColor[2], Def.AccentColor[3], 0.6)

-- Search bar (FilterBySearch defined below after tabFrames/tabButtons exist)
local searchRow = CreateFrame("Frame", nil, panel)
searchRow:SetPoint("TOPLEFT", panel, "TOPLEFT", PADDING + SIDEBAR_WIDTH + 8, -(HEADER_HEIGHT + 4))
searchRow:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PADDING, 0)
searchRow:SetHeight(32)

-- Sidebar
local sidebar = CreateFrame("Frame", nil, panel)
sidebar:SetPoint("TOPLEFT", panel, "TOPLEFT", PADDING, -(HEADER_HEIGHT + 4))
sidebar:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", PADDING, PADDING)
sidebar:SetWidth(SIDEBAR_WIDTH)
local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND")
sidebarBg:SetAllPoints(sidebar)
sidebarBg:SetColorTexture(0.08, 0.08, 0.12, 0.95)
local tabButtons = {}
local selectedTab = 1
local contentWidth = PAGE_WIDTH - PADDING * 2 - SIDEBAR_WIDTH - 8

-- Scroll + content
local scrollFrame = CreateFrame("ScrollFrame", nil, panel)
scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", PADDING + SIDEBAR_WIDTH + 8, -(HEADER_HEIGHT + 4 + 36))
scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -PADDING, PADDING)
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(_, delta)
    local cur = scrollFrame:GetVerticalScroll()
    local childH = scrollFrame:GetScrollChild() and scrollFrame:GetScrollChild():GetHeight() or 0
    local frameH = scrollFrame:GetHeight() or 0
    scrollFrame:SetVerticalScroll(math.max(0, math.min(cur - delta * SCROLL_STEP, math.max(0, childH - frameH))))
end)

local tabFrames = {}
for i = 1, #addon.OptionCategories do
    local f = CreateFrame("Frame", nil, panel)
    f:SetSize(contentWidth, 3000)
    local top = CreateFrame("Frame", nil, f)
    top:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    top:SetSize(1, 1)
    f.topAnchor = top
    tabFrames[i] = f
end
scrollFrame:SetScrollChild(tabFrames[1])
for i = 2, #tabFrames do tabFrames[i]:Hide() end

-- Version at bottom of sidebar
local versionLabel = sidebar:CreateFontString(nil, "OVERLAY")
versionLabel:SetFont(Def.FontPath or "Fonts\\FRIZQT__.TTF", Def.SectionSize or 10, "OUTLINE")
SetTextColor(versionLabel, Def.TextColorSection)
versionLabel:SetText("v" .. (GetAddOnMetadata and GetAddOnMetadata("HorizonSuite", "Version") or "0.6.6"))
versionLabel:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 8, 8)

-- ---------------------------------------------------------------------------
-- Build one category's content
-- ---------------------------------------------------------------------------
local allRefreshers = {}

local function FinalizeCard(card)
    if not card or not card.contentHeight then return end
    card:SetHeight(card.contentHeight + CardPadding)
end

--- Build one options category: section cards, toggles, sliders, dropdowns, color matrix, reorder list; wires get/set and refreshers.
-- @param tab table Tab frame with topAnchor
-- @param options table Array of option descriptors (type, name, dbKey, get, set, etc.)
-- @param refreshers table Array to which refreshable widgets are appended
local function BuildCategory(tab, options, refreshers)
    local anchor = tab.topAnchor
    local currentCard = nil
    for _, opt in ipairs(options) do
        if opt.type == "section" then
            if currentCard then FinalizeCard(currentCard) end
            currentCard = OptionsWidgets_CreateSectionCard(tab, anchor)
            local lbl = OptionsWidgets_CreateSectionHeader(currentCard, opt.name)
            lbl:SetPoint("TOPLEFT", currentCard, "TOPLEFT", CardPadding, -CardPadding)
            currentCard.contentAnchor = lbl
            currentCard.contentHeight = CardPadding + RowHeights.sectionLabel
            anchor = currentCard
        elseif opt.type == "toggle" and currentCard then
            local w = OptionsWidgets_CreateToggleSwitch(currentCard, opt.name, opt.desc or opt.tooltip, opt.get, opt.set)
            w:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -OptionGap)
            w:SetPoint("RIGHT", currentCard, "RIGHT", -CardPadding, 0)
            currentCard.contentAnchor = w
            currentCard.contentHeight = currentCard.contentHeight + OptionGap + RowHeights.toggle
            table.insert(refreshers, w)
        elseif opt.type == "slider" and currentCard then
            local w = OptionsWidgets_CreateSlider(currentCard, opt.name, opt.desc or opt.tooltip, opt.get, opt.set, opt.min, opt.max)
            w:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -OptionGap)
            w:SetPoint("RIGHT", currentCard, "RIGHT", -CardPadding, 0)
            currentCard.contentAnchor = w
            currentCard.contentHeight = currentCard.contentHeight + OptionGap + RowHeights.slider
            table.insert(refreshers, w)
        elseif opt.type == "dropdown" and currentCard then
            local opts = (type(opt.options) == "function" and opt.options()) or opt.options or {}
            local w = OptionsWidgets_CreateCustomDropdown(currentCard, opt.name, opt.desc or opt.tooltip, opts, opt.get, opt.set, opt.displayFn)
            w:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -OptionGap)
            w:SetPoint("RIGHT", currentCard, "RIGHT", -CardPadding, 0)
            currentCard.contentAnchor = w
            currentCard.contentHeight = currentCard.contentHeight + OptionGap + RowHeights.dropdown
            table.insert(refreshers, w)
        elseif opt.type == "colorMatrix" then
            if currentCard then FinalizeCard(currentCard) end
            currentCard = OptionsWidgets_CreateSectionCard(tab, anchor)
            local lbl = OptionsWidgets_CreateSectionHeader(currentCard, opt.name or "Colors")
            lbl:SetPoint("TOPLEFT", currentCard, "TOPLEFT", CardPadding, -CardPadding)
            currentCard.contentAnchor = lbl
            currentCard.contentHeight = CardPadding + RowHeights.sectionLabel
            anchor = currentCard
            local keys = opt.keys or addon.COLOR_KEYS_ORDER
            local defaultMap = opt.defaultMap or addon.QUEST_COLORS
            local sub = OptionsWidgets_CreateSectionHeader(currentCard, "Quest type colors")
            sub:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -SectionGap)
            currentCard.contentAnchor = sub
            currentCard.contentHeight = currentCard.contentHeight + SectionGap + RowHeights.sectionLabel
            local swatches = {}
            for _, key in ipairs(keys) do
                local getTbl = function() local db = getDB(opt.dbKey, nil) return db and db[key] end
                local setKeyVal = function(v) addon.EnsureDB() if not HorizonDB[opt.dbKey] then HorizonDB[opt.dbKey] = {} end HorizonDB[opt.dbKey][key] = v notifyMainAddon() end
                local row = OptionsWidgets_CreateColorSwatchRow(currentCard, currentCard.contentAnchor, (opt.labelMap and opt.labelMap[key]) or key:gsub("^%l", string.upper), defaultMap[key], getTbl, setKeyVal, notifyMainAddon)
                currentCard.contentAnchor = row
                currentCard.contentHeight = currentCard.contentHeight + 4 + 24
                swatches[#swatches+1] = row
            end
            local resetBtn = CreateFrame("Button", nil, currentCard)
            resetBtn:SetSize(120, 22)
            resetBtn:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -6)
            local rl = resetBtn:CreateFontString(nil, "OVERLAY")
            rl:SetFont(Def.FontPath or "Fonts\\FRIZQT__.TTF", Def.LabelSize or 13, "OUTLINE")
            SetTextColor(rl, Def.TextColorLabel)
            rl:SetText("Reset quest types")
            rl:SetPoint("CENTER", resetBtn, "CENTER", 0, 0)
            resetBtn:SetScript("OnClick", function()
                setDB(opt.dbKey, nil)
                if HorizonDB then HorizonDB.sectionColors = nil end
                for _, sw in ipairs(swatches) do if sw.Refresh then sw:Refresh() end end
                notifyMainAddon()
            end)
            currentCard.contentAnchor = resetBtn
            currentCard.contentHeight = currentCard.contentHeight + 6 + 22
            local overridesSub = OptionsWidgets_CreateSectionHeader(currentCard, "Element overrides")
            overridesSub:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -SectionGap)
            currentCard.contentAnchor = overridesSub
            currentCard.contentHeight = currentCard.contentHeight + SectionGap + RowHeights.sectionLabel
            local overrideRows = {}
            for _, ov in ipairs(opt.overrides or {}) do
                local getTbl = function() return getDB(ov.dbKey, nil) end
                local setKeyVal = function(v) setDB(ov.dbKey, v) notifyMainAddon() end
                local row = OptionsWidgets_CreateColorSwatchRow(currentCard, currentCard.contentAnchor, ov.name, ov.default, getTbl, setKeyVal, notifyMainAddon)
                currentCard.contentAnchor = row
                currentCard.contentHeight = currentCard.contentHeight + 4 + 24
                overrideRows[#overrideRows+1] = row
            end
            local resetOv = CreateFrame("Button", nil, currentCard)
            resetOv:SetSize(120, 22)
            resetOv:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -6)
            local rol = resetOv:CreateFontString(nil, "OVERLAY")
            rol:SetFont(Def.FontPath or "Fonts\\FRIZQT__.TTF", Def.LabelSize or 13, "OUTLINE")
            SetTextColor(rol, Def.TextColorLabel)
            rol:SetText("Reset overrides")
            rol:SetPoint("CENTER", resetOv, "CENTER", 0, 0)
            resetOv:SetScript("OnClick", function()
                for _, ov in ipairs(opt.overrides or {}) do setDB(ov.dbKey, nil) end
                for _, r in ipairs(overrideRows) do if r.Refresh then r:Refresh() end end
                notifyMainAddon()
            end)
            currentCard.contentAnchor = resetOv
            currentCard.contentHeight = currentCard.contentHeight + 6 + 22
            table.insert(refreshers, { Refresh = function() for _, sw in ipairs(swatches) do if sw.Refresh then sw:Refresh() end end for _, r in ipairs(overrideRows) do if r.Refresh then r:Refresh() end end end })
        elseif opt.type == "colorGroup" then
            if currentCard then FinalizeCard(currentCard) end
            currentCard = OptionsWidgets_CreateSectionCard(tab, anchor)
            local lbl = OptionsWidgets_CreateSectionHeader(currentCard, opt.name)
            lbl:SetPoint("TOPLEFT", currentCard, "TOPLEFT", CardPadding, -CardPadding)
            currentCard.contentAnchor = lbl
            currentCard.contentHeight = CardPadding + RowHeights.sectionLabel
            anchor = currentCard
            local keys = type(opt.keys) == "function" and opt.keys() or opt.keys or {}
            local defaultMap = opt.defaultMap or {}
            local swatches = {}
            for _, key in ipairs(keys) do
                local getTbl = function() local db = getDB(opt.dbKey, nil) return db and db[key] end
                local setKeyVal = function(v) addon.EnsureDB() if not HorizonDB[opt.dbKey] then HorizonDB[opt.dbKey] = {} end HorizonDB[opt.dbKey][key] = v notifyMainAddon() end
                local def = defaultMap[key] or {0.5,0.5,0.5}
                local row = OptionsWidgets_CreateColorSwatchRow(currentCard, currentCard.contentAnchor, (opt.labelMap and opt.labelMap[key]) or key:gsub("^%l", string.upper), def, getTbl, setKeyVal, notifyMainAddon)
                currentCard.contentAnchor = row
                currentCard.contentHeight = currentCard.contentHeight + 4 + 24
                swatches[#swatches+1] = row
            end
            local resetBtn = CreateFrame("Button", nil, currentCard)
            resetBtn:SetSize(120, 22)
            resetBtn:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -6)
            local rl = resetBtn:CreateFontString(nil, "OVERLAY")
            rl:SetFont(Def.FontPath or "Fonts\\FRIZQT__.TTF", Def.LabelSize or 13, "OUTLINE")
            SetTextColor(rl, Def.TextColorLabel)
            rl:SetText("Reset to defaults")
            rl:SetPoint("CENTER", resetBtn, "CENTER", 0, 0)
            resetBtn:SetScript("OnClick", function()
                setDB(opt.dbKey, nil)
                if HorizonDB then HorizonDB.sectionColors = nil end
                for _, sw in ipairs(swatches) do if sw.Refresh then sw:Refresh() end end
                notifyMainAddon()
            end)
            currentCard.contentAnchor = resetBtn
            currentCard.contentHeight = currentCard.contentHeight + 6 + 22
            table.insert(refreshers, { Refresh = function() for _, sw in ipairs(swatches) do if sw.Refresh then sw:Refresh() end end end })
        elseif opt.type == "reorderList" then
            if currentCard then FinalizeCard(currentCard) end
            local reorderAnchor = anchor
            local w = OptionsWidgets_CreateReorderList(tab, reorderAnchor, opt, scrollFrame, panel, notifyMainAddon)
            anchor = w
            currentCard = nil
            table.insert(refreshers, w)
        end
    end
    if currentCard then FinalizeCard(currentCard) end
end

-- Build sidebar buttons and tab content
local function UpdateTabVisuals()
    for i, btn in ipairs(tabButtons) do
        local sel = (i == selectedTab)
        btn.selected = sel
        SetTextColor(btn.label, sel and Def.TextColorNormal or Def.TextColorSection)
        if btn.leftAccent then btn.leftAccent:SetShown(sel) end
        if btn.highlight then btn.highlight:SetShown(sel) end
    end
end

for i, cat in ipairs(addon.OptionCategories) do
    local btn = CreateFrame("Button", nil, sidebar)
    btn:SetSize(SIDEBAR_WIDTH, 24)
    if i == 1 then btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, 0)
    else btn:SetPoint("TOPLEFT", tabButtons[i-1], "BOTTOMLEFT", 0, 0) end
    btn.label = btn:CreateFontString(nil, "OVERLAY")
    btn.label:SetFont(Def.FontPath or "Fonts\\FRIZQT__.TTF", Def.LabelSize or 13, "OUTLINE")
    btn.label:SetPoint("LEFT", btn, "LEFT", 8, 0)
    btn.label:SetText(cat.name)
    btn.highlight = btn:CreateTexture(nil, "BACKGROUND")
    btn.highlight:SetAllPoints(btn)
    btn.highlight:SetColorTexture(1, 1, 1, 0.06)
    btn.leftAccent = btn:CreateTexture(nil, "OVERLAY")
    btn.leftAccent:SetWidth(2)
    btn.leftAccent:SetColorTexture(Def.AccentColor[1], Def.AccentColor[2], Def.AccentColor[3], Def.AccentColor[4])
    btn.leftAccent:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    btn.leftAccent:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    btn:SetScript("OnClick", function()
        selectedTab = i
        UpdateTabVisuals()
        for j = 1, #tabFrames do tabFrames[j]:SetShown(j == i) end
        scrollFrame:SetScrollChild(tabFrames[i])
        scrollFrame:SetVerticalScroll(0)
    end)
    btn:SetScript("OnEnter", function() if not btn.selected then SetTextColor(btn.label, Def.TextColorHighlight) end end)
    btn:SetScript("OnLeave", function() UpdateTabVisuals() end)
    tabButtons[i] = btn

    local refreshers = {}
    BuildCategory(tabFrames[i], cat.options, refreshers)
    for _, r in ipairs(refreshers) do allRefreshers[#allRefreshers+1] = r end
end
UpdateTabVisuals()

-- Search: FilterBySearch and search input
local searchQuery = ""
local function FilterBySearch(query)
    searchQuery = query and query:trim():lower() or ""
    if searchQuery == "" then
        for i = 1, #tabFrames do tabFrames[i]:SetShown(i == selectedTab) end
        scrollFrame:SetScrollChild(tabFrames[selectedTab])
        UpdateTabVisuals()
        return
    end
    local index = addon.OptionsData_BuildSearchIndex and addon.OptionsData_BuildSearchIndex() or {}
    local matches = {}
    for _, entry in ipairs(index) do
        if entry.searchText:find(searchQuery, 1, true) then matches[#matches+1] = entry end
    end
    for i, btn in ipairs(tabButtons) do
        local cat = addon.OptionCategories[i]
        local hasMatch = false
        for _, m in ipairs(matches) do if m.categoryKey == cat.key then hasMatch = true break end end
        if hasMatch then SetTextColor(btn.label, Def.TextColorHighlight) end
    end
end
local searchInput = OptionsWidgets_CreateSearchInput(searchRow, function(text) FilterBySearch(text) end)
searchInput.edit:SetPoint("TOPLEFT", searchRow, "TOPLEFT", 0, 0)
searchInput.edit:SetPoint("TOPRIGHT", searchRow, "TOPRIGHT", -28, 0)
searchInput.clearBtn:SetPoint("TOPRIGHT", searchRow, "TOPRIGHT", 0, 0)
searchInput.edit:SetScript("OnEscapePressed", function() searchInput.edit:SetText("") FilterBySearch("") searchInput.edit:ClearFocus() end)

-- Update panel fonts (called when font option changes or on show)
function updateOptionsPanelFonts()
    if not panel:IsShown() then return end
    local path = addon.OptionsData_GetDB("fontPath", (addon.GetDefaultFontPath and addon.GetDefaultFontPath()) or "Fonts\\FRIZQT__.TTF")
    local size = addon.OptionsData_GetDB("headerFontSize", 16)
    if OptionsWidgets_SetDef then OptionsWidgets_SetDef({ FontPath = path, HeaderSize = size }) end
    titleText:SetFont(path, size, "OUTLINE")
    closeLabel:SetFont(path, Def.LabelSize or 13, "OUTLINE")
    versionLabel:SetFont(path, Def.SectionSize or 10, "OUTLINE")
    for _, btn in ipairs(tabButtons) do if btn.label then btn.label:SetFont(path, Def.LabelSize or 13, "OUTLINE") end end
end
addon.OptionsData_SetUpdateFontsRef(updateOptionsPanelFonts)

-- OnShow
local ANIM_DUR = 0.2
local easeOut = addon.easeOut or function(t) return 1 - (1-t)*(1-t) end
panel:SetScript("OnShow", function()
    updateOptionsPanelFonts()
    if HorizonDB and HorizonDB.optionsLeft ~= nil and HorizonDB.optionsTop ~= nil then
        panel:ClearAllPoints()
        panel:SetPoint("CENTER", UIParent, "CENTER", HorizonDB.optionsLeft, HorizonDB.optionsTop)
    else
        panel:ClearAllPoints()
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    for _, ref in ipairs(allRefreshers) do if ref and ref.Refresh then ref:Refresh() end end
    panel:SetAlpha(0)
    panel.animStart = GetTime()
    panel.animating = "in"
    panel:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - self.animStart
        if elapsed >= ANIM_DUR then self:SetAlpha(1) self:SetScript("OnUpdate", nil) self.animating = nil return end
        self:SetAlpha(easeOut(elapsed / ANIM_DUR))
    end)
end)

function _G.HorizonSuite_OptionsRequestClose()
    if panel.animating == "out" then return end
    panel.animating = "out"
    panel.animStart = GetTime()
    panel:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - self.animStart
        if elapsed >= ANIM_DUR then self:SetAlpha(1) self:SetScript("OnUpdate", nil) self.animating = nil self:Hide() return end
        self:SetAlpha(1 - easeOut(elapsed / ANIM_DUR))
    end)
end

function _G.HorizonSuite_ShowOptions()
    local p = _G.HorizonSuiteOptionsPanel
    if p then
        if p:IsShown() then
            if _G.HorizonSuite_OptionsRequestClose then _G.HorizonSuite_OptionsRequestClose() else p:Hide() end
        else p:Show() end
    end
end

function _G.HorizonSuite_ShowEditPanel()
    if _G.HorizonSuite_ShowOptions then _G.HorizonSuite_ShowOptions() end
end
