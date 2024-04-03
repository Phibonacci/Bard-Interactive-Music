local BardTrait = {}

local instance = nil
function BardTrait.getInstance()
    if instance == nil then
        instance = BardTrait:new()
        return instance
    end
    return instance
end

function BardTrait.getTraitType()
    return 'BardInteractiveMusician'
end

function BardTrait:new()
    assert(instance == nil,
        'BardTrait is a singleton, call getInstance instead')
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.enabled = false
    self.cost = 2
    return o
end

function BardTrait:enableTrait()
    self.enabled = true
end

function BardTrait:disableTrait()
    self.enabled = false
end

function BardTrait:setCost(value)
    self.cost = value
end

function BardTrait:initTrait()
    if self.enabled then
        TraitFactory.addTrait(self.getTraitType(),           -- In code name to refere that trait
            getText('UI_trait_BardInteractiveMusician'),     -- Trait name in game
            self.cost,                                       -- Cost of the trait, can be positive or negative
            getText('UI_trait_BardInteractiveMusicianDesc'), -- Description of the trait
            false,                                           -- Linked to prof, seems to not be used
            false)                                           -- Remove for MP server
    end
end

return BardTrait
