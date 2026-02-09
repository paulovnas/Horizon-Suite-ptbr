--[[
    Horizon Suite - Focus - Options Widgets
    Reusable widget library: toggle, slider, dropdown, color swatch, search input, reorder list, section card/header.
    Modern Cinematic styling. All widgets expose :Refresh() and .searchText for search indexing.
]]

local addon = _G.ModernQuestTracker
if not addon then return end

-- Design tokens (Modern Cinematic). Panel can override FontPath/HeaderSize via SetDef.
local Def = {
    Padding = 14,
    OptionGap = 10,
    SectionGap = 16,
    CardPadding = 12,
    BorderEdge = 1,
    LabelSize = 13,
    SectionSize = 10,
    FontPath = (addon.GetDefaultFontPath and addon.GetDefaultFontPath()) or "Fonts\\FRIZQT__.TTF",
    HeaderSize = addon.HEADER_SIZE or 16,
    TextColorNormal = { 1, 1, 1 },
    TextColorHighlight = { 0.65, 0.72, 0.85, 1 },
    TextColorLabel = { 0.78, 0.78, 0.78 },
    TextColorSection = { 0.55, 0.65, 0.75 },
    SectionCardBg = { 0.12, 0.12, 0.18, 0.95 },
    SectionCardBorder = { 0.35, 0.38, 0.45, 0.45 },
    AccentColor = { 0.5, 0.6, 0.85, 0.9 },
    InputBg = { 0.08, 0.08, 0.12, 0.95 },
    InputBorder = { 0.35, 0.38, 0.45, 0.7 },
    TrackOff = { 0.15, 0.15, 0.2, 0.95 },
    TrackOn = { 0.5, 0.6, 0.85, 0.9 },
    ThumbColor = { 1, 1, 1, 1 },
}
Def.BorderColor = Def.SectionCardBorder

function _G.OptionsWidgets_SetDef(overrides)
    if not overrides then return end
    for k, v in pairs(overrides) do Def[k] = v end
end

local function SetTextColor(obj, color)
    if not color then return end
    obj:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local easeOut = addon.easeOut or function(t) return 1 - (1 - t) * (1 - t) end
local TOGGLE_ANIM_DUR = 0.15

-- Pill-shaped toggle: 36x18 track, 14px thumb. On = accent fill, Off = dark.
function OptionsWidgets_CreateToggleSwitch(parent, labelText, description, get, set)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(36)
    local searchText = (labelText or "") .. " " .. (description or "")
    row.searchText = searchText:lower()

    local trackW, trackH = 36, 18
    local thumbSize = 14
    local track = CreateFrame("Frame", nil, row)
    track:SetSize(trackW, trackH)
    track:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -9)
    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints(track)
    trackBg:SetColorTexture(Def.TrackOff[1], Def.TrackOff[2], Def.TrackOff[3], Def.TrackOff[4])
    local trackFill = track:CreateTexture(nil, "ARTWORK")
    trackFill:SetPoint("TOPLEFT", track, "TOPLEFT", 0, 0)
    trackFill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 0, 0)
    trackFill:SetWidth(0)
    trackFill:SetColorTexture(Def.TrackOn[1], Def.TrackOn[2], Def.TrackOn[3], Def.TrackOn[4])
    local thumb = track:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(thumbSize, thumbSize)
    thumb:SetColorTexture(Def.ThumbColor[1], Def.ThumbColor[2], Def.ThumbColor[3], Def.ThumbColor[4])
    thumb:SetPoint("CENTER", track, "LEFT", thumbSize/2, 0)

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    label:SetJustifyH("LEFT")
    SetTextColor(label, Def.TextColorLabel)
    label:SetText(labelText or "")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    label:SetPoint("RIGHT", track, "LEFT", -12, 0)
    label:SetWordWrap(true)

    local desc = row:CreateFontString(nil, "OVERLAY")
    desc:SetFont(Def.FontPath, Def.SectionSize, "OUTLINE")
    desc:SetJustifyH("LEFT")
    SetTextColor(desc, Def.TextColorSection)
    desc:SetText(description or "")
    desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    desc:SetPoint("RIGHT", track, "LEFT", -12, 0)
    desc:SetWordWrap(true)

    local btn = CreateFrame("Button", nil, row)
    btn:SetAllPoints(track)
    btn:SetScript("OnClick", function()
        local next = not get()
        set(next)
        row.animStart = GetTime()
        row.animFrom = row.thumbPos
        row.animTo = next and 1 or 0
    end)

    row.thumbPos = get() and 1 or 0
    row.animStart = nil
    row.animFrom = nil
    row.animTo = nil

    local function updateVisuals(t)
        thumb:ClearAllPoints()
        thumb:SetPoint("CENTER", track, "LEFT", thumbSize/2 + t * (trackW - thumbSize), 0)
        trackFill:SetWidth(t * trackW)
    end

    track:SetScript("OnUpdate", function()
        if row.animStart then
            local elapsed = GetTime() - row.animStart
            if elapsed >= TOGGLE_ANIM_DUR then
                row.thumbPos = row.animTo
                row.animStart = nil
                updateVisuals(row.thumbPos)
                return
            end
            row.thumbPos = row.animFrom + (row.animTo - row.animFrom) * easeOut(elapsed / TOGGLE_ANIM_DUR)
        end
        updateVisuals(row.thumbPos)
    end)

    function row:Refresh()
        local on = get()
        row.thumbPos = on and 1 or 0
        row.animStart = nil
        updateVisuals(row.thumbPos)
    end

    row:Refresh()
    return row
end

-- Slider: horizontal track + draggable thumb + numeric readout
local SLIDER_TRACK_HEIGHT = 6
local SLIDER_THUMB_SIZE = 16
function OptionsWidgets_CreateSlider(parent, labelText, description, get, set, minVal, maxVal)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(40)
    local searchText = (labelText or "") .. " " .. (description or "")
    row.searchText = searchText:lower()

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    label:SetJustifyH("LEFT")
    SetTextColor(label, Def.TextColorLabel)
    label:SetText(labelText or "")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    local desc = row:CreateFontString(nil, "OVERLAY")
    desc:SetFont(Def.FontPath, Def.SectionSize, "OUTLINE")
    desc:SetJustifyH("LEFT")
    SetTextColor(desc, Def.TextColorSection)
    desc:SetText(description or "")
    desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    desc:SetPoint("RIGHT", row, "RIGHT", -60, 0)
    desc:SetWordWrap(true)

    local trackWidth = 180
    local track = CreateFrame("Frame", nil, row)
    track:SetSize(trackWidth, SLIDER_TRACK_HEIGHT)
    track:SetPoint("TOPRIGHT", row, "TOPRIGHT", -52, -8)
    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints(track)
    trackBg:SetColorTexture(Def.TrackOff[1], Def.TrackOff[2], Def.TrackOff[3], Def.TrackOff[4])
    local trackFill = track:CreateTexture(nil, "ARTWORK")
    trackFill:SetPoint("TOPLEFT", track, "TOPLEFT", 0, 0)
    trackFill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 0, 0)
    trackFill:SetColorTexture(Def.TrackOn[1], Def.TrackOn[2], Def.TrackOn[3], Def.TrackOn[4])

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetSize(SLIDER_THUMB_SIZE, SLIDER_THUMB_SIZE)
    thumb:SetPoint("CENTER", track, "LEFT", 0, 0)
    local thumbTex = thumb:CreateTexture(nil, "BACKGROUND")
    thumbTex:SetAllPoints(thumb)
    thumbTex:SetColorTexture(Def.ThumbColor[1], Def.ThumbColor[2], Def.ThumbColor[3], Def.ThumbColor[4])

    local edit = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    edit:SetSize(44, 20)
    edit:SetPoint("LEFT", track, "RIGHT", 8, 0)
    edit:SetMaxLetters(6)
    edit:SetNumeric(true)
    edit:SetAutoFocus(false)
    edit:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    edit:SetScript("OnEscapePressed", function() edit:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function()
        local v = tonumber(edit:GetText())
        if v ~= nil then
            v = math.max(minVal, math.min(maxVal, v))
            set(v)
            edit:SetText(tostring(v))
        end
        edit:ClearFocus()
    end)
    edit:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        local v = tonumber(self:GetText())
        if v ~= nil then
            v = math.max(minVal, math.min(maxVal, v))
            set(v)
        end
    end)

    local function valueToNorm(v)
        if maxVal <= minVal then return 0 end
        return (v - minVal) / (maxVal - minVal)
    end
    local function normToValue(n)
        return minVal + n * (maxVal - minVal)
    end

    local function updateFromValue(v)
        v = math.max(minVal, math.min(maxVal, v))
        local n = valueToNorm(v)
        thumb:ClearAllPoints()
        thumb:SetPoint("CENTER", track, "LEFT", n * trackWidth, 0)
        trackFill:SetWidth(n * trackWidth)
        edit:SetText(tostring(math.floor(v + 0.5)))
    end

    local dragging = false
    local startNorm, startX
    thumb:SetScript("OnMouseDown", function(_, btn)
        if btn ~= "LeftButton" then return end
        dragging = true
        startNorm = valueToNorm(get())
        local scale = track:GetEffectiveScale()
        startX = GetCursorPosition() / scale
        thumb:GetParent():SetScript("OnUpdate", function()
            if not IsMouseButtonDown("LeftButton") then
                thumb:GetParent():SetScript("OnUpdate", nil)
                dragging = false
                return
            end
            local x = GetCursorPosition() / scale
            local delta = (x - startX) / trackWidth
            local n = math.max(0, math.min(1, startNorm + delta))
            local v = normToValue(n)
            set(v)
            updateFromValue(v)
            startNorm = n
            startX = x
        end)
    end)

    function row:Refresh()
        updateFromValue(get())
    end

    row:Refresh()
    return row
end

-- Custom dropdown: button + popup list (no UIDropDownMenuTemplate)
function OptionsWidgets_CreateCustomDropdown(parent, labelText, description, options, get, set, displayFn)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(52)
    local searchText = (labelText or "") .. " " .. (description or "")
    row.searchText = searchText:lower()

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    label:SetJustifyH("LEFT")
    SetTextColor(label, Def.TextColorLabel)
    label:SetText(labelText or "")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    local desc = row:CreateFontString(nil, "OVERLAY")
    desc:SetFont(Def.FontPath, Def.SectionSize, "OUTLINE")
    desc:SetJustifyH("LEFT")
    SetTextColor(desc, Def.TextColorSection)
    desc:SetText(description or "")
    desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    desc:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    desc:SetWordWrap(true)

    local btn = CreateFrame("Button", nil, row)
    btn:SetHeight(24)
    btn:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -28)
    btn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    local btnBg = btn:CreateTexture(nil, "BACKGROUND")
    btnBg:SetAllPoints(btn)
    btnBg:SetColorTexture(Def.InputBg[1], Def.InputBg[2], Def.InputBg[3], Def.InputBg[4])
    local btnText = btn:CreateFontString(nil, "OVERLAY")
    btnText:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    SetTextColor(btnText, Def.TextColorLabel)
    btnText:SetPoint("LEFT", btn, "LEFT", 8, 0)
    btnText:SetPoint("RIGHT", btn, "RIGHT", -24, 0)
    btnText:SetJustifyH("LEFT")
    local chevron = btn:CreateFontString(nil, "OVERLAY")
    chevron:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    SetTextColor(chevron, Def.TextColorSection)
    chevron:SetText("v")
    chevron:SetPoint("RIGHT", btn, "RIGHT", -6, 0)

    local list = CreateFrame("Frame", nil, UIParent)
    list:SetFrameStrata("TOOLTIP")
    list:Hide()
    list:SetSize(200, 1)
    local listBg = list:CreateTexture(nil, "BACKGROUND")
    listBg:SetAllPoints(list)
    listBg:SetColorTexture(Def.SectionCardBg[1], Def.SectionCardBg[2], Def.SectionCardBg[3], Def.SectionCardBg[4])
    local listBorder = list:CreateTexture(nil, "BORDER")
    listBorder:SetAllPoints(list)
    listBorder:SetColorTexture(Def.SectionCardBorder[1], Def.SectionCardBorder[2], Def.SectionCardBorder[3], Def.SectionCardBorder[4])

    local catch = CreateFrame("Button", nil, UIParent)
    catch:SetFrameStrata("TOOLTIP")
    catch:SetAllPoints(UIParent)
    catch:Hide()

    local function closeList()
        list:Hide()
        catch:Hide()
    end
    catch:SetScript("OnClick", closeList)

    local function setValue(value, display)
        set(value)
        btnText:SetText(display or tostring(value))
        closeList()
    end

    btn:SetScript("OnClick", function()
        if list:IsShown() then closeList() return end
        list:SetParent(UIParent)
        list:ClearAllPoints()
        list:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
        local opts = (type(options) == "function" and options()) or options or {}
        local num = #opts
        local rowH = 22
        list:SetHeight(num * rowH)
        list:SetWidth(btn:GetWidth())
        while list:GetNumChildren() < num do
            local b = CreateFrame("Button", nil, list)
            b:SetHeight(rowH)
            b:SetPoint("LEFT", list, "LEFT", 0, 0)
            b:SetPoint("RIGHT", list, "RIGHT", 0, 0)
            local tb = b:CreateFontString(nil, "OVERLAY")
            tb:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
            tb:SetPoint("LEFT", b, "LEFT", 8, 0)
            tb:SetJustifyH("LEFT")
            b.text = tb
            local hi = b:CreateTexture(nil, "BACKGROUND")
            hi:SetAllPoints(b)
            hi:SetColorTexture(1, 1, 1, 0.08)
            hi:Hide()
            b:SetScript("OnEnter", function() hi:Show() end)
            b:SetScript("OnLeave", function() hi:Hide() end)
        end
        local children = { list:GetChildren() }
        for i, opt in ipairs(opts) do
            local name = opt[1]
            local value = opt[2]
            local b = children[i]
            if b then
                b:SetPoint("TOP", list, "TOP", 0, -(i-1)*rowH)
                b.text:SetText(name)
                b:SetScript("OnClick", function()
                    setValue(value, name)
                end)
                b:Show()
            end
        end
        for i = #opts + 1, #children do
            if children[i] then children[i]:Hide() end
        end
        list:Show()
        catch:Show()
    end)

    function row:Refresh()
        local val = get()
        local opts = (type(options) == "function" and options()) or options or {}
        for _, opt in ipairs(opts) do
            if opt[2] == val then
                btnText:SetText(opt[1])
                return
            end
        end
        if displayFn then
            btnText:SetText(displayFn(val))
        else
            btnText:SetText(tostring(val))
        end
    end

    row:Refresh()
    return row
end

-- Color swatch + Reset link
function OptionsWidgets_CreateColorSwatch(parent, labelText, description, dbKey, defaultColor, get, set, onReset)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(28)
    local searchText = (labelText or "") .. " " .. (description or "")
    row.searchText = searchText:lower()

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    label:SetJustifyH("LEFT")
    SetTextColor(label, Def.TextColorLabel)
    label:SetText(labelText or "")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    local desc = row:CreateFontString(nil, "OVERLAY")
    desc:SetFont(Def.FontPath, Def.SectionSize, "OUTLINE")
    desc:SetJustifyH("LEFT")
    SetTextColor(desc, Def.TextColorSection)
    desc:SetText(description or "")
    desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    desc:SetPoint("RIGHT", row, "RIGHT", -80, 0)
    desc:SetWordWrap(true)

    local def = defaultColor or { 0.5, 0.5, 0.5 }
    local swatch = CreateFrame("Button", nil, row)
    swatch:SetSize(20, 20)
    swatch:SetPoint("TOPRIGHT", row, "TOPRIGHT", -50, -4)
    local tex = swatch:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(swatch)
    local bc = Def.SectionCardBorder
    local e = 1
    do
        local t1 = swatch:CreateTexture(nil, "BORDER"); t1:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t1:SetHeight(e); t1:SetPoint("TOPLEFT", swatch, "TOPLEFT", 0, 0); t1:SetPoint("TOPRIGHT", swatch, "TOPRIGHT", 0, 0)
        local t2 = swatch:CreateTexture(nil, "BORDER"); t2:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t2:SetHeight(e); t2:SetPoint("BOTTOMLEFT", swatch, "BOTTOMLEFT", 0, 0); t2:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", 0, 0)
        local t3 = swatch:CreateTexture(nil, "BORDER"); t3:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t3:SetWidth(e); t3:SetPoint("TOPLEFT", swatch, "TOPLEFT", 0, 0); t3:SetPoint("BOTTOMLEFT", swatch, "BOTTOMLEFT", 0, 0)
        local t4 = swatch:CreateTexture(nil, "BORDER"); t4:SetColorTexture(bc[1], bc[2], bc[3], bc[4]); t4:SetWidth(e); t4:SetPoint("TOPRIGHT", swatch, "TOPRIGHT", 0, 0); t4:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", 0, 0)
    end
    swatch.tex = tex
    swatch:SetScript("OnClick", function()
        local db = get()
        local r, g, b = def[1], def[2], def[3]
        if db and #db >= 3 then r, g, b = db[1], db[2], db[3] end
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, hasOpacity = false,
            swatchFunc = function()
                addon.EnsureDB()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                HorizonSuiteDB[dbKey] = { nr, ng, nb }
                tex:SetColorTexture(nr, ng, nb, 1)
                if onReset then onReset() end
            end,
            cancelFunc = function()
                local prev = ColorPickerFrame.previousValues
                if prev then set({ prev.r, prev.g, prev.b }) if onReset then onReset() end end
            end,
            finishedFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                set({ nr, ng, nb })
                tex:SetColorTexture(nr, ng, nb, 1)
                if onReset then onReset() end
            end,
        })
    end)

    local resetBtn = CreateFrame("Button", nil, row)
    resetBtn:SetSize(40, 18)
    resetBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    local resetLabel = resetBtn:CreateFontString(nil, "OVERLAY")
    resetLabel:SetFont(Def.FontPath, Def.SectionSize, "OUTLINE")
    SetTextColor(resetLabel, Def.TextColorSection)
    resetLabel:SetText("Reset")
    resetLabel:SetPoint("CENTER", resetBtn, "CENTER", 0, 0)
    resetBtn:SetScript("OnClick", function()
        set(nil)
        if HorizonSuiteDB then HorizonSuiteDB[dbKey] = nil end
        tex:SetColorTexture(def[1], def[2], def[3], 1)
        if onReset then onReset() end
    end)

    function row:Refresh()
        local db = get()
        local r, g, b = def[1], def[2], def[3]
        if db and #db >= 3 then r, g, b = db[1], db[2], db[3] end
        tex:SetColorTexture(r, g, b, 1)
    end

    row:Refresh()
    return row
end

-- Search input: full width, optional magnifier icon and clear button
function OptionsWidgets_CreateSearchInput(parent, onTextChanged)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(32)
    local edit = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    edit:SetHeight(24)
    edit:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    edit:SetPoint("TOPRIGHT", row, "TOPRIGHT", -28, 0)
    edit:SetAutoFocus(false)
    edit:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    edit:SetScript("OnEscapePressed", function()
        edit:SetText("")
        edit:ClearFocus()
        if onTextChanged then onTextChanged("") end
    end)
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput and onTextChanged then onTextChanged(self:GetText()) end
    end)

    local clearBtn = CreateFrame("Button", nil, row)
    clearBtn:SetSize(24, 24)
    clearBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    local clearText = clearBtn:CreateFontString(nil, "OVERLAY")
    clearText:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    SetTextColor(clearText, Def.TextColorSection)
    clearText:SetText("X")
    clearText:SetPoint("CENTER", clearBtn, "CENTER", 0, 0)
    clearBtn:SetScript("OnClick", function()
        edit:SetText("")
        if onTextChanged then onTextChanged("") end
    end)

    row.edit = edit
    row.clearBtn = clearBtn
    row.searchText = ""
    return row
end

-- Section card: deep cinematic background, 1px border
function OptionsWidgets_CreateSectionCard(parent, anchor)
    local card = CreateFrame("Frame", nil, parent)
    card:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -Def.SectionGap)
    card:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    local cardBg = card:CreateTexture(nil, "BACKGROUND")
    cardBg:SetAllPoints(card)
    cardBg:SetColorTexture(Def.SectionCardBg[1], Def.SectionCardBg[2], Def.SectionCardBg[3], Def.SectionCardBg[4])
    local b = Def.BorderEdge
    local bc = Def.SectionCardBorder
    for _, pt in ipairs({{"TOP",b,true},{"BOTTOM",b,true},{"LEFT",b,false},{"RIGHT",b,false}}) do
        local tex = card:CreateTexture(nil, "BORDER")
        tex:SetColorTexture(bc[1], bc[2], bc[3], bc[4])
        if pt[3] then tex:SetHeight(pt[2]) tex:SetPoint(pt[1], card, pt[1]) tex:SetPoint("LEFT", card, "LEFT", 0, 0) tex:SetPoint("RIGHT", card, "RIGHT", 0, 0)
        else tex:SetWidth(pt[2]) tex:SetPoint(pt[1], card, pt[1]) tex:SetPoint("TOP", card, "TOP", 0, 0) tex:SetPoint("BOTTOM", card, "BOTTOM", 0, 0) end
    end
    return card
end

-- Section header: uppercase label, left-aligned
function OptionsWidgets_CreateSectionHeader(parent, text)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(Def.FontPath, Def.SectionSize, "OUTLINE")
    label:SetJustifyH("LEFT")
    SetTextColor(label, Def.TextColorSection)
    label:SetText(text and text:upper() or "")
    return label
end

-- Reorder list: drag rows with ghost and insertion line. scrollFrameRef and panelRef for auto-scroll.
local REORDER_ROW_GAP = 4
local REORDER_ROW_HEIGHT = 24
local REORDER_AUTOSCROLL_MARGIN = 40
local REORDER_AUTOSCROLL_STEP = 10

function OptionsWidgets_CreateReorderList(parent, anchor, opt, scrollFrameRef, panelRef, notifyMainAddonFn)
    local keys = opt.get and opt.get() or {}
    if type(keys) == "function" then keys = keys() end
    if type(keys) ~= "table" then keys = {} end
    local defaultOrder = addon.GROUP_ORDER
    if #keys < #defaultOrder then
        local seen = {}
        for _, k in ipairs(keys) do seen[k] = true end
        for _, k in ipairs(defaultOrder) do
            if not seen[k] then keys[#keys + 1] = k end
        end
    end
    local labelMap = opt.labelMap or {}
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -Def.SectionGap)
    container:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    local sectionLabel = OptionsWidgets_CreateSectionHeader(container, opt.name or "Order")
    sectionLabel:SetPoint("TOPLEFT", container, "TOPLEFT", Def.CardPadding, -Def.CardPadding)

    local rows = {}
    local keyToRow = {}
    local state = {
        active = false,
        sourceIndex = nil,
        targetIndex = nil,
        ghostFrame = nil,
        insertionLine = nil,
        sourceRow = nil,
        rows = rows,
        keyToRow = keyToRow,
        get = opt.get,
        set = opt.set,
    }

    local function ensureGhost()
        if state.ghostFrame then return state.ghostFrame end
        local ghost = CreateFrame("Frame", nil, UIParent)
        ghost:SetFrameStrata("TOOLTIP")
        ghost:SetSize(240, REORDER_ROW_HEIGHT)
        ghost:SetAlpha(0.85)
        local bg = ghost:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(ghost)
        bg:SetColorTexture(Def.SectionCardBg[1], Def.SectionCardBg[2], Def.SectionCardBg[3], 0.95)
        state.ghostFrame = ghost
        state.ghostLabel = ghost:CreateFontString(nil, "OVERLAY")
        state.ghostLabel:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
        SetTextColor(state.ghostLabel, Def.TextColorLabel)
        state.ghostLabel:SetPoint("LEFT", ghost, "LEFT", 28, 0)
        return ghost
    end

    local function ensureInsertionLine()
        if state.insertionLine then return state.insertionLine end
        local line = container:CreateTexture(nil, "OVERLAY")
        line:SetHeight(3)
        line:SetColorTexture(Def.AccentColor[1], Def.AccentColor[2], Def.AccentColor[3], 1)
        state.insertionLine = line
        return line
    end

    local function getInsertionIndexFromCursor()
        if #rows == 0 then return 1 end
        for i = 1, #rows do
            if rows[i]:IsMouseOver() then return i end
        end
        return #rows + 1
    end

    local function repositionRows(orderedKeys)
        local prev = sectionLabel
        for i, key in ipairs(orderedKeys) do
            local row = keyToRow[key]
            if row then
                row.index = i
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -REORDER_ROW_GAP)
                prev = row
            end
        end
        local newRows = {}
        for i, key in ipairs(orderedKeys) do
            if keyToRow[key] then newRows[i] = keyToRow[key] end
        end
        state.rows = newRows
    end

    local function applyReorderAndCleanup()
        if not state.active or not state.rows or #state.rows == 0 then return end
        panelRef:SetScript("OnUpdate", nil)
        state.active = false
        local fromIdx = state.sourceIndex
        local toIdx = state.targetIndex or fromIdx
        if state.ghostFrame then state.ghostFrame:Hide() end
        if state.insertionLine then state.insertionLine:Hide() end
        if state.sourceRow then state.sourceRow:SetAlpha(1) end
        if toIdx == fromIdx then return end
        local orderedKeys = {}
        for i, row in ipairs(state.rows) do orderedKeys[i] = row.key end
        local k = orderedKeys[fromIdx]
        table.remove(orderedKeys, fromIdx)
        local insertAt = (fromIdx < toIdx) and (toIdx - 1) or toIdx
        table.insert(orderedKeys, insertAt, k)
        state.set(orderedKeys)
        repositionRows(orderedKeys)
        if notifyMainAddonFn then notifyMainAddonFn() end
    end

    local function onReorderUpdate()
        if not state.active or not IsMouseButtonDown("LeftButton") then
            applyReorderAndCleanup()
            return
        end
        local ghost = ensureGhost()
        local line = ensureInsertionLine()
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        if scale and scale > 0 then x, y = x / scale, y / scale end
        ghost:ClearAllPoints()
        ghost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        ghost:Show()
        if state.ghostLabel and state.sourceRow and state.sourceRow.label then
            state.ghostLabel:SetText(state.sourceRow.label:GetText() or "")
        end
        local insertIdx = getInsertionIndexFromCursor()
        state.targetIndex = insertIdx
        if insertIdx <= #rows then
            local ref = rows[insertIdx]
            line:ClearAllPoints()
            line:SetPoint("LEFT", ref, "LEFT", 0, 0)
            line:SetPoint("RIGHT", ref, "RIGHT", 0, 0)
            line:SetPoint("BOTTOM", ref, "TOP", 0, REORDER_ROW_GAP / 2)
            line:Show()
        elseif #rows > 0 then
            local last = rows[#rows]
            line:ClearAllPoints()
            line:SetPoint("LEFT", last, "LEFT", 0, 0)
            line:SetPoint("RIGHT", last, "RIGHT", 0, 0)
            line:SetPoint("TOP", last, "BOTTOM", 0, -REORDER_ROW_GAP / 2)
            line:Show()
        end
        if scrollFrameRef then
            local vh = scrollFrameRef:GetHeight()
            local cur = scrollFrameRef:GetVerticalScroll()
            local maxScroll = math.max((scrollFrameRef:GetScrollChild() and scrollFrameRef:GetScrollChild():GetHeight() or 0) - vh, 0)
            local sy = select(2, GetCursorPosition()) / (scrollFrameRef:GetEffectiveScale() or 1)
            local sfBottom = scrollFrameRef:GetBottom()
            local sfTop = scrollFrameRef:GetTop()
            if sfTop and sy > sfTop - REORDER_AUTOSCROLL_MARGIN and maxScroll > 0 then
                scrollFrameRef:SetVerticalScroll(math.min(cur + REORDER_AUTOSCROLL_STEP, maxScroll))
            elseif sfBottom and sy < sfBottom + REORDER_AUTOSCROLL_MARGIN and cur > 0 then
                scrollFrameRef:SetVerticalScroll(math.max(cur - REORDER_AUTOSCROLL_STEP, 0))
            end
        end
    end

    local prevAnchor = sectionLabel
    for i, key in ipairs(keys) do
        local row = CreateFrame("Button", nil, container)
        row:SetSize(240, REORDER_ROW_HEIGHT)
        row:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -REORDER_ROW_GAP)
        prevAnchor = row
        row.key = key
        row.index = i
        keyToRow[key] = row
        local lab = row:CreateFontString(nil, "OVERLAY")
        lab:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
        lab:SetJustifyH("LEFT")
        SetTextColor(lab, Def.TextColorLabel)
        lab:SetText((labelMap[key]) or key:gsub("^%l", string.upper))
        lab:SetPoint("LEFT", row, "LEFT", 24, 0)
        row.label = lab
        local grip = row:CreateFontString(nil, "OVERLAY")
        grip:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
        SetTextColor(grip, Def.TextColorSection)
        grip:SetText("::")
        grip:SetPoint("LEFT", row, "LEFT", 4, 0)
        row:SetScript("OnMouseDown", function(_, btn)
            if btn ~= "LeftButton" then return end
            state.active = true
            state.sourceIndex = row.index
            state.targetIndex = row.index
            state.sourceRow = row
            row:SetAlpha(0.5)
            ensureGhost():Show()
            state.ghostLabel:SetText(lab:GetText())
            panelRef:SetScript("OnUpdate", onReorderUpdate)
        end)
        rows[i] = row
    end

    local resetBtn = CreateFrame("Button", nil, container)
    resetBtn:SetSize(100, 22)
    resetBtn:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -6)
    local resetLabel = resetBtn:CreateFontString(nil, "OVERLAY")
    resetLabel:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    SetTextColor(resetLabel, Def.TextColorLabel)
    resetLabel:SetText("Reset order")
    resetLabel:SetPoint("CENTER", resetBtn, "CENTER", 0, 0)
    resetBtn:SetScript("OnClick", function()
        if opt.set then opt.set(nil) end
        if HorizonSuiteDB then HorizonSuiteDB.groupOrder = nil end
        local newKeys = opt.get and opt.get() or {}
        if type(newKeys) == "function" then newKeys = newKeys() end
        if type(newKeys) == "table" then repositionRows(newKeys) end
        if notifyMainAddonFn then notifyMainAddonFn() end
    end)

    local totalH = Def.CardPadding + 14 + (#keys * (REORDER_ROW_HEIGHT + REORDER_ROW_GAP)) + 6 + 22 + Def.CardPadding
    container:SetHeight(totalH)
    container.searchText = (opt.name or "order") .. " " .. (opt.tooltip or "")
    function container:Refresh()
        local newKeys = opt.get and opt.get() or {}
        if type(newKeys) == "function" then newKeys = newKeys() end
        if type(newKeys) == "table" then repositionRows(newKeys) end
    end
    return container
end

-- Export Def for panel (font updates)
addon.OptionsWidgetsDef = Def
