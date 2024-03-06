local TaskPlayInteractiveMusic = require 'TimedAction/TaskPlayInteractiveMusic'

local ValidItems = {
    ['Base.GuitarAcoustic'] = true,
    ['Base.Banjo'] = true,
    ['Base.GuitarElectricBlack'] = true,
    ['Base.GuitarElectricBlue'] = true,
    ['Base.GuitarElectricRed'] = true,
    ['Base.GuitarElectricBassBlack'] = true,
    ['Base.GuitarElectricBassBlue'] = true,
    ['Base.GuitarElectricBassRed'] = true,
    ['Base.Keytar'] = true,
}

local ItemToActionName = {
    ['Base.GuitarAcoustic'] = 'ContextMenu_PlayAcousticGuitar',
    ['Base.Banjo'] = 'ContextMenu_PlayBanjo',
    ['Base.GuitarElectricBlack'] = 'ContextMenu_PlayElectricGuitar',
    ['Base.GuitarElectricBlue'] = 'ContextMenu_PlayElectricGuitar',
    ['Base.GuitarElectricRed'] = 'ContextMenu_PlayElectricGuitar',
    ['Base.GuitarElectricBassBlack'] = 'ContextMenu_PlayBassGuitar',
    ['Base.GuitarElectricBassBlue'] = 'ContextMenu_PlayBassGuitar',
    ['Base.GuitarElectricBassRed'] = 'ContextMenu_PlayBassGuitar',
    ['Base.Keytar'] = 'ContextMenu_PlaySynthesizer',
}

local ContextMenu = {}

ContextMenu.PlayInstrument = function(source, item)
    ISTimedActionQueue.clear(source)

    if not item:isEquipped() then
        ISTimedActionQueue.add(ISEquipWeaponAction:new(source, item, 50, true, false))
    end

    ISTimedActionQueue.add(TaskPlayInteractiveMusic:new(source, item))
end

local function ObjectContextMenu(playerIndex, context, items)
    local source = getSpecificPlayer(playerIndex)

    for i = 1, #items do
        local item
        if type(items[1]) == 'table' then
            item = items[1].items[1]
        else
            item = items[1]
        end
        if ValidItems[item:getFullType()] then
            context:addOption(
                getText(ItemToActionName[item:getFullType()]),
                source, ContextMenu.PlayInstrument, item)
            break
        end
    end
end

Events.OnPreFillInventoryObjectContextMenu.Add(ObjectContextMenu)
