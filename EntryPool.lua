--[[
    Horizon Suite - Focus - Entry Pool
    Quest entry frames, section headers, ApplyTypography, ApplyDimensions.
]]

local addon = _G.ModernQuestTracker

-- ============================================================================
-- ENTRY POOL
-- ============================================================================

local pool      = {}
local activeMap = {}

local function CreateQuestEntry(parent, index)
    local e = CreateFrame("Frame", nil, parent)
    local w = addon.GetPanelWidth() - addon.PADDING * 2
    local textW = w - (addon.CONTENT_RIGHT_PADDING or 0)
    e:SetSize(w, 20)

    e.trackBar = e:CreateTexture(nil, "BACKGROUND")
    e.trackBar:SetSize(2, 1)
    e.trackBar:SetPoint("TOPLEFT", e, "TOPLEFT", -8, 0)
    e.trackBar:SetColorTexture(0.40, 0.70, 1.00, 0.80)
    e.trackBar:Hide()

    -- Highlight inset
    local highlightInset = 5
    e.highlightBg = e:CreateTexture(nil, "BACKGROUND")
    e.highlightBg:SetPoint("TOPLEFT", e, "TOPLEFT", highlightInset, -highlightInset)
    e.highlightBg:SetPoint("BOTTOMRIGHT", e, "BOTTOMRIGHT", -highlightInset, highlightInset)
    e.highlightBg:SetColorTexture(0.2, 0.4, 0.6, 0.25)
    e.highlightBg:Hide()
    -- Top strip
    e.highlightTop = e:CreateTexture(nil, "BACKGROUND")
    e.highlightTop:SetHeight(2)
    e.highlightTop:SetPoint("TOPLEFT", e, "TOPLEFT", highlightInset, -highlightInset)
    e.highlightTop:SetPoint("TOPRIGHT", e, "TOPRIGHT", -highlightInset, 0)
    e.highlightTop:SetColorTexture(0.35, 0.55, 0.85, 0.4)
    e.highlightTop:Hide()
    -- 1px highlight border
    local borderW = 1
    e.highlightBorderT = e:CreateTexture(nil, "BORDER")
    e.highlightBorderT:SetHeight(borderW)
    e.highlightBorderT:SetPoint("TOPLEFT", e, "TOPLEFT", highlightInset, -highlightInset)
    e.highlightBorderT:SetPoint("TOPRIGHT", e, "TOPRIGHT", -highlightInset, 0)
    e.highlightBorderT:SetColorTexture(0.40, 0.70, 1.00, 0.6)
    e.highlightBorderT:Hide()
    e.highlightBorderB = e:CreateTexture(nil, "BORDER")
    e.highlightBorderB:SetHeight(borderW)
    e.highlightBorderB:SetPoint("BOTTOMLEFT", e, "BOTTOMLEFT", highlightInset, 0)
    e.highlightBorderB:SetPoint("BOTTOMRIGHT", e, "BOTTOMRIGHT", -highlightInset, highlightInset)
    e.highlightBorderB:SetColorTexture(0.40, 0.70, 1.00, 0.6)
    e.highlightBorderB:Hide()
    e.highlightBorderL = e:CreateTexture(nil, "BORDER")
    e.highlightBorderL:SetWidth(borderW)
    e.highlightBorderL:SetPoint("TOPLEFT", e, "TOPLEFT", highlightInset, -highlightInset)
    e.highlightBorderL:SetPoint("BOTTOMLEFT", e, "BOTTOMLEFT", highlightInset, highlightInset)
    e.highlightBorderL:SetColorTexture(0.40, 0.70, 1.00, 0.6)
    e.highlightBorderL:Hide()
    e.highlightBorderR = e:CreateTexture(nil, "BORDER")
    e.highlightBorderR:SetWidth(borderW)
    e.highlightBorderR:SetPoint("TOPRIGHT", e, "TOPRIGHT", -highlightInset, -highlightInset)
    e.highlightBorderR:SetPoint("BOTTOMRIGHT", e, "BOTTOMRIGHT", -highlightInset, highlightInset)
    e.highlightBorderR:SetColorTexture(0.40, 0.70, 1.00, 0.6)
    e.highlightBorderR:Hide()

    local btnName = "MQTItemBtn" .. index
    e.itemBtn = CreateFrame("Button", btnName, e, "SecureActionButtonTemplate")
    e.itemBtn:SetSize(addon.ITEM_BTN_SIZE, addon.ITEM_BTN_SIZE)
    e.itemBtn:SetPoint("TOPRIGHT", e, "TOPRIGHT", 0, 2)
    e.itemBtn:SetAttribute("type", "item")
    e.itemBtn:RegisterForClicks("AnyUp")

    e.itemBtn.icon = e.itemBtn:CreateTexture(nil, "ARTWORK")
    e.itemBtn.icon:SetAllPoints()
    e.itemBtn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    e.itemBtn.shadow = e.itemBtn:CreateTexture(nil, "BACKGROUND")
    e.itemBtn.shadow:SetPoint("TOPLEFT", -2, 2)
    e.itemBtn.shadow:SetPoint("BOTTOMRIGHT", 2, -2)
    e.itemBtn.shadow:SetColorTexture(0, 0, 0, 0.6)

    e.itemBtn.cooldown = CreateFrame("Cooldown", btnName .. "CD", e.itemBtn, "CooldownFrameTemplate")
    e.itemBtn.cooldown:SetAllPoints()

    e.itemBtn:SetScript("OnEnter", function(self)
        local entry = self:GetParent()
        if entry.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            pcall(GameTooltip.SetHyperlink, GameTooltip, entry.itemLink)
            GameTooltip:Show()
        end
    end)
    e.itemBtn:SetScript("OnLeave", function(self)
        if GameTooltip:GetOwner() == self then
            GameTooltip:Hide()
        end
    end)

    e.itemBtn:Hide()

    e.questTypeIcon = e:CreateTexture(nil, "ARTWORK")
    e.questTypeIcon:SetSize(addon.QUEST_TYPE_ICON_SIZE, addon.QUEST_TYPE_ICON_SIZE)
    e.questTypeIcon:SetPoint("TOPRIGHT", e, "TOPLEFT", -addon.QUEST_TYPE_ICON_GAP, 0)
    e.questTypeIcon:Hide()

    e.titleShadow = e:CreateFontString(nil, "BORDER")
    e.titleShadow:SetFont(addon.FONT_PATH, addon.TITLE_SIZE, "OUTLINE")
    e.titleShadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
    e.titleShadow:SetJustifyH("LEFT")
    e.titleShadow:SetWordWrap(true)
    e.titleShadow:SetWidth(textW)

    e.titleText = e:CreateFontString(nil, "OVERLAY")
    e.titleText:SetFont(addon.FONT_PATH, addon.TITLE_SIZE, "OUTLINE")
    e.titleText:SetTextColor(1, 1, 1, 1)
    e.titleText:SetJustifyH("LEFT")
    e.titleText:SetWordWrap(true)
    e.titleText:SetWidth(textW)
    e.titleText:SetPoint("TOPLEFT", e, "TOPLEFT", 0, 0)
    e.titleShadow:SetPoint("CENTER", e.titleText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

    e.zoneShadow = e:CreateFontString(nil, "BORDER")
    e.zoneShadow:SetFont(addon.FONT_PATH, addon.ZONE_SIZE, "OUTLINE")
    e.zoneShadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
    e.zoneShadow:SetJustifyH("LEFT")

    e.zoneText = e:CreateFontString(nil, "OVERLAY")
    e.zoneText:SetFont(addon.FONT_PATH, addon.ZONE_SIZE, "OUTLINE")
    e.zoneText:SetTextColor(addon.ZONE_COLOR[1], addon.ZONE_COLOR[2], addon.ZONE_COLOR[3], 1)
    e.zoneText:SetJustifyH("LEFT")
    e.zoneShadow:SetPoint("CENTER", e.zoneText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)
    e.zoneText:Hide()
    e.zoneShadow:Hide()

    e.objectives = {}
    for j = 1, addon.MAX_OBJECTIVES do
        local objShadow = e:CreateFontString(nil, "BORDER")
        objShadow:SetFont(addon.FONT_PATH, addon.OBJ_SIZE, "OUTLINE")
        objShadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
        objShadow:SetJustifyH("LEFT")
        objShadow:SetWordWrap(true)
        objShadow:SetWidth(textW - addon.OBJ_INDENT)

        local objText = e:CreateFontString(nil, "OVERLAY")
        objText:SetFont(addon.FONT_PATH, addon.OBJ_SIZE, "OUTLINE")
        objText:SetTextColor(addon.OBJ_COLOR[1], addon.OBJ_COLOR[2], addon.OBJ_COLOR[3], 1)
        objText:SetJustifyH("LEFT")
        objText:SetWordWrap(true)
        objText:SetWidth(textW - addon.OBJ_INDENT)

        objShadow:SetPoint("CENTER", objText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

        e.objectives[j] = { text = objText, shadow = objShadow }
        objText:Hide()
        objShadow:Hide()
    end

    e.flash = e:CreateTexture(nil, "HIGHLIGHT")
    e.flash:SetAllPoints(e)
    e.flash:SetColorTexture(1, 1, 1, 0)

    e.animState      = "idle"
    e.animTime       = 0
    e.entryHeight    = 0
    e.questID        = nil
    e.flashTime      = 0
    e.finalX         = 0
    e.finalY         = 0
    e.staggerDelay   = 0
    e.collapseDelay  = 0

    e:SetAlpha(0)
    e:Hide()
    return e
end

local scrollChild = addon.scrollChild
for i = 1, addon.POOL_SIZE do
    pool[i] = CreateQuestEntry(scrollChild, i)
end

local sectionPool = {}

local function CreateSectionHeader(parent)
    local s = CreateFrame("Frame", nil, parent)
    s:SetSize(addon.GetPanelWidth() - addon.PADDING * 2, addon.SECTION_SIZE + 4)

    s.shadow = s:CreateFontString(nil, "BORDER")
    s.shadow:SetFont(addon.FONT_PATH, addon.SECTION_SIZE, "OUTLINE")
    s.shadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
    s.shadow:SetJustifyH("LEFT")

    s.text = s:CreateFontString(nil, "OVERLAY")
    s.text:SetFont(addon.FONT_PATH, addon.SECTION_SIZE, "OUTLINE")
    s.text:SetJustifyH("LEFT")
    s.text:SetPoint("BOTTOMLEFT", s, "BOTTOMLEFT", 0, 0)
    s.shadow:SetPoint("CENTER", s.text, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

    s.active = false
    s:SetAlpha(0)
    s:Hide()
    return s
end

for i = 1, addon.SECTION_POOL_SIZE do
    sectionPool[i] = CreateSectionHeader(scrollChild)
end

local function ApplyTypography()
    local fontPath   = addon.GetDB("fontPath", "Fonts\\FRIZQT__.ttf")
    local outline    = addon.GetDB("fontOutline", "OUTLINE")
    local headerSz   = tonumber(addon.GetDB("headerFontSize", 16)) or 16
    local titleSz    = tonumber(addon.GetDB("titleFontSize", 13)) or 13
    local objSz      = tonumber(addon.GetDB("objectiveFontSize", 11)) or 11
    local zoneSz     = tonumber(addon.GetDB("zoneFontSize", 10)) or 10
    local sectionSz  = tonumber(addon.GetDB("sectionFontSize", 10)) or 10
    local shadowOx   = tonumber(addon.GetDB("shadowOffsetX", 2)) or 2
    local shadowOy   = tonumber(addon.GetDB("shadowOffsetY", -2)) or -2
    local shadowA    = tonumber(addon.GetDB("shadowAlpha", 0.8)) or 0.8

    addon.headerShadow:SetFont(fontPath, headerSz, outline)
    addon.headerShadow:SetTextColor(0, 0, 0, shadowA)
    addon.headerShadow:SetPoint("CENTER", addon.headerText, "CENTER", shadowOx, shadowOy)
    addon.headerText:SetFont(fontPath, headerSz, outline)

    addon.countText:SetFont(fontPath, objSz, outline)
    addon.countShadow:SetFont(fontPath, objSz, outline)
    addon.countShadow:SetTextColor(0, 0, 0, shadowA)
    addon.countShadow:SetPoint("CENTER", addon.countText, "CENTER", shadowOx, shadowOy)
    addon.chevron:SetFont(fontPath, objSz, outline)
    if addon.optionsLabel then addon.optionsLabel:SetFont(fontPath, objSz, outline) end
    if addon.mplusTimerText then
        addon.mplusTimerText:SetFont(fontPath, objSz, outline)
        addon.mplusPctText:SetFont(fontPath, objSz, outline)
        addon.mplusAffixesText:SetFont(fontPath, sectionSz, outline)
    end

    for i = 1, addon.POOL_SIZE do
        local e = pool[i]
        e.titleShadow:SetFont(fontPath, titleSz, outline)
        e.titleShadow:SetTextColor(0, 0, 0, shadowA)
        e.titleShadow:SetPoint("CENTER", e.titleText, "CENTER", shadowOx, shadowOy)
        e.titleText:SetFont(fontPath, titleSz, outline)
        e.zoneShadow:SetFont(fontPath, zoneSz, outline)
        e.zoneShadow:SetTextColor(0, 0, 0, shadowA)
        e.zoneShadow:SetPoint("CENTER", e.zoneText, "CENTER", shadowOx, shadowOy)
        e.zoneText:SetFont(fontPath, zoneSz, outline)
        for j = 1, addon.MAX_OBJECTIVES do
            local obj = e.objectives[j]
            obj.shadow:SetFont(fontPath, objSz, outline)
            obj.shadow:SetTextColor(0, 0, 0, shadowA)
            obj.shadow:SetPoint("CENTER", obj.text, "CENTER", shadowOx, shadowOy)
            obj.text:SetFont(fontPath, objSz, outline)
        end
    end

    for i = 1, addon.SECTION_POOL_SIZE do
        local s = sectionPool[i]
        s.shadow:SetFont(fontPath, sectionSz, outline)
        s.shadow:SetTextColor(0, 0, 0, shadowA)
        s.shadow:SetPoint("CENTER", s.text, "CENTER", shadowOx, shadowOy)
        s.text:SetFont(fontPath, sectionSz, outline)
    end
end

local function ApplyDimensions()
    local w = addon.GetPanelWidth()
    addon.MQT:SetSize(w, addon.MQT:GetHeight() or addon.MIN_HEIGHT)
    addon.divider:SetSize(w - addon.PADDING * 2, addon.DIVIDER_HEIGHT)
    addon.divider:SetPoint("TOP", addon.MQT, "TOPLEFT", w / 2, -(addon.PADDING + addon.HEADER_HEIGHT))
    addon.scrollChild:SetWidth(w)
    for i = 1, addon.POOL_SIZE do
        local e = pool[i]
        local contentW = w - addon.PADDING * 2
        local textW = contentW - (addon.CONTENT_RIGHT_PADDING or 0)
        e:SetSize(contentW, 20)
        e.titleShadow:SetWidth(textW)
        e.titleText:SetWidth(textW)
        for j = 1, addon.MAX_OBJECTIVES do
            local obj = e.objectives[j]
            obj.shadow:SetWidth(textW - addon.OBJ_INDENT)
            obj.text:SetWidth(textW - addon.OBJ_INDENT)
        end
    end
    for i = 1, addon.SECTION_POOL_SIZE do
        sectionPool[i]:SetSize(w - addon.PADDING * 2, addon.SECTION_SIZE + 4)
    end
end

local function ClearEntry(entry, full)
    if not entry then return end
    entry.questID    = nil
    entry.entryKey   = nil
    entry.creatureID = nil
    entry.itemLink   = nil
    entry.animState  = "idle"
    if full ~= false then
        entry:Hide()
        entry:SetAlpha(0)
        if entry.itemBtn then entry.itemBtn:Hide() end
    end
end

addon.pool         = pool
addon.activeMap   = activeMap
addon.sectionPool = sectionPool
addon.ClearEntry   = ClearEntry
addon.ApplyTypography = ApplyTypography
addon.ApplyDimensions = ApplyDimensions
