-- PlotSetup.server.luau
-- Creates 20 Plot models in Workspace > Plots on server start.
-- Each Plot model has:
--   • PlotId attribute (number 1–20)
--   • A Part child named "SpawnArea"
-- Safe to restart: skips plots that already exist.

local PLOTS_FOLDER_NAME = "Plots"
local PLOT_COUNT        = 20

-- SpawnArea settings
local SPAWN_SIZE         = Vector3.new(12, 1, 12)
local SPAWN_ANCHORED     = true
local SPAWN_CAN_COLLIDE  = false
local SPAWN_TRANSPARENCY = 1   -- invisible; PlotVisuals draws the visual base instead

-- World layout: row along the X axis, 30 studs apart
local ORIGIN  = Vector3.new(0, 5, 0)
local SPACING = Vector3.new(30, 0, 0)

-- ============================================================

local workspace = game:GetService("Workspace")

-- Get or create the Plots folder
local plotsFolder = workspace:FindFirstChild(PLOTS_FOLDER_NAME)
if not plotsFolder then
    plotsFolder = Instance.new("Folder")
    plotsFolder.Name   = PLOTS_FOLDER_NAME
    plotsFolder.Parent = workspace
end

local created = 0

for i = 1, PLOT_COUNT do
    -- Skip if a plot with this ID already exists
    local exists = false
    for _, child in ipairs(plotsFolder:GetChildren()) do
        if child:IsA("Model") and child:GetAttribute("PlotId") == i then
            exists = true
            break
        end
    end
    if exists then continue end

    -- Plot model
    local plotModel = Instance.new("Model")
    plotModel.Name   = "Plot"
    plotModel.Parent = plotsFolder

    -- PlotId attribute
    plotModel:SetAttribute("PlotId", i)

    -- SpawnArea part
    local spawnArea = Instance.new("Part")
    spawnArea.Name         = "SpawnArea"
    spawnArea.Size         = SPAWN_SIZE
    spawnArea.Anchored     = SPAWN_ANCHORED
    spawnArea.CanCollide   = SPAWN_CAN_COLLIDE
    spawnArea.Transparency = SPAWN_TRANSPARENCY
    spawnArea.Position     = ORIGIN + SPACING * (i - 1)
    spawnArea.Parent       = plotModel

    -- Align model pivot to SpawnArea
    plotModel:PivotTo(spawnArea.CFrame)

    created += 1
end

print(("[PlotSetup] Created %d new plots in Workspace.%s"):format(created, PLOTS_FOLDER_NAME))
