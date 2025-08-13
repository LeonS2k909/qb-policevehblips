local QBCore = exports['qb-core']:GetCoreObject()

local lastSiren = false
local updating  = false
local myJob     = nil
local blips     = {} -- [serverId] = blip

local function isPolice()
    return myJob and myJob.name == "police"
end

-- job tracking
CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(200) end
    local pdata = QBCore.Functions.GetPlayerData()
    myJob = pdata and pdata.job or myJob
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local pdata = QBCore.Functions.GetPlayerData()
    myJob = pdata and pdata.job or myJob
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    myJob = job
    if not isPolice() and lastSiren then
        lastSiren = false
        updating  = false
        TriggerServerEvent('lvc_blip:state', false)
    end
end)

-- siren watcher (Luxart compatible via natives)
CreateThread(function()
    while true do
        Wait(200)

        if not isPolice() then
            if lastSiren then
                lastSiren = false
                updating  = false
                TriggerServerEvent('lvc_blip:state', false)
            end
            goto cont
        end

        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            if lastSiren then
                lastSiren = false
                updating  = false
                TriggerServerEvent('lvc_blip:state', false)
            end
            goto cont
        end

        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
            if lastSiren then
                lastSiren = false
                updating  = false
                TriggerServerEvent('lvc_blip:state', false)
            end
            goto cont
        end

        -- only continue if vehicle siren can be toggled and is in an emergency class
        local vClass = GetVehicleClass(veh)
        if vClass ~= 18 and vClass ~= 20 then -- 18 = emergency, 20 = commercial (adjust as needed)
            if lastSiren then
                lastSiren = false
                updating  = false
                TriggerServerEvent('lvc_blip:state', false)
            end
            goto cont
        end


        local sirenOn = IsVehicleSirenOn(veh) -- boolean
        if sirenOn ~= lastSiren then
            lastSiren = sirenOn
            TriggerServerEvent('lvc_blip:state', sirenOn)

            if sirenOn and not updating then
                updating = true
                CreateThread(function()
                    while updating do
                        local v = GetVehiclePedIsIn(PlayerPedId(), false)
                        if v == 0 or not IsPedInAnyVehicle(PlayerPedId(), false) or not IsVehicleSirenOn(v) then
                            updating  = false
                            lastSiren = false
                            TriggerServerEvent('lvc_blip:state', false)
                            break
                        end
                        local coords = GetEntityCoords(v)
                        TriggerServerEvent('lvc_blip:updatePos', vector3(coords.x, coords.y, coords.z))
                        Wait(Config.UpdateInterval)
                    end
                end)
            elseif not sirenOn then
                updating = false
            end
        end

        ::cont::
    end
end)

-- receive blip set/clear
RegisterNetEvent('lvc_blip:client_set', function(src, enabled, label)
    if enabled then
        if blips[src] and DoesBlipExist(blips[src]) then return end
        local blip = AddBlipForCoord(0.0, 0.0, 0.0)
        SetBlipSprite(blip, Config.Sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Scale)
        SetBlipColour(blip, Config.Color)
        SetBlipAsShortRange(blip, Config.ShortRange)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(label or "Unit")
        EndTextCommandSetBlipName(blip)
        blips[src] = blip
    else
        if blips[src] and DoesBlipExist(blips[src]) then
            RemoveBlip(blips[src])
        end
        blips[src] = nil
    end
end)

-- receive position
RegisterNetEvent('lvc_blip:client_pos', function(src, coords)
    local blip = blips[src]
    if blip and DoesBlipExist(blip) then
        SetBlipCoords(blip, coords.x, coords.y, coords.z)
    end
end)

-- cleanup
AddEventHandler('onClientResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, b in pairs(blips) do
        if b and DoesBlipExist(b) then RemoveBlip(b) end
    end
end)
