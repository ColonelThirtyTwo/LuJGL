
assert(jit, "LuJGL must run on LuaJIT!")

local ffi = require("ffi")
local bit = require("bit")

local LuJGL = {}

local render_cb
local idle_cb
local event_cb

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
	LuJGL.glut = fii.load("freeglut",false)
end

--- Initializes GLUT and creates a new window.
-- @param name The window name
-- @param args (Optional) Arguments to glutInit
function LuJGL.initialize(name, args)
	args = args or {}
	local argc = ffi.new("int[1]",#args)
	local glut = assert(LuJGL.glut,"Must call LuJGL.load before LuJGL.initialize!")
	glut.glutInit(argc,args)
	glut.glutInitDisplayMode(bit.bor(glut.GLUT_DOUBLE, glut.GLUT_RGB, glut.GLUT_DEPTH))
	glut.glutCreateWindow(name)
	glut.glutIgnoreKeyRepeat(true)
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

package.loaded["luajgl"] = LuJGL
return LuJGL