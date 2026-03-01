-- UIManager.luau
-- Central coordinator for opening/closing UI panels.
-- Ensures only one panel is open at a time.

local UIManager = {}

-- Registry of panels that can be opened/closed
local panels: { [string]: { open: () -> (), close: () -> () } } = {}
local activePanel: string? = nil

--- Register a UI panel with open/close callbacks.
---@param name string
---@param openFn function
---@param closeFn function
function UIManager.register(name: string, openFn: () -> (), closeFn: () -> ())
    panels[name] = { open = openFn, close = closeFn }
end

--- Open a panel by name, closing the currently active one first.
---@param name string
function UIManager.open(name: string)
    if activePanel and activePanel ~= name then
        UIManager.close(activePanel)
    end

    local panel = panels[name]
    if panel then
        panel.open()
        activePanel = name
    else
        warn("[UIManager] Panel not registered:", name)
    end
end

--- Close a panel by name.
---@param name string
function UIManager.close(name: string)
    local panel = panels[name]
    if panel then
        panel.close()
        if activePanel == name then
            activePanel = nil
        end
    end
end

--- Close whichever panel is currently open.
function UIManager.closeActive()
    if activePanel then
        UIManager.close(activePanel)
    end
end

function UIManager.init()
    print("[UIManager] Initialized.")
end

return UIManager
