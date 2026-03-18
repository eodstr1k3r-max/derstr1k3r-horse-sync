-- ============================================================
--  fxmanifest.lua  -  HorseSync
-- ============================================================

fx_version 'cerulean'
games      { 'rdr3' }

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

name         'derstr1k3r-horse-sync'
description  'Synchronises horse speed / animation flags for the local player in RedM.'
author       'DerStr1k3r'
version      '1.0.1'

shared_scripts {
    'config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'data/player_states.json'
}
