local TABasePlayMusicFrom = require('TimedAction/TABasePlayMusicFrom')

local TAPlayMusicFromInventory = TABasePlayMusicFrom:derive('TAPlayMusicFromInventory')

local ItemToInstrumentName = {
    ['Base.GuitarAcoustic'] = 'GuitarAcoustic',
    ['Base.Banjo'] = 'Banjo',
    ['Base.GuitarElectricBlack'] = 'GuitarElectric',
    ['Base.GuitarElectricBlue'] = 'GuitarElectric',
    ['Base.GuitarElectricRed'] = 'GuitarElectric',
    ['Base.GuitarElectricBassBlack'] = 'GuitarBass',
    ['Base.GuitarElectricBassBlue'] = 'GuitarBass',
    ['Base.GuitarElectricBassRed'] = 'GuitarBass',
    ['Base.Keytar'] = 'Synthesizer',
    ['Base.Flute'] = 'Flute',
    ['Base.Saxophone'] = 'Saxophone',
    ['Base.Trumpet'] = 'Trumpet',
    ['Base.Violin'] = 'Violin',
    ['Base.WesternPiano'] = 'Piano',
    ['Base.BlackGrandPiano'] = 'GrandPiano',
}


function TAPlayMusicFromInventory:new(character, item)
    local instrumentName = ItemToInstrumentName[item:getFullType()]
    local hasDistortion = instrumentName == 'GuitarElectric'
    local o = TABasePlayMusicFrom:new(character, instrumentName, hasDistortion)
    setmetatable(o, self)
    self.__index = self
    o.item = item
    return o
end

function TAPlayMusicFromInventory:equipInstrumentOnSecondaryHand()
    if self.isWorldItem then
        return
    end
    if self.character:isItemInBothHands(self.item) then
        self.handItem = 'BothHands'
    elseif self.character:isPrimaryHandItem(self.item) then
        self.handItem = 'PrimaryHand'
    elseif self.character:isSecondaryHandItem(self.item) then
        self.handItem = 'SecondaryHand'
    end
    self.character:setPrimaryHandItem(nil)
    self.character:setSecondaryHandItem(self.item)
end

local ItemToAnimation = {
    ['Base.GuitarAcoustic'] = 'BardPlayGuitarAcoustic',
    ['Base.Banjo'] = 'BardPlayGuitarAcoustic',
    ['Base.GuitarElectricBlack'] = 'BardPlayGuitarElectric',
    ['Base.GuitarElectricBlue'] = 'BardPlayGuitarElectric',
    ['Base.GuitarElectricRed'] = 'BardPlayGuitarElectric',
    ['Base.GuitarElectricBassBlack'] = 'BardPlayGuitarBass',
    ['Base.GuitarElectricBassBlue'] = 'BardPlayGuitarBass',
    ['Base.GuitarElectricBassRed'] = 'BardPlayGuitarBass',
    ['Base.Keytar'] = 'BardPlaySynthesizer',
    ['Base.Flute'] = 'BardPlayFlute',
    -- ['Base.Saxophone'] = 'BardPlaySaxophone',
    -- ['Base.Trumpet'] = 'BardPlayTrumpet',
    ['Base.Violin'] = 'BardPlayViolin',
}

function TAPlayMusicFromInventory:startAnimation()
    local animationName = ItemToAnimation[self.item:getFullType()]
    if animationName ~= nil then
        self:setActionAnim(animationName)
    end
end

function TAPlayMusicFromInventory:start()
    TABasePlayMusicFrom.start(self)
    self:equipInstrumentOnSecondaryHand()
    self:startAnimation()
end

function TAPlayMusicFromInventory:EquipInstrumentAsBefore()
    if self.isWorldItem then
        return
    end
    if self.handItem == 'PrimaryHand' then
        self.character:setPrimaryHandItem(self.item)
        self.character:setSecondaryHandItem(nil)
    elseif self.handItem == 'SecondaryHand' then
        self.character:setPrimaryHandItem(nil)
        self.character:setSecondaryHandItem(self.item)
    elseif self.handItem == 'BothHands' then
        self.character:setPrimaryHandItem(self.item)
        self.character:setSecondaryHandItem(self.item)
    end
end

function TAPlayMusicFromInventory:terminateAction()
    TABasePlayMusicFrom.terminateAction(self)
    self:EquipInstrumentAsBefore()
end

return TAPlayMusicFromInventory
