if GetResourceState('es_extended') ~= 'started' then return end

ESX = exports.es_extended:getSharedObject()

function ShowNotification(text)
	ESX.ShowNotification(text)
end

function ShowHelpNotification(text)
	ESX.ShowHelpNotification(text)
end

function ServerCallback(name, cb, ...)
    ESX.TriggerServerCallback(name, cb,  ...)
end

function PermissionCheck(perm)
    local job = ESX.GetPlayerData().job
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

RegisterNetEvent(GetCurrentResourceName()..":showNotification", function(text)
    ShowNotification(text)
end)