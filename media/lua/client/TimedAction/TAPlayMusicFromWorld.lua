local TABasePlayMusicFrom = require('TimedAction/TABasePlayMusicFrom')

local TAPlayMusicFromWorld = TABasePlayMusicFrom:derive('TAPlayMusicFromWorld')

function TAPlayMusicFromWorld:new(character, instrument, instrumentObject, orientation, seated)
    local o = TABasePlayMusicFrom:new(character, instrument, false)
    setmetatable(o, self)
    self.__index = self
    self.handItems = {}
    o.instrumentObject = instrumentObject
    o.orientation = orientation
    o.seated = seated
    return o
end

local AnimationsParameters = {
    { animation = 'BardPlayPianoEast',             seated = false, orientation = 'east',  instrument = 'Piano' },
    { animation = 'BardPlayPianoSouth',            seated = false, orientation = 'south', instrument = 'Piano' },
    { animation = 'BardPlayPianoSeatedEast',       seated = true,  orientation = 'east',  instrument = 'Piano' },
    { animation = 'BardPlayPianoSeatedSouth',      seated = true,  orientation = 'south', instrument = 'Piano' },
    { animation = 'BardPlayGrandPianoEast',        seated = false, orientation = 'east',  instrument = 'GrandPiano' },
    { animation = 'BardPlayGrandPianoSouth',       seated = false, orientation = 'south', instrument = 'GrandPiano' },
    { animation = 'BardPlayGrandPianoSeatedEast',  seated = true,  orientation = 'east',  instrument = 'GrandPiano' },
    { animation = 'BardPlayGrandPianoSeatedSouth', seated = true,  orientation = 'south', instrument = 'GrandPiano' },
}

function TAPlayMusicFromWorld:startAnimation()
    for _, parameters in ipairs(AnimationsParameters) do
        if parameters.seated == self.seated
            and parameters.orientation == self.orientation
            and parameters.instrument == self.instrument then
            self:setActionAnim(parameters.animation)
            return
        end
    end
    print('Unknown animation for '
        .. self.instrument
        .. ' in TAPlayMusicFromWorld:startAnimation() with current seating state and orientation')
end

function TAPlayMusicFromWorld:unequipHandItems()
    local primaryItem = self.character:getPrimaryHandItem()
    local secondaryItem = self.character:getSecondaryHandItem()
    if primaryItem ~= nil and self.character:isItemInBothHands(primaryItem) then
        table.insert(self.handItems,
            { item = primaryItem, hands = "both" })
    else
        if primaryItem ~= nil then
            table.insert(self.handItems,
                { item = primaryItem, hands = "primary" })
        end
        if secondaryItem ~= nil then
            table.insert(self.handItems,
                { item = secondaryItem, hands = "secondary" })
        end
    end
    self.character:setPrimaryHandItem(nil)
    self.character:setSecondaryHandItem(nil)
end

function TAPlayMusicFromWorld:start()
    self.character:faceThisObject(self.instrumentObject)
    self:startAnimation()
    TABasePlayMusicFrom.start(self)
    self:unequipHandItems()
end

function TAPlayMusicFromWorld:equipHandItemsAsBefore()
    for _, handItemInfo in ipairs(self.handItems) do
        if handItemInfo.hands == 'both' then
            self.character:setPrimaryHandItem(handItemInfo.item)
            self.character:setSecondaryHandItem(handItemInfo.item)
        elseif handItemInfo.hands == 'primary' then
            self.character:setPrimaryHandItem(handItemInfo.item)
        elseif handItemInfo.hands == 'secondary' then
            self.character:setSecondaryHandItem(handItemInfo.item)
        end
    end
    self.handItems = {}
end

function TAPlayMusicFromWorld:terminateAction()
    TABasePlayMusicFrom.terminateAction(self)
    self:equipHandItemsAsBefore()
end

return TAPlayMusicFromWorld
