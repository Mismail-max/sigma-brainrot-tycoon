-- init.client.luau
-- Client bootstrap script.
-- Runs once per player: waits for remotes, initializes all UI modules in order.

-- Wait for the Remotes folder before doing anything
local RemoteDefinitions = require(game.ReplicatedStorage.Shared.RemoteDefinitions)
RemoteDefinitions.waitForFolder()

-- Load client modules in dependency order
local UIManager       = require(script.Parent.UIManager)
local HudUI           = require(script.Parent.HudUI)
local FloatingText    = require(script.Parent.FloatingText)
local GeneratorClient = require(script.Parent.GeneratorClient)
local ShopUI          = require(script.Parent.ShopUI)
local GachaUI         = require(script.Parent.GachaUI)
local LeaderboardUI   = require(script.Parent.LeaderboardUI)
local MobileAdapter   = require(script.Parent.MobileAdapter)

-- Initialize all modules
UIManager.init()
HudUI.init()
FloatingText.init()
GeneratorClient.init()
ShopUI.init()
GachaUI.init()
LeaderboardUI.init()

-- Register panels with UIManager (so only one opens at a time)
UIManager.register("Shop",        ShopUI.open,        ShopUI.close)
UIManager.register("Gacha",       GachaUI.open,       GachaUI.close)
UIManager.register("Leaderboard", LeaderboardUI.open, LeaderboardUI.close)

-- Mobile adapter last (adjusts already-built UIs)
MobileAdapter.init()

-- Listen for steal notifications (shown as a screen notification)
local notifyStealEvent = RemoteDefinitions.getEvent("NotifySteal")
notifyStealEvent.OnClientEvent:Connect(function(message: string)
    -- Show a temporary on-screen notification
    local Players   = game:GetService("Players")
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Reuse existing notification gui or create one
    local notifGui = playerGui:FindFirstChild("NotificationGui")
    if not notifGui then
        notifGui = Instance.new("ScreenGui")
        notifGui.Name         = "NotificationGui"
        notifGui.ResetOnSpawn = false
        notifGui.Parent       = playerGui
    end

    local frame = Instance.new("Frame")
    frame.Size   = UDim2.new(0, 350, 0, 60)
    frame.Position = UDim2.new(0.5, -175, 0, 70)
    frame.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = notifGui

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 10)
    fc.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size     = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Text     = "⚠ " .. message
    label.TextScaled = true
    label.Font     = Enum.Font.GothamBold
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundTransparency = 1
    label.TextWrapped = true
    label.Parent   = frame

    -- Auto-dismiss after 4 seconds
    local TweenService = game:GetService("TweenService")
    task.delay(3, function()
        TweenService:Create(frame, TweenInfo.new(0.5), {
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(label, TweenInfo.new(0.5), {
            TextTransparency = 1,
        }):Play()
        task.wait(0.5)
        frame:Destroy()
    end)
end)

print("[Client] Sigma Brainrot Tycoon — Client initialized successfully!")
