-- GachaManager.luau
-- Weighted RNG crate opening with pity system.
-- All currency deduction and result delivery happen server-side.

local DataManager       = require(script.Parent.DataManager)
local BigNum            = require(game.ReplicatedStorage.Shared.BigNum)
local MemeData          = require(game.ReplicatedStorage.Shared.MemeData)
local Constants         = require(game.ReplicatedStorage.Shared.Constants)
local RemoteDefinitions = require(game.ReplicatedStorage.Shared.RemoteDefinitions)

local GachaManager = {}

-- ============================================================
-- PRE-BUILT CUMULATIVE WEIGHT TABLE
-- ============================================================
-- Built at module load time from MemeData.Rarities
local cumulativeTable = {}  -- { { rarity = "Common", cumWeight = 6000 }, ... }
local totalWeight = MemeData.TOTAL_WEIGHT

do
    for _, rarityInfo in ipairs(MemeData.Rarities) do
        table.insert(cumulativeTable, {
            rarity    = rarityInfo.Name,
            cumWeight = rarityInfo.CumulativeWeight,
        })
    end
end

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================

--- Roll a rarity, applying pity if applicable.
---@param player Player
---@return string  rarity name
local function _rollRarity(player: Player): string
    local data = DataManager.getData(player)
    local pityCounts = data and data.PityCounts or {}
    local mythicPity = (pityCounts.Mythic or 0) >= Constants.PITY_THRESHOLD

    -- Check luck boost
    local luckBoostActive = (data and data.LuckBoostExpiry or 0) > os.time()

    -- Rebuild weight table if pity is active
    local roll: number
    if mythicPity then
        -- Increase Mythic weight by multiplier, recalculate total
        local adjustedTotal = totalWeight
        -- Find raw Mythic weight (diff between last two entries)
        local mythicBase = cumulativeTable[#cumulativeTable].cumWeight
                         - (cumulativeTable[#cumulativeTable - 1] and cumulativeTable[#cumulativeTable - 1].cumWeight or 0)
        local bonus      = mythicBase * (Constants.PITY_MYTHIC_MULTIPLIER - 1)
        adjustedTotal    = totalWeight + bonus

        -- Roll in adjusted space
        local rawRoll = math.random(1, math.floor(adjustedTotal))
        -- Map: if roll falls in the bonus zone, it's Mythic
        if rawRoll > totalWeight then
            return "Mythic"
        end
        roll = rawRoll
    else
        roll = math.random(1, totalWeight)
    end

    -- Apply luck boost: re-roll and take the better (higher-rarity) result
    if luckBoostActive then
        local roll2 = math.random(1, totalWeight)
        -- Higher roll = better rarity (since Common has lowest cumWeight)
        -- Actually cumulative means lower roll = lower rarity; we want the higher rarity result
        -- Lower raw roll ≤ 6000 = Common, we want to AVOID Common, so take the higher roll
        roll = math.max(roll, roll2)
    end

    -- Walk cumulative table
    for _, entry in ipairs(cumulativeTable) do
        if roll <= entry.cumWeight then
            return entry.rarity
        end
    end
    return "Common"  -- fallback
end

--- Pick a random character from a given rarity bucket.
---@param rarity string
---@return table?  MemeCharacter
local function _selectCharacter(rarity: string): any?
    local pool = MemeData.CharactersByRarity[rarity]
    if not pool or #pool == 0 then return nil end
    return pool[math.random(1, #pool)]
end

--- Update pity counters after a pull.
---@param player Player
---@param rarity string  the rarity that was pulled
local function _updatePity(player: Player, rarity: string)
    local data = DataManager.getData(player)
    if not data then return end

    local pity = data.PityCounts or { Rare = 0, Epic = 0, Legendary = 0, Mythic = 0 }

    if rarity == "Mythic" then
        -- Reset Mythic pity on pull
        pity.Mythic = 0
    else
        -- Increment Mythic pity
        pity.Mythic = (pity.Mythic or 0) + 1
    end

    DataManager.setData(player, "PityCounts", pity)
end

-- ============================================================
-- PUBLIC API
-- ============================================================

--- Open a crate for a player, deduct cost, return result.
---@param player Player
---@param crateType string  (reserved for future multi-crate types)
---@return boolean success, table? crateResult
function GachaManager.openCrate(player: Player, crateType: string): (boolean, any?)
    local data = DataManager.getData(player)
    if not data then return false, nil end

    -- Deduct cost
    local currency = BigNum.new(data.Currency or "0")
    local cost     = BigNum.new(Constants.CRATE_COST)
    if not currency:gte(cost) then
        return false, nil
    end

    local newCurrency = currency:sub(cost)
    DataManager.setData(player, "Currency", newCurrency:tostring())

    -- Roll
    local rarity    = _rollRarity(player)
    local character = _selectCharacter(rarity)
    if not character then
        -- Refund if somehow no character available
        DataManager.setData(player, "Currency", currency:tostring())
        return false, nil
    end

    -- Update pity
    _updatePity(player, rarity)

    -- Add to collection
    local brainrots = data.Brainrots or {}
    local isNew     = true
    for _, name in ipairs(brainrots) do
        if name == character.Name then
            isNew = false
            break
        end
    end
    if isNew then
        table.insert(brainrots, character.Name)
        DataManager.setData(player, "Brainrots", brainrots)
    end

    local result = {
        Character = character,
        Rarity    = rarity,
        IsNew     = isNew,
    }

    return true, result
end

-- ============================================================
-- WIRE REMOTES
-- ============================================================

function GachaManager.wireRemotes()
    local openCrateEvent  = RemoteDefinitions.getEvent("OpenCrate")
    local crateResultEvent = RemoteDefinitions.getEvent("CrateResult")
    local updateCurrency   = RemoteDefinitions.getEvent("UpdateCurrency")

    openCrateEvent.OnServerEvent:Connect(function(player: Player, crateType: string)
        crateType = type(crateType) == "string" and crateType or "Standard"
        local success, result = GachaManager.openCrate(player, crateType)
        if success and result then
            -- Fire result to client for animation
            crateResultEvent:FireClient(player, result)

            -- Sync currency
            local data = DataManager.getData(player)
            if data then
                updateCurrency:FireClient(player, data.Currency)
            end
        else
            warn("[GachaManager] Crate open failed for", player.Name)
        end
    end)
end

return GachaManager
