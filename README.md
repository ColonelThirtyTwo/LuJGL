LuJGL
=====

OpenGL library for LuaJIT using FFI

Requirements
------------

 + [LuaJIT](http://luajit.org/luajit.html) (Regular Lua will NOT work!)
 + [GLFW](http://www.glfw.org/)
 + [stb_image](http://nothings.org/) compiled as a DLL

How to Use (Windows)
--------------------
 + Download the source via git
 + Put luajit.exe, lua51.dll, glfw.dll, and stb_image.dll in the directory
 + Load the library via requiring it: `local lujgl = require "lujgl"`
 + Call lujgl.initialize(windowname, w, h) to create the window
 + Pass LuJGL.setIdleCallback/setRenderCallback/setEventCallback the appropriate functions
 + Call lujgl.mainLoop() to start the main loop

