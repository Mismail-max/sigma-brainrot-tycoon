-- init.server.luau
-- Server bootstrap script.
-- Runs first on the server: creates Remotes, loads all managers in order,
-- wires PlayerAdded/PlayerRemoving, and starts the auto-save loop.

local Players           = game:GetService("Players")

-- 1. Create all RemoteEvents/RemoteFunctions first (must exist before clients connect)
local RemoteDefinitions = require(game.ReplicatedStorage.Shared.RemoteDefinitions)
RemoteDefinitions.initServer()
print("[Server] Remotes created.")

-- 2. Load managers in dependency order
local DataManager        = require(script.Parent.DataManager)
local PlotManager        = require(script.Parent.PlotManager)
local GeneratorManager   = require(script.Parent.GeneratorManager)
local GachaManager       = require(script.Parent.GachaManager)
local StealManager       = require(script.Parent.StealManager)
local RebirthManager     = require(script.Parent.RebirthManager)
local LeaderboardManager = require(script.Parent.LeaderboardManager)
local MonetizationManager = require(script.Parent.MonetizationManager)

-- 3. Initialize systems
PlotManager.init()
local PlotVisuals = require(script.Parent.PlotVisuals)
PlotVisuals.init()
GeneratorManager.init()
LeaderboardManager.init()
MonetizationManager.init()

-- 4. Wire all remote event handlers
GeneratorManager.wireRemotes()
GachaManager.wireRemotes()
StealManager.wireRemotes()
RebirthManager.wireRemotes()

-- 5. GetPlotData RemoteFunction
local getPlotDataFn = RemoteDefinitions.getFunction("GetPlotData")
getPlotDataFn.OnServerInvoke = function(player: Player, plotId: number)
    local owner = PlotManager.getPlotOwner(plotId)
    if not owner then return nil end

    local ownerData = DataManager.getData(owner)
    if not ownerData then return nil end

    return {
        OwnerId     = owner.UserId,
        OwnerName   = owner.Name,
        Uncollected = ownerData.Uncollected or "0",
        ShieldActive = (ownerData.ShieldExpiry or 0) > os.time(),
    }
end

-- ============================================================
-- PLAYER LIFECYCLE
-- ============================================================

local function onPlayerAdded(player: Player)
    print("[Server] Player joined:", player.Name)

    -- Load data (blocks until complete or kicks player)
    local loaded = DataManager.loadProfile(player)
    if not loaded then return end

    -- Check gamepass ownership
    MonetizationManager.checkGamepasses(player)

    -- Assign a plot
    PlotManager.assignPlot(player)

    -- Sync initial currency to client
    local data = DataManager.getData(player)
    if data then
        local updateCurrency = RemoteDefinitions.getEvent("UpdateCurrency")
        updateCurrency:FireClient(player, data.Currency or "0")
    end

    print("[Server] Player ready:", player.Name)
end

local function onPlayerRemoving(player: Player)
    print("[Server] Player leaving:", player.Name)

    -- Update leaderboard score before save
    LeaderboardManager.updateScore(player)

    -- Release plot
    PlotManager.releasePlot(player)

    -- Clean up steal cooldowns
    StealManager.cleanupPlayer(player)

    -- Save and release session lock
    DataManager.saveProfile(player)

    print("[Server] Player saved:", player.Name)
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in-game (Studio test with existing session)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end

-- ============================================================
-- AUTO-SAVE LOOP
-- ============================================================
task.spawn(function()
    while true do
        task.wait(60)  -- auto-save every 60 seconds
        DataManager.autoSaveAll()
    end
end)

print("[Server] Sigma Brainrot Tycoon — Server initialized successfully!")
