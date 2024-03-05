local BardClientRecvCommands = {}

MusicPlayer = require('MusicPlayer')

BardClientRecvCommands['ServerSendStartNote'] = function(args)
    local musicPlayer = MusicPlayer.getInstance()
    musicPlayer:playNote(args.sourceId, args.instrument, args.note, args.isDistorted)
end

BardClientRecvCommands['ServerSendEndNote'] = function(args)
    local musicPlayer = MusicPlayer.getInstance()
    musicPlayer:stopNote(args.sourceId, args.note)
end

BardClientRecvCommands['ServerPrint'] = function(args)
    print('Server: ' .. args.message)
end

local function OnServerCommand(module, command, args)
    if module == 'BardInteractiveMusic' and BardClientRecvCommands[command] then
        BardClientRecvCommands[command](args)
    end
end

Events.OnServerCommand.Add(OnServerCommand)

return BardClientRecvCommands
