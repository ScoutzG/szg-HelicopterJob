local QBCore = exports['qb-core']:GetCoreObject()
local Hired = false
local HasPackage = false
local DeliveriesCount = 0
local Delivered = false
local PackageDelivered = false
local ownsVan = false
local activeOrder = false

CreateThread(function()
    local pegasusjobBlip = AddBlipForCoord(vector3(Config.BossCoords.x, Config.BossCoords.y, Config.BossCoords.z)) 
    SetBlipSprite(pegasusjobBlip, 574)
    SetBlipAsShortRange(pegasusjobBlip, true)
    SetBlipScale(pegasusjobBlip, 0.0)
    SetBlipColour(pegasusjobBlip, 63)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pegasus")
    EndTextCommandSetBlipName(pegasusjobBlip)
end)

function ClockInPed()

    if not DoesEntityExist(pegasusBoss) then

        RequestModel(Config.BossModel) while not HasModelLoaded(Config.BossModel) do Wait(0) end

        pegasusBoss = CreatePed(0, Config.BossModel, Config.BossCoords, false, false)
        
        SetEntityAsMissionEntity(pegasusBoss)
        SetPedFleeAttributes(pegasusBoss, 0, 0)
        SetBlockingOfNonTemporaryEvents(pegasusBoss, true)
        SetEntityInvincible(pegasusBoss, true)
        FreezeEntityPosition(pegasusBoss, true)
        loadAnimDict("amb@world_human_leaning@female@wall@back@holding_elbow@idle_a")        
        TaskPlayAnim(pegasusBoss, "amb@world_human_leaning@female@wall@back@holding_elbow@idle_a", "idle_a", 8.0, 1.0, -1, 01, 0, 0, 0, 0)

        exports['qb-target']:AddTargetEntity(pegasusBoss, { 
            options = {
                { 
                    type = "client",
                    event = "sz_pegasusjob:client:startJob",
                    icon = "fa-solid fa-pegasus-package",
                    label = "Start Work",
                    canInteract = function()
                        return not Hired
                    end,
                },
                { 
                    type = "client",
                    event = "sz_pegasusjob:client:finishWork",
                    icon = "fa-solid fa-pegasus-package",
                    label = "Finish Work",
                    canInteract = function()
                        return Hired
                    end,
                },
            }, 
            distance = 1.5, 
        })
    end
end

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() == resource then
        PlayerJob = QBCore.Functions.GetPlayerData().job
        ClockInPed()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    ClockInPed()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    exports['qb-target']:RemoveZone("deliverZone")
    RemoveBlip(JobBlip)
    Hired = false
    HasPackage = false
    DeliveriesCount = 0
    Delivered = false
    PackageDelivered = false
    ownsVan = false
    activeOrder = false  
    DeletePed(pegasusBoss)
end)

AddEventHandler('onResourceStop', function(resourceName) 
	if GetCurrentResourceName() == resourceName then
        exports['qb-target']:RemoveZone("deliverZone")
        RemoveBlip(JobBlip)
        Hired = false
        HasPackage = false
        DeliveriesCount = 0
        Delivered = false
        PackageDelivered = false
        ownsVan = false
        activeOrder = false
        DeletePed(pegasusBoss)  
	end 
end)

CreateThread(function()
    DecorRegister("pegasus_job", 1)
end)

function PullOutVehicle()

        local coords = Config.VehicleSpawn
        QBCore.Functions.SpawnVehicle(Config.Vehicle, function(pegasusHelicopter)
            SetVehicleNumberPlateText(pegasusHelicopter, "pegasus"..tostring(math.random(1000, 9999)))
            SetVehicleColours(pegasusHelicopter, 1, 10)
            SetVehicleDirtLevel(pegasusHelicopter, 1)
            DecorSetFloat(pegasusHelicopter, "pegasus_job", 1)
            TaskWarpPedIntoVehicle(PlayerPedId(), pegasusHelicopter, -1)
            TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(pegasusHelicopter))
            SetVehicleEngineOn(pegasusHelicopter, true, true)
            exports[Config.FuelScript]:SetFuel(pegasusHelicopter, 100.0)
            exports['qb-target']:AddTargetEntity(pegasusHelicopter, {
                options = {
                    {
                        icon = "fa-solid fa-pegasus-package",
                        label = "Take Package",
                        action = function(entity) TakePackage() end,
                        canInteract = function() 
                            return Hired and activeOrder and not HasPackage
                        end,
                        
                    },
                },
                distance = 2.5
            })
        end, coords, true)
        Hired = true
        ownsVan = true
        NextDelivery()
end


RegisterNetEvent('sz_pegasusjob:client:startJob', function()
    if not Hired then
        PullOutVehicle()
    end
end)


RegisterNetEvent('sz_pegasusjob:client:deliverpackage', function()
    if HasPackage and Hired and not PackageDelivered then
        TriggerServerEvent('sz_pegasusjob:server:Payment', DeliveriesCount)
        TriggerEvent('animations:client:EmoteCommandStart', {"knock"})
        PackageDelivered = true
        QBCore.Functions.Progressbar("knock", "Delivering Package", 7000, false, false, {
            disableMovement = true,
            disableHelicopterMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function()
            DeliveriesCount = DeliveriesCount + 1
            RemoveBlip(JobBlip)
            exports['qb-target']:RemoveZone("deliverZone")
            HasPackage = false
            activeOrder = false
            PackageDelivered = false
            DetachEntity(prop, 1, 1)
            DeleteObject(prop)
            Wait(1000)
            ClearPedSecondaryTask(PlayerPedId())
            QBCore.Functions.Notify("Package Delivered. Please wait for your next delivery!", "success") 
            SetTimeout(5000, function()    
                NextDelivery()
            end)
        end)
    else
        QBCore.Functions.Notify("You need the Package from the helicopter.", "error") 
    end
end)


function loadAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		RequestAnimDict(dict)
		Wait(0)
	end
end

function TakePackage()
    local player = PlayerPedId()
    local pos = GetEntityCoords(player)
    if not IsPedInAnyVehicle(player, false) then
        local ad = "anim@heists@box_carry@"
        local prop_name = 'hei_prop_heist_box'
        if DoesEntityExist(player) and not IsEntityDead(player) then
            if not HasPackage then
                if #(pos - vector3(newDelivery.x, newDelivery.y, newDelivery.z)) < 30.0 then
                    loadAnimDict(ad)
                    local x,y,z = table.unpack(GetEntityCoords(player))
                    prop = CreateObject(GetHashKey(prop_name), x, y, z+0.2,  true,  true, true)
                    AttachEntityToEntity(prop, player, GetPedBoneIndex(player, 60309), 0.2, 0.08, 0.2, -45.0, 290.0, 0.0, true, true, false, true, 1, true)
                    TaskPlayAnim(player, ad, "idle", 3.0, -8, -1, 63, 0, 0, 0, 0 )
                    HasPackage = true
                else
                    QBCore.Functions.Notify("You're not close enough to the customer's door!", "error")
                end
            end
        end
    end
end


function NextDelivery()
    if not activeOrder then
        newDelivery = Config.JobLocs[math.random(1, #Config.JobLocs)]
        JobBlip = AddBlipForCoord(newDelivery.x, newDelivery.y, newDelivery.z)
        SetBlipSprite(JobBlip, 1)
        SetBlipDisplay(JobBlip, 4)
        SetBlipScale(JobBlip, 0.8)
        SetBlipFlashes(JobBlip, true)
        SetBlipAsShortRange(JobBlip, true)
        SetBlipColour(JobBlip, 50)
        SetBlipRoute(JobBlip, true)
        SetBlipRouteColour(JobBlip, 68)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Next Customer")
        EndTextCommandSetBlipName(JobBlip)
        exports['qb-target']:AddCircleZone("deliverZone", vector3(newDelivery.x, newDelivery.y, newDelivery.z), 1.3,{ name = "deliverZone", debugPoly = false, useZ=true, }, { options = { { type = "client", event = "sz_pegasusjob:client:deliverpackage", icon = "fa-solid fa-pegasus-package", label = "Deliver package"}, }, distance = 1.5 })
        activeOrder = true
        QBCore.Functions.Notify("You have a new delivery!", "success")
       
    end
end

RegisterNetEvent('sz_pegasusjob:client:finishWork', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local veh = QBCore.Functions.GetClosestVehicle()
    local finishspot = vector3(Config.BossCoords.x, Config.BossCoords.y, Config.BossCoords.z)
    if #(pos - finishspot) < 10.0 then
        if Hired then
            if DecorExistOn((veh), "pegasus_job") then
                QBCore.Functions.DeleteVehicle(veh)
                RemoveBlip(JobBlip)
                Hired = false
                HasPackage = false
                ownsVan = false
                activeOrder = false
                if DeliveriesCount > 0 then
                   
                else
                    QBCore.Functions.Notify("You didn't complete any deliveries so you weren't paid.", "error")
                    PullOutVehicle()
                end
                DeliveriesCount = 0
            else
                QBCore.Functions.Notify("You must return your work vehicle to get paid.", "error")
                PullOutVehicle()
                return
            end
        end
    end
end)


