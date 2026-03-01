-- FloatingText.luau
-- Object pool of BillboardGui instances for "+$X" floating text.
-- Pool size: 30. Each show() borrows, animates, then returns to pool.

local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")

local FloatingText = {}

local POOL_SIZE    = 30
local FLOAT_STUDS  = 10    -- rise distance
local FLOAT_TIME   = 1.5   -- seconds

-- ============================================================
-- POOL SETUP
-- ============================================================

local pool: { { part: Part, gui: BillboardGui, label: TextLabel, inUse: boolean } } = {}

local function createPoolEntry(): any
    -- Invisible anchor part
    local part = Instance.new("Part")
    part.Size       = Vector3.new(0.1, 0.1, 0.1)
    part.Anchored   = true
    part.CanCollide = false
    part.Transparency = 1
    part.Parent     = workspace

    local gui = Instance.new("BillboardGui")
    gui.Size       = UDim2.new(0, 200, 0, 60)
    gui.StudsOffset = Vector3.new(0, 0, 0)
    gui.AlwaysOnTop = false
    gui.Enabled    = false
    gui.Parent     = part

    local label = Instance.new("TextLabel")
    label.Size       = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 220, 50)
    label.TextScaled = true
    label.Font       = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Text       = ""
    label.Parent     = gui

    return { part = part, gui = gui, label = label, inUse = false }
end

local function initPool()
    for i = 1, POOL_SIZE do
        pool[i] = createPoolEntry()
    end
end

local function borrowFromPool(): any?
    for _, entry in ipairs(pool) do
        if not entry.inUse then
            entry.inUse = true
            return entry
        end
    end
    return nil  -- all in use
end

-- ============================================================
-- PUBLIC API
-- ============================================================

--- Show a floating text at a world position.
---@param text string  display text (e.g. "+$1.5K")
---@param position Vector3  world position to appear at
function FloatingText.show(text: string, position: Vector3)
    local entry = borrowFromPool()
    if not entry then return end  -- pool exhausted, skip silently

    local part  = entry.part
    local gui   = entry.gui
    local label = entry.label

    -- Reset state
    part.Position = position + Vector3.new(0, 2, 0)
    label.Text    = text
    label.TextTransparency = 0
    gui.Enabled   = true

    -- Tween: rise + fade
    local moveTween = TweenService:Create(
        part,
        TweenInfo.new(FLOAT_TIME, Enum.EasingStyle.Linear),
        { Position = position + Vector3.new(0, 2 + FLOAT_STUDS, 0) }
    )
    local fadeTween = TweenService:Create(
        label,
        TweenInfo.new(FLOAT_TIME * 0.6, Enum.EasingStyle.Linear, Enum.EasingDirection.In,
                      0, false, FLOAT_TIME * 0.4),
        { TextTransparency = 1 }
    )

    moveTween:Play()
    fadeTween:Play()

    -- Return to pool after animation
    moveTween.Completed:Connect(function()
        gui.Enabled = false
        entry.inUse = false
    end)
end

function FloatingText.init()
    initPool()

    -- Listen for server-fired floating text events
    local RemoteDefinitions = require(game.ReplicatedStorage.Shared.RemoteDefinitions)
    local showEvent = RemoteDefinitions.getEvent("ShowFloatingText")

    showEvent.OnClientEvent:Connect(function(text: string, position: Vector3)
        FloatingText.show(text, position)
    end)

    print("[FloatingText] Pool of", POOL_SIZE, "initialized.")
end

return FloatingText
