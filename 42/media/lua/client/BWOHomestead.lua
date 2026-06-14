--[[ ============================================================================
     Bandits Week One - Homestead
     ----------------------------------------------------------------------------
     Solves the "I spawned inside a house with no key, and Bandits NPCs move in
     the moment I leave" problem.

     WHY A KEY ALONE DOES NOTHING:
       Week One's inhabitant spawner (BWOPopControl.InhabitantsSpawn) teleports
       NPCs straight onto a free tile inside a room - they never path through the
       door, so a locked door is irrelevant. The ONLY building it skips is the one
       flagged as your "home" (BWOPopControl.lua: `IsEventBuilding(building,"home")`).
       That flag is normally set once, for your starting building, by
       BWOEvents.Start - which also gives you a "Home Key".

     WHAT THIS MOD ADDS (all via the right-click world menu, no debug mode):
       * "Claim this house as home"  - only while standing in a building and only
         when Bandits Week One is loaded. Sends Week One's own EventBuildingAdd
         command with event="home" (so it's fully save-compatible), stamps every
         door in the building to the building's key id, and gives you that key
         named "Home Key". This is the part that actually stops the move-ins.
       * "Forge key for this door"    - on any door you don't already have a key
         for. Mirrors the vanilla debug getDoorKey logic (handles double / garage
         doors). Works in any save, Bandits or not.
       * "Forge key for this vehicle" - on any car you don't already have a key
         for. Creates a matching Base.CarKey. Works in any save.

     Single client file, no overrides - it only listens to the context-menu event.
     ========================================================================== ]]

BWOHomestead = BWOHomestead or {}

-- ----------------------------------------------------------------------------
-- helpers
-- ----------------------------------------------------------------------------

local function isDoorObject(o)
    return instanceof(o, "IsoDoor") or (instanceof(o, "IsoThumpable") and o:isDoor())
end

local function doorKeyId(door)
    if instanceof(door, "IsoDoor") then return door:checkKeyId() end
    return door:getKeyId()
end

-- give the player a key item tuned to keyId; returns the item
local function giveKey(playerObj, itemType, keyId, displayName)
    local key = instanceItem(itemType)
    key:setKeyId(keyId)
    if displayName then key:setName(displayName) end
    playerObj:getInventory():AddItem(key)
    return key
end

-- set keyId on a door plus any double/garage-door siblings
local function stampDoor(door, keyId)
    door:setKeyId(keyId)
    local doubles = buildUtil.getDoubleDoorObjects(door)
    for i = 1, #doubles do doubles[i]:setKeyId(keyId) end
    local garage = buildUtil.getGarageDoorObjects(door)
    for i = 1, #garage do garage[i]:setKeyId(keyId) end
end

-- stamp every door inside a building to keyId so one key works on all of them
local function stampBuildingDoors(building, keyId)
    local def = building:getDef()
    local cell = getCell()

    -- gather the z-levels the building actually occupies
    local zLevels = {}
    local rooms = def:getRooms()
    for i = 0, rooms:size() - 1 do
        zLevels[rooms:get(i):getZ()] = true
    end

    -- expand the bounds by 1 so edge-mounted doors are included
    local x1, y1 = def:getX() - 1, def:getY() - 1
    local x2, y2 = def:getX2() + 1, def:getY2() + 1

    for z in pairs(zLevels) do
        for x = x1, x2 do
            for y = y1, y2 do
                local sq = cell:getGridSquare(x, y, z)
                if sq then
                    local objects = sq:getObjects()
                    for i = 0, objects:size() - 1 do
                        local o = objects:get(i)
                        if isDoorObject(o) then
                            stampDoor(o, keyId)
                        end
                    end
                end
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- actions
-- ----------------------------------------------------------------------------

function BWOHomestead.onForgeDoorKey(worldobjects, playerObj, door)
    local keyId = doorKeyId(door)
    if keyId == -1 then
        keyId = ZombRand(100000000)
    end
    stampDoor(door, keyId)
    giveKey(playerObj, "Base.Key1", keyId, nil)
    playerObj:Say("That should fit the lock now.")
end

function BWOHomestead.onForgeVehicleKey(worldobjects, playerObj, vehicle)
    local keyId = vehicle:getKeyId()
    if not keyId or keyId == -1 then
        playerObj:Say("This vehicle has no lock to key.")
        return
    end
    giveKey(playerObj, "Base.CarKey", keyId, nil)
    playerObj:Say("A spare key - that should start it.")
end

function BWOHomestead.onClaimHome(worldobjects, playerObj, building)
    local def = building:getDef()
    local keyId = def:getKeyId()

    -- 1) flag the building as our "home" using Week One's own server command, so
    --    the inhabitant spawner stops moving NPCs in (BWOPopControl skips "home").
    local args = {
        id = keyId,
        event = "home",
        x = (def:getX() + def:getX2()) / 2,
        y = (def:getY() + def:getY2()) / 2,
    }
    sendClientCommand(playerObj, "Commands", "EventBuildingAdd", args)

    -- 2) make the building's doors all answer to one key
    stampBuildingDoors(building, keyId)

    -- 3) hand over that key
    giveKey(playerObj, "Base.Key1", keyId, "Home Key")

    playerObj:Say("This is my home now.")
end

-- ----------------------------------------------------------------------------
-- context menu
-- ----------------------------------------------------------------------------

function BWOHomestead.OnFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    if test then return end
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end
    local inv = playerObj:getInventory()

    -- DOOR: forge a key for the clicked door (unless we already have one)
    local door
    for _, o in ipairs(worldobjects) do
        if isDoorObject(o) then door = o break end
    end
    if door and not inv:haveThisKeyId(doorKeyId(door)) then
        context:addOption("Forge key for this door",
            worldobjects, BWOHomestead.onForgeDoorKey, playerObj, door)
    end

    -- VEHICLE: forge a key for the moused-over car (unless we already have one)
    local vehicle = IsoObjectPicker.Instance:PickVehicle(getMouseXScaled(), getMouseYScaled())
    if vehicle and not inv:haveThisKeyId(vehicle:getKeyId()) then
        context:addOption("Forge key for this vehicle",
            worldobjects, BWOHomestead.onForgeVehicleKey, playerObj, vehicle)
    end

    -- HOME: claim the building we're standing in (Bandits Week One only)
    local building = playerObj:getBuilding()
    if building and getActivatedMods():contains("BanditsWeekOne") then
        local alreadyHome = BWOBuildings and BWOBuildings.IsEventBuilding(building, "home")
        if not alreadyHome then
            context:addOption("Claim this house as home",
                worldobjects, BWOHomestead.onClaimHome, playerObj, building)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(BWOHomestead.OnFillWorldObjectContextMenu)
