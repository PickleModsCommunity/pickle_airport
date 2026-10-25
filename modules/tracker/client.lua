TrackedAircraft = {}

function GetCurrentAircraft()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if (vehicle and GetPedInVehicleSeat(vehicle, -1) == ped) then
        if (IsPedInAnyPlane(ped)) then 
            return vehicle, 1
        elseif (IsPedInAnyHeli(ped)) then 
            return vehicle, 2
        end
    end
end

function UpdateClientTracker(source, data)
    if (TrackedAircraft[source] and TrackedAircraft[source].blip) then 
        RemoveBlip(TrackedAircraft[source].blip)
    end
    if (data) then 
        TrackedAircraft[source] = data
        
        local info = Config.Tracker.BlipTypes[data.aircraftType]
            
        if (PermissionCheck("view_tracker")) then 
            TrackedAircraft[source].blip = CreateBlip({
                Location = data.coords,
                Rotation = data.heading,
                Label = info.Label,
                ID = info.ID,
                Scale = info.Scale,
                Color = info.Color
            })
        end
    else
        TrackedAircraft[source] = nil
    end
end

RegisterNetEvent("pickle_airport:tracker:receiveAircraftUpdate", function(source, data)
    UpdateClientTracker(source, data)
end)
RegisterNetEvent('pickle_airport:tracker:snapshot',function(snapshot)
    for id,data in pairs(TrackedAircraft) do if data.blip then RemoveBlip(data.blip) end end
    TrackedAircraft={}
    if not PermissionCheck('view_tracker') then return end
    for id,data in pairs(snapshot) do
        if Config.Tracker.BlipTypes[data.aircraftType] then UpdateClientTracker(id,data) end
    end
end)
CreateThread(function()
    while true do
        Wait(1000)
        if not PermissionCheck('view_tracker') then
            for id,data in pairs(TrackedAircraft) do if data.blip then RemoveBlip(data.blip) end; TrackedAircraft[id]=nil end
        end
    end
end)
