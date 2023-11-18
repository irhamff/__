grs = {}

exports('getSemuaGarasi', function()
    return grs
end)

-- Radial Menu
grs.radial = 'ox' -- ox / qb / np (untuk np contact irham lagi, karna custom script)
grs.namaradial = 'ox_lib' -- nama scriptnya apa

-- Bensin
grs.oxfuel = true
grs.Fuel = nil -- kalau tidak ada exports GetFuel / SetFuel bisa dijadikan grs.Fuel = nil aja
grs.CustomFuel = { -- ini untuk script selain ox_fuel dan selain script bensin yg memiliki exports GetFuel / SetFuel
    get = function(veh)
        return exports['fmid_fuel']:getbensin(veh) -- hanya contoh, saya ga jualan script fuel.
    end,
    set = function(veh, jumlah)
        exports['fmid_fuel']:setbensin(veh, jumlah) -- hanya contoh, saya ga jualan script fuel.
    end
}

-- Asuransi
grs.BiayaAsuransi = 0.02 -- persen dari harga kendaraan, misal 1% berarti 0.01 // jika mau flat price, jadikan grs.BiayaAsuransi = nil aja dan set grs.FlatAsuransi
grs.FlatAsuransi = 1000 -- harga asuransi flat price, config ini aktif jika grs.BiayaAsuransi = nil

-- Data Kendaraan
grs.DefaultPrice = 100 -- (khusus esx) default price kendaraan jika kamu tidak memasukkan kendaraannya ke table vehicles / grs.kendaraan

-- Tambahan
grs.SaveVehicleProperties = false -- beberapa server mengamankan modifikasi kendaraan dengan cara tidak save vehicle properties dari garasi, melainkan dari script modifikasi kendaraan. jadikan config ini false untuk tidak menyimpan vehicleprops dari garasi.

grs.Framework = 'esx' -- esx / qb
grs.NamaResourceFramework = 'es_extended' -- nama script fw, ex: es_extended / qb-core / qbx-core / qbx_core / custom dll
grs.EventFramework = 'esx:' -- ex: 'esx:' / 'QBCore:' / '...:'