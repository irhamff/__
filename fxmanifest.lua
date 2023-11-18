fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'irham // discord.fivem.id'
version '1.2.8'

shared_scripts {
    '@ox_lib/init.lua',
    'shared.lua',
    'data/etc.lua',
    'data/kendaraan.lua',
    'data/lokasi.lua',
    'bridge/*.lua',
} 
client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

dependecy {
    'fmid_poly'
}