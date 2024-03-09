local TAPlayMusicFromInventory = require 'TimedAction/TAPlayMusicFromInventory'
local TAPlayMusicFromWorld = require 'TimedAction/TAPlayMusicFromWorld'

local PlayerItemToActionName = {
    ['Base.GuitarAcoustic'] = 'ContextMenu_Bard_PlayAcousticGuitar',
    ['Base.Banjo'] = 'ContextMenu_Bard_PlayBanjo',
    ['Base.GuitarElectricBlack'] = 'ContextMenu_Bard_PlayElectricGuitar',
    ['Base.GuitarElectricBlue'] = 'ContextMenu_Bard_PlayElectricGuitar',
    ['Base.GuitarElectricRed'] = 'ContextMenu_Bard_PlayElectricGuitar',
    ['Base.GuitarElectricBassBlack'] = 'ContextMenu_Bard_PlayBassGuitar',
    ['Base.GuitarElectricBassBlue'] = 'ContextMenu_Bard_PlayBassGuitar',
    ['Base.GuitarElectricBassRed'] = 'ContextMenu_Bard_PlayBassGuitar',
    ['Base.Keytar'] = 'ContextMenu_Bard_PlaySynthesizer',
    ['Base.Flute'] = 'ContextMenu_Bard_PlayFlute',
    ['Base.Saxophone'] = 'ContextMenu_Bard_PlaySaxophone',
    ['Base.Trumpet'] = 'ContextMenu_Bard_PlayTrumpet',
    ['Base.Violin'] = 'ContextMenu_Bard_PlayViolin',
}

local ContextMenu = {}

ContextMenu.PlayInstrument = function(source, item)
    ISTimedActionQueue.clear(source)

    if not item:isEquipped() then
        ISTimedActionQueue.add(ISEquipWeaponAction:new(source, item, 50, true, false))
    end
    ISTimedActionQueue.add(TAPlayMusicFromInventory:new(source, item))
end

local function PlayerObjectContextMenu(playerIndex, context, items)
    local source = getSpecificPlayer(playerIndex)

    for i = 1, #items do
        local item
        if type(items[1]) == 'table' then
            item = items[1].items[1]
        else
            item = items[1]
        end
        if PlayerItemToActionName[item:getFullType()] ~= nil then
            context:addOption(
                getText(PlayerItemToActionName[item:getFullType()]),
                source, ContextMenu.PlayInstrument, item)
            break
        end
    end
end

local WorldItemToActionInfo = {
    ['recreational_01_8']  = { action = 'ContextMenu_Bard_PlayPiano', facing = 'south', side = 'left', instrument = 'Piano', upperSide = 'recreational_01_8' },
    ['recreational_01_9']  = { action = 'ContextMenu_Bard_PlayPiano', facing = 'south', side = 'right', instrument = 'Piano', upperSide = 'recreational_01_8' },
    ['recreational_01_12'] = { action = 'ContextMenu_Bard_PlayPiano', facing = 'east', side = 'left', instrument = 'Piano', upperSide = 'recreational_01_13' },
    ['recreational_01_13'] = { action = 'ContextMenu_Bard_PlayPiano', facing = 'east', side = 'right', instrument = 'Piano', upperSide = 'recreational_01_13' },
    ['recreational_01_40'] = { action = 'ContextMenu_Bard_PlayPiano', facing = 'south', side = 'left', instrument = 'GrandPiano', upperSide = 'recreational_01_40' },
    ['recreational_01_41'] = { action = 'ContextMenu_Bard_PlayPiano', facing = 'south', side = 'right', instrument = 'GrandPiano', upperSide = 'recreational_01_40' },
    ['recreational_01_48'] = { action = 'ContextMenu_Bard_PlayPiano', facing = 'east', side = 'left', instrument = 'GrandPiano', upperSide = 'recreational_01_49' },
    ['recreational_01_49'] = { action = 'ContextMenu_Bard_PlayPiano', facing = 'east', side = 'right', instrument = 'GrandPiano', upperSide = 'recreational_01_49' },
}

local function getWestSquare(square)
    return getWorld():getCell():getGridSquare(square:getX() - 1, square:getY(), square:getZ())
end

-- IsoSquare has a getS() function that can return nil for no apparent reason
local function getSouthSquare(square)
    return getWorld():getCell():getGridSquare(square:getX(), square:getY() - 1, square:getZ())
end

local function getPianoUpperSide(pianoSquare, actionInfo)
    local upperPianoSquare
    if actionInfo.facing == 'south' and actionInfo.side == 'right' then
        upperPianoSquare = getWestSquare(pianoSquare)
    elseif actionInfo.facing == 'east' and actionInfo.side == 'left' then
        upperPianoSquare = getSouthSquare(pianoSquare)
    else
        upperPianoSquare = pianoSquare
    end
    local upperSidePianoObject = nil
    for i = 0, upperPianoSquare:getObjects():size() - 1 do
        local object = upperPianoSquare:getObjects():get(i)
        if actionInfo.upperSide == object:getSprite():getName() then
            upperSidePianoObject = object
        end
    end
    return upperSidePianoObject
end

-- todo: add very single suitable seat in the world
local SeatSpriteName = {
    ["recreational_01_10"] = true,
    ["recreational_01_11"] = true,
    ["recreational_01_14"] = true,
    ["recreational_01_15"] = true,
}

local function hasSeat(squareFacingPiano)
    for i = 0, squareFacingPiano:getObjects():size() - 1 do
        local object = squareFacingPiano:getObjects():get(i)
        local spriteName = object:getSprite():getName()
        if SeatSpriteName[spriteName] then
            return true
        end
    end
    return false
end

local function onPlayPiano(worldobjects, player, square, actionInfo)
    local upperSidePianoObject = getPianoUpperSide(square, actionInfo)
    if upperSidePianoObject == nil then
        return nil
    end
    -- it's alright, this square is working with getS() and getE(), very consistant API, no problem here
    local squareFacingPiano = actionInfo.facing == "south" and upperSidePianoObject:getSquare():getS()
        or upperSidePianoObject:getSquare():getE()
    ISTimedActionQueue.add(ISWalkToTimedAction:new(player, squareFacingPiano))
    ISTimedActionQueue.add(TAPlayMusicFromWorld:new(player, actionInfo.instrument,
        upperSidePianoObject, actionInfo.facing, hasSeat(squareFacingPiano)))
end

local function WorldObjectContextMenu(playerIndex, context, worldobjects, test)
    local addedContext = {}
    if test then return end
    local player = getSpecificPlayer(playerIndex)
    for _, worldobject in ipairs(worldobjects) do
        local square = worldobject:getSquare()
        for i = 0, square:getObjects():size() - 1 do
            local item = square:getObjects():get(i)
            local spriteName = item:getSprite():getName()
            if WorldItemToActionInfo[spriteName] ~= nil then
                -- for some unknown reason the pianos are listed twice so we filter the duplicate
                if addedContext[item:getWorldObjectIndex()] == nil then
                    addedContext[item:getWorldObjectIndex()] = true
                    context:addOption(getText("ContextMenu_Bard_PlayPiano"), worldobjects,
                        onPlayPiano,
                        player, square, WorldItemToActionInfo[spriteName])
                end
            end
        end
    end
end

Events.OnPreFillInventoryObjectContextMenu.Add(PlayerObjectContextMenu)
Events.OnPreFillWorldObjectContextMenu.Add(WorldObjectContextMenu)
