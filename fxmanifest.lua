fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rr-3dwaypoint'
author 'rr'
description '3D waypoint HUD with a monochrome glassmorphism interface'
version '1.0.0'

ui_page 'html/index.html'

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}
