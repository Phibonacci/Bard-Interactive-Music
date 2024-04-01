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
            and connectedPlayer:DistTo(player:getX(), player:getY()) < SandboxVars.BardInteractiveMusic.SoundRange + 10 then
            SendBardServerCommand(connectedPlayer, 'ServerSendStartNote', args)
        end
    end
end

BardServerCommands['ClientSendEndNote'] = function(player, args)
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if connectedPlayer:getOnlineID() ~= args.sourceId
            -- we want to make sure the player will receive the end of the note even with lag or when driving a fast vehicle
            and connectedPlayer:DistTo(player:getX(), player:getY()) < SandboxVars.BardInteractiveMusic.SoundRange + 20 then
            SendBardServerCommand(connectedPlayer, 'ServerSendEndNote', args)
        end
    end
end

-- sends back the maximum range of instruments in tiles
BardServerCommands['ClientAskRange'] = function(player, args)
    SendBardServerCommand(player, 'ServerAnswerRange', { SoundRange = SandboxVars.BardInteractiveMusic.SoundRange })
end

local function OnClientCommand(module, command, player, args)
    if module == 'BardInteractiveMusic' and BardServerCommands[command] then
        BardServerCommands[command](player, args)
    end
end

Events.OnClientCommand.Add(OnClientCommand)

return BardServerCommands
