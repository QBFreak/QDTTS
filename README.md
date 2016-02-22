# QDTTS
## Quick and Dirty Turtle Task System
A hacked together project to get my feet wet with [ComputerCraft](http://www.computercraft.info/), Lua, and to get some ideas for [Hive](https://github.com/CC-Hive/Main). All my turtles have names, mostly because they were reused from other projects. Clara was supposed to be a lumberjack and Dean was supposed to shovel snow. I guess we can't all be what we want when we grow up.

### Server
[clara.lua](https://github.com/QBFreak/QDTTS/blob/master/clara.lua)
* Runs a continious loop listening for RedNet messages and responding to them
* Maintains a list of all registered turtles

### Client (Turtle)
[dean.lua](https://github.com/QBFreak/QDTTS/blob/master/dean.lua)
* Registers with the server

### Control Console
[everly.lua](https://github.com/QBFreak/QDTTS/blob/master/everly.lua)
* Interfaces between the player and the server
  * Provides the mechanism to shutdown the server
