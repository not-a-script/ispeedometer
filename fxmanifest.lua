fx_version 'cerulean'
game 'gta5'
use_fxv2_oal 'yes'
lua54 'yes'
author 'Akkariin'
description 'Edited by Sinyx & Space V for iDev'
support 'https://discord.gg/8ecXhFXqR4'
version '1.1'

files {
	'data/handling.meta',
	'data/vehicles.meta',
	'data/carvariations.meta',
	'ui/**/*.*',
	'ui/*.*'
}

client_scripts {
	'config.lua',
	'client.lua'
}

server_script 'server.lua'



data_file 'HANDLING_FILE' 'data/handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'
