-- GeneratorModels.luau
-- Builds themed generator Model instances from Luau code only (no external assets).
-- Public API: GeneratorModels.build(typeId, level) → Model

local GeneratorModels = {}

-- ============================================================
-- HELPERS
-- ============================================================

local function newPart(
	parent: Instance,
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	cf: CFrame,
	canCollide: boolean
): Part
	local p = Instance.new("Part")
	p.Name       = name
	p.Size       = size
	p.Color      = color
	p.Material   = material
	p.CFrame     = cf
	p.Anchored   = true
	p.CanCollide = canCollide
	if not canCollide then
		p.CastShadow = false
	end
	p.Parent = parent
	return p
end

local function newSphere(
	parent: Instance,
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	cf: CFrame
): Part
	local p = newPart(parent, name, size, color, material, cf, false)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent   = p
	return p
end

local function addLabel(part: Part, title: string, levelText: string)
	local bb = Instance.new("BillboardGui")
	bb.Name         = "GeneratorLabel"
	bb.Size         = UDim2.new(0, 150, 0, 55)
	bb.StudsOffset  = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop  = false
	bb.Parent       = part

	local row1 = Instance.new("TextLabel")
	row1.Name                  = "TitleLabel"
	row1.Size                  = UDim2.new(1, 0, 0.5, 0)
	row1.Position              = UDim2.new(0, 0, 0, 0)
	row1.Text                  = title
	row1.TextScaled            = true
	row1.Font                  = Enum.Font.GothamBold
	row1.BackgroundTransparency = 1
	row1.TextColor3            = Color3.new(1, 1, 1)
	row1.Parent                = bb

	local row2 = Instance.new("TextLabel")
	row2.Name                  = "LevelLabel"
	row2.Size                  = UDim2.new(1, 0, 0.5, 0)
	row2.Position              = UDim2.new(0, 0, 0.5, 0)
	row2.Text                  = levelText
	row2.TextScaled            = true
	row2.Font                  = Enum.Font.Gotham
	row2.BackgroundTransparency = 1
	row2.TextColor3            = Color3.fromRGB(255, 220, 50)
	row2.Parent                = bb
end

-- ============================================================
-- BUILDER REGISTRY
-- Each builder creates model parts and returns the topmost part
-- (used as the BillboardGui anchor).
-- PrimaryPart is always the base slab at local position (0, 0.25, 0).
-- ============================================================

local builders: { [string]: (model: Model, level: number) -> Part } = {}

-- ──────────────────────────────────────────────────────────
-- SigmaBasic: Electric blue humanoid
-- disc base → torso block → sphere head → neon cyan eyes
-- ──────────────────────────────────────────────────────────
builders.SigmaBasic = function(model: Model, _level: number): Part
	local blue     = Color3.fromRGB(30, 100, 255)
	local cyanNeon = Color3.fromRGB(0, 255, 255)

	-- Base (PrimaryPart) — wide flat disc slab
	local base = newPart(model, "Base",
		Vector3.new(6, 0.5, 6), blue, Enum.Material.SmoothPlastic,
		CFrame.new(0, 0.25, 0), true)
	model.PrimaryPart = base

	-- Torso
	newPart(model, "Torso",
		Vector3.new(2.5, 3, 2.5), blue, Enum.Material.SmoothPlastic,
		CFrame.new(0, 2.25, 0), false)

	-- Head (sphere)
	local head = newSphere(model, "Head",
		Vector3.new(2.2, 2.2, 2.2), blue, Enum.Material.SmoothPlastic,
		CFrame.new(0, 5, 0))

	-- Neon eye spheres
	newSphere(model, "EyeL",
		Vector3.new(0.4, 0.4, 0.4), cyanNeon, Enum.Material.Neon,
		CFrame.new(-0.5, 5.1, 1.0))
	newSphere(model, "EyeR",
		Vector3.new(0.4, 0.4, 0.4), cyanNeon, Enum.Material.Neon,
		CFrame.new(0.5, 5.1, 1.0))

	return head
end

-- ──────────────────────────────────────────────────────────
-- SkibidiFactory: Concrete gray + orange industrial building
-- building block → chimney stack (3 narrowing blocks)
-- → orange neon ring → yellow neon window panes
-- ──────────────────────────────────────────────────────────
builders.SkibidiFactory = function(model: Model, _level: number): Part
	local concrete  = Color3.fromRGB(140, 140, 130)
	local orangeNeon = Color3.fromRGB(255, 100, 0)
	local yellowNeon = Color3.fromRGB(255, 220, 0)

	-- Base (PrimaryPart)
	local base = newPart(model, "Base",
		Vector3.new(6, 0.5, 6), concrete, Enum.Material.SmoothPlastic,
		CFrame.new(0, 0.25, 0), true)
	model.PrimaryPart = base

	-- Main building block
	newPart(model, "Building",
		Vector3.new(5, 4, 5), concrete, Enum.Material.SmoothPlastic,
		CFrame.new(0, 2.5, 0), false)

	-- Chimney stack: 3 narrowing blocks
	newPart(model, "Chimney1",
		Vector3.new(1.5, 2, 1.5), concrete, Enum.Material.SmoothPlastic,
		CFrame.new(1.5, 5.5, 1.5), false)
	newPart(model, "Chimney2",
		Vector3.new(1.1, 1.5, 1.1), concrete, Enum.Material.SmoothPlastic,
		CFrame.new(1.5, 7.25, 1.5), false)
	local chimney3 = newPart(model, "Chimney3",
		Vector3.new(0.8, 1, 0.8), concrete, Enum.Material.SmoothPlastic,
		CFrame.new(1.5, 8.5, 1.5), false)

	-- Orange neon ring (flat slab around chimney base)
	newPart(model, "NeonRing",
		Vector3.new(2.8, 0.25, 2.8), orangeNeon, Enum.Material.Neon,
		CFrame.new(1.5, 4.6, 1.5), false)

	-- Yellow neon window panes on building front
	newPart(model, "WinL",
		Vector3.new(0.8, 0.8, 0.1), yellowNeon, Enum.Material.Neon,
		CFrame.new(-1, 2.5, 2.55), false)
	newPart(model, "WinR",
		Vector3.new(0.8, 0.8, 0.1), yellowNeon, Enum.Material.Neon,
		CFrame.new(1, 2.5, 2.55), false)
	newPart(model, "WinTop",
		Vector3.new(0.8, 0.8, 0.1), yellowNeon, Enum.Material.Neon,
		CFrame.new(0, 4, 2.55), false)

	return chimney3
end

-- ──────────────────────────────────────────────────────────
-- GrimaceLab: Deep purple + neon magenta flask lab
-- base → neck block → giant glass sphere (flask)
-- → inner neon sphere → cap block → floating bubble spheres
-- ──────────────────────────────────────────────────────────
builders.GrimaceLab = function(model: Model, _level: number): Part
	local purple     = Color3.fromRGB(60, 0, 100)
	local glassColor = Color3.fromRGB(160, 110, 210)
	local magenta    = Color3.fromRGB(255, 0, 200)

	-- Base (PrimaryPart)
	local base = newPart(model, "Base",
		Vector3.new(6, 0.5, 6), purple, Enum.Material.SmoothPlastic,
		CFrame.new(0, 0.25, 0), true)
	model.PrimaryPart = base

	-- Neck block
	newPart(model, "Neck",
		Vector3.new(1.5, 2, 1.5), purple, Enum.Material.SmoothPlastic,
		CFrame.new(0, 1.25, 0), false)

	-- Giant glass flask sphere
	newSphere(model, "Flask",
		Vector3.new(5, 5, 5), glassColor, Enum.Material.Glass,
		CFrame.new(0, 5, 0))

	-- Inner neon sphere
	newSphere(model, "InnerGlow",
		Vector3.new(2.5, 2.5, 2.5), magenta, Enum.Material.Neon,
		CFrame.new(0, 5, 0))

	-- Cap block on top
	local cap = newPart(model, "Cap",
		Vector3.new(2, 0.8, 2), purple, Enum.Material.SmoothPlastic,
		CFrame.new(0, 7.9, 0), false)

	-- Floating bubble spheres
	newSphere(model, "Bubble1",
		Vector3.new(0.7, 0.7, 0.7), magenta, Enum.Material.Neon,
		CFrame.new(-2.5, 7, 0.5))
	newSphere(model, "Bubble2",
		Vector3.new(0.5, 0.5, 0.5), magenta, Enum.Material.Neon,
		CFrame.new(2.2, 7.5, -0.8))
	newSphere(model, "Bubble3",
		Vector3.new(0.6, 0.6, 0.6), magenta, Enum.Material.Neon,
		CFrame.new(1.5, 8.5, 1.2))

	return cap
end

-- ──────────────────────────────────────────────────────────
-- RizzAcademy: Gold + ivory columned temple
-- steps → floor → 4 corner pillars → gold roof slab → neon dome
-- ──────────────────────────────────────────────────────────
builders.RizzAcademy = function(model: Model, _level: number): Part
	local gold     = Color3.fromRGB(255, 200, 0)
	local ivory    = Color3.fromRGB(240, 230, 200)
	local goldNeon = Color3.fromRGB(255, 230, 60)

	-- Base (PrimaryPart)
	local base = newPart(model, "Base",
		Vector3.new(7, 0.5, 7), gold, Enum.Material.SmoothPlastic,
		CFrame.new(0, 0.25, 0), true)
	model.PrimaryPart = base

	-- Steps (2 stacked slabs)
	newPart(model, "Step1",
		Vector3.new(6, 0.4, 6), ivory, Enum.Material.SmoothPlastic,
		CFrame.new(0, 0.7, 0), false)
	newPart(model, "Step2",
		Vector3.new(5, 0.4, 5), ivory, Enum.Material.SmoothPlastic,
		CFrame.new(0, 1.1, 0), false)

	-- Building floor
	newPart(model, "Floor",
		Vector3.new(4.5, 0.5, 4.5), ivory, Enum.Material.SmoothPlastic,
		CFrame.new(0, 1.55, 0), false)

	-- 4 thin gold pillar blocks at corners
	newPart(model, "PillarFL",
		Vector3.new(0.5, 3, 0.5), gold, Enum.Material.SmoothPlastic,
		CFrame.new(-1.75, 3.3, 1.75), false)
	newPart(model, "PillarFR",
		Vector3.new(0.5, 3, 0.5), gold, Enum.Material.SmoothPlastic,
		CFrame.new( 1.75, 3.3, 1.75), false)
	newPart(model, "PillarBL",
		Vector3.new(0.5, 3, 0.5), gold, Enum.Material.SmoothPlastic,
		CFrame.new(-1.75, 3.3, -1.75), false)
	newPart(model, "PillarBR",
		Vector3.new(0.5, 3, 0.5), gold, Enum.Material.SmoothPlastic,
		CFrame.new( 1.75, 3.3, -1.75), false)

	-- Gold roof slab
	newPart(model, "Roof",
		Vector3.new(4.5, 0.5, 4.5), gold, Enum.Material.SmoothPlastic,
		CFrame.new(0, 5.05, 0), false)

	-- Neon gold dome sphere
	local dome = newSphere(model, "Dome",
		Vector3.new(2.5, 2.5, 2.5), goldNeon, Enum.Material.Neon,
		CFrame.new(0, 6.55, 0))

	return dome
end

-- ──────────────────────────────────────────────────────────
-- TuahTower: Red gradient tower
-- 3 stacked blocks (each smaller) → 2 flat neon-red ring slabs
-- → large neon orange beacon sphere
-- ──────────────────────────────────────────────────────────
builders.TuahTower = function(model: Model, _level: number): Part
	local red1      = Color3.fromRGB(180, 20, 20)
	local red2      = Color3.fromRGB(220, 60, 20)
	local red3      = Color3.fromRGB(255, 100, 20)
	local redNeon   = Color3.fromRGB(255, 50, 0)
	local orangeNeon = Color3.fromRGB(255, 160, 0)

	-- Base (PrimaryPart)
	local base = newPart(model, "Base",
		Vector3.new(6, 0.5, 6), red1, Enum.Material.SmoothPlastic,
		CFrame.new(0, 0.25, 0), true)
	model.PrimaryPart = base

	-- Three stacked blocks (each smaller and lighter red)
	newPart(model, "Block1",
		Vector3.new(5, 3, 5), red1, Enum.Material.SmoothPlastic,
		CFrame.new(0, 2, 0), false)
	newPart(model, "Block2",
		Vector3.new(3.5, 2.5, 3.5), red2, Enum.Material.SmoothPlastic,
		CFrame.new(0, 4.75, 0), false)
	newPart(model, "Block3",
		Vector3.new(2.2, 2, 2.2), red3, Enum.Material.SmoothPlastic,
		CFrame.new(0, 7, 0), false)

	-- Two flat neon-red ring slabs
	newPart(model, "Ring1",
		Vector3.new(6.5, 0.3, 6.5), redNeon, Enum.Material.Neon,
		CFrame.new(0, 3.65, 0), false)
	newPart(model, "Ring2",
		Vector3.new(5, 0.3, 5), redNeon, Enum.Material.Neon,
		CFrame.new(0, 6.1, 0), false)

	-- Large neon orange beacon sphere
	local beacon = newSphere(model, "Beacon",
		Vector3.new(2, 2, 2), orangeNeon, Enum.Material.Neon,
		CFrame.new(0, 9.2, 0))

	return beacon
end

-- ──────────────────────────────────────────────────────────
-- MewingMansion: White + navy manor
-- wide base → main block → two side wings → navy roof
-- → neon blue window panes
-- ──────────────────────────────────────────────────────────
builders.MewingMansion = function(model: Model, _level: number): Part
	local white    = Color3.fromRGB(240, 240, 245)
	local navy     = Color3.fromRGB(20, 30, 100)
	local blueNeon = Color3.fromRGB(50, 100, 255)

	-- Base (PrimaryPart) — wide slab
	local base = newPart(model, "Base",
		Vector3.new(8, 0.5, 7), white, Enum.Material.SmoothPlastic,
		CFrame.new(0, 0.25, 0), true)
	model.PrimaryPart = base

	-- Main central block
	newPart(model, "MainBlock",
		Vector3.new(5, 4, 5), white, Enum.Material.SmoothPlastic,
		CFrame.new(0, 2.5, 0), false)

	-- Two shorter side wings
	newPart(model, "WingL",
		Vector3.new(2.5, 2.5, 4), white, Enum.Material.SmoothPlastic,
		CFrame.new(-3.75, 1.75, 0), false)
	newPart(model, "WingR",
		Vector3.new(2.5, 2.5, 4), white, Enum.Material.SmoothPlastic,
		CFrame.new( 3.75, 1.75, 0), false)

	-- Navy roof block
	local roof = newPart(model, "Roof",
		Vector3.new(5.5, 1, 5.5), navy, Enum.Material.SmoothPlastic,
		CFrame.new(0, 5, 0), false)

	-- Neon blue window panes (front facade + wings)
	newPart(model, "WinFL",
		Vector3.new(0.8, 1, 0.1), blueNeon, Enum.Material.Neon,
		CFrame.new(-1.2, 2.5, 2.55), false)
	newPart(model, "WinFR",
		Vector3.new(0.8, 1, 0.1), blueNeon, Enum.Material.Neon,
		CFrame.new( 1.2, 2.5, 2.55), false)
	newPart(model, "WinFMid",
		Vector3.new(0.8, 1, 0.1), blueNeon, Enum.Material.Neon,
		CFrame.new(0, 2.5, 2.55), false)
	newPart(model, "WinWL",
		Vector3.new(0.8, 1, 0.1), blueNeon, Enum.Material.Neon,
		CFrame.new(-3.75, 1.75, 2.05), false)
	newPart(model, "WinWR",
		Vector3.new(0.8, 1, 0.1), blueNeon, Enum.Material.Neon,
		CFrame.new( 3.75, 1.75, 2.05), false)

	return roof
end

-- ============================================================
-- PUBLIC BUILD FUNCTION
-- ============================================================

--- Build a themed generator model for the given typeId and level.
---@param typeId string   matches GeneratorData.ByTypeId key
---@param level  number
---@return Model
function GeneratorModels.build(typeId: string, level: number): Model
	local model = Instance.new("Model")
	model.Name  = typeId

	local builder = builders[typeId]
	if not builder then
		-- Unknown type: plain grey placeholder
		local base = newPart(model, "Base",
			Vector3.new(4, 0.5, 4),
			Color3.fromRGB(100, 100, 100), Enum.Material.SmoothPlastic,
			CFrame.new(0, 0.25, 0), true)
		model.PrimaryPart = base
		local body = newPart(model, "Body",
			Vector3.new(3, 3, 3),
			Color3.fromRGB(150, 150, 150), Enum.Material.SmoothPlastic,
			CFrame.new(0, 2, 0), false)
		addLabel(body, typeId, "Lv." .. level)
		return model
	end

	local topPart = builder(model, level)
	addLabel(topPart, typeId, "Lv." .. level)
	return model
end

return GeneratorModels
