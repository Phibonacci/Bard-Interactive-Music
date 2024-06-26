local MusicPlayer = {}

local instance = nil
function MusicPlayer.getInstance()
    if instance == nil then
        instance = MusicPlayer:new()
        return instance
    end
    return instance
end

local InstrumentParameters = {
    ["GuitarAcoustic"] = { baseTime = 500, fadingTime = 200, polyphonic = true },
    ["Banjo"] = { baseTime = 300, fadingTime = 150, polyphonic = true },
    ["GuitarElectric"] = { baseTime = 250, fadingTime = 150, polyphonic = true },
    ["GuitarBass"] = { baseTime = 350, fadingTime = 150, polyphonic = true },
    ["Synthesizer"] = { baseTime = 250, fadingTime = 150, polyphonic = true },
    ["Flute"] = { baseTime = 0, fadingTime = 50, polyphonic = true },
    ["Saxophone"] = { baseTime = 0, fadingTime = 50, polyphonic = true },
    ["Trumpet"] = { baseTime = 0, fadingTime = 50, polyphonic = true },
    ["Violin"] = { baseTime = 50, fadingTime = 100, polyphonic = true },
    ["Piano"] = { baseTime = 500, fadingTime = 200, polyphonic = true },
    ["GrandPiano"] = { baseTime = 500, fadingTime = 200, polyphonic = true },
}

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
    o.range = nil
    if not isClient() then
        self.range = SandboxVars.BardInteractiveMusic.SoundRange
    end
    return o
end

function MusicPlayer:setRange(range)
    self.range = range
end

local function GetFileName(instrument, note, isDistorted)
    local distorted = isDistorted and 'Distorted' or ''
    return instrument .. distorted .. note -- todo should add checks
end

local function GetKeyFromNoteAndPlayerId(note, playerId)
    return playerId .. note
end

function MusicPlayer:setEmitterVolume(emitter, soundId, volume, sourceId)
    local player = getPlayer()
    local source = getPlayerByOnlineID(sourceId)
    local modifiedVolume = volume
    if isClient() and player:getOnlineID() ~= sourceId then
        local distance = player:DistTo(source:getX(), source:getY())
        modifiedVolume = math.max(0, volume - volume * (distance / self.range))
    end
    emitter:setVolume(soundId, modifiedVolume)
end

function MusicPlayer:playNote(sourcePlayerId, instrument, note, isDistorted)
    if self.range == nil then
        print('error: Bard Music Binding: sound range not set')
        return
    end
    local instrumentNote = GetFileName(instrument, note, isDistorted)
    -- print('playing ' .. instrumentNote)
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
    addSound(source, square:getX(), square:getY(), square:getZ(), self.range, self.baseVolume)
    if not isClient() or player:getOnlineID() == sourcePlayerId then
        soundEmitter:set3D(soundId, false)
    end
    self:setEmitterVolume(soundEmitter, soundId, self.baseVolume, sourcePlayerId)

    local hash = GetKeyFromNoteAndPlayerId(note, sourcePlayerId)
    if InstrumentParameters[instrument].polyphonic == true and self.soundsPlaying[hash] then
        table.insert(self.soundsStopping, self.soundsPlaying[hash])
    elseif InstrumentParameters[instrument].polyphonic == false then
        self:stopPlayerNotes(sourcePlayerId)
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
        self.soundsPlaying[hash] = nil
    end
end

function MusicPlayer:stopPlayerNotes(playerId)
    for _, sound in pairs(self.soundsPlaying) do
        if sound.sourcePlayerId == playerId then
            self:stopNote(sound.sourcePlayerId, sound.note)
        end
    end
end

function MusicPlayer:stopPlayer(action)
    for _, sound in pairs(self.soundsPlaying) do
        if sound.sourcePlayerId == getPlayer():getOnlineID() then
            self:stopNote(sound.sourcePlayerId, sound.note)
            action(sound.note)
        end
    end
end

function GetCurrentTimeInMs()
    return Calendar.getInstance():getTimeInMillis()
end

function MusicPlayer:update()
    local idsToRemove = {}
    for index, sound in pairs(self.soundsStopping) do
        assert(sound.startingTime ~= nil, "Note starting time not found")
        local delta = GetCurrentTimeInMs() - sound.startingTime
        local duration = InstrumentParameters[sound.instrument]
        if delta >
            duration.baseTime
            + (self.baseVolume - sound.volume) / self.baseVolume
            * duration.fadingTime
        then
            sound.volume = sound.volume - 0.1
            if sound.volume <= 0 then sound.volume = 0 end
            self:setEmitterVolume(sound.emitter, sound.soundId, sound.volume, sound.sourcePlayerId)
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
