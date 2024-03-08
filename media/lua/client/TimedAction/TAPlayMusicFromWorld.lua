local TABasePlayMusicFrom = require('TimedAction/TABasePlayMusicFrom')

local TAPlayMusicFromWorld = TABasePlayMusicFrom:derive('TAPlayMusicFromWorld')

local WorldItem = {
    ['Base.WesternPiano'] = true,
    ['Base.BlackGrandPiano'] = true,
}

function TAPlayMusicFromWorld:new(character, instrument, instrumentObject)
    local o = TABasePlayMusicFrom:new(character, instrument, false)
    setmetatable(o, self)
    self.__index = self

    o.instrumentObject = instrumentObject
    return o
end

function TAPlayMusicFromWorld:startAnimation()
end

function TAPlayMusicFromWorld:start()
    self.character:faceThisObject(self.instrumentObject)
    TABasePlayMusicFrom.start(self)
    self:startAnimation()
end

return TAPlayMusicFromWorld
