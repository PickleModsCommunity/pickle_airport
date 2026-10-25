-- Loaded after bridges, before modules.
function AirportIdentity(src)
    if ESX then local p=ESX.GetPlayerFromId(src); return p and p.identifier end
    if QBCore then local p=QBCore.Functions.GetPlayer(src); return p and p.PlayerData.citizenid end
end
function AirportNear(src, coords, radius)
    local ped=GetPlayerPed(src)
    return ped~=0 and GetEntityHealth(ped)>0 and coords and #(GetEntityCoords(ped)-vector3(coords.x,coords.y,coords.z)) <= radius
end
function AirportAircraft(src)
    local ped=GetPlayerPed(src)
    local v=ped~=0 and GetVehiclePedIsIn(ped,false) or 0
    if v==0 or not DoesEntityExist(v) or GetPedInVehicleSeat(v,-1)~=ped then return end
    local t=GetVehicleType(v)
    if t=='plane' or t=='heli' then return v,t end
end
function AirportInteger(v,min,max)
    return type(v)=='number' and v==v and v%1==0 and v>=min and v<=max
end
