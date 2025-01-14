--- === plugins.finalcutpro.touchbar.widgets.duration ===
---
--- Final Cut Pro Browser Duration Control Widget for Touch Bar.

local require           = require

--local log               = require "hs.logger" .new "duration"

local canvas            = require "hs.canvas"

local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"

local mod = {}

--- plugins.finalcutpro.touchbar.widgets.duration.widget() -> `hs._asm.undocumented.touchbar.item`
--- Function
--- The Widget
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.undocumented.touchbar.item`
function mod.widget()

    local canvasWidth, canvasHeight = 250, 30

    local widgetCanvas = canvas.new{x = 0, y = 0, h = 30, w = canvasWidth}

    widgetCanvas[#widgetCanvas + 1] = {
        id               = "background",
        type             = "rectangle",
        action           = "strokeAndFill",
        strokeColor      = { white = 1 },
        fillColor        = { hex = "#1d1d1d", alpha = 1 },
        roundedRectRadii = { xRadius = 5, yRadius = 5 },
    }

    widgetCanvas[#widgetCanvas + 1] = {
        id                  = "startLine",
        type                = "segments",
        coordinates         = {
            {x = 0, y = canvasHeight/2},
            {x = canvasWidth / 2, y = canvasHeight/2} },
        action              = "stroke",
        strokeColor         = { hex = "#5051e7", alpha = 1 },
        strokeWidth         = 1.5,
    }

    widgetCanvas[#widgetCanvas + 1] = {
        id                  = "endLine",
        type                = "segments",
        coordinates         = {
            {x = canvasWidth / 2, y = canvasHeight/2},
            {x = canvasWidth, y = canvasHeight/2} },
        action              = "stroke",
        strokeColor         = { white = 1.0 },
        strokeWidth         = 1.5,
    }

    widgetCanvas[#widgetCanvas + 1] = {
        id                  = "circle",
        type                = "circle",
        radius              = 10,
        action              = "strokeAndFill",
        fillColor           = { hex = "#414141", alpha = 1 },
        strokeWidth         = 1.5,
        center              = { x = canvasWidth / 2, y = canvasHeight / 2 },
    }

    widgetCanvas:canvasMouseEvents(true, true, false, true)
        :mouseCallback(function(_,m,_,x,_)

            if not fcp.isFrontmost() or not fcp.libraries:isShowing() then return end

            widgetCanvas.circle.center = {
                x = x,
                y = canvasHeight / 2,
            }

            widgetCanvas.startLine.coordinates = {
                {x = 0, y = canvasHeight/2},
                {x = x, y = canvasHeight/2},
            }

            widgetCanvas.endLine.coordinates = {
                { x = x, y = canvasHeight / 2 },
                { x = canvasWidth, y = canvasHeight / 2 },
            }

            if m == "mouseDown" or m == "mouseMove" then
                fcp.libraries.appearanceAndFiltering:show().duration:setValue(x/(canvasWidth/11))
            elseif m == "mouseUp" then
                fcp.libraries.appearanceAndFiltering:hide()
            end
    end)

    mod.item = mod._manager.touchbar().item.newCanvas(widgetCanvas, "browserDurationSlider")
        :canvasClickColor{ alpha = 0.0 }

    return mod.item

end

--- plugins.finalcutpro.touchbar.widgets.duration.init() -> nil
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(manager)
    mod._manager = manager

    local params = {
        group = "fcpx",
        text = i18n("browserDurationSlider"),
        subText = i18n("browserDurationSliderDescription"),
        item = mod.widget,
    }
    manager.widgets:new("browserDurationSlider", params)

    return mod

end


local plugin = {
    id              = "finalcutpro.touchbar.widgets.duration",
    group           = "finalcutpro",
    dependencies    = {
        ["core.touchbar.manager"] = "manager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local manager = deps.manager
    if manager.supported() then
        return mod.init(manager)
    end
end

return plugin
