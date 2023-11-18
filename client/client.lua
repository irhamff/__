poly = grs.fmid_polyEarlyAccess and exports.fmid_poly:newpoly() or exports.fmid_poly:poly() 
blipgarasi = {}

lib.callback.register('fmid_garasi:getFuel', function()
    return Utils.veh().getfuel()
end)

lib.callback.register('fmid_garasi:setFuel', function(num)
    return Utils.veh().setfuel(num)
end)

lib.callback.register('fmid_garasi:gvp', function()
    return Utils.veh().gvp()
end)

lib.callback.register('fmid_garasi:sethealth', function(brp)
    local _,__,___,cb = Utils.ped()
    cb.health.set(brp)
    return cb.health.get()
end)

RegisterNetEvent('fmid_garasi:setVehicleEngine', function(vh, num)
    local veh = Utils.veh()
    veh.setengine(num)
end)
RegisterNetEvent('fmid_garasi:svp', function(vh, modif)
    local veh = Utils.veh()
    veh.svp(modif)
end)

local function aksesGarasi(id)
    id = id or LocalPlayer.state.Garasi
    if grs.radial == 'qb' then
        id = LocalPlayer.state.Garasi
    end
    if not id then
        Framework.Notify('Kamu tidak sedang di garasi!')
        return false
    end
    local veh = Utils.veh()
    if veh then
        local sukses, notif = lib.callback.await('fmid_garasi:garasi', false, 'masuk', veh.getplate(), id)

        if sukses then
            Framework.Notify(notif, nil, 7000)
        else
            Framework.Notify(notif, 'error', 7000)
        end
    else
        local semua, notif = lib.callback.await('fmid_garasi:garasi', false, 'return', nil, id)
        local opsi = {}
        if semua then
            for i=1, #semua do
                local trunk = json.decode(semua[i].trunk)
                local isibagasi = {}
                if json.encode(trunk) ~= 'null' then
                    for k,v in pairs(trunk) do
                        isibagasi[#isibagasi+1] = {
                            label = Framework.Items[v.name],
                            value = v.count..'x'
                        }
                    end
                end
                opsike = #opsi+1
                opsi[opsike] = {
                    title = '[ '..semua[i].plate..' ] '..semua[i].namakendaraan,
                    description = 'Klik untuk mengeluarkan kendaraan dari Garasi ke Tempat kamu saat ini',
                    colorScheme = 'cyan',
                    metadata = {
                        {label = 'Bensin', value = semua[i].fuel, progress = semua[i].fuel},
                        {label = 'Mesin', value = (semua[i].engine / 10)..'%', progress = (semua[i].engine / 10)},
                        {label = 'Body', value = (semua[i].body / 10)..'%', progress = (semua[i].body / 10)},
                    },
                    onSelect = function()
                        local sukses, notif = lib.callback.await('fmid_garasi:garasi', false, 'keluar', semua[i].plate, id)
                        if sukses then
                            Framework.Notify(notif, nil, 7000)
                        else
                            Framework.Notify(notif, 'error', 7000)
                        end
                    end
                }
                if #isibagasi > 0 then
                    opsi[opsike].metadata[#opsi[opsike].metadata+1] = {label = '---- Bagasi ---', value = ''}
                end
                for i=1, #isibagasi do
                    opsi[opsike].metadata[#opsi[opsike].metadata+1] = isibagasi[i]
                end
            end
            local ctx = {
                id = 'garasi',
                title = grs.lokasi[id].label,
                hasSearch = true,
                options = opsi,
            }
            lib.registerContext(ctx)
            lib.showContext(ctx.id)
        else
            Framework.Notify(notif, 'error')
        end
    end
end

local function aksesAsuransi()
    if not LocalPlayer.state.Asuransi then
        Framework.Notify('Kamu sedang tidak berada di area asuransi!', 'error')
        return
    end
    if cache.vehicle then
        Framework.Notify('Pastikan kamu berada diluar kendaraan!', 'error', 6000)
    else
        local pd = Framework.GetPlayerData()
        local semua, notif = lib.callback.await('fmid_garasi:garasi', false, 'asuransi')
        local opsi = {}
        if semua then
            for i=1, #semua do
                opsi[#opsi+1] = {
                    title = '[ '..semua[i].plate..' ] '..semua[i].namakendaraan,
                    description = semua[i].disabled and 'Masih berada di jalanan' or ('Biaya: $'..Utils.GroupDigits(grs.BiayaAsuransi and (semua[i].price * grs.BiayaAsuransi) or grs.FlatAsuransi)),
                    disabled = semua[i].disabled or false,
                    colorScheme = 'cyan',
                    metadata = {
                        {label = 'Bensin', value = semua[i].fuel, progress = semua[i].fuel},
                        {label = 'Mesin', value = (semua[i].engine / 10)..'%', progress = (semua[i].engine / 10)},
                        {label = 'Body', value = (semua[i].body / 10)..'%', progress = (semua[i].body / 10)},
                    },
                    onSelect = function()
                        local sukses, notif = lib.callback.await('fmid_garasi:garasi', false, 'keluar_asuransi', semua[i].plate, id)
                        if sukses then
                            Framework.Notify(notif, nil, 7000)
                        else
                            Framework.Notify(notif, 'error', 7000)
                        end
                    end
                }
            end
            local ctx = {
                id = 'asuransi',
                title = 'Asuransi',
                options = opsi,
                hasSearch = true,
            }
            lib.registerContext(ctx)
            lib.showContext(ctx.id)
        else
            Framework.Notify(notif, 'error', 6000)
        end
    end
end 

local keybindInteraksi = lib.addKeybind({
    name = 'fmid_garasi',
    description = 'Akses Garasi / Asuransi',
    defaultKey = 'E',
    onPressed = function(self)
        if LocalPlayer.state.Garasi then
            aksesGarasi()
        elseif LocalPlayer.state.Asuransi then
            aksesAsuransi()
        end
    end,
})
keybindInteraksi:disable(true)

Framework.startloaded(function()
    local bisa = false
    grs.Interaksi = lib.callback.await('fmid_garasi:getgrs', false, 'Interaksi')
    grs.LockInteraksi = lib.callback.await('fmid_garasi:getgrs', false, 'LockInteraksi')
    if Framework.GetMeta('interaksigarasi') and Framework.GetMeta('interaksigarasi') == 'e' then
        bisa = true
    elseif Framework.GetMeta('interaksigarasi') and Framework.GetMeta('interaksigarasi') ~= 'e' then
        bisa = false
    elseif grs.Interaksi == 'e' then
        bisa = true
    end
    if bisa then
        keybindInteraksi:disable(false)
    end
end)

RegisterNetEvent('fmid_garasi:updatedInteraksi', function(jadi)
    grs.Interaksi = lib.callback.await('fmid_garasi:getgrs', false, 'Interaksi')
    grs.LockInteraksi = lib.callback.await('fmid_garasi:getgrs', false, 'LockInteraksi')
    if jadi == 'e' then
        keybindInteraksi:disable(false)
        Utils.RemoveRadial('garasi')
        Utils.RemoveRadial('asuransi')
    else
        keybindInteraksi:disable(true)
    end
    if grs.Interaksi ~= 'radial' then
        Utils.RemoveRadial('garasi')
        Utils.RemoveRadial('asuransi')
    end
end)

function getInteraksi()
    if not grs.LockInteraksi and Framework.GetMeta('interaksigarasi') then return string.upper(Framework.GetMeta('interaksigarasi'))
    elseif grs.Interaksi == 'radial' then return 'F1'
    elseif grs.Interaksi == 'e' then return 'E'
    end
end

function loadGarasi()
    for k,v in pairs(grs.lokasi) do
        if not v.gapakeblip then
            if v.akses and Framework.cekAkses(v.akses) then
                v.ent = Utils.BuatBlip(v.label, v.blip, 357, v.jenis == 'garasi' and 57 or 51, 0.8, 10)
            elseif not v.akses then
                v.ent = Utils.BuatBlip(v.label, v.blip, 357, v.jenis == 'garasi' and 57 or 51, 0.8, 10)
            end
            blipgarasi[#blipgarasi+1] = v.ent
        end
        if v.tipe == 'poly' then
            poly.create('garasi_'..k, 'poly', {
                points = v.a1,
                data = {
                    minZ = v.minZ or v.a2 - 10,
                    maxZ = v.maxZ or v.a2 + 20,
                    debugPoly = grs.Debug,
                },
            }, function()
                if v.akses and not Framework.cekAkses(v.akses) then
                    return
                end
                if v.jenis == 'garasi' then
                    LocalPlayer.state.Garasi = k
                elseif v.jenis == 'asuransi' then
                    LocalPlayer.state.Asuransi = k
                end
                
                lib.showTextUI(getInteraksi()..' - '..v.label, {icon = 'warehouse'})
                if v.jenis == 'garasi' then
                    Utils.AddRadial('garasi', {
                        icon = 'warehouse',
                        label = 'Garasi',
                        event = 'fmid_garasi:aksesGarasi',
                        func = function()
                            aksesGarasi(k)
                        end
                    })
                elseif v.jenis == 'asuransi' then
                    Utils.AddRadial('asuransi', {
                        icon = 'warehouse',
                        label = 'Asuransi',
                        event = 'fmid_garasi:aksesAsuransi',
                        func = function()
                            aksesAsuransi(k)
                        end
                    })
                end
            end, function()
                LocalPlayer.state.Garasi = nil
                LocalPlayer.state.Asuransi = nil
                lib.hideTextUI()
                Utils.RemoveRadial('garasi')
                Utils.RemoveRadial('asuransi')
            end)
        elseif v.tipe == 'normal' then
            poly.create('garasi_'..k, 'box', {
                point = v.blip,
                length = 20,
                width = 20,
                data = {
                    minZ = v.blip.z - 10,
                    maxZ = v.blip.z + 10,
                }
            }, function()
                if v.akses and not Framework.cekAkses(v.akses) then
                    return
                end
                if v.jenis == 'garasi' then
                    LocalPlayer.state.Garasi = k
                elseif v.jenis == 'asuransi' then
                    LocalPlayer.state.Asuransi = k
                end
                lib.showTextUI(getInteraksi()..' - '..v.label, {icon = 'warehouse'})
                if v.jenis == 'garasi' then
                    Utils.AddRadial('garasi', {
                        icon = 'warehouse',
                        label = 'Garasi',
                        event = 'fmid_garasi:aksesGarasi',
                        func = function()
                            aksesGarasi(k)
                        end
                    })
                elseif v.jenis == 'asuransi' then
                    Utils.AddRadial('asuransi', {
                        icon = 'warehouse',
                        label = 'Asuransi',
                        event = 'fmid_garasi:aksesAsuransi',
                        func = function()
                            aksesAsuransi(k)
                        end
                    })
                end
            end, function()
                LocalPlayer.state.Garasi = nil
                LocalPlayer.state.Asuransi = nil
                lib.hideTextUI()
                Utils.RemoveRadial('garasi')
                Utils.RemoveRadial('asuransi')
            end)
        elseif v.tipe == 'custom' then
            if LocalPlayer.state['garasi_'..k] then
                if v.akses and not Framework.cekAkses(v.akses) then
                    return
                end
                if v.jenis == 'garasi' then
                    LocalPlayer.state.Garasi = k
                elseif v.jenis == 'asuransi' then
                    LocalPlayer.state.Asuransi = k
                end
                lib.showTextUI(getInteraksi()..' - '..v.label, {icon = 'warehouse'})
                Utils.AddRadial('garasi', {
                    icon = 'warehouse',
                    label = 'Garasi',
                    event = 'fmid_garasi:aksesGarasi',
                    func = function()
                        aksesGarasi(k)
                    end
                })
            else
                LocalPlayer.state.Garasi = nil
                LocalPlayer.state.Asuransi = nil
                lib.hideTextUI()
                Utils.RemoveRadial('garasi')
                Utils.RemoveRadial('asuransi')
            end 
        end
    end
end

exports('aksesGarasi', function()
    if LocalPlayer.state.Garasi then
        aksesGarasi(LocalPlayer.state.Garasi)
        return true
    end
end)

exports('aksesAsuransi', function()
    if LocalPlayer.state.Asuransi then
        aksesAsuransi()
        return true
    end
end)

exports('getShGarasi', function(namagarasi)
    return grs.lokasi[namagarasi]
end)

exports('AddCustomGarasi', function(nama, data)
    if not nama and data.nama then nama = data.nama end
    if not grs.lokasi['garasi_'..nama] then
        grs.lokasi['garasi_'..nama] = data 
        if not grs.lokasi['garasi_'..nama].tipe then grs.lokasi['garasi_'..nama].tipe = 'custom' end
        grs.lokasi['garasi_'..nama].ent = 0
        grs.lokasi['garasi_'..nama].state = 'garasi_'..nama
        grs.lokasi['garasi_'..nama].jenis = 'garasi'
    end
    local saveCustomGarage = lib.callback.await('fmid_garasi:addCustomGarasi', false, 'garasi_'..nama, data)
    if saveCustomGarage then
        local namagarasi = 'garasi_'..nama
        local cb = {}
        cb.inside = function(namagarasi)
            LocalPlayer.state.Garasi = namagarasi
            local shgarasi = exports.fmid_garasi:getShGarasi(namagarasi)
            lib.showTextUI(getInteraksi()..' - '..shgarasi.label, {icon = 'warehouse'})
            Utils.AddRadial('garasi', {
                icon = 'warehouse',
                label = 'Garasi',
                event = 'fmid_garasi:aksesGarasi',
                func = function()
                    aksesGarasi(k)
                end
            })
        end
        cb.outside = function()
            LocalPlayer.state.Garasi = nil
            lib.hideTextUI()
            Utils.RemoveRadial('garasi')
        end
    end
    
    return cb
end)

local function RemoveBlipGarasi()
    for k,v in pairs(grs.lokasi) do
        RemoveBlip(v.ent)
        poly.remove('garasi_'..k)
    end
    for i=1, #blipgarasi do
        RemoveBlip(blipgarasi[i])
    end
    blipgarasi = {}
end

Utils.stopres(function()
    RemoveBlipGarasi()
    lib.hideTextUI()
    Utils.RemoveRadial('garasi')
    Utils.RemoveRadial('asuransi')
end)

function refreshGarasi()
    local getGarasiRealtime = lib.callback.await('fmid_garasi:garasiRealtime', false)
    for i=1, #getGarasiRealtime do
        local stb = json.decode(getGarasiRealtime[i].data)
        local collec = {}
        for zz=1, #stb.a1 do
            collec[#collec+1] = vec2(stb.a1[zz].x, stb.a1[zz].y)
        end
        local blip = vec3(stb.blip.x, stb.blip.y, stb.blip.z)
        grs.lokasi['garasi_'..getGarasiRealtime[i].nama] = {
            jenis = 'garasi',
            tipe = 'poly',
            state = 'garasi_'..getGarasiRealtime[i].nama,
            blip = blip,
            ent = 0,
            label = stb.label,
            a2 = stb.a2,
            a1 = collec,
            akses = stb.akses
        }
    end
    RemoveBlipGarasi()
    loadGarasi()
end

Framework.startloaded(refreshGarasi)
Framework.JobTerganti(refreshGarasi)

if GetResourceState('qb-core') == 'started' then
    Framework.GangTerganti(refreshGarasi)
end
RegisterNetEvent('fmid_garasi:refreshGarasi', refreshGarasi)
RegisterNetEvent('fmid_garasi:aksesGarasi', aksesGarasi)
RegisterNetEvent('fmid_garasi:aksesAsuransi', aksesAsuransi)
RegisterNetEvent('fmid_garasi:deleteGarasi', function(nama)
    RemoveBlipGarasi()
    grs.lokasi['garasi_'..nama] = nil
    refreshGarasi()
end)
RegisterNetEvent('fmid_garasi:notify', Framework.Notify)
RegisterNetEvent('fmid_garasi:hideTextUI', lib.hideTextUI)

for events, fungsi in pairs(grs.hooks) do
    RegisterNetEvent('fmid_garasi:'..events, function(vehData)
        grs.hooks[events](vehData)
    end)
end

exports('RegisterHooks', function(events, fungsi)
    local ke = #grs.externalHooks[events]+1
    grs.externalHooks[events][ke] = fungsi
    return ke
end)

exports('RemoveHooks', function(events, id)
    grs.externalHooks[events][id] = nil
end)

lib.callback.register('fmid_garasi:konfirmasi', function(data)
    local alert = lib.alertDialog(data)
    if alert == 'confirm' then
        return true
    end
end)
lib.callback.register('fmid_garasi:input', function(heading, rows, options)
    local input = lib.inputDialog(heading, rows, options)
    if not input then return end
    return input
end)

-- Pembuatan Garasi In-Game
RegisterCommand('buatgarasi', function(s,a) -- ke database / realtime
    local butuh, missing = Utils.ButuhResource({'fivem-freecam', 'fmid_poly', 'fmid_loop'})
    if butuh then
        local admin = lib.callback.await('fmid_garasi:admin')
        if admin then
            local meta = {}
            meta.name = a[1]
            local str = ''
            for i=2, #a do
                str = str..' '..a[i]
            end
            meta.label = str
            meta.tipe = 'db'
            meta.source = cache.serverId
            lib.showTextUI('[G] untuk Add Point \n[WASD] untuk navigasi noclip  \n[🡢 🡣 🡠 🡡] untuk navigasi point    \n[Enter] untuk konfirmasi pembuatan zone   \n[Backspace] untuk menggagalkan pembuatan zone')
            poly.makepoly('garasi_'..meta.name, meta)
        else
            Framework.Notify('Kamu bukan admin!', 'error')
        end
    else
        print('Missing Resource: '..missing)
    end
end)

RegisterCommand('bikingarasi', function(s,a) -- ke config / manual
    local butuh, missing = Utils.ButuhResource({'fivem-freecam', 'fmid_poly', 'fmid_loop'})
    if butuh then
        local admin = lib.callback.await('fmid_garasi:admin')
        if admin then
            local meta = {}
            meta.name = a[1]
            local str = ''
            for i=2, #a do
                str = str..' '..a[i]
            end
            meta.label = str
            meta.tipe = 'config'
            meta.source = cache.serverId
            lib.showTextUI('[G] untuk Add Point \n[WASD] untuk navigasi noclip  \n[🡢 🡣 🡠 🡡] untuk navigasi point    \n[Enter] untuk konfirmasi pembuatan zone   \n[Backspace] untuk menggagalkan pembuatan zone')
            poly.makepoly('garasi_'..meta.name, meta)
        else
            Framework.Notify('Kamu bukan admin!', 'error')
        end
    else
        print('Missing Resource: '..missing)
    end
end)

RegisterCommand('mbp', function(s,a)
    local admin = lib.callback.await('fmid_garasi:admin')
    if admin then
        local str = ''
        for i=1, #a do
            str = str..' '..a[i]
        end
        local spawned = lib.callback.await('fmid_garasi:LangsungKeluarByPlate', false, Utils.Trim(str))
        if spawned then
            Framework.Notify('Kamu langsung mengambil kendaraan ini dari garasi/asuransi!', 'success')
        end
    else
        Framework.Notify('Kamu bukan admin!', 'error')
    end
end)

RegisterNetEvent('fmid_poly:closedMakePoly', function()
    lib.hideTextUI()
end)

if grs.Debug then
    lib.addKeybind({
        name = 'f1',
        description = 'f1',
        defaultKey = 'F1',
        onPressed = function(self)
            print('lagi tekan F1')
        end,
    })

    lib.addKeybind({
        name = 'e',
        description = 'e',
        defaultKey = 'e',
        onPressed = function(self)
            print('lagi tekan e')
        end,
    })
end