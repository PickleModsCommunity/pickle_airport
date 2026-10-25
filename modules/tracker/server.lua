-- Tracker data is derived entirely from server entities. No client broadcast endpoint.
TrackedAircraft={}
CreateThread(function()
    while true do
        Wait(math.max(1,Config.Tracker.UpdateTime)*1000)
        local current={}
        for _,id in ipairs(GetPlayers()) do
            local src=tonumber(id); local vehicle,t=AirportAircraft(src)
            if vehicle then current[src]={coords=GetEntityCoords(vehicle),heading=GetEntityHeading(vehicle),aircraftType=t=='plane' and 1 or 2} end
        end
        TrackedAircraft=current
        for _,id in ipairs(GetPlayers()) do
            local src=tonumber(id)
            TriggerClientEvent('pickle_airport:tracker:snapshot',src,PermissionCheck(src,'view_tracker') and current or {})
        end
    end
end)
AddEventHandler('playerDropped',function()
    TrackedAircraft[source]=nil
    for _,id in ipairs(GetPlayers()) do
        local src=tonumber(id)
        if PermissionCheck(src,'view_tracker') then TriggerClientEvent('pickle_airport:tracker:receiveAircraftUpdate',src,source,nil) end
    end
end)
