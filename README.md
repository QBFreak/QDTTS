# QDTTS
## Quick and Dirty Turtle Task System
A hacked together project to get my feet wet with [ComputerCraft](http://www.computercraft.info/), Lua, and to get some ideas for [Hive](https://github.com/CC-Hive/Main).

### Server
[server.lua](https://github.com/QBFreak/QDTTS/blob/master/server.lua)
* Runs a continious loop listening for RedNet messages and responding to them
* Maintains a list of all registered turtles
* Maintains a list of tasks
* Assigns pending tasks to idle turtles

#### Turtle States
* idle
* assigned
* running

#### Task states
* pending
* assigned
* running
* incomplete
* complete

### Turtle object
[qturtle.lua](https://github.com/QBFreak/QDTTS/blob/master/qturtle.lua)
Encapsulated in qTurtle object that the individual turtles can instantiate
* Registers with the server
* Provides move commands that handle fuel level monitoring and refuling
* Notifies server if out of fuel, if no longer out of fuel

### Turtle instance
Instance of a turtle object
[dean.lua](https://github.com/QBFreak/QDTTS/blob/master/dean.lua)
* Instantiates qTurtle object
* Registers with server
* Demonstrates movement methods

### Control Console
[client.lua](https://github.com/QBFreak/QDTTS/blob/master/client.lua)
Command line interface between the player and the server. Provides the following facilities:
* Add a task
* List tasks and turtles
* Query the status of a turtle
* Shutdown the server
