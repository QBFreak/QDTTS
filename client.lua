-- everly.lua v1.0 - Everly
--	Quick and Dirty Turtle Task System - Control console

local tArgs = { ... }
myName = "Everly"

validCommands = {"addtask", "list", "query", "shutdown"}

function displayHelp()
	print("QDTTS Control Console")
	print("Usage: client <command>")
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
		print("Usage: client query <number>")
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

-- Add a task
if command == "addtask" then
	if tArgs[5] == nil then
		print("Usage: client addtask <name> <priority> <type> <file>")
		print("Example: client addtask foo normal turtle foo")
		return
	end
	
	tName = tArgs[2]
	tPriority = tArgs[3]
	tType = tArgs[4]
	tFile = tArgs[5]
	
	rednet.broadcast("ADDTASK "..myName.." "..tName.." "..tPriority.." "..tType.." "..tFile, "QDTTS")
	print("Added task "..tName)
end

if command == "list" then
	if tArgs[2] ~= "turtles" and tArgs[2] ~= "tasks" then
		print("Usage: client list <tasks|turtles>")
		print("Example: client list turtles")
	else
		timeouts = 0
		started = false
		completed = false
		while timeouts < 5 and completed == false do
			if started == false then
				print("Requesting ".. tArgs[2] .." from server")
				rednet.broadcast("LIST"..string.upper(tArgs[2].." "..myName), "QDTTS")
			end
			id,msg = rednet.receive("QDTTS", 5)
			if id == nil then
				timeouts = timeouts + 1
			end
			
			message = {}
			count = 0
			if msg ~= nil then
				for i in string.gmatch(msg, "%S+") do
					count = count + 1
					message[count] = i
				end
				
				if count > 1 then
					local command = message[1]
					
					if command == "LISTTURTLESR" or command == "LISTTASKSR" then
						if message[3] ~= "BEGINLIST" and message[3] ~= "LIST" and message[3] ~= "ENDLIST" then
							print("Malformed list packet received: "..msg)
						else
							if message[3] == "BEGINLIST" then
								print("Begin list from server ".. message[2])
								started = true
							end
							if message[3] == "ENDLIST" then							
								print("End of list from server ".. message[2])
								completed = true
							end
							if message[3] == "LIST" then
								if command == "LISTTURTLESR" then
									if message[9] == nil then
										print("Malformed list response: "..msg)
									else
										print(message[4], message[5], message[6], message[7], message[8], message[9])
									end
								end
								if command == "LISTTASKSR" then
									if message[9] == nil then
										print("Malformed list response: "..msg)
									else
										print(message[4], message[5], message[6], message[7], message[8], message[9], message[10])
									end
								end
							end
						end
					end
				end
			end
		end
		
		if completed == false then
			print("No response from server!")
		end
	end
end