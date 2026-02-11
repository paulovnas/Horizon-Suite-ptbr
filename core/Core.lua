--[[
    Horizon Suite - Focus - Core
    DB access, easing, and main frame (HS + scroll, resize, drag, position).
    Constants, colors, fonts, and labels live in Config.lua.
]]

if not _G.HorizonSuite then _G.HorizonSuite = {} end
local addon = _G.HorizonSuite

-- ============================================================================
-- DB AND DIMENSION HELPERS (depend on Config constants)
-- ============================================================================

function addon.GetTitleSpacing()
    return addon.GetDB("compactMode", false) and addon.COMPACT_TITLE_SPACING or addon.TITLE_SPACING
end
function addon.GetObjSpacing()
    return addon.GetDB("compactMode", false) and addon.COMPACT_OBJ_SPACING or addon.OBJ_SPACING
end
function addon.GetObjIndent()
    return addon.GetDB("compactMode", false) and addon.COMPACT_OBJ_INDENT or addon.OBJ_INDENT
end

function addon.GetPanelWidth()
    return tonumber(addon.GetDB("panelWidth", addon.PANEL_WIDTH)) or addon.PANEL_WIDTH
end
function addon.GetMaxContentHeight()
    return tonumber(addon.GetDB("maxContentHeight", addon.MAX_CONTENT_HEIGHT)) or addon.MAX_CONTENT_HEIGHT
end

function addon.GetDB(key, default)
    if not HorizonDB then return default end
    local v = HorizonDB[key]
    if v == nil then return default end
    return v
end

function addon.SetDB(key, value)
    addon.EnsureDB()
    HorizonDB[key] = value
end

function addon.ShouldHideInCombat()
    return addon.GetDB("hideInCombat", false) and UnitAffectingCombat("player")
end

function addon.EnsureDB()
    if not HorizonDB then HorizonDB = {} end
end

-- Persisted Focus category order (validated, fallback to addon.GROUP_ORDER).
-- SCENARIO is always pinned first; user reorder cannot displace it.
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
    -- Pin SCENARIO first: remove from current position and prepend.
    for i = #result, 1, -1 do
        if result[i] == "SCENARIO" then
            table.remove(result, i)
            break
        end
    end
    table.insert(result, 1, "SCENARIO")
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
    -- Pin SCENARIO first before persisting.
    for i = #result, 1, -1 do
        if result[i] == "SCENARIO" then
            table.remove(result, i)
            break
        end
    end
    table.insert(result, 1, "SCENARIO")
    HorizonDB.groupOrder = result
end

-- Per-category collapse state ------------------------------------------------

local function EnsureCollapsedCategories()
    addon.EnsureDB()
    if not HorizonDB.collapsedCategories then
        HorizonDB.collapsedCategories = {}
    end
    return HorizonDB.collapsedCategories
end

function addon.IsCategoryCollapsed(groupKey)
    if not HorizonDB or not HorizonDB.collapsedCategories then
        return false
    end
    return HorizonDB.collapsedCategories[groupKey] == true
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

-- ============================================================================
-- EASING FUNCTIONS
-- ============================================================================

function addon.easeOut(t)  return 1 - (1 - t) * (1 - t) end
function addon.easeIn(t)   return t * t end

-- ============================================================================
-- FRAME SETUP
-- ============================================================================

local HS = CreateFrame("Frame", "HSFrame", UIParent)
HS:SetSize(addon.GetPanelWidth(), addon.MIN_HEIGHT)
HS:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", addon.PANEL_X, addon.PANEL_Y)
HS:SetFrameStrata("MEDIUM")
HS:SetClampedToScreen(true)
HS:Hide()

local hsBg = HS:CreateTexture(nil, "BACKGROUND")
hsBg:SetAllPoints(HS)
local backdropColor = (addon.Design and addon.Design.BACKDROP_COLOR) or { 0.08, 0.08, 0.12, 0.90 }
hsBg:SetColorTexture(backdropColor[1], backdropColor[2], backdropColor[3], backdropColor[4] or 1)
addon.hsBg = hsBg

local borderColor = (addon.Design and addon.Design.BORDER_COLOR) or nil
local hsBorderT, hsBorderB, hsBorderL, hsBorderR = addon.CreateBorder(HS, borderColor)
addon.hsBorderT, addon.hsBorderB = hsBorderT, hsBorderB
addon.hsBorderL, addon.hsBorderR = hsBorderL, hsBorderR

function addon.ApplyBackdropOpacity()
    if not addon.hsBg then return end
    local a = tonumber(addon.GetDB("backdropOpacity", 0)) or 0
    local base = (addon.Design and addon.Design.BACKDROP_COLOR) or { 0.08, 0.08, 0.12, 0.90 }
    addon.hsBg:SetColorTexture(base[1], base[2], base[3], math.max(0, math.min(1, a)))
end

function addon.ApplyBorderVisibility()
    local show = addon.GetDB("showBorder", false)
    if addon.hsBorderT then addon.hsBorderT:SetShown(show) end
    if addon.hsBorderB then addon.hsBorderB:SetShown(show) end
    if addon.hsBorderL then addon.hsBorderL:SetShown(show) end
    if addon.hsBorderR then addon.hsBorderR:SetShown(show) end
end

local headerShadow = HS:CreateFontString(nil, "BORDER")
headerShadow:SetFontObject(addon.HeaderFont)
headerShadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
headerShadow:SetJustifyH("LEFT")
headerShadow:SetText("OBJECTIVES")

local headerText = HS:CreateFontString(nil, "OVERLAY")
headerText:SetFontObject(addon.HeaderFont)
headerText:SetTextColor(addon.HEADER_COLOR[1], addon.HEADER_COLOR[2], addon.HEADER_COLOR[3], 1)
headerText:SetJustifyH("LEFT")
headerText:SetPoint("TOPLEFT", HS, "TOPLEFT", addon.PADDING, -addon.PADDING)
headerText:SetText("OBJECTIVES")
headerShadow:SetPoint("CENTER", headerText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

local countText = HS:CreateFontString(nil, "OVERLAY")
countText:SetFontObject(addon.ObjFont)
countText:SetTextColor(0.60, 0.65, 0.75, 1)
countText:SetJustifyH("RIGHT")
countText:SetPoint("TOPRIGHT", HS, "TOPRIGHT", -addon.PADDING, -addon.PADDING - 3)

local countShadow = HS:CreateFontString(nil, "BORDER")
countShadow:SetFontObject(addon.ObjFont)
countShadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
countShadow:SetJustifyH("RIGHT")
countShadow:SetPoint("CENTER", countText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

local chevron = HS:CreateFontString(nil, "OVERLAY")
chevron:SetFontObject(addon.ObjFont)
chevron:SetTextColor(0.60, 0.65, 0.75, 1)
chevron:SetJustifyH("RIGHT")
chevron:SetPoint("RIGHT", countText, "LEFT", -6, 0)
chevron:SetText("-")

local optionsBtn = CreateFrame("Button", nil, HS)
local optionsLabel = optionsBtn:CreateFontString(nil, "OVERLAY")
optionsLabel:SetFontObject(addon.ObjFont)
optionsLabel:SetTextColor(0.60, 0.65, 0.75, 1)
optionsLabel:SetJustifyH("RIGHT")
optionsLabel:SetText("Options")
optionsBtn:SetSize(math.max(optionsLabel:GetStringWidth() + 4, 44), 20)
optionsBtn:SetPoint("RIGHT", chevron, "LEFT", -6, 0)
optionsLabel:SetPoint("RIGHT", optionsBtn, "RIGHT", -2, 0)
optionsBtn:SetScript("OnClick", function()
    if _G.HorizonSuite_ShowOptions then _G.HorizonSuite_ShowOptions() end
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

local divider = HS:CreateTexture(nil, "ARTWORK")
divider:SetSize(addon.GetPanelWidth() - addon.PADDING * 2, addon.DIVIDER_HEIGHT)
divider:SetPoint("TOP", HS, "TOPLEFT", addon.GetPanelWidth() / 2, -(addon.PADDING + addon.HEADER_HEIGHT))
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

local scrollFrame = CreateFrame("ScrollFrame", nil, HS)
scrollFrame:SetPoint("TOPLEFT", HS, "TOPLEFT", 0, addon.GetContentTop())
scrollFrame:SetPoint("BOTTOMRIGHT", HS, "BOTTOMRIGHT", 0, addon.PADDING)

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

HS:EnableMouseWheel(true)
HS:SetScript("OnMouseWheel", function(_, delta) HandleScroll(delta) end)

HS:SetMovable(true)
HS:EnableMouse(true)
HS:RegisterForDrag("LeftButton")
HS:SetScript("OnDragStart", function(self)
    if InCombatLockdown() then return end
    if HorizonDB and HorizonDB.lockPosition then return end
    self:StartMoving()
end)

local function SavePanelPosition()
    if InCombatLockdown() then return end
    local uiRight = UIParent:GetRight() or 0
    local right   = HS:GetRight()
    if not right then return end
    addon.EnsureDB()
    if addon.GetDB("growUp", false) then
        local bottom = HS:GetBottom()
        local uiBottom = UIParent:GetBottom() or 0
        if not bottom then return end
        local x, y = right - uiRight, bottom - uiBottom
        HS:ClearAllPoints()
        HS:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", x, y)
        HorizonDB.point    = "BOTTOMRIGHT"
        HorizonDB.relPoint = "BOTTOMRIGHT"
        HorizonDB.x        = x
        HorizonDB.y        = y
    else
        local top = HS:GetTop()
        local uiTop = UIParent:GetTop() or 0
        if not top then return end
        local x, y = right - uiRight, top - uiTop
        HS:ClearAllPoints()
        HS:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", x, y)
        HorizonDB.point    = "TOPRIGHT"
        HorizonDB.relPoint = "TOPRIGHT"
        HorizonDB.x        = x
        HorizonDB.y        = y
    end
end

HS:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self:SetUserPlaced(false)
    if InCombatLockdown() then return end
    SavePanelPosition()
end)

-- Resize handle: drag bottom-right corner to change panel width and height
local RESIZE_MIN, RESIZE_MAX = 180, 800
local RESIZE_HEIGHT_MIN = addon.MIN_HEIGHT
local headerAreaResize = addon.PADDING + addon.HEADER_HEIGHT + addon.DIVIDER_HEIGHT + 6
local RESIZE_HEIGHT_MAX = headerAreaResize + 1000 + addon.PADDING
local RESIZE_CONTENT_HEIGHT_MIN, RESIZE_CONTENT_HEIGHT_MAX = 200, 1000

local resizeHandle = CreateFrame("Frame", nil, HS)
resizeHandle:SetSize(20, 20)
resizeHandle:SetPoint("BOTTOMRIGHT", HS, "BOTTOMRIGHT", 0, 0)
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
    if InCombatLockdown() then
        isResizing = false
        self:SetScript("OnUpdate", nil)
        return
    end
    local scale = UIParent and UIParent:GetEffectiveScale() or 1
    local curX = select(1, GetCursorPosition()) / scale
    local curY = select(2, GetCursorPosition()) / scale
    local deltaX = curX - startMouseX
    local deltaY = curY - startMouseY
    local newWidth = math.max(RESIZE_MIN, math.min(RESIZE_MAX, startWidth + deltaX))
    local newHeight = math.max(RESIZE_HEIGHT_MIN, math.min(RESIZE_HEIGHT_MAX, startHeight - deltaY))
    HS:SetWidth(newWidth)
    HS:SetHeight(newHeight)
    addon.targetHeight = newHeight
    addon.currentHeight = newHeight
    if addon.ApplyDimensions then addon.ApplyDimensions(newWidth) end
end
resizeHandle:SetScript("OnDragStart", function(self)
    if HorizonDB and HorizonDB.lockPosition then return end
    if InCombatLockdown() then return end
    isResizing = true
    startWidth = HS:GetWidth()
    startHeight = HS:GetHeight()
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
    HorizonDB.panelWidth = HS:GetWidth()
    local h = HS:GetHeight()
    local contentH = math.max(RESIZE_CONTENT_HEIGHT_MIN, math.min(RESIZE_CONTENT_HEIGHT_MAX, h - headerAreaResize - addon.PADDING))
    HorizonDB.maxContentHeight = contentH
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
    resizeHandle:SetShown(not (HorizonDB and HorizonDB.lockPosition))
end
addon.UpdateResizeHandleVisibility()

local function RestoreSavedPosition()
    if not HorizonDB or not HorizonDB.point then return end
    local db = HorizonDB
    HS:ClearAllPoints()
    HS:SetPoint(db.point, UIParent, db.relPoint or db.point, db.x, db.y)
end

local function ApplyGrowUpAnchor()
    if not addon.GetDB("growUp", false) then return end
    local right = HS:GetRight()
    local bottom = HS:GetBottom()
    if not right or not bottom then return end
    local uiRight = UIParent:GetRight() or 0
    local uiBottom = UIParent:GetBottom() or 0
    local x, y = right - uiRight, bottom - uiBottom
    HS:ClearAllPoints()
    HS:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", x, y)
    addon.EnsureDB()
    HorizonDB.point    = "BOTTOMRIGHT"
    HorizonDB.relPoint = "BOTTOMRIGHT"
    HorizonDB.x        = x
    HorizonDB.y        = y
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
    if not ok and addon.HSPrint then addon.HSPrint("GetItemInfoInstant failed: " .. tostring(itemLink)) end
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
addon.HS                  = HS
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
