-- dean.lua v1.0 - Dean Winchester - He's been to hell and back. Litterally.
--	Quick and Dirty Turtle Task System - Client

myName = "Dean"

rednet.open("left")
rednet.broadcast("HELLO Dean Turtle", "QDTTS")

id,msg = rednet.receive(5)
if id then
	print("Response from server!")
else
	print("No response from server")
end
