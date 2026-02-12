--[[
    Horizon Suite - Focus - Options Data
    OptionCategories (General, Content, Style, Colors, Categories), getDB/setDB/notifyMainAddon, search index.
]]

if not HorizonDB then HorizonDB = {} end
local addon = _G.HorizonSuite
if not addon then return end

-- ---------------------------------------------------------------------------
-- DB helpers
-- ---------------------------------------------------------------------------

local TYPOGRAPHY_KEYS = {
    fontPath = true,
    headerFontSize = true,
    titleFontSize = true,
    objectiveFontSize = true,
    zoneFontSize = true,
    sectionFontSize = true,
    fontOutline = true,
}

function OptionsData_GetDB(key, default)
    return addon.GetDB(key, default)
end

local updateOptionsPanelFontsRef
function OptionsData_SetUpdateFontsRef(fn)
    updateOptionsPanelFontsRef = fn
end

function OptionsData_SetDB(key, value)
    addon.SetDB(key, value)
    if key == "fontPath" and updateOptionsPanelFontsRef then
        updateOptionsPanelFontsRef()
    end
    if TYPOGRAPHY_KEYS[key] and addon.UpdateFontObjectsFromDB then
        addon.UpdateFontObjectsFromDB()
    end
    if key == "lockPosition" and addon.UpdateResizeHandleVisibility then
        addon.UpdateResizeHandleVisibility()
    end
    OptionsData_NotifyMainAddon()
end

function OptionsData_NotifyMainAddon()
    local applyTy = _G.HorizonSuite_ApplyTypography or addon.ApplyTypography
    if applyTy then applyTy() end
    if _G.HorizonSuite_ApplyDimensions then _G.HorizonSuite_ApplyDimensions() end
    if addon.ApplyBackdropOpacity then addon.ApplyBackdropOpacity() end
    if addon.ApplyBorderVisibility then addon.ApplyBorderVisibility() end
    if _G.HorizonSuite_RequestRefresh then _G.HorizonSuite_RequestRefresh() end
    if _G.HorizonSuite_FullLayout and not InCombatLockdown() then _G.HorizonSuite_FullLayout() end
end

-- ---------------------------------------------------------------------------
-- Option value helpers (used in category descriptors)
-- ---------------------------------------------------------------------------

local function getDB(k, d) return addon.GetDB(k, d) end
local function setDB(k, v) return OptionsData_SetDB(k, v) end

local defaultFontPath = (addon.GetDefaultFontPath and addon.GetDefaultFontPath()) or "Fonts\\FRIZQT__.TTF"

local function GetFontDropdownOptions()
    if addon.RefreshFontList then addon.RefreshFontList() end
    local list = (addon.GetFontList and addon.GetFontList()) or {}
    local saved = getDB("fontPath", defaultFontPath)
    for _, o in ipairs(list) do
        if o[2] == saved then return list end
    end
    local out = {}
    for i = 1, #list do out[i] = list[i] end
    out[#out + 1] = { "Custom", saved }
    return out
end

local OUTLINE_OPTIONS = {
    { "None", "" },
    { "Outline", "OUTLINE" },
    { "Thick Outline", "THICKOUTLINE" },
}
local HIGHLIGHT_OPTIONS = {
    { "Bar (left edge)", "bar-left" },
    { "Bar (right edge)", "bar-right" },
    { "Bar (top edge)", "bar-top" },
    { "Bar (bottom edge)", "bar-bottom" },
    { "Outline only", "outline" },
    { "Soft glow", "glow" },
    { "Dual edge bars", "bar-both" },
    { "Pill left accent", "pill-left" },
    { "Highlight", "highlight" },
}
local MPLUS_POSITION_OPTIONS = {
    { "Top", "top" },
    { "Bottom", "bottom" },
}
-- Use addon.QUEST_COLORS from Config as single source for quest type colors.
local COLOR_KEYS_ORDER = { "DEFAULT", "CAMPAIGN", "LEGENDARY", "WORLD", "DELVES", "SCENARIO", "WEEKLY", "DAILY", "COMPLETE", "RARE" }
local ZONE_COLOR_DEFAULT = { 0.55, 0.65, 0.75 }
local OBJ_COLOR_DEFAULT = { 0.78, 0.78, 0.78 }
local OBJ_DONE_COLOR_DEFAULT = { 0.30, 0.80, 0.30 }
local HIGHLIGHT_COLOR_DEFAULT = { 0.4, 0.7, 1 }

local VALID_HIGHLIGHT_STYLES = {
    ["bar-left"] = true, ["bar-right"] = true, ["bar-top"] = true, ["bar-bottom"] = true,
    ["outline"] = true, ["glow"] = true, ["bar-both"] = true, ["pill-left"] = true, ["highlight"] = true,
}
local function getActiveQuestHighlight()
    local v = addon.NormalizeHighlightStyle(getDB("activeQuestHighlight", "bar-left"))
    if not VALID_HIGHLIGHT_STYLES[v] then return "bar-left" end
    return v
end

-- ---------------------------------------------------------------------------
-- OptionCategories: General, Content, Style, Colors, Categories
-- ---------------------------------------------------------------------------

local OptionCategories = {
    {
        key = "General",
        name = "General",
        options = {
            { type = "section", name = "Panel behavior" },
            { type = "toggle", name = "Lock position", desc = "Prevent dragging to reposition the tracker.", dbKey = "lockPosition", get = function() return (HorizonDB and HorizonDB.lockPosition) == true end, set = function(v) setDB("lockPosition", v) end },
            { type = "toggle", name = "Grow upward", desc = "Anchor the tracker by its bottom edge so the list expands upward.", dbKey = "growUp", get = function() return getDB("growUp", false) end, set = function(v) setDB("growUp", v) end },
            { type = "toggle", name = "Start collapsed", desc = "When enabled, the objectives panel starts collapsed (header only) until you expand it.", dbKey = "collapsed", get = function() return (HorizonDB and HorizonDB.collapsed) == true end, set = function(v) setDB("collapsed", v) end },
            { type = "section", name = "Instance visibility" },
            { type = "toggle", name = "Show in dungeon", desc = "Show the tracker while in a party dungeon.", dbKey = "showInDungeon", get = function() return getDB("showInDungeon", false) end, set = function(v) setDB("showInDungeon", v) end },
            { type = "toggle", name = "Show in raid", desc = "Show the tracker while in a raid.", dbKey = "showInRaid", get = function() return getDB("showInRaid", false) end, set = function(v) setDB("showInRaid", v) end },
            { type = "toggle", name = "Show in battleground", desc = "Show the tracker while in a battleground.", dbKey = "showInBattleground", get = function() return getDB("showInBattleground", false) end, set = function(v) setDB("showInBattleground", v) end },
            { type = "toggle", name = "Show in arena", desc = "Show the tracker while in an arena.", dbKey = "showInArena", get = function() return getDB("showInArena", false) end, set = function(v) setDB("showInArena", v) end },
            { type = "section", name = "Combat" },
            { type = "toggle", name = "Hide in combat", desc = "Hide the tracker and floating quest item while in combat.", dbKey = "hideInCombat", get = function() return getDB("hideInCombat", false) end, set = function(v) setDB("hideInCombat", v) end },
            { type = "section", name = "Dimensions" },
            { type = "slider", name = "Panel width", desc = "Width of the tracker in pixels.", dbKey = "panelWidth", min = 180, max = 800, get = function() return getDB("panelWidth", 260) end, set = function(v) setDB("panelWidth", math.max(180, math.min(800, v))) end },
            { type = "slider", name = "Max content height", desc = "Maximum height of the scrollable content area.", dbKey = "maxContentHeight", min = 200, max = 1000, get = function() return getDB("maxContentHeight", 480) end, set = function(v) setDB("maxContentHeight", math.max(200, math.min(1000, v))) end },
        },
    },
    {
        key = "Content",
        name = "Content",
        options = {
            { type = "section", name = "Header" },
            { type = "toggle", name = "Show quest count", desc = "Show the tracked quest count in the header.", dbKey = "showQuestCount", get = function() return getDB("showQuestCount", true) end, set = function(v) setDB("showQuestCount", v) end },
            { type = "toggle", name = "Show header divider", desc = "Show the line below the OBJECTIVES header.", dbKey = "showHeaderDivider", get = function() return getDB("showHeaderDivider", true) end, set = function(v) setDB("showHeaderDivider", v) end },
            { type = "toggle", name = "Super-minimal mode", desc = "Hide the OBJECTIVES header for a pure text list.", dbKey = "hideObjectivesHeader", get = function() return getDB("hideObjectivesHeader", false) end, set = function(v) setDB("hideObjectivesHeader", v) end },
            { type = "section", name = "List" },
            { type = "toggle", name = "Show section headers", desc = "Show category labels above each group.", dbKey = "showSectionHeaders", get = function() return getDB("showSectionHeaders", true) end, set = function(v) setDB("showSectionHeaders", v) end },
            { type = "toggle", name = "Show zone labels", desc = "Show the zone name under each quest title.", dbKey = "showZoneLabels", get = function() return getDB("showZoneLabels", true) end, set = function(v) setDB("showZoneLabels", v) end },
            { type = "toggle", name = "Show quest type icons", desc = "Show quest type icon to the left of each title.", dbKey = "showQuestTypeIcons", get = function() return getDB("showQuestTypeIcons", false) end, set = function(v) setDB("showQuestTypeIcons", v) end },
            { type = "dropdown", name = "Active quest highlight", desc = "How the super-tracked quest is highlighted.", dbKey = "activeQuestHighlight", options = HIGHLIGHT_OPTIONS, get = getActiveQuestHighlight, set = function(v) setDB("activeQuestHighlight", v) end },
            { type = "toggle", name = "Show quest item buttons", desc = "Show the usable quest item button to the left of the quest type icon. Text and icon positions stay the same.", dbKey = "showQuestItemButtons", get = function() return getDB("showQuestItemButtons", false) end, set = function(v) setDB("showQuestItemButtons", v) end },
            { type = "toggle", name = "Show objective numbers", desc = "Prefix objectives with 1., 2., 3.", dbKey = "showObjectiveNumbers", get = function() return getDB("showObjectiveNumbers", false) end, set = function(v) setDB("showObjectiveNumbers", v) end },
            { type = "toggle", name = "Show completed count", desc = "Show X/Y objective progress in quest title.", dbKey = "showCompletedCount", get = function() return getDB("showCompletedCount", false) end, set = function(v) setDB("showCompletedCount", v) end },
            { type = "toggle", name = "Compact mode", desc = "Reduce spacing between quest entries.", dbKey = "compactMode", get = function() return getDB("compactMode", false) end, set = function(v) setDB("compactMode", v) end },
            { type = "toggle", name = "Show quest level", desc = "Show quest level next to the title.", dbKey = "showQuestLevel", get = function() return getDB("showQuestLevel", false) end, set = function(v) setDB("showQuestLevel", v) end },
            { type = "toggle", name = "Dim non-super-tracked quests", desc = "Slightly dim quests that are not super-tracked.", dbKey = "dimNonSuperTracked", get = function() return getDB("dimNonSuperTracked", false) end, set = function(v) setDB("dimNonSuperTracked", v) end },
            { type = "toggle", name = "Click title to open quest log", desc = "Single left-click opens quest log instead of super-tracking.", dbKey = "clickTitleOpensQuestLog", get = function() return getDB("clickTitleOpensQuestLog", false) end, set = function(v) setDB("clickTitleOpensQuestLog", v) end },
            { type = "toggle", name = "Right double-click to abandon", desc = "Right double-click on a quest abandons it with confirmation.", dbKey = "doubleClickToAbandon", get = function() return getDB("doubleClickToAbandon", true) end, set = function(v) setDB("doubleClickToAbandon", v) end },
            { type = "section", name = "Filtering" },
            { type = "toggle", name = "Only show quests in current zone", desc = "Hide tracked quests not in your current zone.", dbKey = "filterByZone", get = function() return getDB("filterByZone", false) end, set = function(v) setDB("filterByZone", v) end },
            { type = "section", name = "Rare bosses" },
            { type = "toggle", name = "Show rare bosses", desc = "Show rare boss vignettes in the list.", dbKey = "showRareBosses", get = function() return getDB("showRareBosses", true) end, set = function(v) setDB("showRareBosses", v) end },
            { type = "toggle", name = "Rare added sound", desc = "Play a sound when a rare is added to the list.", dbKey = "rareAddedSound", get = function() return getDB("rareAddedSound", true) end, set = function(v) setDB("rareAddedSound", v) end },
            { type = "section", name = "Floating quest item" },
            { type = "toggle", name = "Show floating quest item", desc = "Show a quick-use button for the super-tracked quest's usable item.", dbKey = "showFloatingQuestItem", get = function() return getDB("showFloatingQuestItem", false) end, set = function(v) setDB("showFloatingQuestItem", v) end },
            { type = "toggle", name = "Lock floating quest item position", desc = "Prevent dragging to reposition the floating quest item button.", dbKey = "lockFloatingQuestItemPosition", get = function() return getDB("lockFloatingQuestItemPosition", false) end, set = function(v) setDB("lockFloatingQuestItemPosition", v) end },
            { type = "section", name = "Mythic+" },
            { type = "toggle", name = "Show Mythic+ block", desc = "Show timer, completion %, and affixes when in a Mythic+ dungeon.", dbKey = "showMythicPlusBlock", get = function() return getDB("showMythicPlusBlock", false) end, set = function(v) setDB("showMythicPlusBlock", v) end },
            { type = "dropdown", name = "M+ block position", desc = "Position of the Mythic+ block relative to the quest list.", dbKey = "mplusBlockPosition", options = MPLUS_POSITION_OPTIONS, get = function() return getDB("mplusBlockPosition", "top") end, set = function(v) setDB("mplusBlockPosition", v) end },
            { type = "section", name = "Scenario & Delve events" },
            { type = "toggle", name = "Show scenario events", desc = "Show active scenario and Delve activities (main and bonus steps). Delves appear in a dedicated DELVES section with all in-delve objectives; other scenarios use SCENARIO EVENTS.", dbKey = "showScenarioEvents", get = function() return getDB("showScenarioEvents", true) end, set = function(v) setDB("showScenarioEvents", v) end },
            { type = "toggle", name = "Hide other categories in Delve or Dungeon", desc = "When in a Delve, show only the DELVES section; when in a party dungeon, show only the Dungeon section. All other categories (quests, rares, etc.) are hidden.", dbKey = "hideOtherCategoriesInDelve", get = function() return getDB("hideOtherCategoriesInDelve", false) end, set = function(v) setDB("hideOtherCategoriesInDelve", v) end },
            { type = "toggle", name = "Cinematic scenario bar", desc = "Show the timer and progress bar for scenario entries with a clean cinematic style.", dbKey = "cinematicScenarioBar", get = function() return getDB("cinematicScenarioBar", true) end, set = function(v) setDB("cinematicScenarioBar", v) end },
            { type = "slider", name = "Scenario bar opacity", desc = "Opacity of the scenario timer/progress bar (0–1).", dbKey = "scenarioBarOpacity", min = 0.3, max = 1, get = function() return tonumber(getDB("scenarioBarOpacity", 0.85)) or 0.85 end, set = function(v) setDB("scenarioBarOpacity", v) end },
            { type = "slider", name = "Scenario bar height", desc = "Height of the scenario progress bar in pixels (4–8).", dbKey = "scenarioBarHeight", min = 4, max = 8, get = function() return math.max(4, math.min(8, tonumber(getDB("scenarioBarHeight", 6)) or 6)) end, set = function(v) setDB("scenarioBarHeight", math.max(4, math.min(8, v))) end },
        },
    },
    {
        key = "Style",
        name = "Style",
        options = {
            { type = "section", name = "Typography" },
            { type = "dropdown", name = "Font", desc = "Font family for the tracker.", dbKey = "fontPath", options = GetFontDropdownOptions, get = function() return getDB("fontPath", defaultFontPath) end, set = function(v) setDB("fontPath", v) end, displayFn = addon.GetFontNameForPath },
            { type = "slider", name = "Header size", desc = "Font size for the OBJECTIVES header.", dbKey = "headerFontSize", min = 8, max = 32, get = function() return getDB("headerFontSize", 16) end, set = function(v) setDB("headerFontSize", v) end },
            { type = "slider", name = "Title size", desc = "Font size for quest titles.", dbKey = "titleFontSize", min = 8, max = 24, get = function() return getDB("titleFontSize", 13) end, set = function(v) setDB("titleFontSize", v) end },
            { type = "slider", name = "Objective size", desc = "Font size for objective text.", dbKey = "objectiveFontSize", min = 8, max = 20, get = function() return getDB("objectiveFontSize", 11) end, set = function(v) setDB("objectiveFontSize", v) end },
            { type = "slider", name = "Zone size", desc = "Font size for zone labels.", dbKey = "zoneFontSize", min = 8, max = 18, get = function() return getDB("zoneFontSize", 10) end, set = function(v) setDB("zoneFontSize", v) end },
            { type = "slider", name = "Section size", desc = "Font size for section headers.", dbKey = "sectionFontSize", min = 8, max = 18, get = function() return getDB("sectionFontSize", 10) end, set = function(v) setDB("sectionFontSize", v) end },
            { type = "dropdown", name = "Outline", desc = "Font outline style.", dbKey = "fontOutline", options = OUTLINE_OPTIONS, get = function() return getDB("fontOutline", "OUTLINE") end, set = function(v) setDB("fontOutline", v) end },
            { type = "section", name = "Shadow" },
            { type = "toggle", name = "Show text shadow", desc = "Enable drop shadow on tracker text.", dbKey = "showTextShadow", get = function() return getDB("showTextShadow", true) end, set = function(v) setDB("showTextShadow", v) end },
            { type = "slider", name = "Shadow X", desc = "Horizontal shadow offset.", dbKey = "shadowOffsetX", min = -10, max = 10, get = function() return getDB("shadowOffsetX", 2) end, set = function(v) setDB("shadowOffsetX", v) end },
            { type = "slider", name = "Shadow Y", desc = "Vertical shadow offset.", dbKey = "shadowOffsetY", min = -10, max = 10, get = function() return getDB("shadowOffsetY", -2) end, set = function(v) setDB("shadowOffsetY", v) end },
            { type = "slider", name = "Shadow alpha", desc = "Shadow opacity (0–1).", dbKey = "shadowAlpha", min = 0, max = 1, get = function() return getDB("shadowAlpha", 0.8) end, set = function(v) setDB("shadowAlpha", v) end },
            { type = "section", name = "Panel" },
            { type = "slider", name = "Backdrop opacity", desc = "Opacity of the tracker panel background (0–1).", dbKey = "backdropOpacity", min = 0, max = 1, get = function() return tonumber(getDB("backdropOpacity", 0)) or 0 end, set = function(v) setDB("backdropOpacity", v) end },
            { type = "toggle", name = "Show border", desc = "Show a border around the tracker panel.", dbKey = "showBorder", get = function() return getDB("showBorder", false) end, set = function(v) setDB("showBorder", v) end },
            { type = "section", name = "Highlight" },
            { type = "slider", name = "Highlight alpha", desc = "Opacity of the super-tracked quest highlight bar or background (0–1).", dbKey = "highlightAlpha", min = 0, max = 1, get = function() return tonumber(getDB("highlightAlpha", 0.25)) or 0.25 end, set = function(v) setDB("highlightAlpha", v) end },
            { type = "slider", name = "Bar width", desc = "Width of bar-style highlights in pixels (2–6). Affects bar-top, bar-bottom, bar-both, pill-left.", dbKey = "highlightBarWidth", min = 2, max = 6, get = function() return math.max(2, math.min(6, tonumber(getDB("highlightBarWidth", 2)) or 2)) end, set = function(v) setDB("highlightBarWidth", math.max(2, math.min(6, v))) end },
        },
    },
    {
        key = "Colors",
        name = "Colors",
        options = {
            { type = "section", name = "Quest type colors" },
            { type = "colorMatrix", name = "Colors", dbKey = "questColors", keys = COLOR_KEYS_ORDER, defaultMap = addon.QUEST_COLORS, resetSectionKeys = true,
                overrides = {
                    { dbKey = "zoneColor", name = "Zone label", default = ZONE_COLOR_DEFAULT, tooltip = "Zone name under quest title." },
                    { dbKey = "objectiveColor", name = "Objective text", default = OBJ_COLOR_DEFAULT, tooltip = "Active objectives." },
                    { dbKey = "objectiveDoneColor", name = "Completed objective", default = OBJ_DONE_COLOR_DEFAULT, tooltip = "Done objectives, ready to turn in." },
                    { dbKey = "highlightColor", name = "Highlight", default = HIGHLIGHT_COLOR_DEFAULT, tooltip = "Super-tracked quest bar or background." },
                },
            },
            { type = "colorGroup", name = "Section header colors", dbKey = "sectionColors", keys = function() return addon.GetGroupOrder() end, defaultMap = addon.SECTION_COLORS, labelMap = addon.SECTION_LABELS, tooltip = "Colors for category labels." },
        },
    },
    {
        key = "Categories",
        name = "Categories",
        options = {
            { type = "section", name = "Focus order" },
            { type = "reorderList", name = "Focus category order", labelMap = addon.SECTION_LABELS, get = function() return addon.GetGroupOrder() end, set = function(order) addon.SetGroupOrder(order) end, tooltip = "Drag to reorder categories in the Focus list. DELVES and SCENARIO EVENTS are always pinned first and second." },
            { type = "section", name = "Sort within categories" },
            { type = "dropdown", name = "Focus sort mode", desc = "How entries are ordered within each category.", dbKey = "entrySortMode", options = { { "Alphabetical", "alpha" }, { "Quest Type", "questType" }, { "Zone", "zone" }, { "Quest Level", "level" } }, get = function() return getDB("entrySortMode", "questType") end, set = function(v) setDB("entrySortMode", v) end },
            { type = "section", name = "Effects" },
            { type = "toggle", name = "Animations", desc = "Enable cinematic slide and fade for quests.", dbKey = "animations", get = function() return getDB("animations", true) end, set = function(v) setDB("animations", v) end },
            { type = "toggle", name = "Objective progress flash", desc = "Show a green flash when an objective is completed.", dbKey = "objectiveProgressFlash", get = function() return getDB("objectiveProgressFlash", true) end, set = function(v) setDB("objectiveProgressFlash", v) end },
        },
    },
}

-- ---------------------------------------------------------------------------
-- Search index: flatten all options for search (name + desc)
-- ---------------------------------------------------------------------------

function OptionsData_BuildSearchIndex()
    local index = {}
    for _, cat in ipairs(OptionCategories) do
        for _, opt in ipairs(cat.options) do
            if opt.type ~= "section" then
                local name = (opt.name or ""):lower()
                local desc = (opt.desc or opt.tooltip or ""):lower()
                local searchText = name .. " " .. desc
                index[#index + 1] = {
                    categoryKey = cat.key,
                    categoryName = cat.name,
                    option = opt,
                    searchText = searchText,
                }
            end
        end
    end
    return index
end

-- Export for panel
addon.OptionsData_GetDB = OptionsData_GetDB
addon.OptionsData_SetDB = OptionsData_SetDB
addon.OptionsData_NotifyMainAddon = OptionsData_NotifyMainAddon
addon.OptionsData_SetUpdateFontsRef = OptionsData_SetUpdateFontsRef
addon.OptionCategories = OptionCategories
addon.OptionsData_BuildSearchIndex = OptionsData_BuildSearchIndex
addon.COLOR_KEYS_ORDER = COLOR_KEYS_ORDER
addon.ZONE_COLOR_DEFAULT = ZONE_COLOR_DEFAULT
addon.OBJ_COLOR_DEFAULT = OBJ_COLOR_DEFAULT
addon.OBJ_DONE_COLOR_DEFAULT = OBJ_DONE_COLOR_DEFAULT
addon.HIGHLIGHT_COLOR_DEFAULT = HIGHLIGHT_COLOR_DEFAULT
