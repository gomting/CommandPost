--- === plugins.core.preferences.panels.scripting ===
---
--- Scripting Preferences Panel

local require           = require

--local log               = require "hs.logger".new "snippets"

local hs                = _G.hs

local base64            = require "hs.base64"
local dialog            = require "hs.dialog"
local image             = require "hs.image"
local ipc				= require "hs.ipc"
local timer             = require "hs.timer"

local config            = require "cp.config"
local i18n              = require "cp.i18n"
local json              = require "cp.json"
local tools             = require "cp.tools"

local template          = require "resty.template"

local execute           = hs.execute
local allowAppleScript  = hs.allowAppleScript

local blockAlert        = dialog.blockAlert
local encode            = base64.encode
local encodeURI         = tools.encodeURI
local htmlEscape        = template.escape
local imageFromPath     = image.imageFromPath
local webviewAlert      = dialog.webviewAlert

local mod = {}

--- plugins.core.preferences.panels.scripting.snippets <cp.prop: table>
--- Field
--- Snippets
mod.snippets = json.prop(config.userConfigRootPath, "Snippets", "Snippets.cpSnippets", {}):watch(function()
    if mod._handler then
        --------------------------------------------------------------------------------
        -- Reset the Action Handler each time a Snippet is updated:
        --------------------------------------------------------------------------------
        mod._handler:reset(true)
    end
end)

-- getSelectedSnippet() -> string
-- Function
-- Gets the label of the selected snippet.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A string
local function getSelectedSnippet()
    local snippets = mod.snippets()
    local count = 0
    local firstLabel
    for label, snippet in pairs(snippets) do
        if not firstLabel then
            firstLabel = label
        end
        count = count + 1
        if snippet.selected then
            return label
        end
    end

    if count ~= 0 then
        snippets[firstLabel].selected = true
        mod.snippets(snippets)
    end

    return firstLabel
end

-- getSnippetLabels() -> string
-- Function
-- Gets the HTML code for the Snippets select.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A string
local function getSnippetLabels()
    local snippets = mod.snippets()

    local selectedSnippet = getSelectedSnippet()

    if not selectedSnippet then
        return [[<option selected value="">]] .. i18n("none") .. [[</option>]]
    end

    local labels = {}

    for label, _ in pairs(snippets) do
        table.insert(labels, label)
    end

    table.sort(labels)

    local result = ""
    for _, label in ipairs(labels) do

        local selected = ""
        if snippets[label].selected == true then
            selected = " selected "
        end
        result = result .. [[<option ]] .. selected .. [[ value="]] .. htmlEscape(label) .. [[">]] .. label .. [[</option>]] .. "\n"
    end

    return result
end

-- getCode() -> string
-- Function
-- Gets the selected code value from the JSON file.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The code as as string
local function getCode()
    local snippets = mod.snippets()
    local snippet = getSelectedSnippet()
    return snippets and snippet and snippets[snippet].code or ""
end

-- updatePreferences() -> none
-- Function
-- Updates the Preferences Panel UI.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function updatePreferences()
    mod._manager.injectScript([[changeCheckedByID('commandLineTool', ]] .. tostring(ipc.cliStatus(nil, true)) .. [[);]])
    --------------------------------------------------------------------------------
    -- Sometimes it takes a little while to uninstall the CLI:
    --------------------------------------------------------------------------------
    timer.doAfter(0.5, function()
        mod._manager.injectScript([[changeCheckedByID('commandLineTool', ]] .. tostring(ipc.cliStatus(nil, true)) .. [[);]])
    end)
end

-- toggleCommandLineTool() -> none
-- Function
-- Toggles the Command Line Tool
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function toggleCommandLineTool()
    local cliStatus = ipc.cliStatus()
    if cliStatus then
        ipc.cliUninstall()
    else
        ipc.cliInstall()
    end
    local newCliStatus = ipc.cliStatus()
    if cliStatus == newCliStatus then
        if cliStatus then
            webviewAlert(mod._manager.getWebview(), function()
                updatePreferences()
            end, i18n("cliUninstallError"), "", i18n("ok"), nil, "informational")
        else
            webviewAlert(mod._manager.getWebview(), function()
                updatePreferences()
            end, i18n("cliInstallError"), "", i18n("ok"), nil, "informational")
        end
    else
        updatePreferences()
    end
end

local plugin = {
    id              = "core.preferences.panels.scripting",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"] = "manager",
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps, env)

    --------------------------------------------------------------------------------
    -- Dependancies:
    --------------------------------------------------------------------------------
    mod._manager = deps.manager
    local actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- Setup a global shortcut function for trigger actions:
    --------------------------------------------------------------------------------
    cp.triggerAction = function(handler, action)
        local theHandler = actionmanager.getHandler(handler)
        if theHandler then
            theHandler:execute(action)
        end
    end

    local icon = imageFromPath(config.bundledPluginsPath .. "/core/preferences/panels/images/SEScriptEditorX.icns")

    local panel = deps.manager.addPanel({
        priority    = 2049,
        id          = "scripting",
        label       = i18n("scripting"),
        image       = icon,
        tooltip     = i18n("scripting"),
        height      = 660,
    })

    --------------------------------------------------------------------------------
    -- Command Line Tool:
    --------------------------------------------------------------------------------
    panel
        :addHeading(1, i18n("scriptingTools"))
        :addCheckbox(2,
            {
                label		= i18n("enableCommandLineSupport"),
                checked		= function() return ipc.cliStatus() end,
                onchange	= toggleCommandLineTool,
                id		    = "commandLineTool",
            }
        )

    --------------------------------------------------------------------------------
    -- AppleScript:
    --------------------------------------------------------------------------------
    panel
        :addCheckbox(3,
            {
                label		= i18n("enableAppleScriptSupport"),
                checked		= function() return allowAppleScript() end,
                onchange	= function()
                                local value = allowAppleScript()
                                allowAppleScript(not value)
                            end,
            }
        )

    --------------------------------------------------------------------------------
    -- Learn More Button:
    --------------------------------------------------------------------------------
    panel
        :addContent(4, [[<br />]], false)
        :addButton(5,
            {
                label 	    = "Learn More...",
                width       = 100,
                onclick	    = function() execute("open 'https://help.commandpost.io/advanced/controlling_commandpost'") end,
            }
        )

    --------------------------------------------------------------------------------
    -- Generate HTML for Panel:
    --------------------------------------------------------------------------------
    local e = {}
    e.i18n = i18n
    e.getSnippetLabels = getSnippetLabels
    e.getCode = getCode
    local renderPanel = env:compileTemplate("html/panel.html")
    panel:addContent(100, function() return renderPanel(e) end, false)

    --------------------------------------------------------------------------------
    -- Setup Controller Callback:
    --------------------------------------------------------------------------------
    local controllerCallback = function(_, params)
        if params["type"] == "examples" then
            os.execute('open "http://help.commandpost.io/advanced/snippets"')
        elseif params["type"] == "new" then
            --------------------------------------------------------------------------------
            -- New Snippet:
            --------------------------------------------------------------------------------
            local label = params["label"]
            if label and label ~= "" then
                local snippets = mod.snippets()
                if snippets[label] then
                    local webview = mod._manager._webview
                    if webview then
                        webviewAlert(webview, function() end, i18n("snippetAlreadyExists"), i18n("snippetUniqueName"), i18n("ok"))
                    end
                else
                    for _, v in pairs(snippets) do
                        v.selected = false
                    end
                    snippets[label] = {
                        ["code"] = "",
                        ["selected"] = true,
                    }
                    mod.snippets(snippets)
                    mod._manager.refresh()
                end
            end
        elseif params["type"] == "delete" then
            --------------------------------------------------------------------------------
            -- Delete Snippet:
            --------------------------------------------------------------------------------
            local snippet = params["snippet"]
            if snippet ~= "" then
                webviewAlert(mod._manager._webview, function(result)
                    if result == i18n("yes") then
                        local snippets = mod.snippets()
                        snippets[snippet] = nil
                        mod.snippets(snippets)
                        mod._manager.refresh()
                    end
                end, i18n("deleteSnippetConfirmation"), "", i18n("yes"), i18n("no"))
            end
        elseif params["type"] == "change" then
            --------------------------------------------------------------------------------
            -- Change Snippet via Dropdown Menu:
            --------------------------------------------------------------------------------
            local snippet = params["snippet"]
            if snippet then
                local snippets = mod.snippets()
                for label, _ in pairs(snippets) do
                    if label == snippet then
                        snippets[label].selected = true
                    else
                        snippets[label].selected = false
                    end
                end
                mod.snippets(snippets)
            end
            mod._manager.refresh()
        elseif params["type"] == "update" then
            --------------------------------------------------------------------------------
            -- Updating Code:
            --------------------------------------------------------------------------------
            local code = params["code"]
            local snippet = params["snippet"]
            if code and snippet and snippet ~= "" then
                local snippets = mod.snippets()
                snippets[snippet] = {
                    ["code"] = code,
                    ["selected"] = true
                }
                mod.snippets(snippets)
            end
        elseif params["type"] == "insertAction" then
            --------------------------------------------------------------------------------
            -- Insert Action:
            --------------------------------------------------------------------------------
            actionmanager.getActivator("snippetsAddAction"):onActivate(function(handler, action, _)
                --------------------------------------------------------------------------------
                -- Simplify a table into a single line string:
                --------------------------------------------------------------------------------
                local processTable
                processTable = function(input)
                    local s = "{"
                    for i, v in pairs(input) do
                        --------------------------------------------------------------------------------
                        -- If the key is a number, wrap it in a bracket and quotes:
                        --------------------------------------------------------------------------------
                        local key = i
                        if type(i) == "number" then
                            key = "['" .. i .. "']"
                        end

                        if type(v) == "table" then
                            s = s .. key .. "=" .. processTable(v) .. ","
                        else
                            --------------------------------------------------------------------------------
                            -- If the value contains a slash or quotes put it in brackets:
                            --------------------------------------------------------------------------------
                            local value
                            if v:find("/", 1, true) or v:find([["]], 1, true) or v:find([[\]], 1, true) then
                                value = "[[" .. v .. "]]"
                            else
                                value = [["]] .. v .. [["]]
                            end

                            s = s .. key .. "=" .. value .. ","
                        end
                    end
                    if s:sub(-1) == "," then
                        s = s:sub(1, -2)
                    end
                    s = s .. "}"
                    return s
                end

                local actionString = [[cp.triggerAction("]] .. handler:id()  .. [[",]] .. processTable(action) .. ")"

                --------------------------------------------------------------------------------
                -- URI Encode then Base64 Encode the String to Avoid Non-Standard Character
                -- and JavaScript Escaping Weirdness:
                --------------------------------------------------------------------------------
                local encodedActionString = encode(encodeURI(actionString))
                mod._manager.injectScript("insertTextAtCursor(`" .. encodedActionString .. "`);")
            end):show()
        elseif params["type"] == "execute" then
            --------------------------------------------------------------------------------
            -- Execute Code:
            --------------------------------------------------------------------------------
            local snippet = params["snippet"]
            if snippet and snippet ~= "" then
                local snippets = mod.snippets()
                local code = snippets[snippet].code

                local successful, message = pcall(load(code))
                if not successful then
                    local webview = mod._manager._webview
                    if webview then
                        webviewAlert(webview, function() end, i18n("snippetError"), message, i18n("ok"))
                    end
                end
            else
                local webview = mod._manager._webview
                if webview then
                    webviewAlert(webview, function() end, i18n("noSnippetExists"), "", i18n("ok"))
                end
            end
        end
    end
    deps.manager.addHandler("snippets", controllerCallback)

    --------------------------------------------------------------------------------
    -- Action Handler:
    --------------------------------------------------------------------------------
    mod._handler = actionmanager.addHandler("global_snippets", "global")
        :onChoices(function(choices)
            local snippets = mod.snippets()
            for label, item in pairs(snippets) do
                choices
                    :add(label)
                    :subText(i18n("executeLuaCodeSnippet"))
                    :params({
                        code = item.code,
                        id = label,
                    })
                    :id("global_snippets_" .. label)
                    :image(icon)
            end
        end)
        :onExecute(function(action)
            local snippets = mod.snippets()
            local code = snippets[action.id] and snippets[action.id].code

            --------------------------------------------------------------------------------
            -- This Snippet doesn't exist in the Snippets Preferences, so it must have
            -- been deleted or imported through one of the Control Surface panels.
            -- It will be reimported into the Snippets Preferences.
            --------------------------------------------------------------------------------
            if not code then
                snippets[action.id] = {
                    ["code"] = action.code
                }
                code = action.code
            end

            if code then
                local successful, message = pcall(load(code))
                if not successful then
                    blockAlert(i18n("snippetExecuteError"), message, i18n("ok"))
                end
            end
        end)
        :onActionId(function(params)
            return "global_snippets_" .. params.id
        end)

    return mod
end

return plugin
