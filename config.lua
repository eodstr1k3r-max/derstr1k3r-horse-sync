-- ============================================================
--  HorseSync - Config
--  Developer: DerStr1k3r
-- ============================================================

Config = {}

-- -- General ------------------------------------------------

-- Default sync state when the resource starts.
-- Can also be overridden in server.cfg:
--   set horsesync_enabled 1   (1 = on, 0 = off)
Config.DefaultEnabled = true

-- How often (ms) the client loop checks for ped changes.
-- Lower = more responsive  |  Higher = less CPU usage
-- Recommended: 300-1000
Config.LoopInterval = 500

-- -- NUI Notification ---------------------------------------

-- How long (ms) each NUI notification stays on screen.
Config.NotifyDuration = 4000

-- -- Persistence --------------------------------------------

-- Save each player's sync state to data/player_states.json.
-- State is restored automatically on reconnect.
-- Set to false to disable persistence entirely.
Config.PersistenceEnabled = true

-- -- Flag IDs (do not change unless RDR3 updates them) ------

Config.FLAG_HORSE_NPCBEHAVIOR = 319  -- NPC-style horse behaviour (disables player sync)
Config.FLAG_HORSE_SPEEDSYNC   = 366  -- Player horse speed synchronisation
