-- clara.lua v1.0 - Clara Oswold - The impossible girl
--  Quick and Dirty Turtle Task System - Server

rednet.open("top")

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

function addLoc(lName, lX, lY, lZ)
    if lName == nil then
        return false
    end
    local locData = {}
    locData.name = lName
    locData.x = lX
    locData.y = lY
    locData.z = lZ
    -- Store the location by NAME
    locations[lName] = locData
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

-- Retrieve a location from the location table by name, or nil if not found
function getLoc(lName)
    return locations[lName]
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

-- Initialize the server
function load()
    print("Server '"..myName.."' starting.")
    print("Loading locations from database")
    locFile = fs.open(".locations.tab", "r")
    if locFile == nil then
        print("No location database found. First run?")
    else
        local line = locFile.readLine()
        local tblTmp = {}
        local count = 0
        while line ~= nil do
            -- print("# "..line)
            tblTmp = {}
            count = 0
            for i in string.gmatch(line, "%S+") do
                tblTmp[count] = i
                count = count + 1
            end
            if count == 4 then
                local tblLoc = {}
                tblLoc.name = tblTmp[0]
                tblLoc.x = tblTmp[1]
                tblLoc.y = tblTmp[2]
                tblLoc.z = tblTmp[3]
                print("- "..tblLoc.name.." "..tblLoc.x.." "..tblLoc.y.." "..tblLoc.z)
                locations[tblLoc.name] = tblLoc
            else
                print("ERROR: Bad location in database:")
                print(line)
            end
            line = locFile.readLine()
        end
        locFile.close()
    end
    print(#locations.." locations loaded")

    -- Announce server started
    rednet.broadcast("SERVER "..myName, protocol)
    print("Server started.")
end

-- Prepare the server to shutdown
function shutdown()
    -- Announce we are no longer available
    rednet.broadcast("GOODBYE "..myName, protocol)
    print("Console "..turtleName.." requested a shutdown")

    print("Writing locations to database")
    locFile = fs.open(".locations.tab", "w")
    if locFile == nil then
        print("Error writing to database, locations lost!")
    else
        for index,locData in pairs(locations) do
            locFile.writeLine(locData.name .. " " .. locData.x .. " " .. locData.y .. " " .. locData.z)
        end
        locFile.close()
    end
    print(#locations.." locations saved")
    rednet.close()
    print("Shutting down.")
end

-- Init globals
turtles = {}
tasks = {}
locations = {}

-- Constants
label = os.getComputerLabel()
compid = "server" .. math.floor(math.random() * 100)
myName = label or compid
protocol = "QDTTS"

-- Init the server
load()

-- Start the server
local running = true
while running do
  id,msg = rednet.receive(protocol)

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

    -- Server alive?
    if command == "PING" then
        print("Ping from " .. turtleName)
        rednet.broadcast("PONG " .. myName, protocol)
    end

    -- Turtle Registration
    if command == "HELLO" then
      local turtleType = message[3]
      print("Greeting "..turtleName)
      rednet.broadcast("SERVER "..myName, protocol)
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
        shutdown()
        running = false
    end

    if command == "RESTART" then
        shutdown()
        running = false
        print("Restarting...")
        shell.run("reboot")
    end

    -- Query a Turtle's status
    if command == "QUERY" then
      local queriedTurtle = message[3]
      local tID = nil

      print("Console "..turtleName.." requested status of turtle "..queriedTurtle)

      local turtleData = findTurtle(queriedTurtle)
      if turtleData == nil then
        local queryData = {}
        queryData.serverName = myName
        queryData.messageType = "Query Response"
        queryData.requestSuccess = false
        queryData.name = queriedTurtle
        rednet.send(id, queryData, protocol)
      else
        local queryData = {}
        queryData.serverName = myName
        queryData.messageType = "Query Response"
        queryData.requestSuccess = true
        queryData.rednet = turtleData.rednet
        queryData.name = turtleData.name
        queryData.status = turtleData.status
        queryData.priority = turtleData.priority
        queryData.type = turtleData.type
        queryData.nofuel = turtleData.nofuel
        rednet.send(id, queryData, protocol)
      end
    end

    -- List turtles
    if command == "LISTTURTLES" then
      print("Console "..turtleName.." requested a list of all turtles")
      rednet.broadcast("LISTTURTLESR "..myName.." BEGINLIST", protocol)
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
        rednet.broadcast(listResponse, protocol)
      end
      rednet.broadcast("LISTTURTLESR "..myName.." ENDLIST", protocol)
    end

    -- List tasks
    if command == "LISTTASKS" then
      print("Console "..turtleName.." requested a list of all tasks")
      rednet.broadcast("LISTTASKSR "..myName.." BEGINLIST", protocol)
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
        rednet.broadcast(listResponse, protocol)
      end
      rednet.broadcast("LISTTASKSR "..myName.." ENDLIST", protocol)
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

    -- Store a location: SAVELOC sender locName X Y Z
    if command == "SAVELOC" then
        if message[3] == nil or message[4] == nil or message[5] == nil or message[6] == nil then
            print("Malformed SAVELOC packet received from "..id..": "..msg)
        else
            local lName = message[3]
            local lX = message[4]
            local lY = message[5]
            local lZ = message[6]
            print("Console "..turtleName.." added location "..lName.."("..lX..","..lY..","..lZ..")")
            addLoc(lName, lX, lY, lZ)
        end
    end

    -- Retrieve a location
    if command == "GETLOC" then
        if message[3] == nil then
            print("Malformed GETLOC packet received from "..id..": "..msg)
        else
            local lName = message[3]
            print(turtleName.." requested location "..lName)
            local tblLoc = getLoc(lName)
            if tblLoc == nil then
                -- Location not in database
                rednet.broadcast("BADLOC "..myName.." "..lName, protocol)
                print("Response: BADLOC")
            else
                -- Return location
                local sLoc = tblLoc.name .. " " .. tblLoc.x .. " " .. tblLoc.y .. " " .. tblLoc.z
                rednet.broadcast("LOC "..myName.." "..sLoc, protocol)
                print("Response: LOC "..sLoc)
            end
        end
    end
  else
    print("Malformed packet received from "..id..": "..msg)
  end
end
print("Server '"..myName.."' stopped.")
