-- Types.luau
-- Luau type annotations for Sigma Brainrot Tycoon

export type BigNum = {
    digits: string,
    isNegative: boolean,
    add: (self: BigNum, other: BigNum) -> BigNum,
    sub: (self: BigNum, other: BigNum) -> BigNum,
    mul: (self: BigNum, scalar: number) -> BigNum,
    gt: (self: BigNum, other: BigNum) -> boolean,
    eq: (self: BigNum, other: BigNum) -> boolean,
    tostring: (self: BigNum) -> string,
    toNumber: (self: BigNum) -> number,
}

export type GeneratorInfo = {
    TypeId: string,
    Name: string,
    Description: string,
    BaseCost: string,      -- BigNum string
    BaseIncome: string,    -- BigNum string per tick
    Model: string,         -- Model name in ReplicatedStorage
}

export type OwnedGenerator = {
    TypeId: string,
    Level: number,
    Income: string,        -- BigNum string (current income per tick)
    Uncollected: string,   -- BigNum string
}

export type MemeCharacter = {
    Name: string,
    Rarity: string,
    Weight: number,
    Description: string,
    IncomeMultiplier: number,
}

export type RarityInfo = {
    Name: string,
    Color: Color3,
    CumulativeWeight: number,
    PityThreshold: number,
}

export type PlayerData = {
    Currency: string,          -- BigNum string
    TotalEarned: string,       -- BigNum string (lifetime, for leaderboard)
    Generators: { [string]: OwnedGenerator },
    Brainrots: { string },     -- list of character names collected
    PityCounts: {
        Rare: number,
        Epic: number,
        Legendary: number,
        Mythic: number,
    },
    ShieldExpiry: number,      -- os.time() timestamp
    RebirthCount: number,
    Multiplier: number,        -- income multiplier from rebirths
    LuckBoostExpiry: number,   -- os.time() timestamp
    HasAutoCollect: boolean,
    HasSigmaAura: boolean,
    PlotId: number,
}

export type StealCooldown = {
    [string]: number,  -- targetUserId -> os.time() when cooldown expires
}

export type CrateResult = {
    Character: MemeCharacter,
    Rarity: string,
    IsNew: boolean,
}

return {}
