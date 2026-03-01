-- LeaderboardManager.luau
-- Maintains a global OrderedDataStore leaderboard.
-- Updates every 60 seconds. Provides GetLeaderboard RemoteFunction.

local DataStoreService  = game:GetService("DataStoreService")
local Players           = game:GetService("Players")

local DataManager       = require(script.Parent.DataManager)
local Constants         = require(game.ReplicatedStorage.Shared.Constants)
local RemoteDefinitions = require(game.ReplicatedStorage.Shared.RemoteDefinitions)

local LeaderboardManager = {}

-- ============================================================
-- ORDERED DATASTORE
-- ============================================================
local orderedStore: OrderedDataStore
local ok, err = pcall(function()
    orderedStore = DataStoreService:GetOrderedDataStore("SigmaLeaderboard_v1")
end)
if not ok then
    warn("[LeaderboardManager] OrderedDataStore init failed:", err)
end

-- In-memory cache of top entries
local cachedLeaderboard: { { rank: number, name: string, score: number } } = {}

-- ============================================================
-- HELPERS
-- ============================================================

--- Update a single player's score in the OrderedDataStore.
---@param player Player
local function updatePlayerScore(player: Player)
    if not orderedStore then return end

    local data = DataManager.getData(player)
    if not data then return end

    local totalEarned = tonumber(data.TotalEarned) or 0
    -- Clamp to safe integer range for OrderedDataStore
    local score = math.floor(math.min(totalEarned, Constants.LEADERBOARD_MAX_SCORE))

    local scoreOk, scoreErr = pcall(function()
        orderedStore:SetAsync(tostring(player.UserId), score)
    end)
    if not scoreOk then
        warn("[LeaderboardManager] Failed to update score for", player.Name, scoreErr)
    end
end

--- Fetch the top N entries from the OrderedDataStore.
local function fetchTopPlayers()
    if not orderedStore then return end

    local fetchOk, pages = pcall(function()
        return orderedStore:GetSortedAsync(false, Constants.LEADERBOARD_TOP_COUNT)
    end)
    if not fetchOk then
        warn("[LeaderboardManager] Failed to fetch leaderboard:", pages)
        return
    end

    local entries = pages:GetCurrentPage()
    local newBoard = {}
    for rank, entry in ipairs(entries) do
        -- Try to get display name
        local displayName = entry.key
        local nameOk, name = pcall(function()
            return Players:GetNameFromUserIdAsync(tonumber(entry.key))
        end)
        if nameOk and name then
            displayName = name
        end

        table.insert(newBoard, {
            rank  = rank,
            name  = displayName,
            score = entry.value,
        })
    end
    cachedLeaderboard = newBoard
end

-- ============================================================
-- PUBLIC API
-- ============================================================

--- Get the cached leaderboard entries.
---@return table
function LeaderboardManager.getTopPlayers(): any
    return cachedLeaderboard
end

-- ============================================================
-- INIT
-- ============================================================

function LeaderboardManager.init()
    -- Periodic update loop
    task.spawn(function()
        while true do
            task.wait(Constants.LEADERBOARD_UPDATE_INTERVAL)

            -- Update scores for all online players
            for _, player in ipairs(Players:GetPlayers()) do
                if DataManager.isLoaded(player) then
                    updatePlayerScore(player)
                end
            end

            -- Fetch fresh leaderboard
            fetchTopPlayers()

            -- Broadcast updated leaderboard to all clients
            local updateEvent = RemoteDefinitions.getEvent("UpdateLeaderboard")
            updateEvent:FireAllClients(cachedLeaderboard)
        end
    end)

    -- GetLeaderboard RemoteFunction
    local getLeaderboardFn = RemoteDefinitions.getFunction("GetLeaderboard")
    getLeaderboardFn.OnServerInvoke = function(player: Player)
        return cachedLeaderboard
    end

    -- Initial fetch
    fetchTopPlayers()

    print("[LeaderboardManager] Leaderboard initialized.")
end

--- Update a single player's score immediately (e.g. on leave).
---@param player Player
function LeaderboardManager.updateScore(player: Player)
    updatePlayerScore(player)
end

return LeaderboardManager
