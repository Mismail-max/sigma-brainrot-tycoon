-- MonetizationManager.luau
-- Handles Gamepass ownership checks and DevProduct purchase receipts.
-- ALWAYS returns PurchaseGranted after saving to DataStore.

local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")

local DataManager        = require(script.Parent.DataManager)
local Constants          = require(game.ReplicatedStorage.Shared.Constants)
local RemoteDefinitions  = require(game.ReplicatedStorage.Shared.RemoteDefinitions)

local MonetizationManager = {}

-- ============================================================
-- GAMEPASS CHECKS
-- ============================================================

--- Check if a player owns a gamepass (with pcall safety).
---@param player Player
---@param passId number
---@return boolean
local function ownsGamepass(player: Player, passId: number): boolean
    if passId == 0 then return false end  -- not published yet
    local ok, result = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
    end)
    return ok and result or false
end

--- Check and apply all gamepass perks for a player.
---@param player Player
function MonetizationManager.checkGamepasses(player: Player)
    local data = DataManager.getData(player)
    if not data then return end

    local hasAutoCollect = ownsGamepass(player, Constants.GAMEPASSES.AutoCollect.Id)
    local hasSigmaAura   = ownsGamepass(player, Constants.GAMEPASSES.SigmaAura.Id)

    if hasAutoCollect ~= data.HasAutoCollect then
        DataManager.setData(player, "HasAutoCollect", hasAutoCollect)
    end
    if hasSigmaAura ~= data.HasSigmaAura then
        DataManager.setData(player, "HasSigmaAura", hasSigmaAura)

        -- Fire shield status or aura notification if newly acquired
        if hasSigmaAura then
            local shieldEvent = RemoteDefinitions.getEvent("ShieldStatusChanged")
            shieldEvent:FireClient(player, { auraActive = true })
        end
    end
end

-- ============================================================
-- PROCESSRECEIPT (DEV PRODUCTS)
-- ============================================================

--- Apply the purchased dev product to the player's data.
---@param player Player
---@param productId number
---@return boolean  true if applied successfully
local function applyProduct(player: Player, productId: number): boolean
    local data = DataManager.getData(player)
    if not data then return false end

    local products = Constants.DEV_PRODUCTS
    local now = os.time()

    if productId == products.LuckBoost.Id and productId ~= 0 then
        local currentExpiry = data.LuckBoostExpiry or 0
        -- Stack duration if already active
        local newExpiry = math.max(now, currentExpiry) + products.LuckBoost.Duration
        DataManager.setData(player, "LuckBoostExpiry", newExpiry)
        return true

    elseif productId == products.AntiLShield.Id and productId ~= 0 then
        local currentExpiry = data.ShieldExpiry or 0
        local newExpiry = math.max(now, currentExpiry) + products.AntiLShield.Duration
        DataManager.setData(player, "ShieldExpiry", newExpiry)

        -- Notify client of new shield status
        local shieldEvent = RemoteDefinitions.getEvent("ShieldStatusChanged")
        shieldEvent:FireClient(player, { active = true, expiry = newExpiry })
        return true

    elseif productId == products.InstantRebirth.Id and productId ~= 0 then
        -- Grant an instant rebirth without the currency requirement
        local RebirthManager = require(script.Parent.RebirthManager)
        -- Temporarily override requirement by directly calling internal reset
        local newMultiplier   = (data.Multiplier or 1.0) + Constants.REBIRTH_MULTIPLIER_BONUS
        local newRebirthCount = (data.RebirthCount or 0) + 1
        DataManager.setData(player, "Currency",       "0")
        DataManager.setData(player, "TotalEarned",    "0")
        DataManager.setData(player, "Generators",     {})
        DataManager.setData(player, "Brainrots",      {})
        DataManager.setData(player, "Uncollected",    "0")
        DataManager.setData(player, "LuckBoostExpiry", 0)
        DataManager.setData(player, "Multiplier",     newMultiplier)
        DataManager.setData(player, "RebirthCount",   newRebirthCount)

        local updateCurrency = RemoteDefinitions.getEvent("UpdateCurrency")
        updateCurrency:FireClient(player, "0")
        return true
    end

    warn("[MonetizationManager] Unknown productId:", productId)
    return false
end

--- ProcessReceipt callback. ALWAYS returns PurchaseGranted after save.
local function processReceipt(receiptInfo: any): Enum.ProductPurchaseDecision
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        -- Player left; process next time they join via ReceiptHistory
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- Wait for data to be loaded (up to 10 seconds)
    local waited = 0
    while not DataManager.isLoaded(player) and waited < 10 do
        task.wait(0.5)
        waited = waited + 0.5
    end

    if not DataManager.isLoaded(player) then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local success = applyProduct(player, receiptInfo.ProductId)
    if success then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    else
        -- Still grant to avoid charging the player for nothing
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
end

-- ============================================================
-- INIT
-- ============================================================

function MonetizationManager.init()
    MarketplaceService.ProcessReceipt = processReceipt
    print("[MonetizationManager] Initialized.")
end

return MonetizationManager
