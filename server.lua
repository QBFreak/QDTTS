-- clara.lua v1.0 - Clara Oswold - The impossible girl
--	Quick and Dirty Turtle Task System - Server

rednet.open("top")

local myName = "Clara"

function addTurtle(tID, tName, tType)
	if tID == nil then
		return false
	end
	local turtleData = {}
	turtleData.name = tName
	turtleData.status = "idle"
	turtleData.priority = 0
	turtleData.type = tType
	turtles[tID] = turtleData
	return true
end

function addTask(tName, tPriority, tType, tFile)
	if tName == nil then
		return false
	end
	local taskData = {}
	taskData.name = tName
	taskData.priority = tPriority
	taskData.type = tType
	taskData.file = tFile
	taskData.status = "pending"
	
	-- Check and see if we have any of the appropriate turtles free
	local turtleID = getAvailableTurtle(taskData)
	if turtleID ~= nil then
		assignTask(turtles[turtleID], taskData)
	end

	tID = table.getn(tasks) + 1
	tasks[tID] = taskData

	return true
end

-- Finds the next available turtle to take <task>
--	Returns index of turtle if a turtle is found
--	Returns nil if no turtle is available
function getAvailableTurtle(task)
	if task == nil then
		return nil
	end
	
	-- See if any turtles are idle
	for tID,tData in pairs(turtles) do
		if tData.status == "idle" then
			return tID
		end
	end
	
	-- Looks like we couldn't find any free turtles
	return nil
end

-- Assign a task to a turtle
--	<turtle> and <task> are tables out of their respective turtle and task tables
function assignTask(turtle, task)
	-- If the turtle was busy, mark the current task incomplete
	if turtle.status ~= idle then
		turtle.task = "incomplete"
	end
	
	-- Assign the turtle the new task
	turtle.task = task
	turtle.status = "assigned"
	turtle.priority = task.priority
	
	-- Update the task
	task.turtle = turtle
	task.status = "assigned"
	
	-- Transmit the assignment
	rednet.broadcast("ASSIGN "..myName.." ".. turtle.name .." ".. task.file)
end

turtles = {}
tasks = {}

print("Server '"..myName.."' started.")
rednet.broadcast("SERVER "..myName)

local running = true
while running do
	id,msg = rednet.receive("QDTTS")
	
	message = {}
	count = 0
	for i in string.gmatch(msg, "%S+") do
	  count = count + 1
	  message[count] = i
	end
	
	--print("RX("..count.."): "..msg)
	
	if count > 1 then
		command = message[1]
		turtleName = message[2]
		
		--if command == nil then print("ERR: command is nil!") end
		--if turtleName == nil then print("ERR: turtleName is nil!") end
		
		--print("CMD: "..turtleName..": "..command)

		-- Turtle Registration
		if command == "HELLO" then
			local turtleType = message[3]
			print("Greeting "..turtleName)
			rednet.broadcast("SERVER "..myName, "QDTTS")
			if addTurtle(id, turtleName, turtleType) then
				print("Registered new "..turtleType..", "..turtleName..", ID "..id)
			else
				print("Registration error. Type: "..turtleType.." Name: "..turtleName.." ID: "..id)
			end
		end
		
		-- Turtle Status

		-- Console commands --
		-- Shutdown the server
		if command == "SHUTDOWN" then
			print("Console "..turtleName.." requested a shutdown")
			rednet.broadcast("GOODBYE "..myName, "QDTTS")
			running = false
		end
		-- Query a Turtle's status
		if command == "QUERY" then
			local queriedTurtle = message[3] + 0 -- Add zero to convert our string to a number
			
			print("Console "..turtleName.." requested status of turtle "..queriedTurtle..".")
			local turtleData = turtles[queriedTurtle]
			
			print(type(queriedTurtle))
			print("--- Turtles ---")
			for i,t in pairs(turtles) do
				print(i,t)
			end
			
			local queryResponse = queriedTurtle .. " "
			queryResponse = queryResponse .. turtleData.name .. " "
			queryResponse = queryResponse .. turtleData.status .. " "
			queryResponse = queryResponse .. turtleData.priority .. " "
			queryResponse = queryResponse .. turtleData.type
			rednet.broadcast("QUERYR "..myName.." "..queryResponse, "QDTTS")
		end
		
		-- Add a task to the task queue
		if command == "ADDTASK" then
			if message[3] == nil or message[4] == nil or message[5] == nil or message[6] == nil then
				print("Malformed ADDTASK packet received from "..id..": "..msg)
			else
				local tName = message[3]
				local tPriority = message[4]
				local tType = message[5]
				local tFile = message[6]
				print("Console "..turtleName.." added task "..tName.." ("..tFile..")")								
				addTask(tName, tPriority, tType, tFile)
			end
		end
	else
		print("Malformed packet received from "..id..": "..msg)
	end
end
print("Server '"..myName.."' stopped.")
