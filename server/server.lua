datakendaraan = require 'data/kendaraan'
lib.callback.register('fmid_garasi:garasi', function(source, tipe, plate, garasi)
    local src = source
    if tipe == 'return' then
        local rt = DB.GetGarasiByGarage(src, {garage = garasi, state = 1})
        if rt then
            return rt
        end
        return false, 'Tidak ada kendaraan di garasi ini!'
    elseif tipe == 'asuransi' then
        local ss = DB.GetAsuransi(src)
        if ss then
            local aa = Utils.KendaraanMasihDiluar(ss)
            return aa
        end
        return false, 'Data Kendaraan tidak ditemukan!'
    elseif tipe == 'keluar_asuransi' then
        local pd = Framework.GetPlayerFromId(src)
        local get = DB.GetVehDataByPlate(plate)
        if get then
            local state = get.state or get.stored
            if type(state) ~= 'number' then
                state = (state == false) and 0 or 1
            end
            local model = (get.state ~= nil) and GetHashKey(get.vehicle) or json.decode(get.vehicle).model
            if tonumber(state) == 0 then
                if Framework.RemoveMoney(pd, 'bank', Framework.GetBiayaAsuransi(model)) then
                    local spawned = DB.LangsungKeluar(src, plate)
                    if spawned then
                        return true, 'Berhasil membayar $'.. Utils.GroupDigits(Framework.GetBiayaAsuransi(model)) ..' untuk mengambil kendaraan '..(Framework.SharedVehicles[model] and Framework.SharedVehicles[model].name or model)..' dari Asuransi'
                    end
                    return false, 'Gagal keluar dari asuransi!'
                end
                return false, 'Kekurangan uang di dalam bank!'
            end
        end
        return false, 'Data Kendaraan tidak ditemukan!'
    elseif tipe == 'masuk' then
        local get = DB.GetVehDataByPlate(plate)
        if get then
            local id_saya = Framework.Identifier(src)
            local owner = get.citizenid or get.owner
            local state = get.state or get.stored
            if type(state) ~= 'number' then
                state = (state == false) and 0 or 1
            end
            if tonumber(state) == 0 then
                if garasi:sub(1,7) == 'garasi_' then
                    if owner == id_saya then
                        if DB.MasukGarasi(src, {garage = garasi, deleteEntity = true}) then
                            return true, 'Sukses masuk ke garasi!'
                        end
                    end
                else
                    if grs.lokasi[garasi].tanpaIdentifier then
                        if DB.MasukGarasi(src, {garage = garasi, deleteEntity = true}) then
                            return true, 'Sukses masuk ke garasi!'
                        end
                    else
                        if owner == id_saya then
                            if DB.MasukGarasi(src, {garage = garasi, deleteEntity = true}) then
                                return true, 'Sukses masuk ke garasi!'
                            end
                        end
                    end
                end
                return false, 'Kendaraan ini bukan milik anda!'

            else
                local veh = Utils.veh(src)
                if veh then
                    veh.delete()
                end
            end
        end
        return false, 'Data Kendaraan tidak ditemukan!'
    elseif tipe == 'keluar' then
        local spawn = DB.KeluarGarasi(src, {plate = plate, garage = garasi})
        if spawn then
            return true, 'Sukses keluar dari garasi'
        end
        return false, 'Gagal keluar dari garasi'
    end
    return false, 'Terjadi Kesalahan!'
end)

lib.callback.register('fmid_garasi:addCustomGarasi', function(source, name, data)
    if name and data then
        if not grs.lokasi[name] then
            grs.lokasi[name] = data
            TriggerClientEvent('fmid_garasi:refreshGarasi', -1)
            return true
        end
    end
end)

lib.callback.register('fmid_garasi:garasiRealtime', function(source)
    return DB.GarasiRealtime()
end)

lib.callback.register('fmid_garasi:admin', function(source)
    return Framework.Admin(source)
end)

lib.callback.register('fmid_garasi:LangsungKeluarByPlate', function(source, plate)
    local mbp = DB.LangsungKeluar(source, plate, true)
    if mbp then
        return true
    end
end)

local function addKendaraan(src)
    local status, reason = DB.InsertKendaraan(src)
    if status then
        TriggerClientEvent('fmid_garasi:notify', src, 'Kendaraan berhasil terdata!', 'success')
    else
        TriggerClientEvent('fmid_garasi:notify', src, 'Kendaraan gagal didata karena '.. reason, 'error')
    end
end
if grs.enableAddKendaraanExports then
    exports('addKendaraan', addKendaraan)
end

local function removeKendaraan(src)
    local status, reason = DB.RemoveKendaraan(src)
    if status then
        TriggerClientEvent('fmid_garasi:notify', src, 'Kendaraan berhasil terhapus!', 'success')
    else
        TriggerClientEvent('fmid_garasi:notify', src, 'Kendaraan gagal didata karena '.. reason, 'error')
    end
end
if grs.enableRemoveKendaraanExports then
    exports('removeKendaraan', removeKendaraan)
end

local function updateGRS(tipe, value)
    grs[tipe] = value
end

lib.callback.register('fmid_garasi:getgrs', function(source, tipe)
    return grs[tipe]
end)

AddEventHandler('fmid_poly:created', function(zone, meta)
    if meta.tipe == 'db' then
        local dbsave = {
            jenis = 'garasi',
            tipe = 'poly',
            a1 = zone.points,
            a2 = zone.minZ + 10,
            label = meta.label,
            ent = 0,
            blip = vec3(zone.center.x, zone.center.y, zone.minZ + 10),
        }
        if DB.InsertGarasi(dbsave, meta) then
            TriggerClientEvent('fmid_garasi:refreshGarasi', -1)
        end
    elseif meta.tipe == 'config' then
        local points = {}
        local poin = zone.points
        for i=1, #poin do
            points[#points + 1] = '\t\t'..poin[i]..',\n'
        end
        local dataGarasi = {
            '\n'..meta.name..' = {\n',
            '\tjenis = "garasi",\n',
            '\ttipe= "poly",\n',
            '\ta2 = '..(zone.minZ+10)..',\n',
            '\tblip = '..vec3(zone.center.x, zone.center.y, zone.minZ + 10).xyz..',\n',
            '\tent = 0,\n',
            '\tlabel = "'..Utils.Trim(meta.label)..'",\n',
            '\ta1 = {\n',
            ('%s'):format(table.concat(points)),
            '\t}\n',
            '},\n'
        }
        local output = (LoadResourceFile('fmid_garasi', 'data/zones.lua') or '') .. table.concat(dataGarasi)
        SaveResourceFile('fmid_garasi', 'data/zones.lua', output, -1)
    end
end)

lib.addCommand('deletegarasi', {
    params = {
        {name = 'garasi', type = 'string'},
    },
    restricted = 'group.admin',
}, function(source, args)
    if DB.RemoveGarasi(args.garasi) then
        TriggerClientEvent('fmid_garasi:deleteGarasi', -1, args.garasi)
        TriggerClientEvent('fmid_garasi:refreshGarasi', -1)
    end
end)

lib.addCommand('addaksesgarasi', {
    params = {
        {name = 'garasi', type = 'string'},
        {name = 'data', type = 'string'}
    },
    restricted = 'group.admin'
}, function(source, args)
    if DB.AddAksesGarasi(args.data, args.garasi) then
        TriggerClientEvent('fmid_garasi:refreshGarasi', -1)
    end
end)

lib.addCommand('removeaksesgarasi', {
    params = {
        {name = 'garasi', type = 'string'},
        {name = 'data', type = 'string'}
    },
    restricted = 'group.admin'
}, function(source, args)
    if DB.RemoveAksesGarasi(args.data, args.garasi) then
        TriggerClientEvent('fmid_garasi:refreshGarasi', -1)
    end
end)

lib.addCommand('simpanmobil', {
    help = 'Simpan Kendaraan yang saat ini kamu kendarai',
    restricted = 'group.admin'
}, function(src, arg)
    addKendaraan(src)
end)

lib.addCommand('hapusmobil', {
    help = 'Menghapus data kendaraan yang saat ini kamu kendarai',
    restricted = 'group.admin'
}, function(src, arg)
    removeKendaraan(src)
end)

lib.addCommand('mobil', {
    help = 'Spawn Kendaraan',
    restricted = 'group.admin',
    params = {
        {name = 'model', help = 'Kode Spawn', type = 'string'},
    }
}, function(src, arg)
    Utils.SpawnVehicle(src, arg.model, nil, true)
end)

lib.addCommand('mbh', {
    help = 'Spawn Kendaraan menggunakan Hash (nomor)',
    restricted = 'group.admin',
    params = {
        {name = 'hash', help = 'Kode Hash', type = 'number'}
    }
}, function(src, arg)
    Utils.SpawnVehicle(src, arg.hash, nil, true)
end)

lib.addCommand('interaksigarasi', {
    help = 'Mengubah Interaksi Garasi',
    restricted = 'group.'..grs.RealtimeInteraksi,
}, function(src, arg)
    local tanya = {
        {type = 'select', label = 'Pilihan Interaksi', options = {
            {label = 'F1 / Radial', value = 'f1'},
            {label = 'Tekan E', value = 'e'},
        }}
    }
    if grs.RealtimeInteraksi == 'admin' then
        tanya[#tanya+1] = {
            type = 'checkbox', label = 'Semua Player?'
        }
    end
    local input = lib.callback.await('fmid_garasi:input', src, 'Pergantian Tipe Interaksi (diri sendiri)', tanya)
    if input then
        updateGRS('LockInteraksi', input[2] == true and true or false)
        if grs.RealtimeInteraksi == 'admin' and input[2] == true then
            updateGRS('Interaksi', input[1] == 'f1' and 'radial' or input[1])
            TriggerClientEvent('fmid_garasi:updatedInteraksi', -1, input[1])
        else
            Framework.SetMeta(src, 'interaksigarasi', input[1])
            TriggerClientEvent('fmid_garasi:updatedInteraksi', src, input[1])
        end
    end
end)

lib.addCommand('addkendaraan', {
    help = 'Add Nama Kendaraan',
    restricted = 'group.admin'
}, function(source, args)
    local veh = Utils.veh(source)
    local gamename = string.lower(veh.gamename())
    local tanya = {
        {type = 'input', label = 'Kode Spawn Kendaraan', default = gamename or ''},
        {type = 'input', label = 'Label Kendaraan', default = Framework.SharedVehicles?[GetHashKey(gamename)]?.name or ''},
        {type = 'number', label = 'Price Kendaraan', default = Framework.SharedVehicles?[GetHashKey(gamename)]?.price or nil},
    }
    local input = lib.callback.await('fmid_garasi:input', source, 'Add Kendaraan', tanya)
    if input then
        datakendaraan[input[1]] = {label = input[2], price = input[3]}
        local databaru = {}
        local semuadatakendaraan = {}
        
        for k, v in pairs(datakendaraan) do
            if datakendaraan[k] then
                databaru[#databaru + 1] = ('\t["%s"] = {\n\t    label = "%s",\n\t    price = %s\n\t},\n'):format(k, v.label, v.price)
            end
            Framework.SharedVehicles[GetHashKey(k)] = {
                name = v.label,
                price = v.price,
                model = k,
            }
        end
        semuadatakendaraan = table.concat(databaru, "\n")
        local stringDataKendaraan = ('return {\n%s\n}'):format(semuadatakendaraan)
        SaveResourceFile(GetCurrentResourceName(), 'data/kendaraan.lua', stringDataKendaraan, -1)
    end
end)