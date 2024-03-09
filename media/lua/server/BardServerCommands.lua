local BardServerCommands = {}

function SendBardServerCommand(player, commandName, args)
    sendServerCommand(player, 'BardInteractiveMusic', commandName, args)
end

function ServerPrint(player, message)
    SendBardServerCommand(player, 'ServerPrint', { message = message })
end

BardServerCommands['ClientSendStartNote'] = function(player, args)
    local x = player:getX()
    local y = player:getY()
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        local playerOnlineId = connectedPlayer:getOnlineID()
        if playerOnlineId ~= args.sourceId
            and connectedPlayer:DistTo(player:getX(), player:getY()) < 60 then
            SendBardServerCommand(connectedPlayer, 'ServerSendStartNote', args)
        end
    end
end

BardServerCommands['ClientSendEndNote'] = function(player, args)
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if connectedPlayer:getOnlineID() ~= args.sourceId
            and connectedPlayer:DistTo(player:getX(), player:getY()) < 80 then
            SendBardServerCommand(connectedPlayer, 'ServerSendEndNote', args)
        end
    end
end

local function OnClientCommand(module, command, player, args)
    if module == 'BardInteractiveMusic' and BardServerCommands[command] then
        BardServerCommands[command](player, args)
    end
end

Events.OnClientCommand.Add(OnClientCommand)

return BardServerCommands
