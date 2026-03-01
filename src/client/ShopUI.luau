-- ShopUI.luau
-- Generator shop panel: lists all purchasable/upgradeable generators.
-- Fires BuyGenerator remote when a purchase is confirmed.

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")

local GeneratorData     = require(game.ReplicatedStorage.Shared.GeneratorData)
local FormatNumber      = require(game.ReplicatedStorage.Shared.FormatNumber)
local RemoteDefinitions = require(game.ReplicatedStorage.Shared.RemoteDefinitions)

local ShopUI = {}

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local shopFrame: Frame
local screenGui: ScreenGui
local isOpen    = false

-- ============================================================
-- BUILD SHOP UI
-- ============================================================

local function makeButton(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3): TextButton
    local btn = Instance.new("TextButton")
    btn.Size            = size
    btn.Position        = pos
    btn.Text            = text
    btn.TextScaled      = true
    btn.Font            = Enum.Font.GothamBold
    btn.TextColor3      = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Parent          = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent       = btn
    return btn
end

local function wireButtonAnim(button: TextButton)
    local originalSize = button.Size
    local info = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, info, {
            Size = UDim2.new(
                originalSize.X.Scale * 1.05, originalSize.X.Offset * 1.05,
                originalSize.Y.Scale * 1.05, originalSize.Y.Offset * 1.05
            )
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, info, { Size = originalSize }):Play()
    end)
    button.MouseButton1Click:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.05), {
            Size = UDim2.new(
                originalSize.X.Scale * 0.95, originalSize.X.Offset * 0.95,
                originalSize.Y.Scale * 0.95, originalSize.Y.Offset * 0.95
            )
        }):Play()
        task.wait(0.05)
        TweenService:Create(button, info, { Size = originalSize }):Play()
    end)
end

local function buildShopUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name         = "ShopGui"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled      = false
    screenGui.Parent       = playerGui

    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Size            = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent          = screenGui

    -- Main shop panel
    shopFrame = Instance.new("Frame")
    shopFrame.Name            = "ShopFrame"
    shopFrame.Size            = UDim2.new(0, 500, 0, 550)
    shopFrame.Position        = UDim2.new(0.5, -250, 0.5, -275)
    shopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    shopFrame.BorderSizePixel = 0
    shopFrame.Parent          = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent       = shopFrame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size     = UDim2.new(1, -60, 0, 50)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.Text     = "⚡ GENERATOR SHOP"
    title.TextScaled = true
    title.Font     = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(255, 220, 50)
    title.BackgroundTransparency = 1
    title.Parent   = shopFrame

    -- Close button
    local closeBtn = makeButton(
        shopFrame, "✕",
        UDim2.new(0, 40, 0, 40),
        UDim2.new(1, -50, 0, 5),
        Color3.fromRGB(200, 50, 50)
    )
    closeBtn.MouseButton1Click:Connect(function()
        ShopUI.close()
    end)

    -- Scrolling list of generators
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size        = UDim2.new(1, -20, 1, -65)
    scrollFrame.Position    = UDim2.new(0, 10, 0, 60)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    scrollFrame.Parent      = shopFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding      = UDim.new(0, 8)
    listLayout.SortOrder    = Enum.SortOrder.LayoutOrder
    listLayout.Parent       = scrollFrame

    -- Create an entry for each generator
    local buyEvent = RemoteDefinitions.getEvent("BuyGenerator")

    for i, genDef in ipairs(GeneratorData.Generators) do
        local card = Instance.new("Frame")
        card.Size            = UDim2.new(1, -10, 0, 90)
        card.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        card.BorderSizePixel = 0
        card.LayoutOrder     = i
        card.Parent          = scrollFrame

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 10)
        cardCorner.Parent       = card

        -- Generator name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size     = UDim2.new(0.6, 0, 0, 30)
        nameLabel.Position = UDim2.new(0, 10, 0, 5)
        nameLabel.Text     = genDef.Name
        nameLabel.TextScaled = true
        nameLabel.Font     = Enum.Font.GothamBold
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent   = card

        -- Income per tick label
        local incomeLabel = Instance.new("TextLabel")
        incomeLabel.Size     = UDim2.new(0.6, 0, 0, 25)
        incomeLabel.Position = UDim2.new(0, 10, 0, 35)
        incomeLabel.Text     = "+" .. FormatNumber.format(genDef.BaseIncome) .. "/tick"
        incomeLabel.TextScaled = true
        incomeLabel.Font     = Enum.Font.Gotham
        incomeLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
        incomeLabel.BackgroundTransparency = 1
        incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
        incomeLabel.Parent   = card

        -- Description
        local descLabel = Instance.new("TextLabel")
        descLabel.Size     = UDim2.new(0.6, 0, 0, 25)
        descLabel.Position = UDim2.new(0, 10, 0, 60)
        descLabel.Text     = genDef.Description
        descLabel.TextScaled = true
        descLabel.Font     = Enum.Font.Gotham
        descLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
        descLabel.BackgroundTransparency = 1
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent   = card

        -- Buy button
        local buyBtn = makeButton(
            card, "Buy\n" .. FormatNumber.format(genDef.BaseCost),
            UDim2.new(0, 120, 0, 70),
            UDim2.new(1, -130, 0, 10),
            Color3.fromRGB(50, 150, 255)
        )
        wireButtonAnim(buyBtn)

        buyBtn.MouseButton1Click:Connect(function()
            buyEvent:FireServer(genDef.TypeId)
        end)
    end

    -- Update scroll canvas size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, (#GeneratorData.Generators * 98) + 10)
end

-- ============================================================
-- OPEN / CLOSE
-- ============================================================

local openInfo  = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local closeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

function ShopUI.open()
    if isOpen then return end
    isOpen = true
    screenGui.Enabled = true
    shopFrame.Size     = UDim2.new(0, 0, 0, 0)
    shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(shopFrame, openInfo, {
        Size     = UDim2.new(0, 500, 0, 550),
        Position = UDim2.new(0.5, -250, 0.5, -275),
    }):Play()
end

function ShopUI.close()
    if not isOpen then return end
    local tween = TweenService:Create(shopFrame, closeInfo, {
        Size     = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
    })
    tween:Play()
    tween.Completed:Connect(function()
        isOpen = false
        screenGui.Enabled = false
    end)
end

function ShopUI.init()
    buildShopUI()
    print("[ShopUI] Initialized.")
end

return ShopUI
