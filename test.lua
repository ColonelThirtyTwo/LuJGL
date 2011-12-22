lujgl = require "lujgl"

print("Initializing window")
lujgl.initialize("Test App")

local gl = lujgl.gl
local glu = lujgl.glu
local glut = lujgl.glut

gl.glMatrixMode(gl.GL_PROJECTION)
glu.gluPerspective(60,lujgl.width / lujgl.height,0.01, 1000)
gl.glMatrixMode(gl.GL_MODELVIEW)
glu.gluLookAt(0,0,5,
	0,0,0,
	0,1,0)

gl.glEnable(gl.GL_LIGHTING)
gl.glEnable(gl.GL_LIGHT0)
lujgl.glLight(gl.GL_LIGHT0, gl.GL_AMBIENT, 0.2, 0.2, 0.2)

local r = 0
function think()
	r = r + 0.1
end
lujgl.setIdleCallback(think)

function render()
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT));
	gl.glPushMatrix()
	gl.glRotated(r,0,1,0)
	glut.glutSolidCube(1)
	gl.glPopMatrix()
end
lujgl.setRenderCallback(render)

function event(ev,...)
	print("Event", ev, ...)
end
lujgl.setEventCallback(event)

print("Entering main loop")
lujgl.mainLoop()
print("Exiting normally")