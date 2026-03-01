-- PlotManager.luau
-- Assigns plots to players on join and manages generator model spawning.
-- Plots are pre-built in Workspace > Plots by the developer (Studio setup).

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")

local DataManager    = require(script.Parent.DataManager)
local GeneratorData  = require(game.ReplicatedStorage.Shared.GeneratorData)
local BigNum         = require(game.ReplicatedStorage.Shared.BigNum)

local PlotManager = {}

-- ============================================================
-- INTERNAL STATE
-- ============================================================
-- plotRegistry[plotId] = Player | nil
local plotRegistry: { [number]: Player? } = {}

-- generatorModels[plotId] = { [instanceKey] = Model }
local generatorModels: { [number]: { [string]: Model } } = {}

-- All Plot models found in Workspace
local plotFolder: Folder

-- ============================================================
-- INITIALIZATION
-- ============================================================

function PlotManager.init()
    plotFolder = workspace:WaitForChild("Plots", 10) :: Folder
    if not plotFolder then
        warn("[PlotManager] No 'Plots' folder found in Workspace!")
        return
    end

    -- Register all plots
    for _, plotModel in ipairs(plotFolder:GetChildren()) do
        if plotModel:IsA("Model") then
            local plotId = plotModel:GetAttribute("PlotId")
            if plotId then
                plotRegistry[plotId] = nil
                generatorModels[plotId] = {}
            end
        end
    end

    print("[PlotManager] Registered", #plotFolder:GetChildren(), "plots.")
end

-- ============================================================
-- HELPERS
-- ============================================================

local function getPlotModel(plotId: number): Model?
    if not plotFolder then return nil end
    for _, child in ipairs(plotFolder:GetChildren()) do
        if child:IsA("Model") and child:GetAttribute("PlotId") == plotId then
            return child :: Model
        end
    end
    return nil
end

--- Find the first unoccupied plot.
local function findFreePlot(): number?
    for plotId, occupant in pairs(plotRegistry) do
        if occupant == nil then
            return plotId
        end
    end
    return nil
end

-- ============================================================
-- GENERATOR SPAWNING
-- ============================================================

--- Spawn a generator model on a plot at a reasonable position.
---@param plotId number
---@param genTypeId string
---@param instanceKey string  unique key for this generator instance
---@param level number
local function spawnGeneratorModel(plotId: number, genTypeId: string, instanceKey: string, level: number): Model?
    local plotModel = getPlotModel(plotId)
    if not plotModel then return nil end

    local spawnArea = plotModel:FindFirstChild("SpawnArea") :: BasePart
    if not spawnArea then
        warn("[PlotManager] Plot", plotId, "has no SpawnArea!")
        return nil
    end

    -- Check if a model template exists in ReplicatedStorage
    local genDef = GeneratorData.ByTypeId[genTypeId]
    local modelTemplate = game.ReplicatedStorage:FindFirstChild(genDef and genDef.ModelName or "")

    local GeneratorModels = require(script.Parent.GeneratorModels)
    local genModel: Model
    if modelTemplate and modelTemplate:IsA("Model") then
        genModel = modelTemplate:Clone()
    else
        genModel = GeneratorModels.build(genTypeId, level)
    end

    -- Position near the SpawnArea; offset by index to avoid overlap
    local existingCount = 0
    for _ in pairs(generatorModels[plotId] or {}) do
        existingCount = existingCount + 1
    end
    local offset = Vector3.new((existingCount % 5) * 5, 0, math.floor(existingCount / 5) * 5)
    local spawnCFrame = spawnArea.CFrame * CFrame.new(offset)
    genModel:SetPrimaryPartCFrame(spawnCFrame)

    -- Set Attributes for server queries
    genModel:SetAttribute("TypeId",      genTypeId)
    genModel:SetAttribute("Level",       level)
    genModel:SetAttribute("InstanceKey", instanceKey)
    genModel:SetAttribute("PlotId",      plotId)

    genModel.Parent = plotModel

    if not generatorModels[plotId] then
        generatorModels[plotId] = {}
    end
    generatorModels[plotId][instanceKey] = genModel

    return genModel
end

-- ============================================================
-- PUBLIC API
-- ============================================================

--- Assign a free plot to a player, restore saved generators.
---@param player Player
function PlotManager.assignPlot(player: Player)
    local data = DataManager.getData(player)
    if not data then return end

    -- Try to reuse the player's saved plot
    local plotId = data.PlotId
    if plotId == 0 or plotRegistry[plotId] ~= nil then
        plotId = findFreePlot()
    end

    if not plotId then
        warn("[PlotManager] No free plots for", player.Name)
        player:Kick("The server is full! All plots are occupied.")
        return
    end

    plotRegistry[plotId] = player
    DataManager.setData(player, "PlotId", plotId)

    -- Restore saved generators
    local generators = data.Generators or {}
    for instanceKey, genData in pairs(generators) do
        spawnGeneratorModel(plotId, genData.TypeId, instanceKey, genData.Level or 1)
    end

    print("[PlotManager] Assigned plot", plotId, "to", player.Name)
    local PlotVisuals = require(script.Parent.PlotVisuals)
    PlotVisuals.updatePlotClaimed(plotId, player.Name)
end

--- Release a player's plot on leave.
---@param player Player
function PlotManager.releasePlot(player: Player)
    local data = DataManager.getData(player)
    local plotId = data and data.PlotId or 0

    if plotId ~= 0 then
        -- Remove all generator models
        if generatorModels[plotId] then
            for _, model in pairs(generatorModels[plotId]) do
                model:Destroy()
            end
            generatorModels[plotId] = {}
        end
        local PlotVisuals = require(script.Parent.PlotVisuals)
        PlotVisuals.updatePlotReleased(plotId)
        plotRegistry[plotId] = nil
    end
end

--- Spawn a new generator for a player (called after purchase).
---@param player Player
---@param genTypeId string
---@param instanceKey string
---@param level number
function PlotManager.spawnGenerator(player: Player, genTypeId: string, instanceKey: string, level: number)
    local data = DataManager.getData(player)
    if not data then return end
    local plotId = data.PlotId
    spawnGeneratorModel(plotId, genTypeId, instanceKey, level)
end

--- Get the plot model for a given plotId.
---@param plotId number
---@return Model?
function PlotManager.getPlotModel(plotId: number): Model?
    return getPlotModel(plotId)
end

--- Get the player occupying a plot.
---@param plotId number
---@return Player?
function PlotManager.getPlotOwner(plotId: number): Player?
    return plotRegistry[plotId]
end

--- Get all plot occupants as a table.
---@return { [number]: Player? }
function PlotManager.getRegistry(): { [number]: Player? }
    return plotRegistry
end

--- Get generator models for a plot.
---@param plotId number
---@return { [string]: Model }
function PlotManager.getGeneratorModels(plotId: number): { [string]: Model }
    return generatorModels[plotId] or {}
end

return PlotManager
