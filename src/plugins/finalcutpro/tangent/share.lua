--- === plugins.finalcutpro.tangent.share ===
---
--- Final Cut Pro Share Inspector for Tangent

local require = require

--local log                   = require("hs.logger").new("tangentShare")

local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")

local plugin = {
    id = "finalcutpro.tangent.share",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.common"]  = "common",
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Setup:
    --------------------------------------------------------------------------------
    local id                            = 0x0F780000

    local common                        = deps.common
    local fcpGroup                      = deps.fcpGroup

    local doShowParameter               = common.doShowParameter

    --------------------------------------------------------------------------------
    -- GENERATOR INSPECTOR:
    --------------------------------------------------------------------------------
    local share                     = fcp.inspector.share
    local shareGroup                = fcpGroup:group(i18n("share") .. " " .. i18n("inspector"))

        --------------------------------------------------------------------------------
        -- Show Inspector:
        --------------------------------------------------------------------------------
        doShowParameter(shareGroup, share, id, i18n("show") .. " " .. i18n("inspector"))

end

return plugin
