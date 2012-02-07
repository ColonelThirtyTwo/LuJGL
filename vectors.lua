-- Vectors library using FFI. Uses less memory than Lua tables.

local sqrt = math.sqrt
local ffi = require("ffi")

local Vector = {}
setmetatable(Vector, {__call = function(self,...) return Vector.new(...) end})
Vector.__index = Vector
local new_vector3 = ffi.metatype("struct { double x, y, z; }",Vector)

function Vector.new(x,y,z)
	return new_vector3(x or 0, y or 0, z or 0)
end

function Vector:__add(other)
	return new_vector3(self.x+other.x, self.y+other.y, self.z+other.z)
end
function Vector:__sub(other)
	return new_vector3(self.x-other.x, self.y-other.y, self.z-other.z)
end
function Vector:__mul(other)
	return new_vector3(self.x*other, self.y*other, self.z*other)
end
function Vector:__div(other)
	return new_vector3(self.x/other, self.y/other, self.z/other)
end
function Vector:__unm()
	return new_vector3(-self.x, -self.y, -self.z)
end
function Vector:__tostring()
	return string.format("<%d,%d,%d>",self.x,self.y,self.z)
end

function Vector:len()
	return sqrt(self.x*self.x+self.y*self.y+self.z*self.z)
end
Vector.__len = Vector.len
function Vector:len2()
	return self.x*self.x+self.y*self.y+self.z*self.z
end

function Vector:normalized()
	return self/self:len()
end
Vector.normalize = Vector.normalized
function Vector:dot(o)
	return self.x*o.x + self.y*o.y + self.z*o.z
end
function Vector:cross(other)
	return new_vector3(self.y*other.z-self.z*other.y, self.z*other.x - self.x*other.z, self.x*other.y - self.y*other.x)
end
function Vector:set(x,y,z)
	self.x = x
	self.y = y
	self.z = z
end
function Vector:unpack()
	return self.x, self.y, self.z
end
function Vector:copy()
	return new_vector3(self.x, self.y, self.z)
end

return Vector