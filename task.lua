--[[ Task.lua ]]--
--
-- Sample task

function task(qtobj)
    -- The new instance
    local self = {
        -- Public fields go here in the instance table
        name = "My Task"
    }

    -- Private fields are implemented using locals
    local qt = qtobj

    -- Run some init code here
    print(self.name)

    -- Put some functions here
    function self.run()
        qt.init()

        -- Face North
        qt.face(qt.North())

        -- Drop to ground level
        qt.sink()

        -- Get the block below the turtle
        succ, blk = turtle.inspectDown()
        -- Move forward until we find something different
        qt.forwardWhile(blk.name)

        succ, blk = turtle.inspectDown()
        print("Found "..blk.name)
    end

    -- Return the instance
    return self
end
