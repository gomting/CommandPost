--- === cp.ui.GridElement ===
---
--- Abstract base class for `AX` elements which form a grid, such as [GridElement](cp.ui.GridElement.md) and [Outline](cp.ui.Outline.md).

local require                   = require
-- local log                       = require "hs.logger" .new "GridElement"

local LazyList                  = require "cp.collect.LazyList"
local fn                        = require "cp.fn"
local ax                        = require "cp.fn.ax"
local prop	                    = require "cp.prop"
local Element	                = require "cp.ui.Element"

local class                     = require "middleclass"

local chain                     = fn.chain
local get                       = fn.table.get

local Do                        = require "cp.rx.go.Do"

local GridElement = Element:subclass("cp.ui.GridElement")
    :defineBuilder("withHeaderOf", "withRowsOf", "withColumnsOf")

-----------------------------------------------------------------------
-- GridElement.Builder Methods, created by `defineBuilder`.
-----------------------------------------------------------------------

--- === cp.ui.GridElement.Builder ===
---
--- A `Builder` for `GridElement`s.

--- cp.ui.GridElement.Builder:withHeaderOf(headerInit) -> cp.ui.GridElement.Builder
--- Method
--- Adds a `Header` initializer to the `GridElement` builder.
---
--- Parameters:
---  * headerInit - A `Header` initializer.
---
--- Returns:
---  * The `GridElement` builder.

--- cp.ui.GridElement.Builder:withRowsOf(rowInit) -> cp.ui.GridElement.Builder
--- Method
--- Adds a `Row` initializer to the `GridElement` builder.
---
--- Parameters:
---  * rowInit - A `Row` initializer.
---
--- Returns:
---  * The `GridElement` builder.

--- cp.ui.GridElement.Builder:withColumnsOf(columnInit) -> cp.ui.GridElement.Builder
--- Method
--- Adds a `Column` initializer to the `GridElement` builder.
---
--- Parameters:
---  * columnInit - A `Column` initializer.
---
--- Returns:
---  * The `GridElement` builder.

-----------------------------------------------------------------------
-- GridElement
-----------------------------------------------------------------------

--- cp.ui.GridElement:withHeaderOf(headerInit) -> cp.ui.GridElement.Builder
--- Function
--- Returns a new `Builder` for `GridElement`s with the specified `headerInit`.
---
--- Parameters:
---  * headerInit - A `Header` initializer.
---
--- Returns:
---  * A new `Builder` for `GridElement`s.

--- cp.ui.GridElement:withRowsOf(rowInit) -> cp.ui.GridElement.Builder
--- Function
--- Returns a new `Builder` for `GridElement`s with the specified `rowInit`.
---
--- Parameters:
---  * rowInit - A `Row` initializer.
---
--- Returns:
---  * A new `Builder` for `GridElement`s.

--- cp.ui.GridElement:withColumnsOf(columnInit) -> cp.ui.GridElement.Builder
--- Function
--- Returns a new `Builder` for `GridElement`s with the specified `columnInit`.
---
--- Parameters:
---  * columnInit - A `Column` initializer.
---
--- Returns:
---  * A new `Builder` for `GridElement`s.

--- cp.ui.GridElement.matches(element) -> boolean
--- Function
--- Checks if the `element` is an `GridElement`.
---
--- Parameters:
---  * element - An element to check
---
--- Returns:
---  * A boolean
GridElement.static.matches = ax.matchesIf(
    -- it's an Element
    Element.matches,
    -- it has either rows or columns
    fn.any(
        ax.attribute "AXRows",
        ax.attribute "AXColumns"
    )
)

--- cp.ui.GridElement:withRowsOf(...) -> function(parent, uiFinder) -> GridElement
--- Function
--- A combinator that returns a function expecting a `parent` and `uiFinder` and returns a `GridElement` instance, with
--- the arguments defining the [Cell](cp.ui.Cell.md.html) instances that make up the rows of the table.
---
--- Parameters:
---  * ... - One or more arguments to pass to the constructor.
---
--- Returns:
---  * A function that will return a new `GridElement` instance.
function GridElement.static:withRowsOf(...)
    local factory = GridElement.OfRows(...)
    return function(parent, uiFinder)
        return self(parent, uiFinder, factory)
    end
end

--- cp.ui.GridElement(parent, uiFinder, headerInit, rowInit, columnInit) -> cp.ui.GridElement
--- Constructor
--- Creates a new `GridElement` instance.
---
--- Parameters:
---  * parent - The parent `Element` instance.
---  * uiFinder - A `hs.uielement` or `axuielementObject` that will be used to find this element.
---  * headerInit - An initializer function that will be called to create the header `Element` instance.
---  * rowInit - An initializer function that will be called to create each row element.
---  * columnInit - An initializer function that will be called to create each column element.
---
--- Returns:
---  * A new `GridElement` instance.
---
--- Notes:
---  * The `headerType`, `rowType` arguments are optional.
function GridElement:initialize(parent, uiFinder, headerInit, rowInit, columnInit)
    Element.initialize(self, parent, uiFinder)
    self._headerInit = headerInit or Element
    self._rowInit = rowInit or Element
    self._columnInit = columnInit or Element
end

--- cp.ui.GridElement.headerUI <cp.prop: axuielement; read-only; live>
--- Field
--- Returns the header UI element.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The header UI element.
function GridElement.lazy.prop:headerUI()
    return ax.prop(self.UI, "AXHeader")
end

--- cp.ui.GridElement.header <cp.ui.Element>
--- Field
--- The `Element` representing the `AXHeader` of the `GridElement`.
function GridElement.lazy.value:header()
    return self._headerInit(self, self.headerUI)
end

--- cp.ui.GridElement.rowsUI <cp.prop: table of axuielement; live?; read-only>
--- Field
--- The list of `Row`s which are children of this `GridElement`.
function GridElement.lazy.prop:rowsUI()
    return ax.prop(self.UI, "AXRows")
end

--- cp.ui.GridElement.firstRow <cp.ui.Element>
--- Field
--- An `Element` of the `rowInit` type that will always point at the first row (if available).
function GridElement.lazy.value:firstRow()
    return self._rowInit(self, self.rowsUI:mutate(function(original)
        local rows = original()
        if rows then
            return rows[1]
        end
    end))
end

--- cp.ui.GridElement.lastRow <cp.ui.Element>
--- Field
--- An `Element` of the `rowInit` type that will always point at the last row (if available).
function GridElement.lazy.value:lastRow()
    return self._rowInit(self, self.rowsUI:mutate(function(original)
        local rows = original()
        if rows then
            return rows[#rows]
        end
    end))
end

--- cp.ui.GridElement:row(index) -> cp.ui.Element | nil
--- Method
--- Returns an `Element` at the specified `index`.
---
--- Parameters:
---  * index - The index of the `Element` to return.
---
--- Returns:
---  * The `Element` at the specified `index`.
function GridElement:row(index)
    return self._rowInit(self, self.rowsUI:mutate(function(original)
        local rows = original()
        if rows then
            return rows[index]
        end
    end))
end

--- cp.ui.GridElement.selectedRowsUI <cp.prop: table of cp.ui.Row; live?>
--- Field
--- The list of `Row`s which are selected in this `GridElement`.
function GridElement.lazy.prop:selectedRowsUI()
    return ax.prop(self.UI, "AXSelectedRows", true)
end



--- cp.ui.GridElement.selectedRows <table of cp.ui.Row; live?; read-only>
--- Field
--- The list of `Row`s which are selected in this `GridElement`.
function GridElement.lazy.value:selectedRows()
    return self._factory:createRows(self, self.selectedRowsUI)
end

--- cp.ui.GridElement.visibleRowsUI <cp.prop: table of cp.ui.Row; live?; read-only>
--- Field
--- The list of `Row`s which are visible in this `GridElement`.
function GridElement.lazy.prop:visibleRowsUI()
    return ax.prop(self.UI, "AXVisibleRows")
end

--- cp.ui.GridElement.visibleRows <table of cp.ui.Row; live?; read-only>
--- Field
--- The list of `Row`s which are visible in this `GridElement`.
function GridElement.lazy.value:visibleRows()
    return self._factory:createRows(self, self.visibleRowsUI)
end

--- cp.ui.GridElement.columnsUI <cp.prop: table of axuielement; live?; read-only>
--- Field
--- The list of `axuielement`s which are children of this `GridElement`.
function GridElement.lazy.prop:columnsUI()
    return ax.prop(self.UI, "AXColumns")
end

--- cp.ui.GridElement.columns <table of cp.ui.Column; live?; read-only>
--- Field
--- The list of `Column`s which are children of this `GridElement`.
function GridElement.lazy.value:columns()
    return self._factory:createColumns(self, self.columnsUI)
end

--- cp.ui.GridElement.selectedColumnsUI <cp.prop: table of axuielement; live?>
--- Field
--- The list of `axuielement` `AXColumn`s which are selected in this `GridElement`.
function GridElement.lazy.prop:selectedColumnsUI()
    return ax.prop(self.UI, "AXSelectedColumns", true)
end

--- cp.ui.GridElement.selectedColumns <table of cp.ui.Column; live?; read-only>
--- Field
--- The list of `Column`s which are selected in this `GridElement`.
function GridElement.lazy.value:selectedColumns()
    return self._factory:createColumns(self, self.selectedColumnsUI)
end

--- cp.ui.GridElement.visibleColumnsUI <cp.prop: table of axuielement; live?; read-only>
--- Field
--- The list of `Column`s which are visible in this `GridElement`.
function GridElement.lazy.prop:visibleColumnsUI()
    return ax.prop(self.UI, "AXVisibleColumns")
end

--- cp.ui.GridElement.visibleColumns <table of cp.ui.Column; live?; read-only>
--- Field
--- The list of `Column`s which are visible in this `GridElement`.
function GridElement.lazy.value:visibleColumns()
    return self._factory:createColumns(self, self.visibleColumnsUI)
end

--- cp.ui.GridElement:fetchColumn(columnUI) -> cp.ui.Column or nil
--- Method
--- Returns the [Column](cp.ui.Column.md) that represents the provided `columnUI`, if it is actually present.
---
--- Parameters:
---  * columnUI - The `axuielement` for the `AXColumn` to find a [Column](cp.ui.Column.md) for.
---
--- Returns:
---  * The [Column](cp.ui.Column.md), or `nil` if the `columnUI` is not available.
function GridElement:fetchColumn(columnUI)
    return self._columnCache:fetchElement(columnUI)
end

--- cp.ui.GridElement:fetchColumn(columnsUI) -> table of cp.ui.Columns
--- Method
--- Returns a `table` of the same length as `columnsUI`.
--- If provided items in the table are not valid columns in this table, then `nil` will be put in the matching index.
--- Note that this will break the standard `#`/looping behaviour for tables at that point.
---
--- Parameters:
---  * columnsUI - The list of `AXColumn` `axuielement`s to find.
---
--- Returns:
---  * A `table` with the same number of elements, containing the matching [Column](cp.ui.Column.md) instances.
function GridElement:fetchColumns(columnsUI)
    return self._columnCache:fetchElements(columnsUI)
end

local function walkRows(rows, path, actionFn)
    if rows then
        local name = table.remove(path, 1)
        for _,row in ipairs(rows) do
            local cells = row:cells()
            local cell = cells and cells[1]
            if cell and cell:valueIs(name) then
                if #path > 0 then
                    row:discloseRow()
                    return walkRows(row:disclosedRows(), path, actionFn)
                else
                    actionFn(row)
                    return row
                end
            end
        end
    end
    return nil
end

--- cp.ui.GridElement:visitRow(path, actionFn) -> cp.ui.Row
--- Method
--- Visits the row at the sub-level named in the `names` table, and executes the `actionFn`.
---
--- Parameters:
---  * `names`		- The array of names to navigate down
---  * `actionFn`	- A function to execute when the target row is found.
---
--- Returns:
---  * The row that was visited, or `nil` if not.
function GridElement:visitRow(path, actionFn)
    return walkRows(self.rows, path, actionFn)
end

--- cp.ui.GridElement:findColumnIndex(id) -> number | nil
--- Method
--- Finds the Column Index based on an `AXIdentifier` ID.
---
--- Parameters:
---  * id - The `AXIdentifier` of the column index you want to find.
---
--- Returns:
---  * A column index as a number, or `nil` if no index can be found.
function GridElement:findColumnIndex(id)
    local cols = self:columns()
    if cols then
        for i=1,#cols do
            if cols[i]:identifier() == id then
                return i
            end
        end
    end
    return nil
end

--- cp.ui.GridElement:findCell(rowNumber, columnId) -> `hs.axuielement` | nil
--- Method
--- Finds a specific [Cell](cp.ui.Cell.md).
---
--- Parameters:
---  * rowNumber - The row number.
---  * columnId - The Column ID.
---
--- Returns:
---  * A `hs.axuielement` object for the cell, or `nil` if the cell cannot be found.
function GridElement:findCell(rowNumber, columnId)
    local rows = self:rows()
    if rows and rowNumber >= 1 and rowNumber < #rows then
        local colNumber = self:findColumnIndex(columnId)
        return colNumber and rows[rowNumber]:cells()[colNumber]
    end
    return nil
end

--- cp.ui.GridElement:selectRows(rows) -> nil
--- Method
--- Attempts to select the provided list of `cp.ui.Row`s.
---
--- Parameters:
---  * rows - The list of `cp.ui.Row`s to select.
---
--- Returns:
---  * `nil`
function GridElement:selectRows(rows)
    -- build a list of axuielements for the provided rows
    local rowsUI = {}
    for _,row in ipairs(rows) do
        -- check it's a supported row type
        if not self._rowInit:isTypeOf(row) then
            error("Unsupported row type: " .. tostring(row))
        end
        local rowUI = row:UI()
        if self._rowInit.matches(rowUI) then
            table.insert(rowsUI, rowUI)
        end
    end
    -- select the rows
    self:selectedRowsUI(rowsUI)
end

--- cp.ui.GridElement:selectRow(row) -> nil
--- Method
--- Attempts to select the provided `cp.ui.Row`.
---
--- Parameters:
---  * row - The `cp.ui.Row` to select.
---
--- Returns:
---  * `nil`
function GridElement:selectRow(row)
    -- check it's a supported row type
    if not self._rowInit:isTypeOf(row) then
        error("Unsupported row type: " .. tostring(row))
    end
    -- select the row
    self:selectedRowsUI({row:UI()})
end

--- cp.ui.GridElement:selectRowAt(path) -> cp.ui.Row
--- Method
--- Selects the row at the sub-level named in the `path` table.
---
--- Parameters:
---  * path - A `table` of names to navigate through to find the [Row](cp.ui.Row.md) to select.
---
--- Returns:
---  * The selected [Row](cp.ui.Row.md), or `nil` if not found.
function GridElement:selectRowAt(path)
    return self:visitRow(path, function(row) row:selected(true) end)
end

--- cp.ui.GridElement:doSelectRow(path) -> [Statement](cp.rx.go.Statement.md)
--- Method
--- Selects the row at the sub-level named in the `path` table.
---
--- Parameters:
---  * path - A `table` of names to navigate through to find the [Row](cp.ui.Row.md) to select.
---
--- Returns:
---  * The selected [Row](cp.ui.Row.md), or `nil` if not found.
function GridElement:doSelectRowAt(path)
    return Do(function()
        return self:visitRow(path, function(row) row:selected(true) end)
    end)
end

-- === cp.ui.GridElement.Factory ===
--
-- A factory for processing `GridElement` contents, such as [Rows](cp.ui.Row.md) and [Columns](cp.ui.Column.md).
GridElement.Factory = class("cp.ui.GridElement.Factory")

-- GridElement.Factory:createRow(tbl, rowFinder) -> cp.ui.Row
-- Function
-- Creates a new `Row` instance.
--
-- Parameters:
--  * tbl - The `GridElement` instance.
--  * row - A callable that will return the `axuielementObject` for the row.
--
-- Returns:
--  * The new `Row` instance.
function GridElement.Factory.createRow(_, _)
    error("Unimplemented", 2)
end

-- cp.ui.GridElement.Factory:createRows(tableUI) -> table of cp.ui.Row
-- Function
-- Creates the rows for the `GridElement`.
--
-- Parameters:
--  * tableUI - The `axuielementObject` for the `GridElement`.
--
-- Returns:
--  * A table of `Row`s.
function GridElement.Factory.createRows(_)
    error("Unimplemented", 2)
end

--- === cp.ui.GridElement.OfRows === ---
---
--- Processes the contents of the GridElement as a list of rows.
--- Each of the defined `Element` initialisers will be used to create a cell within each `Row`.
GridElement.OfRows = GridElement.Factory:subclass("cp.ui.GridElement.OfRows")

--- cp.ui.GridElement.OfRows(...) -> cp.ui.GridElement.OfRows
--- Constructor
--- Creates a new `GridElement.OfRows` instance.
---
--- Parameters:
---  * ... - The `Cell` initialisers.
---
--- Returns:
---  * A new `GridElement.OfRows` instance.
function GridElement.OfRows:initialize(...)
    self._cellInitialisers = {...}
end

--- cp.ui.GridElement.OfRows:createRow(tbl, rowFinder) -> cp.ui.Row
--- Method
--- Creates a new `Row` instance.
---
--- Parameters:
---  * tbl - The `GridElement` instance.
---  * rowFinder - a callable that will return the `axuielementObject` for the row.
---
--- Returns:
---  * The new `Row` instance.
function GridElement.OfRows:createRow(tbl, rowFinder)
    return tbl._rowInit(tbl, rowFinder, self._cellInitialisers)
end

--- cp.ui.GridElement.OfRows:createRows(tbl, rowsFinder) -> table of cp.ui.Row
--- Method
--- Creates the [Row](cp.ui.Row.md)s for the `GridElement`.
---
--- Parameters:
---  * tbl - The `GridElement` instance
---  * rowsFinder - a callable that will return the a table of `cp.ui.Row` values.
---
--- Returns:
---  * A table of `Row`s.
function GridElement.OfRows:createRows(tbl, rowsFinder)
    local rowsProp = prop.FROM(rowsFinder)

    return LazyList(
        function()
            local rowsUI = rowsProp()
            return rowsUI and #rowsUI or 0
        end,
        function(index)
            return self:createRow(
                tbl,
                rowsProp:mutate(chain // ax.uielementList >> get(index))
            )
        end
    )
end

return GridElement