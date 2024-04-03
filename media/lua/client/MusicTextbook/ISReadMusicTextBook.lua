local BardTrait = require 'BardTrait'
local ISReadMusicTextBook = ISReadABook:derive("ISReadABook");


function ISReadMusicTextBook:perform()
    ISReadABook.perform(self)
    local player = getPlayer()
    player:getTraits():add(BardTrait.getTraitType())
    player:getInventory():Remove(self.item)
    player:removeFromHands(self.item)
end

function ISReadMusicTextBook:start(character, item, time)
    self.item:setJobType(getText("ContextMenu_Read") .. ' ' .. self.item:getName());
    self.item:setJobDelta(0.0);
    self:setAnimVariable("ReadType", "book")
    self:setActionAnim(CharacterActionAnims.Read);

    self.displayItem = instanceItem('Base.SmithingMag3')
    self:setOverrideHandModels(nil, self.displayItem);

    self.character:setReading(true)
    self.character:reportEvent("EventRead");

    if SkillBook[self.item:getSkillTrained()] then
        self.character:playSound("OpenBook")
    else
        self.character:playSound("OpenMagazine")
    end
end

function ISReadMusicTextBook:new(character, item, time)
    local o = ISReadABook.new(self, character, item, time)
    setmetatable(o, self)
    self.__index = self
    o.maxTime = o.maxTime * 0.1 -- we want to read it fast
    return o;
end

return ISReadMusicTextBook
