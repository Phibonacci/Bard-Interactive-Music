local KeybindManager = {}
local KeyCode = require 'KeyCode'

local instance = nil
function KeybindManager.getInstance()
    if instance == nil then
        instance = KeybindManager:new()
    end
    return instance
end

function KeybindManager:new()
    assert(instance == nil,
        'KeybindManager is a singleton, call getInstance instead')
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.overridenKeys = nil
    return o
end

function KeybindManager:removeAndSaveBindings(keyCode, exceptTag)
    for _, keybind in ipairs(keyBinding) do
        if keybind.key == keyCode
            and (keybind.tag == nil or keybind.tag ~= exceptTag)
            and keybind.key ~= nil -- only keybind, not categories
        then
            if self.overridenKeys == nil then
                self.overridenKeys = {}
            end
            table.insert(self.overridenKeys, keybind)
            getCore():addKeyBinding(keybind.value, 0)
        end
    end
end

function KeybindManager:addCategory(category)
    table.insert(keyBinding, { value = category });
end

function KeybindManager:addBinding(keyName, keyValue, tag)
    local keyCode = KeyCode[keyName]
    table.insert(keyBinding, { value = keyValue, key = keyCode, tag = tag })
end

function KeybindManager:disableKey(keyName, exceptTag)
    local keyCode = KeyCode[keyName]
    if keyCode == nil then
        print('KeybindManager: disableKey called with unknown keyName: ' .. keyName)
        return
    end
    self:removeAndSaveBindings(keyCode, exceptTag)
end

function KeybindManager:restoreKeys()
    if self.overridenKeys == nil then return end
    for _, keybind in ipairs(self.overridenKeys) do
        getCore():addKeyBinding(keybind.value, keybind.key)
    end
    self.overridenKeys = nil
end

return KeybindManager
