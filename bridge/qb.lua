if grs.Framework ~= 'qb' then return end
if not (GetResourceState('oxmysql') == 'started') then return end

local namatable = grs.CustomDatabase.namatable or 'player_vehicles'
local kolom_garasi = grs.CustomDatabase.garasi or 'garage'
local kolom_posisi = grs.CustomDatabase.posisi or 'state'


Framework = {}
DB = {}

oxmysql = exports.oxmysql
sqlsync = function(query, array)
    if not oxmysql then
        oxmysql = exports.oxmysql
    end
    return oxmysql:executeSync(query, array)
end

if (GetResourceState('qbx_core') == 'started') then
    Framework.Object = exports['qb-core']:GetCoreObject()
else
    Framework.Object = exports[grs.NamaResourceFramework]:GetCoreObject()
end

Framework.GetPlayerFromId = Framework.Object.Functions.GetPlayer
Framework.GetPlayerData = Framework.Object.Functions.GetPlayerData
Framework.GetAllPlayers = Framework.Object.GetQBPlayers

Framework.SharedVehicles = {}

Framework.Notify = function(msg, tipe, durasi)
    return Framework.Object.Functions.Notify(msg, tipe, durasi)
end exports('Notify', Framework.Notify)

Framework.GetJob = function(src)
    return IsDuplicityVersion() and Framework.GetPlayerFromId(src).PlayerData.job or Framework.GetPlayerData().job
end exports('GetJob', Framework.GetJob)

Framework.GetGang = function(src)
    return IsDuplicityVersion() and Framework.GetPlayerFromId(src).PlayerData.gang or Framework.GetPlayerData().gang
end

Framework.Identifier = function(src)
    return IsDuplicityVersion() and Framework.GetPlayerFromId(src).PlayerData.citizenid or Framework.GetPlayerData().citizenid
end

Framework.License = function(src)
    return IsDuplicityVersion() and Framework.GetPlayerFromId(src).PlayerData.license or Framework.GetPlayerData().license
end

Framework.cekAkses = function(data)
    for i=1, #data do
        if data[i] == Framework.GetJob().name then
            return true
        end
        if data[i] == Framework.GetGang().name then
            return true
        end
        if data[i] == Framework.Identifier() then
            return true
        end
        if data[i] == Framework.License() then
            return true
        end
    end
end exports('CekAkses', Framework.cekAkses)

Framework.SetMeta = function(src, key, value)
    local pd = Framework.GetPlayerFromId(src)
    pd.Functions.SetMetaData(key, value)
end

Framework.GetMeta = function(src, key)
    if IsDuplicityVersion() then
        local pd = Framework.GetPlayerFromId(src)
        return pd.Functions.GetMetaData(key)
    else
        return Framework.GetPlayerData().metadata[src]
    end
end

Framework.Admin = function(src)
    if Framework.Object.Functions.HasPermission(src, 'admin') then
        return true
    end
end

Framework.JobTerganti = function(fungsi)
    RegisterNetEvent(grs.EventFramework..'Client:OnJobUpdate', function(JobInfo)
        fungsi(JobInfo)
    end)
end

Framework.GangTerganti = function(fungsi)
    RegisterNetEvent(grs.EventFramework..'Client:OnGangUpdate', function(JobInfo)
        fungsi(JobInfo)
    end)
end

Framework.GetBiayaAsuransi = function(model)
    return grs.BiayaAsuransi and ((Framework.SharedVehicles[model] and Framework.SharedVehicles[model].price or grs.DefaultPrice) * grs.BiayaAsuransi) or grs.FlatAsuransi
end

Framework.RemoveMoney = function(pd, acc, money)
    return pd.Functions.RemoveMoney(acc, money)
end

function Framework.startloaded(fungsi)
    AddEventHandler('onResourceStart', function()
        if (GetCurrentResourceName() ~= 'fmid_garasi') then
          return
        end
        fungsi()
    end)
    AddEventHandler(grs.EventFramework..'Client:OnPlayerLoaded', function()
        fungsi()
    end)
end

if (GetResourceState('ox_inventory') == 'started') then
    Framework.Items = {}
    for item, data in pairs(exports.ox_inventory:Items()) do
        Framework.Items[item] = data.label
    end
end

DB.SetVehicleState = function(plate, state)
    exports.oxmysql:executeSync('update '..namatable..' set '..kolom_posisi..' = ? where plate = ?', {state, plate})
    return true
end exports('SetVehicleState', DB.SetVehicleState)

DB.SaveVehicleProperties = function(src)
    local veh = Utils.veh(src)
    if veh then
        local gvp = json.encode(veh.gvp())
        local plate = veh.getplate()
        local up = oxmysql:executeSync('update '..namatable..' set mods = ? where plate = ?', {gvp, plate})
        return true
    end
end exports('SaveVehicleProperties', DB.SaveVehicleProperties)

DB.SaveKerusakan = function(src)
    local veh = Utils.veh(src)
    if veh then
        local plate = veh.getplate()
        local gvp = oxmysql:executeSync('select mods from '..namatable..' where plate = ?', {plate})
        gvp = json.decode(gvp[1].mods)
        local rusaknya = veh.getKerusakan()
        gvp.tyreBurst = rusaknya.tyreBurst
        gvp.doorsBroken = rusaknya.doorsBroken
        gvp.windowsBroken = rusaknya.windowsBroken
        local up = oxmysql:executeSync('update '..namatable..' set mods = ? where plate = ?', {json.encode(gvp), plate})
        return true
    end
end exports('SaveKerusakan', DB.SaveKerusakan)

DB.MasukGarasi = function(src, data)
    local veh = Utils.veh(src)
    if veh then
        local query = 'update %s set %s = 1, %s = ?, engine = ?, body = ?, fuel = ? where plate = ?'
        local lanjut = not grs.SaveVehicleProperties
        local saveRusak = DB.SaveKerusakan(src)
        if saveRusak then
            if grs.SaveVehicleProperties then
                local SaveP = DB.SaveVehicleProperties(src)
                if SaveP then
                    lanjut = true
                end
            end
            if lanjut then
                query = query:format(namatable, kolom_posisi, kolom_garasi)
                local engine, body, fuel, plate = veh.getengine(), veh.getbody(), veh.getfuel(), veh.getplate()
                local vehData = {engine = engine, body = body, fuel = fuel, plate = plate, vehicle = vehicle}
                TriggerClientEvent('fmid_garasi:beforeVehicleStored', src, vehData)
                local up = oxmysql:executeSync(query, {data.garage, engine, body, fuel, plate})
                if data.deleteEntity then veh.delete() end
                TriggerClientEvent('fmid_garasi:afterVehicleStored', src, vehData)
                return true
            end
        end
    end
end

DB.KeluarGarasi = function(src, data)
    local get = DB.GetGarasiByPlate(src, {plate = data.plate, garage = data.garage, state = 1})
    local res = sqlsync('update '.. namatable ..' set '.. kolom_posisi ..' = 0 where plate = ?', {data.plate})
    if get and res then
        local spveh = Utils.SpawnVehicle(src, get.vehicle, false, true)
        local vehData = {meta = get, data = data}
        if spveh then
            local veh = Utils.veh(src, spveh)
            if veh then
                veh.warp()
                veh.setplate(data.plate)
                veh.svp(json.decode(get.mods))
                veh.setengine(tonumber(get.engine) + 0.0)
                veh.setbody(tonumber(get.body) + 0.0)
                veh.setfuel(tonumber(get.fuel))
                TriggerClientEvent('fmid_garasi:onVehicleSpawned', src, vehData)
                return true
            end
        end
    end
end


DB.LangsungKeluar = function(src, plate)
    local get = DB.GetVehDataByPlate(plate)
    local spveh = Utils.SpawnVehicle(src, get.vehicle, false, true)
    local vehData = {meta = get, data = data or plate or nil}
    if spveh then
        local veh = Utils.veh(src, spveh)
        if veh then
            veh.warp()
            veh.setplate(plate)
            veh.svp(json.decode(get.mods))
            veh.setengine(tonumber(get.engine) + 0.0)
            veh.setbody(tonumber(get.body) + 0.0)
            veh.setfuel(tonumber(get.fuel))
            TriggerClientEvent('fmid_garasi:onVehicleSpawned', src, vehData)
            return true
        end
    end
end exports('LangsungKeluar', DB.LangsungKeluar)

DB.InsertKendaraan = function(src)
    local veh = Utils.veh(src)
    local pd = Framework.GetPlayerFromId(src)
    local engine, body, fuel, plate, mods = veh.getengine(), veh.getbody(), veh.getfuel(), veh.getplate(), json.encode(veh.gvp())
    local get = DB.GetVehDataByPlate(plate)
    if not get then
        local vh = GetVehiclePedIsIn(GetPlayerPed(src), false)
        local model = nil
        local hash = nil
        for a,b in pairs(Framework.Object.Shared.Vehicles) do
            if b.hash == GetEntityModel(vh) then
                model = b.model
                hash = b.hash
            end
        end
        if model and hash then
            local inst = exports.oxmysql:executeSync('INSERT INTO '..namatable..' ('..kolom_garasi..', '..kolom_posisi..', mods, plate, engine, body, fuel, license, citizenid, vehicle, hash) VALUES (?, 0, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                grs.defaultGarasi, 
                mods, 
                plate, 
                engine, 
                body, 
                fuel, 
                pd.PlayerData.license, 
                pd.PlayerData.citizenid, 
                model, 
                hash
            })
            return inst.affectedRows == 1 and true or false
        else
            return false, 'Kendaraan tidak ditemukan!'
        end
    else
        return false, 'Kendaraan sudah dimiliki orang lain!'
    end
end

DB.RemoveKendaraan = function(src)
    local veh = Utils.veh(src)
    local pd = Framework.GetPlayerFromId(src)
    local plate = veh.getplate()
    local vData = DB.GetVehDataByPlate(plate)
    if vData then
        local yakin = lib.callback.await('fmid_garasi:konfirmasi', src, {
            header = 'KONFIRMASI REMOVE KENDARAAN',
            content = 'Apakah kamu yakin ingin delete kepemilikan kendaraan ini?',
            centered = true,
            cancel = true
        })
        if yakin then
            exports.oxmysql:executeSync('delete from '..namatable..' where plate = ?', {plate})
            return true
        else
            return false, 'digagalkan'
        end
    end
end

DB.GetVehData = function(src)
    local veh = Utils.veh(src)
    local plate = veh.getplate()
    local result = sqlsync('select mods, engine, body, fuel, vehicle, trunk, '.. kolom_posisi ..', '.. kolom_garasi ..', citizenid from '.. namatable ..' where plate = ?', {plate})
    if result[1] then
        return result[1]
    end
end

DB.GetVehDataByPlate = function(plate)
    local result = sqlsync('select mods, engine, body, fuel, vehicle, trunk, '.. kolom_posisi ..', '.. kolom_garasi ..', citizenid from '.. namatable ..' where plate = ?', {plate})
    if result[1] then
        return result[1]
    end
end

DB.GetGarasiByPlate = function(src, data)
    local pd = Framework.GetPlayerFromId(src)
    local cid = pd.PlayerData.citizenid
    local query = ''
    local array = nil
    if data.garage:sub(1, 7) == 'garasi_' then
        query = 'select mods, engine, body, fuel, vehicle, trunk from '.. namatable ..' where plate = ? and '.. kolom_garasi ..' = ? and citizenid = ? and '.. kolom_posisi ..' = ?'
        array = {data.plate, garasi or data.garage, cid, data.state}
    else
        if grs.lokasi[data.garage].tanpaIdentifier then
            query = 'select mods, engine, body, fuel, vehicle, trunk from '.. namatable ..' where plate = ? and '.. kolom_garasi ..' = ? and '.. kolom_posisi ..' = ?'
            array = {data.plate, garasi or data.garage, data.state}
        else
            query = 'select mods, engine, body, fuel, vehicle, trunk from '.. namatable ..' where plate = ? and '.. kolom_garasi ..' = ? and citizenid = ? and '.. kolom_posisi ..' = ?'
            array = {data.plate, garasi or data.garage, cid, data.state}
        end
    end
    local result = sqlsync(query, array)
    if result[1] then
        return result[1]
    end
end

DB.GetGarasiByGarage = function(src, data)
    local pd = Framework.GetPlayerFromId(src)
    local cid = pd.PlayerData.citizenid
    local query = ''
    local array = nil
    local garasi = nil
    if data.garage:sub(1, 7) == 'garasi_' then
        query = 'select mods, engine, body, fuel, vehicle, trunk, plate from '.. namatable ..' where '.. kolom_garasi ..' = ? and citizenid = ? and '.. kolom_posisi ..' = ?'
        array = {data.garage, cid, data.state}
    else
        if grs.lokasi[data.garage].tanpaIdentifier then
            query = 'select mods, engine, body, fuel, vehicle, trunk, plate from '.. namatable ..' where '.. kolom_garasi ..' = ? and '.. kolom_posisi ..' = ?'
            array = {data.garage, data.state}
        else
            query = 'select mods, engine, body, fuel, vehicle, trunk, plate from '.. namatable ..' where '.. kolom_garasi ..' = ? and citizenid = ? and '.. kolom_posisi ..' = ?'
            array = {data.garage, cid, data.state}
        end
    end
    local result = sqlsync(query, array)
    if result[1] then
        for i=1, #result do
            result[i].namakendaraan = Framework.SharedVehicles[GetHashKey(result[i].vehicle)] and Framework.SharedVehicles[GetHashKey(result[i].vehicle)].name or (grs.defaultKendaraanLabel == 'hash' and veh.model or grs.defaultKendaraanLabel)
        end
        return result
    end
end

DB.GetAsuransi = function(src)
    local pd = Framework.GetPlayerFromId(src)
    local cid = pd.PlayerData.citizenid
    local result = sqlsync('select mods, engine, body, fuel, vehicle, trunk, plate from '.. namatable ..' where citizenid = ? and '.. kolom_posisi ..' = 0', {cid})
    if result[1] then
        for i=1, #result do
            result[i].namakendaraan = Framework.SharedVehicles[GetHashKey(result[i].vehicle)] and Framework.SharedVehicles[GetHashKey(result[i].vehicle)].name or (grs.defaultKendaraanLabel == 'hash' and veh.model or grs.defaultKendaraanLabel)
            result[i].price = Framework.SharedVehicles[GetHashKey(result[i].vehicle)] and Framework.SharedVehicles[GetHashKey(result[i].vehicle)].price or grs.DefaultPrice
        end
        return result
    end
end

DB.GarasiRealtime = function()
    return sqlsync('select * from garasi_realtime')
end

DB.InsertGarasi = function(data, nama)
    sqlsync('insert into garasi_realtime (data, nama) values (?,?)', {json.encode(data), nama.name})
    return true
end

DB.RemoveGarasi = function(key)
    sqlsync('delete from garasi_realtime where nama = ?', {key})
    return true
end

DB.AddAksesGarasi = function(id, nama)
    local data = sqlsync('select data from garasi_realtime where nama = ?', {nama})
    if data[1] then
        local dt = json.decode(data[1].data)
        if dt.akses then
            dt.akses[#dt.akses+1] = id
            sqlsync('update garasi_realtime set data = ? where nama = ?', {json.encode(dt), nama})
            return true
        else
            dt.akses = {}
            dt.akses[#dt.akses+1] = id
            sqlsync('update garasi_realtime set data = ? where nama = ?', {json.encode(dt), nama})
            return true
        end
    end
end

DB.RemoveAksesGarasi = function(id, nama)
    local data = sqlsync('select data from garasi_realtime where nama = ?', {nama})
    if data[1] then
        local dt = json.decode(data[1].data)
        for i=1, #dt.akses do
            if dt.akses[i] == id then
                dt.akses[i] = ''
            end
        end
        sqlsync('update garasi_realtime set data = ? where nama = ?', {json.encode(dt), nama})
        return true
    end
end

DB.GetAllMyVeh = function(id)
    local data = sqlsync('select plate from '..namatable..' where citizenid = ?', {id})
    if data[1] then
        local dt = {}
        for i=1, #data do
            dt[#dt+1] = data[i].plate
        end
        return dt
    end
end exports('GetAllMyVeh', DB.GetAllMyVeh)

DB.GetAllMyVehFilter = function(id, key, value)
    local data = sqlsync('select plate from '..namatable..' where citizenid = ? and '..key..' = ?', {id, value})
    if data[1] then
        local dt = {}
        for i=1, #data do
            dt[#dt+1] = data[i].plate
        end
        return dt
    end
end exports('GetAllMyVehFilter', DB.GetAllMyVehFilter)

DB.GetAllVehFilter = function(key, value)
    local data = sqlsync('select plate from '..namatable..' where '..key..' = ?', {value})
    if data[1] then
        local dt = {}
        for i=1, #data do
            dt[#dt+1] = data[i].plate
        end
        return dt
    end
end exports('GetAllVehFilter', DB.GetAllVehFilter)

RandomPlate = function(pattern)
    local random = Utils.GenerateRandomPlate(pattern or grs.formatPlate)
    local data = sqlsync('select plate from '..namatable..' where plate = ?', {random})
    if data[1] then
        RandomPlate(pattern)
    else
        return random
    end
end
DB.RandomPlate = RandomPlate
exports('RandomPlate', DB.RandomPlate)

AddEventHandler('onResourceStart', function()
    if (GetCurrentResourceName() ~= 'fmid_garasi') then
      return
    end
    if IsDuplicityVersion() then
        sqlsync("CREATE TABLE IF NOT EXISTS `garasi_realtime` (`id` int(11) NOT NULL AUTO_INCREMENT, `nama` varchar(50) DEFAULT NULL, `data` longtext NOT NULL DEFAULT '[]', PRIMARY KEY (`id`))")
        sqlsync("ALTER TABLE "..namatable.." ADD COLUMN IF NOT EXISTS `engine` INT(11) NOT NULL DEFAULT '1000';")
        sqlsync("ALTER TABLE "..namatable.." ADD COLUMN IF NOT EXISTS `body` INT(11) NOT NULL DEFAULT '1000';")
        sqlsync("ALTER TABLE "..namatable.." ADD COLUMN IF NOT EXISTS `fuel` INT(11) NOT NULL DEFAULT '100';")
        sqlsync("ALTER TABLE "..namatable.." ADD COLUMN IF NOT EXISTS `trunk` longtext;")
    end
end)

for model, data in pairs(Framework.Object.Shared.Vehicles) do
    Framework.SharedVehicles[data.hash] = data
end

exports('SharedVehicles', function()
    return Framework.SharedVehicles
end)