--- === cp.apple.finalcutpro.main.LibrariesList ===
---
--- Libraries List Module.

local require               = require

--local log                   = require "hs.logger".new "LibrariesList"

local axutils               = require "cp.ui.axutils"
local SplitGroup            = require "cp.ui.SplitGroup"
local Table                 = require "cp.ui.OldTable"

local Clip                  = require "cp.apple.finalcutpro.content.Clip"
local Playhead              = require "cp.apple.finalcutpro.main.Playhead"
local Columns               = require "cp.apple.finalcutpro.browser.Columns"

local moses                 = require "moses"

local filter                = moses.filter
local map                   = moses.map

local cache                 = axutils.cache
local childFromTop          = axutils.childFromTop
local childrenMatching      = axutils.childrenMatching
local childWithRole         = axutils.childWithRole
local isValid               = axutils.isValid

local LibrariesList = SplitGroup:subclass("cp.apple.finalcutpro.main.LibrariesList")

--- cp.apple.finalcutpro.main.CommandEditor.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function LibrariesList.static.matches(element)
    return SplitGroup.matches(element)
end

--- cp.apple.finalcutpro.main.LibrariesList(app) -> LibrariesList
--- Constructor
--- Creates a new `LibrariesList` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `LibrariesList` object.
function LibrariesList:initialize(parent)
    local UI = parent.mainGroupUI:mutate(function(original)
        return cache(self, "_ui", function()
            local main = original()
            if main then
                for _,child in ipairs(main) do
                    if child:attributeValue("AXRole") == "AXGroup" and #child == 1 then
                        if LibrariesList.matches(child[1]) then
                            return child[1]
                        end
                    end
                end
            end
            return nil
        end, LibrariesList.matches)
    end)

    SplitGroup.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.main.LibrariesList.playerUI <cp.prop: hs.axuielement; read-only>
--- Field
--- The `axuielement` for the player section of the Libraries List UI.
function LibrariesList.lazy.prop:playerUI()
    return self.UI:mutate(function(original)
        return cache(self, "_player", function()
            return childFromTop(original(), 1)
        end)
    end)
end

--- cp.apple.finalcutpro.main.LibrariesList.isShowing <cp.prop: boolean; read-only>
--- Field
--- Checks if the Libraries List is showing on screen.
function LibrariesList.lazy.prop:isShowing()
    return self:parent().isShowing:AND(self.UI:ISNOT(nil))
end

--- cp.apple.finalcutpro.main.LibrariesList.isFocused <cp.prop: boolean; read-only>
--- Field
--- Checks if the Libraries List is currently focused within FCPX.
function LibrariesList.lazy.prop:isFocused()
    return self.contents.isFocused:OR(self.playerUI:mutate(function(original)
        local ui = original()
        return ui ~= nil and ui:attributeValue("AXFocused") == true
    end))
end

--- cp.apple.finalcutpro.main.LibrariesList:columns() -> Columns
--- Method
--- Gets the List View Columns object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Columns` object.
function LibrariesList:columns()
    return Columns(self)
end

-----------------------------------------------------------------------
--
-- UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.LibrariesList:show() -> LibrariesList
--- Method
--- Show the Libraries List.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `LibrariesList` object
function LibrariesList:show()
    if not self:isShowing() and self:parent():show():isShowing() then
        self:parent():toggleViewMode()
    end
end

-----------------------------------------------------------------------
--
-- PREVIEW PLAYER:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.LibrariesList.playhead <Playhead>
--- Field
--- The Libraries List Playhead.
function LibrariesList.lazy.value:playhead()
    return Playhead(self, false, self.playerUI, true)
end

--- cp.apple.finalcutpro.main.LibrariesList.skimmingPlayhead <Playhead>
--- Field
--- the Libraries List Skimming Playhead.
function LibrariesList.lazy.value:skimmingPlayhead()
    return Playhead(self, true, self.playerUI, true)
end

-----------------------------------------------------------------------
--
-- LIBRARY CONTENT:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.LibrariesList.contents <cp.ui.OldTable>
--- Field
--- The Libraries List Contents UI.
function LibrariesList.lazy.value:contents()
    return Table(self, function()
        return childWithRole(self:UI(), "AXScrollArea")
    end)
end

--- cp.apple.finalcutpro.main.LibrariesList:clipsUI(filterFn) -> table | nil
--- Function
--- Gets clip UIs using a custom filter.
---
--- Parameters:
---  * filterFn - A function to filter the UI results.
---
--- Returns:
---  * A table of `axuielementObject` objects or `nil` if no clip UI could be found.
function LibrariesList:clipsUI(filterFn)
    local rowsUI = self.contents:rowsUI()
    if rowsUI then
        local level = 0
        -- if the first row has no icon, it's a group
        local firstCell = self.contents:findCellUI(1, "filmlist name col")
        if firstCell and childWithRole(firstCell, "AXImage") == nil then
            level = 1
        end
        return childrenMatching(rowsUI, function(row)
            return row:attributeValue("AXDisclosureLevel") == level
               and (filterFn == nil or filterFn(row))
        end)
    end
    return nil
end

-- cp.apple.finalcutpro.main.LibrariesList:uiToClips(clipsUI) -> none
-- Function
-- Converts a table of `axuielementObject` objects to `Clip` objects.
--
-- Parameters:
--  * clipsUI - Table of `axuielementObject` objects.
--
-- Returns:
--  * A table of `Clip` objects.
function LibrariesList:_uiToClips(clipsUI)
    --------------------------------------------------------------------------------
    -- NOTE: At some point the column with "filmlist name col" disappeared, probably
    --       when custom columns were added so we now just return 1.
    --------------------------------------------------------------------------------
    local columnIndex = self.contents:findColumnIndex("filmlist name col") or 1
    local options = {columnIndex = columnIndex}
    return map(clipsUI, function(clipUI)
        return Clip.new(clipUI, options)
    end)
end

-- _clipsToUI(clips) -> none
-- Function
-- Converts a table of `Clip` objects to `axuielementObject` objects.
--
-- Parameters:
--  * clips - Table of `Clip` objects
--
-- Returns:
--  * A table of `axuielementObject` objects.
local function _clipsToUI(clips)
    return map(clips, function(clip) return clip:UI() end)
end

--- cp.apple.finalcutpro.main.LibrariesList:clips(filterFn) -> table | nil
--- Function
--- Gets clips using a custom filter.
---
--- Parameters:
---  * filterFn - A function to filter the UI results.
---
--- Returns:
---  * A table of `Clip` objects or `nil` if no clip UI could be found.
function LibrariesList:clips(filterFn)
    local clips = self:_uiToClips(self:clipsUI())
    if filterFn then
        clips = filter(clips, function(_,clip) return filterFn(clip) end)
    end
    return clips

end

--- cp.apple.finalcutpro.main.LibrariesList:selectedClipsUI() -> table | nil
--- Function
--- Gets selected clips UI's.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of `axuielementObject` objects or `nil` if no clips are selected.
function LibrariesList:selectedClipsUI()
    return self.contents:selectedRowsUI()
end

--- cp.apple.finalcutpro.main.LibrariesList:selectedClips() -> table | nil
--- Function
--- Gets selected clips.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of `Clip` objects or `nil` if no clips are selected.
function LibrariesList:selectedClips()
    return self:_uiToClips(self.contents:selectedRowsUI())
end

--- cp.apple.finalcutpro.main.LibrariesList:showClip(clip) -> boolean
--- Function
--- Shows a clip.
---
--- Parameters:
---  * clip - The `Clip` you want to show.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesList:showClip(clip)
    if clip then
        local clipUI = clip:UI()
        if isValid(clipUI) then
            self.contents:showRow(clipUI)
            return true
        end
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesList:selectClip(clip) -> boolean
--- Function
--- Selects a clip.
---
--- Parameters:
---  * clip - The `Clip` you want to select.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesList:selectClip(clip)
    if clip then
        local clipUI = clip:UI()
        if isValid(clipUI) then
            self.contents:selectRow(clip:UI())
            return true
        end
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesList:selectClipAt(index) -> boolean
--- Function
--- Select clip at a specific index.
---
--- Parameters:
---  * index - A number of where the clip appears in the list.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesList:selectClipAt(index)
    local clips = self:clipsUI()
    if clips and #clips >= index then
        self.contents:selectRow(clips[index])
        return true
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesList:indexOfClip(clip) -> number | nil
--- Function
--- Gets the index of a specific clip.
---
--- Parameters:
---  * clip - The `Clip` you want to get the index of.
---
--- Returns:
---  * The index or `nil` if an error occurs.
function LibrariesList:indexOfClip(clip)
    local clips = self:clipsUI()
    local ui = clip and clip:UI()
    if clips and ui then
        for i, v in pairs(clips) do
            if ui == v then
                return i
            end
        end
    end
end

--- cp.apple.finalcutpro.main.LibrariesList:selectClipTitled(title) -> boolean
--- Function
--- Select clip with a specific title.
---
--- Parameters:
---  * title - The title of a clip.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesList:selectClipTitled(title)
    local clips = self:clips()
    for _,clip in ipairs(clips) do
        if clip:getTitle() == title then
            return self:selectClip(clip)
        end
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesList:selectAll([clips]) -> boolean
--- Function
--- Select all clips.
---
--- Parameters:
---  * clips - A optional table of `Clip` objects.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesList:selectAll(clips)
    clips = clips or self:clips()
    if clips then
        self.contents:selectAll(_clipsToUI(clips))
        return true
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesList:deselectAll() -> boolean
--- Function
--- Deselect all clips.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesList:deselectAll(clips)
    clips = clips or self:clips()
    if clips then
        self.contents:deselectAll(_clipsToUI(clips))
        return true
    end
    return false
end

return LibrariesList
