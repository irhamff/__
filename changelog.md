## fmid_garasi Updates
### versi 1.2.8

## Updates
- Utils.SpawnVehicle kini mengirimkan onVehicleSpawned hook function
- Utils.veh kini berisi function getKerusakan (return dalam bentuk table doors, windows, tyres), bisa dipanggil dari clientside/serverside
- Optimize Koneksi DB.MasukGarasi, menghindari null value dari vehprops
- Added exports SaveKerusakan (serversided)
- Removed Deformation Systems
- Added Checking, Saving dan Loading Kerusakan Pintu/Kap/Bagasi/Kaca/Ban
- Teks Blip `Property:` menjadi `Garasi Lainnya:`
- Update Utils.BuatBlip

## Replace Files
- [REMOVE] client/deformation
- [REMOVE] server/deformations.lua
- client/client.lua
- server/server.lua
- semua isi folder bridge
- data/etc.lua [hapus grs.deformation saja]