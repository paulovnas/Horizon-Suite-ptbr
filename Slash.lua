--[[
    Horizon Suite - Focus - Slash Commands
    /horizon and subcommands.
]]

local A = _G.ModernQuestTracker

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
        A.enabled = not A.enabled
        if A.enabled then
            A.TrySuppressTracker()
            A.ScheduleRefresh()
            print("|cFF00CCFFHorizon Suite - Focus:|r |cFF00FF00Enabled|r")
        else
            A.RestoreTracker()
            A.MQT:Hide()
            for i = 1, A.POOL_SIZE do A.ClearEntry(A.pool[i]) end
            wipe(A.activeMap)
            A.HideAllSectionHeaders()
            A.sectionIdx = 0
            print("|cFF00CCFFHorizon Suite - Focus:|r |cFFFF0000Disabled|r")
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
            pcall(PlaySound, A.RARE_ADDED_SOUND)
            print("|cFF00CCFFHorizon Suite - Focus:|r Played rare-added sound.")
        else
            print("|cFF00CCFFHorizon Suite - Focus:|r Could not play sound.")
        end

    elseif cmd == "test" then
        print("|cFF00CCFFHorizon Suite - Focus:|r Showing test data (10 entries)...")

        local testQuests = {
            { questID = 90001, title = "The Fate of the Horde",
              color = A.QUEST_COLORS.CAMPAIGN, category = "CAMPAIGN",
              questTypeAtlas = "Quest-Campaign-Available",
              isComplete = false, isSuperTracked = true, isNearby = true, isAccepted = true,
              zoneName = "Valdrakken",
              itemLink = "item:12345:0:0:0:0:0:0:0", itemTexture = "Interface\\Icons\\INV_Misc_Rune_01",
              objectives = {
                  { text = "Speak with Thrall", finished = true },
                  { text = "Harbingers defeated: 2/5", finished = false },
              }},
            { questID = 90002, title = "Aiding the Accord",
              color = A.QUEST_COLORS.DEFAULT, category = "DEFAULT",
              isComplete = false, isSuperTracked = false, isNearby = true, isAccepted = true,
              zoneName = "Valdrakken",
              objectives = {
                  { text = "Dragon Glyphs: 3/5", finished = false },
                  { text = "World Quests: 2/3", finished = false },
              }},
            { questID = 90007, title = "Scales of War",
              color = A.QUEST_COLORS.DEFAULT, category = "DEFAULT",
              isComplete = false, isSuperTracked = false, isNearby = true, isAccepted = true,
              zoneName = "Valdrakken",
              objectives = {
                  { text = "War Scales collected: 14/20", finished = false },
              }},
            { questID = 90006, title = "Threads of Fate",
              color = A.QUEST_COLORS.CAMPAIGN, category = "CAMPAIGN",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "The Waking Shores",
              objectives = {
                  { text = "Explore the Loom: 1/3", finished = false },
              }},
            { questID = 90008, title = "The Last Stitch",
              color = A.QUEST_COLORS.CAMPAIGN, category = "CAMPAIGN",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Azure Span",
              itemLink = "item:67890:0:0:0:0:0:0:0", itemTexture = "Interface\\Icons\\INV_Fabric_Silk_02",
              objectives = {
                  { text = "Mend the Veil: 0/1", finished = false },
                  { text = "Gather Thread: 5/8", finished = false },
              }},
            { questID = 90003, title = "World Boss: Doomwalker",
              color = A.QUEST_COLORS.WORLD, category = "WORLD",
              questTypeAtlas = "quest-recurring-available",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Thaldraszus",
              objectives = {
                  { text = "Slay Doomwalker", finished = false },
              }},
            { questID = 90009, title = "Elemental Fury",
              color = A.QUEST_COLORS.WORLD, category = "CALLING",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "The Forbidden Reach",
              objectives = {
                  { text = "Elemental cores: 1/3", finished = false },
              }},
            { questID = 90004, title = "The Legendary Cloak",
              color = A.QUEST_COLORS.LEGENDARY, category = "LEGENDARY",
              questTypeAtlas = "UI-QuestPoiLegendary-QuestBang",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Ohn'ahran Plains",
              objectives = {
                  { text = "Collect 50 Echoes: 37/50", finished = false },
              }},
            { questID = 90010, title = "Supply Run",
              color = A.QUEST_COLORS.DEFAULT, category = "DEFAULT",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Stormwind City",
              objectives = {
                  { text = "Deliver supplies: 0/1", finished = false },
              }},
            { questID = 90005, title = "Boar Pelts",
              color = A.QUEST_COLORS.COMPLETE, category = "COMPLETE",
              questTypeAtlas = "QuestTurnin",
              isComplete = true, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Elwynn Forest",
              objectives = {
                  { text = "Boar Pelts: 10/10", finished = true },
              }},
        }

        -- Inject test data into the quest pipeline and use the normal layout engine.
        A.testQuests = testQuests
        if A.collapsed then
            A.collapsed = false
            A.chevron:SetText("-")
            A.scrollFrame:Show()
            if HorizonSuiteDB then HorizonSuiteDB.collapsed = false end
        end
        A.FullLayout()

    elseif cmd == "reset" then
        -- Clear any injected test data and return to live quest data.
        A.testQuests = nil
        A.ScheduleRefresh()
        print("|cFF00CCFFHorizon Suite - Focus:|r Reset tracker to live data.")

    elseif cmd == "resetpos" then
        A.MQT:ClearAllPoints()
        A.MQT:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", A.PANEL_X, A.PANEL_Y)
        if HorizonSuiteDB then
            HorizonSuiteDB.point    = nil
            HorizonSuiteDB.relPoint = nil
            HorizonSuiteDB.x        = nil
            HorizonSuiteDB.y        = nil
        end
        print("|cFF00CCFFHorizon Suite - Focus:|r Position reset to default.")

    elseif cmd == "options" or cmd == "config" then
        if _G.ModernQuestTracker_ShowOptions then
            _G.ModernQuestTracker_ShowOptions()
        else
            print("|cFF00CCFFHorizon Suite - Focus:|r Options not loaded.")
        end

    else
        print("|cFF00CCFFHorizon Suite - Focus Commands:|r")
        print("  /horizon            - Show this help")
        print("  /horizon toggle     - Enable / disable")
        print("  /horizon collapse   - Collapse / expand panel")
        print("  /horizon options    - Open options window")
        print("  /horizon testsound  - Play the rare-added notification sound")
        print("  /horizon test       - Show with test data")
        print("  /horizon reset      - Reset to live data")
        print("  /horizon resetpos   - Reset panel to default position")
        print("")
        print("  Click the header row to collapse / expand.")
        print("  Scroll with mouse wheel when content overflows.")
        print("  Drag the panel to reposition it (saved across sessions).")
        print("  Left-click a quest or rare to super-track; double-click quest to open log.")
        print("  Right-click a quest to untrack it; right-click rare to clear super-track.")
    end
end
