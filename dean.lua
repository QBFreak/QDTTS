-- dean.lua v1.0 - Dean Winchester - He's been to hell and back. Litterally.
--  Quick and Dirty Turtle Task System - Client

local tArgs = { ... }

-- Turtle name
local myName = "Dean"

-- Task name
local taskName = tArgs[1]

if taskName == nil then
    print("You must specify a task")
    print("Usage: "..myName.." <task file>")
    return
end

-- Load the qTurtle object
dofile("qturtle.lua")

-- Instantiate the qTurtle object
local dean = qTurtle(myName, "turtle", "right")
-- Turn on debug messages on the console
dean.debugEnabled = true
-- Register with the server
dean.register()

-- Load the task object
dofile(taskName .. ".lua")
-- Instantiate the task object
local st = task(dean)
-- Run the task
st.run()
