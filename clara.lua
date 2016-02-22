-- clara.lua v1.0 - Clara Oswold - The impossible girl
--	Quick and Dirty Turtle Task System - Server

rednet.open("top")

serverName = "Clara"

print("Starting loop, CTRL+T to terminate")
while true do
	id,msg = rednet.receive()
	
	message = {}
	count = 1
	for i in string.gmatch(msg, "%S+") do
	  message[count] = i
	  count = count + 1
	end
	
	command = message[1]
	turtleName = message[2]
	
	if command == "HELLO" then
		print("Greeting new Turtle " .. turtleName)
		rednet.broadcast("SERVER "..serverName)
	end
end
