lujgl = require "lujgl"

print("Loading LuJGL")
lujgl.load()

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

local r = 0
function think()
	r = r + 0.1
	print("Thinking")
end
lujgl.setIdleCallback(think)

function render()
	gl.glPushMatrix()
	gl.glRotated(r,0,1,0)
	glut.glutSolidCube(1)
	gl.glPopMatrix()
	print("Rendering")
end
lujgl.setRenderCallback(render)

function event(ev,...)
	print("Event", ev)
end
lujgl.setEventCallback(event)

print("Entering main loop")
lujgl.mainLoop()
print("Exiting normally")