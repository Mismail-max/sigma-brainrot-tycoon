-- RemoteDefinitions.luau
-- Single source of truth for all RemoteEvents and RemoteFunctions.
-- Both server and client require this module to get references.
-- The server init script CREATES the Remotes; clients WAIT for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteDefinitions = {}

-- ============================================================
-- REMOTE CONTAINER
-- ============================================================
-- Remotes are stored under ReplicatedStorage.Remotes
local FOLDER_NAME = "Remotes"

--- Get or create the Remotes folder (called on server at startup).
function RemoteDefinitions.initServer(): Folder
    local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = FOLDER_NAME
        folder.Parent = ReplicatedStorage
    end

    -- Create RemoteEvents
    local events = {
        -- Client → Server
        "BuyGenerator",
        "CollectEarnings",
        "OpenCrate",
        "StealEarnings",
        "RequestRebirth",
        -- Server → Client
        "UpdateCurrency",
        "ShowFloatingText",
        "CrateResult",
        "NotifySteal",
        "ShieldStatusChanged",
        "UpdateLeaderboard",
    }
    for _, name in ipairs(events) do
        if not folder:FindFirstChild(name) then
            local re = Instance.new("RemoteEvent")
            re.Name = name
            re.Parent = folder
        end
    end

    -- Create RemoteFunctions
    local functions = {
        "GetPlotData",
        "GetLeaderboard",
    }
    for _, name in ipairs(functions) do
        if not folder:FindFirstChild(name) then
            local rf = Instance.new("RemoteFunction")
            rf.Name = name
            rf.Parent = folder
        end
    end

    return folder
end

--- Wait for the Remotes folder on the client side.
function RemoteDefinitions.waitForFolder(): Folder
    return ReplicatedStorage:WaitForChild(FOLDER_NAME, 30)
end

--- Get a RemoteEvent by name (waits for it if necessary).
---@param name string
---@return RemoteEvent
function RemoteDefinitions.getEvent(name: string): RemoteEvent
    local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME, 30)
    return folder:WaitForChild(name, 30) :: RemoteEvent
end

--- Get a RemoteFunction by name (waits for it if necessary).
---@param name string
---@return RemoteFunction
function RemoteDefinitions.getFunction(name: string): RemoteFunction
    local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME, 30)
    return folder:WaitForChild(name, 30) :: RemoteFunction
end

return RemoteDefinitions
