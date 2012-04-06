
local ffi = require "ffi"
local bit = require "bit"
local gl2glew = require "gl2glew"

local max = math.max
local gl, glu, glfw, glew

local int_buffer = ffi.new("int[2]")

local LuJGL = {}
LuJGL.frameCount = 0

-- Error flag, so we can exit the main loop if a callback errors
local stop = false
-- Client callback functions
local render_cb
local idle_cb
local event_cb

local tex_channels2glconst

do
	local basepath = LUJGL_FFI_PATH or "./ffi"
	
	-- Load OpenGL + GLEW
	ffi.cdef(assert(io.open(basepath.."/glew.ffi")):read("*a"))
	local gllib = ffi.load("opengl32",true)
	local glewlib = ffi.load("glew32",true)
	LuJGL.gl = setmetatable({},{__index = function(self, k)
		return gl2glew[k] and glewlib[gl2glew[k]] or gllib[k]
	end})
	gl = LuJGL.gl
	glew = glewlib
	LuJGL.glew = glewlib
	
	-- Load GLU
	ffi.cdef(assert(io.open(basepath.."/glu.ffi")):read("*a"))
	glu = ffi.load("glu32",true)
	LuJGL.glu = glu
	-- Load GLFW
	ffi.cdef(assert(io.open(basepath.."/glfw.ffi")):read("*a"))
	glfw = ffi.load("glfw",true)
	LuJGL.glfw = glfw
	-- Load stb_image
	ffi.cdef(assert(io.open(basepath.."/stb_image.ffi")):read("*a"))
	LuJGL.stb_image = ffi.load("stb_image",true)

	-- Load some constants for utility functions
	tex_channels2glconst = {
		[1] = glu.GL_ALPHA,
		[2] = glu.GL_LUMINANCE_ALPHA,
		[3] = glu.GL_RGB,
		[4] = glu.GL_RGBA,
	}
end

local function xpcall_traceback_hook(err)
	print(debug.traceback(tostring(err) or "(non-string error)"))
end

local function create_callback(func)
	-- Work around for this:
	-- http://lua-users.org/lists/lua-l/2011-12/msg00712.html
	jit.off(func)
	return func
end

local function call_callback(func,...)
	if not func then return true end
	local ok, msg = xpcall(func,xpcall_traceback_hook,...)
	if not ok then
		stop = true
	end
	return ok, msg
end

--- Initializes GLFW and creates a new window.
-- @param name The window name
-- @param w (Optional) Window width. Defaults to 640.
-- @param h (Optional) Window height. Defaults to 480.
function LuJGL.initialize(name, w, h)
	w = w or 640
	h = h or 480
	
	if glfw.glfwInit() == 0 then
		error("error initializing glfw",0)
	end
	
	glfw.glfwOpenWindowHint(glfw.GLFW_WINDOW_NO_RESIZE, true)
	
	-- TODO: Whats a good default for the number of stencil bits?
	if glfw.glfwOpenWindow(w,h,8,8,8,8,24,8,glfw.GLFW_WINDOW) == 0 then
		glfw.glfwTerminate()
		error("error initializing glfw window",0)
	end
	
	local err = glew.glewInit()
	if err ~= glew.GLEW_OK then
		error("error initializing glew: "..ffi.string(glew.glewGetErrorString(err)),0)
	end
	
	local size_buffer = ffi.new("int[2]")
	glfw.glfwGetWindowSize(size_buffer, size_buffer + 1)
	LuJGL.width = size_buffer[0]
	LuJGL.height = size_buffer[1]
	
	glfw.glfwSetWindowTitle(name)
	
	glfw.glfwSetWindowCloseCallback(create_callback(function()
		local ok, msg = call_callback(event_cb, "close")
		if ok and not msg then stop = true end
		return false
	end))
	
	glfw.glfwSetKeyCallback(create_callback(function(key, down)
		if key <= 255 then
			key = string.char(key):lower()
		end
		call_callback(event_cb, "key", down ~= 0, key)
	end))
	
	glfw.glfwSetMouseButtonCallback(create_callback(function(button, action)
		glfw.glfwGetMousePos(int_buffer,int_buffer+1)
		call_callback(event_cb, "mouse", button, action ~= 0, int_buffer[0], int_buffer[1])
	end))
	
	glfw.glfwSetMousePosCallback(create_callback(function(x,y)
		call_callback(event_cb, "motion", x, y)
	end))
end

function LuJGL.deinitialize()
	glfw.glfwTerminate()
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

--- Checks for an OpenGL error. Errors if it finds one.
function LuJGL.checkError()
	local errcode = gl.glGetError()
	if errcode ~= gl.GL_NO_ERROR then
		error("OpenGL Error: "..ffi.string(glu.gluErrorString(errcode)),0)
	end
end

--- Enters the main loop.
function LuJGL.mainLoop()
	glfw.glfwSetTime(0)
	LuJGL.frameCount = 0
	while not stop do
		call_callback(idle_cb)
		call_callback(render_cb)
		glfw.glfwSwapBuffers()
		LuJGL.frameCount = LuJGL.frameCount + 1
	end
	glfw.glfwCloseWindow()
	glfw.glfwTerminate()
end

--- Signals the main loop to terminate. This simply sets a flag; this function
-- does return.
function LuJGL.signalQuit()
	stop = true
end

--- Gets the time since the main loop started in seconds
function LuJGL.getTime()
	return glfw.glfwGetTime()
end

-- -- Some helful utilities

do
	local last_framecount = 0
	local last_time = 0
	--- Returns (frames / seconds) since the last call to this function
	function LuJGL.fps()
		local count, now = LuJGL.frameCount, LuJGL.getTime()
		local num = (count - last_framecount) / (now - last_time)
		last_framecount = count
		last_time = now
		return num
	end
end

--- Loads an image file to a texture, using stb_image
-- @param filepath Path to file to load texture from
-- @param fchannels If non-nil, force this number of channels
-- @param mipmaps Whether to generate mipmaps for this texture
-- @param wrap Whether to set the texture repeat flag
-- @return Texture ID
-- @return Image Width
-- @return Image Height
-- @return Image channels (before adjusting to fchannels, see stb_image)
function LuJGL.loadTexture(filepath, fchannels, mipmaps, wrap)
	local imgdatabuffer = ffi.new("int[3]",0)
	
	local image = ffi.gc(LuJGL.stb_image.stbi_load(filepath, imgdatabuffer, imgdatabuffer+1, imgdatabuffer+2, fchannels or 0),
		LuJGL.stb_image.stbi_image_free)
	
	if image == nil then
		error(ffi.string(LuJGL.stb_image.stbi_failure_reason()))
	end
	
	local texbuffer = ffi.new("unsigned int[1]",0)
	gl.glGenTextures(1,texbuffer)
	local texid = texbuffer[0]
	if texid == 0 then error("glGenTextures failed") end
	gl.glBindTexture(gl.GL_TEXTURE_2D,texid)
	
	if wrap then
		gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_REPEAT)
		gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_REPEAT)
	end
	
	if mipmaps then
		gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR_MIPMAP_NEAREST)
		gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
		local ok = glu.gluBuild2DMipmaps(gl.GL_TEXTURE_2D, fchannels or imgdatabuffer[2], imgdatabuffer[0], imgdatabuffer[1],
			tex_channels2glconst[fchannels or imgdatabuffer[2]], gl.GL_UNSIGNED_BYTE, image)
		if ok ~= 0 then
			error(glu.gluErrorString(ok))
		end
	else
		gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
		gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
		gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, fchannels or imgdatabuffer[2], imgdatabuffer[0], imgdatabuffer[1],
			0, tex_channels2glconst[fchannels or imgdatabuffer[2]], gl.GL_UNSIGNED_BYTE, image)
	end
	
	LuJGL.checkError()
	return texid
end

local fbuffer = ffi.new("float[?]",4)
--- Convenience function for glLightfv. Uses a static internal buffer
-- to store the array in.
function LuJGL.glLight(light, enum, r, g, b, a)
	fbuffer[0] = r or 0
	fbuffer[1] = g or 0
	fbuffer[2] = b or 0
	fbuffer[3] = a or 1
	gl.glLightfv(light, enum, fbuffer)
end

--- Begins rendering 2D. Use this to render HUD, GUI, etc.
function LuJGL.begin2D()
	gl.glPushAttrib(bit.bor(gl.GL_ENABLE_BIT))
	gl.glDisable(gl.GL_DEPTH_TEST)
	gl.glDisable(gl.GL_CULL_FACE)
	gl.glDisable(gl.GL_FOG)
	gl.glDisable(gl.GL_LIGHTING)
	
	gl.glMatrixMode(gl.GL_MODELVIEW)
	gl.glPushMatrix()
	gl.glLoadIdentity()
	gl.glMatrixMode(gl.GL_PROJECTION)
	gl.glPushMatrix()
	gl.glLoadIdentity()
	gl.glOrtho(0,LuJGL.width,0,LuJGL.height,-1,1)
	gl.glMatrixMode(gl.GL_MODELVIEW)
end

--- Ends 2d rendering.
function LuJGL.end2D()
	gl.glMatrixMode(gl.GL_PROJECTION)
	gl.glPopMatrix()
	gl.glMatrixMode(gl.GL_MODELVIEW)
	gl.glPopMatrix()
	
	gl.glPopAttrib()
end

return LuJGL