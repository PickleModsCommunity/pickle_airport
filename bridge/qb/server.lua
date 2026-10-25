if GetResourceState('qb-core') ~= 'started' then return end

QBCore = exports['qb-core']:GetCoreObject()

function RegisterCallback(name, cb)
    QBCore.Functions.CreateCallback(name, cb)
end

function ShowNotification(target, text)
	TriggerClientEvent(GetCurrentResourceName()..":showNotification", target, text)
end

function Search(source, name)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return 0 end
    if name ~= "money" and name ~= "cash" then 
        local item = xPlayer.Functions.GetItemByName(name)
        if item ~= nil then 
            return item.amount
        else
            return 0
        end
    else
        return xPlayer.PlayerData.money['cash']
    end
end

function AddItem(source, name, amount)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return false end
    if name == "money" or name == "cash" then 
        return xPlayer.Functions.AddMoney("cash", amount)
    else
        return xPlayer.Functions.AddItem(name, amount)
    end
end

function RemoveItem(source, name, amount)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return false end
    if name == "money" or name == "cash" then 
        return xPlayer.Functions.RemoveMoney("cash", amount)
    else
        return xPlayer.Functions.RemoveItem(name, amount)
    end
end

function RegisterUsableItem(...)
    QBCore.Functions.CreateUseableItem(...)
end

function PermissionCheck(source, perm)
    local p = QBCore.Functions.GetPlayer(source)
    local job = p and p.PlayerData.job
    if not job then return false end
    if (perm == "flight") then 
        return (job.name == "airport")
    elseif perm == "view_tracker" then
        return job.name == "airport" or job.name == "police"
    elseif (perm == "pilot_mission") then 
        return (job.name == "airport")
    end
end
