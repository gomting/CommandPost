--- === plugins.finalcutpro.preferences.manager ===
---
--- Final Cut Pro Preferences Panel Manager.

local require           = require

local image             = require "hs.image"

local fcp               = require "cp.apple.finalcutpro"
local tools             = require "cp.tools"
local i18n              = require "cp.i18n"

local iconFallback      = tools.iconFallback
local imageFromPath     = image.imageFromPath

local plugin = {
    id              = "finalcutpro.preferences.manager",
    group           = "finalcutpro",
    dependencies    = {
        ["core.preferences.manager"]    = "manager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local mod = {}
    mod.panel = deps.manager.addPanel({
        priority    = 2040,
        id          = "finalcutpro",
        label       = i18n("finalCutProPanelLabel"),
        image       = imageFromPath(iconFallback(fcp:getPath() .. "/Contents/Resources/Final Cut.icns", fcp:getPath() .. "/Contents/Resources/AppIcon.icns")),
        tooltip     = i18n("finalCutProPanelTooltip"),
        height      = 630,
    })

    return mod
end

return plugin
