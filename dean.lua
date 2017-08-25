-- dean.lua v1.0 - Dean Winchester - He's been to hell and back. Litterally.
--  Quick and Dirty Turtle Task System - Client

local tArgs = { ... }

dofile("qturtle.lua")

local dean = qTurtle("Dean", "turtle", "right")
dean.debugEnabled = true
dean.register()

local taskName = tArgs[1] or "survey"

-- Run the survey code
dofile(taskName .. ".lua")
local st = task(dean)
st.run()
