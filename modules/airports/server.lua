local Flights, journeys, npc, rate = {}, {}, {}, {}
GlobalState.Flights={}
local generation=0
local function update() GlobalState.Flights=Flights end
local function airport(i) return AirportInteger(i,1,#Config.Airports) and Config.Airports[i] end
local function throttle(src)
    local now=GetGameTimer()
    if rate[src] and now-rate[src]<500 then return false end
    rate[src]=now; return true
end
local function debit(src,amount)
    return AirportInteger(amount,0,Config.AirportSettings.MaxFare or 100000) and
        (amount==0 or (Search(src,'money')>=amount and RemoveItem(src,'money',amount)==true))
end
RegisterCallback('pickle_airport:startFlight',function(src,cb,index,info)
    local cfg=airport(index)
    local vehicle=AirportAircraft(src)
    if not throttle(src) or not cfg or Flights[index] or not vehicle or type(info)~='table'
        or not airport(info.destination) or info.destination==index or not AirportInteger(info.price,0,Config.AirportSettings.MaxFare or 100000)
        or not PermissionCheck(src,'flight') or not AirportNear(src,cfg.Locations.Flight,100) then cb(false); return end
    for _,f in pairs(Flights) do if f.source==src then cb(false); return end end
    generation=generation+1
    local f={source=src, identity=AirportIdentity(src), destination=info.destination, price=info.price,
        coords=GetEntityCoords(vehicle), net_id=NetworkGetNetworkIdFromEntity(vehicle), generation=generation,
        vehicle=vehicle, expires=os.time()+Config.AirportSettings.DepartureTime, seats={}}
    Flights[index]=f
    update(); cb(f)
    SetTimeout(Config.AirportSettings.DepartureTime*1000,function()
        if Flights[index]==f then Flights[index]=nil; update() end
    end)
end)
RegisterCallback('pickle_airport:purchaseTicket',function(src,cb,index,expected)
    local f=Flights[index]; local cfg=airport(index)
    if not throttle(src) or not f or f.generation~=expected or not cfg or not AirportNear(src,cfg.Locations.Boarding,15)
        or GetPlayerRoutingBucket(src)~=GetPlayerRoutingBucket(f.source) or not DoesEntityExist(f.vehicle)
        or AirportIdentity(f.source)~=f.identity or Search(src,'money')<f.price then cb(false); return end
    local old=journeys[src]
    if old and old.generation==expected and old.identity==AirportIdentity(src) then cb(old); return end
    for seat=0,15 do
        if not f.seats[seat] and GetPedInVehicleSeat(f.vehicle,seat)==0 then
            f.seats[seat]=src
            local j={generation=expected,index=index,seat=seat,net_id=f.net_id,coords=f.coords,vehicle=f.vehicle,
                price=f.price,identity=AirportIdentity(src),owner=f.source,destination=f.destination,created=os.time()}
            journeys[src]=j; cb(j); return
        end
    end
    cb(false)
end)
RegisterCallback('pickle_airport:confirmBoarding',function(src,cb,gen)
    local j=journeys[src]
    if not j or j.generation~=gen or j.identity~=AirportIdentity(src) or os.time()-j.created>30
        or GetPedInVehicleSeat(j.vehicle,j.seat)~=GetPlayerPed(src) then cb(false); return end
    if j.paid then cb(j.paid==true); return end
    j.paid='pending'
    local ok=debit(src,j.price)
    j.paid=ok or nil
    cb(ok)
end)
RegisterCallback('pickle_airport:startNPCFlight',function(src,cb,index,from)
    local a,b=airport(from),airport(index)
    local cost=Config.AirportSettings.NPCFlightCost
    if not throttle(src) or not a or not b or from==index or not AirportNear(src,a.Locations.Boarding,15)
        or not AirportInteger(cost,0,100000) or Search(src,'money')<cost or npc[src] then cb(false); return end
    generation=generation+1
    npc[src]={id=generation,from=from,destination=index,identity=AirportIdentity(src),cost=cost,started=os.time()}
    cb(generation)
end)
RegisterCallback('pickle_airport:finishNPCFlight',function(src,cb,id)
    local j=npc[src]
    if not j or j.id~=id or j.identity~=AirportIdentity(src) or os.time()-j.started<30
        or not AirportNear(src,Config.Airports[j.destination].Locations.Boarding,20) then cb(false); return end
    npc[src]=nil
    cb(debit(src,j.cost))
end)
RegisterNetEvent('pickle_airport:cancelNPCFlight',function() npc[source]=nil end)
RegisterNetEvent('pickle_airport:returnPassengers',function(index)
    local src=source; local cfg=airport(index); local vehicle=AirportAircraft(src)
    if not throttle(src) or not cfg or not vehicle or not PermissionCheck(src,'flight')
        or not AirportNear(src,cfg.Locations.Flight,100) then return end
    for passenger,j in pairs(journeys) do
        if j.owner==src and j.destination==index and j.vehicle==vehicle and j.paid==true
            and j.identity==AirportIdentity(passenger) and GetVehiclePedIsIn(GetPlayerPed(passenger),false)==vehicle then
            TriggerClientEvent('pickle_airport:returnBoarding',passenger,index)
            journeys[passenger]=nil
        end
    end
end)
AddEventHandler('playerDropped',function()
    local src=source
    for i,f in pairs(Flights) do if f.source==src then Flights[i]=nil else
        for seat,passenger in pairs(f.seats) do if passenger==src then f.seats[seat]=nil end end
    end end
    journeys[src]=nil; npc[src]=nil; rate[src]=nil; update()
end)
CreateThread(function()
    while true do
        Wait(1000)
        for src,j in pairs(journeys) do
            if j.identity~=AirportIdentity(src) or (not j.paid and os.time()-j.created>30) then
                local f=Flights[j.index]
                if f and f.generation==j.generation then f.seats[j.seat]=nil end
                journeys[src]=nil
            end
        end
        for src,j in pairs(npc) do if j.identity~=AirportIdentity(src) or os.time()-j.started>180 then npc[src]=nil end end
    end
end)
