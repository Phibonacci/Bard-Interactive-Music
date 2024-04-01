local BardClientSendCommands = {}

function SendBardClientCommand(commandName, args)
    sendClientCommand('BardInteractiveMusic', commandName, args)
end

BardClientSendCommands.sendStartNote = function(sourceId, instrument, note, isDistorted)
    if not isClient() then return end
    SendBardClientCommand('ClientSendStartNote', {
        sourceId = sourceId,
        instrument = instrument,
        note = note,
        isDistorted = isDistorted
    })
end

BardClientSendCommands.sendStopNote = function(sourceId, note)
    if not isClient() then return end
    SendBardClientCommand('ClientSendEndNote',
        { sourceId = sourceId, note = note })
end

BardClientSendCommands.sendAskRange = function()
    if not isClient() then return end
    SendBardClientCommand('ClientAskRange', {})
end

return BardClientSendCommands
