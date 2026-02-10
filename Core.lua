--[[
    Horizon Suite - Focus - Core
    Addon namespace, configuration, easing, and main frame (MQT + scroll).
]]

if not _G.ModernQuestTracker then _G.ModernQuestTracker = {} end
local addon = _G.ModernQuestTracker

-- Migrate from legacy ModernQuestTrackerDB to HorizonSuiteDB (rebrand)
if ModernQuestTrackerDB and (not HorizonSuiteDB or not next(HorizonSuiteDB)) then
    HorizonSuiteDB = ModernQuestTrackerDB
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

-- Default: use game font path so it works across locales/patches (set explicitly before font object creation)
addon.FONT_PATH       = nil
addon.HEADER_SIZE     = 16
addon.TITLE_SIZE      = 13
addon.OBJ_SIZE        = 11

addon.POOL_SIZE       = 25
addon.MAX_OBJECTIVES  = 7

addon.PANEL_WIDTH     = 260
addon.PANEL_X         = -40
addon.PANEL_Y         = -100
addon.PADDING              = 14
addon.CONTENT_RIGHT_PADDING = 20
addon.HEADER_HEIGHT         = 28
addon.DIVIDER_HEIGHT  = 2
addon.TITLE_SPACING   = 8
addon.OBJ_SPACING     = 2
addon.OBJ_INDENT      = 12
addon.COMPACT_TITLE_SPACING = 4
addon.COMPACT_OBJ_SPACING   = 1
addon.COMPACT_OBJ_INDENT    = 8
addon.MIN_HEIGHT      = 50

function addon.GetTitleSpacing()
    return addon.GetDB("compactMode", false) and addon.COMPACT_TITLE_SPACING or addon.TITLE_SPACING
end
function addon.GetObjSpacing()
    return addon.GetDB("compactMode", false) and addon.COMPACT_OBJ_SPACING or addon.OBJ_SPACING
end
function addon.GetObjIndent()
    return addon.GetDB("compactMode", false) and addon.COMPACT_OBJ_INDENT or addon.OBJ_INDENT
end

addon.MAX_CONTENT_HEIGHT = 480
addon.SCROLL_STEP        = 30

addon.ITEM_BTN_SIZE   = 26
addon.ITEM_BTN_OFFSET = 4

addon.QUEST_TYPE_ICON_SIZE = 16
addon.QUEST_TYPE_ICON_GAP  = 4
addon.ICON_COLUMN_WIDTH    = addon.QUEST_TYPE_ICON_SIZE + addon.QUEST_TYPE_ICON_GAP
addon.BAR_LEFT_OFFSET      = 12  -- space from entry left (more = more gap between bar and quest type icon)
addon.TRACKED_OTHER_ZONE_ICON_SIZE = 12

addon.SHADOW_OX       = 2
addon.SHADOW_OY       = -2
addon.SHADOW_A        = 0.8

addon.FADE_IN_DUR     = 0.4
addon.FADE_OUT_DUR    = 0.4
addon.COMPLETE_HOLD   = 0.50
addon.HEIGHT_SPEED    = 8
addon.FLASH_DUR       = 0.35

addon.SLIDE_IN_X      = 20
addon.SLIDE_OUT_X     = 20
addon.DRIFT_OUT_Y     = 10
addon.ENTRY_STAGGER   = 0.05
addon.COLLAPSE_DUR    = 0.4
addon.COMBAT_FADE_DUR = 0.4

addon.HEADER_COLOR    = { 1, 1, 1 }
addon.DIVIDER_COLOR   = { 1, 1, 1, 0.5 }
addon.OBJ_COLOR       = { 0.78, 0.78, 0.78 }
addon.OBJ_DONE_COLOR  = { 0.30, 0.80, 0.30 }
addon.ZONE_SIZE       = 10
addon.ZONE_COLOR      = { 0.55, 0.65, 0.75 }

addon.QUEST_COLORS = {
    DEFAULT   = { 0.90, 0.90, 0.90 },
    CAMPAIGN  = { 1.00, 0.82, 0.20 },
    IMPORTANT = { 1.00, 0.45, 0.80 },  -- pink to match importantavailablequesticon
    LEGENDARY = { 1.00, 0.50, 0.00 },
    WORLD     = { 0.60, 0.20, 1.00 },
    CALLING   = { 0.20, 0.60, 1.00 },
    COMPLETE  = { 0.20, 1.00, 0.40 },
    RARE      = { 1.00, 0.55, 0.25 },
}

addon.SECTION_SIZE      = 10
addon.SECTION_SPACING   = 10
addon.SECTION_COLOR_A   = 1
addon.SECTION_POOL_SIZE = 8

-- Default font path from the game (must be defined before font object creation)
function addon.GetDefaultFontPath()
    local path = GameFontNormal and GameFontNormal:GetFont()
    if path and path ~= "" then return path end
    return "Fonts\\FRIZQT__.TTF"
end

-- Master Font Objects (source of truth for display; updated from DB by UpdateFontObjectsFromDB)
addon.FONT_PATH = addon.GetDefaultFontPath()
addon.HeaderFont  = CreateFont("HorizonSuiteHeaderFont")
addon.HeaderFont:SetFont(addon.FONT_PATH, addon.HEADER_SIZE, "OUTLINE")
addon.TitleFont   = CreateFont("HorizonSuiteTitleFont")
addon.TitleFont:SetFont(addon.FONT_PATH, addon.TITLE_SIZE, "OUTLINE")
addon.ObjFont     = CreateFont("HorizonSuiteObjFont")
addon.ObjFont:SetFont(addon.FONT_PATH, addon.OBJ_SIZE, "OUTLINE")
addon.ZoneFont    = CreateFont("HorizonSuiteZoneFont")
addon.ZoneFont:SetFont(addon.FONT_PATH, addon.ZONE_SIZE, "OUTLINE")
addon.SectionFont = CreateFont("HorizonSuiteSectionFont")
addon.SectionFont:SetFont(addon.FONT_PATH, addon.SECTION_SIZE, "OUTLINE")

addon.SECTION_LABELS = {
    DUNGEON   = "IN THIS DUNGEON",
    AVAILABLE = "AVAILABLE IN ZONE",
    NEARBY    = "CURRENT ZONE",
    CAMPAIGN  = "CAMPAIGN",
    IMPORTANT = "IMPORTANT",
    LEGENDARY = "LEGENDARY",
    WORLD     = "WORLD QUESTS",
    RARES     = "RARE BOSSES",
    DEFAULT   = "QUESTS",
    COMPLETE  = "READY TO TURN IN",
}

addon.SECTION_COLORS = {
    DUNGEON   = { 0.60, 0.40, 1.00 },
    AVAILABLE = { 0.25, 0.88, 0.92 },  -- cyan/teal (available to pick up)
    NEARBY    = { 0.35, 0.75, 0.98 },  -- sky blue (accepted, in zone)
    CAMPAIGN  = { 1.00, 0.82, 0.20 },
    IMPORTANT = { 1.00, 0.45, 0.80 },  -- pink to match importantavailablequesticon
    LEGENDARY = { 1.00, 0.50, 0.00 },
    WORLD     = { 0.60, 0.20, 1.00 },
    RARES     = { 1.00, 0.55, 0.25 },
    DEFAULT   = { 0.70, 0.70, 0.70 },
    COMPLETE  = { 0.20, 1.00, 0.40 },
}

addon.GROUP_ORDER = { "DUNGEON", "COMPLETE", "WORLD", "RARES", "NEARBY", "AVAILABLE", "CAMPAIGN", "IMPORTANT", "LEGENDARY", "DEFAULT" }

addon.CATEGORY_TO_GROUP = {
    COMPLETE  = "COMPLETE",
    LEGENDARY = "LEGENDARY",
    IMPORTANT = "IMPORTANT",
    CAMPAIGN  = "CAMPAIGN",
    WORLD     = "WORLD",
    CALLING   = "WORLD",
    DEFAULT   = "DEFAULT",
}

-- Persisted Focus category order (validated, fallback to addon.GROUP_ORDER)
function addon.GetGroupOrder()
    local default = addon.GROUP_ORDER
    local saved = addon.GetDB("groupOrder", nil)
    if not saved or type(saved) ~= "table" or #saved == 0 then
        return default
    end
    local seen = {}
    local result = {}
    for _, key in ipairs(default) do
        seen[key] = true
    end
    for _, key in ipairs(saved) do
        if type(key) == "string" and seen[key] then
            result[#result + 1] = key
            seen[key] = nil
        end
    end
    for _, key in ipairs(default) do
        if seen[key] then
            result[#result + 1] = key
        end
    end
    return result
end

function addon.SetGroupOrder(order)
    if not order or type(order) ~= "table" then return end
    addon.EnsureDB()
    local default = addon.GROUP_ORDER
    local seen = {}
    for _, key in ipairs(default) do
        seen[key] = true
    end
    local result = {}
    for _, key in ipairs(order) do
        if type(key) == "string" and seen[key] then
            result[#result + 1] = key
            seen[key] = nil
        end
    end
    for _, key in ipairs(default) do
        if seen[key] then
            result[#result + 1] = key
        end
    end
    HorizonSuiteDB.groupOrder = result
end

function addon.GetDB(key, default)
    if not HorizonSuiteDB then return default end
    local v = HorizonSuiteDB[key]
    if v == nil then return default end
    return v
end

function addon.ShouldHideInCombat()
    return addon.GetDB("hideInCombat", false) and UnitAffectingCombat("player")
end

function addon.EnsureDB()
    if not HorizonSuiteDB then HorizonSuiteDB = {} end
end

-- Per-category collapse state ------------------------------------------------

local function EnsureCollapsedCategories()
    addon.EnsureDB()
    if not HorizonSuiteDB.collapsedCategories then
        HorizonSuiteDB.collapsedCategories = {}
    end
    return HorizonSuiteDB.collapsedCategories
end

function addon.IsCategoryCollapsed(groupKey)
    if not HorizonSuiteDB or not HorizonSuiteDB.collapsedCategories then
        return false
    end
    return HorizonSuiteDB.collapsedCategories[groupKey] == true
end

function addon.SetCategoryCollapsed(groupKey, collapsed)
    if not groupKey then return end
    local tbl = EnsureCollapsedCategories()
    if collapsed then
        tbl[groupKey] = true
    else
        -- Missing/nil means expanded by default.
        tbl[groupKey] = nil
    end
end

function addon.ToggleCategoryCollapsed(groupKey)
    if not groupKey then return false end
    local newState = not addon.IsCategoryCollapsed(groupKey)
    addon.SetCategoryCollapsed(groupKey, newState)
    return newState
end

-- Font list: "Game Font" first, then LibSharedMedia fonts if available
local fontListNames, fontListPaths = {}, {}
function addon.RefreshFontList()
    table.wipe(fontListNames)
    table.wipe(fontListPaths)
    local gamePath = addon.GetDefaultFontPath()
    fontListNames[1] = "Game Font"
    fontListPaths[1] = gamePath
    local LSM = (LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)) or nil
    if LSM and LSM.HashTable and LSM:HashTable("font") then
        local t = {}
        for name, path in pairs(LSM:HashTable("font")) do
            t[#t + 1] = { name = name, path = path }
        end
        table.sort(t, function(a, b) return (a.name or "") < (b.name or "") end)
        for _, f in ipairs(t) do
            fontListNames[#fontListNames + 1] = f.name
            fontListPaths[#fontListPaths + 1] = f.path
        end
    end
end

function addon.GetFontList()
    if #fontListNames == 0 then addon.RefreshFontList() end
    local list = {}
    for i = 1, #fontListNames do
        list[i] = { fontListNames[i], fontListPaths[i] }
    end
    return list
end

function addon.GetFontPathForIndex(index)
    if #fontListPaths == 0 then addon.RefreshFontList() end
    if not index or index < 1 or index > #fontListPaths then return addon.GetDefaultFontPath() end
    return fontListPaths[index]
end

function addon.GetFontNameForPath(path)
    if #fontListNames == 0 then addon.RefreshFontList() end
    for i = 1, #fontListPaths do
        if fontListPaths[i] == path then return fontListNames[i] end
    end
    return "Custom"
end

-- Legacy: static list used if no LSM; GetFontList() is the source of truth for the dropdown
addon.FONT_LIST = {
    { "Friz Quadrata (Default)", "Fonts\\FRIZQT__.TTF" },
    { "Arial Narrow", "Fonts\\ARIALN.ttf" },
    { "Morpheus", "Fonts\\MORPHEUS.ttf" },
    { "Skurri", "Fonts\\skurri.ttf" },
}

function addon.GetPanelWidth()
    return tonumber(addon.GetDB("panelWidth", addon.PANEL_WIDTH)) or addon.PANEL_WIDTH
end
function addon.GetMaxContentHeight()
    return tonumber(addon.GetDB("maxContentHeight", addon.MAX_CONTENT_HEIGHT)) or addon.MAX_CONTENT_HEIGHT
end

-- ============================================================================
-- EASING FUNCTIONS
-- ============================================================================

function addon.easeOut(t)  return 1 - (1 - t) * (1 - t) end
function addon.easeIn(t)   return t * t end

-- ============================================================================
-- FRAME SETUP
-- ============================================================================

local MQT = CreateFrame("Frame", "ModernQuestTrackerFrame", UIParent)
MQT:SetSize(addon.GetPanelWidth(), addon.MIN_HEIGHT)
MQT:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", addon.PANEL_X, addon.PANEL_Y)
MQT:SetFrameStrata("MEDIUM")
MQT:SetClampedToScreen(true)
MQT:Hide()

local mqtBg = MQT:CreateTexture(nil, "BACKGROUND")
mqtBg:SetAllPoints(MQT)
mqtBg:SetColorTexture(0.08, 0.08, 0.12, 0.9)
addon.mqtBg = mqtBg

local BORDER_COLOR = { 0.35, 0.38, 0.45, 0.45 }
local mqtBorderT = MQT:CreateTexture(nil, "BORDER")
mqtBorderT:SetColorTexture(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
mqtBorderT:SetHeight(1)
mqtBorderT:SetPoint("TOPLEFT", MQT, "TOPLEFT", 0, 0)
mqtBorderT:SetPoint("TOPRIGHT", MQT, "TOPRIGHT", 0, 0)
local mqtBorderB = MQT:CreateTexture(nil, "BORDER")
mqtBorderB:SetColorTexture(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
mqtBorderB:SetHeight(1)
mqtBorderB:SetPoint("BOTTOMLEFT", MQT, "BOTTOMLEFT", 0, 0)
mqtBorderB:SetPoint("BOTTOMRIGHT", MQT, "BOTTOMRIGHT", 0, 0)
local mqtBorderL = MQT:CreateTexture(nil, "BORDER")
mqtBorderL:SetColorTexture(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
mqtBorderL:SetWidth(1)
mqtBorderL:SetPoint("TOPLEFT", MQT, "TOPLEFT", 0, 0)
mqtBorderL:SetPoint("BOTTOMLEFT", MQT, "BOTTOMLEFT", 0, 0)
local mqtBorderR = MQT:CreateTexture(nil, "BORDER")
mqtBorderR:SetColorTexture(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
mqtBorderR:SetWidth(1)
mqtBorderR:SetPoint("TOPRIGHT", MQT, "TOPRIGHT", 0, 0)
mqtBorderR:SetPoint("BOTTOMRIGHT", MQT, "BOTTOMRIGHT", 0, 0)
addon.mqtBorderT, addon.mqtBorderB = mqtBorderT, mqtBorderB
addon.mqtBorderL, addon.mqtBorderR = mqtBorderL, mqtBorderR

function addon.ApplyBackdropOpacity()
    if not addon.mqtBg then return end
    local a = tonumber(addon.GetDB("backdropOpacity", 0.9)) or 0.9
    addon.mqtBg:SetColorTexture(0.08, 0.08, 0.12, math.max(0, math.min(1, a)))
end

function addon.ApplyBorderVisibility()
    local show = addon.GetDB("showBorder", true)
    if addon.mqtBorderT then addon.mqtBorderT:SetShown(show) end
    if addon.mqtBorderB then addon.mqtBorderB:SetShown(show) end
    if addon.mqtBorderL then addon.mqtBorderL:SetShown(show) end
    if addon.mqtBorderR then addon.mqtBorderR:SetShown(show) end
end

local headerShadow = MQT:CreateFontString(nil, "BORDER")
headerShadow:SetFontObject(addon.HeaderFont)
headerShadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
headerShadow:SetJustifyH("LEFT")
headerShadow:SetText("OBJECTIVES")

local headerText = MQT:CreateFontString(nil, "OVERLAY")
headerText:SetFontObject(addon.HeaderFont)
headerText:SetTextColor(addon.HEADER_COLOR[1], addon.HEADER_COLOR[2], addon.HEADER_COLOR[3], 1)
headerText:SetJustifyH("LEFT")
headerText:SetPoint("TOPLEFT", MQT, "TOPLEFT", addon.PADDING, -addon.PADDING)
headerText:SetText("OBJECTIVES")
headerShadow:SetPoint("CENTER", headerText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

local countText = MQT:CreateFontString(nil, "OVERLAY")
countText:SetFontObject(addon.ObjFont)
countText:SetTextColor(0.60, 0.65, 0.75, 1)
countText:SetJustifyH("RIGHT")
countText:SetPoint("TOPRIGHT", MQT, "TOPRIGHT", -addon.PADDING, -addon.PADDING - 3)

local countShadow = MQT:CreateFontString(nil, "BORDER")
countShadow:SetFontObject(addon.ObjFont)
countShadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
countShadow:SetJustifyH("RIGHT")
countShadow:SetPoint("CENTER", countText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

local chevron = MQT:CreateFontString(nil, "OVERLAY")
chevron:SetFontObject(addon.ObjFont)
chevron:SetTextColor(0.60, 0.65, 0.75, 1)
chevron:SetJustifyH("RIGHT")
chevron:SetPoint("RIGHT", countText, "LEFT", -6, 0)
chevron:SetText("-")

local optionsBtn = CreateFrame("Button", nil, MQT)
local optionsLabel = optionsBtn:CreateFontString(nil, "OVERLAY")
optionsLabel:SetFontObject(addon.ObjFont)
optionsLabel:SetTextColor(0.60, 0.65, 0.75, 1)
optionsLabel:SetJustifyH("RIGHT")
optionsLabel:SetText("Options")
optionsBtn:SetSize(math.max(optionsLabel:GetStringWidth() + 4, 44), 20)
optionsBtn:SetPoint("RIGHT", chevron, "LEFT", -6, 0)
optionsLabel:SetPoint("RIGHT", optionsBtn, "RIGHT", -2, 0)
optionsBtn:SetScript("OnClick", function()
    if _G.ModernQuestTracker_ShowOptions then _G.ModernQuestTracker_ShowOptions() end
end)
optionsBtn:SetScript("OnEnter", function(self)
    optionsLabel:SetTextColor(0.85, 0.85, 0.90, 1)
    if GameTooltip then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Options", nil, nil, nil, nil, true)
        GameTooltip:Show()
    end
end)
optionsBtn:SetScript("OnLeave", function()
    optionsLabel:SetTextColor(0.60, 0.65, 0.75, 1)
    if GameTooltip then GameTooltip:Hide() end
end)

local divider = MQT:CreateTexture(nil, "ARTWORK")
divider:SetSize(addon.GetPanelWidth() - addon.PADDING * 2, addon.DIVIDER_HEIGHT)
divider:SetPoint("TOP", MQT, "TOPLEFT", addon.GetPanelWidth() / 2, -(addon.PADDING + addon.HEADER_HEIGHT))
divider:SetColorTexture(addon.DIVIDER_COLOR[1], addon.DIVIDER_COLOR[2], addon.DIVIDER_COLOR[3], addon.DIVIDER_COLOR[4])

function addon.GetContentTop()
    if addon.GetDB("hideObjectivesHeader", false) then
        return -8
    end
    return -(addon.PADDING + addon.HEADER_HEIGHT + addon.DIVIDER_HEIGHT + 6)
end
function addon.GetCollapsedHeight()
    if addon.GetDB("hideObjectivesHeader", false) then
        return 8
    end
    return addon.PADDING + addon.HEADER_HEIGHT + 6
end

local scrollFrame = CreateFrame("ScrollFrame", nil, MQT)
scrollFrame:SetPoint("TOPLEFT", MQT, "TOPLEFT", 0, addon.GetContentTop())
scrollFrame:SetPoint("BOTTOMRIGHT", MQT, "BOTTOMRIGHT", 0, addon.PADDING)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(addon.GetPanelWidth())
scrollChild:SetHeight(1)
scrollFrame:SetScrollChild(scrollChild)

addon.scrollOffset = 0

local function HandleScroll(delta)
    if InCombatLockdown() then return end
    local childH  = scrollChild:GetHeight() or 0
    local frameH  = scrollFrame:GetHeight() or 0
    local maxScr  = math.max(childH - frameH, 0)
    addon.scrollOffset = math.max(0, math.min(addon.scrollOffset - delta * addon.SCROLL_STEP, maxScr))
    scrollFrame:SetVerticalScroll(addon.scrollOffset)
end

scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(_, delta) HandleScroll(delta) end)

MQT:EnableMouseWheel(true)
MQT:SetScript("OnMouseWheel", function(_, delta) HandleScroll(delta) end)

MQT:SetMovable(true)
MQT:EnableMouse(true)
MQT:RegisterForDrag("LeftButton")
MQT:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

local function SavePanelPosition()
    local uiRight = UIParent:GetRight() or 0
    local right   = MQT:GetRight()
    if not right then return end
    addon.EnsureDB()
    if addon.GetDB("growUp", false) then
        local bottom = MQT:GetBottom()
        local uiBottom = UIParent:GetBottom() or 0
        if not bottom then return end
        local x, y = right - uiRight, bottom - uiBottom
        MQT:ClearAllPoints()
        MQT:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", x, y)
        HorizonSuiteDB.point    = "BOTTOMRIGHT"
        HorizonSuiteDB.relPoint = "BOTTOMRIGHT"
        HorizonSuiteDB.x        = x
        HorizonSuiteDB.y        = y
    else
        local top = MQT:GetTop()
        local uiTop = UIParent:GetTop() or 0
        if not top then return end
        local x, y = right - uiRight, top - uiTop
        MQT:ClearAllPoints()
        MQT:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", x, y)
        HorizonSuiteDB.point    = "TOPRIGHT"
        HorizonSuiteDB.relPoint = "TOPRIGHT"
        HorizonSuiteDB.x        = x
        HorizonSuiteDB.y        = y
    end
end

MQT:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self:SetUserPlaced(false)
    SavePanelPosition()
end)

-- Resize handle: drag bottom-right corner to change panel width and height
local RESIZE_MIN, RESIZE_MAX = 180, 500
local RESIZE_HEIGHT_MIN = addon.MIN_HEIGHT
local headerAreaResize = addon.PADDING + addon.HEADER_HEIGHT + addon.DIVIDER_HEIGHT + 6
local RESIZE_HEIGHT_MAX = headerAreaResize + 800 + addon.PADDING
local RESIZE_CONTENT_HEIGHT_MIN, RESIZE_CONTENT_HEIGHT_MAX = 200, 800

local resizeHandle = CreateFrame("Frame", nil, MQT)
resizeHandle:SetSize(20, 20)
resizeHandle:SetPoint("BOTTOMRIGHT", MQT, "BOTTOMRIGHT", 0, 0)
resizeHandle:EnableMouse(true)
resizeHandle:SetScript("OnEnter", function(self)
    if GameTooltip then
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("Drag to resize", nil, nil, nil, nil, true)
        GameTooltip:Show()
    end
end)
resizeHandle:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
end)
local isResizing = false
local startWidth, startHeight, startMouseX, startMouseY
resizeHandle:RegisterForDrag("LeftButton")
local function ResizeOnUpdate(self, elapsed)
    if not isResizing then return end
    local scale = UIParent and UIParent:GetEffectiveScale() or 1
    local curX = select(1, GetCursorPosition()) / scale
    local curY = select(2, GetCursorPosition()) / scale
    local deltaX = curX - startMouseX
    local deltaY = curY - startMouseY
    local newWidth = math.max(RESIZE_MIN, math.min(RESIZE_MAX, startWidth + deltaX))
    local newHeight = math.max(RESIZE_HEIGHT_MIN, math.min(RESIZE_HEIGHT_MAX, startHeight - deltaY))
    MQT:SetWidth(newWidth)
    MQT:SetHeight(newHeight)
    addon.targetHeight = newHeight
    addon.currentHeight = newHeight
    addon.EnsureDB()
    HorizonSuiteDB.panelWidth = newWidth
    local contentH = math.max(RESIZE_CONTENT_HEIGHT_MIN, math.min(RESIZE_CONTENT_HEIGHT_MAX, newHeight - headerAreaResize - addon.PADDING))
    HorizonSuiteDB.maxContentHeight = contentH
    if addon.ApplyDimensions then addon.ApplyDimensions() end
end
resizeHandle:SetScript("OnDragStart", function(self)
    if HorizonSuiteDB and HorizonSuiteDB.lockPosition then return end
    isResizing = true
    startWidth = MQT:GetWidth()
    startHeight = MQT:GetHeight()
    local scale = UIParent and UIParent:GetEffectiveScale() or 1
    startMouseX = select(1, GetCursorPosition()) / scale
    startMouseY = select(2, GetCursorPosition()) / scale
    self:SetScript("OnUpdate", ResizeOnUpdate)
end)
resizeHandle:SetScript("OnDragStop", function(self)
    if not isResizing then return end
    isResizing = false
    self:SetScript("OnUpdate", nil)
    addon.EnsureDB()
    HorizonSuiteDB.panelWidth = MQT:GetWidth()
    local h = MQT:GetHeight()
    local contentH = math.max(RESIZE_CONTENT_HEIGHT_MIN, math.min(RESIZE_CONTENT_HEIGHT_MAX, h - headerAreaResize - addon.PADDING))
    HorizonSuiteDB.maxContentHeight = contentH
    if addon.ApplyDimensions then addon.ApplyDimensions() end
    if addon.FullLayout and not InCombatLockdown() then addon.FullLayout() end
end)

-- Sleek L-shaped corner grip (two thin strips)
local gripR, gripG, gripB, gripA = 0.55, 0.56, 0.6, 0.65
local resizeLineH = resizeHandle:CreateTexture(nil, "OVERLAY")
resizeLineH:SetSize(12, 2)
resizeLineH:SetPoint("BOTTOMRIGHT", resizeHandle, "BOTTOMRIGHT", 0, 0)
resizeLineH:SetColorTexture(gripR, gripG, gripB, gripA)
local resizeLineV = resizeHandle:CreateTexture(nil, "OVERLAY")
resizeLineV:SetSize(2, 12)
resizeLineV:SetPoint("BOTTOMRIGHT", resizeHandle, "BOTTOMRIGHT", 0, 0)
resizeLineV:SetColorTexture(gripR, gripG, gripB, gripA)

function addon.UpdateResizeHandleVisibility()
    resizeHandle:SetShown(not (HorizonSuiteDB and HorizonSuiteDB.lockPosition))
end
addon.UpdateResizeHandleVisibility()

local function RestoreSavedPosition()
    if not HorizonSuiteDB or not HorizonSuiteDB.point then return end
    local db = HorizonSuiteDB
    MQT:ClearAllPoints()
    MQT:SetPoint(db.point, UIParent, db.relPoint or db.point, db.x, db.y)
end

local function ApplyGrowUpAnchor()
    if not addon.GetDB("growUp", false) then return end
    local right = MQT:GetRight()
    local bottom = MQT:GetBottom()
    if not right or not bottom then return end
    local uiRight = UIParent:GetRight() or 0
    local uiBottom = UIParent:GetBottom() or 0
    local x, y = right - uiRight, bottom - uiBottom
    MQT:ClearAllPoints()
    MQT:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", x, y)
    addon.EnsureDB()
    HorizonSuiteDB.point    = "BOTTOMRIGHT"
    HorizonSuiteDB.relPoint = "BOTTOMRIGHT"
    HorizonSuiteDB.x        = x
    HorizonSuiteDB.y        = y
end

function addon.UpdateHeaderQuestCount(questCount)
    local maxQ = (C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept()) or 35
    local countStr = (questCount and questCount > 0) and (questCount .. "/" .. maxQ) or ""
    addon.countText:SetText(countStr)
    addon.countShadow:SetText(countStr)
    if addon.GetDB("showQuestCount", true) then
        addon.countText:Show()
        addon.countShadow:Show()
    else
        addon.countText:Hide()
        addon.countShadow:Hide()
    end
end

function addon.ApplyItemCooldown(cooldownFrame, itemLink)
    if not cooldownFrame or not itemLink then return end
    local ok, itemID = pcall(GetItemInfoInstant, itemLink)
    if not ok or not itemID or not GetItemCooldown then return end
    local start, duration = GetItemCooldown(itemID)
    if start and duration and duration > 0 then
        cooldownFrame:SetCooldown(start, duration)
    else
        cooldownFrame:Clear()
    end
end

addon.RARE_ADDED_SOUND = (SOUNDKIT and SOUNDKIT.UI_AUTO_QUEST_COMPLETE) or 61969

-- Export to addon table
addon.MQT                 = MQT
addon.scrollFrame         = scrollFrame
addon.scrollChild         = scrollChild
addon.headerText          = headerText
addon.headerShadow        = headerShadow
addon.countText           = countText
addon.countShadow         = countShadow
addon.chevron             = chevron
addon.optionsBtn          = optionsBtn
addon.optionsLabel        = optionsLabel
addon.divider             = divider
addon.HandleScroll        = HandleScroll
addon.SavePanelPosition   = SavePanelPosition
addon.RestoreSavedPosition = RestoreSavedPosition
addon.ApplyGrowUpAnchor   = ApplyGrowUpAnchor
