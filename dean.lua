-- dean.lua v1.0 - Dean Winchester - He's been to hell and back. Litterally.
--  Quick and Dirty Turtle Task System - Client

dofile("qturtle.lua")

local dean = qTurtle("Dean", "turtle", "right")
dean.debugEnabled = true
dean.register()

-- print("I'm leaving.")
--
-- while not turtle.inspect() do
--   dean.forward()
-- end
--
-- print("Oh no! A thing! Run away!")
--
-- dean.turnRight()
-- dean.turnRight()
--
-- while not turtle.inspect() do
--   dean.forward()
-- end
--
-- print("Whew, that was scary")

dean.queryTask()
