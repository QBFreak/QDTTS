--[[ Survey.lua ]]--
--
-- Survey the hill perimeter as marked with redstone torches

function task(qtobj)
    -- The new instance
    local self = {
        -- Public fields go here in the instance table
        name = "Perimeter survey"
    }

    -- Private fields are implemented using locals
    local qt = qtobj

    -- Run some init code here
    print(self.name)

    -- Put some functions here
    function self.run()
        if qt.init() == false then
            print("Failed to initialize")
        end

        loc = qt.getLoc(qt.name().."_home")
        if loc == nil then
            qt.saveLoc(qt.name().."_home")
            loc = qt.getLoc(qt.name().."_home")
        end
        if loc == nil then
            print("Failed to retrieve home location!")
            return
        end
        print("Home location: "..loc.x.." "..loc.y.." "..loc.z)

        qt.face(qt.North())

        -- Look for the torch that marks the outline
        qt.forwardUntil("minecraft:torch")

        -- Look for the first corner marker
        qt.face(qt.East())
        qt.forwardUntil("minecraft:redstone_torch")
        qt.saveLoc(qt.name().."_CornerSE")

        -- Look for the second corner marker
        qt.face(qt.North())
        qt.forward()
        qt.forwardUntil("minecraft:redstone_torch")
        qt.saveLoc(qt.name().."_CornerNE")

        -- Look for the third corner marker
        qt.face(qt.West())
        qt.forward()
        qt.forwardUntil("minecraft:redstone_torch")
        qt.saveLoc(qt.name().."_CornerNW")

        -- Look for the fourth corner marker
        qt.face(qt.South())
        qt.forward()
        qt.forwardUntil("minecraft:redstone_torch")
        qt.saveLoc(qt.name().."_CornerSW")

        -- Home
        qt.face(qt.East())
        qt.forward()
        qt.forwardUntil("minecraft:torch")
        qt.face(qt.South())
        qt.forwardWhile("minecraft:brick_block")
        qt.forwardClimb()
    end

    -- Return the instance
    return self
end
