local IS_SERVER = IsDuplicityVersion()

local registered_commands = {}
local resting_commands = {}

function IsSourceRestingOnCommand(source, commandName)
    if (resting_commands[source]) then
        for cName, rest_end_at in pairs(resting_commands[source]) do
            if (cName == commandName) then
                return true
            end
        end
    end
    
    return false
end

if IS_SERVER then
    AddEventHandler("onPlayerDropped", function(source, reason)
            if (resting_commands[source]) then
                resting_commands[source] = nil
            end
        end
    )
end

Citizen.CreateThread(
    function()
        while true do
            Citizen.Wait(1000)

            local gametimer = GetGameTimer()

            for source, r_commands in ipairs(resting_commands) do
                for cName, rest_end_at in pairs(resting_commands[source]) do
                    if gametimer >= rest_end_at then
                        resting_commands[source][cName] = nil
                    end
                end
            end
        end
    end
)

vRP.RegisterRestingCommand = function(commandName, handler, err_handler, resting_time, restricted)
    if (handler ~= nil) then

        RegisterCommand(commandName, function(source, args, raw)

            if (not IsSourceRestingOnCommand(source, commandName) or resting_commands[source][commandName] <= GetGameTimer()) then

                if (not resting_commands[source]) then
                    resting_commands[source] = {}
                end

                resting_commands[source][commandName] = GetGameTimer() + (resting_time * 1000)

                handler(source, args, raw)
            else
                if err_handler then

                    local time_left = (resting_commands[source][commandName] - GetGameTimer()) / 1000

                    err_handler(source, args, raw, time_left)
                end
            end

        end, restricted)
    end
end

function Handler_gcolete(source, args, raw)
    print("^6Colete guardado!!")

    local playerPed = PlayerPedId()
    SetPedArmour(playerPed, 100)

end

function ErrHandler_gcolete(source, args, raw, time_left)
    print("^6Você ainda está em um cooldown de " .. time_left .. " segundos :O ^7")
end

vRP.RegisterRestingCommand("gcolete",
    Handler_gcolete,
    ErrHandler_gcolete,
    3,
    false
)

vRP.RegisterRestingCommand("gcolete", 
    function (source, args, raw)
        local playerPed = GetPlayerPed(source)
        SetPedArmour(playerPed, 0)
    end,
    function (source, args, raw, time_left)
        print('Cooldown :(')
    end,
    3,
    false
)

Citizen.CreateThread(function()
    Citizen.Wait(100)

    --ExecuteCommand("gcolete")

    --ExecuteCommand("gcolete")
end)