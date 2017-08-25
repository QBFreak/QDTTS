-- turtle.lua v1.0 - Turtle object
--  Quick and Dirty Turtle Task System


function qTurtle(initName, initType, initSide)
  -- the new instance
  local self = {
    -- public fields go in the instance table
    fuelSlots = {16},
    minimumFuelLevel = 1,
    debugEnabled = false,
  }

  -- private fields are implemented using locals
  -- they are faster than table access, and are truly private, so the code that uses your class can't get them
  local selfValid = true
  local name = initName
  local side = initSide
  local type = initType
  local serverNotifiedNoFuel = false
  -- Which way is the turtle facing?
  local facing = nil    -- Unknown
  -- Block detection
  local blkFront = nil
  local blkUp = nil
  local blkDown = nil

  if initName == "" then
      self.debug("initName is blank!")
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
      self.debug("validType is false")
    selfValid = false
  end

  if peripheral.getType(side) ~= "modem" then
      self.debug("Side peripheral is not a modem!")
    selfValid = false
  end

  function self.name()
      return name
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

  function self.North()
      return 1
  end

  function self.South()
      return 2
  end

  function self.East()
      return 3
  end

  function self.West()
      return 4
  end

  -- Initialize the turtle
  function self.init()
      -- Check that we have a GPS fix
      x, y, z = gps.locate(5)
      if x == nil then
          self.debug("Failed to get GPS position")
          return false
      end

      -- Orient the turtle
      if facing == nil then
          if self.orient() == false then
              self.debug("Failed to orient turtle")
              return false
          end
      end

      -- Init block detection
      blkFront = turtle.detect()
      blkUp = turtle.detectUp()
      blkDown = turtle.detectDown()

      return true
  end

  -- Tasks to run before moving
  function self.preMove()
    self.checkFuel()
    -- What's in the way?
    blkFront = turtle.detect()
    blkUp = turtle.detectUp()
    blkDown = turtle.detectDown()
  end

  -- Tasks to run after moving
  function self.postMove()
      -- What's around us now?
      blkFront = turtle.detect()
      blkUp = turtle.detectUp()
      blkDown = turtle.detectDown()
    -- Mapping will go here
  end

    function self.checkFuel()
        -- Store the currently selected slot so we can come back to it
        local slot = turtle.getSelectedSlot()
        local fSuccess = false
        if turtle.getFuelLevel() == "unlimited" then
            -- No fuel necessary
            return true
        end
        if turtle.getFuelLevel() >= self.minimumFuelLevel then
            -- We don't need fuel yet
            return true
        end

        -- Refuel until we have the minimum amount of fuel
        while turtle.getFuelLevel() < self.minimumFuelLevel do
            -- Check all of the slots designated for fuel
            for i,fSlot in ipairs(self.fuelSlots) do
                turtle.select(fSlot)
                -- Refuel one block from the current slot
                if turtle.refuel(1) then
                    print("Refueled from slot "..fSlot)
                    -- Does the server think we're out of fuel?
                    if serverNotifiedNoFuel then
                        -- Tell it otherwise
                        serverNotifiedNoFuel = false
                        rednet.broadcast("FUEL ".. name, "QDTTS")
                    end
                    -- Success fueling
                    fSuccess = true
                end
            end
        end
        -- Select the originally selected slot
        turtle.select(slot)
        -- If we failed to fuel and we haven't told the server we're out yet...
        if fSuccess == false and serverNotifiedNoFuel == false then
            -- Make the announcement
            serverNotifiedNoFuel = true
            print("Out of fuel")
            rednet.broadcast("NOFUEL ".. name, "QDTTS")
        end
        -- Return the status from above
        return fSuccess
    end

  function self.forward()
    self.preMove()
    local ret = turtle.forward()
    self.postMove()
    return ret
  end

    -- Move forward, but climb up or down to stay at ground level
    -- TODO: check for blocks ABOVE before moving up
    function self.forwardClimb()
        if blkFront == false then
            -- Nothing in front of us, lets go forward
            if self.forward() == false then
                -- We failed to move, stuck
                return false
            end
        else
            -- Something is in the way! (in front of us)
            while blkFront and blkUp == false do
                if self.up() == false then
                    -- We failed to move, stuck
                    return false
                end
            end
            while blkFront and blkDown == false do
                if self.down() == false then
                    -- We failed to move, stuck
                    return false
                end
            end
            if blkFront then
                -- We've tried to go over, we've tried to go under
                --  we're stuck.
                return false
            end
            if self.forward() == false then
                -- We failed to move, stuck
                return false
            end
        end

        -- self.debug("XX Time to move down")
        while blkDown == false do
            -- self.debug("XX Down loop")
            if self.down() == false then
                -- self.debug("XX Moving down failed")
                -- We failed to move, stuck
                break
            end
        end

        return true
    end

    -- TODO: Add a maximum number of steps (a sort of timeout)
    function self.forwardUntil(blockType)
        if blockType == nil then
            return false
        end
        local s, d = turtle.inspectDown()
        while (d.name ~= blockType) do
            self.forwardClimb()
            s, d = turtle.inspectDown()
        end
        self.debug("Found "..blockType)
        return true
    end

    -- TODO: Add a maximum number of steps (a sort of timeout)
    function self.forwardWhile(blockType)
        if blockType == nil then
            return false
        end
        local s, d = turtle.inspectDown()
        while (d.name == blockType) do
            self.forwardClimb()
            s, d = turtle.inspectDown()
        end
        self.debug("Found end of "..blockType.."("..d.name..")")
        return true
    end

    function self.sink()
        local s, d = turtle.inspectDown()
        while s == false do
            if self.down() == false then
                self.debug("sink() failed to move down")
                return false
            end
            s, d = turtle.inspectDown()
        end
        self.debug("sink() stopped at "..d.name)
        return true
    end

    function self.rise()
        local s, d = turtle.inspectUp()
        while s == false do
            if self.up() == false then
                self.debug("rise() failed to move down")
                return false
            end
            s, d = turtle.inspectUp()
        end
        self.debug("rise() stopped at "..d.name)
        return true
    end

  function self.back()
    self.preMove()
    local ret = turtle.back()
    self.postMove()
    return ret
  end

  function self.up()
    self.preMove()
    local ret = turtle.up()
    self.postMove()
    return ret
  end

  function self.down()
    self.preMove()
    local ret = turtle.down()
    self.postMove()
    return ret
  end

  function self.turnLeft()
    self.preMove()
    local ret = turtle.turnLeft()
    -- Update which direction the turtle is facing
    if facing == self.North() then
        facing = self.West()
    elseif facing == self.East() then
        facing = self.North()
    elseif facing == self.South() then
        facing = self.East()
    elseif facing == self.West() then
        facing = self.South()
    end
    self.postMove()
    return ret
  end

  function self.turnRight()
    self.preMove()
    local ret = turtle.turnRight()
    -- Update which direction the turtle is facing
    if facing == self.North() then
        facing = self.East()
    elseif facing == self.East() then
        facing = self.South()
    elseif facing == self.South() then
        facing = self.West()
    elseif facing == self.West() then
        facing = self.North()
    end
    self.postMove()
    return ret
  end

  function self.queryTask()
      self.debug("Asking server for a task")
      rednet.broadcast("NEXTTASK " .. name, "QDTTS")
      local id, msg, proto = rednet.receive("QDTTS", 5)
      if msg == nil then
          self.debug("No task returned")
          return
      else
          self.debug("Task: " .. msg)
      end
  end

  function self.debug(str)
      if self.debugEnabled then
          print("DEBUG: " .. str)
      end
      rednet.broadcast(str, "DEBUG")
  end

  function self.saveLoc(locName)
      if locName == nil then
          self.debug("saveLoc() failed, no location name specified")
          return false
      end
      local x, y, z = gps.locate(5)
      if x == nil then
          self.debug("saveLoc() failed, no GPS fix available")
          return false
      else
          rednet.broadcast("SAVELOC "..name.." "..locName.." "..x.." "..y.." "..z, "QDTTS")
          return true
      end
  end

  function self.getLoc(locName)
      if locName == nil then
          self.debug("Location failed: No name specified")
          return nil
      end
      rednet.broadcast("GETLOC "..name.." "..locName, "QDTTS")
      local id, msg, proto = rednet.receive("QDTTS", 5)
      if id == nil then
          self.debug("Location failed: No answer to request")
          return nil
      end
      local tblTmp = {}
      local count = 0
      for i in string.gmatch(msg, "%S+") do
          tblTmp[count] = i
          count = count + 1
      end
      if count ~= 6 then
          if tblTmp[0] == "BADLOC" then
              self.debug("Location failed: Not in database")
          else
              self.debug("Location failed: Wrong answer length ("..count.."/6)")
          end
          return nil
      end
      local tblLoc = {}
      tblLoc.name = tblTmp[2]
      tblLoc.x = tblTmp[3]
      tblLoc.y = tblTmp[4]
      tblLoc.z = tblTmp[5]
      self.debug("Location success: "..tblLoc.name)
      return tblLoc
  end

    function self.navTo(x, y, z)
        -- x, y, z == Destination
        x = tonumber(x)
        y = tonumber(y)
        z = tonumber(z)
        while true do
            if turtle.getFuelLevel() == 0 then
                self.debug("Navigation failed, out of fuel")
                return false
            end
            if facing == nil then
                if self.orient() == false then
                    self.debug("Navigation failed, could not orient turtle")
                    return false
                end
            end
            -- Turtle location
            local tx, ty, tz = gps.locate(5)
            if tx == nil then
                -- Failed to get a GPS lock
                self.debug("Navigation failed, could not get GPS location")
                return false
            end
            -- Are we there yet?
            if tx == x and ty == y and tz == z then
                return true
            end
            -- Distance remaining
            dx = math.abs(x - tx)
            dy = math.abs(y - ty)
            dz = math.abs(z - tz)

            -- self.debug("---------------")
            -- self.debug("DEST "..x.." "..y.." "..z)
            -- self.debug("CURR "..tx.." "..ty.." "..tz)
            -- self.debug("DIFF "..dx.." "..dy.." "..dz)

            if dx > dz or (dx > 0 and dx == dz) then
                self.debug("Step towards X")
                -- Step towards X
                if tx > x then
                    -- Step towards X==0
                    self.face(self.West())
                    self.debug("Face: West")
                else
                    -- Step away from X==0
                    self.face(self.East())
                    self.debug("Face: East")
                end
                self.forwardClimb()
            elseif dz > dx then
                self.debug("Step towards Z")
                -- Step towards Z
                if tz > z then
                    -- Step towards Z==0
                    self.face(self.North())
                    self.debug("Face: North")
                else
                    -- Step away from Z==0
                    self.face(self.South())
                    self.debug("Face: South")
                end
                self.forwardClimb()
            -- elseif dy >= dx and dy >= dz then
            else
                self.debug("Step towards Y")
                self.debug("err, kinda")
                -- Step towards Y
                -- How to we resolve moving towards Y and moving above/below terrain?
                if ty > y then
                    self.down()
                elseif ty < y then
                    self.up()
                end
            end
        end
    end

  function self.navToName(locName)
      tblLoc = self.getLoc(locName)
      if tblLoc == nil then
          return false
      else
          return self.navTo(tblLoc.x, tblLoc.y, tblLoc.z)
      end
  end

  function self.orient()
      -- Attempt to determine which direction we're facing based on a single step
      local x1, y1, z1 = gps.locate(5)
      if x1 == nil then
          -- Failed to get a GPS lock
          return false
      end

      -- MOVE IN ANY X/Z DIRECTION
      local rot = 0
      if turtle.detect() then
          -- We're blocked, start the dance
          while rot < 5 and turtle.detect() do
              self.turnRight()
              rot = rot + 1
          end
          if rot == 4 then
              -- We need to go up or down
              self.debug("HEY, IDIOT, YOU FORGOT TO CODE THIS")
              return false
          else
              -- Woo, we found a direction, lets move and then reset
              self.forward()
          end
      else
          self.forward()
      end

      local x2, y2, z2 = gps.locate(5)
      if x2 == nil then
          -- Failed to get a GPS lock, should never happen if x1 is OK
          return false
      end
      facing = nil
      if x2 > x1 then
          facing = self.East()
      elseif x1 > x2 then
          facing = self.West()
      elseif z2 > z1 then
          facing = self.South()
      elseif z1 > z2 then
          facing = self.North()
      end
      if facing == nil then
          self.debug("orient() facing: nil!")
      end
      -- Move back to where we started
      self.back()
      while rot > 0 do
          self.turnLeft()
          rot = rot - 1
      end
      return true
  end

  function self.face(direction)
      if direction ~= self.North() and direction ~= self.South() and direction ~= self.East() and direction ~= self.West() then
          return false
      end
      if facing == nil then
          if self.orient() == false then
              return false
          end
      end

      if facing == self.North() and direction == self.West() then
          self.turnLeft()
      elseif facing == self.North() and direction == self.East() then
          self.turnRight()
      elseif facing == self.East() and direction == self.North() then
          self.turnLeft()
      elseif facing == self.East() and direction == self.South() then
          self.turnRight()
      elseif facing == self.South() and direction == self.East() then
          self.turnLeft()
      elseif facing == self.South() and direction == self.West() then
          self.turnRight()
      elseif facing == self.West() and direction == self.North() then
          self.turnRight()
      elseif facing == self.West() and direction == self.South() then
          self.turnLeft()
      else
          while facing ~= direction do
              self.turnRight()
          end
      end
      return true
  end

  if selfValid then
    -- return the instance
    return self
  else
    self.debug("Self is INVALID!")
    return nil
  end
end
