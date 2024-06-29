fx_version 'cerulean'
game 'gta5'

author 'inQer'
description 'iQ-Weather: A custom weather and time control script for ESX servers.'

shared_scripts {
	--'config.lua',
	--'Locales/*.lua',
	'@es_extended/imports.lua'
}

client_scripts {
    'Client/client.lua'
}
server_script 'Server/server.lua'

files {
    'weather_time.json'
}

dependencies {
    'es_extended',
    'ox_lib'
}
