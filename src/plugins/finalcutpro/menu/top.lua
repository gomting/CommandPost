--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                      T I M E L I N E    M E N U                            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.menu.top ===
---
--- The top menu section.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local config					= require("cp.config")
local fcp						= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 					= 1.1
local PREFERENCES_PRIORITY		= 1
local SETTING 					= "menubarFinalCutProTopEnabled"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local sectionEnabled = config.prop(SETTING, true)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.menu.top",
	group			= "finalcutpro",
	dependencies	= {
		["core.menu.manager"] 				= "manager",
		["core.preferences.panels.menubar"]	= "prefs",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)

	--------------------------------------------------------------------------------
	-- Create the Timeline section:
	--------------------------------------------------------------------------------
	local shortcuts = dependencies.manager.addSection(PRIORITY)

	--------------------------------------------------------------------------------
	-- Disable the section if the Timeline option is disabled:
	--------------------------------------------------------------------------------
	shortcuts:setDisabledFn(function() return not fcp:isInstalled() or not sectionEnabled() end)

	--------------------------------------------------------------------------------
	-- Add the separator and title for the section:
	--------------------------------------------------------------------------------
	shortcuts
		:addItem(1, function()
			return { title = string.upper(i18n("finalCutPro")) .. ":", disabled = true }
		end)

	--------------------------------------------------------------------------------
	-- Add to General Preferences Panel:
	--------------------------------------------------------------------------------
	local prefs = dependencies.prefs
	prefs:addCheckbox(prefs.SECTIONS_HEADING + PREFERENCES_PRIORITY,
		{
			label = i18n("show") .. " " .. i18n("finalCutPro"),
			onchange = function(id, params) sectionEnabled(params.checked) end,
			checked = sectionEnabled,
		}
	)

	return shortcuts
end

return plugin