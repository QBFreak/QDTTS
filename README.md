# QDTTS
## Quick and Dirty Turtle Task System
A hacked together project to get my feet wet with [ComputerCraft](http://www.computercraft.info/), Lua, and to get some ideas for [Hive](https://github.com/CC-Hive/Main).

### Server
[server.lua](https://github.com/QBFreak/QDTTS/blob/master/server.lua)
* Runs a continious loop listening for RedNet messages and responding to them
* Maintains a list of all registered turtles

### Turtle (Turtle)
[turtle.lua](https://github.com/QBFreak/QDTTS/blob/master/turtle.lua)
* Registers with the server

### Control Console
[client.lua](https://github.com/QBFreak/QDTTS/blob/master/client.lua)
* Interfaces between the player and the server. Provides the following facilities:
  * Shutdown the server
  * Query the status of a turtle
