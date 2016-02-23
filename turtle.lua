-- dean.lua v1.0 - Dean Winchester - He's been to hell and back. Litterally.
--	Quick and Dirty Turtle Task System - Client

myName = "Dean"

rednet.open("left")

local tries = 0
local success = false
while tries < 6 and success == false do
	print("Searching for server")
	rednet.broadcast("HELLO Dean Turtle", "QDTTS")
	id,msg = rednet.receive("QDTTS", 5)
	tries = tries + 1
	
	message = {}
	count = 0
	if msg ~= nil then
		for i in string.gmatch(msg, "%S+") do
			count = count + 1
			message[count] = i
		end

		if count > 1 then
			command = message[1]

			if command == "SERVER" then
				if message[2] == nil then
					print("Malformed SERVER packet received: "..msg)
				else
					print("Registered with server ".. message[2])
					success = true
				end
			end
		end
	end
end

if success == false then
	print("No response from server!")
end