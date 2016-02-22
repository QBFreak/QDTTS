-- everly.lua v1.0 - Everly
--	Quick and Dirty Turtle Task System - Control console

local tArgs = { ... }
myName = "Everly"

validCommands = {"shutdown", "query"}

function displayHelp()
	print("QDTTS Control Console")
	print("Usage: "..string.lower(myName).." <command>")
	displayValidCommands()
end

function displayValidCommands()
	local validCmdString = ""
	for i,cmd in ipairs(validCommands) do
		validCmdString = validCmdString.." "..cmd
	end
	print("Valid commands:"..validCmdString)
end

if table.getn(tArgs) == 0 then
	displayHelp()
	return
end

validCommand = false
for i,cmd in ipairs(validCommands) do
	if tArgs[1] == cmd then
		validCommand = true
	end
end

if validCommand == false then
	print("Invalid command")
	displayValidCommands()
	return
end

local command = tArgs[1]
rednet.open("top")

-- Shutdown the Turtle server
if command == "shutdown" then
	rednet.broadcast("SHUTDOWN "..myName, "QDTTS")
	print("Shutdown command sent")
end

-- Query a Turtle's status
if command == "query" then
	queryID = tArgs[2]
	if queryID == nil then
		print("Usage: "..string.lower(myName).." query <number>")
		print("  Number corresponds to the RedNet node number of the turtle you wish to query")
	else
		rednet.broadcast("QUERY "..myName.." "..queryID, "QDTTS")
		local command = nil
		local ctr = 0
		while (command ~= "QUERYR") and (ctr < 5) do
			ctr = ctr + 1
			id,msg = rednet.receive("QDTTS", 2)

			if msg ~= nil then
				message = {}
				count = 1
				for i in string.gmatch(msg, "%S+") do
					message[count] = i
					count = count + 1
				end
				if table.getn(message) > 0 then
					command = message[1]
				end
			end
		end

		if command == nil then
			print("Request timed out")
		else
			if table.getn(message) < 7 then
				print("Error: Malformed query response")
			end
			local server = message[2]
			local rID = message[3]
			local rName = message[4]
			local rStatus = message[5]
			local rPriority = message[6]
			local rType = message[7]
			print("------ " .. rName .. "------")
			print("RedNet ID:  " .. rID)
			print("Type:       " .. rType)
			print("Status:     " .. rStatus)
			print("Priority:   " .. rPriority)
		end
	end
end