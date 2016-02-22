-- everly.lua v1.0 - Everly
--	Quick and Dirty Turtle Task System - Control console

local tArgs = { ... }
myName = "Everly"

function displayHelp()
	print("QDTTS Control Console")
	print("Usage: "..string.lower(myName).." <command>")
	displayValidCommands()
end

function displayValidCommands()
	print("Valid commands: shutdown")
end

if table.getn(tArgs) == 0 then
	displayHelp()
	return
end

if tArgs[1] ~= "shutdown" then
	print("Invalid command")
	displayValidCommands()
	return
end

rednet.open("top")
rednet.broadcast("SHUTDOWN "..myName)
print("Shutdown command sent")

