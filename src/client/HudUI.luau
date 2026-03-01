-- HudUI.luau
-- Always-visible HUD: currency display and Collect button.
-- Receives UpdateCurrency events from the server to stay in sync.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")

local RemoteDefinitions = require(game.ReplicatedStorage.Shared.RemoteDefinitions)
local FormatNumber      = require(game.ReplicatedStorage.Shared.FormatNumber)

local HudUI = {}

-- ============================================================
-- BUILD UI
-- ============================================================

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")

local screenGui: ScreenGui
local currencyLabel: TextLabel
local collectButton: TextButton
local uncollectedLabel: TextLabel
local shieldIndicator: Frame

local function buildHud()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name           = "HudGui"
    screenGui.ResetOnSpawn   = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent         = playerGui

    -- ── Currency bar (top centre) ──────────────────────────
    local topBar = Instance.new("Frame")
    topBar.Name            = "TopBar"
    topBar.Size            = UDim2.new(0.4, 0, 0, 50)
    topBar.Position        = UDim2.new(0.3, 0, 0, 10)
    topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    topBar.BackgroundTransparency = 0.3
    topBar.BorderSizePixel = 0
    topBar.Parent          = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent       = topBar

    local coinIcon = Instance.new("TextLabel")
    coinIcon.Size     = UDim2.new(0, 40, 1, 0)
    coinIcon.Position = UDim2.new(0, 5, 0, 0)
    coinIcon.Text     = "💰"
    coinIcon.TextScaled = true
    coinIcon.BackgroundTransparency = 1
    coinIcon.Parent   = topBar

    currencyLabel = Instance.new("TextLabel")
    currencyLabel.Name      = "CurrencyLabel"
    currencyLabel.Size      = UDim2.new(1, -50, 1, 0)
    currencyLabel.Position  = UDim2.new(0, 45, 0, 0)
    currencyLabel.Text      = "$0"
    currencyLabel.TextScaled = true
    currencyLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
    currencyLabel.Font      = Enum.Font.GothamBold
    currencyLabel.BackgroundTransparency = 1
    currencyLabel.TextXAlignment = Enum.TextXAlignment.Left
    currencyLabel.Parent    = topBar

    -- ── Uncollected earnings label ─────────────────────────
    uncollectedLabel = Instance.new("TextLabel")
    uncollectedLabel.Name      = "UncollectedLabel"
    uncollectedLabel.Size      = UDim2.new(0.3, 0, 0, 30)
    uncollectedLabel.Position  = UDim2.new(0.35, 0, 0, 65)
    uncollectedLabel.Text      = "Uncollected: $0"
    uncollectedLabel.TextScaled = true
    uncollectedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    uncollectedLabel.Font      = Enum.Font.Gotham
    uncollectedLabel.BackgroundTransparency = 1
    uncollectedLabel.Parent    = screenGui

    -- ── Collect button (bottom centre) ────────────────────
    collectButton = Instance.new("TextButton")
    collectButton.Name            = "CollectButton"
    collectButton.Size            = UDim2.new(0, 200, 0, 60)
    collectButton.Position        = UDim2.new(0.5, -100, 1, -80)
    collectButton.Text            = "COLLECT"
    collectButton.TextScaled      = true
    collectButton.Font            = Enum.Font.GothamBold
    collectButton.TextColor3      = Color3.new(1, 1, 1)
    collectButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
    collectButton.BorderSizePixel = 0
    collectButton.Parent          = screenGui

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 12)
    btnCorner.Parent       = collectButton

    -- ── Shield indicator (top right) ──────────────────────
    shieldIndicator = Instance.new("Frame")
    shieldIndicator.Name            = "ShieldIndicator"
    shieldIndicator.Size            = UDim2.new(0, 120, 0, 40)
    shieldIndicator.Position        = UDim2.new(1, -130, 0, 10)
    shieldIndicator.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    shieldIndicator.BackgroundTransparency = 0.3
    shieldIndicator.BorderSizePixel = 0
    shieldIndicator.Visible         = false
    shieldIndicator.Parent          = screenGui

    local shieldCorner = Instance.new("UICorner")
    shieldCorner.CornerRadius = UDim.new(0, 8)
    shieldCorner.Parent       = shieldIndicator

    local shieldLabel = Instance.new("TextLabel")
    shieldLabel.Size       = UDim2.new(1, 0, 1, 0)
    shieldLabel.Text       = "🛡 SHIELDED"
    shieldLabel.TextScaled = true
    shieldLabel.TextColor3 = Color3.new(1, 1, 1)
    shieldLabel.Font       = Enum.Font.GothamBold
    shieldLabel.BackgroundTransparency = 1
    shieldLabel.Parent     = shieldIndicator
end

-- ============================================================
-- BUTTON ANIMATIONS (reusable pattern)
-- ============================================================

local function wireButtonAnimations(button: TextButton)
    local originalSize = button.Size
    local hoverInfo = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    button.MouseEnter:Connect(function()
        TweenService:Create(button, hoverInfo, {
            Size = UDim2.new(
                originalSize.X.Scale * 1.1, originalSize.X.Offset * 1.1,
                originalSize.Y.Scale * 1.1, originalSize.Y.Offset * 1.1
            )
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, hoverInfo, { Size = originalSize }):Play()
    end)

    button.MouseButton1Click:Connect(function()
        local shrinkInfo = TweenInfo.new(0.05)
        TweenService:Create(button, shrinkInfo, {
            Size = UDim2.new(
                originalSize.X.Scale * 0.95, originalSize.X.Offset * 0.95,
                originalSize.Y.Scale * 0.95, originalSize.Y.Offset * 0.95
            )
        }):Play()
        task.wait(0.05)
        TweenService:Create(button, hoverInfo, { Size = originalSize }):Play()
    end)
end

-- ============================================================
-- PUBLIC API
-- ============================================================

--- Update the displayed currency.
---@param currencyStr string  BigNum digit string
function HudUI.setCurrency(currencyStr: string)
    if currencyLabel then
        currencyLabel.Text = FormatNumber.format(currencyStr)
    end
end

--- Update the uncollected display.
---@param uncollectedStr string
function HudUI.setUncollected(uncollectedStr: string)
    if uncollectedLabel then
        uncollectedLabel.Text = "Uncollected: " .. FormatNumber.format(uncollectedStr)
    end
end

--- Show or hide the shield indicator.
---@param active boolean
function HudUI.setShieldActive(active: boolean)
    if shieldIndicator then
        shieldIndicator.Visible = active
    end
end

function HudUI.init()
    buildHud()
    wireButtonAnimations(collectButton)

    -- Wire collect button
    local collectEvent = RemoteDefinitions.getEvent("CollectEarnings")
    collectButton.MouseButton1Click:Connect(function()
        collectEvent:FireServer()
    end)

    -- Listen for currency updates from server
    local updateCurrencyEvent = RemoteDefinitions.getEvent("UpdateCurrency")
    updateCurrencyEvent.OnClientEvent:Connect(function(currencyStr: string)
        HudUI.setCurrency(currencyStr)
    end)

    -- Listen for shield status updates
    local shieldEvent = RemoteDefinitions.getEvent("ShieldStatusChanged")
    shieldEvent.OnClientEvent:Connect(function(info: any)
        if info and info.active then
            HudUI.setShieldActive(true)
            -- Auto-hide when shield expires
            local remaining = (info.expiry or 0) - os.time()
            if remaining > 0 then
                task.delay(remaining, function()
                    HudUI.setShieldActive(false)
                end)
            end
        else
            HudUI.setShieldActive(false)
        end
    end)

    print("[HudUI] Initialized.")
end

return HudUI
