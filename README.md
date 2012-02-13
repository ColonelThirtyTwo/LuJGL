LuJGL
=====

OpenGL library for LuaJIT using FFI

Requirements
------------

 + OpenGL (Should come with most systems)
 + [LuaJIT](http://luajit.org/luajit.html) (Regular Lua will NOT work!)
 + [FreeGLUT](http://freeglut.sourceforge.net/)
 + [stb_image](http://nothings.org/) compiled as a DLL

How to Use (Windows)
--------------------
 + Download the source via git
 + Put luajit.exe, lua51.dll, freeglut.dll, and stb_image.dll in the directory
 + If the ffi folder is not in the working directory (a submodule, etc.), set the Lua global LUJGL_FFI_PATH to the directory where the FFI headers reside in.
 + Load the library via requiring it: `local lujgl = require "lujgl"`
 + Call lujgl.initialize(windowname, w, h) followed by lujgl.mainLoop()
 + Pass LuJGL.setIdleCallback/setRenderCallback/setEventCallback the appropriate functions
 + Run LuJGL.mainLoop to start.
