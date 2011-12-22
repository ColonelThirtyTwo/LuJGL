= LuJGL =
Easy to use OpenGL library for LuaJIT using FFI

== Requirements ==
* OpenGL (Should come with most systems)
* [http://luajit.org/luajit.html LuaJIT] (Regular Lua will NOT work!)
* [http://freeglut.sourceforge.net/ FreeGLUT]

== How to Use (Windows) ==
* Download the source via git
* Put luajit.exe, lua51.dll, freeglut.dll in the directory
* Load the library via requiring it:
local lujgl = require "lujgl"
* Call lujgl.initialize(windowname, w, h) followed by lujgl.mainLoop()
