-- GeneratorClient.luau
-- Detects clicks on generator models in the player's plot.
-- Fires BuyGenerator and CollectEarnings remotes to the server.

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local RemoteDefinitions = require(game.ReplicatedStorage.Shared.RemoteDefinitions)
local GeneratorData     = require(game.ReplicatedStorage.Shared.GeneratorData)

local GeneratorClient = {}

local player    = Players.LocalPlayer
local mouse     = player:GetMouse()
local camera    = workspace.CurrentCamera

local buyEvent: RemoteEvent
local collectEvent: RemoteEvent

-- ============================================================
-- CLICK DETECTION
-- ============================================================

-- Maximum distance (in studs) for click detection
local MAX_CLICK_DISTANCE = 50

--- Find if the mouse is hovering over a generator model part.
---@return Model?
local function getHoveredGenerator(): Model?
    local unitRay  = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local raycast  = workspace:Raycast(
        unitRay.Origin,
        unitRay.Direction * MAX_CLICK_DISTANCE,
        RaycastParams.new()
    )
    if not raycast then return nil end

    local hit = raycast.Instance
    -- Walk up the part hierarchy to find a Model with a TypeId attribute
    local current: Instance? = hit
    while current do
        if current:IsA("Model") and current:GetAttribute("TypeId") then
            return current :: Model
        end
        current = current.Parent
    end
    return nil
end

-- ============================================================
-- SHOP UI OPEN (click on plot ground → open shop)
-- ============================================================

local ShopUI  -- lazily loaded to avoid circular deps
local GachaUI

local function tryOpenShop()
    local unitRay  = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local params   = RaycastParams.new()
    local raycast  = workspace:Raycast(unitRay.Origin, unitRay.Direction * 100, params)
    if not raycast then return end

    -- Check if we hit a SpawnArea part (opens shop)
    local hit = raycast.Instance
    if hit and hit.Name == "SpawnArea" then
        if ShopUI then
            ShopUI.open()
        end
    end
end

-- ============================================================
-- INPUT HANDLER
-- ============================================================

local function onInputBegan(input: InputObject, gameProcessed: boolean)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

        -- Check for generator click (collect / interact)
        local genModel = getHoveredGenerator()
        if genModel then
            local typeId = genModel:GetAttribute("TypeId")
            if typeId then
                -- For now, clicking a generator manually triggers collect
                -- (the shop handles purchasing)
                collectEvent:FireServer()
            end
            return
        end

        -- Check for plot click (open shop)
        tryOpenShop()
    end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function GeneratorClient.init()
    buyEvent     = RemoteDefinitions.getEvent("BuyGenerator")
    collectEvent = RemoteDefinitions.getEvent("CollectEarnings")

    UserInputService.InputBegan:Connect(onInputBegan)

    -- Lazy-load UI modules after they're initialized
    task.spawn(function()
        task.wait(1)
        local ok1, shop  = pcall(require, script.Parent.ShopUI)
        local ok2, gacha = pcall(require, script.Parent.GachaUI)
        if ok1 then ShopUI  = shop  end
        if ok2 then GachaUI = gacha end
    end)

    print("[GeneratorClient] Input handler active.")
end

--- Public helper to buy a generator (called by ShopUI).
---@param typeId string
function GeneratorClient.buyGenerator(typeId: string)
    if buyEvent then
        buyEvent:FireServer(typeId)
    end
end

return GeneratorClient
