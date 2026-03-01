-- RebirthManager.luau
-- Prestige reset: validates requirement, applies multiplier bonus,
-- resets currency/generators/brainrots while preserving progress stats.

local DataManager       = require(script.Parent.DataManager)
local BigNum            = require(game.ReplicatedStorage.Shared.BigNum)
local Constants         = require(game.ReplicatedStorage.Shared.Constants)
local RemoteDefinitions = require(game.ReplicatedStorage.Shared.RemoteDefinitions)

local RebirthManager = {}

-- ============================================================
-- PUBLIC API
-- ============================================================

--- Attempt a rebirth for the given player.
---@param player Player
---@return boolean success, string message
function RebirthManager.attemptRebirth(player: Player): (boolean, string)
    local data = DataManager.getData(player)
    if not data then return false, "Data not loaded." end

    -- Validate TotalEarned >= requirement
    local totalEarned   = BigNum.new(data.TotalEarned or "0")
    local requirement   = BigNum.new(Constants.REBIRTH_REQUIREMENT)

    if not totalEarned:gte(requirement) then
        return false, "You need at least " .. requirement:tostring() .. " total earnings to rebirth."
    end

    -- Calculate new multiplier
    local newMultiplier = (data.Multiplier or 1.0) + Constants.REBIRTH_MULTIPLIER_BONUS
    local newRebirthCount = (data.RebirthCount or 0) + 1

    -- Preserve: Multiplier, RebirthCount, PityCounts, HasAutoCollect, HasSigmaAura, ShieldExpiry, PlotId
    -- Reset:    Currency, Generators, Brainrots, Uncollected, TotalEarned, LuckBoostExpiry
    DataManager.setData(player, "Currency",       "0")
    DataManager.setData(player, "TotalEarned",    "0")
    DataManager.setData(player, "Generators",     {})
    DataManager.setData(player, "Brainrots",      {})
    DataManager.setData(player, "Uncollected",    "0")
    DataManager.setData(player, "LuckBoostExpiry", 0)
    DataManager.setData(player, "Multiplier",     newMultiplier)
    DataManager.setData(player, "RebirthCount",   newRebirthCount)

    -- Remove generator models from plot
    local PlotManager = require(script.Parent.PlotManager)
    local plotId = data.PlotId
    if plotId and plotId ~= 0 then
        local models = PlotManager.getGeneratorModels(plotId)
        for _, model in pairs(models) do
            model:Destroy()
        end
    end

    -- Sync currency to client
    local updateCurrency = RemoteDefinitions.getEvent("UpdateCurrency")
    updateCurrency:FireClient(player, "0")

    print(string.format("[RebirthManager] %s rebirthed! Count: %d, Multiplier: %.1fx",
        player.Name, newRebirthCount, newMultiplier))

    return true, string.format("Rebirthed! You now have a %.1fx income multiplier.", newMultiplier)
end

-- ============================================================
-- WIRE REMOTES
-- ============================================================

function RebirthManager.wireRemotes()
    local rebirthEvent = RemoteDefinitions.getEvent("RequestRebirth")

    rebirthEvent.OnServerEvent:Connect(function(player: Player)
        local success, msg = RebirthManager.attemptRebirth(player)
        if not success then
            warn("[RebirthManager] Rebirth failed for", player.Name, ":", msg)
        end
    end)
end

return RebirthManager
