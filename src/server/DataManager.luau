-- DataManager.luau
-- DataStore wrapper with session locking.
-- Prevents duplicate saves and concurrent loads across servers.

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

local Constants = require(game.ReplicatedStorage.Shared.Constants)

local DataManager = {}

-- ============================================================
-- DATASTORES
-- ============================================================
local STORE_NAME = "SigmaBrainrotTycoon_v1"
local LOCK_STORE_NAME = "SigmaBrainrotLocks_v1"

local playerDataStore: DataStore
local lockDataStore: DataStore

if not RunService:IsStudio() or true then  -- always attempt, Studio has DataStores enabled
    local ok, err = pcall(function()
        playerDataStore = DataStoreService:GetDataStore(STORE_NAME)
        lockDataStore   = DataStoreService:GetDataStore(LOCK_STORE_NAME)
    end)
    if not ok then
        warn("[DataManager] DataStore init failed:", err)
    end
end

-- ============================================================
-- DEFAULT DATA TEMPLATE
-- ============================================================
local DEFAULT_DATA = {
    Currency        = "0",
    TotalEarned     = "0",
    Generators      = {},       -- { [instanceKey] = OwnedGenerator }
    Brainrots       = {},       -- { "CharacterName", ... }
    PityCounts      = {
        Rare      = 0,
        Epic      = 0,
        Legendary = 0,
        Mythic    = 0,
    },
    ShieldExpiry    = 0,
    RebirthCount    = 0,
    Multiplier      = 1.0,
    LuckBoostExpiry = 0,
    HasAutoCollect  = false,
    HasSigmaAura    = false,
    PlotId          = 0,
    Uncollected     = "0",      -- pending earnings between ticks
}

-- ============================================================
-- IN-MEMORY CACHE
-- ============================================================
-- playerCache[userId] = { data = table, dirty = bool }
local playerCache: { [string]: { data: any, dirty: boolean } } = {}

-- ============================================================
-- HELPERS
-- ============================================================

local function deepCopy(t: any): any
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deepCopy(v)
    end
    return copy
end

local function mergeDefaults(data: any): any
    -- Ensure all keys from DEFAULT_DATA exist
    for key, default in pairs(DEFAULT_DATA) do
        if data[key] == nil then
            data[key] = deepCopy(default)
        end
    end
    -- Ensure PityCounts sub-keys
    for k, v in pairs(DEFAULT_DATA.PityCounts) do
        if data.PityCounts[k] == nil then
            data.PityCounts[k] = v
        end
    end
    return data
end

local function dataKey(userId: number): string
    return "Player_" .. tostring(userId)
end

local function lockKey(userId: number): string
    return "Lock_" .. tostring(userId)
end

-- ============================================================
-- SESSION LOCK
-- ============================================================

--- Attempt to acquire a session lock. Returns true if successful.
local function acquireLock(userId: number): boolean
    if not lockDataStore then return true end  -- no-op in offline mode
    local key = lockKey(userId)
    local now = os.time()
    local success = false

    for attempt = 1, Constants.DATASTORE_MAX_RETRIES do
        local ok, result = pcall(function()
            lockDataStore:UpdateAsync(key, function(existing)
                if existing == nil or (now - existing) > Constants.SESSION_LOCK_TIMEOUT then
                    return now  -- acquire lock
                end
                return nil  -- lock still held
            end)
        end)
        if ok and result ~= nil then
            success = true
            break
        elseif attempt < Constants.DATASTORE_MAX_RETRIES then
            task.wait(Constants.DATASTORE_RETRY_WAIT)
        end
    end

    return success
end

--- Release the session lock.
local function releaseLock(userId: number)
    if not lockDataStore then return end
    local key = lockKey(userId)
    for attempt = 1, Constants.DATASTORE_MAX_RETRIES do
        local ok, err = pcall(function()
            lockDataStore:RemoveAsync(key)
        end)
        if ok then break end
        if attempt < Constants.DATASTORE_MAX_RETRIES then
            task.wait(Constants.DATASTORE_RETRY_WAIT)
        else
            warn("[DataManager] Failed to release lock for", userId, err)
        end
    end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

--- Load a player's profile from DataStore into memory.
---@param player Player
---@return boolean  true if loaded successfully
function DataManager.loadProfile(player: Player): boolean
    local userId = player.UserId
    local key    = dataKey(userId)

    -- Acquire session lock to prevent concurrent loads
    local locked = acquireLock(userId)
    if not locked then
        warn("[DataManager] Could not acquire lock for", player.Name, "— kicking.")
        player:Kick("Could not load your data (server conflict). Please rejoin.")
        return false
    end

    -- Load from DataStore
    local rawData = nil
    for attempt = 1, Constants.DATASTORE_MAX_RETRIES do
        local ok, result = pcall(function()
            rawData = playerDataStore and playerDataStore:GetAsync(key) or nil
        end)
        if ok then break end
        warn("[DataManager] Load attempt", attempt, "failed:", result)
        if attempt < Constants.DATASTORE_MAX_RETRIES then
            task.wait(Constants.DATASTORE_RETRY_WAIT)
        end
    end

    local data = rawData and deepCopy(rawData) or deepCopy(DEFAULT_DATA)
    data = mergeDefaults(data)

    playerCache[tostring(userId)] = { data = data, dirty = false }
    return true
end

--- Save a player's profile back to DataStore and release the lock.
---@param player Player
function DataManager.saveProfile(player: Player)
    local userId = player.UserId
    local cacheEntry = playerCache[tostring(userId)]
    if not cacheEntry then
        warn("[DataManager] No cached data for", player.Name, "on save.")
        return
    end

    local key  = dataKey(userId)
    local data = deepCopy(cacheEntry.data)

    for attempt = 1, Constants.DATASTORE_MAX_RETRIES do
        local ok, err = pcall(function()
            if playerDataStore then
                playerDataStore:SetAsync(key, data)
            end
        end)
        if ok then
            break
        else
            warn("[DataManager] Save attempt", attempt, "failed:", err)
            if attempt < Constants.DATASTORE_MAX_RETRIES then
                task.wait(Constants.DATASTORE_RETRY_WAIT)
            end
        end
    end

    releaseLock(userId)
    playerCache[tostring(userId)] = nil
end

--- Get the in-memory data table for a player.
---@param player Player
---@return table?
function DataManager.getData(player: Player): any?
    local entry = playerCache[tostring(player.UserId)]
    return entry and entry.data or nil
end

--- Update a top-level key in a player's data.
---@param player Player
---@param key string
---@param value any
function DataManager.setData(player: Player, key: string, value: any)
    local entry = playerCache[tostring(player.UserId)]
    if not entry then
        warn("[DataManager] setData called for unloaded player:", player.Name)
        return
    end
    entry.data[key] = value
    entry.dirty = true
end

--- Auto-save all dirty profiles (call periodically from server init).
function DataManager.autoSaveAll()
    for userId, entry in pairs(playerCache) do
        if entry.dirty then
            local player = Players:GetPlayerByUserId(tonumber(userId))
            if player then
                local key = dataKey(tonumber(userId))
                local data = deepCopy(entry.data)
                local ok, err = pcall(function()
                    if playerDataStore then
                        playerDataStore:SetAsync(key, data)
                    end
                end)
                if ok then
                    entry.dirty = false
                else
                    warn("[DataManager] AutoSave failed for", userId, err)
                end
            end
        end
    end
end

--- Check if a player's data is loaded.
function DataManager.isLoaded(player: Player): boolean
    return playerCache[tostring(player.UserId)] ~= nil
end

return DataManager
