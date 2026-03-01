-- GachaUI.luau
-- Crate opening panel: spin animation → rarity-colored reveal tween.
-- Triggered by the client; result delivered via CrateResult remote.

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")

local MemeData          = require(game.ReplicatedStorage.Shared.MemeData)
local RemoteDefinitions = require(game.ReplicatedStorage.Shared.RemoteDefinitions)

local GachaUI = {}

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui:  ScreenGui
local mainFrame:  Frame
local spinLabel:  TextLabel
local revealFrame: Frame
local rarityLabel: TextLabel
local nameLabel:   TextLabel
local descLabel:   TextLabel
local isOpen = false
local isAnimating = false

-- ============================================================
-- BUILD GACHA UI
-- ============================================================

local function makeLabel(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3, font: Enum.Font?): TextLabel
    local lbl = Instance.new("TextLabel")
    lbl.Size       = size
    lbl.Position   = pos
    lbl.Text       = text
    lbl.TextScaled = true
    lbl.Font       = font or Enum.Font.GothamBold
    lbl.TextColor3 = color
    lbl.BackgroundTransparency = 1
    lbl.Parent     = parent
    return lbl
end

local function buildGachaUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name         = "GachaGui"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled      = false
    screenGui.Parent       = playerGui

    -- Dim overlay
    local overlay = Instance.new("Frame")
    overlay.Size  = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.4
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui

    -- Main crate panel
    mainFrame = Instance.new("Frame")
    mainFrame.Size     = UDim2.new(0, 420, 0, 480)
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -240)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent   = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = mainFrame

    makeLabel(mainFrame, "🎰 OPEN CRATE",
        UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 10),
        Color3.fromRGB(255, 220, 50))

    -- Spin display (shows scrolling character names during animation)
    spinLabel = Instance.new("TextLabel")
    spinLabel.Size     = UDim2.new(0.9, 0, 0, 120)
    spinLabel.Position = UDim2.new(0.05, 0, 0, 70)
    spinLabel.Text     = "???"
    spinLabel.TextScaled = true
    spinLabel.Font     = Enum.Font.GothamBold
    spinLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    spinLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    spinLabel.BorderSizePixel = 0
    spinLabel.Parent   = mainFrame

    local spinCorner = Instance.new("UICorner")
    spinCorner.CornerRadius = UDim.new(0, 12)
    spinCorner.Parent = spinLabel

    -- Reveal frame (hidden until result)
    revealFrame = Instance.new("Frame")
    revealFrame.Size     = UDim2.new(0.9, 0, 0, 220)
    revealFrame.Position = UDim2.new(0.05, 0, 0, 200)
    revealFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    revealFrame.BorderSizePixel = 0
    revealFrame.Visible  = false
    revealFrame.Parent   = mainFrame

    local revealCorner = Instance.new("UICorner")
    revealCorner.CornerRadius = UDim.new(0, 12)
    revealCorner.Parent = revealFrame

    rarityLabel = makeLabel(revealFrame, "COMMON",
        UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 5),
        Color3.fromRGB(180, 180, 180))

    nameLabel = makeLabel(revealFrame, "",
        UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 50),
        Color3.new(1, 1, 1))

    descLabel = makeLabel(revealFrame, "",
        UDim2.new(1, -20, 0, 80), UDim2.new(0, 10, 0, 120),
        Color3.fromRGB(180, 180, 180), Enum.Font.Gotham)
    descLabel.TextScaled = false
    descLabel.TextSize   = 14
    descLabel.TextWrapped = true

    -- NEW badge
    local newBadge = Instance.new("TextLabel")
    newBadge.Name      = "NewBadge"
    newBadge.Size      = UDim2.new(0, 80, 0, 30)
    newBadge.Position  = UDim2.new(1, -90, 0, 5)
    newBadge.Text      = "✨ NEW!"
    newBadge.TextScaled = true
    newBadge.Font      = Enum.Font.GothamBold
    newBadge.TextColor3 = Color3.fromRGB(255, 220, 50)
    newBadge.BackgroundTransparency = 1
    newBadge.Visible   = false
    newBadge.Parent    = revealFrame

    -- Open / Close buttons
    local openBtn = Instance.new("TextButton")
    openBtn.Size   = UDim2.new(0.45, 0, 0, 50)
    openBtn.Position = UDim2.new(0.05, 0, 1, -60)
    openBtn.Text   = "🎲 OPEN ($500)"
    openBtn.TextScaled = true
    openBtn.Font   = Enum.Font.GothamBold
    openBtn.TextColor3 = Color3.new(1,1,1)
    openBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
    openBtn.BorderSizePixel = 0
    openBtn.Parent = mainFrame
    local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0,10); oc.Parent = openBtn

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size   = UDim2.new(0.45, 0, 0, 50)
    closeBtn.Position = UDim2.new(0.5, 0, 1, -60)
    closeBtn.Text   = "✕ CLOSE"
    closeBtn.TextScaled = true
    closeBtn.Font   = Enum.Font.GothamBold
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = mainFrame
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,10); cc.Parent = closeBtn

    -- Wire open button → fire server
    local openCrateEvent = RemoteDefinitions.getEvent("OpenCrate")
    openBtn.MouseButton1Click:Connect(function()
        if not isAnimating then
            openCrateEvent:FireServer("Standard")
            GachaUI.playSpinAnimation()
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        GachaUI.close()
    end)
end

-- ============================================================
-- ANIMATION
-- ============================================================

local allCharNames = {}
do
    for _, char in ipairs(MemeData.Characters) do
        table.insert(allCharNames, char.Name)
    end
end

--- Play spinning animation while waiting for server result.
function GachaUI.playSpinAnimation()
    if isAnimating then return end
    isAnimating = true
    revealFrame.Visible = false
    spinLabel.Visible   = true

    -- Rapid-fire character names
    local spinDuration = 2.5  -- seconds
    local startTime    = os.clock()
    local interval     = 0.08

    task.spawn(function()
        while os.clock() - startTime < spinDuration do
            spinLabel.Text = allCharNames[math.random(1, #allCharNames)]
            task.wait(interval)
            interval = math.min(interval * 1.08, 0.25)  -- slow down
        end
        -- Keep animating until result arrives (isAnimating resets in showResult)
    end)
end

--- Show the result after receiving CrateResult from server.
---@param result table  { Character, Rarity, IsNew }
function GachaUI.showResult(result: any)
    isAnimating = false

    local rarityInfo = MemeData.RarityByName[result.Rarity]
    local color      = rarityInfo and rarityInfo.Color or Color3.fromRGB(180, 180, 180)

    spinLabel.Visible = false
    revealFrame.Visible = true

    rarityLabel.Text      = result.Rarity:upper()
    rarityLabel.TextColor3 = color
    nameLabel.Text        = result.Character.Name
    descLabel.Text        = result.Character.Description

    local newBadge = revealFrame:FindFirstChild("NewBadge")
    if newBadge then
        newBadge.Visible = result.IsNew
    end

    -- Rarity glow tween
    revealFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    local glowTween = TweenService:Create(
        revealFrame,
        TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 2, true),
        { BackgroundColor3 = color }
    )
    glowTween:Play()

    -- Scale bounce on mainFrame
    local bounceInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    mainFrame.Size = UDim2.new(0, 380, 0, 440)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -220)
    TweenService:Create(mainFrame, bounceInfo, {
        Size     = UDim2.new(0, 420, 0, 480),
        Position = UDim2.new(0.5, -210, 0.5, -240),
    }):Play()
end

-- ============================================================
-- OPEN / CLOSE
-- ============================================================

function GachaUI.open()
    if isOpen then return end
    isOpen = true
    revealFrame.Visible = false
    spinLabel.Text      = "???"
    screenGui.Enabled   = true
end

function GachaUI.close()
    if not isOpen then return end
    isOpen      = false
    isAnimating = false
    screenGui.Enabled = false
end

function GachaUI.init()
    buildGachaUI()

    -- Listen for crate results from server
    local crateResultEvent = RemoteDefinitions.getEvent("CrateResult")
    crateResultEvent.OnClientEvent:Connect(function(result: any)
        GachaUI.showResult(result)
    end)

    print("[GachaUI] Initialized.")
end

return GachaUI
