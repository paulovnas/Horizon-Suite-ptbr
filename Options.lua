--[[
    Horizon Suite - Focus - Options panel (popout)
    Def, OptionCategories, widget helpers. Opens via /horizon options or header gear.
]]

local ADDON_NAME = "Horizon Suite - Focus"

-- Ensure DB exists
if not ModernQuestTrackerDB then
    ModernQuestTrackerDB = {}
end

local addon = _G.ModernQuestTracker

-- Layout and visual constants (aligned with Core)
local Def = {
    -- Sizes and gaps
    ButtonSize = 28,
    WidgetGap = 14,
    PageWidth = 600,
    PageHeight = 520,
    SidebarWidth = 140,
    SidebarGap = 6,
    SidebarItemHeight = 24,
    Padding = 14,
    OptionGap = 10,
    SectionGap = 16,
    CardPadding = 12,
    ScrollStep = 40,
    TabContentHeight = 1200,
    BorderEdge = 1,
    ScrollInset = 1,
    -- Font (from Core)
    FontPath = nil,
    HeaderSize = nil,
    LabelSize = 13,
    SectionSize = 10,
    -- Shadow (from Core)
    ShadowOx = nil,
    ShadowOy = nil,
    ShadowA = nil,
    DividerHeight = 2,
    -- Text colors
    TextColorNormal = { 1, 1, 1 },
    TextColorHighlight = { 0.65, 0.72, 0.85, 1 },
    TextColorLabel = { 0.78, 0.78, 0.78 },
    TextColorSection = { 0.55, 0.65, 0.75 },
    TextColorTitleBar = { 1, 1, 1, 1 },
    -- Backgrounds and borders
    TitleBarBg = { 0.06, 0.06, 0.10, 0.88 },
    ContentBg = { 0.10, 0.10, 0.15, 0.82 },
    TabBarBg = { 0.08, 0.08, 0.12, 0.85 },
    TabSelectedBg = { 1, 1, 1, 0.06 },
    AccentColor = { 0.5, 0.6, 0.85, 0.9 },
    BorderColor = { 0.35, 0.38, 0.45, 0.55 },
    ContentInsetBg = { 0.06, 0.06, 0.10, 0.45 },
    SectionCardBg = { 0.12, 0.12, 0.18, 0.6 },
    SectionCardBorder = { 0.35, 0.38, 0.45, 0.45 },
    -- Control styling (dark theme)
    InputBg = { 0.08, 0.08, 0.12, 0.95 },
    InputBorder = { 0.35, 0.38, 0.45, 0.7 },
    CheckboxBg = { 0.12, 0.12, 0.18, 0.9 },
    CheckboxBorder = { 0.4, 0.45, 0.55, 0.8 },
    CheckboxCheckColor = { 0.5, 0.6, 0.85, 1 },
}
-- Resolve from DB when available, else addon default (lowercase for dropdown consistency)
Def.FontPath = (addon.GetDB and addon.GetDB("fontPath", addon.GetDefaultFontPath and addon.GetDefaultFontPath() or "Fonts\\FRIZQT__.TTF")) or (addon.FONT_PATH or (addon.GetDefaultFontPath and addon.GetDefaultFontPath()) or "Fonts\\FRIZQT__.TTF")
Def.HeaderSize = addon.HEADER_SIZE or 16
Def.ShadowOx = addon.SHADOW_OX or 2
Def.ShadowOy = addon.SHADOW_OY or -2
Def.ShadowA = addon.SHADOW_A or 0.8
Def.HeaderHeight = Def.Padding + Def.HeaderSize + 6 + Def.DividerHeight
Def.DividerColor = addon.DIVIDER_COLOR or Def.AccentColor

-- Helpers
local function SetTextColor(obj, color)
    if not color then return end
    obj:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local function CreateDivider(parent, width)
    local div = parent:CreateTexture(nil, "OVERLAY")
    div:SetHeight(Def.DividerHeight)
    if width then div:SetWidth(width) end
    local dc = Def.DividerColor
    div:SetColorTexture(dc[1], dc[2], dc[3], dc[4] or 1)
    return div
end

local function getDB(key, default)
    return addon.GetDB(key, default)
end

local function notifyMainAddon()
    local applyTy = _G.ModernQuestTracker_ApplyTypography or (addon and addon.ApplyTypography)
    if applyTy then applyTy() end
    if _G.ModernQuestTracker_ApplyDimensions then _G.ModernQuestTracker_ApplyDimensions() end
    if _G.ModernQuestTracker_RequestRefresh then _G.ModernQuestTracker_RequestRefresh() end
    if _G.ModernQuestTracker_FullLayout and not InCombatLockdown() then _G.ModernQuestTracker_FullLayout() end
end

local TYPOGRAPHY_KEYS = {
    fontPath = true,
    headerFontSize = true,
    titleFontSize = true,
    objectiveFontSize = true,
    zoneFontSize = true,
    sectionFontSize = true,
    fontOutline = true,
}

local updateOptionsPanelFonts  -- forward decl, set after panel built
local function setDB(key, value)
    addon.EnsureDB()
    ModernQuestTrackerDB[key] = value
    if key == "fontPath" then
        Def.FontPath = value
        if updateOptionsPanelFonts then updateOptionsPanelFonts() end
    end
    if TYPOGRAPHY_KEYS[key] and addon.UpdateFontObjectsFromDB then
        addon.UpdateFontObjectsFromDB()
    end
    notifyMainAddon()
end

local function PlaceOptionFor(parent, anchor, control, isSection)
    local y = isSection and -Def.SectionGap or -Def.OptionGap
    control:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y)
    return control
end

-- Build the panel frame (popout window)
local panel = CreateFrame("Frame", "ModernQuestTrackerOptionsPanel", UIParent)
panel.name = ADDON_NAME
panel:SetSize(Def.PageWidth, Def.PageHeight)
panel:SetFrameStrata("DIALOG")
panel:SetClampedToScreen(true)

-- Backdrop: content area (main body)
local bg = panel:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(panel)
bg:SetColorTexture(Def.ContentBg[1], Def.ContentBg[2], Def.ContentBg[3], Def.ContentBg[4])
local function addBorderEdge(point, relPoint, width, height, x, y)
    local tex = panel:CreateTexture(nil, "BORDER")
    tex:SetColorTexture(Def.BorderColor[1], Def.BorderColor[2], Def.BorderColor[3], Def.BorderColor[4])
    tex:SetSize(width, height)
    tex:SetPoint(point, panel, relPoint or point, x or 0, y or 0)
    return tex
end
addBorderEdge("TOPLEFT", "TOPLEFT", Def.PageWidth, Def.BorderEdge)
addBorderEdge("BOTTOMLEFT", "BOTTOMLEFT", Def.PageWidth, Def.BorderEdge)
addBorderEdge("TOPLEFT", "TOPLEFT", Def.BorderEdge, Def.PageHeight)
addBorderEdge("TOPRIGHT", "TOPRIGHT", Def.BorderEdge, Def.PageHeight)

panel:SetMovable(true)
panel:RegisterForDrag("LeftButton")

-- Title bar
local titleBar = CreateFrame("Frame", nil, panel)
titleBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
titleBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
titleBar:SetHeight(Def.HeaderHeight)
local titleBarBg = titleBar:CreateTexture(nil, "BACKGROUND")
titleBarBg:SetAllPoints(titleBar)
titleBarBg:SetColorTexture(Def.TitleBarBg[1], Def.TitleBarBg[2], Def.TitleBarBg[3], Def.TitleBarBg[4])
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function() panel:StartMoving() end)
titleBar:SetScript("OnDragStop", function()
    panel:StopMovingOrSizing()
    local db = ModernQuestTrackerDB
    if db then
        local x, y = panel:GetCenter()
        local uix, uiy = UIParent:GetCenter()
        db.optionsLeft = x - uix
        db.optionsTop = y - uiy
    end
end)
titleBar:SetFrameLevel(0)

local titleShadow = titleBar:CreateFontString(nil, "BORDER")
titleShadow:SetFont(Def.FontPath, Def.HeaderSize, "OUTLINE")
titleShadow:SetTextColor(0, 0, 0, Def.ShadowA)
titleShadow:SetJustifyH("LEFT")
titleShadow:SetText("OPTIONS")

local titleText = titleBar:CreateFontString(nil, "OVERLAY")
titleText:SetFont(Def.FontPath, Def.HeaderSize, "OUTLINE")
SetTextColor(titleText, Def.TextColorTitleBar)
titleText:SetJustifyH("LEFT")
titleText:SetPoint("TOPLEFT", titleBar, "TOPLEFT", Def.Padding, -Def.Padding)
titleText:SetText("OPTIONS")
titleShadow:SetPoint("CENTER", titleText, "CENTER", Def.ShadowOx, Def.ShadowOy)

local closeBtn = CreateFrame("Button", nil, panel)
closeBtn:SetSize(44, 22)
closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -Def.Padding, -Def.Padding)
local closeLabel = closeBtn:CreateFontString(nil, "OVERLAY")
closeLabel:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
closeLabel:SetTextColor(Def.TextColorLabel[1], Def.TextColorLabel[2], Def.TextColorLabel[3], Def.TextColorLabel[4] or 1)
closeLabel:SetJustifyH("CENTER")
closeLabel:SetText("Close")
closeLabel:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
closeBtn:SetScript("OnClick", function()
    if _G.ModernQuestTracker_OptionsRequestClose then _G.ModernQuestTracker_OptionsRequestClose()
    else panel:Hide() end
end)
closeBtn:SetScript("OnEnter", function()
    closeLabel:SetTextColor(Def.TextColorHighlight[1], Def.TextColorHighlight[2], Def.TextColorHighlight[3], Def.TextColorHighlight[4] or 1)
    if GameTooltip then GameTooltip:SetOwner(closeBtn, "ANCHOR_BOTTOM"); GameTooltip:SetText("Close options", nil, nil, nil, nil, true); GameTooltip:Show() end
end)
closeBtn:SetScript("OnLeave", function()
    closeLabel:SetTextColor(Def.TextColorLabel[1], Def.TextColorLabel[2], Def.TextColorLabel[3], Def.TextColorLabel[4] or 1)
    if GameTooltip then GameTooltip:Hide() end
end)

panel:Hide()

local divider = panel:CreateTexture(nil, "ARTWORK")
divider:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
divider:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
divider:SetHeight(Def.DividerHeight)
local dc = Def.DividerColor
divider:SetColorTexture(dc[1], dc[2], dc[3], dc[4] or 1)

local tabFrames = {}
local tabButtons = {}
local selectedTab = 1
local contentWidth = Def.PageWidth - Def.Padding * 2 - Def.SidebarWidth - Def.SidebarGap

-- Sidebar: category list
local sidebar = CreateFrame("Frame", nil, panel)
sidebar:SetPoint("TOPLEFT", panel, "TOPLEFT", Def.Padding, -(Def.HeaderHeight + 4))
sidebar:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", Def.Padding, Def.Padding)
sidebar:SetWidth(Def.SidebarWidth)
local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND")
sidebarBg:SetAllPoints(sidebar)
sidebarBg:SetColorTexture(Def.TabBarBg[1], Def.TabBarBg[2], Def.TabBarBg[3], Def.TabBarBg[4])

-- Scroll frame and tab content frames
local scrollFrame = CreateFrame("ScrollFrame", nil, panel)
scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", Def.Padding + Def.SidebarWidth + Def.SidebarGap, -(Def.HeaderHeight + 4))
scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -Def.Padding, Def.Padding)
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(_, delta)
    local cur = scrollFrame:GetVerticalScroll()
    local childH = scrollFrame:GetScrollChild() and scrollFrame:GetScrollChild():GetHeight() or 0
    local frameH = scrollFrame:GetHeight() or 0
    local maxScroll = math.max(childH - frameH, 0)
    scrollFrame:SetVerticalScroll(math.max(0, math.min(cur - delta * Def.ScrollStep, maxScroll)))
end)
for idx = 1, 5 do
    local f = CreateFrame("Frame", nil, panel)
    f:SetSize(contentWidth, Def.TabContentHeight)
    local top = CreateFrame("Frame", nil, f)
    top:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    top:SetSize(1, 1)
    f.topAnchor = top
    tabFrames[idx] = f
end
scrollFrame:SetScrollChild(tabFrames[1])
for idx = 2, 5 do
    tabFrames[idx]:Hide()
end

local contentInsetBg = panel:CreateTexture(nil, "BORDER")
contentInsetBg:SetPoint("TOPLEFT", panel, "TOPLEFT", Def.Padding + Def.SidebarWidth + Def.SidebarGap + Def.ScrollInset, -(Def.HeaderHeight + 4 + Def.ScrollInset))
contentInsetBg:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -Def.Padding - Def.ScrollInset, Def.Padding + Def.ScrollInset)
contentInsetBg:SetColorTexture(Def.ContentInsetBg[1], Def.ContentInsetBg[2], Def.ContentInsetBg[3], Def.ContentInsetBg[4])

-- Section label (SettingsHeader-style)
local function CreateSectionLabel(parent, text)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(Def.FontPath, Def.SectionSize, "OUTLINE")
    SetTextColor(label, Def.TextColorSection)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

-- Section card: groups options
local function CreateSectionCard(parent, anchor)
    local card = CreateFrame("Frame", nil, parent)
    card:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -Def.SectionGap)
    card:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    local cardBg = card:CreateTexture(nil, "BACKGROUND")
    cardBg:SetAllPoints(card)
    cardBg:SetColorTexture(Def.SectionCardBg[1], Def.SectionCardBg[2], Def.SectionCardBg[3], Def.SectionCardBg[4])
    local b = Def.BorderEdge
    local bc = Def.SectionCardBorder
    local function edgeHorz(point)
        local tex = card:CreateTexture(nil, "BORDER")
        tex:SetColorTexture(bc[1], bc[2], bc[3], bc[4])
        tex:SetHeight(b)
        tex:SetPoint(point, card, point, 0, 0)
        tex:SetPoint("LEFT", card, "LEFT", 0, 0)
        tex:SetPoint("RIGHT", card, "RIGHT", 0, 0)
    end
    local function edgeVert(point)
        local tex = card:CreateTexture(nil, "BORDER")
        tex:SetColorTexture(bc[1], bc[2], bc[3], bc[4])
        tex:SetWidth(b)
        tex:SetPoint(point, card, point, 0, 0)
        tex:SetPoint("TOP", card, "TOP", 0, 0)
        tex:SetPoint("BOTTOM", card, "BOTTOM", 0, 0)
    end
    edgeHorz("TOP")
    edgeHorz("BOTTOM")
    edgeVert("LEFT")
    edgeVert("RIGHT")
    return card
end

-- Row heights for card sizing (GetBottom nil before layout)
local DROPDOWN_LABEL_SPACE = 18
local NUMERIC_INPUT_OFFSET = 200
local ROW_HEIGHTS = {
    sectionLabel = 14,
    checkbox = 22,
    numeric = 22,
    dropdown = 28,
    dropdownListReserve = 24,
    colorRow = 24,
    hint = 14,
    colorGroupLabel = 14,
    colorGroupRow = 24,
    resetBtn = 22,
}

local function FinalizeSectionCard(card)
    if not card then return end
    -- Prefer accumulated content height
    if card.contentHeight then
        card:SetHeight(card.contentHeight + Def.CardPadding)
        return
    end
    -- Fallback: lowest child GetBottom()
    local minBottom = 0
    local children = { card:GetChildren() }
    for i = 1, #children do
        local child = children[i]
        if child and child.GetBottom then
            local b = child:GetBottom()
            if b ~= nil and b < minBottom then minBottom = b end
        end
    end
    for i = 1, card:GetNumRegions() do
        local r = select(i, card:GetRegions())
        if r and r.GetBottom then
            local b = r:GetBottom()
            if b ~= nil and b < minBottom then minBottom = b end
        end
    end
    card:SetHeight(math.max(Def.CardPadding * 2 + 12, -minBottom + Def.CardPadding))
end

-- Numeric option (label + input)
local function CreateNumericOption(parent, labelText, tooltipText, getValue, setValue, minVal, maxVal, width)
    width = width or 50
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    SetTextColor(label, Def.TextColorLabel)
    label:SetText(labelText)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(width, 22)
    eb:SetMaxLetters(6)
    eb:SetNumeric(true)
    eb:SetAutoFocus(false)
    eb:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    local ebbg = eb:CreateTexture(nil, "BACKGROUND")
    ebbg:SetAllPoints(eb)
    ebbg:SetColorTexture(Def.InputBg[1], Def.InputBg[2], Def.InputBg[3], Def.InputBg[4])
    for i = 1, eb:GetNumRegions() do
        local r = select(i, eb:GetRegions())
        if r and r.SetColorTexture then
            r:SetColorTexture(Def.InputBg[1], Def.InputBg[2], Def.InputBg[3], Def.InputBg[4])
        end
    end
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEnter", function(self)
        if tooltipText and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end
    end)
    eb:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    eb:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        local v = tonumber(self:GetText())
        if v ~= nil and minVal and maxVal then
            v = math.max(minVal, math.min(maxVal, v))
        end
        if v ~= nil then setValue(v) end
    end)
    eb:SetScript("OnEnterPressed", function(self)
        local v = tonumber(self:GetText())
        if v ~= nil and minVal and maxVal then
            v = math.max(minVal, math.min(maxVal, v))
            self:SetText(tostring(v))
        end
        if v ~= nil then setValue(v); notifyMainAddon() end
        self:ClearFocus()
    end)
    function eb:Refresh()
        self:SetText(tostring(getValue()))
    end
    return label, eb
end

local function addNumericRowFor(parent, anchor, name, getVal, setVal, minV, maxV)
    local lab, eb = CreateNumericOption(parent, name, nil, getVal, function(v) setVal(v); notifyMainAddon() end, minV, maxV)
    lab:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -Def.OptionGap)
    eb:SetPoint("LEFT", lab, "RIGHT", 10, 0)
    return lab, eb
end

-- Dropdown via UIDropDownMenu_Initialize (optionsTable can be a function that returns { { name, value }, ... })
local function InitDropdownMenu(frame, optionsTable, onSelect)
    if not UIDropDownMenu_Initialize or not UIDropDownMenu_CreateInfo or not UIDropDownMenu_AddButton then return end
    UIDropDownMenu_Initialize(frame, function(self, level, menuList)
        local opts = (type(optionsTable) == "function" and optionsTable()) or optionsTable or {}
        for _, opt in ipairs(opts) do
            local info = UIDropDownMenu_CreateInfo()
            if info then
                info.text = opt[1]
                info.func = function()
                    if onSelect then onSelect(opt) end
                    if UIDropDownMenu_SetText then UIDropDownMenu_SetText(frame, opt[1]) end
                    if CloseDropDownMenus then CloseDropDownMenus() end
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)
end
-- Open dropdown upward
local function ToggleDropdown(frame)
    if not ToggleDropDownMenu then return end
    if UIDropDownMenu_SetAnchor then
        -- List opens upward
        UIDropDownMenu_SetAnchor(frame, 0, 0, "BOTTOMLEFT", frame, "TOPLEFT")
    end
    ToggleDropDownMenu(1, nil, frame, frame, 0, 0)
end

-- Font options: Game Font + LibSharedMedia. Returns list with "Custom" entry if saved path not in list.
local function GetFontDropdownOptions()
    if addon.RefreshFontList then addon.RefreshFontList() end
    local list = (addon.GetFontList and addon.GetFontList()) or {}
    local saved = getDB("fontPath", (addon.GetDefaultFontPath and addon.GetDefaultFontPath()) or "Fonts\\FRIZQT__.TTF")
    for _, o in ipairs(list) do
        if o[2] == saved then return list end
    end
    local out = {}
    for i = 1, #list do out[i] = list[i] end
    out[#out + 1] = { "Custom", saved }
    return out
end

-- Outline options
local OUTLINE_OPTIONS = {
    { "None", "" },
    { "Outline", "OUTLINE" },
    { "Thick Outline", "THICKOUTLINE" },
}
local HIGHLIGHT_OPTIONS = {
    { "Bar (left edge)", "bar" },
    { "Highlight", "highlight" },
}
local QUEST_COLOR_DEFAULTS = {
    DEFAULT = { 0.90, 0.90, 0.90 },
    CAMPAIGN = { 1.00, 0.82, 0.20 },
    LEGENDARY = { 1.00, 0.50, 0.00 },
    WORLD = { 0.60, 0.20, 1.00 },
    COMPLETE = { 0.20, 1.00, 0.40 },
    RARE = { 1.00, 0.55, 0.25 },
}
local COLOR_KEYS_ORDER = { "DEFAULT", "CAMPAIGN", "LEGENDARY", "WORLD", "COMPLETE", "RARE" }
local HIGHLIGHT_COLOR_DEFAULT = { 0.4, 0.7, 1 }
local OBJ_COLOR_DEFAULT = { 0.78, 0.78, 0.78 }
local OBJ_DONE_COLOR_DEFAULT = { 0.30, 0.80, 0.30 }
local ZONE_COLOR_DEFAULT = { 0.55, 0.65, 0.75 }

-- OptionCategories define panel tabs and options
local OptionCategories = {
    {
        key = "Appearance",
        name = "Appearance",
        options = {
            { type = "section", name = "Typography" },
            { type = "dropdown", name = "Font", dbKey = "fontPath", options = GetFontDropdownOptions, get = function() return getDB("fontPath", (addon.GetDefaultFontPath and addon.GetDefaultFontPath()) or "Fonts\\FRIZQT__.TTF") end, set = function(v) setDB("fontPath", v) end },
            { type = "numeric", name = "Header size", dbKey = "headerFontSize", min = 8, max = 32, get = function() return getDB("headerFontSize", 16) end, set = function(v) setDB("headerFontSize", v) end },
            { type = "numeric", name = "Title size", dbKey = "titleFontSize", min = 8, max = 24, get = function() return getDB("titleFontSize", 13) end, set = function(v) setDB("titleFontSize", v) end },
            { type = "numeric", name = "Objective size", dbKey = "objectiveFontSize", min = 8, max = 20, get = function() return getDB("objectiveFontSize", 11) end, set = function(v) setDB("objectiveFontSize", v) end },
            { type = "numeric", name = "Zone size", dbKey = "zoneFontSize", min = 8, max = 18, get = function() return getDB("zoneFontSize", 10) end, set = function(v) setDB("zoneFontSize", v) end },
            { type = "numeric", name = "Section size", dbKey = "sectionFontSize", min = 8, max = 18, get = function() return getDB("sectionFontSize", 10) end, set = function(v) setDB("sectionFontSize", v) end },
            { type = "dropdown", name = "Outline", dbKey = "fontOutline", options = nil, get = function() return getDB("fontOutline", "OUTLINE") end, set = function(v) setDB("fontOutline", v) end },
            { type = "numeric", name = "Shadow X", dbKey = "shadowOffsetX", min = -10, max = 10, get = function() return getDB("shadowOffsetX", 2) end, set = function(v) setDB("shadowOffsetX", v) end },
            { type = "numeric", name = "Shadow Y", dbKey = "shadowOffsetY", min = -10, max = 10, get = function() return getDB("shadowOffsetY", -2) end, set = function(v) setDB("shadowOffsetY", v) end },
            { type = "numeric", name = "Shadow alpha (0-1)", dbKey = "shadowAlpha", min = 0, max = 1, get = function() return getDB("shadowAlpha", 0.8) end, set = function(v) setDB("shadowAlpha", v) end },
            { type = "section", name = "Dimensions" },
            { type = "numeric", name = "Panel width", dbKey = "panelWidth", min = 180, max = 500, get = function() return getDB("panelWidth", 260) end, set = function(v) setDB("panelWidth", math.max(180, math.min(500, v))) end },
            { type = "numeric", name = "Max content height", dbKey = "maxContentHeight", min = 200, max = 800, get = function() return getDB("maxContentHeight", 480) end, set = function(v) setDB("maxContentHeight", math.max(200, math.min(800, v))) end },
            { type = "colorMatrix", name = "Colors", dbKey = "questColors", keys = COLOR_KEYS_ORDER, defaultMap = QUEST_COLOR_DEFAULTS, resetSectionKeys = true,
                overrides = {
                    { dbKey = "zoneColor", name = "Zone label", default = ZONE_COLOR_DEFAULT, tooltip = "Zone name under quest title." },
                    { dbKey = "objectiveColor", name = "Objective text", default = OBJ_COLOR_DEFAULT, tooltip = "Active objectives. Default uses quest type colors." },
                    { dbKey = "objectiveDoneColor", name = "Completed objective", default = OBJ_DONE_COLOR_DEFAULT, tooltip = "Done objectives, Ready to turn in." },
                    { dbKey = "highlightColor", name = "Highlight", default = HIGHLIGHT_COLOR_DEFAULT, tooltip = "Super-tracked quest bar or background." },
                },
            },
        },
    },
    {
        key = "Layout",
        name = "Layout",
        options = {
            { type = "section", name = "Layout" },
            { type = "checkbox", name = "Start collapsed", dbKey = "collapsed", tooltip = "When enabled, the objectives panel starts in collapsed state (header only) until you expand it.", get = function() return (ModernQuestTrackerDB and ModernQuestTrackerDB.collapsed) == true end, set = function(v) setDB("collapsed", v) end },
            { type = "checkbox", name = "Lock position", dbKey = "lockPosition", tooltip = "When enabled, the objectives panel cannot be dragged to reposition.", get = function() return (ModernQuestTrackerDB and ModernQuestTrackerDB.lockPosition) == true end, set = function(v) setDB("lockPosition", v) end },
            { type = "checkbox", name = "Grow upward (fix bottom edge)", dbKey = "growUp", tooltip = "Anchor the tracker by its bottom edge so the list expands upward.", get = function() return getDB("growUp", false) end, set = function(v) setDB("growUp", v) end },
        },
    },
    {
        key = "Display",
        name = "Display",
        options = {
            { type = "section", name = "Display" },
            { type = "checkbox", name = "Show quest count", dbKey = "showQuestCount", tooltip = "Show the tracked quest count in the header.", get = function() return getDB("showQuestCount", true) end, set = function(v) setDB("showQuestCount", v) end },
            { type = "checkbox", name = "Show header divider", dbKey = "showHeaderDivider", tooltip = "Show the 2px line below the OBJECTIVES header.", get = function() return getDB("showHeaderDivider", true) end, set = function(v) setDB("showHeaderDivider", v) end },
            { type = "checkbox", name = "Super-minimal mode (hide Objectives header)", dbKey = "hideObjectivesHeader", tooltip = "Hide the OBJECTIVES header for a pure text list.", get = function() return getDB("hideObjectivesHeader", false) end, set = function(v) setDB("hideObjectivesHeader", v) end },
            { type = "checkbox", name = "Show section headers", dbKey = "showSectionHeaders", tooltip = "Show category labels above each group.", get = function() return getDB("showSectionHeaders", true) end, set = function(v) setDB("showSectionHeaders", v) end },
            { type = "checkbox", name = "Show zone labels", dbKey = "showZoneLabels", tooltip = "Show the zone name under each quest title.", get = function() return getDB("showZoneLabels", true) end, set = function(v) setDB("showZoneLabels", v) end },
            { type = "checkbox", name = "Show quest type icons", dbKey = "showQuestTypeIcons", tooltip = "Show quest type icon to the left of each title.", get = function() return getDB("showQuestTypeIcons", true) end, set = function(v) setDB("showQuestTypeIcons", v) end },
            { type = "dropdown", name = "Active quest highlight", dbKey = "activeQuestHighlight", options = nil, get = function()
                local v = getDB("activeQuestHighlight", "bar")
                if v ~= "bar" and v ~= "highlight" then return (v == "none") and "bar" or "highlight" end
                return v
            end, set = function(v) setDB("activeQuestHighlight", v) end },
            { type = "checkbox", name = "Show quest item buttons", dbKey = "showQuestItemButtons", tooltip = "Show the usable quest item button on the right of a quest.", get = function() return getDB("showQuestItemButtons", true) end, set = function(v) setDB("showQuestItemButtons", v) end },
        },
    },
    {
        key = "Visibility",
        name = "Visibility",
        options = {
            { type = "section", name = "Filtering" },
            { type = "checkbox", name = "Only show quests in current zone", dbKey = "filterByZone", tooltip = "Hide tracked quests not in your current zone.", get = function() return getDB("filterByZone", false) end, set = function(v) setDB("filterByZone", v) end },
            { type = "section", name = "Rare bosses" },
            { type = "checkbox", name = "Show rare bosses", dbKey = "showRareBosses", get = function() return getDB("showRareBosses", true) end, set = function(v) setDB("showRareBosses", v) end },
            { type = "checkbox", name = "Rare added sound", dbKey = "rareAddedSound", get = function() return getDB("rareAddedSound", true) end, set = function(v) setDB("rareAddedSound", v) end },
        },
    },
    {
        key = "Effects",
        name = "Effects",
        options = {
            { type = "section", name = "Animations" },
            { type = "checkbox", name = "Animations", dbKey = "animations", tooltip = "Enable cinematic slide and fade for quests.", get = function() return getDB("animations", true) end, set = function(v) setDB("animations", v) end },
            { type = "checkbox", name = "Objective progress flash", dbKey = "objectiveProgressFlash", tooltip = "Show a green flash when an objective is completed.", get = function() return getDB("objectiveProgressFlash", true) end, set = function(v) setDB("objectiveProgressFlash", v) end },
        },
    },
}
-- Wire dropdown option tables into descriptors (Font uses GetFontDropdownOptions function)
OptionCategories[1].options[8].options = OUTLINE_OPTIONS -- Outline
OptionCategories[3].options[8].options = HIGHLIGHT_OPTIONS   -- Active quest highlight

-- Forward declaration for CategoryButtonMixin
local UpdateTabVisuals

-- CategoryButtonMixin and CreateCategoryButton
local CategoryButtonMixin = {}
function CategoryButtonMixin:SetCategory(key, name)
    self.categoryKey = key
    self.categoryName = name
    self.label:SetText(name)
end
function CategoryButtonMixin:OnEnter()
    if not self.selected then
        SetTextColor(self.label, Def.TextColorHighlight)
    end
end
function CategoryButtonMixin:OnLeave()
    UpdateTabVisuals()
end
function CategoryButtonMixin:OnClick()
    for i, cat in ipairs(OptionCategories) do
        if cat.key == self.categoryKey then
            selectedTab = i
            UpdateTabVisuals()
            for j = 1, #OptionCategories do
                tabFrames[j]:SetShown(j == i)
            end
            scrollFrame:SetScrollChild(tabFrames[i])
            scrollFrame:SetVerticalScroll(0)
            break
        end
    end
end

local Mixin = Mixin or function(obj, mixin) for k, v in pairs(mixin) do obj[k] = v end return obj end

local function CreateCategoryButton(parent)
    local btn = CreateFrame("Button", nil, parent)
    Mixin(btn, CategoryButtonMixin)
    btn:SetSize(Def.SidebarWidth, Def.SidebarItemHeight)
    btn.label = btn:CreateFontString(nil, "OVERLAY")
    btn.label:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    SetTextColor(btn.label, Def.TextColorSection)
    btn.label:SetPoint("LEFT", btn, "LEFT", 8, 0)
    btn.label:SetJustifyH("LEFT")
    btn.highlight = btn:CreateTexture(nil, "BACKGROUND")
    btn.highlight:SetAllPoints(btn)
    btn.highlight:SetColorTexture(Def.TabSelectedBg[1], Def.TabSelectedBg[2], Def.TabSelectedBg[3], Def.TabSelectedBg[4])
    btn.leftAccent = btn:CreateTexture(nil, "OVERLAY")
    btn.leftAccent:SetWidth(2)
    btn.leftAccent:SetColorTexture(Def.AccentColor[1], Def.AccentColor[2], Def.AccentColor[3], Def.AccentColor[4])
    btn.leftAccent:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    btn.leftAccent:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    btn:SetScript("OnClick", btn.OnClick)
    btn:SetScript("OnEnter", btn.OnEnter)
    btn:SetScript("OnLeave", btn.OnLeave)
    return btn
end

local function CreateSettingsHeader(parent, text)
    return CreateSectionLabel(parent, text)
end

-- Custom checkbox (no template; check drawn with textures)
local CHECK_SIZE = 18
local function CreateMinimalCheckbox(parent)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(CHECK_SIZE, CHECK_SIZE)
    -- Background
    local bg = cb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(cb)
    bg:SetColorTexture(Def.CheckboxBg[1], Def.CheckboxBg[2], Def.CheckboxBg[3], Def.CheckboxBg[4])
    -- 1px border (crisp edges)
    local bc = Def.CheckboxBorder
    local e = 1
    local t1 = cb:CreateTexture(nil, "BORDER"); t1:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t1:SetHeight(e); t1:SetPoint("TOPLEFT", cb, "TOPLEFT", 0, 0); t1:SetPoint("TOPRIGHT", cb, "TOPRIGHT", 0, 0)
    local t2 = cb:CreateTexture(nil, "BORDER"); t2:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t2:SetHeight(e); t2:SetPoint("BOTTOMLEFT", cb, "BOTTOMLEFT", 0, 0); t2:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", 0, 0)
    local t3 = cb:CreateTexture(nil, "BORDER"); t3:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t3:SetWidth(e); t3:SetPoint("TOPLEFT", cb, "TOPLEFT", 0, 0); t3:SetPoint("BOTTOMLEFT", cb, "BOTTOMLEFT", 0, 0)
    local t4 = cb:CreateTexture(nil, "BORDER"); t4:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t4:SetWidth(e); t4:SetPoint("TOPRIGHT", cb, "TOPRIGHT", 0, 0); t4:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", 0, 0)
    -- Check mark: diagonal stroke
    local c = Def.CheckboxCheckColor
    local s = 2
    local strokes = {}
    -- Diagonal bottom-left to top-right
    for i = 0, 5 do
        local t = i / 5
        local x = 3 + t * 12
        local y = -15 + t * 12
        local tex = cb:CreateTexture(nil, "OVERLAY")
        tex:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
        tex:SetSize(s, s)
        tex:SetPoint("TOPLEFT", cb, "TOPLEFT", x, y)
        tex:Hide()
        strokes[#strokes + 1] = tex
    end
    cb.checkMark = strokes
    -- Hover (shown from CreateSettingsEntry OnEnter)
    local hover = cb:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints(cb)
    hover:SetColorTexture(1, 1, 1, 0.06)
    hover:Hide()
    cb.hoverBg = hover
    return cb
end

-- CreateSettingsEntry: checkbox row
local function CreateSettingsEntry(parent, descriptor)
    local cb = CreateMinimalCheckbox(parent)
    local label = cb:CreateFontString(nil, "OVERLAY")
    label:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    SetTextColor(label, Def.TextColorLabel)
    label:SetText(descriptor.name)
    label:SetPoint("LEFT", cb, "RIGHT", 8, 0)
    cb.descriptor = descriptor
    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        if cb.checkMark then
            for _, tex in ipairs(cb.checkMark) do tex:SetShown(checked) end
        end
        descriptor.set(checked)
    end)
    cb:SetScript("OnEnter", function()
        if cb.hoverBg then cb.hoverBg:Show() end
        if descriptor.tooltip and GameTooltip then
            GameTooltip:SetOwner(cb, "ANCHOR_RIGHT")
            GameTooltip:SetText(descriptor.tooltip, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end
    end)
    cb:SetScript("OnLeave", function()
        if cb.hoverBg then cb.hoverBg:Hide() end
        if GameTooltip then GameTooltip:Hide() end
    end)
    function cb:Refresh()
        local checked = descriptor.get()
        self:SetChecked(checked)
        if cb.checkMark then
            for _, tex in ipairs(cb.checkMark) do tex:SetShown(checked) end
        end
    end
    return cb
end

local function CreateNumericRow(parent, descriptor)
    local lab, eb = CreateNumericOption(parent, descriptor.name, descriptor.tooltip, descriptor.get, function(v) descriptor.set(v); notifyMainAddon() end, descriptor.min, descriptor.max)
    eb.descriptor = descriptor
    return lab, eb
end

local function CreateDropdownRow(parent, descriptor)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    InitDropdownMenu(dd, descriptor.options, function(opt)
        descriptor.set(opt[2])
    end)
    local btn
    local name = dd:GetName()
    if name then btn = _G[name .. "Button"] end
    if not btn then
        local n = dd:GetNumChildren()
        for i = 1, n do
            local child = select(i, dd:GetChildren())
            if child and child:GetObjectType() == "Button" then btn = child break end
        end
    end
    if btn then
        btn:SetScript("OnMouseDown", function() ToggleDropdown(dd) end)
        btn:SetScript("OnClick", function() end)
        btn:SetHeight(24)
        local btnText = btn.GetFontString and btn:GetFontString() or (name and _G[name .. "ButtonText"])
        if btnText then
            btnText:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
            btnText:SetTextColor(Def.TextColorLabel[1], Def.TextColorLabel[2], Def.TextColorLabel[3], Def.TextColorLabel[4] or 1)
        end
    end
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    SetTextColor(label, Def.TextColorLabel)
    label:SetText(descriptor.name)
    label:SetPoint("BOTTOMLEFT", dd, "TOPLEFT", 20, 4)
    dd.descriptor = descriptor
    function dd:Refresh()
        local val = descriptor.get()
        local opts = (type(descriptor.options) == "function" and descriptor.options()) or descriptor.options or {}
        for _, opt in ipairs(opts) do
            if opt[2] == val then
                if UIDropDownMenu_SetText then UIDropDownMenu_SetText(self, opt[1]) end
                return
            end
        end
        if UIDropDownMenu_SetText and addon.GetFontNameForPath then
            UIDropDownMenu_SetText(self, addon.GetFontNameForPath(val))
        end
    end
    return dd
end

local function CreateColorRow(parent, descriptor)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(200, 24)
    local lab = row:CreateFontString(nil, "OVERLAY")
    lab:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    SetTextColor(lab, Def.TextColorLabel)
    lab:SetText(descriptor.name)
    lab:SetPoint("LEFT", row, "LEFT", 0, 0)
    local swatch = CreateFrame("Button", nil, row)
    swatch:SetSize(18, 18)
    swatch:SetPoint("LEFT", lab, "RIGHT", 10, 0)
    local tex = swatch:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    local def = descriptor.default or { 0.5, 0.5, 0.5 }
    tex:SetColorTexture(def[1], def[2], def[3], 1)
    do
        local bc = Def.SectionCardBorder
        local e = 1
        local t1 = swatch:CreateTexture(nil, "BORDER"); t1:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t1:SetHeight(e); t1:SetPoint("TOPLEFT", swatch, "TOPLEFT", 0, 0); t1:SetPoint("TOPRIGHT", swatch, "TOPRIGHT", 0, 0)
        local t2 = swatch:CreateTexture(nil, "BORDER"); t2:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t2:SetHeight(e); t2:SetPoint("BOTTOMLEFT", swatch, "BOTTOMLEFT", 0, 0); t2:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", 0, 0)
        local t3 = swatch:CreateTexture(nil, "BORDER"); t3:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t3:SetWidth(e); t3:SetPoint("TOPLEFT", swatch, "TOPLEFT", 0, 0); t3:SetPoint("BOTTOMLEFT", swatch, "BOTTOMLEFT", 0, 0)
        local t4 = swatch:CreateTexture(nil, "BORDER"); t4:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t4:SetWidth(e); t4:SetPoint("TOPRIGHT", swatch, "TOPRIGHT", 0, 0); t4:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", 0, 0)
    end
    swatch.tex = tex
    swatch.descriptor = descriptor
    swatch:SetScript("OnClick", function(self)
        local d = self.descriptor
        local db = d.get()
        local r, g, b = d.default[1], d.default[2], d.default[3]
        if db and #db >= 3 then r, g, b = db[1], db[2], db[3] end
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, hasOpacity = false,
            swatchFunc = function() addon.EnsureDB(); local nr, ng, nb = ColorPickerFrame:GetColorRGB(); ModernQuestTrackerDB[d.dbKey] = { nr, ng, nb }; self.tex:SetColorTexture(nr, ng, nb, 1); notifyMainAddon() end,
            cancelFunc = function() local prev = ColorPickerFrame.previousValues; if prev then d.set({ prev.r, prev.g, prev.b }) end end,
            finishedFunc = function() local nr, ng, nb = ColorPickerFrame:GetColorRGB(); d.set({ nr, ng, nb }); notifyMainAddon() end,
        })
    end)
    function swatch:Refresh()
        local db = descriptor.get()
        local r, g, b = def[1], def[2], def[3]
        if db and #db >= 3 then r, g, b = db[1], db[2], db[3] end
        self.tex:SetColorTexture(r, g, b, 1)
    end
    local defaultBtn = CreateFrame("Button", nil, row)
    defaultBtn:SetSize(60, 20)
    defaultBtn:SetPoint("LEFT", swatch, "RIGHT", 12, 0)
    local defaultLabel = defaultBtn:CreateFontString(nil, "OVERLAY")
    defaultLabel:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    SetTextColor(defaultLabel, Def.TextColorLabel)
    defaultLabel:SetText("Default")
    defaultLabel:SetPoint("CENTER", defaultBtn, "CENTER", 0, 0)
    defaultBtn:SetScript("OnClick", function()
        descriptor.set(nil)
        if ModernQuestTrackerDB then ModernQuestTrackerDB[descriptor.dbKey] = nil end
        swatch.tex:SetColorTexture(def[1], def[2], def[3], 1)
        notifyMainAddon()
    end)
    row.Refresh = function() swatch:Refresh() end
    return row
end

-- Build one category's content (section cards)
local function BuildContentFromOptions(tab, options, refreshers)
    local anchor = tab.topAnchor
    local currentCard = nil
    for _, opt in ipairs(options) do
        if opt.type == "section" then
            if currentCard then
                FinalizeSectionCard(currentCard)
            end
            local card = CreateSectionCard(tab, anchor)
            local lbl = CreateSectionLabel(card, opt.name)
            lbl:SetPoint("TOPLEFT", card, "TOPLEFT", Def.CardPadding, -Def.CardPadding)
            card.contentAnchor = lbl
            card.contentHeight = Def.CardPadding + ROW_HEIGHTS.sectionLabel
            currentCard = card
            anchor = card
        elseif opt.type == "checkbox" then
            local entry = CreateSettingsEntry(currentCard, opt)
            entry:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -Def.OptionGap)
            currentCard.contentHeight = currentCard.contentHeight + Def.OptionGap + ROW_HEIGHTS.checkbox
            currentCard.contentAnchor = entry
            table.insert(refreshers, entry)
        elseif opt.type == "numeric" then
            local lab, eb = CreateNumericRow(currentCard, opt)
            lab:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -Def.OptionGap)
            eb:SetPoint("LEFT", currentCard, "LEFT", NUMERIC_INPUT_OFFSET, 0)
            eb:SetPoint("TOP", lab, "TOP", 0, 0)
            currentCard.contentHeight = currentCard.contentHeight + Def.OptionGap + ROW_HEIGHTS.numeric
            currentCard.contentAnchor = lab
            table.insert(refreshers, eb)
        elseif opt.type == "dropdown" then
            local dd = CreateDropdownRow(currentCard, opt)
            dd:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -(Def.OptionGap + DROPDOWN_LABEL_SPACE))
            currentCard.contentHeight = currentCard.contentHeight + Def.OptionGap + DROPDOWN_LABEL_SPACE + ROW_HEIGHTS.dropdown + ROW_HEIGHTS.dropdownListReserve
            currentCard.contentAnchor = dd
            table.insert(refreshers, dd)
        elseif opt.type == "color" then
            local row = CreateColorRow(currentCard, opt)
            row:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -4)
            currentCard.contentHeight = currentCard.contentHeight + 4 + ROW_HEIGHTS.colorRow
            currentCard.contentAnchor = row
            table.insert(refreshers, row)
        elseif opt.type == "colorGroup" then
            local keys = opt.keys or COLOR_KEYS_ORDER
            local defaultMap = opt.defaultMap or QUEST_COLOR_DEFAULTS
            local sectionLabel = CreateSectionLabel(currentCard, opt.name)
            sectionLabel:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -Def.SectionGap)
            currentCard.contentAnchor = sectionLabel
            currentCard.contentHeight = currentCard.contentHeight + Def.SectionGap + ROW_HEIGHTS.colorGroupLabel
            local swatches = {}
            for i, key in ipairs(keys) do
                local row = CreateFrame("Frame", nil, currentCard)
                row:SetSize(200, 24)
                row:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -4)
                currentCard.contentHeight = currentCard.contentHeight + 4 + ROW_HEIGHTS.colorGroupRow
                currentCard.contentAnchor = row
                local lab = row:CreateFontString(nil, "OVERLAY")
                lab:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
                SetTextColor(lab, Def.TextColorLabel)
                lab:SetText(key:gsub("^%l", string.upper))
                lab:SetPoint("LEFT", row, "LEFT", 0, 0)
                local swatch = CreateFrame("Button", nil, row)
                swatch:SetSize(18, 18)
                swatch:SetPoint("LEFT", lab, "RIGHT", 10, 0)
                local tex = swatch:CreateTexture(nil, "BACKGROUND")
                tex:SetAllPoints()
                local def = defaultMap[key]
                tex:SetColorTexture(def[1], def[2], def[3], 1)
                do
                    local bc = Def.SectionCardBorder
                    local e = 1
                    local t1 = swatch:CreateTexture(nil, "BORDER"); t1:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t1:SetHeight(e); t1:SetPoint("TOPLEFT", swatch, "TOPLEFT", 0, 0); t1:SetPoint("TOPRIGHT", swatch, "TOPRIGHT", 0, 0)
                    local t2 = swatch:CreateTexture(nil, "BORDER"); t2:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t2:SetHeight(e); t2:SetPoint("BOTTOMLEFT", swatch, "BOTTOMLEFT", 0, 0); t2:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", 0, 0)
                    local t3 = swatch:CreateTexture(nil, "BORDER"); t3:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t3:SetWidth(e); t3:SetPoint("TOPLEFT", swatch, "TOPLEFT", 0, 0); t3:SetPoint("BOTTOMLEFT", swatch, "BOTTOMLEFT", 0, 0)
                    local t4 = swatch:CreateTexture(nil, "BORDER"); t4:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t4:SetWidth(e); t4:SetPoint("TOPRIGHT", swatch, "TOPRIGHT", 0, 0); t4:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", 0, 0)
                end
                swatch.key = key
                swatch.tex = tex
                swatch:SetScript("OnClick", function(self)
                    local k = self.key
                    local dbColors = getDB(opt.dbKey, nil)
                    local r, g, b = defaultMap[k][1], defaultMap[k][2], defaultMap[k][3]
                    if dbColors and dbColors[k] then r, g, b = dbColors[k][1], dbColors[k][2], dbColors[k][3] end
                    local function apply(nr, ng, nb)
                        addon.EnsureDB()
                        if not ModernQuestTrackerDB[opt.dbKey] then ModernQuestTrackerDB[opt.dbKey] = {} end
                        ModernQuestTrackerDB[opt.dbKey][k] = { nr, ng, nb }
                        self.tex:SetColorTexture(nr, ng, nb, 1)
                        notifyMainAddon()
                    end
                    ColorPickerFrame:SetupColorPickerAndShow({
                        r = r, g = g, b = b, hasOpacity = false,
                        swatchFunc = function() local nr, ng, nb = ColorPickerFrame:GetColorRGB(); apply(nr, ng, nb) end,
                        cancelFunc = function() local prev = ColorPickerFrame.previousValues; if prev then apply(prev.r, prev.g, prev.b) end end,
                        finishedFunc = function() local nr, ng, nb = ColorPickerFrame:GetColorRGB(); apply(nr, ng, nb) end,
                    })
                end)
                function swatch:Refresh()
                    local dbColors = getDB(opt.dbKey, nil)
                    local r, g, b = defaultMap[self.key][1], defaultMap[self.key][2], defaultMap[self.key][3]
                    if dbColors and dbColors[self.key] then r, g, b = dbColors[self.key][1], dbColors[self.key][2], dbColors[self.key][3] end
                    self.tex:SetColorTexture(r, g, b, 1)
                end
                swatches[i] = swatch
            end
            local resetBtn = CreateFrame("Button", nil, currentCard)
            resetBtn:SetSize(120, 22)
            resetBtn:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -6)
            currentCard.contentHeight = currentCard.contentHeight + 6 + ROW_HEIGHTS.resetBtn
            currentCard.contentAnchor = resetBtn
            local resetLabel = resetBtn:CreateFontString(nil, "OVERLAY")
            resetLabel:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
            SetTextColor(resetLabel, Def.TextColorLabel)
            resetLabel:SetText("Reset to defaults")
            resetLabel:SetPoint("CENTER", resetBtn, "CENTER", 0, 0)
            resetBtn:SetScript("OnClick", function()
                setDB(opt.dbKey, nil)
                if opt.resetSectionKeys and ModernQuestTrackerDB then ModernQuestTrackerDB.sectionColors = nil end
                for _, sw in ipairs(swatches) do if sw.Refresh then sw:Refresh() end end
                notifyMainAddon()
            end)
            table.insert(refreshers, { Refresh = function() for _, sw in ipairs(swatches) do sw:Refresh() end end })
        elseif opt.type == "colorMatrix" then
            if currentCard then
                FinalizeSectionCard(currentCard)
            end
            local card = CreateSectionCard(tab, anchor)
            local lbl = CreateSectionLabel(card, opt.name or "Colors")
            lbl:SetPoint("TOPLEFT", card, "TOPLEFT", Def.CardPadding, -Def.CardPadding)
            card.contentAnchor = lbl
            card.contentHeight = Def.CardPadding + ROW_HEIGHTS.sectionLabel
            currentCard = card
            anchor = card

            local keys = opt.keys or COLOR_KEYS_ORDER
            local defaultMap = opt.defaultMap or QUEST_COLOR_DEFAULTS
            local questSub = CreateSectionLabel(currentCard, "Quest type colors (titles, objectives, headers)")
            questSub:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -Def.SectionGap)
            currentCard.contentAnchor = questSub
            currentCard.contentHeight = currentCard.contentHeight + Def.SectionGap + ROW_HEIGHTS.colorGroupLabel
            local questSwatches = {}
            for i, key in ipairs(keys) do
                local row = CreateFrame("Frame", nil, currentCard)
                row:SetSize(200, 24)
                row:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -4)
                currentCard.contentHeight = currentCard.contentHeight + 4 + ROW_HEIGHTS.colorGroupRow
                currentCard.contentAnchor = row
                local lab = row:CreateFontString(nil, "OVERLAY")
                lab:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
                SetTextColor(lab, Def.TextColorLabel)
                lab:SetText(key:gsub("^%l", string.upper))
                lab:SetPoint("LEFT", row, "LEFT", 0, 0)
                local swatch = CreateFrame("Button", nil, row)
                swatch:SetSize(18, 18)
                swatch:SetPoint("LEFT", lab, "RIGHT", 10, 0)
                local tex = swatch:CreateTexture(nil, "BACKGROUND")
                tex:SetAllPoints()
                local def = defaultMap[key]
                tex:SetColorTexture(def[1], def[2], def[3], 1)
                do
                    local bc = Def.SectionCardBorder
                    local e = 1
                    local t1 = swatch:CreateTexture(nil, "BORDER"); t1:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t1:SetHeight(e); t1:SetPoint("TOPLEFT", swatch, "TOPLEFT", 0, 0); t1:SetPoint("TOPRIGHT", swatch, "TOPRIGHT", 0, 0)
                    local t2 = swatch:CreateTexture(nil, "BORDER"); t2:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t2:SetHeight(e); t2:SetPoint("BOTTOMLEFT", swatch, "BOTTOMLEFT", 0, 0); t2:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", 0, 0)
                    local t3 = swatch:CreateTexture(nil, "BORDER"); t3:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t3:SetWidth(e); t3:SetPoint("TOPLEFT", swatch, "TOPLEFT", 0, 0); t3:SetPoint("BOTTOMLEFT", swatch, "BOTTOMLEFT", 0, 0)
                    local t4 = swatch:CreateTexture(nil, "BORDER"); t4:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t4:SetWidth(e); t4:SetPoint("TOPRIGHT", swatch, "TOPRIGHT", 0, 0); t4:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", 0, 0)
                end
                swatch.key = key
                swatch.tex = tex
                swatch:SetScript("OnClick", function(self)
                    local k = self.key
                    local dbColors = getDB(opt.dbKey, nil)
                    local r, g, b = defaultMap[k][1], defaultMap[k][2], defaultMap[k][3]
                    if dbColors and dbColors[k] then r, g, b = dbColors[k][1], dbColors[k][2], dbColors[k][3] end
                    local function apply(nr, ng, nb)
                        addon.EnsureDB()
                        if not ModernQuestTrackerDB[opt.dbKey] then ModernQuestTrackerDB[opt.dbKey] = {} end
                        ModernQuestTrackerDB[opt.dbKey][k] = { nr, ng, nb }
                        self.tex:SetColorTexture(nr, ng, nb, 1)
                        notifyMainAddon()
                    end
                    ColorPickerFrame:SetupColorPickerAndShow({
                        r = r, g = g, b = b, hasOpacity = false,
                        swatchFunc = function() local nr, ng, nb = ColorPickerFrame:GetColorRGB(); apply(nr, ng, nb) end,
                        cancelFunc = function() local prev = ColorPickerFrame.previousValues; if prev then apply(prev.r, prev.g, prev.b) end end,
                        finishedFunc = function() local nr, ng, nb = ColorPickerFrame:GetColorRGB(); apply(nr, ng, nb) end,
                    })
                end)
                function swatch:Refresh()
                    local dbColors = getDB(opt.dbKey, nil)
                    local r, g, b = defaultMap[self.key][1], defaultMap[self.key][2], defaultMap[self.key][3]
                    if dbColors and dbColors[self.key] then r, g, b = dbColors[self.key][1], dbColors[self.key][2], dbColors[self.key][3] end
                    self.tex:SetColorTexture(r, g, b, 1)
                end
                questSwatches[i] = swatch
            end
            local resetQuestBtn = CreateFrame("Button", nil, currentCard)
            resetQuestBtn:SetSize(140, 22)
            resetQuestBtn:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -6)
            currentCard.contentHeight = currentCard.contentHeight + 6 + ROW_HEIGHTS.resetBtn
            currentCard.contentAnchor = resetQuestBtn
            local resetQuestLabel = resetQuestBtn:CreateFontString(nil, "OVERLAY")
            resetQuestLabel:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
            SetTextColor(resetQuestLabel, Def.TextColorLabel)
            resetQuestLabel:SetText("Reset quest types")
            resetQuestLabel:SetPoint("CENTER", resetQuestBtn, "CENTER", 0, 0)
            resetQuestBtn:SetScript("OnClick", function()
                setDB(opt.dbKey, nil)
                if opt.resetSectionKeys and ModernQuestTrackerDB then ModernQuestTrackerDB.sectionColors = nil end
                for _, sw in ipairs(questSwatches) do if sw.Refresh then sw:Refresh() end end
                notifyMainAddon()
            end)

            local div = CreateDivider(currentCard, 400)
            div:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -Def.SectionGap)
            currentCard.contentHeight = currentCard.contentHeight + Def.SectionGap + Def.DividerHeight
            currentCard.contentAnchor = div
            local overridesSub = CreateSectionLabel(currentCard, "Element overrides")
            overridesSub:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -Def.SectionGap)
            currentCard.contentAnchor = overridesSub
            currentCard.contentHeight = currentCard.contentHeight + Def.SectionGap + ROW_HEIGHTS.colorGroupLabel

            local overrideRows = {}
            for _, ov in ipairs(opt.overrides or {}) do
                local desc = { type = "color", name = ov.name, dbKey = ov.dbKey, default = ov.default, tooltip = ov.tooltip,
                    get = function() return getDB(ov.dbKey, nil) end,
                    set = function(v) setDB(ov.dbKey, v) end }
                local row = CreateColorRow(currentCard, desc)
                row:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -4)
                currentCard.contentHeight = currentCard.contentHeight + 4 + ROW_HEIGHTS.colorRow
                currentCard.contentAnchor = row
                table.insert(overrideRows, row)
            end
            local resetOverridesBtn = CreateFrame("Button", nil, currentCard)
            resetOverridesBtn:SetSize(140, 22)
            resetOverridesBtn:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -6)
            currentCard.contentHeight = currentCard.contentHeight + 6 + ROW_HEIGHTS.resetBtn
            currentCard.contentAnchor = resetOverridesBtn
            local resetOverridesLabel = resetOverridesBtn:CreateFontString(nil, "OVERLAY")
            resetOverridesLabel:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
            SetTextColor(resetOverridesLabel, Def.TextColorLabel)
            resetOverridesLabel:SetText("Reset overrides")
            resetOverridesLabel:SetPoint("CENTER", resetOverridesBtn, "CENTER", 0, 0)
            resetOverridesBtn:SetScript("OnClick", function()
                for _, ov in ipairs(opt.overrides or {}) do
                    setDB(ov.dbKey, nil)
                end
                for _, r in ipairs(overrideRows) do if r.Refresh then r:Refresh() end end
                notifyMainAddon()
            end)
            table.insert(refreshers, { Refresh = function()
                for _, sw in ipairs(questSwatches) do if sw.Refresh then sw:Refresh() end end
                for _, r in ipairs(overrideRows) do if r.Refresh then r:Refresh() end end
            end })
        elseif opt.type == "hint" then
            local hint = currentCard:CreateFontString(nil, "OVERLAY")
            hint:SetFont(Def.FontPath, Def.SectionSize, "OUTLINE")
            SetTextColor(hint, Def.TextColorSection)
            hint:SetText(opt.text or "")
            hint:SetPoint("TOPLEFT", currentCard.contentAnchor, "BOTTOMLEFT", 0, -4)
            currentCard.contentHeight = currentCard.contentHeight + 4 + ROW_HEIGHTS.hint
            currentCard.contentAnchor = hint
        end
    end
    if currentCard then
        FinalizeSectionCard(currentCard)
    end
end

local allRefreshers = {}
UpdateTabVisuals = function()
    for i, btn in ipairs(tabButtons) do
        local isSelected = (i == selectedTab)
        btn.selected = isSelected
        if isSelected then
            SetTextColor(btn.label, Def.TextColorNormal)
        else
            SetTextColor(btn.label, Def.TextColorSection)
        end
        if btn.leftAccent then btn.leftAccent:SetShown(isSelected) end
        if btn.highlight then btn.highlight:SetShown(isSelected) end
    end
end

-- Build sidebar from OptionCategories
for i, cat in ipairs(OptionCategories) do
    local btn = CreateCategoryButton(sidebar)
    if i == 1 then
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, 0)
    else
        btn:SetPoint("TOPLEFT", tabButtons[i - 1], "BOTTOMLEFT", 0, 0)
    end
    btn:SetCategory(cat.key, cat.name)
    tabButtons[i] = btn
end

-- Build center content from OptionCategories
for i, cat in ipairs(OptionCategories) do
    local refreshers = {}
    BuildContentFromOptions(tabFrames[i], cat.options, refreshers)
    for _, r in ipairs(refreshers) do
        table.insert(allRefreshers, r)
    end
end

-- Update options panel fonts from DB (when shown or when font option changes)
updateOptionsPanelFonts = function()
    if not panel or not panel:IsShown() then return end
    local path = Def.FontPath
    titleShadow:SetFont(path, Def.HeaderSize, "OUTLINE")
    titleText:SetFont(path, Def.HeaderSize, "OUTLINE")
    closeLabel:SetFont(path, Def.LabelSize, "OUTLINE")
    for _, btn in ipairs(tabButtons) do
        if btn.label then btn.label:SetFont(path, Def.LabelSize, "OUTLINE") end
    end
end

-- Open/close animation (fade, optional slide)
local ANIM_DUR = 0.2
local easeOut = addon.easeOut or function(t) return 1 - (1 - t) * (1 - t) end

panel:SetScript("OnShow", function()
    Def.FontPath = addon.GetDB("fontPath", (addon.GetDefaultFontPath and addon.GetDefaultFontPath()) or "Fonts\\FRIZQT__.TTF")
    if updateOptionsPanelFonts then updateOptionsPanelFonts() end
    local db = ModernQuestTrackerDB
    if db and db.optionsLeft ~= nil and db.optionsTop ~= nil then
        panel:ClearAllPoints()
        panel:SetPoint("CENTER", UIParent, "CENTER", db.optionsLeft, db.optionsTop)
    else
        panel:ClearAllPoints()
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    for _, ref in ipairs(allRefreshers) do
        if ref and ref.Refresh then ref:Refresh() end
    end
    -- Fade in
    panel:SetAlpha(0)
    panel.animStart = GetTime()
    panel.animating = "in"
    panel:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - self.animStart
        if elapsed >= ANIM_DUR then
            self:SetAlpha(1)
            self:SetScript("OnUpdate", nil)
            self.animating = nil
            return
        end
        self:SetAlpha(easeOut(elapsed / ANIM_DUR))
    end)
end)

function _G.ModernQuestTracker_OptionsRequestClose()
    if panel.animating == "out" then return end
    panel.animating = "out"
    panel.animStart = GetTime()
    panel:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - self.animStart
        if elapsed >= ANIM_DUR then
            self:SetAlpha(1)
            self:SetScript("OnUpdate", nil)
            self.animating = nil
            self:Hide()
            return
        end
        self:SetAlpha(1 - easeOut(elapsed / ANIM_DUR))
    end)
end

-- Expose for /horizon options and tracker gear button
function _G.ModernQuestTracker_ShowOptions()
    local p = _G.ModernQuestTrackerOptionsPanel
    if p then
        if p:IsShown() then
            if _G.ModernQuestTracker_OptionsRequestClose then _G.ModernQuestTracker_OptionsRequestClose()
            else p:Hide() end
        else
            p:Show()
        end
    end
end
