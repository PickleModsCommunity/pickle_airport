if GetResourceState('qb-core') ~= 'started' then return end

QBCore = exports['qb-core']:GetCoreObject()

function GiveKeys(vehicle) 
	TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(vehicle))
end

function ShowNotification(text)
	QBCore.Functions.Notify(text)
end

function ShowHelpNotification(text)
    AddTextEntry('qbHelpNotification', text)
    BeginTextCommandDisplayHelp('qbHelpNotification')
    EndTextCommandDisplayHelp(0, false, false, -1)
end

function ServerCallback(name, cb, ...)
    QBCore.Functions.TriggerCallback(name, cb,  ...)
end

RegisterNetEvent(GetCurrentResourceName()..":showNotification", function(text)
    ShowNotification(text)
end)

function PermissionCheck(perm)
    local job = QBCore.Functions.GetPlayerData().job
    if not job then return false end
    if (perm == "flight") then 
        return (job.name == "airport")
    elseif (perm == "hangar") then 
        return (job.name == "airport")
    elseif (perm == "pilot_mission") then 
        return (job.name == "airport")
    elseif (perm == "view_tracker") then 
        return (job.name == "airport" or job.name == "police")
    end
end
