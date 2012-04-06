
local lujgl = require "lujgl"
local ffi = require "ffi"
local bit = require "bit"
local vectors = require "vectors"

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
local glu = lujgl.glu
local glew = lujgl.glew

local imgtx = lujgl.loadTexture("test.png", nil, false, false)

gl.glEnable(gl.GL_DEPTH_TEST);

gl.glMatrixMode(gl.GL_PROJECTION)
glu.gluPerspective(60,lujgl.width / lujgl.height,0.01, 1000)
gl.glMatrixMode(gl.GL_MODELVIEW)
glu.gluLookAt(0,0,5,
	0,0,0,
	0,1,0)

gl.glEnable(gl.GL_DEPTH_TEST)
gl.glEnable(gl.GL_COLOR_MATERIAL)

gl.glEnable(gl.GL_LIGHTING)
gl.glEnable(gl.GL_LIGHT0)
lujgl.glLight(gl.GL_LIGHT0, gl.GL_AMBIENT, 0.2, 0.2, 0.2)

lujgl.setIdleCallback(function() end)

local rotationAxis = vectors.new(1,1,0):normalized()
local boxPos = vectors(-0.5,-0.5,2)
print("Rotation Axis:",rotationAxis)
print("Box Position:",boxPos)

-- GLEW test
if gl.GLEW_ARB_vertex_program ~= 0 then
	print("Vertex shaders supported.")
else
	print("Vertex shaders not supported.")
end

function render()
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT));
	
	-- 3D stuff
	gl.glEnable(gl.GL_TEXTURE_2D);
	gl.glBindTexture(gl.GL_TEXTURE_2D,imgtx)
	gl.glPushMatrix()
	gl.glColor3d(1,1,1)
	gl.glScaled(3,3,1)
	gl.glBegin(gl.GL_QUADS)
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
	gl.glDisable(gl.GL_TEXTURE_2D)
	
	gl.glPushMatrix()
	gl.glTranslated(boxPos:unpack())
	gl.glRotated(lujgl.getTime()*10,rotationAxis:unpack())
	for i=0,5 do
		gl.glBegin(gl.GL_QUADS)
		gl.glNormal3fv(CubeVerticies.n[i])
		for j=0,3 do
			gl.glVertex3fv(CubeVerticies.v[CubeVerticies.f[i][j]])
		end
		gl.glEnd()
	end
	gl.glPopMatrix()
	
	-- 2D stuff
	gl.glDisable(gl.GL_TEXTURE_2D)
	lujgl.begin2D()
	gl.glBegin(gl.GL_QUADS)
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