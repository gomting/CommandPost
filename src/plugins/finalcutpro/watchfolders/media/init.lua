--- === plugins.finalcutpro.watchfolders.media ===
---
--- Final Cut Pro Media Watch Folder Plugin.

local require           = require

--local log               = require "hs.logger".new "WatchFolderMedia"

local config            = require "cp.config"
local fcp               = require "cp.apple.finalcutpro"

local MediaFolder       = require "MediaFolder"
local panel             = require "panel"

local insert            = table.insert

local mod = {}

-- The storage for the media folders.
local savedMediaFolders = config.prop("fcp.watchFolders.mediaFolders", {})

--- plugins.finalcutpro.watchfolders.media.mediaFolders -> table
--- Variable
--- The table of MediaFolders currently configured.
local mediaFolders = nil

--- plugins.finalcutpro.watchfolders.media.addMediaFolder(path, videoTag, audioTag, imageTag) -> none
--- Function
--- Removes a media folder.
---
--- Parameters:
---  * path - The path of the folder to remove.
---  * videoTag - An optional video tag as a string.
---  * audioTag - An optional audio tag as a string.
---  * imageTag - An optional image tag as a string.
---
--- Returns:
---  * None
function mod.addMediaFolder(path, videoTag, audioTag, imageTag)
    insert(mediaFolders, MediaFolder.new(mod, path, videoTag, audioTag, imageTag):init())
    mod.saveMediaFolders()
end

--- plugins.finalcutpro.watchfolders.media.removeMediaFolder(path) -> boolean
--- Function
--- Removes a media folder.
---
--- Parameters:
---  * path - The path of the folder to remove.
---
--- Returns:
---  * None
function mod.removeMediaFolder(path)
    for i,f in ipairs(mediaFolders) do
        if f.path == path then
            f:destroy()
            table.remove(mediaFolders, i)
            mod.saveMediaFolders()
            break
        end
    end
end

--- plugins.finalcutpro.watchfolders.media.hasMediaFolder(path) -> boolean
--- Function
--- Checks to see if a path has a media folder already saved.
---
--- Parameters:
---  * path - The path to check.
---
--- Returns:
---  * A boolean
function mod.hasMediaFolder(path)
    for _,folder in ipairs(mediaFolders) do
        if folder.path == path then
            return true
        end
    end
end

--- plugins.finalcutpro.watchfolders.media.mediaFolders() -> table
--- Function
--- Gets a table of all the media folders.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of all the media folders.
function mod.mediaFolders()
    return mediaFolders
end

--- plugins.finalcutpro.watchfolders.media.saveMediaFolders()
--- Function
--- Saves the current state of the media folders, including notifications, etc.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Nothing
function mod.saveMediaFolders()
    local details = {}
    for _,folder in ipairs(mediaFolders) do
        insert(details, folder:freeze())
    end
    savedMediaFolders(details)
end

--- plugins.finalcutpro.watchfolders.media.loadMediaFolders()
--- Function
--- Loads the MediaFolder list from storage. Any existing MediaFolder instances
--- will be destroyed before loading.
function mod.loadMediaFolders()
    if mediaFolders then
        for _,folder in ipairs(mediaFolders) do
            folder:destroy()
        end
    end

    local details = savedMediaFolders()
    -- delete any existing ones.
    mediaFolders = {}
    for _,frozen in ipairs(details) do
        insert(mediaFolders, MediaFolder.thaw(mod, frozen):init())
    end
end

--- plugins.finalcutpro.watchfolders.media.SECONDS_UNTIL_DELETE -> number
--- Constant
--- Seconds until a file is deleted.
mod.SECONDS_UNTIL_DELETE = 30

--- plugins.finalcutpro.watchfolders.media.automaticallyImport <cp.prop: boolean>
--- Variable
--- Boolean that sets whether or not new generated voice file are automatically added to the timeline or not.
mod.automaticallyImport = config.prop("fcp.watchFolders.automaticallyImport", false)

--- plugins.finalcutpro.watchfolders.media.insertIntoTimeline <cp.prop: boolean>
--- Variable
--- Boolean that sets whether or not the files are automatically added to the timeline or not.
mod.insertIntoTimeline = config.prop("fcp.watchFolders.insertIntoTimeline", true)

--- plugins.finalcutpro.watchfolders.media.deleteAfterImport <cp.prop: boolean>
--- Variable
--- Boolean that sets whether or not you want to delete file after they've been imported.
mod.deleteAfterImport = config.prop("fcp.watchFolders.deleteAfterImport", false)

--- plugins.finalcutpro.watchfolders.media.init(deps, env) -> table
--- Function
--- Initialises the module.
---
--- Parameters:
---  * deps - The dependencies environment
---  * env - The plugin environment
---
--- Returns:
---  * Table of the module.
function mod.init(deps)
    --------------------------------------------------------------------------------
    -- Ignore Panel if Final Cut Pro isn't installed.
    --------------------------------------------------------------------------------
    fcp.isSupported:watch(function(installed)
        --------------------------------------------------------------------------------
        -- Setup Watchers:
        --------------------------------------------------------------------------------
        mod.loadMediaFolders()

        if installed then
            panel.init(mod, deps.panelManager)
        end
    end, true)

    --------------------------------------------------------------------------------
    -- Define Plugins:
    --------------------------------------------------------------------------------
    mod.pasteboardManager = deps.pasteboardManager

    return mod
end

local plugin = {
    id = "finalcutpro.watchfolders.media",
    group = "finalcutpro",
    dependencies = {
        ["core.watchfolders.manager"]		= "panelManager",
        ["finalcutpro.pasteboard.manager"]	= "pasteboardManager",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    return mod.init(deps, env)
end

return plugin
