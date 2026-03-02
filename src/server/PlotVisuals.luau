-- PlotVisuals.luau
-- Decorates Plot models in Workspace.Plots with visual elements:
-- base slab, border trim, corner pillars with neon caps, and an ownership sign.
-- Exposes updatePlotClaimed / updatePlotReleased for runtime sign updates.

local PlotVisuals = {}

-- signRefs[plotId] = { statusLabel: TextLabel, base: Part }
type SignRef = { statusLabel: TextLabel, base: Part }
local signRefs: { [number]: SignRef } = {}

-- ============================================================
-- CONSTANTS
-- ============================================================

local COLOR_SLATE         = Color3.fromRGB(35, 40, 50)       -- unclaimed base
local COLOR_SLATE_CLAIMED = Color3.fromRGB(20, 50, 30)        -- claimed base tint
local COLOR_TRIM          = Color3.fromRGB(75, 80, 92)
local COLOR_PILLAR        = Color3.fromRGB(55, 60, 72)
local COLOR_NEON_CAP      = Color3.fromRGB(0, 200, 255)
local COLOR_UNCLAIMED     = Color3.fromRGB(255, 60, 60)
local COLOR_CLAIMED       = Color3.fromRGB(60, 220, 60)
local COLOR_PLOT_TITLE    = Color3.fromRGB(180, 180, 180)

-- ============================================================
-- HELPERS
-- ============================================================

local function newPart(
	parent: Instance,
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	cf: CFrame
): Part
	local p = Instance.new("Part")
	p.Name        = name
	p.Size        = size
	p.Color       = color
	p.Material    = material
	p.CFrame      = cf
	p.Anchored    = true
	p.CanCollide  = false
	p.CastShadow  = false
	p.Parent      = parent
	return p
end

-- ============================================================
-- PER-PLOT DECORATION
-- ============================================================

local function decoratePlot(plotModel: Model)
	local plotId = plotModel:GetAttribute("PlotId") :: number
	if not plotId then return end

	local spawnArea = plotModel:FindFirstChild("SpawnArea") :: BasePart
	if not spawnArea then
		warn("[PlotVisuals] Plot", plotId, "has no SpawnArea — skipping.")
		return
	end

	-- Hide SpawnArea; keep it for position reference
	spawnArea.Transparency = 1
	spawnArea.CanCollide   = false

	local cx  = spawnArea.Position.X
	local cy  = spawnArea.Position.Y
	local cz  = spawnArea.Position.Z
	local sx  = spawnArea.Size.X
	local sz  = spawnArea.Size.Z
	local sy  = spawnArea.Size.Y

	local baseSX = sx + 2
	local baseSZ = sz + 2

	-- Base slab (sits flush under/around SpawnArea)
	local baseY = cy - sy / 2 + 0.3   -- centre of a 0.6-tall slab
	local base = newPart(plotModel, "PlotBase_V",
		Vector3.new(baseSX, 0.6, baseSZ),
		COLOR_SLATE, Enum.Material.SmoothPlastic,
		CFrame.new(cx, baseY, cz))

	-- Border trim (4 thin raised strips)
	local trimH     = 0.3
	local trimThick = 0.4
	local trimY     = baseY + 0.3 + trimH / 2    -- top of base + half trim height

	-- North
	newPart(plotModel, "BorderN_V",
		Vector3.new(baseSX, trimH, trimThick),
		COLOR_TRIM, Enum.Material.SmoothPlastic,
		CFrame.new(cx, trimY, cz + baseSZ / 2 - trimThick / 2))
	-- South
	newPart(plotModel, "BorderS_V",
		Vector3.new(baseSX, trimH, trimThick),
		COLOR_TRIM, Enum.Material.SmoothPlastic,
		CFrame.new(cx, trimY, cz - baseSZ / 2 + trimThick / 2))
	-- East
	newPart(plotModel, "BorderE_V",
		Vector3.new(trimThick, trimH, baseSZ),
		COLOR_TRIM, Enum.Material.SmoothPlastic,
		CFrame.new(cx + baseSX / 2 - trimThick / 2, trimY, cz))
	-- West
	newPart(plotModel, "BorderW_V",
		Vector3.new(trimThick, trimH, baseSZ),
		COLOR_TRIM, Enum.Material.SmoothPlastic,
		CFrame.new(cx - baseSX / 2 + trimThick / 2, trimY, cz))

	-- Corner pillars + neon caps
	local pillarH  = 1.5
	local pillarS  = 0.6
	local pillarY  = trimY + pillarH / 2   -- pillar centre
	local halfSX   = baseSX / 2
	local halfSZ   = baseSZ / 2
	local inset    = pillarS / 2

	local corners = {
		{ name = "CornerPostNE_V", dx =  (halfSX - inset), dz =  (halfSZ - inset) },
		{ name = "CornerPostNW_V", dx = -(halfSX - inset), dz =  (halfSZ - inset) },
		{ name = "CornerPostSE_V", dx =  (halfSX - inset), dz = -(halfSZ - inset) },
		{ name = "CornerPostSW_V", dx = -(halfSX - inset), dz = -(halfSZ - inset) },
	}

	for _, corner in ipairs(corners) do
		local px = cx + corner.dx
		local pz = cz + corner.dz

		newPart(plotModel, corner.name,
			Vector3.new(pillarS, pillarH, pillarS),
			COLOR_PILLAR, Enum.Material.SmoothPlastic,
			CFrame.new(px, pillarY, pz))

		-- Neon cap
		newPart(plotModel, corner.name .. "Cap",
			Vector3.new(pillarS + 0.1, 0.2, pillarS + 0.1),
			COLOR_NEON_CAP, Enum.Material.Neon,
			CFrame.new(px, pillarY + pillarH / 2 + 0.1, pz))
	end

	-- Invisible sign post at plot centre
	local signPostCF = CFrame.new(cx, cy + 3, cz)
	local signPost   = newPart(plotModel, "SignPost_V",
		Vector3.new(0.1, 6, 0.1),
		Color3.new(0, 0, 0), Enum.Material.SmoothPlastic,
		signPostCF)
	signPost.Transparency = 1

	-- BillboardGui ownership sign
	local ownerSign = Instance.new("BillboardGui")
	ownerSign.Name        = "OwnerSign_V"
	ownerSign.Size        = UDim2.new(8, 0, 3, 0)  -- stud-based: shrinks naturally with distance
	ownerSign.StudsOffset = Vector3.new(0, 3, 0)
	ownerSign.AlwaysOnTop = false
	ownerSign.Parent      = signPost

	local plotLabel = Instance.new("TextLabel")
	plotLabel.Name                  = "PlotLabel"
	plotLabel.Size                  = UDim2.new(1, 0, 0.45, 0)
	plotLabel.Position              = UDim2.new(0, 0, 0, 0)
	plotLabel.Text                  = "PLOT " .. plotId
	plotLabel.TextScaled            = true
	plotLabel.Font                  = Enum.Font.GothamBold
	plotLabel.BackgroundTransparency = 1
	plotLabel.TextColor3            = COLOR_PLOT_TITLE
	plotLabel.Parent                = ownerSign

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name                  = "StatusLabel"
	statusLabel.Size                  = UDim2.new(1, 0, 0.55, 0)
	statusLabel.Position              = UDim2.new(0, 0, 0.45, 0)
	statusLabel.Text                  = "UNCLAIMED"
	statusLabel.TextScaled            = true
	statusLabel.Font                  = Enum.Font.GothamBold
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3            = COLOR_UNCLAIMED
	statusLabel.Parent                = ownerSign

	signRefs[plotId] = { statusLabel = statusLabel, base = base }
end

-- ============================================================
-- PUBLIC API
-- ============================================================

--- Decorate all Plot models found in Workspace.Plots.
function PlotVisuals.init()
	local plotsFolder = workspace:WaitForChild("Plots", 10) :: Folder?
	if not plotsFolder then
		warn("[PlotVisuals] No 'Plots' folder found in Workspace!")
		return
	end

	local function tryDecorate(child: Instance)
		if child:IsA("Model") and child:GetAttribute("PlotId") then
			decoratePlot(child :: Model)
		end
	end

	-- Decorate plots already present
	for _, child in ipairs(plotsFolder:GetChildren()) do
		tryDecorate(child)
	end

	-- Decorate plots created later by the setup script (race condition)
	plotsFolder.ChildAdded:Connect(tryDecorate)

	print("[PlotVisuals] Plot watcher started.")
end

--- Update sign to show owner name (green) and tint base dark-green.
---@param plotId number
---@param playerName string
function PlotVisuals.updatePlotClaimed(plotId: number, playerName: string)
	local refs = signRefs[plotId]
	if not refs then return end
	refs.statusLabel.Text       = playerName
	refs.statusLabel.TextColor3 = COLOR_CLAIMED
	refs.base.Color             = COLOR_SLATE_CLAIMED
end

--- Reset sign to "UNCLAIMED" (red) and restore base to dark-slate.
---@param plotId number
function PlotVisuals.updatePlotReleased(plotId: number)
	local refs = signRefs[plotId]
	if not refs then return end
	refs.statusLabel.Text       = "UNCLAIMED"
	refs.statusLabel.TextColor3 = COLOR_UNCLAIMED
	refs.base.Color             = COLOR_SLATE
end

return PlotVisuals
