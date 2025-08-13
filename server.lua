local QBCore = exports['qb-core']:GetCoreObject()

-- officers with lights ON
local active = {} -- [src] = true

local function isPolice(src)
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return false end
    local job = p.PlayerData and p.PlayerData.job
    return job and job.name == "police"
end

local function forEachPolice(fn)
    local players = QBCore.Functions.GetQBPlayers()
    for _, p in pairs(players) do
        local job = p.PlayerData and p.PlayerData.job
        if job and job.name == "police" then
            fn(p.PlayerData.source)
        end
    end
end

local function unitLabel(src)
    local p = QBCore.Functions.GetPlayer(src)
    local md = p and p.PlayerData and p.PlayerData.metadata or {}
    local ci = p and p.PlayerData and p.PlayerData.charinfo or {}

    local name = md.callsign or ci.callsign
    if not name or name == "" then
        if ci.firstname then
            name = (ci.firstname or "") .. " " .. (ci.lastname or "")
        else
            name = p and p.PlayerData and p.PlayerData.name or tostring(src)
        end
    end
    return Config.BuildUnitLabel(src, name)
end

RegisterNetEvent('lvc_blip:state', function(enabled)
    local src = source
    if not isPolice(src) then return end

    if enabled then
        active[src] = true
        local label = unitLabel(src)
        forEachPolice(function(ps)
            TriggerClientEvent('lvc_blip:client_set', ps, src, true, label)
        end)
    else
        if active[src] then
            active[src] = nil
            forEachPolice(function(ps)
                TriggerClientEvent('lvc_blip:client_set', ps, src, false, nil)
            end)
        end
    end
end)

RegisterNetEvent('lvc_blip:updatePos', function(coords)
    local src = source
    if not active[src] then return end
    if not isPolice(src) then return end
    forEachPolice(function(ps)
        TriggerClientEvent('lvc_blip:client_pos', ps, src, coords)
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if active[src] then
        active[src] = nil
        forEachPolice(function(ps)
            TriggerClientEvent('lvc_blip:client_set', ps, src, false, nil)
        end)
    end
end)

-- Important: ignore the event parameter; fetch current job from PlayerData
RegisterNetEvent('QBCore:Server:OnJobUpdate', function(_ignored)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    local job = p.PlayerData and p.PlayerData.job
    local isCop = job and job.name == "police"

    if not isCop and active[src] then
        active[src] = nil
        forEachPolice(function(ps)
            TriggerClientEvent('lvc_blip:client_set', ps, src, false, nil)
        end)
    end
end)
