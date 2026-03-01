-- LeaderboardUI.luau
-- Renders the global top-10 leaderboard panel.
-- Populated by GetLeaderboard RemoteFunction on open.

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")

local FormatNumber      = require(game.ReplicatedStorage.Shared.FormatNumber)
local RemoteDefinitions = require(game.ReplicatedStorage.Shared.RemoteDefinitions)

local LeaderboardUI = {}

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui: ScreenGui
local mainFrame: Frame
local listFrame: ScrollingFrame
local isOpen = false

-- Rank colors for top 3
local RANK_COLORS = {
    [1] = Color3.fromRGB(255, 215, 0),   -- Gold
    [2] = Color3.fromRGB(192, 192, 192), -- Silver
    [3] = Color3.fromRGB(205, 127, 50),  -- Bronze
}

-- ============================================================
-- BUILD UI
-- ============================================================

local function buildLeaderboardUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name         = "LeaderboardGui"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled      = false
    screenGui.Parent       = playerGui

    local overlay = Instance.new("Frame")
    overlay.Size  = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui

    mainFrame = Instance.new("Frame")
    mainFrame.Size     = UDim2.new(0, 400, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -260)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent   = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Size     = UDim2.new(1, -60, 0, 50)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.Text     = "🏆 GLOBAL LEADERBOARD"
    title.TextScaled = true
    title.Font     = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.BackgroundTransparency = 1
    title.Parent   = mainFrame

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size   = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -50, 0, 5)
    closeBtn.Text   = "✕"
    closeBtn.TextScaled = true
    closeBtn.Font   = Enum.Font.GothamBold
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = mainFrame
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,8); cc.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        LeaderboardUI.close()
    end)

    -- Column headers
    local header = Instance.new("Frame")
    header.Size   = UDim2.new(1, -20, 0, 30)
    header.Position = UDim2.new(0, 10, 0, 58)
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(0,6); hc.Parent = header

    local function makeHeaderLabel(text: string, xPos: number, width: number)
        local lbl = Instance.new("TextLabel")
        lbl.Size     = UDim2.new(0, width, 1, 0)
        lbl.Position = UDim2.new(0, xPos, 0, 0)
        lbl.Text     = text
        lbl.TextScaled = true
        lbl.Font     = Enum.Font.GothamBold
        lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
        lbl.BackgroundTransparency = 1
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent   = header
    end
    makeHeaderLabel("RANK", 8, 50)
    makeHeaderLabel("PLAYER", 65, 180)
    makeHeaderLabel("TOTAL EARNED", 255, 130)

    -- Scrolling list
    listFrame = Instance.new("ScrollingFrame")
    listFrame.Size     = UDim2.new(1, -20, 1, -100)
    listFrame.Position = UDim2.new(0, 10, 0, 95)
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 5
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listFrame.Parent   = mainFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding    = UDim.new(0, 4)
    layout.SortOrder  = Enum.SortOrder.LayoutOrder
    layout.Parent     = listFrame
end

-- ============================================================
-- POPULATE
-- ============================================================

local function clearList()
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

local function populateList(entries: any)
    clearList()

    if not entries or #entries == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size     = UDim2.new(1, 0, 0, 50)
        empty.Text     = "No entries yet. Be the first!"
        empty.TextScaled = true
        empty.Font     = Enum.Font.Gotham
        empty.TextColor3 = Color3.fromRGB(150, 150, 150)
        empty.BackgroundTransparency = 1
        empty.Parent   = listFrame
        return
    end

    for i, entry in ipairs(entries) do
        local row = Instance.new("Frame")
        row.Size   = UDim2.new(1, 0, 0, 45)
        row.BackgroundColor3 = i % 2 == 0
            and Color3.fromRGB(25, 25, 38)
            or  Color3.fromRGB(30, 30, 45)
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = listFrame

        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 8)
        rc.Parent = row

        -- Rank
        local rankColor = RANK_COLORS[i] or Color3.fromRGB(200, 200, 200)
        local rankLbl = Instance.new("TextLabel")
        rankLbl.Size   = UDim2.new(0, 50, 1, 0)
        rankLbl.Position = UDim2.new(0, 5, 0, 0)
        rankLbl.Text   = "#" .. tostring(entry.rank)
        rankLbl.TextScaled = true
        rankLbl.Font   = Enum.Font.GothamBold
        rankLbl.TextColor3 = rankColor
        rankLbl.BackgroundTransparency = 1
        rankLbl.Parent = row

        -- Name
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size   = UDim2.new(0, 180, 1, 0)
        nameLbl.Position = UDim2.new(0, 60, 0, 0)
        nameLbl.Text   = tostring(entry.name)
        nameLbl.TextScaled = true
        nameLbl.Font   = Enum.Font.Gotham
        nameLbl.TextColor3 = Color3.new(1, 1, 1)
        nameLbl.BackgroundTransparency = 1
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = row

        -- Score
        local scoreLbl = Instance.new("TextLabel")
        scoreLbl.Size   = UDim2.new(0, 130, 1, 0)
        scoreLbl.Position = UDim2.new(0, 250, 0, 0)
        scoreLbl.Text   = FormatNumber.format(entry.score)
        scoreLbl.TextScaled = true
        scoreLbl.Font   = Enum.Font.GothamBold
        scoreLbl.TextColor3 = Color3.fromRGB(100, 220, 100)
        scoreLbl.BackgroundTransparency = 1
        scoreLbl.TextXAlignment = Enum.TextXAlignment.Left
        scoreLbl.Parent = row
    end

    listFrame.CanvasSize = UDim2.new(0, 0, 0, (#entries * 49))
end

-- ============================================================
-- OPEN / CLOSE
-- ============================================================

function LeaderboardUI.open()
    if isOpen then return end
    isOpen = true
    screenGui.Enabled = true

    -- Fetch fresh data from server
    task.spawn(function()
        local getLeaderboard = RemoteDefinitions.getFunction("GetLeaderboard")
        local ok, result = pcall(function()
            return getLeaderboard:InvokeServer()
        end)
        if ok and result then
            populateList(result)
        else
            populateList({})
        end
    end)
end

function LeaderboardUI.close()
    if not isOpen then return end
    isOpen = false
    screenGui.Enabled = false
end

function LeaderboardUI.init()
    buildLeaderboardUI()

    -- Listen for server-pushed leaderboard updates
    local updateEvent = RemoteDefinitions.getEvent("UpdateLeaderboard")
    updateEvent.OnClientEvent:Connect(function(entries: any)
        if isOpen then
            populateList(entries)
        end
    end)

    print("[LeaderboardUI] Initialized.")
end

return LeaderboardUI
