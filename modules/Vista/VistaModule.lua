--[[
    Horizon Suite - Vista Module
    Cinematic square minimap with zone text, coordinates, instance difficulty, mail, and button collector.
    Registers with addon:RegisterModule. Migrated from ModernMinimap.
]]

local addon = _G.HorizonSuite
if not addon or not addon.RegisterModule then return end

addon:RegisterModule("vista", {
    title       = "Vista",
    description = "Cinematic square minimap with zone text, coordinates, instance difficulty, mail indicator, and button collector.",
    order       = 25,

    OnInit = function()
        -- Migrate from standalone ModernMinimapDB to HorizonDB.modules.vista
        if _G.ModernMinimapDB and HorizonDB and HorizonDB.modules and HorizonDB.modules.vista then
            local src = _G.ModernMinimapDB
            local dst = HorizonDB.modules.vista
            -- Only migrate if we have no position data (fresh Vista or old vista was Presence)
            local hasPosition = dst.point or dst.x or dst.y
            if not hasPosition and (src.point or src.x or src.y or src.scale or src.lock ~= nil or src.autoZoom ~= nil) then
                dst.point = src.point
                dst.relpoint = src.relpoint
                dst.x = src.x
                dst.y = src.y
                dst.scale = src.scale
                dst.lock = src.lock
                dst.autoZoom = src.autoZoom
                if src.enabled ~= nil then
                    dst.enabled = src.enabled
                end
            end
        end

        -- Ensure defaults for Vista-specific fields
        if HorizonDB and HorizonDB.modules and HorizonDB.modules.vista then
            local d = HorizonDB.modules.vista
            if d.enabled == nil then d.enabled = true end
            if d.lock == nil then d.lock = false end
            if d.autoZoom == nil then d.autoZoom = 5 end
            if d.scale == nil then d.scale = 1.0 end
        end
    end,

    OnEnable = function()
        if addon.Vista and addon.Vista.Init then
            addon.Vista.Init()
        end
    end,

    OnDisable = function()
        if addon.Vista and addon.Vista.Disable then
            addon.Vista.Disable()
        end
    end,
})
