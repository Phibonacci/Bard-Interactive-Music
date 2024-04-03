local BardTrait = require 'BardTrait'
local ISReadMusicTextBook = require 'MusicTextbook/ISReadMusicTextBook'

ISInventoryMenuElements = ISInventoryMenuElements or {}

function ISInventoryMenuElements.ContextMusicTextBook()
    local self         = ISMenuElement.new()
    self.inventoryMenu = ISContextManager.getInstance().getInventoryMenu()

    ---@diagnostic disable-next-line: duplicate-set-field
    function self.init()
    end

    ---@diagnostic disable-next-line: duplicate-set-field
    function self.createMenu(item)
        if not BardTrait.getInstance().enabled then
            return
        end
        if item:getFullType() == 'BardInteractiveMusic.MusicTextBook' then
            self.inventoryMenu.context:removeOptionByName(getText('ContextMenu_Read'))
            if not getPlayer():HasTrait(BardTrait.getTraitType()) then
                self.inventoryMenu.context:addOption(
                    getText('ContextMenu_Bard_ReadMusicTextbook'),
                    self.inventoryMenu,
                    self.onLearnMusic,
                    item)
            end
        end
    end

    function self.onLearnMusic(inventoryMenu, item)
        local player = getPlayer()
        ISInventoryPaneContextMenu.transferIfNeeded(player, item)
        -- the 3rd parameter is a trap, it's unused...
        ISTimedActionQueue.add(ISReadMusicTextBook:new(player, item, 1))
    end

    function self.onMyDebugInfos(inventoryMenu, item)
        if item == nil then
            print('nil item')
            return
        end

        if item:getTexture() == nil then
            print('nil texture')
        else
            if item:getTexture():getName() ~= nil then
                print('Texture          : ' .. item:getTexture():getName())
            else
                print('nil texture name')
            end
        end
        print('World Texture    : ' .. item:getWorldTexture())
        print('Type             : ' .. item:getType())
        print('Full Type        : ' .. item:getFullType())
        print('World Static Item: ' .. item:getWorldStaticItem())
        if (item:getIconsForTexture() ~= nil and item:getIconsForTexture() > 0) then
            for icon in item:getIconsForTexture() do
                print('Icon             : ' .. icon)
            end
        end
    end

    return self
end
