-- MobileAdapter.luau
-- Detects touch devices and adjusts UI sizes for mobile play.
-- Must run after all UI modules have initialized.

local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")

local MobileAdapter = {}

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Scale factor applied to absolute-size buttons on mobile
local MOBILE_SCALE = 1.5

-- ============================================================
-- SCALE HELPERS
-- ============================================================

--- Recursively scale all TextButton and ImageButton sizes in a GUI.
---@param instance Instance
---@param factor number
local function scaleButtons(instance: Instance, factor: number)
    for _, child in ipairs(instance:GetDescendants()) do
        if child:IsA("TextButton") or child:IsA("ImageButton") then
            local size = child.Size
            -- Only scale offset-based sizes (not Scale-based ones, which adapt automatically)
            if size.X.Scale == 0 and size.Y.Scale == 0 then
                child.Size = UDim2.new(
                    0, size.X.Offset * factor,
                    0, size.Y.Offset * factor
                )
            end
        end
        -- Increase font sizes for readability
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            if not child.TextScaled then
                child.TextSize = math.floor(child.TextSize * factor)
            end
        end
    end
end

--- Scale a specific ScreenGui.
---@param guiName string
local function scaleGui(guiName: string)
    local gui = playerGui:FindFirstChild(guiName)
    if gui then
        scaleButtons(gui, MOBILE_SCALE)
    end
end

-- ============================================================
-- MOBILE HUD ADJUSTMENTS
-- ============================================================

--- Reposition/resize the HUD elements for mobile (thumb-friendly).
local function adjustHudForMobile()
    local hudGui = playerGui:WaitForChild("HudGui", 5) :: ScreenGui
    if not hudGui then return end

    -- Move collect button higher so it's above virtual thumbstick area
    local collectBtn = hudGui:FindFirstChild("CollectButton", true)
    if collectBtn then
        collectBtn.Position = UDim2.new(0.5, -110, 1, -140)
        collectBtn.Size     = UDim2.new(0, 220, 0, 70)
    end

    -- Make currency bar taller
    local topBar = hudGui:FindFirstChild("TopBar", true)
    if topBar then
        topBar.Size = UDim2.new(0.6, 0, 0, 60)
        topBar.Position = UDim2.new(0.2, 0, 0, 8)
    end
end

-- ============================================================
-- GACHA BUTTON (mobile shortcut)
-- ============================================================

--- Add a floating gacha button for mobile users.
local function addMobileGachaButton()
    local hudGui = playerGui:WaitForChild("HudGui", 5)
    if not hudGui then return end

    local gachaBtn = Instance.new("TextButton")
    gachaBtn.Name   = "MobileGachaBtn"
    gachaBtn.Size   = UDim2.new(0, 80, 0, 80)
    gachaBtn.Position = UDim2.new(0, 10, 1, -100)
    gachaBtn.Text   = "🎰"
    gachaBtn.TextScaled = true
    gachaBtn.Font   = Enum.Font.GothamBold
    gachaBtn.TextColor3 = Color3.new(1, 1, 1)
    gachaBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    gachaBtn.BorderSizePixel = 0
    gachaBtn.Parent = hudGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 40)  -- circle
    corner.Parent = gachaBtn

    gachaBtn.MouseButton1Click:Connect(function()
        local GachaUI = require(script.Parent.GachaUI)
        GachaUI.open()
    end)

    -- Leaderboard button
    local lbBtn = Instance.new("TextButton")
    lbBtn.Name   = "MobileLbBtn"
    lbBtn.Size   = UDim2.new(0, 80, 0, 80)
    lbBtn.Position = UDim2.new(0, 100, 1, -100)
    lbBtn.Text   = "🏆"
    lbBtn.TextScaled = true
    lbBtn.Font   = Enum.Font.GothamBold
    lbBtn.TextColor3 = Color3.new(1, 1, 1)
    lbBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
    lbBtn.BorderSizePixel = 0
    lbBtn.Parent = hudGui

    local lbCorner = Instance.new("UICorner")
    lbCorner.CornerRadius = UDim.new(0, 40)
    lbCorner.Parent = lbBtn

    lbBtn.MouseButton1Click:Connect(function()
        local LeaderboardUI = require(script.Parent.LeaderboardUI)
        LeaderboardUI.open()
    end)
end

-- ============================================================
-- INIT
-- ============================================================

function MobileAdapter.init()
    local isMobile = UserInputService.TouchEnabled
        and not UserInputService.KeyboardEnabled

    if isMobile then
        print("[MobileAdapter] Mobile device detected — scaling UI.")

        -- Wait a frame for UIs to finish building
        task.wait(0.2)

        adjustHudForMobile()
        addMobileGachaButton()

        -- Scale shop and gacha panels
        scaleGui("ShopGui")
        scaleGui("GachaGui")
        scaleGui("LeaderboardGui")
    else
        -- Desktop: add convenience buttons in the HUD
        local hudGui = playerGui:WaitForChild("HudGui", 5)
        if hudGui then
            -- Shop button
            local shopBtn = Instance.new("TextButton")
            shopBtn.Name   = "ShopButton"
            shopBtn.Size   = UDim2.new(0, 100, 0, 40)
            shopBtn.Position = UDim2.new(0, 10, 0.5, -20)
            shopBtn.Text   = "🛒 SHOP"
            shopBtn.TextScaled = true
            shopBtn.Font   = Enum.Font.GothamBold
            shopBtn.TextColor3 = Color3.new(1, 1, 1)
            shopBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
            shopBtn.BorderSizePixel = 0
            shopBtn.Parent = hudGui
            local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0,8); sc.Parent = shopBtn

            shopBtn.MouseButton1Click:Connect(function()
                local ShopUI = require(script.Parent.ShopUI)
                ShopUI.open()
            end)

            -- Gacha button
            local gachaBtn = Instance.new("TextButton")
            gachaBtn.Name   = "GachaButton"
            gachaBtn.Size   = UDim2.new(0, 100, 0, 40)
            gachaBtn.Position = UDim2.new(0, 10, 0.5, 30)
            gachaBtn.Text   = "🎰 GACHA"
            gachaBtn.TextScaled = true
            gachaBtn.Font   = Enum.Font.GothamBold
            gachaBtn.TextColor3 = Color3.new(1, 1, 1)
            gachaBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
            gachaBtn.BorderSizePixel = 0
            gachaBtn.Parent = hudGui
            local gc = Instance.new("UICorner"); gc.CornerRadius = UDim.new(0,8); gc.Parent = gachaBtn

            gachaBtn.MouseButton1Click:Connect(function()
                local GachaUI = require(script.Parent.GachaUI)
                GachaUI.open()
            end)

            -- Leaderboard button
            local lbBtn = Instance.new("TextButton")
            lbBtn.Name   = "LeaderboardButton"
            lbBtn.Size   = UDim2.new(0, 100, 0, 40)
            lbBtn.Position = UDim2.new(0, 10, 0.5, 80)
            lbBtn.Text   = "🏆 RANKS"
            lbBtn.TextScaled = true
            lbBtn.Font   = Enum.Font.GothamBold
            lbBtn.TextColor3 = Color3.new(1, 1, 1)
            lbBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
            lbBtn.BorderSizePixel = 0
            lbBtn.Parent = hudGui
            local lbc = Instance.new("UICorner"); lbc.CornerRadius = UDim.new(0,8); lbc.Parent = lbBtn

            lbBtn.MouseButton1Click:Connect(function()
                local LeaderboardUI = require(script.Parent.LeaderboardUI)
                LeaderboardUI.open()
            end)

            -- Steal button (for testing, in a real game this would appear over plots)
            local rebirthBtn = Instance.new("TextButton")
            rebirthBtn.Name   = "RebirthButton"
            rebirthBtn.Size   = UDim2.new(0, 100, 0, 40)
            rebirthBtn.Position = UDim2.new(0, 10, 0.5, 130)
            rebirthBtn.Text   = "⭐ REBIRTH"
            rebirthBtn.TextScaled = true
            rebirthBtn.Font   = Enum.Font.GothamBold
            rebirthBtn.TextColor3 = Color3.new(1, 1, 1)
            rebirthBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
            rebirthBtn.BorderSizePixel = 0
            rebirthBtn.Parent = hudGui
            local rbc = Instance.new("UICorner"); rbc.CornerRadius = UDim.new(0,8); rbc.Parent = rebirthBtn

            local RemoteDefinitions = require(game.ReplicatedStorage.Shared.RemoteDefinitions)
            rebirthBtn.MouseButton1Click:Connect(function()
                local rebirthEvent = RemoteDefinitions.getEvent("RequestRebirth")
                rebirthEvent:FireServer()
            end)
        end
    end

    print("[MobileAdapter] Initialized. Mobile:", tostring(isMobile))
end

return MobileAdapter
