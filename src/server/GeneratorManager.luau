-- GeneratorManager.luau
-- Centralized Heartbeat income engine.
-- ONE RunService.Heartbeat loop ticks ALL generators every TICK_INTERVAL seconds.
-- Accumulates uncollected earnings; fires ShowFloatingText to clients.

local RunService         = game:GetService("RunService")
local Players            = game:GetService("Players")

local DataManager        = require(script.Parent.DataManager)
local PlotManager        = require(script.Parent.PlotManager)
local BigNum             = require(game.ReplicatedStorage.Shared.BigNum)
local GeneratorData      = require(game.ReplicatedStorage.Shared.GeneratorData)
local Constants          = require(game.ReplicatedStorage.Shared.Constants)
local RemoteDefinitions  = require(game.ReplicatedStorage.Shared.RemoteDefinitions)
local FormatNumber       = require(game.ReplicatedStorage.Shared.FormatNumber)

local GeneratorManager = {}

-- ============================================================
-- INTERNAL STATE
-- ============================================================
local accumulatedTime = 0
local showFloatingText: RemoteEvent
local updateCurrency: RemoteEvent

-- ============================================================
-- HELPERS
-- ============================================================

--- Apply all active multipliers to an income BigNum.
---@param player Player
---@param income BigNum
---@return BigNum
local function applyMultipliers(player: Player, income: BigNum): any
    local data = DataManager.getData(player)
    if not data then return income end

    local mult = data.Multiplier or 1.0

    -- Sigma Aura gamepass bonus
    if data.HasSigmaAura then
        mult = mult * Constants.GAMEPASSES.SigmaAura.Multiplier
    end

    if mult <= 1.0 then return income end

    return income:mul(mult)
end

--- Tick all generators for one player, accumulate uncollected, fire float text.
---@param player Player
local function tickPlayer(player: Player)
    local data = DataManager.getData(player)
    if not data then return end

    local generators = data.Generators
    if not generators or next(generators) == nil then return end

    local tickIncome = BigNum.new("0")

    for instanceKey, genData in pairs(generators) do
        -- Compute income at current level
        local incomeStr = GeneratorData.getIncomeAtLevel(genData.TypeId, genData.Level or 1)
        local income    = BigNum.new(incomeStr)
        tickIncome      = tickIncome:add(income)
    end

    -- Apply multipliers
    tickIncome = applyMultipliers(player, tickIncome)

    -- Auto-collect for gamepass holders — add directly to currency
    if data.HasAutoCollect then
        local currency = BigNum.new(data.Currency or "0")
        local newCurrency = currency:add(tickIncome)
        DataManager.setData(player, "Currency", newCurrency:tostring())

        -- Also update TotalEarned
        local totalEarned = BigNum.new(data.TotalEarned or "0")
        DataManager.setData(player, "TotalEarned", totalEarned:add(tickIncome):tostring())

        -- Fire currency update
        if updateCurrency then
            updateCurrency:FireClient(player, newCurrency:tostring())
        end
    else
        -- Add to uncollected pool
        local uncollected = BigNum.new(data.Uncollected or "0")
        local newUncollected = uncollected:add(tickIncome)
        DataManager.setData(player, "Uncollected", newUncollected:tostring())
    end

    -- Fire floating text to the player
    if showFloatingText and tickIncome:gt(BigNum.zero()) then
        local plotId = data.PlotId
        local plotModel = PlotManager.getPlotModel(plotId)
        local spawnPart = plotModel and plotModel:FindFirstChild("SpawnArea") :: BasePart
        local position = spawnPart and spawnPart.Position or Vector3.new(0, 5, 0)

        showFloatingText:FireClient(
            player,
            "+" .. FormatNumber.format(tickIncome),
            position
        )
    end
end

-- ============================================================
-- BUY GENERATOR (server-authoritative)
-- ============================================================

--- Process a generator purchase request.
---@param player Player
---@param typeId string
---@return boolean success, string message
function GeneratorManager.buyGenerator(player: Player, typeId: string): (boolean, string)
    local data = DataManager.getData(player)
    if not data then return false, "Data not loaded." end

    local genDef = GeneratorData.ByTypeId[typeId]
    if not genDef then return false, "Unknown generator type." end

    -- Check if player already owns this generator type (for now, one per type)
    -- Generate a unique instance key
    local instanceKey = typeId .. "_" .. os.time()
    -- If they own one already, this becomes an upgrade — find existing key
    local existingKey = nil
    for key, gen in pairs(data.Generators) do
        if gen.TypeId == typeId then
            existingKey = key
            break
        end
    end

    local cost: string
    local level: number

    if existingKey then
        -- Upgrade
        level = (data.Generators[existingKey].Level or 1) + 1
        cost  = GeneratorData.getUpgradeCost(typeId, data.Generators[existingKey].Level or 1)
        instanceKey = existingKey
    else
        -- First purchase
        level = 1
        cost  = genDef.BaseCost
    end

    -- Validate currency
    local currency = BigNum.new(data.Currency or "0")
    local costBN   = BigNum.new(cost)
    if not currency:gte(costBN) then
        return false, "Insufficient currency."
    end

    -- Deduct cost
    local newCurrency = currency:sub(costBN)
    DataManager.setData(player, "Currency", newCurrency:tostring())

    -- Save generator
    local incomeStr = GeneratorData.getIncomeAtLevel(typeId, level)
    local generators = data.Generators
    generators[instanceKey] = {
        TypeId  = typeId,
        Level   = level,
        Income  = incomeStr,
    }
    DataManager.setData(player, "Generators", generators)

    -- Spawn/update model
    PlotManager.spawnGenerator(player, typeId, instanceKey, level)

    -- Fire currency update
    if updateCurrency then
        updateCurrency:FireClient(player, newCurrency:tostring())
    end

    return true, existingKey and "Upgraded!" or "Purchased!"
end

-- ============================================================
-- COLLECT EARNINGS (server-authoritative)
-- ============================================================

--- Move uncollected earnings into currency.
---@param player Player
function GeneratorManager.collectEarnings(player: Player)
    local data = DataManager.getData(player)
    if not data then return end

    local uncollected = BigNum.new(data.Uncollected or "0")
    if not uncollected:gt(BigNum.zero()) then return end

    local currency    = BigNum.new(data.Currency or "0")
    local newCurrency = currency:add(uncollected)

    -- Update TotalEarned
    local totalEarned = BigNum.new(data.TotalEarned or "0")
    DataManager.setData(player, "TotalEarned", totalEarned:add(uncollected):tostring())

    DataManager.setData(player, "Currency",   newCurrency:tostring())
    DataManager.setData(player, "Uncollected", "0")

    -- Fire currency update to client
    if updateCurrency then
        updateCurrency:FireClient(player, newCurrency:tostring())
    end
end

-- ============================================================
-- PUBLIC INIT
-- ============================================================

function GeneratorManager.init()
    showFloatingText = RemoteDefinitions.getEvent("ShowFloatingText")
    updateCurrency   = RemoteDefinitions.getEvent("UpdateCurrency")

    -- Single centralized Heartbeat loop
    RunService.Heartbeat:Connect(function(dt: number)
        accumulatedTime = accumulatedTime + dt
        if accumulatedTime >= Constants.TICK_INTERVAL then
            accumulatedTime = accumulatedTime - Constants.TICK_INTERVAL
            for _, player in ipairs(Players:GetPlayers()) do
                if DataManager.isLoaded(player) then
                    local ok, err = pcall(tickPlayer, player)
                    if not ok then
                        warn("[GeneratorManager] Tick error for", player.Name, err)
                    end
                end
            end
        end
    end)

    print("[GeneratorManager] Heartbeat income engine started.")
end

--- Wire up the BuyGenerator and CollectEarnings remotes.
function GeneratorManager.wireRemotes()
    local buyEvent     = RemoteDefinitions.getEvent("BuyGenerator")
    local collectEvent = RemoteDefinitions.getEvent("CollectEarnings")

    buyEvent.OnServerEvent:Connect(function(player: Player, typeId: string)
        if type(typeId) ~= "string" then return end
        local ok, msg = GeneratorManager.buyGenerator(player, typeId)
        if not ok then
            warn("[GeneratorManager] BuyGenerator rejected for", player.Name, ":", msg)
        end
    end)

    collectEvent.OnServerEvent:Connect(function(player: Player)
        GeneratorManager.collectEarnings(player)
    end)
end

return GeneratorManager
