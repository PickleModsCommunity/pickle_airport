if GetResourceState('es_extended') ~= 'started' then return end

ESX = exports.es_extended:getSharedObject()

function RegisterCallback(name, cb)
    ESX.RegisterServerCallback(name, cb)
end

function ShowNotification(target, text)
	TriggerClientEvent(GetCurrentResourceName()..":showNotification", target, text)
end

function Search(source, name)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    if (name ~= "money") then
        local item = xPlayer.getInventoryItem(name)
        if item ~= nil then 
            return item.count
        else
            return 0
        end
    else
        return xPlayer.getMoney()
    end
end

function AddItem(source,name,amount)
    local p=ESX.GetPlayerFromId(source)
    if not p then return false end
    local before=Search(source,name)

    if name=='money' then p.addMoney(amount) else p.addInventoryItem(name,amount) end
    return Search(source,name)==before + amount
end

function RemoveItem(source,name,amount)
    local p=ESX.GetPlayerFromId(source)
    if not p then return false end
    local before=Search(source,name)
    if before<amount then return false end
    if name=='money' then p.removeMoney(amount) else p.removeInventoryItem(name,amount) end
    return Search(source,name)==before - amount
end

function RegisterUsableItem(...)
    ESX.RegisterUsableItem(...)
end

function PermissionCheck(source, perm)
    local p = ESX.GetPlayerFromId(source)
    local job = p and p.job
    if not job then return false end
    if (perm == "flight") then 
        return (job.name == "airport")
    elseif perm == "view_tracker" then
        return job.name == "airport" or job.name == "police"
    elseif (perm == "pilot_mission") then 
        return (job.name == "airport")
    end
end