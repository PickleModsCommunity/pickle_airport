local NpcEntities={}
local ActiveTicket=nil
Interact = false

function StartNPCFlight(from, index)
    ServerCallback("pickle_airport:startNPCFlight", function(result)
        if (result) then 
            local Plane = nil
            local airport_cfg = Config.Airports[from]
            local cfg = Config.Airports[index]
            local coords = cfg.Locations.Boarding
            local ped = PlayerPedId()
            DoScreenFadeOut(1000)
            Wait(1400)
            local data = Flight
            local start, finish, board = airport_cfg.Locations.Flight, cfg.Locations.Flight, cfg.Locations.Boarding
            
            start, finish = vec3(start.x, start.y, 1700.0), vec3(finish.x, finish.y, 1700.0)

            local heading = GetHeadingFromVector_2d(start.x - finish.x, start.y - finish.y)
            local ped = CreateNPC(`g_m_m_armboss_01`, start.x, start.y, start.z, 0.0, true, true)

            Plane = CreateVeh(`luxor`, start.x, start.y, start.z, heading - 180.0, false, true)
            NpcEntities={plane=Plane,pilot=ped}
            SetEntityCoords(ped, start.x, start.y, start.z)
            TaskWarpPedIntoVehicle(ped, Plane, -1)
            TaskWarpPedIntoVehicle(PlayerPedId(), Plane, 1)
        
            Wait(100)
            DoScreenFadeIn(1000)
            
            NpcEntities={plane=Plane,pilot=ped}
            local started=GetGameTimer()
            local percent = 0
            while percent < 1.0 do
                percent = math.min(1.0,(GetGameTimer()-started)/33334)
                local coords = lerp(start, finish, percent)
                SetEntityCoords(Plane, coords.x, coords.y, coords.z)
                DisableControlAction(1, 75, 1)
                Wait(0)
            end
            FreezeEntityPosition(Plane, true)
            DoScreenFadeOut(1000)
            Wait(1500)
            DeleteEntity(Plane)
            DeleteEntity(ped)
            NpcEntities={}
            SetEntityCoords(PlayerPedId(), board.x, board.y, board.z)
            local done=promise.new()
            ServerCallback('pickle_airport:finishNPCFlight',function(ok) done:resolve(ok) end,result)
            if not Citizen.Await(done) then
                local origin=airport_cfg.Locations.Boarding
                SetEntityCoords(PlayerPedId(),origin.x,origin.y,origin.z)
            end
                
            Wait(100)
            DoScreenFadeIn(1000)
        else
            ShowNotification(U.Boarding_broke)
        end
        Interact = false
    end, index, from)
end

function JoinActiveFlight(index)
    local cfg=Config.Airports[index]
    local offer=GlobalState.Flights[index]
    if not cfg or not offer then Interact=false; return end
    ServerCallback('pickle_airport:purchaseTicket',function(ticket)
        if not ticket then Interact=false; return end
        CreateThread(function()
            local ped=PlayerPedId()
            DoScreenFadeOut(500); Wait(600)
            SetEntityCoords(ped,ticket.coords.x,ticket.coords.y,ticket.coords.z+5)
            local deadline=GetGameTimer()+10000
            local vehicle=0
            repeat
                if NetworkDoesEntityExistWithNetworkId(ticket.net_id) then vehicle=NetToVeh(ticket.net_id) end
                if vehicle~=0 and DoesEntityExist(vehicle) then break end
                Wait(50)
            until GetGameTimer()>deadline
            local valid=vehicle~=0 and DoesEntityExist(vehicle) and ped==PlayerPedId()
            if valid then
                RequestCollisionAtCoord(ticket.coords.x,ticket.coords.y,ticket.coords.z)
                deadline=GetGameTimer()+5000
                while not HasCollisionLoadedAroundEntity(vehicle) and GetGameTimer()<deadline do Wait(50) end
                valid=IsVehicleSeatFree(vehicle,ticket.seat)
                if valid then TaskWarpPedIntoVehicle(ped,vehicle,ticket.seat); Wait(250) end
                valid=valid and GetPedInVehicleSeat(vehicle,ticket.seat)==ped
            end
            if valid then
                local receipt=promise.new()
                ServerCallback('pickle_airport:confirmBoarding',function(ok) receipt:resolve(ok) end,ticket.generation)
                valid=Citizen.Await(receipt)
                if valid then ActiveTicket=ticket end
            end
            if not valid then
                local c=cfg.Locations.Boarding
                SetEntityCoords(ped,c.x,c.y,c.z)
                ShowNotification(U.Boarding_broke)
            end
            DoScreenFadeIn(500); Interact=false
        end)
    end,index,offer.generation)
end

function OpenFlightMenu(index, vehicle)
    local menu_id = "airport_flight_menu"
    local options = {}
    for i=1, #Config.Airports do 
        if index ~= i then 
            local _index = i
            options[#options + 1] = {label = Config.Airports[i].AirportTitle, description = "", index = _index}
        end
    end
    lib.registerMenu({
        id = menu_id,
        title = 'Choose Destination',
        position = 'top-left',
        onClose = function(keyPressed)
            Interact = false
        end,
        options = options
    }, function(selected, scrollIndex, args)
        Wait(250)
        local input = lib.inputDialog('Flight Cost', {'Price'})
        if not input or not tonumber(input[1]) or tonumber(input[1]) < 0 or tonumber(input[1]) > (Config.AirportSettings.MaxFare or 100000) then
            Interact = false
            return 
        else
            local flight_info = {destination = options[selected].index, price = math.ceil(tonumber(input[1])), coords = GetEntityCoords(vehicle), net_id = VehToNet(vehicle)}
            ServerCallback("pickle_airport:startFlight", function(result)
                if (result) then 
                    ShowNotification("Boarding Players, Takeoff Time: ".. Config.AirportSettings.DepartureTime .. " (s)")
                    FreezeEntityPosition(vehicle, true)
                    Wait(1000 * Config.AirportSettings.DepartureTime)
                    FreezeEntityPosition(vehicle, false)
                    ShowNotification("Players are now boarded, you are clear for takeoff.")
                end
                Interact = false
            end, index, flight_info)
        end
    end)
    lib.showMenu(menu_id)
end

function OpenSpawnMenu(index)
    local menu_id = "airport_spawn_menu"
    local options = Config.Spawner.Vehicles
    local cfg = Config.Airports[index]
    local coords = cfg.Locations.Hangar
    lib.registerMenu({
        id = menu_id,
        title = 'Aircraft Spawner',
        position = 'top-left',
        onClose = function(keyPressed)
            Interact = false
        end,
        options = options
    }, function(selected, scrollIndex, args)
        local data = options[selected]
        local vehicle = CreateVeh(data.model, coords.x, coords.y, coords.z, coords.w, true, true)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        Interact = false
    end)

    lib.showMenu(menu_id)
end

function ShowHangarMenu(index)
    local menu_id = "airport_hangar_menu"
    local options = {
        {label = "Aircraft Spawner", description = ""},
        {label = "Mission Selector", description = ""},
    }
    lib.registerMenu({
        id = menu_id,
        title = 'Hangar',
        position = 'top-left',
        onClose = function(keyPressed)
            Interact = false
        end,
        options = options
    }, function(selected, scrollIndex, args)
        if (selected == 1) then 
            OpenSpawnMenu(index)
        elseif (selected == 2) then
            OpenMissionMenu(index)
        end
    end)

    lib.showMenu(menu_id)
end

function OpenNPCMenu(index)
    local menu_id = "airport_npc_menu"
    local options = {}
    for i=1, #Config.Airports do 
        if index ~= i then 
            local _index = i
            options[#options + 1] = {label = Config.Airports[i].AirportTitle, description = "", index = _index}
        end
    end
    lib.registerMenu({
        id = menu_id,
        title = 'Choose Destination',
        position = 'top-left',
        onClose = function(keyPressed)
            Interact = false
        end,
        options = options
    }, function(selected, scrollIndex, args)
        StartNPCFlight(index, options[selected].index)
    end)
    lib.showMenu(menu_id)
end

function InteractAirport(index, key)
    Interact = true
    if (key == "Boarding") then 
        local data = GlobalState.Flights[index]
        if (data) then
            JoinActiveFlight(index)
        elseif (Config.AirportSettings.NPCFlightCost) then 
            OpenNPCMenu(index)
        else
            ShowHelpNotification(U.Boarding_unavailable)
        end
    elseif (key == "Flight") then 
        if not PermissionCheck("flight") then 
            Interact = false
            ShowNotification(U.Flight_denied)
            return
        end
        local vehicle = GetCurrentAircraft()
        if vehicle then 
            local seats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2
            local players = {}
            local found = false
            for i=0, seats do
                if not IsVehicleSeatFree(vehicle, i) then 
                    local player = NetworkGetPlayerIndexFromPed(GetPedInVehicleSeat(vehicle, i))
                    if (player) then 
                        found = true
                        players[#players + 1] = GetPlayerServerId(player)
                    end
                end
            end
            if found then 
                TriggerServerEvent("pickle_airport:returnPassengers", index, players)
                Interact = false
            else
                OpenFlightMenu(index, vehicle)
            end
        else
            Interact = false
            --ShowNotification("You are not able to start a flight without being in a plane.")
        end
    elseif (key == "Hangar") then 
        if not PermissionCheck("hangar") then 
            Interact = false
            ShowNotification(U.Hangar_denied)
            return
        end
        local vehicle = GetCurrentAircraft()
        if vehicle then 
            DeleteEntity(vehicle)
            Interact = false
        else
            ShowHangarMenu(index)
        end
    end
end

function ShowInteract(index, key)
    local airport = Config.Airports[index]
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local coords, heading = v3(airport.Locations[key])
    local dist = #(coords - pcoords)
    if not Interact and dist < 20.0 then 
        if (dist < 1.75) then
            if (key == "Boarding") then 
                local data = GlobalState.Flights[index]
                if (data) then 
                    local airport = Config.Airports[index]
                    local dest = Config.Airports[data.destination]
                    ShowHelpNotification("~INPUT_CONTEXT~ " .. airport.AirportTitle .. " -> " .. dest.AirportTitle .. " ($" .. data.price .. ")")
                elseif (Config.AirportSettings.NPCFlightCost) then 
                    ShowHelpNotification(U.Boarding_npc_interact .. Config.AirportSettings.NPCFlightCost .. ".")
                else
                    ShowHelpNotification(U.Boarding_unavailable)
                end
                return true, true
            elseif (key == "Flight") then 
                local vehicle = GetCurrentAircraft()
                if vehicle then 
                    local seats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2
                    local found = false
                    for i=0, seats do
                        if not IsVehicleSeatFree(vehicle, i) then 
                            found = true
                            break
                        end
                    end
                    if found then 
                        ShowHelpNotification(U.Flight_return)
                    else
                        ShowHelpNotification(U.Flight_interact)
                    end
                    return true, true 
                else
                    ShowHelpNotification(U.Flight_reject)
                    return false, true 
                end
            elseif (key == "Hangar") then 
                local vehicle = GetCurrentAircraft()
                if vehicle then 
                    ShowHelpNotification(U.Hangar_return)
                else
                    ShowHelpNotification(U.Hangar_interact)
                end
                return true, true 
            end
        else
            if (key == "Boarding") then 
                return nil, true
            elseif (key == "Flight") then 
                return nil, true
            elseif (key == "Hangar") then 
                return nil, true
            end
        end
    end
end

RegisterNetEvent("pickle_airport:returnBoarding", function(index)
    local cfg = Config.Airports[index]
    local ticket=ActiveTicket
    if not cfg or not ticket or ticket.destination~=index then return end
    local coords = cfg.Locations.Flight
    local ped = PlayerPedId()
    local vehicle=GetVehiclePedIsIn(ped,false)
    if vehicle==0 or VehToNet(vehicle)~=ticket.net_id then return end
    if #(coords - GetEntityCoords(ped)) < 10.0 then 
        local coords = cfg.Locations.Boarding
        DoScreenFadeOut(1000)
        Wait(1500)
        if ped~=PlayerPedId() or ActiveTicket~=ticket or GetVehiclePedIsIn(ped,false)~=vehicle then DoScreenFadeIn(0); return end
        SetEntityCoords(ped, coords.x, coords.y, coords.z)
        ActiveTicket=nil
        Wait(100)
        DoScreenFadeIn(1000)
    end
end)

CreateThread(function()
    for i=1, #Config.Airports do 
        local airport = Config.Airports[i]
        if airport.Blips then 
            for k,v in pairs(airport.Blips) do 
                local data = v
                data.Location = v3(airport.Locations[k])
                CreateBlip(data)
            end
        end
    end
    while true do
        local wait = 1000
        for i=1, #Config.Airports do 
            local airport = Config.Airports[i]
            for k,v in pairs(airport.Locations) do 
                local inZone, displayZone = ShowInteract(i, k)
                if (displayZone) then
                    wait = 0
                    local coords, heading = v3(v)
                    DrawMarker(2, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 255, 255, 255, 127, false, true)
                    if (inZone and IsControlJustPressed(1, 51)) then 
                        InteractAirport(i, k)
                    end
                end
            end
        end
        Wait(wait)
    end
end)
AddEventHandler('onResourceStop',function(name)
    if name~=GetCurrentResourceName() then return end
    for _,e in pairs(NpcEntities) do if DoesEntityExist(e) then DeleteEntity(e) end end
    DoScreenFadeIn(0)
end)
