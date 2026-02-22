--[[
    Horizon Suite - Vista - Core
    Cinematic square minimap with zone text, coordinates, instance difficulty, mail, tracking, button collector.
    Migrated from ModernMinimap. Blizzard APIs: Minimap, C_Map, C_ChallengeMode, etc.
]]

local addon = _G.HorizonSuite
if not addon then return end

addon.Vista = addon.Vista or {}

local Vista = addon.Vista

-- Typography
local FONT_PATH   = "Fonts\\FRIZQT__.TTF"
local ZONE_SIZE   = 12
local COORD_SIZE  = 10

local BORDER_COLOR  = { 1, 1, 1, 0.15 }
local ZONE_COLOR    = { 1, 1, 1 }
local COORD_COLOR   = { 0.55, 0.65, 0.75 }
local DIFF_COLOR    = { 0.55, 0.65, 0.75 }
local DIFF_SIZE     = 10

local SHADOW_OX   = 2
local SHADOW_OY   = -2
local SHADOW_A    = 0.8

local MAP_SIZE    = 200
local BORDER_W    = 1

local BTN_SIZE    = 26
local BTN_GAP     = 4

local FADE_DUR       = 0.20
local COORD_THROTTLE = 0.1

local PULSE_MIN   = 0.40
local PULSE_MAX   = 1.00
local PULSE_SPEED = 2.0

local DEFAULT_POINT    = "TOPRIGHT"
local DEFAULT_RELPOINT = "TOPRIGHT"
local DEFAULT_X        = -20
local DEFAULT_Y        = -20

local function easeOut(t) return 1 - (1 - t) * (1 - t) end

-- Proxy frame for taint-free Minimap manipulation
local proxy = CreateFrame("Frame")

local blizzardFramesToHide = {
    "MinimapBorderTop",
    "MiniMapWorldMapButton",
    "MinimapZoomIn",
    "MinimapZoomOut",
    "MinimapCompassTexture",
    "GameTimeFrame",
    "MinimapBackdrop",
    "MinimapNorthTag",
    "MinimapZoneTextButton",
    "MiniMapInstanceDifficulty",
}

local function KillFrame(name)
    local frame = _G[name]
    if not frame then return end
    pcall(function()
        frame:Hide()
        frame:SetAlpha(0)
        frame:SetSize(1, 1)
        frame.Show = function() end
    end)
end

local function StripBlizzardChrome()
    for _, name in ipairs(blizzardFramesToHide) do
        KillFrame(name)
    end

    pcall(function()
        if MinimapBorder then
            MinimapBorder:Hide()
            MinimapBorder:SetAlpha(0)
        end
    end)

    pcall(function()
        if MinimapCluster then
            local children = { MinimapCluster:GetChildren() }
            for _, child in ipairs(children) do
                if child and child ~= Minimap then
                    pcall(function()
                        child:Hide()
                        child:SetAlpha(0)
                        child.Show = function() end
                    end)
                end
            end
            local regions = { MinimapCluster:GetRegions() }
            for _, region in ipairs(regions) do
                pcall(function()
                    region:Hide()
                    region:SetAlpha(0)
                end)
            end
        end
    end)

    pcall(function()
        local regions = { Minimap:GetRegions() }
        for _, region in ipairs(regions) do
            if region and region:IsObjectType("Texture") then
                local tex = region:GetTexture()
                if tex and type(tex) == "string" then
                    local low = tex:lower()
                    if low:find("border") or low:find("background") or low:find("compass") then
                        region:SetAlpha(0)
                    end
                end
            end
        end
    end)

    pcall(function()
        Minimap:SetArchBlobRingScalar(0)
        Minimap:SetArchBlobRingAlpha(0)
        Minimap:SetQuestBlobRingScalar(0)
        Minimap:SetQuestBlobRingAlpha(0)
    end)
end

local decor, zoneText, zoneShadow, diffText, diffShadow, coordText, coordShadow
local mailFrame, mailPulsing
local collectorBar, collectedButtons = {}, {}
local barAlpha, hoverTarget, hoverElapsed = 0, 0, 0
local coordElapsed = 0
local zoomStarted, zoomCurrent = 0, 0
local hookedButtons = {}
local setParentHook

local function ScheduleAutoZoom()
    if not addon.GetDB then return end
    local autoZoom = addon.GetDB("vistaAutoZoom", 5)
    if autoZoom and autoZoom > 0 then
        zoomStarted = zoomStarted + 1
        C_Timer.After(autoZoom, function()
            zoomCurrent = zoomCurrent + 1
            if zoomStarted == zoomCurrent then
                for i = 1, Minimap:GetZoom() or 0 do
                    if Minimap_ZoomOutClick then
                        Minimap_ZoomOutClick()
                    elseif Minimap.ZoomOut then
                        Minimap.ZoomOut:Click()
                    end
                end
                zoomStarted, zoomCurrent = 0, 0
            end
        end)
    end
end

local function SetupMinimap()
    if not addon.GetDB then return end
    local pt = addon.GetDB("vistaPoint", nil)
    local rp = addon.GetDB("vistaRelPoint", nil)
    local vx = addon.GetDB("vistaX", nil)
    local vy = addon.GetDB("vistaY", nil)
    local scale = addon.GetDB("vistaScale", 1.0)

    Minimap:SetSize(MAP_SIZE, MAP_SIZE)
    Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")

    if pt then
        proxy.ClearAllPoints(Minimap)
        proxy.SetPoint(Minimap, pt, UIParent, rp or pt, vx or 0, vy or 0)
    else
        proxy.ClearAllPoints(Minimap)
        proxy.SetPoint(Minimap, DEFAULT_POINT, UIParent, DEFAULT_RELPOINT, DEFAULT_X, DEFAULT_Y)
    end

    if hooksecurefunc and not Vista._setPointHooked then
        Vista._setPointHooked = true
        hooksecurefunc(Minimap, "SetPoint", function()
            if not addon:IsModuleEnabled("vista") then return end
            if not addon.GetDB then return end
            local dpt = addon.GetDB("vistaPoint", nil)
            if dpt then
                proxy.ClearAllPoints(Minimap)
                proxy.SetPoint(Minimap, dpt, UIParent, addon.GetDB("vistaRelPoint", dpt) or dpt, addon.GetDB("vistaX", 0) or 0, addon.GetDB("vistaY", 0) or 0)
            end
        end)
    end

    local moduleScale = (addon.GetModuleScale and addon.GetModuleScale("vista")) or 1
    proxy.SetScale(Minimap, (scale or 1.0) * moduleScale)

    Minimap:Show()
    Minimap:SetAlpha(1)
end

local function CreateDecor()
    decor = CreateFrame("Frame", "HorizonSuiteVistaDecor", Minimap)
    decor:SetAllPoints(Minimap)
    decor:SetFrameLevel(Minimap:GetFrameLevel() + 5)

    local borderTop = decor:CreateTexture(nil, "OVERLAY")
    borderTop:SetColorTexture(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
    borderTop:SetHeight(BORDER_W)
    borderTop:SetPoint("TOPLEFT",  Minimap, "TOPLEFT",  0, BORDER_W)
    borderTop:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, BORDER_W)

    local borderBottom = decor:CreateTexture(nil, "OVERLAY")
    borderBottom:SetColorTexture(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
    borderBottom:SetHeight(BORDER_W)
    borderBottom:SetPoint("BOTTOMLEFT",  Minimap, "BOTTOMLEFT",  0, -BORDER_W)
    borderBottom:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, -BORDER_W)

    local borderLeft = decor:CreateTexture(nil, "OVERLAY")
    borderLeft:SetColorTexture(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
    borderLeft:SetWidth(BORDER_W)
    borderLeft:SetPoint("TOPLEFT",    Minimap, "TOPLEFT",    -BORDER_W, BORDER_W)
    borderLeft:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -BORDER_W, -BORDER_W)

    local borderRight = decor:CreateTexture(nil, "OVERLAY")
    borderRight:SetColorTexture(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
    borderRight:SetWidth(BORDER_W)
    borderRight:SetPoint("TOPRIGHT",    Minimap, "TOPRIGHT",    BORDER_W, BORDER_W)
    borderRight:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", BORDER_W, -BORDER_W)

    Minimap:SetMovable(true)
    Minimap:SetClampedToScreen(true)
    Minimap:RegisterForDrag("LeftButton")

    Minimap:SetScript("OnDragStart", function(self)
        if not addon.GetDB then return end
        local lock = addon.GetDB("vistaLock", false)
        if not lock and self:IsMovable() then
            if not InCombatLockdown() then self:StartMoving() end
        end
    end)

    Minimap:SetScript("OnDragStop", function(self)
        if InCombatLockdown() then return end
        self:StopMovingOrSizing()
        if not addon.SetDB then return end
        local p, _, rp, x, y = self:GetPoint()
        addon.SetDB("vistaPoint", p)
        addon.SetDB("vistaRelPoint", rp)
        addon.SetDB("vistaX", x)
        addon.SetDB("vistaY", y)
    end)

    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(_, d)
        if d > 0 then
            (MinimapZoomIn or Minimap.ZoomIn):Click()
        elseif d < 0 then
            (MinimapZoomOut or Minimap.ZoomOut):Click()
        end
    end)

    pcall(function()
        if MinimapZoomIn then
            MinimapZoomIn:HookScript("OnClick", ScheduleAutoZoom)
            MinimapZoomOut:HookScript("OnClick", ScheduleAutoZoom)
        elseif Minimap.ZoomIn then
            Minimap.ZoomIn:HookScript("OnClick", ScheduleAutoZoom)
            Minimap.ZoomOut:HookScript("OnClick", ScheduleAutoZoom)
        end
    end)

    Minimap:HookScript("OnMouseWheel", ScheduleAutoZoom)

    zoneShadow = decor:CreateFontString(nil, "BORDER")
    zoneShadow:SetFont(FONT_PATH, ZONE_SIZE, "OUTLINE")
    zoneShadow:SetTextColor(0, 0, 0, SHADOW_A)
    zoneShadow:SetJustifyH("CENTER")

    zoneText = decor:CreateFontString(nil, "OVERLAY")
    zoneText:SetFont(FONT_PATH, ZONE_SIZE, "OUTLINE")
    zoneText:SetTextColor(ZONE_COLOR[1], ZONE_COLOR[2], ZONE_COLOR[3])
    zoneText:SetJustifyH("CENTER")
    zoneText:SetPoint("TOP", Minimap, "BOTTOM", 0, -6)
    zoneText:SetWidth(MAP_SIZE)
    zoneShadow:SetPoint("CENTER", zoneText, "CENTER", SHADOW_OX, SHADOW_OY)
    zoneShadow:SetWidth(MAP_SIZE)

    diffShadow = decor:CreateFontString(nil, "BORDER")
    diffShadow:SetFont(FONT_PATH, DIFF_SIZE, "OUTLINE")
    diffShadow:SetTextColor(0, 0, 0, SHADOW_A)
    diffShadow:SetJustifyH("CENTER")

    diffText = decor:CreateFontString(nil, "OVERLAY")
    diffText:SetFont(FONT_PATH, DIFF_SIZE, "OUTLINE")
    diffText:SetTextColor(DIFF_COLOR[1], DIFF_COLOR[2], DIFF_COLOR[3])
    diffText:SetJustifyH("CENTER")
    diffText:SetPoint("TOP", zoneText, "BOTTOM", 0, -2)
    diffText:SetWidth(MAP_SIZE)
    diffShadow:SetPoint("CENTER", diffText, "CENTER", SHADOW_OX, SHADOW_OY)
    diffShadow:SetWidth(MAP_SIZE)

    coordShadow = decor:CreateFontString(nil, "BORDER")
    coordShadow:SetFont(FONT_PATH, COORD_SIZE, "OUTLINE")
    coordShadow:SetTextColor(0, 0, 0, SHADOW_A)
    coordShadow:SetJustifyH("RIGHT")

    coordText = decor:CreateFontString(nil, "OVERLAY")
    coordText:SetFont(FONT_PATH, COORD_SIZE, "OUTLINE")
    coordText:SetTextColor(COORD_COLOR[1], COORD_COLOR[2], COORD_COLOR[3])
    coordText:SetJustifyH("RIGHT")
    coordText:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", -2, -6)
    coordShadow:SetPoint("CENTER", coordText, "CENTER", SHADOW_OX, SHADOW_OY)
end

local function UpdateZoneText()
    if not zoneText then return end
    local zone = GetMinimapZoneText() or ""
    zoneText:SetText(zone)
    zoneShadow:SetText(zone)
end

local function UpdateDifficultyText()
    if not diffText then return end
    local _, instanceType, difficultyID = GetInstanceInfo()
    if instanceType == "none" or difficultyID == 0 then
        diffText:SetText("")
        diffShadow:SetText("")
        return
    end

    local diffName = GetDifficultyInfo(difficultyID)
    if not diffName or diffName == "" then
        diffText:SetText("")
        diffShadow:SetText("")
        return
    end

    if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo then
        local keystoneLevel = C_ChallengeMode.GetActiveKeystoneInfo()
        if keystoneLevel and keystoneLevel > 0 then
            diffName = diffName .. " +" .. keystoneLevel
        end
    end

    diffText:SetText(diffName)
    diffShadow:SetText(diffName)
end

local function UpdateCoords(_, elapsed)
    if not coordText then return end
    coordElapsed = coordElapsed + elapsed
    if coordElapsed < COORD_THROTTLE then return end
    coordElapsed = 0

    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID and C_Map.GetPlayerMapPosition then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if pos then
                local x, y = pos:GetXY()
                local str = format("%.1f, %.1f", x * 100, y * 100)
                coordText:SetText(str)
                coordShadow:SetText(str)
                return
            end
        end
    end
    coordText:SetText("--")
    coordShadow:SetText("--")
end

local function CreateMailIndicator()
    mailFrame = CreateFrame("Frame", nil, decor)
    mailFrame:SetSize(20, 20)
    mailFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 4, -4)
    mailFrame:SetFrameLevel(decor:GetFrameLevel() + 2)
    mailFrame:Hide()

    local icon = mailFrame:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\MINIMAP\\TRACKING\\Mailbox")
    icon:SetAllPoints()
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    mailFrame.icon = icon

    mailFrame:EnableMouse(true)
    mailFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText("You have mail")
        GameTooltip:Show()
    end)
    mailFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local pulseTime = 0
    mailFrame:SetScript("OnUpdate", function(self, elapsed)
        if not mailPulsing then
            self.icon:SetAlpha(1)
            return
        end
        pulseTime = pulseTime + elapsed
        local t = (math.sin(pulseTime * PULSE_SPEED * math.pi * 2) + 1) / 2
        self.icon:SetAlpha(PULSE_MIN + (PULSE_MAX - PULSE_MIN) * t)
    end)
end

local function UpdateMailIndicator()
    if not mailFrame then return end
    local hasMail = HasNewMail()
    if hasMail then
        mailFrame:Show()
        mailPulsing = true
    else
        mailFrame:Hide()
        mailPulsing = false
    end
end

local function SuppressBlizzardMail()
    pcall(function()
        if MiniMapMailFrame then
            MiniMapMailFrame:Hide()
            MiniMapMailFrame:SetAlpha(0)
            MiniMapMailFrame.Show = function() end
        end
    end)
    pcall(function()
        if MinimapCluster and MinimapCluster.IndicatorFrame then
            local indicator = MinimapCluster.IndicatorFrame
            if indicator.MailFrame then
                indicator.MailFrame:Hide()
                indicator.MailFrame:SetAlpha(0)
                indicator.MailFrame.Show = function() end
            end
            indicator:Hide()
            indicator:SetAlpha(0)
            indicator.Show = function() end
        end
    end)
    pcall(function()
        if MiniMapMailIcon then
            MiniMapMailIcon:Hide()
            MiniMapMailIcon:SetAlpha(0)
            MiniMapMailIcon.Show = function() end
        end
    end)
end

local function RestyleTrackingButton()
    pcall(function()
        local tracking = MiniMapTracking or MinimapTrackingFrame
        if not tracking then return end

        tracking:SetParent(decor)
        tracking:ClearAllPoints()
        tracking:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -4, -4)
        tracking:SetSize(22, 22)
        tracking:SetFrameLevel(decor:GetFrameLevel() + 2)

        local regions = { tracking:GetRegions() }
        for _, region in ipairs(regions) do
            if region and region:IsObjectType("Texture") then
                local rName = region:GetName()
                if rName and (rName:find("Border") or rName:find("Background")) then
                    region:SetAlpha(0)
                end
            end
        end

        if MiniMapTrackingIcon then
            MiniMapTrackingIcon:ClearAllPoints()
            MiniMapTrackingIcon:SetAllPoints(tracking)
            MiniMapTrackingIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end

        if MiniMapTrackingButton then
            MiniMapTrackingButton:SetAllPoints(tracking)
            MiniMapTrackingButton:SetHighlightTexture(nil)
        end
    end)
end

local BLACKLIST = {
    ["HorizonSuiteVistaDecor"]     = true,
    ["HorizonSuiteVistaButtonBar"] = true,
    ["MinimapBackdrop"]           = true,
    ["MinimapCompassTexture"]     = true,
    ["MiniMapMailFrame"]           = true,
    ["MiniMapTracking"]            = true,
    ["MinimapTrackingFrame"]       = true,
    ["MiniMapTrackingButton"]      = true,
    ["MiniMapTrackingIcon"]        = true,
    ["MinimapZoomIn"]              = true,
    ["MinimapZoomOut"]             = true,
    ["MiniMapWorldMapButton"]      = true,
    ["GameTimeFrame"]              = true,
    ["MinimapBorder"]              = true,
    ["MinimapBorderTop"]           = true,
    ["MinimapNorthTag"]            = true,
    ["TimeManagerClockButton"]     = true,
    ["MinimapZoneTextButton"]      = true,
}

local function CreateCollectorBar()
    collectorBar = CreateFrame("Frame", "HorizonSuiteVistaButtonBar", decor)
    collectorBar:SetPoint("TOP", diffText, "BOTTOM", 0, -4)
    collectorBar:SetHeight(BTN_SIZE)
    collectorBar:SetAlpha(0)
    collectorBar:Show()
end

local function LayoutCollectedButtons()
    if not collectorBar then return end
    if #collectedButtons == 0 then
        collectorBar:SetWidth(1)
        return
    end

    local totalWidth = #collectedButtons * BTN_SIZE + (#collectedButtons - 1) * BTN_GAP
    collectorBar:SetWidth(totalWidth)

    for i, btn in ipairs(collectedButtons) do
        btn:ClearAllPoints()
        btn:SetParent(collectorBar)
        btn:SetSize(BTN_SIZE, BTN_SIZE)
        local xOff = (i - 1) * (BTN_SIZE + BTN_GAP)
        btn:SetPoint("LEFT", collectorBar, "LEFT", xOff, 0)
        btn:SetFrameLevel(collectorBar:GetFrameLevel() + 2)
        btn:Show()
    end

    collectorBar:EnableMouse(true)
    collectorBar:SetScript("OnEnter", function()
        hoverTarget = 1
        hoverElapsed = 0
    end)
    collectorBar:SetScript("OnLeave", function()
        if not Minimap:IsMouseOver() and not collectorBar:IsMouseOver() then
            for _, b in ipairs(collectedButtons) do
                if b:IsMouseOver() then return end
            end
            hoverTarget = 0
            hoverElapsed = 0
        end
    end)

    for _, btn in ipairs(collectedButtons) do
        if not hookedButtons[btn] then
            hookedButtons[btn] = true
            btn:HookScript("OnEnter", function()
                hoverTarget = 1
                hoverElapsed = 0
            end)
            btn:HookScript("OnLeave", function()
                if not Minimap:IsMouseOver() and not collectorBar:IsMouseOver() then
                    for _, b in ipairs(collectedButtons) do
                        if b ~= btn and b:IsMouseOver() then return end
                    end
                    hoverTarget = 0
                    hoverElapsed = 0
                end
            end)
        end
    end
end

local function CollectMinimapButtons()
    wipe(collectedButtons)

    local children = { Minimap:GetChildren() }
    for _, child in ipairs(children) do
        if child and child:IsObjectType("Button") and child:IsShown() then
            local cName = child:GetName()
            if cName and not BLACKLIST[cName] then
                local w, h = child:GetSize()
                if w >= 20 and w <= 48 and h >= 20 and h <= 48 then
                    table.insert(collectedButtons, child)
                end
            elseif not cName then
                local w, h = child:GetSize()
                if w >= 20 and w <= 48 and h >= 20 and h <= 48 then
                    table.insert(collectedButtons, child)
                end
            end
        end
    end

    LayoutCollectedButtons()
end

local function OnHoverUpdate(_, elapsed)
    UpdateCoords(nil, elapsed)

    if not collectorBar or #collectedButtons == 0 then return end
    if barAlpha == hoverTarget then return end

    hoverElapsed = hoverElapsed + elapsed
    local t = math.min(hoverElapsed / FADE_DUR, 1)

    if hoverTarget > barAlpha then
        barAlpha = easeOut(t) * hoverTarget
    else
        barAlpha = 1 - easeOut(t)
        if barAlpha < 0 then barAlpha = 0 end
    end

    if t >= 1 then barAlpha = hoverTarget end
    collectorBar:SetAlpha(barAlpha)
end

local eventFrame

--- Initialize Vista minimap. Reparents Minimap, creates decor, strips Blizzard chrome.
--- Called from VistaModule OnEnable.
function Vista.Init()
    if not Minimap or not MinimapCluster then return end

    proxy.SetFrameStrata(Minimap, "LOW")
    proxy.SetFrameLevel(Minimap, 2)
    pcall(function()
        proxy.SetFixedFrameStrata(Minimap, true)
        proxy.SetFixedFrameLevel(Minimap, true)
    end)

    proxy.SetParent(Minimap, UIParent)

    if hooksecurefunc then
        setParentHook = function()
            if addon:IsModuleEnabled("vista") then
                proxy.SetParent(Minimap, UIParent)
            end
        end
        hooksecurefunc(Minimap, "SetParent", setParentHook)
    end

    MinimapCluster:EnableMouse(false)

    if MinimapBackdrop then
        MinimapBackdrop:ClearAllPoints()
        MinimapBackdrop:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
    end

    StripBlizzardChrome()
    CreateDecor()
    SetupMinimap()
    CreateMailIndicator()
    CreateCollectorBar()
    SuppressBlizzardMail()
    RestyleTrackingButton()

    UpdateZoneText()
    UpdateDifficultyText()
    UpdateMailIndicator()

    ScheduleAutoZoom()

    decor:SetScript("OnUpdate", OnHoverUpdate)

    Minimap:HookScript("OnEnter", function()
        hoverTarget = 1
        hoverElapsed = 0
    end)

    Minimap:HookScript("OnLeave", function()
        if collectorBar and collectorBar:IsMouseOver() then return end
        for _, btn in ipairs(collectedButtons) do
            if btn:IsMouseOver() then return end
        end
        hoverTarget = 0
        hoverElapsed = 0
    end)

    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ZONE_CHANGED")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
    eventFrame:RegisterEvent("UPDATE_PENDING_MAIL")
    eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
    eventFrame:RegisterEvent("PET_BATTLE_OPENING_START")
    eventFrame:RegisterEvent("PET_BATTLE_CLOSE")

    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            UpdateZoneText()
            UpdateDifficultyText()
            UpdateMailIndicator()
            C_Timer.After(3, CollectMinimapButtons)
        elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" then
            UpdateZoneText()
            UpdateDifficultyText()
        elseif event == "UPDATE_INSTANCE_INFO" then
            UpdateDifficultyText()
        elseif event == "UPDATE_PENDING_MAIL" then
            UpdateMailIndicator()
        elseif event == "PET_BATTLE_OPENING_START" then
            Minimap:Hide()
        elseif event == "PET_BATTLE_CLOSE" then
            if addon:IsModuleEnabled("vista") then
                Minimap:Show()
            end
        end
    end)

    local showMinimap = addon.GetDB and addon.GetDB("vistaShowMinimap", true)
    if showMinimap ~= false then
        Minimap:Show()
    else
        Minimap:Hide()
    end
end

--- Restore Minimap to MinimapCluster. Called from VistaModule OnDisable.
function Vista.Disable()
    if not Minimap or not MinimapCluster then return end

    if eventFrame then
        eventFrame:UnregisterAllEvents()
        eventFrame:SetScript("OnEvent", nil)
    end

    if decor then
        decor:SetScript("OnUpdate", nil)
    end

    if not InCombatLockdown() then
        proxy.SetParent(Minimap, MinimapCluster)
    end

    ReloadUI()
end

--- Collect minimap buttons (for slash command).
function Vista.CollectButtons()
    CollectMinimapButtons()
    return #collectedButtons
end

-- Slash commands: /mmm and /modernminimap
SLASH_HORIZONSUITEVISTA1 = "/mmm"
SLASH_HORIZONSUITEVISTA2 = "/modernminimap"

SlashCmdList["HORIZONSUITEVISTA"] = function(msg)
    if not addon:IsModuleEnabled("vista") then
        print("|cFF00CCFFHorizon Suite:|r Vista module is disabled. Enable it in Horizon Suite options.")
        return
    end
    if not addon.GetDB or not addon.SetDB then return end

    local cmd = (msg or ""):trim():lower()

    if cmd == "reset" then
        if not InCombatLockdown() then
            proxy.ClearAllPoints(Minimap)
            proxy.SetPoint(Minimap, DEFAULT_POINT, UIParent, DEFAULT_RELPOINT, DEFAULT_X, DEFAULT_Y)
        end
        addon.SetDB("vistaPoint", nil)
        addon.SetDB("vistaRelPoint", nil)
        addon.SetDB("vistaX", nil)
        addon.SetDB("vistaY", nil)
        print("|cFF00CCFFHorizon Suite Vista:|r Position reset to default.")

    elseif cmd == "toggle" then
        if InCombatLockdown() then
            print("|cFF00CCFFHorizon Suite Vista:|r |cFFFF0000Cannot toggle during combat.|r")
            return
        end
        local show = not (addon.GetDB("vistaShowMinimap", true) ~= false)
        addon.SetDB("vistaShowMinimap", show)
        if show then
            Minimap:Show()
            print("|cFF00CCFFHorizon Suite Vista:|r |cFF00FF00Enabled|r")
        else
            Minimap:Hide()
            print("|cFF00CCFFHorizon Suite Vista:|r |cFFFF0000Disabled|r")
        end

    elseif cmd == "lock" then
        local lock = not addon.GetDB("vistaLock", false)
        addon.SetDB("vistaLock", lock)
        Minimap:SetMovable(not lock)
        if lock then
            print("|cFF00CCFFHorizon Suite Vista:|r Minimap |cFFFF8800locked|r. Dragging disabled.")
        else
            print("|cFF00CCFFHorizon Suite Vista:|r Minimap |cFF00FF00unlocked|r. Drag to reposition.")
        end

    elseif cmd:find("^scale") then
        local val = tonumber(cmd:match("scale%s+(.+)"))
        if val then
            val = math.max(0.5, math.min(2.0, val))
            addon.SetDB("vistaScale", val)
            local moduleScale = (addon.GetModuleScale and addon.GetModuleScale("vista")) or 1
            proxy.SetScale(Minimap, val * moduleScale)
            print("|cFF00CCFFHorizon Suite Vista:|r Scale set to " .. format("%.2f", val))
        else
            local cur = addon.GetDB("vistaScale", 1)
            print("|cFF00CCFFHorizon Suite Vista:|r Current scale: " .. format("%.2f", cur or 1) .. "  (usage: /mmm scale 0.5-2.0)")
        end

    elseif cmd:find("^autozoom") then
        local val = tonumber(cmd:match("autozoom%s+(.+)"))
        if val then
            val = math.max(0, math.min(30, math.floor(val)))
            addon.SetDB("vistaAutoZoom", val)
            if val == 0 then
                print("|cFF00CCFFHorizon Suite Vista:|r Auto zoom-out |cFFFF0000disabled|r.")
            else
                print("|cFF00CCFFHorizon Suite Vista:|r Auto zoom-out set to " .. val .. "s.")
            end
        else
            local cur = addon.GetDB("vistaAutoZoom", 5)
            if cur == 0 then
                print("|cFF00CCFFHorizon Suite Vista:|r Auto zoom-out: disabled  (usage: /mmm autozoom 0-30)")
            else
                print("|cFF00CCFFHorizon Suite Vista:|r Auto zoom-out: " .. cur .. "s  (usage: /mmm autozoom 0-30)")
            end
        end

    elseif cmd == "buttons" then
        local n = Vista.CollectButtons()
        print("|cFF00CCFFHorizon Suite Vista:|r Re-scanned minimap buttons. Found " .. n .. ".")

    else
        print("|cFF00CCFFHorizon Suite Vista Commands:|r")
        print("  /mmm              - Show this help")
        print("  /mmm lock         - Toggle lock / unlock (drag)")
        print("  /mmm scale X      - Set scale (0.5 - 2.0)")
        print("  /mmm autozoom X   - Auto zoom-out delay (0=off, 1-30)")
        print("  /mmm reset        - Reset position to default")
        print("  /mmm toggle       - Enable / disable minimap")
        print("  /mmm buttons      - Re-scan minimap buttons")
    end
end

--- Re-apply minimap scale (e.g. after global UI scale change).
function Vista.ApplyScale()
    if not Minimap then return end
    local scale = (addon.GetDB and addon.GetDB("vistaScale", 1.0)) or 1.0
    local moduleScale = (addon.GetModuleScale and addon.GetModuleScale("vista")) or 1
    proxy.SetScale(Minimap, (scale or 1.0) * moduleScale)
end

addon.Vista = Vista
