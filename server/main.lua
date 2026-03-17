-- ============================================================
--  HorseSync - Server Script
--  State authority, commands, lifecycle, logging, persistence
--  Developer: DerStr1k3r
-- ============================================================

-- ============================================================
--  Helpers
-- ============================================================

--- Log a prefixed message to the server console.
---@param msg string
local function log(msg)
    print(("[HorseSync] %s"):format(msg))
end

--- Safely get a player's display name.
---@param src number
---@return string
local function playerName(src)
    return GetPlayerName(tostring(src)) or ("Player#%d"):format(src)
end

--- Send a NUI notification to a specific player via net event.
---@param src     number
---@param message string
---@param style   string  "enabled" | "disabled" | "warning"
local function nuiNotify(src, message, style)
    TriggerClientEvent("horsesync:nuiNotify", src, message, style)
end

--- Parse a command argument string into a boolean or nil (toggle).
---@param arg string|nil
---@return boolean|nil result, boolean valid
local function resolveArg(arg)
    if arg == nil                                    then return nil,   true  end
    if arg == "on"  or arg == "1" or arg == "true"  then return true,  true  end
    if arg == "off" or arg == "0" or arg == "false" then return false, true  end
    return nil, false
end

--- Get the primary identifier for a player (license preferred).
---@param src number
---@return string|nil
local function getIdentifier(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:find("^license:") then
            return id
        end
    end
    -- Fallback to first available identifier
    if GetNumPlayerIdentifiers(src) > 0 then
        return GetPlayerIdentifier(src, 0)
    end
    return nil
end

-- ============================================================
--  Persistence  (JSON file on disk)
-- ============================================================

local DATA_FILE = ("data/player_states.json")
local savedStates = {}   -- [identifier] = boolean

--- Load saved states from disk into memory.
local function loadFromDisk()
    if not Config.PersistenceEnabled then return end

    local file = LoadResourceFile(GetCurrentResourceName(), DATA_FILE)
    if not file or file == "" then
        savedStates = {}
        return
    end

    local ok, decoded = pcall(json.decode, file)
    if ok and type(decoded) == "table" then
        savedStates = decoded
        log(("Persistence: loaded %d saved state(s)."):format(
            (function() local n=0 for _ in pairs(savedStates) do n=n+1 end return n end)()))
    else
        log("Persistence: failed to parse JSON, starting fresh.")
        savedStates = {}
    end
end

--- Persist all current saved states to disk.
local function saveToDisk()
    if not Config.PersistenceEnabled then return end

    local ok, encoded = pcall(json.encode, savedStates)
    if not ok then
        log("Persistence: failed to encode JSON.")
        return
    end

    local written = SaveResourceFile(GetCurrentResourceName(), DATA_FILE, encoded, -1)
    if not written then
        log("Persistence: failed to write file.")
    end
end

--- Save a single player's state by identifier.
---@param identifier string
---@param state      boolean
local function savePlayerState(identifier, state)
    if not Config.PersistenceEnabled or not identifier then return end
    savedStates[identifier] = state
    saveToDisk()
end

--- Load a saved state for an identifier. Returns nil if not found.
---@param identifier string
---@return boolean|nil
local function loadPlayerState(identifier)
    if not Config.PersistenceEnabled or not identifier then return nil end
    return savedStates[identifier]
end

-- ============================================================
--  Runtime state  (server is the single source of truth)
-- ============================================================

local playerStates      = {}   -- [src]        = boolean
local playerIdentifiers = {}   -- [src]        = identifier string

--- Read the server-wide default from convar, falling back to Config.
---@return boolean
local function serverDefault()
    return GetConvarInt("horsesync_enabled", Config.DefaultEnabled and 1 or 0) == 1
end

--- Apply a new sync state to a player, notify their client, and persist.
---@param src      number
---@param newState boolean
local function setPlayerState(src, newState)
    playerStates[src] = newState
    TriggerClientEvent("horsesync:setState", src, newState)
    log(("%s (ID %d) -> sync %s"):format(
        playerName(src), src, newState and "ENABLED" or "DISABLED"))

    -- Persist by identifier
    local identifier = playerIdentifiers[src]
    if identifier then
        savePlayerState(identifier, newState)
    end
end

--- Get the current runtime state for a player (falls back to server default).
---@param src number
---@return boolean
local function getPlayerState(src)
    if playerStates[src] ~= nil then return playerStates[src] end
    return serverDefault()
end

-- ============================================================
--  Player lifecycle
-- ============================================================

AddEventHandler("playerJoining", function()
    local src        = source
    local identifier = getIdentifier(src)
    playerIdentifiers[src] = identifier

    -- Restore saved state, or fall back to server default
    local saved   = loadPlayerState(identifier)
    local initial = (saved ~= nil) and saved or serverDefault()

    playerStates[src] = initial

    if saved ~= nil then
        log(("Player %s (ID %d) joined - restored saved sync: %s"):format(
            playerName(src), src, initial and "ENABLED" or "DISABLED"))
    else
        log(("Player %s (ID %d) joined - sync initialised to %s (default)"):format(
            playerName(src), src, initial and "ENABLED" or "DISABLED"))
    end
end)

AddEventHandler("playerDropped", function(reason)
    local src = source
    log(("Player %s (ID %d) dropped (%s)."):format(
        playerName(src), src, reason))
    playerStates[src]      = nil
    playerIdentifiers[src] = nil
end)

-- ============================================================
--  Commands
-- ============================================================

--- /horsesync [on|off]
RegisterCommand("horsesync", function(src, args)
    if src == 0 then
        log("This command must be used in-game.")
        return
    end

    local arg             = args[1] and args[1]:lower()
    local newState, valid = resolveArg(arg)

    if not valid then
        nuiNotify(src, "Usage: /horsesync [on|off]", "warning")
        return
    end

    if newState == nil then
        newState = not getPlayerState(src)
    end

    if getPlayerState(src) == newState then
        nuiNotify(src,
            ("Sync is already <b>%s</b>."):format(newState and "ENABLED" or "DISABLED"),
            "warning")
        return
    end

    setPlayerState(src, newState)
end, false)

--- /horsesyncstatus
RegisterCommand("horsesyncstatus", function(src)
    if src == 0 then
        log("Current sync states:")
        if not next(playerStates) then
            log("  (no players online)")
            return
        end
        for id, state in pairs(playerStates) do
            log(("  [%3d] %-30s %s"):format(
                id, playerName(id), state and "ENABLED" or "DISABLED"))
        end
        return
    end

    TriggerClientEvent("horsesync:requestStatus", src)
end, false)

--- /horsesyncall [on|off]  -  txAdmin / console only
RegisterCommand("horsesyncall", function(src, args)
    if src ~= 0 then
        nuiNotify(src,
            "This command is only available via txAdmin or the server console.",
            "disabled")
        log(("Blocked /horsesyncall by %s (ID %d)."):format(playerName(src), src))
        return
    end

    local arg             = args[1] and args[1]:lower()
    local newState, valid = resolveArg(arg)

    if not valid or newState == nil then
        log("Usage: /horsesyncall [on|off]")
        return
    end

    local players = GetPlayers()
    if #players == 0 then
        log("No players online.")
        return
    end

    log(("Setting sync %s for all %d player(s)."):format(
        newState and "ENABLED" or "DISABLED", #players))

    for _, playerId in ipairs(players) do
        setPlayerState(tonumber(playerId), newState)
    end
end, false)

-- ============================================================
--  Startup / Shutdown
-- ============================================================

local function printBanner(starting)
    local action  = starting and "STARTED" or "STOPPED"
    local version = GetResourceMetadata(GetCurrentResourceName(), "version", 0) or "?"
    local line    = ("="):rep(52)
    print(("^5%s^7"):format(line))
    print(("^5  HorseSync ^7| ^3%s^7"):format(action))
    print(("^5  Version   ^7| ^3v%s^7"):format(version))
    print(("^5  Developer ^7| ^3DerStr1k3r^7"))
    if starting then
        local default = serverDefault()
        print(("^5  Sync      ^7| ^3%s^7"):format(default and "ENABLED" or "DISABLED"))
        print(("^5  Persist   ^7| ^3%s^7"):format(Config.PersistenceEnabled and "ENABLED" or "DISABLED"))
        print(("^5  Commands  ^7| ^3/horsesync  /horsesyncstatus  /horsesyncall^7"))
    end
    print(("^5%s^7"):format(line))
end

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    loadFromDisk()
    printBanner(true)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    saveToDisk()
    printBanner(false)
end)
