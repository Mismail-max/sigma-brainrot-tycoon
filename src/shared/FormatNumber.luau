-- FormatNumber.luau
-- Converts a BigNum (or plain number/string) into a human-readable
-- currency string such as "$1.5T" or "$42.3Qa".

local BigNum = require(script.Parent.BigNum)

local FormatNumber = {}

-- Suffix table in ascending order of magnitude.
-- Each entry: { suffix, divisorString }
-- divisorString is the number of digits in the divisor minus one.
local SUFFIXES = {
    { suffix = "K",  zeros = 3  },
    { suffix = "M",  zeros = 6  },
    { suffix = "B",  zeros = 9  },
    { suffix = "T",  zeros = 12 },
    { suffix = "Qa", zeros = 15 },
    { suffix = "Qi", zeros = 18 },
    { suffix = "Sx", zeros = 21 },
    { suffix = "Sp", zeros = 24 },
    { suffix = "Oc", zeros = 27 },
    { suffix = "No", zeros = 30 },
    { suffix = "Dc", zeros = 33 },
}

--- Format a BigNum, number, or digit string into a display string.
--- Prepends "$" by default.
---@param value any  BigNum | number | string
---@param prefix string?  Defaults to "$"
---@return string
function FormatNumber.format(value: any, prefix: string?): string
    prefix = prefix or "$"

    local digits: string
    if type(value) == "table" and value.digits then
        digits = value.digits
    elseif type(value) == "number" then
        digits = tostring(math.floor(value))
    else
        digits = tostring(value):match("^%d+") or "0"
    end

    local len = #digits

    -- Find the appropriate suffix
    local chosenSuffix = nil
    local chosenZeros = 0
    for i = #SUFFIXES, 1, -1 do
        if len > SUFFIXES[i].zeros then
            chosenSuffix = SUFFIXES[i].suffix
            chosenZeros  = SUFFIXES[i].zeros
            break
        end
    end

    if not chosenSuffix then
        -- Less than 1K — show raw number
        return prefix .. digits
    end

    -- Extract the integer part and one decimal digit
    local intPart = digits:sub(1, len - chosenZeros)
    local decDigit = digits:sub(len - chosenZeros + 1, len - chosenZeros + 1) or "0"

    local display
    if decDigit == "0" or decDigit == "" then
        display = intPart
    else
        display = intPart .. "." .. decDigit
    end

    return prefix .. display .. chosenSuffix
end

--- Convenience alias — formats without the "$" prefix.
function FormatNumber.formatRaw(value: any): string
    return FormatNumber.format(value, "")
end

return FormatNumber
