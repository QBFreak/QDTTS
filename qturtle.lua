-- turtle.lua v1.0 - Turtle object
--  Quick and Dirty Turtle Task System


function qTurtle(initName, initType, initSide)
  -- the new instance
  local self = {
    -- public fields go in the instance table
    fuelSlots = {16},
    minimumFuelLevel = 1
  }

  -- private fields are implemented using locals
  -- they are faster than table access, and are truly private, so the code that uses your class can't get them
  local selfValid = true
  local name = initName
  local side = initSide
  local type = initType
  
  if initName == "" then
    selfValid = false
  end
  
  local validTypes = {"turtle", "mining", "felling", "melee", "digging", "farming", "crafty"}
  local validType = false
  for i,typ in ipairs(validTypes) do
    if type == typ then
      validType = true
    end
  end
  if validType == false then
    selfValid = false
  end
  
  if peripheral.getType(side) ~= "modem" then
    selfValid = false
  end
  
  function self.register()
    rednet.open(side)
    
    local tries = 0
    local success = false
    while tries < 6 and success == false do
      print("Searching for server")
      rednet.broadcast("HELLO ".. name .." ".. type, "QDTTS")
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
    
    return
  end
  
  function self.checkFuel()
    local slot = turtle.getSelectedSlot()
    local fSuccess = false
    for i,fSlot in ipairs(self.fuelSlots) do
      
      print("Checking for fuel in slot "..fSlot)
      
      turtle.select(fSlot)
      if turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < self.minimumFuelLevel then
        if turtle.refuel(1) then
          print("Refueled from slot "..fSlot)
          fSuccess = true
        end
      else
        fSuccess = true
      end
    end
    turtle.select(slot)
    if fSuccess == false then
      print("Unable to refuel!")
      -- TODO Notify server that turtle is out of fuel
    end
    return fSuccess
  end
  
  function self.forward()
    self.checkFuel()
    print("Moving forward")
    return turtle.forward()
  end
  
  if selfValid then
    -- return the instance
    return self
  else
    return nil
  end
end
