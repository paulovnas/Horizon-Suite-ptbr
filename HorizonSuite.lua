--[[
    HORIZON SUITE - FOCUS
    A cinematic-styled replacement for the default objective tracker.
    This file only creates the addon namespace; all behavior lives in Core and module files.

    Abbreviation glossary:
    - HS   = Horizon Suite (addon / frame prefix)
    - WQ   = World Quest
    - M+   = Mythic Plus (dungeon)
    - ATT  = All The Things (addon; rare vignette source)
    - WQT  = World Quest / Task Quest (C_TaskQuest API)
]]

if not _G.HorizonSuite then _G.HorizonSuite = {} end

-- Binding display name for Key Bindings UI
if not _G.BINDING_NAME_CLICK_HSCollapseButton_LeftButton then
    _G.BINDING_NAME_CLICK_HSCollapseButton_LeftButton = "Collapse Tracker"
end
