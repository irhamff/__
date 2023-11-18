-- Data Lokasi
grs.lokasi = {
    asuransi_ss = {
        jenis = 'asuransi',
        tipe = 'poly',
        a1 = {
            vector2(359.69360351562, 3425.7114257812),
            vector2(362.37890625, 3419.4606933594),
            vector2(369.76318359375, 3418.26171875),
            vector2(374.29098510742, 3410.2199707031),
            vector2(362.60076904297, 3405.6381835938),
            vector2(358.43588256836, 3409.4370117188),
            vector2(350.86654663086, 3408.4738769531),
            vector2(327.82366943359, 3399.4248046875),
            vector2(318.2783203125, 3395.1062011719),
            vector2(315.32574462891, 3402.833984375),
            vector2(322.21643066406, 3425.4379882812),
            vector2(333.77484130859, 3429.052734375)
        },
        a2 = 36,
        blip = vector3(339.9, 3414.15, 36.58),
        ent = 0,
        label = 'Asuransi SS',
    },
    alta = {
        jenis = 'garasi',
        tipe = 'poly', -- poly / kosongin jika gamau ribet pzcreate
        a1 = {
            vector2(-283.14474487305, -885.40100097656),
            vector2(-286.05035400391, -898.98687744141),
            vector2(-295.49435424805, -896.05670166016),
            vector2(-297.26834106445, -903.66790771484),
            vector2(-341.73297119141, -894.22552490234),
            vector2(-340.37109375, -887.818359375),
            vector2(-347.58609008789, -885.61077880859),
            vector2(-344.95758056641, -871.77697753906)
        },
        a2 = 31,
        minZ = 30,
        maxZ = 35,
        blip = vector3(-316.46, -888.26, 31.08),
        ent = 0,
        label = 'Garasi Alta Street',
    },
    contoh1 = { -- advanced
        jenis = "garasi", -- garasi / asuransi
        tipe= "poly",
        a2 = 38.780548095703,
        blip = vec3(-327.660889, -753.524536, 38.780548),
        ent = 0,
        label = "Garasi Merah",
        a1 = {
            vec2(-327.968506, -754.323853),
            vec2(-328.217621, -772.322876),
            vec2(-341.650238, -772.769043),
            vec2(-341.587158, -754.268921),
            vec2(-341.587158, -754.268921),
        },
        tanpaIdentifier = true,
        akses = { -- cid / job / gang / steamhex
            'police', -- contoh job
            'steam:11111111', -- contoh steamhex
            'mafia', -- contoh gang
            'RF92091', -- contoh cid     
        },
    },
    contoh2 = { -- basic
        jenis = 'garasi',
        tipe = 'normal',
        label = 'Garasi Merah 2',
        blip = vec3(-302.2883, -753.3808, 38.7798),
        ent = 0
    },
}