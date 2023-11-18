Utils = {}
Utils.side = IsDuplicityVersion
Utils.SpawnVehicle = function(source, model, coords, warp, plate)
    local ped = GetPlayerPed(source)
    model = type(model) == 'string' and joaat(model) or model
    if not coords then coords = GetEntityCoords(ped) end
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, true, true)
    local jdp = plate or Utils.GenerateRandomPlate(grs.formatPlate)
    SetVehicleNumberPlateText(veh, jdp)
    while not DoesEntityExist(veh) do Wait(0) end
    if warp then
        while GetVehiclePedIsIn(ped, false) ~= veh do
            Wait(0)
            TaskWarpPedIntoVehicle(ped, veh, -1)
        end
    end
    while NetworkGetEntityOwner(veh) ~= source do Wait(0) end
    TriggerClientEvent('fmid_garasi:onVehicleSpawned', source, {data = {plate = jdp}})
    return veh
end exports('SpawnVehicle', Utils.SpawnVehicle)

Utils.GroupDigits = function(value)
    return grs.lib.math and lib.math.groupdigits(value) or value
end

Utils.Trim = function(value)
    if not value then return nil end
    return string.gsub(value, '^%s*(.-)%s*$', '%1')
end

Utils.Round = function(value, numDecimalPlaces)
    if not numDecimalPlaces then return math.floor(value + 0.5) end
    local power = 10 ^ numDecimalPlaces
    return math.floor((value * power) + 0.5) / (power)
end

Utils.ped = function(src)
    local cb = {}
    if Utils.side() then
        local ped = GetPlayerPed(src)
        local coord = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        cb.health = {}
        cb.health.set = function(brp)
            local set = lib.callback.await('fmid_garasi:sethealth', src, brp)
            return set
        end
        cb.health.get = function()
            return GetEntityHealth(ped)
        end
        cb.health.add = function(brp)
            local he = GetEntityHealth(ped)
            he = he + brp
            if he >= 200 then he = 200 end
            -- SetEntityHealth(ped, he)
            local set = lib.callback.await('fmid_garasi:sethealth', src, he)
            return set
        end
        cb.health.remove = function(brp)
            local he = GetEntityHealth(ped)
            he = he - brp
            if he <= 0 then he = 0 end
            -- SetEntityHealth(ped, he)
            local set = lib.callback.await('fmid_garasi:sethealth', src, he)
            return set
        end
        cb.health.sisa = function()
            return GetEntityHealth(ped) - 100
        end

        return ped, coord, heading, cb
    else
        local ped = PlayerPedId()

        cb.health = {}
        cb.health.set = function(brp)
            SetEntityHealth(ped, brp)
        end
        cb.health.get = function()
            return GetEntityHealth(ped)
        end
        cb.health.sisa = function()
            return GetEntityHealth(ped) - 100
        end
        cb.health.add = function(brp)
            local he = GetEntityHealth(ped)
            he = he + brp
            if he >= 200 then he = 200 end
            SetEntityHealth(ped, he)
        end
        cb.health.remove = function(brp)
            local he = GetEntityHealth(ped)
            he = he - brp
            if he <= 0 then he = 0 end
            SetEntityHealth(ped, he)
        end
        return ped, GetEntityCoords(ped), GetEntityHeading(ped), cb
    end
end

Utils.veh = function(src, vh)
    local ped = Utils.ped(src)
    local veh = vh or GetVehiclePedIsIn(ped, false)
    local tb = {}
    if veh > 0 then
        tb.ent = function()
            return veh
        end
        tb.gamename = function()
            return lib.callback.await('fmid_garasi:getGameName', src)
        end
        tb.setplate = function(newplate)
            SetVehicleNumberPlateText(veh, newplate)
        end
        tb.getplate = function()
            return Utils.Trim(GetVehicleNumberPlateText(veh))
        end
        
        tb.getengine = function()
            return GetVehicleEngineHealth(veh)
        end
        tb.getbody = function()
            return GetVehicleBodyHealth(veh)
        end
        tb.setbody = function(num)
            SetVehicleBodyHealth(veh, num * 1.0 or 1000.0)
        end
        tb.warp = function()
            TaskWarpPedIntoVehicle(ped, veh, -1)
        end
        
        if not Utils.side() then
            tb.getfuel = function()
                return grs.oxfuel and Entity(veh).state.fuel or grs.Fuel and exports[grs.Fuel]:GetFuel(veh) or grs.CustomFuel.get(veh)
            end
            tb.setfuel = function(num)
                if grs.oxfuel then
                    local setfuel = lib.callback.await('fmid_garasi:setoxfuel', NetworkGetNetworkIdFromEntity(veh), num)
                else
                    if grs.Fuel then
                        exports[grs.Fuel]:SetFuel(veh, num)
                    else
                        grs.CustomFuel.set(veh, num)
                    end
                end
            end
            tb.setengine = function(num)
                SetVehicleEngineHealth(veh, num or 1000)
            end
            tb.svp = function(modifan)
                Utils.SetVehicleProperties(veh, modifan)
            end
            tb.gvp = function()
                return Utils.GetVehicleProperties(veh)
            end
            tb.getKerusakan = function()
                local vp = Utils.GetVehicleProperties(veh)
                local rusaknya = {
                    doorsBroken = {},
                    tyreBurst = {},
                    windowsBroken = {},
                }
                for k, v in pairs(vp.doorsBroken) do
                    rusaknya.doorsBroken[k] = v 
                end
                for k, v in pairs(vp.tyreBurst) do
                    rusaknya.tyreBurst[k] = v 
                end
                for k, v in pairs(vp.windowsBroken) do
                    rusaknya.windowsBroken[k] = v 
                end
    
                return rusaknya
            end
        else
            tb.getfuel = function()
                if grs.oxfuel then
                    local netid = lib.callback.await('fmid_garasi:getNetId', src)
                    if netid then
                        local vehicle = NetworkGetEntityFromNetworkId(netid)
                        return Entity(vehicle).state.fuel
                    end
                else
                    local fuel = lib.callback.await('fmid_garasi:getFuel', src)
                    return fuel
                end
            end 
            tb.setfuel = function(num)
                if grs.oxfuel then
                    local netid = lib.callback.await('fmid_garasi:getNetId', src)
                    if netid then
                        local vehicle = NetworkGetEntityFromNetworkId(netid)
                        Entity(vehicle).state.fuel = num
                    end
                else
                    local fuel = lib.callback.await('fmid_garasi:setFuel', src, num)
                end
            end
            tb.setengine = function(num)
                TriggerClientEvent('fmid_garasi:setVehicleEngine', src, veh, num)
            end
            tb.svp = function(modif)
                TriggerClientEvent('fmid_garasi:svp', src, veh, modif)
            end
            tb.gvp = function()
                return lib.callback.await('fmid_garasi:gvp', src)
            end
            tb.getKerusakan = function()
                local vp = lib.callback.await('fmid_garasi:gvp', src)
                local rusaknya = {
                    doorsBroken = {},
                    tyreBurst = {},
                    windowsBroken = {},
                }
                for k, v in pairs(vp.doorsBroken) do
                    rusaknya.doorsBroken[k] = v 
                end
                for k, v in pairs(vp.tyreBurst) do
                    rusaknya.tyreBurst[k] = v 
                end
                for k, v in pairs(vp.windowsBroken) do
                    rusaknya.windowsBroken[k] = v 
                end
    
                return rusaknya
            end
        end
        tb.delete = function()
            DeleteEntity(veh)
        end
        return tb
    end
    return false
end exports('VehUtils', Utils.veh)

if IsDuplicityVersion() then
    lib.callback.register('fmid_garasi:setoxfuel', function(source, netid, num)
        local vehicle = NetworkGetEntityFromNetworkId(netid)
        Entity(vehicle).state.fuel = num
    end)
else
    lib.callback.register('fmid_garasi:getNetId', function()
        if cache.vehicle then
            return NetworkGetNetworkIdFromEntity(cache.vehicle)
        end
    end)
    lib.callback.register('fmid_garasi:getGameName', function()
        if cache.vehicle then
            return GetDisplayNameFromVehicleModel(GetEntityModel(cache.vehicle))
        end
    end)    
end

Utils.GetVehicleProperties = function(vehicle)
    if not DoesEntityExist(vehicle) then
        return
    end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    local hasCustomPrimaryColor = GetIsVehiclePrimaryColourCustom(vehicle)
    local customPrimaryColor = nil
    if hasCustomPrimaryColor then
        customPrimaryColor = {GetVehicleCustomPrimaryColour(vehicle)}
    end

    local hasCustomXenonColor, customXenonColorR, customXenonColorG, customXenonColorB = GetVehicleXenonLightsCustomColor(vehicle)
    local customXenonColor = nil
    if hasCustomXenonColor then 
        customXenonColor = {customXenonColorR, customXenonColorG, customXenonColorB}
    end
    
    local hasCustomSecondaryColor = GetIsVehicleSecondaryColourCustom(vehicle)
    local customSecondaryColor = nil
    if hasCustomSecondaryColor then
        customSecondaryColor = {GetVehicleCustomSecondaryColour(vehicle)}
    end

    local extras = {}
    for extraId = 0, 12 do
        if DoesExtraExist(vehicle, extraId) then
            extras[tostring(extraId)] = IsVehicleExtraTurnedOn(vehicle, extraId)
        end
    end

    local doorsBroken, windowsBroken, tyreBurst = {}, {}, {}
    local numWheels = tostring(GetVehicleNumberOfWheels(vehicle))

    local TyresIndex = { -- Wheel index list according to the number of vehicle wheels.
        ['2'] = {0, 4}, -- Bike and cycle.
        ['3'] = {0, 1, 4, 5}, -- Vehicle with 3 wheels (get for wheels because some 3 wheels vehicles have 2 wheels on front and one rear or the reverse).
        ['4'] = {0, 1, 4, 5}, -- Vehicle with 4 wheels.
        ['6'] = {0, 1, 2, 3, 4, 5} -- Vehicle with 6 wheels.
    }

    if TyresIndex[numWheels] then
        for tyre, idx in pairs(TyresIndex[numWheels]) do
            tyreBurst[tostring(idx)] = IsVehicleTyreBurst(vehicle, idx, false)
        end
    end

    for windowId = 0, 7 do -- 13
        windowsBroken[tostring(windowId)] = not IsVehicleWindowIntact(vehicle, windowId)
    end

    local numDoors = GetNumberOfVehicleDoors(vehicle)
    if numDoors and numDoors > 0 then
        for doorsId = 0, numDoors do
            doorsBroken[tostring(doorsId)] = IsVehicleDoorDamaged(vehicle, doorsId)
        end
    end

    return {
        model = GetEntityModel(vehicle),
        doorsBroken = doorsBroken,
        windowsBroken = windowsBroken,
        tyreBurst = tyreBurst,
        plate = Utils.Trim(GetVehicleNumberPlateText(vehicle)),
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),

        bodyHealth = Utils.Round(GetVehicleBodyHealth(vehicle), 1),
        engineHealth = Utils.Round(GetVehicleEngineHealth(vehicle), 1),
        tankHealth = Utils.Round(GetVehiclePetrolTankHealth(vehicle), 1),

        fuelLevel = Utils.Round(GetVehicleFuelLevel(vehicle), 1),
        dirtLevel = Utils.Round(GetVehicleDirtLevel(vehicle), 1),
        color1 = colorPrimary,
        color2 = colorSecondary,
        customPrimaryColor = customPrimaryColor,
        customSecondaryColor = customSecondaryColor,

        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,

        wheels = GetVehicleWheelType(vehicle),
        windowTint = GetVehicleWindowTint(vehicle),
        xenonColor = GetVehicleXenonLightsColor(vehicle),
        customXenonColor = customXenonColor,

        neonEnabled = {IsVehicleNeonLightEnabled(vehicle, 0), IsVehicleNeonLightEnabled(vehicle, 1),
                        IsVehicleNeonLightEnabled(vehicle, 2), IsVehicleNeonLightEnabled(vehicle, 3)},

        neonColor = table.pack(GetVehicleNeonLightsColour(vehicle)),
        extras = extras,
        tyreSmokeColor = table.pack(GetVehicleTyreSmokeColor(vehicle)),

        modSpoilers = GetVehicleMod(vehicle, 0),
        modFrontBumper = GetVehicleMod(vehicle, 1),
        modRearBumper = GetVehicleMod(vehicle, 2),
        modSideSkirt = GetVehicleMod(vehicle, 3),
        modExhaust = GetVehicleMod(vehicle, 4),
        modFrame = GetVehicleMod(vehicle, 5),
        modGrille = GetVehicleMod(vehicle, 6),
        modHood = GetVehicleMod(vehicle, 7),
        modFender = GetVehicleMod(vehicle, 8),
        modRightFender = GetVehicleMod(vehicle, 9),
        modRoof = GetVehicleMod(vehicle, 10),

        modEngine = GetVehicleMod(vehicle, 11),
        modBrakes = GetVehicleMod(vehicle, 12),
        modTransmission = GetVehicleMod(vehicle, 13),
        modHorns = GetVehicleMod(vehicle, 14),
        modSuspension = GetVehicleMod(vehicle, 15),
        modArmor = GetVehicleMod(vehicle, 16),

        modTurbo = IsToggleModOn(vehicle, 18),
        modSmokeEnabled = IsToggleModOn(vehicle, 20),
        modXenon = IsToggleModOn(vehicle, 22),

        modFrontWheels = GetVehicleMod(vehicle, 23),
        modBackWheels = GetVehicleMod(vehicle, 24),

        modPlateHolder = GetVehicleMod(vehicle, 25),
        modVanityPlate = GetVehicleMod(vehicle, 26),
        modTrimA = GetVehicleMod(vehicle, 27),
        modOrnaments = GetVehicleMod(vehicle, 28),
        modDashboard = GetVehicleMod(vehicle, 29),
        modDial = GetVehicleMod(vehicle, 30),
        modDoorSpeaker = GetVehicleMod(vehicle, 31),
        modSeats = GetVehicleMod(vehicle, 32),
        modSteeringWheel = GetVehicleMod(vehicle, 33),
        modShifterLeavers = GetVehicleMod(vehicle, 34),
        modAPlate = GetVehicleMod(vehicle, 35),
        modSpeakers = GetVehicleMod(vehicle, 36),
        modTrunk = GetVehicleMod(vehicle, 37),
        modHydrolic = GetVehicleMod(vehicle, 38),
        modEngineBlock = GetVehicleMod(vehicle, 39),
        modAirFilter = GetVehicleMod(vehicle, 40),
        modStruts = GetVehicleMod(vehicle, 41),
        modArchCover = GetVehicleMod(vehicle, 42),
        modAerials = GetVehicleMod(vehicle, 43),
        modTrimB = GetVehicleMod(vehicle, 44),
        modTank = GetVehicleMod(vehicle, 45),
        modDoorR = GetVehicleMod(vehicle, 47),
        modLivery = GetVehicleMod(vehicle, 48) == -1 and GetVehicleLivery(vehicle) or GetVehicleMod(vehicle, 48),
        modLightbar = GetVehicleMod(vehicle, 49)
    }
end exports('GetVehicleProperties', Utils.GetVehicleProperties)

Utils.SetVehicleProperties = function(vehicle, props)
    if not DoesEntityExist(vehicle) then
        return
    end
    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    SetVehicleModKit(vehicle, 0)

    if props.plate ~= nil then
        SetVehicleNumberPlateText(vehicle, props.plate)
    end
    if props.plateIndex ~= nil then
        SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex)
    end
    if props.bodyHealth ~= nil then
        SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0)
    end
    if props.engineHealth ~= nil then
        SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0)
    end
    if props.tankHealth ~= nil then
        SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0)
    end
    if props.fuelLevel ~= nil then
        SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
    end
    if props.dirtLevel ~= nil then
        SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0)
    end
    if props.customPrimaryColor ~= nil then
        SetVehicleCustomPrimaryColour(vehicle, props.customPrimaryColor[1], props.customPrimaryColor[2],
            props.customPrimaryColor[3])
    end
    if props.customSecondaryColor ~= nil then
        SetVehicleCustomSecondaryColour(vehicle, props.customSecondaryColor[1], props.customSecondaryColor[2],
            props.customSecondaryColor[3])
    end
    if props.color1 ~= nil then
        SetVehicleColours(vehicle, props.color1, colorSecondary)
    end
    if props.color2 ~= nil then
        SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2)
    end
    if props.pearlescentColor ~= nil then
        SetVehicleExtraColours(vehicle, props.pearlescentColor, wheelColor)
    end
    if props.wheelColor ~= nil then
        SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor)
    end
    if props.wheels ~= nil then
        SetVehicleWheelType(vehicle, props.wheels)
    end
    if props.windowTint ~= nil then
        SetVehicleWindowTint(vehicle, props.windowTint)
    end

    if props.neonEnabled ~= nil then
        SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
        SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
        SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
        SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
    end

    if props.extras ~= nil then
        for extraId, enabled in pairs(props.extras) do
            SetVehicleExtra(vehicle, tonumber(extraId), enabled and 0 or 1)
        end
    end

    if props.neonColor ~= nil then
        SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
    end
    if props.xenonColor ~= nil then
        SetVehicleXenonLightsColor(vehicle, props.xenonColor)
    end
    if props.customXenonColor ~= nil then
        SetVehicleXenonLightsCustomColor(vehicle, props.customXenonColor[1], props.customXenonColor[2],
            props.customXenonColor[3])
    end
    if props.modSmokeEnabled ~= nil then
        ToggleVehicleMod(vehicle, 20, true)
    end
    if props.tyreSmokeColor ~= nil then
        SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
    end
    if props.modSpoilers ~= nil then
        SetVehicleMod(vehicle, 0, props.modSpoilers, false)
    end
    if props.modFrontBumper ~= nil then
        SetVehicleMod(vehicle, 1, props.modFrontBumper, false)
    end
    if props.modRearBumper ~= nil then
        SetVehicleMod(vehicle, 2, props.modRearBumper, false)
    end
    if props.modSideSkirt ~= nil then
        SetVehicleMod(vehicle, 3, props.modSideSkirt, false)
    end
    if props.modExhaust ~= nil then
        SetVehicleMod(vehicle, 4, props.modExhaust, false)
    end
    if props.modFrame ~= nil then
        SetVehicleMod(vehicle, 5, props.modFrame, false)
    end
    if props.modGrille ~= nil then
        SetVehicleMod(vehicle, 6, props.modGrille, false)
    end
    if props.modHood ~= nil then
        SetVehicleMod(vehicle, 7, props.modHood, false)
    end
    if props.modFender ~= nil then
        SetVehicleMod(vehicle, 8, props.modFender, false)
    end
    if props.modRightFender ~= nil then
        SetVehicleMod(vehicle, 9, props.modRightFender, false)
    end
    if props.modRoof ~= nil then
        SetVehicleMod(vehicle, 10, props.modRoof, false)
    end
    if props.modEngine ~= nil then
        SetVehicleMod(vehicle, 11, props.modEngine, false)
    end
    if props.modBrakes ~= nil then
        SetVehicleMod(vehicle, 12, props.modBrakes, false)
    end
    if props.modTransmission ~= nil then
        SetVehicleMod(vehicle, 13, props.modTransmission, false)
    end
    if props.modHorns ~= nil then
        SetVehicleMod(vehicle, 14, props.modHorns, false)
    end
    if props.modSuspension ~= nil then
        SetVehicleMod(vehicle, 15, props.modSuspension, false)
    end
    if props.modArmor ~= nil then
        SetVehicleMod(vehicle, 16, props.modArmor, false)
    end
    if props.modTurbo ~= nil then
        ToggleVehicleMod(vehicle, 18, props.modTurbo)
    end
    if props.modXenon ~= nil then
        ToggleVehicleMod(vehicle, 22, props.modXenon)
    end
    if props.modFrontWheels ~= nil then
        SetVehicleMod(vehicle, 23, props.modFrontWheels, false)
    end
    if props.modBackWheels ~= nil then
        SetVehicleMod(vehicle, 24, props.modBackWheels, false)
    end
    if props.modPlateHolder ~= nil then
        SetVehicleMod(vehicle, 25, props.modPlateHolder, false)
    end
    if props.modVanityPlate ~= nil then
        SetVehicleMod(vehicle, 26, props.modVanityPlate, false)
    end
    if props.modTrimA ~= nil then
        SetVehicleMod(vehicle, 27, props.modTrimA, false)
    end
    if props.modOrnaments ~= nil then
        SetVehicleMod(vehicle, 28, props.modOrnaments, false)
    end
    if props.modDashboard ~= nil then
        SetVehicleMod(vehicle, 29, props.modDashboard, false)
    end
    if props.modDial ~= nil then
        SetVehicleMod(vehicle, 30, props.modDial, false)
    end
    if props.modDoorSpeaker ~= nil then
        SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false)
    end
    if props.modSeats ~= nil then
        SetVehicleMod(vehicle, 32, props.modSeats, false)
    end
    if props.modSteeringWheel ~= nil then
        SetVehicleMod(vehicle, 33, props.modSteeringWheel, false)
    end
    if props.modShifterLeavers ~= nil then
        SetVehicleMod(vehicle, 34, props.modShifterLeavers, false)
    end
    if props.modAPlate ~= nil then
        SetVehicleMod(vehicle, 35, props.modAPlate, false)
    end
    if props.modSpeakers ~= nil then
        SetVehicleMod(vehicle, 36, props.modSpeakers, false)
    end
    if props.modTrunk ~= nil then
        SetVehicleMod(vehicle, 37, props.modTrunk, false)
    end
    if props.modHydrolic ~= nil then
        SetVehicleMod(vehicle, 38, props.modHydrolic, false)
    end
    if props.modEngineBlock ~= nil then
        SetVehicleMod(vehicle, 39, props.modEngineBlock, false)
    end
    if props.modAirFilter ~= nil then
        SetVehicleMod(vehicle, 40, props.modAirFilter, false)
    end
    if props.modStruts ~= nil then
        SetVehicleMod(vehicle, 41, props.modStruts, false)
    end
    if props.modArchCover ~= nil then
        SetVehicleMod(vehicle, 42, props.modArchCover, false)
    end
    if props.modAerials ~= nil then
        SetVehicleMod(vehicle, 43, props.modAerials, false)
    end
    if props.modTrimB ~= nil then
        SetVehicleMod(vehicle, 44, props.modTrimB, false)
    end
    if props.modTank ~= nil then
        SetVehicleMod(vehicle, 45, props.modTank, false)
    end
    if props.modWindows ~= nil then
        SetVehicleMod(vehicle, 46, props.modWindows, false)
    end

    if props.modLivery ~= nil then
        SetVehicleMod(vehicle, 48, props.modLivery, false)
        SetVehicleLivery(vehicle, props.modLivery)
    end

    if props.windowsBroken ~= nil then
        for k, v in pairs(props.windowsBroken) do
            if v then
                SmashVehicleWindow(vehicle, tonumber(k))
            end
        end
    end

    if props.doorsBroken ~= nil then
        for k, v in pairs(props.doorsBroken) do
            if v then
                SetVehicleDoorBroken(vehicle, tonumber(k), true)
            end
        end
    end

    if props.tyreBurst ~= nil then
        for k, v in pairs(props.tyreBurst) do
            if v then
                SetVehicleTyreBurst(vehicle, tonumber(k), true, 1000.0)
            end
        end
    end
end exports('SetVehicleProperties', Utils.SetVehicleProperties)

Utils.stopres = function(fungsi)
    AddEventHandler('onResourceStop', function()
        if (GetCurrentResourceName() ~= 'fmid_garasi') then
          return
        end
        fungsi()
    end)
end
if not IsDuplicityVersion() then
    AddTextEntry('BLIP_PROPCAT', 'Garasi Lainnya')
end
Utils.BuatBlip = function(name, coords, sprite, colour, scale, category)
    local blip = AddBlipForCoord(coords)

    SetBlipSprite (blip, sprite)
    SetBlipScale  (blip, scale or 1.0)
    SetBlipColour (blip, colour)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)
    if category then
        
        SetBlipCategory(blip, category)
    end
    return blip
end

if IsDuplicityVersion() then
    Utils.KendaraanMasihDiluar = function(list)
        local allveh = GetAllVehicles()
        for i=1, #list do
            for a=1, #allveh do
                if Utils.Trim(GetVehicleNumberPlateText(allveh[a])) == Utils.Trim(list[i].plate) then
                    dapet = allveh[a]
                    list[i].disabled = true
                end
            end
        end
        return list, (#list == 1 and dapet or nil)
    end exports('KendaraanMasihDiluar', Utils.KendaraanMasihDiluar)
end

Utils.Debug = function(msg)
    print('fmid_garasi debug: '..msg)
end

Utils.AddRadial = function(id, data)
    -- if Framework.GetMeta('interaksigarasi') and Framework.GetMeta('interaksigarasi') == 'f1' or grs.Interaksi == 'radial' then
    if not grs.LockInteraksi and Framework.GetMeta('interaksigarasi') and Framework.GetMeta('interaksigarasi') == 'f1' then
        bisa = true
    elseif not grs.LockInteraksi and Framework.GetMeta('interaksigarasi') and Framework.GetMeta('interaksigarasi') ~= 'f1' then
        bisa = false
    elseif grs.Interaksi == 'radial' then
        bisa = true
    end
    if bisa then
        if grs.radial == 'ox' then
            lib.addRadialItem({
                id = id,
                icon = data.icon,
                label = data.label,
                onSelect = data.func
            })
        elseif grs.radial == 'qb' then
            exports[grs.namaradial]:AddOption({
                id = id,
                title = data.label,
                icon = data.icon,
                event = data.event,
                type = 'client',
                shouldClose = true,
            }, id)
        elseif grs.radial == 'np' then
            exports[grs.namaradial]:addRadial(id, {
                label = data.label,
                icon = data.icon,
                func = data.event,
                canInteract = data.interact,
            })
        end
    end
end

Utils.RemoveRadial = function(id)
    if not grs.LockInteraksi and Framework.GetMeta('interaksigarasi') and Framework.GetMeta('interaksigarasi') == 'f1' then
        bisa = true
    elseif not grs.LockInteraksi and Framework.GetMeta('interaksigarasi') and Framework.GetMeta('interaksigarasi') ~= 'f1' then
        bisa = false
    elseif grs.Interaksi == 'radial' then
        bisa = true
    end
    if bisa then
        if grs.radial == 'ox' then
            lib.removeRadialItem(id)
        elseif grs.radial == 'qb' then
            exports[grs.namaradial]:RemoveOption(id)
        elseif grs.radial == 'np' then
            exports[grs.namaradial]:removeRadial(id)
        end
    end
end

Utils.ButuhResource = function(data)
    for i=1, #data do
        if GetResourceState(data[i]) ~= 'started' then
            return false, data[i]
        end
    end
    return true
end

local stringCharset = {}
local numberCharset = {}
local globalCharset = {}

for i = 48, 57 do numberCharset[#numberCharset + 1] = string.char(i) end
for i = 65, 90 do stringCharset[#stringCharset + 1] = string.char(i) end
for i = 97, 122 do stringCharset[#stringCharset + 1] = string.char(i) end

for i = 1, #numberCharset do globalCharset[#globalCharset + 1] = numberCharset[i] end
for i = 1, #stringCharset do globalCharset[#globalCharset + 1] = stringCharset[i] end

---Returns a random letter
---@param length integer
---@return string
function RandomLetter(length) -- luacheck: ignore
    if length <= 0 then return '' end
    return RandomLetter(length - 1) .. stringCharset[math.random(1, #stringCharset)]
end

---Returns a random number
---@param length integer
---@return string
function RandomNumber(length) -- luacheck: ignore
    if length <= 0 then return '' end
    return RandomNumber(length - 1) .. numberCharset[math.random(1, #numberCharset)]
end

---Returns a random number or letter
---@param length integer
---@return string
function RandomNumberOrLetter(length) -- luacheck: ignore
    if length <= 0 then return '' end
    return RandomNumberOrLetter(length - 1) .. globalCharset[math.random(1, #globalCharset)]
end

Utils.RandomLetter = RandomLetter
Utils.RandomNumber = RandomNumber
Utils.RandomNumberOrLetter = RandomNumberOrLetter

Utils.GenerateRandomPlate = function(pattern) -- luacheck: ignore
    local newPattern = ''
    local skipNext = false
    for i = 1, #pattern do
        if not skipNext then
            local last = i == #pattern
            local c = pattern:sub(i, i)
            local nextC = last and '\0' or pattern:sub(i + 1, i + 1)
            local curC

            if c == '1' then
                curC = Utils.RandomNumber(1)
            elseif c == 'A' then
                curC = Utils.RandomLetter(1)
            elseif c == '.' then
                curC = Utils.RandomNumberOrLetter(1)
            elseif c == '^' and (nextC == '1' or nextC == 'A' or nextC == '.') then
                curC = nextC
                skipNext = true
            else
                curC = c
            end

            newPattern = newPattern .. curC
        else
            skipNext = false
        end
    end

    return string.upper(newPattern)
end