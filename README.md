# derstr1k3r-horse-sync

> **Developer:** DerStr1k3r
> **Version:** 1.0.1
> **Game:** RedM (RDR3)

Synchronises horse speed and animation config flags for the local player ped.
The server is the single source of truth. All feedback uses a custom NUI overlay.
Player states persist across reconnects and server restarts via a local JSON file.

---

## Features

- Horse speed sync toggle per player
- Server-authoritative state with per-player persistence (JSON)
- State restored automatically on reconnect
- NUI notification overlay (bottom-right, RDR2 style)
- NUI command suggestion panel (appears while typing /horse in chat)
- Server console startup/shutdown banner with status info
- Automatic flag reset on respawn and resource stop
- txAdmin / console bulk control command

---

## Installation

1. Drop the `derstr1k3r-horse-sync` folder into your `resources` directory
2. Add to `server.cfg`:

```
ensure derstr1k3r-horse-sync
```

3. Start the server or run `start derstr1k3r-horse-sync` in txAdmin

---

## Configuration

Edit `config.lua` only. Do not touch any other file.

| Option | Default | Description |
|---|---|---|
| `Config.DefaultEnabled` | `true` | Sync state for first-time players |
| `Config.LoopInterval` | `500` | Client check interval in ms |
| `Config.NotifyDuration` | `4000` | NUI notification display time in ms |
| `Config.PersistenceEnabled` | `true` | Save and restore player states |
| `Config.FLAG_HORSE_NPCBEHAVIOR` | `319` | Ped flag ID - do not change |
| `Config.FLAG_HORSE_SPEEDSYNC` | `366` | Ped flag ID - do not change |

Override the default sync state at runtime in `server.cfg`:

```
set horsesync_enabled 1
```

---

## Commands

| Command | Who | Description |
|---|---|---|
| `/horsesync` | Any player | Toggle own sync on/off |
| `/horsesync on\|off` | Any player | Force sync on or off |
| `/horsesyncstatus` | Any player | Show own current sync state |
| `/horsesyncstatus` | Console / txAdmin | List all online players and their states |
| `/horsesyncall on\|off` | Console / txAdmin only | Set sync for all online players |

---

## Persistence

Player states are saved in `data/player_states.json` by license identifier.

- State is saved immediately on every change
- State is restored automatically when the player rejoins
- File is also written on resource stop as a safety flush
- Set `Config.PersistenceEnabled = false` to disable entirely

Example file content:

```json
{
  "license:a1b2c3d4e5f6...": true,
  "license:f6e5d4c3b2a1...": false
}
```

---

## NUI Overlay

**Notifications** appear bottom-right on every sync state change or error.
Three styles: green (enabled), red (disabled), yellow (warning).
Each notification includes a progress bar showing remaining display time.

**Command Suggestions** appear above the chat box when typing `/horse`.
Shows all matching commands with arguments and a short description.
The matching part of each command is highlighted in gold.

---

## File Structure

```
derstr1k3r-horse-sync/
|-- fxmanifest.lua              Resource manifest
|-- config.lua                  All settings - edit this file only
|-- README.md
|-- data/
|   `-- player_states.json      Persisted sync states (auto-generated)
|-- client/
|   `-- main.lua                Flag logic, NUI, chat watcher, net events
|-- server/
|   `-- main.lua                State, persistence, commands, lifecycle
`-- html/
    `-- index.html              NUI overlay (notifications + suggestions)
```

---

## Event Flow

```
Player types /horsesync
        |
        v
server/main.lua       validates, updates playerStates + savedStates
        |             writes data/player_states.json
        |
        v  TriggerClientEvent("horsesync:setState", src, newState)
        |
        v
client/main.lua       SetPedConfigFlag on local ped
        |
        v  SendNUIMessage({ type = "horsesync:notify", ... })
        |
        v
html/index.html       renders NUI notification
```

---

## License

Free to use and modify. Credit appreciated.
