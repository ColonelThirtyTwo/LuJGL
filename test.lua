
local lujgl = require "lujgl"
local ffi = require "ffi"
local bit = require "bit"

local CubeVerticies = {}
CubeVerticies.v = ffi.new("const float[8][3]", {
	{0,0,1}, {0,0,0}, {0,1,0}, {0,1,1},
	{1,0,1}, {1,0,0}, {1,1,0}, {1,1,1}
})

CubeVerticies.n = ffi.new("const float[6][3]", {
	{-1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {1.0, 0.0, 0.0},
	{0.0, -1.0, 0.0}, {0.0, 0.0, -1.0}, {0.0, 0.0, 1.0}
})

CubeVerticies.f = ffi.new("const float[6][4]", { 
	{0, 1, 2, 3}, {3, 2, 6, 7}, {7, 6, 5, 4},
	{4, 5, 1, 0}, {5, 6, 2, 1}, {7, 4, 0, 3}
})

print("Initializing window")
lujgl.initialize("Test App")

local gl = lujgl.gl
local glconst = lujgl.glconst
local glu = lujgl.glu

local imgtx = lujgl.loadTexture("test.png", nil, false, false)

gl.glEnable(glconst.GL_DEPTH_TEST)

gl.glMatrixMode(glconst.GL_PROJECTION)
glu.gluPerspective(60,lujgl.width / lujgl.height,0.01, 1000)
gl.glMatrixMode(glconst.GL_MODELVIEW)
glu.gluLookAt(0,0,5,
	0,0,0,
	0,1,0)

gl.glEnable(glconst.GL_DEPTH_TEST)
gl.glEnable(glconst.GL_COLOR_MATERIAL)

gl.glEnable(glconst.GL_LIGHTING)
gl.glEnable(glconst.GL_LIGHT0)
lujgl.glLight(glconst.GL_LIGHT0, glconst.GL_AMBIENT, 0.2, 0.2, 0.2)

lujgl.setIdleCallback(function() end)

local rotx, roty, rotz = 1/math.sqrt(2), 1/math.sqrt(2), 0
local boxx, boxy, boxz = -0.5,-0.5,2
print("Rotation Axis:", rotx, roty, rotz)
print("Box Position:", boxx, boxy, boxz)

-- Try loading an extension
--[[
do
	if lujgl.glfw.glfwExtensionSupported("GL_ARB_shader_objects") ~= 0 then
		print("Shader objects supported. Trying to fetch address for glLinkProgramARB.")
		local glLinkProgramARB = lujgl.glext.glLinkProgramARB
		if glLinkProgramARB ~= nil then
			print("Address:", tostring(glLinkProgramARB))
		else
			print("Couldn't find or address is null.")
		end
	else
		print("Shader objects not supported.")
	end
end
]]

function render()
	gl.glClear(bit.bor(glconst.GL_COLOR_BUFFER_BIT, glconst.GL_DEPTH_BUFFER_BIT));
	
	-- 3D stuff
	gl.glEnable(glconst.GL_TEXTURE_2D)
	gl.glBindTexture(glconst.GL_TEXTURE_2D,imgtx)
	gl.glPushMatrix()
	gl.glColor3d(1,1,1)
	gl.glScaled(3,3,1)
	gl.glBegin(glconst.GL_QUADS)
		gl.glNormal3d(0,0,-1)
		gl.glTexCoord2d(0,0)
		gl.glVertex3d(-1,-1,0)
		
		gl.glTexCoord2d(1,0)
		gl.glVertex3d(1,-1,0)
		
		gl.glTexCoord2d(1,1)
		gl.glVertex3d(1,1,0)
		
		gl.glTexCoord2d(0,1)
		gl.glVertex3d(-1,1,0)
	gl.glEnd()
	gl.glPopMatrix()
	gl.glDisable(glconst.GL_TEXTURE_2D)
	
	gl.glPushMatrix()
	gl.glTranslated(boxx, boxy, boxz)
	--gl.glRotated(lujgl.getTime()*10, rotx, roty, rotz)
	gl.glRotated(os.clock()*10, rotx, roty, rotz)
	for i=0,5 do
		gl.glBegin(glconst.GL_QUADS)
		gl.glNormal3fv(CubeVerticies.n[i])
		for j=0,3 do
			gl.glVertex3fv(CubeVerticies.v[CubeVerticies.f[i][j]])
		end
		gl.glEnd()
	end
	gl.glPopMatrix()
	
	-- 2D stuff
	gl.glDisable(glconst.GL_TEXTURE_2D)
	lujgl.begin2D()
	gl.glBegin(glconst.GL_QUADS)
		gl.glVertex2i(0, 0)
		gl.glVertex2i(50, 0)
		gl.glVertex2i(50, 50)
		gl.glVertex2i(0, 50)
	gl.glEnd()
	lujgl.end2D()
	
	lujgl.checkError()
end
lujgl.setRenderCallback(render)

function think()
	if lujgl.frameCount % 1000 == 1000-1 then
		print(string.format("FPS: %f", lujgl.fps()))
	end
end
lujgl.setIdleCallback(think)

function event(ev,...)
	print("Event", ev, ...)
end
lujgl.setEventCallback(event)

print("Entering main loop")
lujgl.mainLoop()
print("Exiting normally")