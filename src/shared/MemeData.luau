-- MemeData.luau
-- All brainrot characters and gacha rarities.
-- Cumulative weights out of 10000 total pool.

local MemeData = {}

-- ============================================================
-- RARITIES
-- Cumulative weights: Common=6000, Rare=8500, Epic=9700,
--                     Legendary=9980, Mythic=10000
-- ============================================================
MemeData.Rarities = {
    {
        Name              = "Common",
        Color             = Color3.fromRGB(180, 180, 180),
        CumulativeWeight  = 6000,
        PityThreshold     = 0,   -- no pity for Common
    },
    {
        Name              = "Rare",
        Color             = Color3.fromRGB(0, 120, 255),
        CumulativeWeight  = 8500,
        PityThreshold     = 0,
    },
    {
        Name              = "Epic",
        Color             = Color3.fromRGB(160, 0, 255),
        CumulativeWeight  = 9700,
        PityThreshold     = 0,
    },
    {
        Name              = "Legendary",
        Color             = Color3.fromRGB(255, 165, 0),
        CumulativeWeight  = 9980,
        PityThreshold     = 0,
    },
    {
        Name              = "Mythic",
        Color             = Color3.fromRGB(255, 50, 50),
        CumulativeWeight  = 10000,
        PityThreshold     = 50,  -- pity activates after 50 non-Mythic pulls
    },
}

MemeData.TOTAL_WEIGHT = 10000

-- Build lookup by name
MemeData.RarityByName = {}
for _, r in ipairs(MemeData.Rarities) do
    MemeData.RarityByName[r.Name] = r
end

-- ============================================================
-- CHARACTERS
-- Each character belongs to one rarity bucket.
-- IncomeMultiplier applies to the player's active generators
-- when this character is equipped (future feature hook).
-- ============================================================
MemeData.Characters = {
    -- COMMON (6 characters)
    {
        Name             = "Basic Sigma",
        Rarity           = "Common",
        Description      = "Just a regular guy grinding.",
        IncomeMultiplier = 1.0,
    },
    {
        Name             = "Skibidi Toilet",
        Rarity           = "Common",
        Description      = "Toilet head. Sigma mindset.",
        IncomeMultiplier = 1.0,
    },
    {
        Name             = "Npc Villager",
        Rarity           = "Common",
        Description      = "Background character. Unaware of the sigma grind.",
        IncomeMultiplier = 1.0,
    },
    {
        Name             = "Gyatt Goblin",
        Rarity           = "Common",
        Description      = "Small but relentless in the grind.",
        IncomeMultiplier = 1.0,
    },
    {
        Name             = "Rizz Noob",
        Rarity           = "Common",
        Description      = "Learning the ways of the rizz.",
        IncomeMultiplier = 1.0,
    },
    {
        Name             = "Sussy Baka",
        Rarity           = "Common",
        Description      = "Among us energy. Kinda suspicious.",
        IncomeMultiplier = 1.0,
    },

    -- RARE (4 characters)
    {
        Name             = "Ohio Warrior",
        Rarity           = "Rare",
        Description      = "Only in Ohio does he thrive.",
        IncomeMultiplier = 1.1,
    },
    {
        Name             = "No Cap King",
        Rarity           = "Rare",
        Description      = "Absolutely no cap on this grind.",
        IncomeMultiplier = 1.1,
    },
    {
        Name             = "Grimace Shake",
        Rarity           = "Rare",
        Description      = "Purple menace. Oddly profitable.",
        IncomeMultiplier = 1.15,
    },
    {
        Name             = "Rizz Master",
        Rarity           = "Rare",
        Description      = "Moderate rizz. Still training.",
        IncomeMultiplier = 1.1,
    },

    -- EPIC (3 characters)
    {
        Name             = "Hawk Tuah Girl",
        Rarity           = "Epic",
        Description      = "Spit on that thang. Iconic.",
        IncomeMultiplier = 1.25,
    },
    {
        Name             = "Chad Mewer",
        Rarity           = "Epic",
        Description      = "Jawline could cut diamonds. Mewing 24/7.",
        IncomeMultiplier = 1.3,
    },
    {
        Name             = "Fanum Tax Collector",
        Rarity           = "Epic",
        Description      = "The tax is inevitable. You will be fanummed.",
        IncomeMultiplier = 1.25,
    },

    -- LEGENDARY (2 characters)
    {
        Name             = "Ultimate Sigma",
        Rarity           = "Legendary",
        Description      = "Peak sigma performance. Alpha of alphas.",
        IncomeMultiplier = 1.5,
    },
    {
        Name             = "NPC Awakened",
        Rarity           = "Legendary",
        Description      = "The NPC has become self-aware. Very dangerous.",
        IncomeMultiplier = 1.5,
    },

    -- MYTHIC (2 characters)
    {
        Name             = "Skibidi God",
        Rarity           = "Mythic",
        Description      = "The original. The one. The only. Toilet supremacy.",
        IncomeMultiplier = 2.0,
    },
    {
        Name             = "Omega Rizz Lord",
        Rarity           = "Mythic",
        Description      = "Infinite rizz. Cannot be comprehended by mortals.",
        IncomeMultiplier = 2.0,
    },
}

-- Build lookup by name
MemeData.CharacterByName = {}
-- Build lookup by rarity for O(1) random selection
MemeData.CharactersByRarity = {}
for _, char in ipairs(MemeData.Characters) do
    MemeData.CharacterByName[char.Name] = char
    if not MemeData.CharactersByRarity[char.Rarity] then
        MemeData.CharactersByRarity[char.Rarity] = {}
    end
    table.insert(MemeData.CharactersByRarity[char.Rarity], char)
end

return MemeData
