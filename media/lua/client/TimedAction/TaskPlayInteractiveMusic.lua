local PlayInteractiveMusic = ISBaseTimedAction:derive 'PlayInteractiveMusic';

local MusicNotes = require 'MusicNotes'
local MusicPlayer = require 'MusicPlayer'
local BardClientSendCommands = require 'BardClientSendCommands'
local KeybindManager = require 'KeybindManager'
local PianoKeyboard = require 'ui/PianoKeyboard'

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
}

function PlayInteractiveMusic:new(character, item)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = false
    o.maxTime = -1
    o.item = item
    o.instrumentName = ItemToInstrumentName[item:getFullType()]
    o.electrical = o.instrumentName == 'GuitarElectric' or o.instrumentName == 'GuitarBass'
    o.handItem = nil
    o.isPlaying = false
    o.eventAdded = false
    o.keyboard = nil
    return o
end

function PlayInteractiveMusic:onKeyPressed(key)
    if not self.isPlaying then
        return
    end
    for octave = 2, 5 do
        for _, noteName in pairs(MusicNotes) do
            local fullNote = noteName .. octave
            if key == getCore():getKey('BardNote' .. fullNote) then
                local playerId = getPlayer():getOnlineID()
                BardClientSendCommands.sendStartNote(playerId, self.instrumentName, fullNote, self.keyboard:isDistorted())
                MusicPlayer.getInstance():playNote(playerId, self.instrumentName, fullNote, self.keyboard:isDistorted())
                self.keyboard:markPressedKey(fullNote)
            end
        end
    end
end

function PlayInteractiveMusic:onKeyReleased(key)
    if not self.isPlaying then
        return
    end
    for octave = 2, 5 do
        for _, noteName in pairs(MusicNotes) do
            local fullNote = noteName .. octave
            if key == getCore():getKey("BardNote" .. fullNote) then
                local playerId = getPlayer():getOnlineID()
                BardClientSendCommands.sendStopNote(playerId, fullNote)
                MusicPlayer.getInstance():stopNote(playerId, fullNote)
                self.keyboard:markReleasedKey(fullNote)
            end
        end
    end
end

function PlayInteractiveMusic:isValid()
    return true
end

local KeyToNote = {
    ['1'] = 'C2',
    ['2'] = 'Cs2',
    ['3'] = 'D2',
    ['4'] = 'Ds2',
    ['5'] = 'E2',
    ['6'] = 'F2',
    ['7'] = 'Fs2',
    ['8'] = 'G2',
    ['9'] = 'Gs2',
    ['0'] = 'A2',
    ['-'] = 'As2',
    ['='] = 'B2',
    ['Q'] = 'C3',
    ['W'] = 'Cs3',
    ['E'] = 'D3',
    ['R'] = 'Ds3',
    ['T'] = 'E3',
    ['Y'] = 'F3',
    ['U'] = 'Fs3',
    ['I'] = 'G3',
    ['O'] = 'Gs3',
    ['P'] = 'A3',
    ['['] = 'As3',
    [']'] = 'B3',
    ['A'] = 'C4',
    ['S'] = 'Cs4',
    ['D'] = 'D4',
    ['F'] = 'Ds4',
    ['G'] = 'E4',
    ['H'] = 'F4',
    ['J'] = 'Fs4',
    ['K'] = 'G4',
    ['L'] = 'Gs4',
    [';'] = 'A4',
    ['\''] = 'As4',
    ['Z'] = 'B4',
    ['X'] = 'C5',
}

function PlayInteractiveMusic:start()
    if not self.eventAdded then
        -- no mistake here, the KeyPressed event is named OnKeyStartPressed
        -- and the KeyReleased event is named OnKeyPressed, blame PZ
        self.onKeyPressedLambda = function(key)
            self:onKeyPressed(key)
        end
        self.onKeyReleasedLambda = function(key)
            self:onKeyReleased(key)
        end
        Events.OnKeyStartPressed.Add(self.onKeyPressedLambda)
        Events.OnKeyPressed.Add(self.onKeyReleasedLambda)
        self.eventAdded = true
    end
    for key, _ in pairs(KeyToNote) do
        KeybindManager.getInstance():disableKey(key, 'bard')
    end
    self.isPlaying = true
    self.keyboard = PianoKeyboard:new(self.instrumentName, self.electrical)

    local type = self.item:getFullType()
    -- Checks if the item are on both hands, primary or secondary. self.handItem save it.
    if self.character:isItemInBothHands(self.item) then
        self.handItem = 'BothHands'
    else
        if self.character:isPrimaryHandItem(self.item) then
            self.handItem = 'PrimaryHand'
        elseif self.character:isSecondaryHandItem(self.item) then
            self.handItem = 'SecondaryHand'
        end
    end

    -- Sets the guitar on secondary hand.
    self.character:setPrimaryHandItem(nil)
    self.character:setSecondaryHandItem(self.item)

    -- todo loop on table
    if type == 'Base.GuitarAcoustic' then
        self:setActionAnim('BardPlayGuitarAcoustic')
    elseif type == 'Base.Banjo' then
        self:setActionAnim('BardPlayGuitarAcoustic') -- meh, it works with Acoustic
    elseif type == 'Base.GuitarElectricBlack' or type == 'Base.GuitarElectricBlue' or type == 'Base.GuitarElectricRed' then
        self:setActionAnim('BardPlayGuitarElectric')
    elseif type == 'Base.GuitarElectricBassBlack' or type == 'Base.GuitarElectricBassBlue' or type == 'Base.GuitarElectricBassRed' then
        self:setActionAnim('BardPlayGuitarBass')
    elseif type == 'Base.Keytar' then
        --self:setActionAnim('BardPlaySynthesizer')
    elseif type == 'Base.Flute' then
    end
end

function PlayInteractiveMusic:stop()
    Events.OnKeyStartPressed.Remove(self.onKeyPressedLambda)
    Events.OnKeyPressed.Remove(self.onKeyReleasedLambda)
    KeybindManager.getInstance():restoreKeys()
    self.keyboard:close()
    self.isPlaying = false;
    MusicPlayer.getInstance():stop()
    -- Checks the hand the item was in before the TimedAction and returns it to how it was.
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

    ISBaseTimedAction:stop()
end

function PlayInteractiveMusic:update()
    if self.keyboard.closing then
        self:forceStop()
    end
end

-- I don't think this can be called as the action has not time limit
-- stop should be the last function called before the object end
function PlayInteractiveMusic:perform()
    Events.OnKeyStartPressed.Remove(self.onKeyPressedLambda)
    Events.OnKeyPressed.Remove(self.onKeyReleasedLambda)
    KeybindManager.getInstance():restoreKeys()
    self.keyboard:close()
    self.isPlaying = false;
    MusicPlayer.getInstance():stop()
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
    ISBaseTimedAction:perform()
end

KeybindManager.getInstance():addCategory('[Bard]')
for key, note in pairs(KeyToNote) do
    KeybindManager.getInstance():addBinding(key, 'BardNote' .. note, 'bard')
end

return PlayInteractiveMusic
