-- BigNum.luau
-- Custom arbitrary-precision non-negative integer library.
-- Stores digits as a plain decimal string (e.g. "12345").
-- Supports add, sub (clamped to 0), mul by Lua number scalar,
-- comparison (gt, gte, eq), tostring, and toNumber.

local BigNum = {}
BigNum.__index = BigNum

-- ============================================================
-- CONSTRUCTOR
-- ============================================================

--- Create a BigNum from a number or decimal string.
---@param value string|number
---@return BigNum
function BigNum.new(value: string | number): any
    local self = setmetatable({}, BigNum)
    local str = tostring(value or "0"):match("^%s*(.-)%s*$")  -- trim whitespace
    -- Strip leading zeroes, keep at least "0"
    str = str:match("^0*(.+)$") or "0"
    -- Validate: only digits allowed
    if not str:match("^%d+$") then
        warn("[BigNum] Invalid value '" .. tostring(value) .. "', defaulting to 0")
        str = "0"
    end
    self.digits = str
    return self
end

--- Zero constant shorthand
function BigNum.zero(): any
    return BigNum.new("0")
end

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================

-- Compare two digit strings (both already normalised).
-- Returns 1 if a > b, -1 if a < b, 0 if equal.
local function _cmp(a: string, b: string): number
    if #a ~= #b then
        return #a > #b and 1 or -1
    end
    if a == b then return 0 end
    return a > b and 1 or -1
end

-- Add two normalised digit strings.
local function _addStr(a: string, b: string): string
    -- Work right-to-left
    local result = {}
    local carry = 0
    local ia, ib = #a, #b
    while ia > 0 or ib > 0 or carry > 0 do
        local da = ia > 0 and (string.byte(a, ia) - 48) or 0
        local db = ib > 0 and (string.byte(b, ib) - 48) or 0
        local sum = da + db + carry
        carry = math.floor(sum / 10)
        table.insert(result, 1, tostring(sum % 10))
        ia = ia - 1
        ib = ib - 1
    end
    return table.concat(result)
end

-- Subtract b from a (assumes a >= b, both normalised strings).
local function _subStr(a: string, b: string): string
    local result = {}
    local borrow = 0
    local ia, ib = #a, #b
    while ia > 0 do
        local da = string.byte(a, ia) - 48
        local db = ib > 0 and (string.byte(b, ib) - 48) or 0
        local diff = da - db - borrow
        if diff < 0 then
            diff = diff + 10
            borrow = 1
        else
            borrow = 0
        end
        table.insert(result, 1, tostring(diff))
        ia = ia - 1
        ib = ib - 1
    end
    -- Remove leading zeros
    local str = table.concat(result):match("^0*(.+)$") or "0"
    return str
end

-- ============================================================
-- PUBLIC METHODS
-- ============================================================

--- Add another BigNum and return a new BigNum.
function BigNum:add(other: any): any
    return BigNum.new(_addStr(self.digits, other.digits))
end

--- Subtract another BigNum and return a new BigNum (clamped to 0).
function BigNum:sub(other: any): any
    if _cmp(self.digits, other.digits) <= 0 then
        return BigNum.zero()
    end
    return BigNum.new(_subStr(self.digits, other.digits))
end

--- Multiply by a Lua number scalar (must be a non-negative integer or float).
--- The result is truncated to an integer.
function BigNum:mul(scalar: number): any
    if scalar <= 0 then return BigNum.zero() end
    -- For large numbers use string multiplication; for small scalars use native
    -- conversion only if within safe integer range.
    local n = tonumber(self.digits)
    if n and n < 1e15 then
        -- Fast path: native number multiplication
        local result = math.floor(n * scalar)
        return BigNum.new(tostring(result))
    end
    -- Slow path: multiply digit string by integer part of scalar
    local intScalar = math.floor(scalar)
    local carry = 0
    local digits = self.digits
    local result = {}
    for i = #digits, 1, -1 do
        local prod = (string.byte(digits, i) - 48) * intScalar + carry
        carry = math.floor(prod / 10)
        table.insert(result, 1, tostring(prod % 10))
    end
    while carry > 0 do
        table.insert(result, 1, tostring(carry % 10))
        carry = math.floor(carry / 10)
    end
    local str = table.concat(result):match("^0*(.+)$") or "0"
    return BigNum.new(str)
end

--- Returns true if self > other.
function BigNum:gt(other: any): boolean
    return _cmp(self.digits, other.digits) == 1
end

--- Returns true if self >= other.
function BigNum:gte(other: any): boolean
    return _cmp(self.digits, other.digits) >= 0
end

--- Returns true if self == other.
function BigNum:eq(other: any): boolean
    return self.digits == other.digits
end

--- Returns the plain decimal string representation.
function BigNum:tostring(): string
    return self.digits
end

--- Converts to a Lua number (loses precision beyond ~15 digits).
function BigNum:toNumber(): number
    return tonumber(self.digits) or math.huge
end

-- Allow tostring() on the object directly
BigNum.__tostring = function(self)
    return self.digits
end

return BigNum
