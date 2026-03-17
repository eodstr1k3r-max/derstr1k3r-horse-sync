-- ============================================================
--  HorseSync - Client Script
--  Handles ped flags, NUI notifications, and chat suggestions
--  Developer: DerStr1k3r
-- ============================================================

-- ============================================================
--  State
-- ============================================================

local horsesync   = Config.DefaultEnabled
local lastPed     = -1
local lastSyncVal = nil

-- ============================================================
--  NUI helper
-- ============================================================

---@param message string
---@param style   string  "enabled" | "disabled" | "warning"
---@param duration number?
local function notify(message, style, duration)
    SendNUIMessage({
        type     = "horsesync:notify",
        message  = message,
        style    = style    or "enabled",
        duration = duration or Config.NotifyDuration,
    })
end

-- ============================================================
--  Ped flag helpers
-- ============================================================

local function applyFlags(ped)
    if not DoesEntityExist(ped) then return end
    if lastSyncVal == horsesync  then return end
    SetPedConfigFlag(ped, Config.FLAG_HORSE_NPCBEHAVIOR, horsesync)
    SetPedConfigFlag(ped, Config.FLAG_HORSE_SPEEDSYNC,   not horsesync)
    lastSyncVal = horsesync
end

local function resetFlags(ped)
    if not DoesEntityExist(ped) then return end
    SetPedConfigFlag(ped, Config.FLAG_HORSE_NPCBEHAVIOR, false)
    SetPedConfigFlag(ped, Config.FLAG_HORSE_SPEEDSYNC,   false)
end

local function printStatus(silent)
    local state = horsesync and "ENABLED" or "DISABLED"
    print(("[HorseSync] Horse speed sync is now %s%s^7"):format(
        horsesync and "^2" or "^1", state))
    if not silent then
        notify(("Horse speed sync is now <b>%s</b>"):format(state),
               horsesync and "enabled" or "disabled")
    end
end

local function forceReapply()
    lastSyncVal = nil
    applyFlags(PlayerPedId())
end

-- ============================================================
--  Network events  (server -> client)
-- ============================================================

RegisterNetEvent("horsesync:setState", function(newState)
    if type(newState) ~= "boolean" then return end
    if horsesync == newState        then return end
    horsesync = newState
    forceReapply()
    printStatus(false)
end)

RegisterNetEvent("horsesync:requestStatus", function()
    printStatus(false)
end)

RegisterNetEvent("horsesync:nuiNotify", function(message, style)
    if type(message) ~= "string" then return end
    notify(message, style or "warning")
end)

-- ============================================================
--  Chat input watcher -> NUI suggestions
--  We hook the chat resource's open/close/input events.
--  The chat resource fires these on the client:
--    "chat:open"    when the chat box opens
--    "chat:close"   when it closes
--  For the typed text we poll GetCurrentChat() each frame
--  while the chat is open.
-- ============================================================

local chatIsOpen = false

AddEventHandler("chat:open", function()
    chatIsOpen = true
end)

AddEventHandler("chat:close", function()
    chatIsOpen = false
    SendNUIMessage({ type = "horsesync:chatClose" })
end)

-- Poll the chat input each frame while chat is open
CreateThread(function()
    while true do
        if chatIsOpen then
            -- GetCurrentChat returns the current chat input string
            local input = GetCurrentChat()
            if input and #input > 0 then
                SendNUIMessage({ type = "horsesync:chatInput", input = input })
            else
                SendNUIMessage({ type = "horsesync:chatClose" })
            end
            Wait(0)
        else
            Wait(100)
        end
    end
end)

-- ============================================================
--  Main loop
-- ============================================================

CreateThread(function()
    repeat Wait(200) until DoesEntityExist(PlayerPedId())

    SetNuiFocus(false, false)
    printStatus(true)

    while true do
        local ped = PlayerPedId()
        if ped ~= lastPed then
            lastPed     = ped
            lastSyncVal = nil
        end
        applyFlags(ped)
        Wait(Config.LoopInterval)
    end
end)

-- ============================================================
--  Cleanup
-- ============================================================

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    resetFlags(PlayerPedId())
    print("[HorseSync] Resource stopped - flags reset to default.")
end)
