local TABasePlayMusicFrom = ISBaseTimedAction:derive('TABasePlayMusicFrom');

local MusicNotes = require 'MusicNotes'
local MusicPlayer = require 'MusicPlayer'
local BardClientSendCommands = require 'BardClientSendCommands'
local KeybindManager = require 'KeybindManager'
local PianoKeyboard = require 'ui/PianoKeyboard'

function TABasePlayMusicFrom:new(character, instrument, hasDistortion)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index = self
    o.instrument = instrument
    o.hasDistortion = hasDistortion
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = true
    o.maxTime = -1
    o.handItem = nil
    o.isPlaying = false
    o.eventAdded = false
    o.keyboard = nil
    return o
end

function TABasePlayMusicFrom:onKeyPressed(key)
    if not self.isPlaying then
        return
    end
    for octave = 2, 5 do
        for _, noteName in pairs(MusicNotes) do
            local fullNote = noteName .. octave
            if key == getCore():getKey('BardNote' .. fullNote) then
                local playerId = getPlayer():getOnlineID()
                BardClientSendCommands.sendStartNote(playerId, self.instrument, fullNote, self.keyboard:isDistorted())
                MusicPlayer.getInstance():playNote(playerId, self.instrument, fullNote, self.keyboard:isDistorted())
                self.keyboard:markPressedKey(fullNote)
            end
        end
    end
end

function TABasePlayMusicFrom:onKeyReleased(key)
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

function TABasePlayMusicFrom:isValid()
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

function TABasePlayMusicFrom:start()
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
    self.keyboard = PianoKeyboard:new(self.instrument, self.hasDistortion)
end

function TABasePlayMusicFrom:terminateAction()
    Events.OnKeyStartPressed.Remove(self.onKeyPressedLambda)
    Events.OnKeyPressed.Remove(self.onKeyReleasedLambda)
    KeybindManager.getInstance():restoreKeys()
    self.keyboard:close()
    self.isPlaying = false;
    MusicPlayer.getInstance():stop()
end

function TABasePlayMusicFrom:stop()
    self:terminateAction()
    ISBaseTimedAction.stop(self)
end

function TABasePlayMusicFrom:update()
    if self.keyboard.closing then
        self:forceStop()
    end
end

-- I don't think this can be called as the action has no time limit
-- stop should be the last function called before the object ends
function TABasePlayMusicFrom:perform()
    self:terminateAction()
    ISBaseTimedAction.perform(self)
end

KeybindManager.getInstance():addCategory('[Bard]')
for key, note in pairs(KeyToNote) do
    KeybindManager.getInstance():addBinding(key, 'BardNote' .. note, 'bard')
end

return TABasePlayMusicFrom
