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

addon.FONT_PATH       = "Fonts\\FRIZQT__.ttf"
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
addon.MIN_HEIGHT      = 50

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

addon.FADE_IN_DUR     = 0.30
addon.FADE_OUT_DUR    = 0.40
addon.COMPLETE_HOLD   = 0.50
addon.HEIGHT_SPEED    = 8
addon.FLASH_DUR       = 0.35

addon.SLIDE_IN_X      = 20
addon.SLIDE_OUT_X     = 20
addon.DRIFT_OUT_Y     = 10
addon.ENTRY_STAGGER   = 0.05
addon.COLLAPSE_DUR    = 0.25

addon.HEADER_COLOR    = { 1, 1, 1 }
addon.DIVIDER_COLOR   = { 1, 1, 1, 0.5 }
addon.OBJ_COLOR       = { 0.78, 0.78, 0.78 }
addon.OBJ_DONE_COLOR  = { 0.30, 0.80, 0.30 }
addon.ZONE_SIZE       = 10
addon.ZONE_COLOR      = { 0.55, 0.65, 0.75 }

addon.QUEST_COLORS = {
    DEFAULT   = { 0.90, 0.90, 0.90 },
    CAMPAIGN  = { 1.00, 0.82, 0.20 },
    IMPORTANT = { 1.00, 0.82, 0.20 },
    LEGENDARY = { 1.00, 0.50, 0.00 },
    WORLD     = { 0.60, 0.20, 1.00 },
    CALLING   = { 0.20, 0.60, 1.00 },
    COMPLETE  = { 0.20, 1.00, 0.40 },
    RARE      = { 1.00, 0.55, 0.25 },
}

addon.SECTION_SIZE      = 10
addon.SECTION_SPACING   = 10
addon.SECTION_COLOR_A   = 0.60
addon.SECTION_POOL_SIZE = 8

addon.SECTION_LABELS = {
    DUNGEON   = "IN THIS DUNGEON",
    AVAILABLE = "AVAILABLE IN ZONE",
    NEARBY    = "NEARBY",
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
    IMPORTANT = { 1.00, 0.82, 0.20 },
    LEGENDARY = { 1.00, 0.50, 0.00 },
    WORLD     = { 0.60, 0.20, 1.00 },
    RARES     = { 1.00, 0.55, 0.25 },
    DEFAULT   = { 0.70, 0.70, 0.70 },
    COMPLETE  = { 0.20, 1.00, 0.40 },
}

addon.GROUP_ORDER = { "DUNGEON", "NEARBY", "AVAILABLE", "CAMPAIGN", "IMPORTANT", "LEGENDARY", "WORLD", "RARES", "COMPLETE", "DEFAULT" }

addon.CATEGORY_TO_GROUP = {
    COMPLETE  = "COMPLETE",
    LEGENDARY = "LEGENDARY",
    IMPORTANT = "IMPORTANT",
    CAMPAIGN  = "CAMPAIGN",
    WORLD     = "WORLD",
    CALLING   = "WORLD",
    DEFAULT   = "DEFAULT",
}

function addon.GetDB(key, default)
    if not HorizonSuiteDB then return default end
    local v = HorizonSuiteDB[key]
    if v == nil then return default end
    return v
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

addon.FONT_LIST = {
    { "Friz Quadrata (Default)", "Fonts\\FRIZQT__.ttf" },
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

local headerShadow = MQT:CreateFontString(nil, "BORDER")
headerShadow:SetFont(addon.FONT_PATH, addon.HEADER_SIZE, "OUTLINE")
headerShadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
headerShadow:SetJustifyH("LEFT")
headerShadow:SetText("OBJECTIVES")

local headerText = MQT:CreateFontString(nil, "OVERLAY")
headerText:SetFont(addon.FONT_PATH, addon.HEADER_SIZE, "OUTLINE")
headerText:SetTextColor(addon.HEADER_COLOR[1], addon.HEADER_COLOR[2], addon.HEADER_COLOR[3], 1)
headerText:SetJustifyH("LEFT")
headerText:SetPoint("TOPLEFT", MQT, "TOPLEFT", addon.PADDING, -addon.PADDING)
headerText:SetText("OBJECTIVES")
headerShadow:SetPoint("CENTER", headerText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

local countText = MQT:CreateFontString(nil, "OVERLAY")
countText:SetFont(addon.FONT_PATH, addon.OBJ_SIZE, "OUTLINE")
countText:SetTextColor(0.60, 0.65, 0.75, 1)
countText:SetJustifyH("RIGHT")
countText:SetPoint("TOPRIGHT", MQT, "TOPRIGHT", -addon.PADDING, -addon.PADDING - 3)

local countShadow = MQT:CreateFontString(nil, "BORDER")
countShadow:SetFont(addon.FONT_PATH, addon.OBJ_SIZE, "OUTLINE")
countShadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
countShadow:SetJustifyH("RIGHT")
countShadow:SetPoint("CENTER", countText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

local chevron = MQT:CreateFontString(nil, "OVERLAY")
chevron:SetFont(addon.FONT_PATH, addon.OBJ_SIZE, "OUTLINE")
chevron:SetTextColor(0.60, 0.65, 0.75, 1)
chevron:SetJustifyH("RIGHT")
chevron:SetPoint("RIGHT", countText, "LEFT", -6, 0)
chevron:SetText("-")

local optionsBtn = CreateFrame("Button", nil, MQT)
local optionsLabel = optionsBtn:CreateFontString(nil, "OVERLAY")
optionsLabel:SetFont(addon.FONT_PATH, addon.OBJ_SIZE, "OUTLINE")
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
