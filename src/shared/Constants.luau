-- Constants.luau
-- All tunable game numbers in one place for easy balancing

local Constants = {}

-- ============================================================
-- ECONOMY
-- ============================================================
Constants.TICK_INTERVAL         = 5       -- seconds between income ticks
Constants.STEAL_FRACTION        = 0.25    -- fraction of uncollected earnings stolen
Constants.STEAL_COOLDOWN        = 10      -- seconds before same target can be stolen again
Constants.STEAL_MIN_UNCOLLECTED = "1000"  -- minimum uncollected earnings to be steal-able (BigNum string)

-- ============================================================
-- GACHA / PITY
-- ============================================================
Constants.PITY_THRESHOLD        = 50     -- pulls without Mythic before pity activates
Constants.PITY_MYTHIC_MULTIPLIER = 3     -- Mythic weight multiplied by this at pity
Constants.CRATE_COST            = "500"  -- BigNum string, cost per crate pull

-- ============================================================
-- REBIRTH
-- ============================================================
Constants.REBIRTH_REQUIREMENT   = "1000000"  -- BigNum string minimum TotalEarned
Constants.REBIRTH_MULTIPLIER_BONUS = 0.1     -- +10% income multiplier per rebirth

-- ============================================================
-- SHIELDS
-- ============================================================
Constants.SHIELD_DURATION       = 1800   -- seconds (30 minutes)

-- ============================================================
-- LEADERBOARD
-- ============================================================
Constants.LEADERBOARD_UPDATE_INTERVAL = 60    -- seconds between global board refresh
Constants.LEADERBOARD_TOP_COUNT       = 10    -- how many entries to show

-- ============================================================
-- MONETIZATION (replace 0 with real IDs after publishing)
-- ============================================================
Constants.DEV_PRODUCTS = {
    LuckBoost      = { Id = 0, Duration = 900 },    -- 15 min
    InstantRebirth = { Id = 0 },
    AntiLShield    = { Id = 0, Duration = 1800 },   -- 30 min
}

Constants.GAMEPASSES = {
    AutoCollect = { Id = 0 },
    SigmaAura   = { Id = 0, Multiplier = 1.5 },
}

-- ============================================================
-- FLOATING TEXT
-- ============================================================
Constants.FLOAT_POOL_SIZE       = 30     -- number of BillboardGui objects in pool
Constants.FLOAT_DURATION        = 1.5    -- seconds for float-up animation
Constants.FLOAT_RISE_STUDS      = 10     -- studs the text rises over duration

-- ============================================================
-- SESSION LOCK
-- ============================================================
Constants.SESSION_LOCK_TIMEOUT  = 60    -- seconds before stale lock is considered expired
Constants.DATASTORE_RETRY_WAIT  = 5     -- seconds between DataStore retry attempts
Constants.DATASTORE_MAX_RETRIES = 3     -- max DataStore retry attempts

-- ============================================================
-- ORDERED DATASTORE (leaderboard)
-- ============================================================
Constants.LEADERBOARD_MAX_SCORE = 2^53 - 1  -- max safe integer for OrderedDataStore

return Constants
