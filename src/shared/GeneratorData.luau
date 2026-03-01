-- GeneratorData.luau
-- Defines all generator types available in the shop.
-- BaseCost and BaseIncome are BigNum-compatible decimal strings.

local GeneratorData = {}

-- Ordered list of generators (displayed in this order in the shop).
GeneratorData.Generators = {
    {
        TypeId      = "SigmaBasic",
        Name        = "Sigma Grindset",
        Description = "A lone sigma grinding 24/7. Never skips leg day.",
        BaseCost    = "500",
        BaseIncome  = "100",     -- per tick (5 seconds)
        ModelName   = "SigmaBasicModel",
    },
    {
        TypeId      = "SkibidiFactory",
        Name        = "Skibidi Factory",
        Description = "Mass-produces Skibidi content at industrial scale.",
        BaseCost    = "8000",
        BaseIncome  = "1500",
        ModelName   = "SkibidiFactoryModel",
    },
    {
        TypeId      = "GrimaceLab",
        Name        = "Grimace Shake Lab",
        Description = "Mysterious purple concoctions fuel maximum brain rot.",
        BaseCost    = "80000",
        BaseIncome  = "15000",
        ModelName   = "GrimaceLabModel",
    },
    {
        TypeId      = "RizzAcademy",
        Name        = "Rizz Academy",
        Description = "Teaching the ancient art of W rizz to the masses.",
        BaseCost    = "500000",
        BaseIncome  = "80000",
        ModelName   = "RizzAcademyModel",
    },
    {
        TypeId      = "TuahTower",
        Name        = "Hawk Tuah Tower",
        Description = "Spit on that thang and watch the coins flow in.",
        BaseCost    = "5000000",
        BaseIncome  = "700000",
        ModelName   = "TuahTowerModel",
    },
    {
        TypeId      = "MewingMansion",
        Name        = "Mewing Mansion",
        Description = "Hard mewing around the clock. Jawline = profit.",
        BaseCost    = "40000000",
        BaseIncome  = "5000000",
        ModelName   = "MewingMansionModel",
    },
}

-- Build a lookup table by TypeId for O(1) access.
GeneratorData.ByTypeId = {}
for _, gen in ipairs(GeneratorData.Generators) do
    GeneratorData.ByTypeId[gen.TypeId] = gen
end

--- Returns the cost to upgrade a generator from its current level.
--- Cost scales by 1.15^level.
---@param typeId string
---@param currentLevel number
---@return string  BigNum-compatible decimal string
function GeneratorData.getUpgradeCost(typeId: string, currentLevel: number): string
    local gen = GeneratorData.ByTypeId[typeId]
    if not gen then return "99999999999999" end
    local base = tonumber(gen.BaseCost) or 500
    local cost = math.floor(base * (1.15 ^ currentLevel))
    return tostring(cost)
end

--- Returns the income per tick at a given level.
--- Income scales by 1.10^level.
---@param typeId string
---@param level number
---@return string  BigNum-compatible decimal string
function GeneratorData.getIncomeAtLevel(typeId: string, level: number): string
    local gen = GeneratorData.ByTypeId[typeId]
    if not gen then return "0" end
    local base = tonumber(gen.BaseIncome) or 100
    local income = math.floor(base * (1.10 ^ (level - 1)))
    return tostring(income)
end

return GeneratorData
