-- clara.lua v1.0 - Clara Oswold - The impossible girl
--  Quick and Dirty Turtle Task System - Server

rednet.open("top")

local myName = "Clara"

function findTurtle(fTurtle)
  local tID = nil
  -- Determine whether fTurtle is a name or a number
  if string.find(fTurtle, "[^%d]") then
    -- Name, we need to look up the index number
    for i,t in pairs(turtles) do
      --print(t.name,t.name==fTurtle)
      if string.lower(t.name) == string.lower(fTurtle) then
        tID = i
      end
    end
  else
    -- Number, however it's likely a string. We need to convert it to a number
    tID = fTurtle + 0
  end
  if tID == nil then
    return nil
  end
  return turtles[tID]
end

function addTurtle(tID, tName, tType)
  if tID == nil then
    return false
  end
  local turtleData = {}
  turtleData.name = tName
  turtleData.status = "idle"
  turtleData.priority = 0
  turtleData.type = tType
  turtleData.rednet = tID
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
--  Returns index of turtle if a turtle is found
--  Returns nil if no turtle is available
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
--  <turtle> and <task> are tables out of their respective turtle and task tables
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
    
    -- Turtle Status --
    -- Turtle out of fuel
    if command == "NOFUEL" then
      print(turtleName.." is out of fuel")
      local turtleData = findTurtle(turtleName)
      turtleData.nofuel = true
    end
    
    -- Previously out of fuel turtle has been refueled
    if command == "FUEL" then
      print(turtleName.." has been refueled")
      local turtleData = findTurtle(turtleName)
      turtleData.nofuel = false
    end

    -- Console commands --
    -- Shutdown the server
    if command == "SHUTDOWN" then
      print("Console "..turtleName.." requested a shutdown")
      rednet.broadcast("GOODBYE "..myName, "QDTTS")
      running = false
    end
    -- Query a Turtle's status
    if command == "QUERY" then
      local queriedTurtle = message[3]
      local tID = nil
      
      print("Console "..turtleName.." requested status of turtle "..queriedTurtle)

      local turtleData = findTurtle(queriedTurtle)
      if turtleData == nil then
        rednet.broadcast("QUERYR "..myName.." "..queriedTurtle.." NOTFOUND", "QDTTS")
      else
        local queryResponse = turtleData.rednet .. " "
        queryResponse = queryResponse .. turtleData.name .. " "
        queryResponse = queryResponse .. turtleData.status .. " "
        queryResponse = queryResponse .. turtleData.priority .. " "
        queryResponse = queryResponse .. turtleData.type .. " "
        if turtleData.nofuel == nil then
          queryResponse = queryResponse .. "UNK"
        end
        if turtleData.nofuel == true then
          queryResponse = queryResponse .. "NOFUEL"
        end
        if turtleData.nofuel == false then
          queryResponse = queryResponse .. "FUEL"
        end
        rednet.broadcast("QUERYR "..myName.." "..queryResponse, "QDTTS")
      end
    end
    
    -- List turtles
    if command == "LISTTURTLES" then
      print("Console "..turtleName.." requested a list of all turtles")
      rednet.broadcast("LISTTURTLESR "..myName.." BEGINLIST", "QDTTS")
      for index,turtle in pairs(turtles) do
        local listResponse = "LISTTURTLESR "..myName.." LIST "
        listResponse = listResponse.. index .." "
        listResponse = listResponse.. turtle.name .." "
        listResponse = listResponse.. turtle.status .." "
        listResponse = listResponse.. turtle.priority .." "
        listResponse = listResponse.. turtle.type .." "
        if turtle.task == nil then
          listResponse = listResponse.." NO"
        else
          listResponse = listResponse.." YES"
        end
        rednet.broadcast(listResponse, "QDTTS")
      end
      rednet.broadcast("LISTTURTLESR "..myName.." ENDLIST", "QDTTS")
    end
    
    -- List tasks
    if command == "LISTTASKS" then
      print("Console "..turtleName.." requested a list of all tasks")
      rednet.broadcast("LISTTASKSR "..myName.." BEGINLIST", "QDTTS")
      for index,task in pairs(tasks) do
        local listResponse = "LISTTASKSR "..myName.." LIST "
        listResponse = listResponse.. index .." "
        listResponse = listResponse.. task.name .." "
        listResponse = listResponse.. task.priority .." "
        listResponse = listResponse.. task.type .." "
        listResponse = listResponse.. task.file .." "
        listResponse = listResponse.. task.status .." "
        if task.turtle == nil then
          listResponse = listResponse.." NO"
        else
          listResponse = listResponse.." YES"
        end
        rednet.broadcast(listResponse, "QDTTS")
      end
      rednet.broadcast("LISTTASKSR "..myName.." ENDLIST", "QDTTS")
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
