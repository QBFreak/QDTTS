-- everly.lua v1.0 - Everly
--  Quick and Dirty Turtle Task System - Control console

local tArgs = { ... }

validCommands = {"ping", "addtask", "list", "query", "shutdown", "restart", "getloc", "saveloc", "sendraw"}

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

label = os.getComputerLabel()
compid = "client" .. math.floor(math.random() * 100)
myName = label or compid

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
    print("Usage: client query <turtle>")
    print("  Name or RedNet node number of the turtle you wish to query")
  else
    rednet.broadcast("QUERY "..myName.." "..queryID, "QDTTS")
    local isResponse = false
    local ctr = 0
    while (isResponse == false) and (ctr < 5) do
      ctr = ctr + 1
      id,msg = rednet.receive("QDTTS", 2)

      if type(msg) == "table" then
        if msg.messageType == "Query Response" then
          isResponse = true
        end
      end
    end

    if isResponse == false then
      print("Request timed out")
    else
      local server = msg.serverName
      local rName = msg.name
      if msg.requestSuccess == false then
        print(server .." was unable to locate a turtle named '".. rName .."'")
      else
        local rID = msg.rednet
        local rStatus = msg.status
        local rPriority = msg.priority
        local rType = msg.type
        local rFuel = "Unknown"
        if msg.nofuel == false then
          rFuel = "OK"
        end
        if msg.nofuel == true then
          rFuel = "None"
        end
        print("------ " .. rName .. " ------")
        print("RedNet ID:  " .. rID)
        print("Type:       " .. rType)
        print("Status:     " .. rStatus)
        print("Priority:   " .. rPriority)
        print("Fuel:       " .. rFuel)
      end
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
  tPriority = tonumber(tArgs[3])
  tType = tArgs[4]
  tFile = tArgs[5]

  if not type(tPriority) == "number" then
    print("The priority must be a number between 0 and 5 (inclusive)")
    return
  end

  if tPriority < 0 or tPriority > 5 then
    print("The priority must be a number between 0 and 5 (inclusive)")
    return
  end

  validTypes = {"turtle", "mining", "felling", "melee", "digging", "farming", "crafty"}
  validType = false
  for i,typ in ipairs(validTypes) do
    if tType == typ then
      validType = true
    end
  end

  if validType == false then
  print("Invalid turtle type.")
    local validTypesString = ""
    for i,typ in ipairs(validTypes) do
      validTypesString = validTypesString.." "..typ
    end
    print("Valid types:"..validTypesString)
    return
  end

  rednet.broadcast("ADDTASK "..myName.." "..tName.." "..tPriority.." "..tType.." "..tFile, "QDTTS")
  print("Added task "..tName)
end

-- List turtles and tasks
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

-- Send a raw command over rednet
if command == "sendraw" then
    local rawcmd = table.concat(tArgs, " ", 2)
    rednet.broadcast(rawcmd, "QDTTS")
    print("Raw command sent:")
    print(rawcmd)
    local sndr, msg, proto = rednet.receive("QDTTS", 5)
    if sndr == nil then
        print("No response.")
    else
        print(sndr .. ": " .. msg)
    end
end

-- Ping the server to see if it's up
if command == "ping" then
    rednet.broadcast("PING "..myName, "QDTTS")
    print("Ping sent to server")
    local sndr, msg, proto = rednet.receive("QDTTS", 5)
    if sndr == nil then
        print("No response")
    else
        print(msg)
    end
end

-- Request a location from the server
if command == "getloc" then
    locName = tArgs[2]
    if locName == nil then
        print("Usage: client getloc <name>")
        return
    end
    rednet.broadcast("GETLOC "..myName.." "..locName, "QDTTS")
    local sndr, msg, proto = rednet.receive("QDTTS", 5)
    if sndr == nil then
        print("No answer from server")
        return
    else
        print(msg)
    end
end

if command == "saveloc" then
    -- Get the params
    local locName = tArgs[2]
    local x = tArgs[3]
    local y = tArgs[4]
    local z = tArgs[5]
    -- Make sure they're all good
    if locName == nil then
        print("You must specify a location name")
    end
    if x == nil or y == nil or z == nil then
        print("You must specify a location")
    end
    if locName == nil or x == nil or y == nil or z == nil then
        print("Usage: client saveloc <name> <x> <y> <z>")
        return
    end
    rednet.broadcast("SAVELOC "..myName.." "..locName.." "..x.." ".." "..y.." "..z, "QDTTS")
    print("Location sent to server")
end

-- Restart the server
if command == "restart" then
    rednet.broadcast("RESTART "..myName, "QDTTS")
    print("Restart request sent to server")
    local sndr, msg, proto = rednet.receive("QDTTS", 5)
    if sndr == nil then
        print("No response")
    else
        print(msg)
    end
end

rednet.close()
