
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
-- Also calls LuJGL.load() if it hasn't been done already
-- @param name The window name
-- @param w (Optional) Window width. Defaults to 640.
-- @param h (Optional) Window height. Defaults to 480.
-- @param args (Optional) Arguments to glutInit. (TODO: Not implemented)
function LuJGL.initialize(name, w, h, args)
	if not LuJGL.glut then LuJGL.load() end
	local glut = assert(LuJGL.glut)
	
	w = w or 640
	h = h or 480
	
	local argc = ffi.new("int[1]",0)
	glut.glutInit(argc,nil)
	glut.glutInitDisplayMode(bit.bor(glut.GLUT_DOUBLE, glut.GLUT_RGB, glut.GLUT_DEPTH))
	glut.glutInitWindowSize(w,h)
	glut.glutCreateWindow(name)
	glut.glutIgnoreKeyRepeat(true)
	glut.glutSetOption(glut.GLUT_ACTION_ON_WINDOW_CLOSE,glut.GLUT_ACTION_CONTINUE_EXECUTION)
	
	lujgl.width = glut.glutGet(glut.GLUT_WINDOW_WIDTH)
	lujgl.height = glut.glutGet(glut.GLUT_WINDOW_HEIGHT)
	
	-- -- Callbacks
	
	-- Render
	glut.glutDisplayFunc(function()
		local ok = call_callback(render_cb)
		if ok then glut.glutSwapBuffers() end
	end)
	
	-- Idle (doing this in main loop)
	--glut.glutIdleFunc(function()
	--	call_callback(idle_cb)
	--	LuJGL.glut.glutPostRedisplay()
	--end)
	
	-- Close
	glut.glutCloseFunc(function()
		local ok, msg = call_callback(event_cb, "close")
		if ok and not msg then stop = true end
	end)
	
	-- Keyboard
	glut.glutKeyboardFunc(function(key, x, y)
		call_callback(event_cb, "key", true, string.char(key), x, y)
	end)
	glut.glutKeyboardUpFunc(function(key,x,y)
		call_callback(event_cb, "key", false, string.char(key), x, y)
	end)
	glut.glutSpecialFunc(function(key,x,y)
		call_callback(event_cb, "key", true, key, x, y)
	end)
	glut.glutSpecialUpFunc(function(key,x,y)
		call_callback(event_cb, "key", false, key, x, y)
	end)
	
	glut.glutMouseFunc(function(button, state, x, y)
		call_callback(event_cb, "mouse", button, state ~= 0, x, y)
	end)
	
	glut.glutMotionFunc(function(x,y)
		call_callback(event_cb, "motion", x, y)
	end)
	glut.glutPassiveMotionFunc(function(x,y)
		call_callback(event_cb, "motion", x, y)
	end)
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
		call_callback(idle_cb)
		LuJGL.glut.glutPostRedisplay()
		LuJGL.glut.glutMainLoopEvent()
	end
end

--- Signals the main loop to terminate. This simply sets a flag; this function
-- does return.
function LuJGL.signalQuit()
	stop = true
end

-- -- Some helful utilities
local fbuffer = ffi.new("float[?]",4)

--- Convenience function for glLightfv. Uses a static internal buffer
-- to store the array in.
function LuJGL.glLight(light, enum, r, g, b, a)
	fbuffer[0] = r or 0
	fbuffer[1] = g or 0
	fbuffer[2] = b or 0
	fbuffer[3] = a or 1
	LuJGL.gl.glLightfv(light, enum, fbuffer)
end

package.loaded["luajgl"] = LuJGL
return LuJGL