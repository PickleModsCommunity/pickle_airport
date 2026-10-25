local sessions={}
RegisterCallback('pickle_airport:beginMission',function(src,cb,index)
    local cfg=AirportInteger(index,1,#Config.Missions.Sequences) and Config.Missions.Sequences[index]
    local aircraft=AirportAircraft(src)
    if not cfg or not aircraft or sessions[src] or not PermissionCheck(src,'pilot_mission') then cb(false); return end
    sessions[src]={index=index, aircraft=aircraft, identity=AirportIdentity(src), started=os.time(), pickup=false}
    cb(true)
end)
RegisterNetEvent('pickle_airport:cancelMission',function() sessions[source]=nil end)
RegisterNetEvent('pickle_airport:finishedMission',function(index)
    local src=source; local session=sessions[src]
    if not session or session.index~=index or session.identity~=AirportIdentity(src)
        or not session.pickup or os.time()-session.started<10 or not PermissionCheck(src,'pilot_mission') then return end
    local cfg=Config.Missions.Sequences[index]
    local destination=cfg.PackageDropoff or cfg.PassengerDropoff
    if not DoesEntityExist(session.aircraft) or not AirportNear(src,destination,8)
        or #(GetEntityCoords(session.aircraft)-destination)>45 then return end
    sessions[src]=nil -- consume before adapters can yield
    for _,reward in ipairs(cfg.Rewards) do
        if AddItem(src,reward.name,GetRandomInt(reward.min,reward.max))~=true then
            print('Airport mission reward delivery failed for '..tostring(session.identity))
        end
    end
end)
AddEventHandler('playerDropped',function() sessions[source]=nil end)
CreateThread(function()
    while true do
        Wait(250)
        for src,s in pairs(sessions) do
            if s.identity~=AirportIdentity(src) or os.time()-s.started>3600 or not DoesEntityExist(s.aircraft) then sessions[src]=nil
            elseif not s.pickup then
                local cfg=Config.Missions.Sequences[s.index]
                local pos=cfg.PackagePickup or cfg.PassengerPickup
                if AirportNear(src,pos,8) and #(GetEntityCoords(s.aircraft)-pos)<45 then s.pickup=true end
            end
        end
    end
end)
