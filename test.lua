local lujgl = require "lujgl"
local bit = require "bit"
local vectors = require "vectors"

print("Initializing window")
lujgl.initialize("Test App")

local gl = lujgl.gl
local glu = lujgl.glu
local glut = lujgl.glut

local imgtx = lujgl.loadTexture("test.png", nil, false, false)

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

local r = 0
function think()
	r = r + 0.1
end
lujgl.setIdleCallback(think)

local rotationAxis = vectors.new(1,1,0):normalized()
local boxPos = vectors(0,0,2)
print("Rotation Axis:",rotationAxis)
print("Box Position:",boxPos)
function render()
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT));
	
	-- 3D stuff
	gl.glEnable(gl.GL_DEPTH_TEST);
	gl.glEnable(gl.GL_CULL_FACE);
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
	gl.glRotated(r,rotationAxis:unpack())
	glut.glutSolidCube(1)
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

function event(ev,...)
	print("Event", ev, ...)
end
lujgl.setEventCallback(event)

print("Entering main loop")
lujgl.mainLoop()
print("Exiting normally")