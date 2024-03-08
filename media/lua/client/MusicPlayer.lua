---@version 5.1 Kahlua

local MusicPlayer = ISBaseTimedAction:derive('MusicPlayer')

local instance = nil
function MusicPlayer.getInstance()
    if instance == nil then
        instance = MusicPlayer:new()
        return instance
    end
    return instance
end

function MusicPlayer:new()
    assert(instance == nil,
        'MusicPlayer is a singleton, call getInstance instead')
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.soundsPlaying = {}
    o.soundsStopping = {}
    o.baseVolume = 0.7
    o.maxDistance = 40 -- tiles
    return o
end

local function GetFileName(instrument, note, isDistorted)
    local distorted = isDistorted and 'Distorted' or ''
    return instrument .. distorted .. note -- todo should add checks
end

local function GetKeyFromNoteAndPlayerId(note, playerId)
    return playerId .. note
end

function MusicPlayer:playNote(sourcePlayerId, instrument, note, isDistorted)
    local instrumentNote = GetFileName(instrument, note, isDistorted)
    print('playing ' .. instrumentNote)
    assert(instrumentNote ~= nil, string.format("Unknown note %s", note))

    local player = getPlayer()
    local source
    if isClient() then
        source = getPlayerByOnlineID(sourcePlayerId)
    else
        source = player
    end
    local soundEmitter = getWorld():getFreeEmitter()
    local square = source:getSquare()
    local soundId = soundEmitter:playSoundImpl(instrumentNote, square)
    addSound(source, square:getX(), square:getY(), square:getZ(), 40, self.baseVolume)
    if isClient() and player:getOnlineID() ~= sourcePlayerId then
        soundEmitter:set3D(soundId, true)
        local distance = player:DistTo(source:getX(), source:getY())
        local volume = self.baseVolume - self.baseVolume * (distance / 40)
        soundEmitter:setVolume(soundId, volume)
    end

    local hash = GetKeyFromNoteAndPlayerId(note, sourcePlayerId)
    if self.soundsPlaying[hash] then
        table.insert(self.soundsStopping, self.soundsPlaying[hash])
        -- self.soundsStopping[hash] = self.soundsPlaying[hash]
    end
    self.soundsPlaying[hash] = {
        emitter = soundEmitter,
        soundId = soundId,
        startingTime = GetCurrentTimeInMs(),
        volume = 0.7,
        sourcePlayerId = sourcePlayerId,
        note = note,
        instrument = instrument
    }
end

function MusicPlayer:stopNote(sourcePlayerId, note)
    local hash = GetKeyFromNoteAndPlayerId(note, sourcePlayerId)
    if self.soundsPlaying[hash] then
        table.insert(self.soundsStopping, self.soundsPlaying[hash])
        -- self.soundsStopping[hash] = self.soundsPlaying[hash]
        self.soundsPlaying[hash] = nil
    end
end

function MusicPlayer:stop()
    for _, sound in pairs(self.soundsPlaying) do
        self:stopNote(sound.sourcePlayerId, sound.note)
    end
end

function GetCurrentTimeInMs()
    return Calendar.getInstance():getTimeInMillis()
end

local minimalNoteDurationByInstrument = {
    ["GuitarAcoustic"] = { baseTime = 500, fadingTime = 200, polyphonic = true },
    ["Banjo"] = { baseTime = 300, fadingTime = 150, polyphonic = true },
    ["GuitarElectric"] = { baseTime = 250, fadingTime = 150, polyphonic = true },
    ["GuitarBass"] = { baseTime = 350, fadingTime = 150, polyphonic = true },
    ["Synthesizer"] = { baseTime = 250, fadingTime = 150, polyphonic = true },
    ["Flute"] = { baseTime = 0, fadingTime = 50, polyphonic = false },
    ["Saxophone"] = { baseTime = 0, fadingTime = 50, polyphonic = false },
    ["Trumpet"] = { baseTime = 0, fadingTime = 50, polyphonic = false },
    ["Violin"] = { baseTime = 50, fadingTime = 100, polyphonic = true },
}

function MusicPlayer:update()
    local idsToRemove = {}
    for index, sound in pairs(self.soundsStopping) do
        assert(sound.startingTime ~= nil, "Note starting time not found")
        local delta = GetCurrentTimeInMs() - sound.startingTime
        local duration = minimalNoteDurationByInstrument[sound.instrument]
        if delta >
            duration.baseTime
            + (self.baseVolume - sound.volume) / self.baseVolume
            * duration.fadingTime
        then
            sound.volume = sound.volume - 0.1
            if sound.volume <= 0 then sound.volume = 0 end
            local volume = sound.volume
            local player = getPlayer()
            if isClient() and player:getOnlineID() ~= sound.sourcePlayerId then
                local source = getPlayerByOnlineID(sound.sourcePlayerId)
                local distance = player:DistTo(source:getX(), source:getY())
                volume = sound.volume - sound.volume * (distance / 40)
            end
            sound.emitter:setVolume(sound.soundId, volume)
        end
        if sound.volume <= 0 then
            table.insert(idsToRemove, index)
        end
    end
    for _, index in pairs(idsToRemove) do
        self.soundsStopping[index] = nil
    end
end

Events.OnPostRender.Add(function() MusicPlayer.getInstance():update() end)

return MusicPlayer
