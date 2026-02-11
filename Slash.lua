--[[
    Horizon Suite - Focus - Slash Commands
    /horizon and subcommands.
]]

local addon = _G.ModernQuestTracker
if not addon then return end
local HSPrint = addon.HSPrint or function(msg)
    print("|cFF00CCFFHorizon Suite - Focus:|r " .. tostring(msg or ""))
end

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

SLASH_MODERNQUESTTRACKER1 = "/horizon"
SlashCmdList["MODERNQUESTTRACKER"] = function(msg)
    local cmd = strtrim(msg or ""):lower()

    if cmd == "toggle" then
        if InCombatLockdown() then
            print("|cFFFF0000Horizon Suite - Focus:|r Cannot toggle during combat.")
            return
        end
        addon.enabled = not addon.enabled
        if addon.enabled then
            addon.TrySuppressTracker()
            addon.ScheduleRefresh()
            HSPrint("|cFF00FF00Enabled|r")
        else
            addon.RestoreTracker()
            addon.MQT:Hide()
            for i = 1, addon.POOL_SIZE do addon.ClearEntry(addon.pool[i]) end
            wipe(addon.activeMap)
            addon.HideAllSectionHeaders()
            addon.sectionIdx = 0
            HSPrint("|cFFFF0000Disabled|r")
        end

    elseif cmd == "collapse" then
        A.ToggleCollapse()
        if A.collapsed then
            print("|cFF00CCFFHorizon Suite - Focus:|r Panel collapsed.")
        else
            print("|cFF00CCFFHorizon Suite - Focus:|r Panel expanded.")
        end

    elseif cmd == "testsound" then
        if PlaySound then
            pcall(PlaySound, addon.RARE_ADDED_SOUND)
            HSPrint("Played rare-added sound.")
        else
            HSPrint("Could not play sound.")
        end

    elseif cmd == "test" then
        HSPrint("Showing test data (10 entries)...")

        local testQuests = {
            { questID = 90001, title = "The Fate of the Horde",
              color = addon.QUEST_COLORS.CAMPAIGN, category = "CAMPAIGN",
              questTypeAtlas = "Quest-Campaign-Available",
              isComplete = false, isSuperTracked = true, isNearby = true, isAccepted = true,
              zoneName = "Valdrakken",
              itemLink = "item:12345:0:0:0:0:0:0:0", itemTexture = "Interface\\Icons\\INV_Misc_Rune_01",
              objectives = {
                  { text = "Speak with Thrall", finished = true },
                  { text = "Harbingers defeated: 2/5", finished = false },
              }},
            { questID = 90002, title = "Aiding the Accord",
              color = addon.QUEST_COLORS.DEFAULT, category = "DEFAULT",
              isComplete = false, isSuperTracked = false, isNearby = true, isAccepted = true,
              zoneName = "Valdrakken",
              objectives = {
                  { text = "Dragon Glyphs: 3/5", finished = false },
                  { text = "World Quests: 2/3", finished = false },
              }},
            { questID = 90007, title = "Scales of War",
              color = addon.QUEST_COLORS.DEFAULT, category = "DEFAULT",
              isComplete = false, isSuperTracked = false, isNearby = true, isAccepted = true,
              zoneName = "Valdrakken",
              objectives = {
                  { text = "War Scales collected: 14/20", finished = false },
              }},
            { questID = 90006, title = "Threads of Fate",
              color = addon.QUEST_COLORS.CAMPAIGN, category = "CAMPAIGN",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "The Waking Shores",
              objectives = {
                  { text = "Explore the Loom: 1/3", finished = false },
              }},
            { questID = 90008, title = "The Last Stitch",
              color = addon.QUEST_COLORS.CAMPAIGN, category = "CAMPAIGN",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Azure Span",
              itemLink = "item:67890:0:0:0:0:0:0:0", itemTexture = "Interface\\Icons\\INV_Fabric_Silk_02",
              objectives = {
                  { text = "Mend the Veil: 0/1", finished = false },
                  { text = "Gather Thread: 5/8", finished = false },
              }},
            { questID = 90003, title = "World Boss: Doomwalker",
              color = addon.QUEST_COLORS.WORLD, category = "WORLD",
              questTypeAtlas = "quest-recurring-available",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Thaldraszus",
              objectives = {
                  { text = "Slay Doomwalker", finished = false },
              }},
            { questID = 90009, title = "Elemental Fury",
              color = addon.QUEST_COLORS.WORLD, category = "CALLING",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "The Forbidden Reach",
              objectives = {
                  { text = "Elemental cores: 1/3", finished = false },
              }},
            { questID = 90004, title = "The Legendary Cloak",
              color = addon.QUEST_COLORS.LEGENDARY, category = "LEGENDARY",
              questTypeAtlas = "UI-QuestPoiLegendary-QuestBang",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Ohn'ahran Plains",
              objectives = {
                  { text = "Collect 50 Echoes: 37/50", finished = false },
              }},
            { questID = 90010, title = "Supply Run",
              color = addon.QUEST_COLORS.DEFAULT, category = "DEFAULT",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Stormwind City",
              objectives = {
                  { text = "Deliver supplies: 0/1", finished = false },
              }},
            { questID = 90005, title = "Boar Pelts",
              color = addon.QUEST_COLORS.COMPLETE, category = "COMPLETE",
              questTypeAtlas = "QuestTurnin",
              isComplete = true, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Elwynn Forest",
              objectives = {
                  { text = "Boar Pelts: 10/10", finished = true },
              }},
        }

        -- Inject test data into the quest pipeline and use the normal layout engine.
        addon.testQuests = testQuests
        if addon.collapsed then
            addon.collapsed = false
            addon.chevron:SetText("-")
            addon.scrollFrame:Show()
            if HorizonDB then HorizonDB.collapsed = false end
        end
        addon.FullLayout()

    elseif cmd == "reset" then
        -- Clear any injected test data and return to live quest data.
        addon.testQuests = nil
        addon.ScheduleRefresh()
        HSPrint("Reset tracker to live data.")

    elseif cmd == "resetpos" then
        addon.MQT:ClearAllPoints()
        addon.MQT:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", addon.PANEL_X, addon.PANEL_Y)
        if HorizonDB then
            HorizonDB.point    = nil
            HorizonDB.relPoint = nil
            HorizonDB.x        = nil
            HorizonDB.y        = nil
        end
        HSPrint("Position reset to default.")

    elseif cmd == "options" or cmd == "config" then
        if _G.ModernQuestTracker_ShowOptions then
            _G.ModernQuestTracker_ShowOptions()
        else
            HSPrint("Options not loaded.")
        end

    elseif cmd == "edit" then
        if _G.ModernQuestTracker_ShowEditPanel then
            _G.ModernQuestTracker_ShowEditPanel()
        else
            HSPrint("Edit panel not loaded.")
        end

    else
        HSPrint("Commands:")
        HSPrint("  /horizon            - Show this help")
        HSPrint("  /horizon toggle     - Enable / disable")
        HSPrint("  /horizon collapse   - Collapse / expand panel")
        HSPrint("  /horizon options    - Open options window")
        HSPrint("  /horizon edit       - Open edit screen")
        HSPrint("  /horizon testsound  - Play the rare-added notification sound")
        HSPrint("  /horizon test       - Show with test data")
        HSPrint("  /horizon reset      - Reset to live data")
        HSPrint("  /horizon resetpos   - Reset panel to default position")
        HSPrint("")
        HSPrint("  Click the header row to collapse / expand.")
        HSPrint("  Scroll with mouse wheel when content overflows.")
        HSPrint("  Drag the panel to reposition it (saved across sessions).")
        HSPrint("  Left-click a quest or rare to super-track; double-click quest to open log.")
        HSPrint("  Right-click a quest to untrack it; right-click rare to clear super-track.")
    end
end
