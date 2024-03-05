local PianoKeyboard = ISCollapsableWindow:derive("PianoKeyboard");
local MusicPlayer = require 'MusicPlayer'

local NOTES_IN_SCALE = 7 -- A, B, C, D, E, F, G
local KEY_RATIO = 7

local WHITE_KEY_TEXTURE_WIDTH = 4 * KEY_RATIO
local SPACE_AROUND_WHITE_KEY = 2
local WHITE_KEY_WIDTH = WHITE_KEY_TEXTURE_WIDTH + SPACE_AROUND_WHITE_KEY * 2 -- left and right spaces
local WHITE_KEY_HEIGHT = 27 * KEY_RATIO

local BLACK_KEY_TEXTURE_WIDTH = 3 * KEY_RATIO
local SPACE_AROUND_BLACK_KEY = 0
local BLACK_KEY_WIDTH = BLACK_KEY_TEXTURE_WIDTH + SPACE_AROUND_BLACK_KEY * 2
local BLACK_KEY_HEIGHT = 16 * KEY_RATIO


local OCTAVES_INCLUDED = 3
local NOTES_INCLUDED = OCTAVES_INCLUDED * NOTES_IN_SCALE + 1 -- from C2 to C5
local SCALE_WIDTH = WHITE_KEY_WIDTH * NOTES_IN_SCALE         -- width of a group of 7 white keys

local WIDTH = WHITE_KEY_WIDTH * NOTES_INCLUDED
local HEIGHT = WHITE_KEY_HEIGHT + ISCollapsableWindow.TitleBarHeight()
local X = getCore():getScreenWidth() / 2 - WIDTH / 2
local Y = getCore():getScreenHeight() - HEIGHT - 75

function PianoKeyboard:new(instrument, iSelectrical)
    local o = ISCollapsableWindow:new(X, Y, WIDTH, HEIGHT);
    setmetatable(o, self)
    self.__index = self

    o.instrument = instrument
    o.iSelectrical = iSelectrical

    o.textureKeyWhite = getTexture('media/ui/piano/Keys/White1.png');
    o.textureKeyWhitePressed = getTexture('media/ui/piano/Keys/White1Pressed.png');
    o.textureKeyBlack = getTexture('media/ui/piano/Flats + Sharps/White.png')
    o.textureKeyBlackPressed = getTexture('media/ui/piano/Flats + Sharps/WhitePressed.png')
    o.distortionButtonOnImage = getTexture('media/ui/thunder-on-icon.png')
    o.distortionButtonOffImage = getTexture('media/ui/thunder-off-icon.png')

    o.closing = false
    o.distorted = false
    o.currentKeyPressed = nil
    o.keyPressed = {}
    o:initialise()
    return o
end

function PianoKeyboard:initialise()
    ISCollapsableWindow.initialise(self)
    ISCollapsableWindow.createChildren(self)

    self:setInfo(getText("SurvivalGuide_BardInteractiveMusic"))

    local th = self:titleBarHeight()
    self.distortionButton = ISButton:new(
        self.infoButton:getRight() + 1, 0, th, th,
        "", self, function(self, button) self:onDistortionButton(button) end)
    self.distortionButton:initialise()
    self.distortionButton.borderColor.a = 0.0
    self.distortionButton.backgroundColor.a = 0.0
    self.distortionButton.backgroundColorMouseOver.a = 0.7
    self.distortionButton:setImage(self.distortionButtonOffImage)
    self:addChild(self.distortionButton)
    -- todo: I wanted to add some mods for the bass as well but I did not
    -- find samples. It would be nice to have multiple options for all instruments
    -- like steel chords for the classical guitar
    self.distortionButton:setVisible(self.instrument == "GuitarElectric");

    self:setResizable(false)
    self:addToUIManager()
    -- ISLayoutManager.RegisterWindow('PianoKeyboard', PianoKeyboard, self);
end

function PianoKeyboard:prerender()
    ISCollapsableWindow.prerender(self)
end

function PianoKeyboard:close()
    ISCollapsableWindow.close(self)
    self.closing = true
    self:removeFromUIManager()
end

function PianoKeyboard:render()
    ISCollapsableWindow.render(self)
    self:drawDistortionButton()
    self:drawKeys()
end

function PianoKeyboard:drawDistortionButton()
    -- self:drawTextureScaled(texture, x + SPACE_AROUND_WHITE_KEY, self:titleBarHeight(),
    --     WHITE_KEY_TEXTURE_WIDTH, drawHeight, 1, 1, 1, 1)
end

function PianoKeyboard:drawKeys()
    for scaleOffset = 0, 2 do
        self:drawKeysOfScale(scaleOffset)
    end
    local keyName = ScaleOffsetToKeyName(3, 0, false)
    self:drawWhiteKey(self.keyPressed[keyName] ~= nil,
        3 * SCALE_WIDTH)
end

local keyOffsetToNoteName = {
    'C', 'D', 'E', 'F', 'G', 'A', 'B'
}

function ScaleOffsetToKeyName(scaleOffset, keyOffset, isSharp)
    local note = keyOffsetToNoteName[keyOffset + 1]
    local sharp = isSharp and 's' or ''
    local octave = 2 + scaleOffset
    return note .. sharp .. octave
end

function PianoKeyboard:drawKeysOfScale(scaleOffset)
    local scaleX = scaleOffset * SCALE_WIDTH
    for keyOffset = 0, 6 do
        local keyName = ScaleOffsetToKeyName(scaleOffset, keyOffset, false)
        -- C1,D1,E1..A1,B1,C2 this is not the note octave but the key positioning
        self:drawWhiteKey(self.keyPressed[keyName] ~= nil,
            scaleX + keyOffset * WHITE_KEY_WIDTH)
    end
    for keyOffset = 0, 5 do    -- C# (0) to A# (5)
        if keyOffset ~= 2 then -- actually there is no E# (2)
            local keyName = ScaleOffsetToKeyName(scaleOffset, keyOffset, true)
            self:drawBlackKey(self.keyPressed[keyName] ~= nil,
                scaleX + (keyOffset + 1) * WHITE_KEY_WIDTH - BLACK_KEY_WIDTH / 2)
        end
    end
end

function PianoKeyboard:drawWhiteKey(isPressed, x)
    local texture = isPressed and self.textureKeyWhitePressed or self.textureKeyWhite
    local drawHeight = WHITE_KEY_HEIGHT
    -- when self:getMaxDrawHeight() is 'cleared' it is worth -1... come on!
    -- when it is not it cannot be lower than self:titleBarHeight() which is
    -- around 16 depending on font
    if self:getMaxDrawHeight() > 0 then
        drawHeight = math.min(self:getMaxDrawHeight() - self:titleBarHeight(), WHITE_KEY_HEIGHT)
    end
    if drawHeight <= 0 then
        return
    end
    self:drawTextureScaled(texture, x + SPACE_AROUND_WHITE_KEY, self:titleBarHeight(),
        WHITE_KEY_TEXTURE_WIDTH, drawHeight, 1, 1, 1, 1)
end

function PianoKeyboard:drawBlackKey(isPressed, x)
    local texture = isPressed and self.textureKeyBlackPressed or self.textureKeyBlack
    local drawHeight = BLACK_KEY_HEIGHT
    if self:getMaxDrawHeight() > 0 then
        drawHeight = math.min(self:getMaxDrawHeight() - self:titleBarHeight(), BLACK_KEY_HEIGHT)
    end
    if drawHeight <= 0 then
        return
    end
    self:drawTextureScaled(texture, x + SPACE_AROUND_BLACK_KEY, self:titleBarHeight(),
        BLACK_KEY_TEXTURE_WIDTH, drawHeight, 1, 1, 1, 1)
end

function PianoKeyboard:pressKeyWithMouse(x, y)
    return self:pressBlackKey(x, y) or self:pressWhiteKey(x, y)
end

function PianoKeyboard:getKey(x, y)
    return self:getBlackKey(x, y) or self:getWhiteKey(x, y)
end

function PianoKeyboard:getBlackKey(x, y)
    if y < self:titleBarHeight() or y > HEIGHT
        or x < 0 or x > WIDTH
    then
        return nil
    end
    if x <= WHITE_KEY_WIDTH / 2 or y > self:titleBarHeight() + BLACK_KEY_HEIGHT then
        return nil
    end
    local keyIndex = math.floor((x - WHITE_KEY_WIDTH / 2) / WHITE_KEY_WIDTH)
    local i = (x - WHITE_KEY_WIDTH / 2) % WHITE_KEY_WIDTH
    if i >= (WHITE_KEY_WIDTH - BLACK_KEY_WIDTH) / 2
        and i <= WHITE_KEY_WIDTH - (WHITE_KEY_WIDTH - BLACK_KEY_WIDTH) / 2
    then
        local scaleOffset = math.floor(keyIndex / 7)
        local keyOffset = keyIndex % 7
        if keyOffset == 2 or keyOffset == 6 then
            return nil -- no E# or B#
        end
        return ScaleOffsetToKeyName(scaleOffset, keyOffset, true)
    end
end

function PianoKeyboard:getWhiteKey(x, y)
    if y < self:titleBarHeight() or y > HEIGHT
        or x < 0 or x > WIDTH
    then
        return nil
    end
    local keyIndex = math.floor(x / WHITE_KEY_WIDTH)
    local scaleOffset = math.floor(keyIndex / 7)
    local keyOffset = keyIndex % 7
    return ScaleOffsetToKeyName(scaleOffset, keyOffset, false)
end

function PianoKeyboard:pressBlackKey(x, y)
    local keyName = self:getBlackKey(x, y)
    if keyName == nil then
        return false
    end
    self.keyPressed[keyName] = true
    self.currentKeyPressed = keyName
    MusicPlayer.getInstance():playNote(getPlayer():getOnlineID(), self.instrument, keyName, self:isDistorted())
    return true
end

function PianoKeyboard:pressWhiteKey(x, y)
    local keyName = self:getWhiteKey(x, y)
    if keyName == nil then
        return false
    end
    self.keyPressed[keyName] = true
    self.currentKeyPressed = keyName
    MusicPlayer.getInstance():playNote(getPlayer():getOnlineID(), self.instrument, keyName, self:isDistorted())
    return true
end

function PianoKeyboard:onMouseDown(x, y)
    if not self:pressKeyWithMouse(x, y) then
        -- copied from ISCollapsableWindow.lua onMouseDown()
        -- calling the function was not working
        if not self:getIsVisible() then
            return
        end
        self.downX = x
        self.downY = y
        self.moving = true
        self:bringToTop()
    end
end

function PianoKeyboard:releaseKeyWithMouse()
    self.keyPressed[self.currentKeyPressed] = nil
    if self.currentKeyPressed ~= nil then
        MusicPlayer.getInstance():stopNote(getPlayer():getOnlineID(), self.currentKeyPressed)
    end
    self.currentKeyPressed = nil
end

function PianoKeyboard:onMouseUp(x, y)
    if self.currentKeyPressed ~= nil
    then
        self:releaseKeyWithMouse()
    end

    -- copied from ISCollapsableWindow.lua onMouseUp()
    -- calling the function was not working
    if not self:getIsVisible() then
        return
    end
    self.moving = false
    if ISMouseDrag.tabPanel then
        ISMouseDrag.tabPanel:onMouseUp(x, y)
    end
    ISMouseDrag.dragView = nil
end

function PianoKeyboard:onMouseUpOutside(x, y)
    if self.currentKeyPressed ~= nil then
        self:releaseKeyWithMouse()
    end

    -- copied from ISCollapsableWindow.lua onMouseUpOutside()
    -- calling the function was not working
    if not self:getIsVisible() then
        return
    end

    self.moving = false
    ISMouseDrag.dragView = nil
end

function PianoKeyboard:onMouseMove(x, y)
    if self.currentKeyPressed ~= nil then
        local keyOvered = self:getKey(self:getMouseX(), self:getMouseY())
        if keyOvered ~= self.currentKeyPressed then
            self:releaseKeyWithMouse()
            if keyOvered ~= nil then
                self:pressKeyWithMouse(self:getMouseX(), self:getMouseY())
            end
        end
    end

    -- copied from ISCollapsableWindow.lua onMouseMove()
    -- calling the function was not working
    self.mouseOver = true;

    if self.moving then
        self:setX(self.x + x);
        self:setY(self.y + y);
        self:bringToTop();
        --ISMouseDrag.dragView = self;
    end
    if not isMouseButtonDown(0) and not isMouseButtonDown(1) and not isMouseButtonDown(2) then
        self:uncollapse();
    end
end

function PianoKeyboard:onMouseMoveOutside(dx, dy)
    if self.currentKeyPressed ~= nil then
        self:releaseKeyWithMouse()
    end

    -- copied from ISCollapsableWindow.lua onMouseMoveOutside()
    -- calling the function was not working
    self.mouseOver = false;

    if self.moving then
        self:setX(self.x + dx);
        self:setY(self.y + dy);
        self:bringToTop();
    end

    if not self.pin and (self:getMouseX() < 0 or self:getMouseY() < 0 or self:getMouseX() > self:getWidth() or self:getMouseY() > self:getHeight()) then
        self.collapseCounter = self.collapseCounter + 1;

        local bDo = true;

        if self.collapseCounter > 20 and not self.isCollapsed and bDo then
            self.isCollapsed = true;
            self:setMaxDrawHeight(self:titleBarHeight());
        end
    end
end

function PianoKeyboard:markPressedKey(keyName)
    self.keyPressed[keyName] = true
end

function PianoKeyboard:markReleasedKey(keyName)
    self.keyPressed[keyName] = nil
    if keyName == self.currentKeyPressed then
        self.currentKeyPressed = nil
    end
end

function PianoKeyboard:onDistortionButton(button)
    self:setDistortion(not self.distorted)
end

function PianoKeyboard:setDistortion(isDistorted)
    self.distorted = isDistorted
    self.distortionButton:setImage(
        isDistorted and self.distortionButtonOnImage or self.distortionButtonOffImage)
end

function PianoKeyboard:isDistorted()
    return self.distorted
end

return PianoKeyboard
