grs.CustomDatabase = {
    posisi = nil, -- biasanya stored / state
    namatable = nil, -- biasanya player_vehicles / owned_vehicles
    garasi = nil, -- biasanya garage / parking
}

grs.lib = {
    math = true, -- jika menggunakan ox_lib terbaru dan mau pakai fitur decimal places bisa set true / kalau yang belum support bisa set false
}

grs.defaultGarasi = 'alta'
grs.enableAddKendaraanExports = true
grs.enableRemoveKendaraanExports = true

grs.hooks = { -- bekerja di clientside
    onVehicleSpawned = function(vehicleData)
        -- bagian ini kalau mau tambahkan fungsi dari fmid_garasi
        -- print('onVehicleSpawned')
        -- print(json.encode(vehicleData, {indent = true}))

        -- dibawah ini jangan di disable
        for nomor, isi in pairs(grs.externalHooks.onVehicleSpawned) do
            if grs.externalHooks.onVehicleSpawned[nomor] then
                grs.externalHooks.onVehicleSpawned[nomor](vehicleData)
            end
        end
    end,
    beforeVehicleStored = function(vehicleData)
        -- bagian ini kalau mau tambahkan fungsi dari fmid_garasi
        -- print('beforeVehicleStored')
        -- print(json.encode(vehicleData, {indent = true}))

        -- dibawah ini jangan di disable
        for nomor, isi in pairs(grs.externalHooks.beforeVehicleStored) do
            if grs.externalHooks.beforeVehicleStored[nomor] then
                grs.externalHooks.beforeVehicleStored[nomor](vehicleData)
            end
        end
    end,
    afterVehicleStored = function(vehicleData)
        -- bagian ini kalau mau tambahkan fungsi dari fmid_garasi
        -- print('afterVehicleStored')
        -- print(json.encode(vehicleData, {indent = true}))

        -- dibawah ini jangan di disable
        for nomor, isi in pairs(grs.externalHooks.afterVehicleStored) do
            if grs.externalHooks.afterVehicleStored[nomor] then
                grs.externalHooks.afterVehicleStored[nomor](vehicleData)
            end
        end
    end,
}

grs.externalHooks = {}
for event, _ in pairs(grs.hooks) do
    grs.externalHooks[event] = {}
end

-- Update 4 Oktober 2023
grs.Interaksi = 'radial' -- (radial / e)
grs.LockInteraksi = true -- player tidak bisa ganti interaksi = true.
grs.RealtimeInteraksi = 'admin' -- (user/admin) yang bisa menggunakan /interaksigarasi itu apakah user (semua player) atau admin (hanya admin yang bisa). !! PILIHAN HANYA USER DAN ADMIN SAJA, TIDAK ADA SUPERADMIN / GOD / MOD DLL !!
grs.Debug = false

-- Update 8 Oktober 2023
grs.oldESX = false -- untuk esx yang belum memiliki function setMeta dan getMeta (dibawah esx legacy 1.9.4 wajib true)
grs.defaultKendaraanLabel = 'hash' -- kalau hash akan menjadi nomor hash dari kendaraannya, selain itu misal set 'Kendaraan', label yang tidak ditemukan akan menjadi 'Kendaraan'

-- Update 17 Oktober 2023
grs.formatPlate = 'FMID A.1'  -- . = random huruf / angka | A = random huruf | 1 = random angka | ^1 = angka 1 | ^A = huruf A | ^. = titik | apapun seperti biasa saja misal F = F

-- Update 3 November 2023
grs.fmid_polyEarlyAccess = false