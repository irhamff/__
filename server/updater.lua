local updateLinks = {
    ['bridge/esx.lua'] = 'https://raw.githubusercontent.com/irhamff/__/main/bridge/esx.lua',
    ['bridge/qb.lua'] = 'https://raw.githubusercontent.com/irhamff/__/main/bridge/qb.lua',
    ['bridge/utils.lua'] = 'https://raw.githubusercontent.com/irhamff/__/main/bridge/utils.lua',
    ['client/client.lua'] = 'https://raw.githubusercontent.com/irhamff/__/main/client/client.lua',
    ['server/server.lua'] = 'https://raw.githubusercontent.com/irhagram/fmid_garasi/main/server/server.lua?token=GHSAT0AAAAAACKIM76GWWY5PYQJJENLU2IWZKYCG7Q',
    ['fxmanifest.lua'] = 'https://raw.githubusercontent.com/irhagram/fmid_garasi/main/fxmanifest.lua?token=GHSAT0AAAAAACKIM76HRHP62R72D2TVCTZCZKYCI2A',
}

local updateConfig = {
    ['data/etc.lua'] = 'https://raw.githubusercontent.com/irhagram/fmid_garasi/main/data/etc.lua?token=GHSAT0AAAAAACKIM76GM7NUAMBUEUB54QNOZKYCHNA',
    ['shared.lua'] = 'https://raw.githubusercontent.com/irhagram/fmid_garasi/main/shared.lua?token=GHSAT0AAAAAACKIM76HWR2DF4JOCQDPEKEGZKYCHVQ',
}

local sukses = 'https://raw.githubusercontent.com/irhagram/fmid_garasi/main/latest.lua?token=GHSAT0AAAAAACKIM76GRQDH6AYKIKOYIMR2ZKYC2QA'

local function updateNow()
    for k,v in pairs(updateLinks) do
        PerformHttpRequest(v, function (_, kode)
            SaveResourceFile(GetCurrentResourceName(), k, kode, -1)
        end)
    end
    return true
end

local function updateConfigNow()
    for k,v in pairs(updateConfig) do
        PerformHttpRequest(v, function (_, kode)
            SaveResourceFile(GetCurrentResourceName(), k, kode, -1)
        end)
    end
    return true
end

local function printSukses()
    PerformHttpRequest(sukses, function (status, body, headers, errorData)
        print(body)
    end)
end

RegisterCommand('update_garasi', function(a,b)
    if b[1] == 'y' then
        updateNow()
        updateConfigNow()
    else
        updateNow()
    end
    printSukses()
end)