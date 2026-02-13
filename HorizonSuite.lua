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

-- Binding display names for Key Bindings UI (must match Binding name in Bindings.xml exactly)
_G["BINDING_NAME_CLICK HSCollapseButton:LeftButton"] = "Collapse Tracker"
_G["BINDING_NAME_CLICK HSNearbyToggleButton:LeftButton"] = "Toggle Nearby Group"
