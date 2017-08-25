--[[ Snooper.lua ]]--
-- Monitors and displays rednet messages on the screen

local protocol = "QDTTS"
local modem = "top"

print("Listening to RedNet protocol "..protocol..":")

rednet.open(modem)
while true do
    id,msg = rednet.receive(protocol, 5)
    if id ~= nil then
        print("["..math.floor(os.clock()).."] "..id..": "..msg)
    end
end
