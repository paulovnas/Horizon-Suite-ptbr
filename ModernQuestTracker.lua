--[[
    HORIZON SUITE - FOCUS
    A cinematic-styled replacement for the default objective tracker.
    This file only creates the addon namespace; all behavior lives in Core and module files.
]]

if not _G.ModernQuestTracker then _G.ModernQuestTracker = {} end

-- Binding display name for Key Bindings UI
if not _G.BINDING_NAME_CLICK_MQTCollapseButton_LeftButton then
    _G.BINDING_NAME_CLICK_MQTCollapseButton_LeftButton = "Collapse Tracker"
end
