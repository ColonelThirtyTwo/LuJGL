
assert(jit, "LuJGL must run on LuaJIT!")

local ffi = require("ffi")
local bit = require("bit")

local LuJGL = {}

-- Error flag, so we can exit the main loop if a callback errors
local stop = false
-- Client callback functions
local render_cb
local idle_cb
local event_cb

local function xpcall_traceback_hook(err)
	print(debug.traceback(tostring(err) or "(non-string error)"))
end

local function call_callback(func,...)
	if not func then return true end
	local ok, msg = xpcall(func,xpcall_traceback_hook,...)
	if not ok then
		stop = true
	end
	return ok, msg
end

--- Loads the OpenGL, GLU, and GLUT libraries.
-- After this call, LuJGL.gl[u[t]] will be set to their respective
-- libraries. No window will be created however.
-- @param basepath (Optional) The path where the ffi definitions reside in. Defaults to ./ffi/
function LuJGL.load(basepath)
	basepath = basepath or "./ffi"
	-- Load OpenGL
	ffi.cdef(assert(io.open(basepath.."/gl.h"):read("*a")))
	LuJGL.gl = ffi.load("opengl32",true)
	-- Load GLU
	ffi.cdef(assert(io.open(basepath.."/glu.h"):read("*a")))
	LuJGL.glu = ffi.load("glu32",true)
	-- Load GLUT
	ffi.cdef(assert(io.open(basepath.."/freeglut.h"):read("*a")))
	LuJGL.glut = ffi.load("freeglut",false)
end

--- Initializes GLUT and creates a new window.
-- @param name The window name
-- @param w (Optional) Window width. Defaults to 640.
-- @param h (Optional) Window height. Defaults to 480.
-- @param args (Optional) Arguments to glutInit. (TODO: Make this do something)
function LuJGL.initialize(name, w, h, args)
	local glut = assert(LuJGL.glut,"Must call LuJGL.load before LuJGL.initialize!")
	
	w = w or 640
	h = h or 480
	
	local argc = ffi.new("int[1]",0)
	glut.glutInit(argc,nil)
	glut.glutInitDisplayMode(bit.bor(glut.GLUT_DOUBLE, glut.GLUT_RGB, glut.GLUT_DEPTH))
	glut.glutInitWindowSize(w,h)
	glut.glutCreateWindow(name)
	glut.glutIgnoreKeyRepeat(true)
	glut.glutSetOption(glut.GLUT_ACTION_ON_WINDOW_CLOSE,glut.GLUT_ACTION_CONTINUE_EXECUTION)
	
	lujgl.width = w -- TODO: Change to glutGet calls
	lujgl.height = h
	
	-- -- Callbacks
	
	-- Render
	glut.glutDisplayFunc(function()
		local ok = call_callback(render_cb)
		if ok then glut.glutSwapBuffers() end
	end)
	
	-- Idle
	glut.glutIdleFunc(function()
		call_callback(idle_cb)
		LuJGL.glut.glutPostRedisplay()
	end)
	
	-- Close
	glut.glutCloseFunc(function()
		local ok, msg = call_callback(event_cb, "close")
		if ok and not msg then stop = true end
	end)
	
	-- Keyboard
	glut.glutKeyboardFunc(function(key, x, y)
		call_callback(event_cb, "key", true, key, string.byte(key), x, y)
	end)
end

--- Deinitializes everything.
function LuJGL.deinitialize()
end

--- Sets the idle callback. This is where the "thinking" code should go.
function LuJGL.setIdleCallback(cb)
	idle_cb = cb
end

--- Sets the render callback. Render the scene here.
function LuJGL.setRenderCallback(cb)
	render_cb = cb
end

--- Sets the event callback. Called for handling events.
function LuJGL.setEventCallback(cb)
	event_cb = cb
end

--- Enters the main loop.
function LuJGL.mainLoop()
	while not stop do
		LuJGL.glut.glutMainLoopEvent()
	end
end

--- Signals the main loop to terminate. This simply sets a flag; this function
-- does return.
function LuJGL.signalQuit()
	stop = true
end

package.loaded["luajgl"] = LuJGL
return LuJGL