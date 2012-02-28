
assert(jit, "LuJGL must run on LuaJIT!")

local ffi = require("ffi")
local bit = require("bit")

local max = math.max
local gl, glu, glut

local LuJGL = {}

-- Error flag, so we can exit the main loop if a callback errors
local stop = false
-- Client callback functions
local render_cb
local idle_cb
local event_cb

local tex_channels2glconst

do
	local basepath = LUJGL_FFI_PATH or "./ffi"
	-- Load OpenGL
	ffi.cdef(assert(io.open(basepath.."/gl.ffi")):read("*a"))
	gl = ffi.load("opengl32",true)
	LuJGL.gl = gl
	-- Load GLU
	ffi.cdef(assert(io.open(basepath.."/glu.ffi")):read("*a"))
	glu = ffi.load("glu32",true)
	LuJGL.glu = glu
	-- Load GLUT
	ffi.cdef(assert(io.open(basepath.."/freeglut.ffi")):read("*a"))
	glut = ffi.load("freeglut",true)
	LuJGL.glut = glut
	-- Load stb_image
	ffi.cdef(assert(io.open(basepath.."/stb_image.ffi")):read("*a"))
	LuJGL.stb_image = ffi.load("stb_image",true)

	-- Load some constants for utility functions
	local gl = LuJGL.glu
	tex_channels2glconst = {
		[1] = gl.GL_ALPHA,
		[2] = gl.GL_LUMINANCE_ALPHA,
		[3] = gl.GL_RGB,
		[4] = gl.GL_RGBA,
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

--- Initializes GLUT and creates a new window.
-- @param name The window name
-- @param w (Optional) Window width. Defaults to 640.
-- @param h (Optional) Window height. Defaults to 480.
-- @param args (Optional) Arguments to glutInit. (TODO: Not implemented)
function LuJGL.initialize(name, w, h, args)
	local glut = assert(LuJGL.glut)
	
	w = w or 640
	h = h or 480
	
	local argc = ffi.new("int[1]",0)
	glut.glutInit(argc,nil)
	glut.glutInitDisplayMode(bit.bor(glut.GLUT_DOUBLE, glut.GLUT_RGBA, glut.GLUT_DEPTH, glut.GLUT_STENCIL))
	glut.glutInitWindowSize(w,h)
	glut.glutCreateWindow(name)
	glut.glutIgnoreKeyRepeat(true)
	glut.glutSetOption(glut.GLUT_ACTION_ON_WINDOW_CLOSE,glut.GLUT_ACTION_CONTINUE_EXECUTION)
	
	LuJGL.width = glut.glutGet(glut.GLUT_WINDOW_WIDTH)
	LuJGL.height = glut.glutGet(glut.GLUT_WINDOW_HEIGHT)
	
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
	
	glut.glutCloseFunc(create_callback(function()
		local ok, msg = call_callback(event_cb, "close")
		if ok and not msg then stop = true end
	end))
	
	glut.glutKeyboardFunc(create_callback(function(key, x, y)
		call_callback(event_cb, "key", true, string.char(key), x, y)
	end))
	glut.glutKeyboardUpFunc(create_callback(function(key,x,y)
		call_callback(event_cb, "key", false, string.char(key), x, y)
	end))
	glut.glutSpecialFunc(create_callback(function(key,x,y)
		call_callback(event_cb, "key", true, key, x, y)
	end))
	glut.glutSpecialUpFunc(create_callback(function(key,x,y)
		call_callback(event_cb, "key", false, key, x, y)
	end))
	
	glut.glutMouseFunc(create_callback(function(button, state, x, y)
		call_callback(event_cb, "mouse", button, state ~= 0, x, y)
	end))
	
	glut.glutMotionFunc(create_callback(function(x,y)
		call_callback(event_cb, "motion", x, y)
	end))
	glut.glutPassiveMotionFunc(create_callback(function(x,y)
		call_callback(event_cb, "motion", x, y)
	end))
	
	glut.glutReshapeFunc(create_callback(function(w,h)
		LuJGL.gl.glViewport(0,0,max(w,1),max(1,h))
		LuJGL.width = w
		LuJGL.height = h
		call_callback(event_cb,"resize",w,h)
	end))
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
	while not stop do
		LuJGL.checkError()
		call_callback(idle_cb)
		glut.glutPostRedisplay()
		glut.glutMainLoopEvent()
	end
end

--- Signals the main loop to terminate. This simply sets a flag; this function
-- does return.
function LuJGL.signalQuit()
	stop = true
end

-- -- Some helful utilities

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
	glu.gluOrtho2D(0,LuJGL.width,0,LuJGL.height)
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