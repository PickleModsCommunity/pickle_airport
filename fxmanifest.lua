fx_version "cerulean"
game "gta5"
version "1.1.3"
shared_scripts {
	"@ox_lib/init.lua",
	"config.lua",
	"bridge/**/shared.lua",
	"modules/**/shared.lua",
    "core/shared.lua"
}

client_scripts {
	"bridge/**/client.lua",
	"modules/**/client.lua",
    "core/client.lua"
}

server_scripts {
	"bridge/**/server.lua",
    "core/authority.lua",
	"modules/**/server.lua",
    "core/server.lua"
}

dependencies { 'ox_lib', '/onesync' }
lua54 'yes'
