-- clara.lua v1.0 - Clara Oswold - The impossible girl
--	Quick and Dirty Turtle Task System - Server

rednet.open("top")

local myName = "Clara"

function addTurtle(tName)
	if tName == nil then
		return
	end
	turtles[tables.getn(turtles)] = tName
end

print("Server '"..myName.."' started.")
rednet.broadcast("SERVER "..myName)

turtles = {}

local running = true
while running do
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
		rednet.broadcast("SERVER "..myName)
		addTurtle(turtleName)
	end
	if command == "SHUTDOWN" then
		print("Console "..turtleName.." requested a shutdown")
		rednet.broadcast("GOODBYE "..myName)
		running = false
	end
end
print("Server '"..myName.."' stopped.")
