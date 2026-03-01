-- StealManager.luau
-- Server-authoritative PvP stealing with per-target cooldowns and shield checks.

local Players           = game:GetService("Players")

local DataManager       = require(script.Parent.DataManager)
local PlotManager       = require(script.Parent.PlotManager)
local BigNum            = require(game.ReplicatedStorage.Shared.BigNum)
local Constants         = require(game.ReplicatedStorage.Shared.Constants)
local RemoteDefinitions = require(game.ReplicatedStorage.Shared.RemoteDefinitions)
local FormatNumber      = require(game.ReplicatedStorage.Shared.FormatNumber)

local StealManager = {}

-- ============================================================
-- INTERNAL STATE
-- ============================================================
-- Cooldown table: cooldowns[thiefUserId][targetUserId] = expiry os.time()
local cooldowns: { [number]: { [number]: number } } = {}

-- ============================================================
-- HELPERS
-- ============================================================

local function hasCooldown(thiefId: number, targetId: number): boolean
    local thiefCools = cooldowns[thiefId]
    if not thiefCools then return false end
    local expiry = thiefCools[targetId]
    return expiry ~= nil and os.time() < expiry
end

local function setCooldown(thiefId: number, targetId: number)
    if not cooldowns[thiefId] then
        cooldowns[thiefId] = {}
    end
    cooldowns[thiefId][targetId] = os.time() + Constants.STEAL_COOLDOWN
end

--- Check if a player currently has an active shield.
---@param player Player
---@return boolean
function StealManager.isShielded(player: Player): boolean
    local data = DataManager.getData(player)
    if not data then return false end
    return (data.ShieldExpiry or 0) > os.time()
end

-- ============================================================
-- STEAL LOGIC
-- ============================================================

--- Attempt to steal from the owner of a given plot.
---@param thief Player
---@param targetPlotId number
---@return boolean success, string message
function StealManager.attemptSteal(thief: Player, targetPlotId: number): (boolean, string)
    -- 1. Validate plot exists and has an owner
    local targetPlayer = PlotManager.getPlotOwner(targetPlotId)
    if not targetPlayer then
        return false, "That plot is unoccupied."
    end

    -- 2. No self-stealing
    if targetPlayer == thief then
        return false, "You cannot steal from yourself."
    end

    -- 3. Check cooldown
    if hasCooldown(thief.UserId, targetPlayer.UserId) then
        return false, "You are on cooldown for this target."
    end

    -- 4. Check shield
    if StealManager.isShielded(targetPlayer) then
        return false, "That player is shielded!"
    end

    -- 5. Target must have enough uncollected earnings
    local targetData = DataManager.getData(targetPlayer)
    if not targetData then return false, "Target data unavailable." end

    local uncollected = BigNum.new(targetData.Uncollected or "0")
    local minSteal    = BigNum.new(Constants.STEAL_MIN_UNCOLLECTED)
    if not uncollected:gt(minSteal) then
        return false, "Not enough uncollected earnings to steal."
    end

    -- 6. Calculate steal amount (fraction of uncollected)
    local stealAmount = uncollected:mul(Constants.STEAL_FRACTION)
    if not stealAmount:gt(BigNum.zero()) then
        return false, "Steal amount too small."
    end

    -- Apply the steal
    local newTargetUncollected = uncollected:sub(stealAmount)
    DataManager.setData(targetPlayer, "Uncollected", newTargetUncollected:tostring())

    -- Give stolen currency to thief
    local thiefData     = DataManager.getData(thief)
    local thiefCurrency = BigNum.new(thiefData and thiefData.Currency or "0")
    local newThiefCurrency = thiefCurrency:add(stealAmount)
    DataManager.setData(thief, "Currency", newThiefCurrency:tostring())

    -- Also credit thief's TotalEarned
    local thiefTotal = BigNum.new(thiefData and thiefData.TotalEarned or "0")
    DataManager.setData(thief, "TotalEarned", thiefTotal:add(stealAmount):tostring())

    -- Set cooldown
    setCooldown(thief.UserId, targetPlayer.UserId)

    -- Notify victim
    local notifySteal  = RemoteDefinitions.getEvent("NotifySteal")
    local updateCurrency = RemoteDefinitions.getEvent("UpdateCurrency")
    local stealDisplay = FormatNumber.format(stealAmount)

    notifySteal:FireClient(
        targetPlayer,
        thief.Name .. " stole " .. stealDisplay .. " from you!"
    )

    -- Sync both players' currencies
    updateCurrency:FireClient(thief, newThiefCurrency:tostring())
    updateCurrency:FireClient(targetPlayer, targetData.Currency)

    print(string.format("[StealManager] %s stole %s from %s (plot %d)",
        thief.Name, stealDisplay, targetPlayer.Name, targetPlotId))

    return true, "Stole " .. stealDisplay .. "!"
end

-- ============================================================
-- WIRE REMOTES
-- ============================================================

function StealManager.wireRemotes()
    local stealEvent = RemoteDefinitions.getEvent("StealEarnings")

    stealEvent.OnServerEvent:Connect(function(player: Player, targetPlotId: number)
        if type(targetPlotId) ~= "number" then return end
        local success, msg = StealManager.attemptSteal(player, targetPlotId)
        if not success then
            warn("[StealManager] Steal failed for", player.Name, ":", msg)
        end
    end)
end

--- Clean up cooldowns when a player leaves.
---@param player Player
function StealManager.cleanupPlayer(player: Player)
    cooldowns[player.UserId] = nil
    -- Also remove this player from all other cooldown tables
    for _, thiefCools in pairs(cooldowns) do
        thiefCools[player.UserId] = nil
    end
end

return StealManager
