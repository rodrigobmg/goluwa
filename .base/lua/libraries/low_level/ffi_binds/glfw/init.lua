local enums = include("enums.lua")
local header = include("header.lua")

ffi.cdef(header)

local lib = ffi.load(jit.os == "Linux" and "glfw" or "glfw3")

local glfw = {}
local e = _G.e or glfw

glfw.enums = enums
glfw.header = header
glfw.lib = lib

-- put all the functions in the glfw table
for line in header:gmatch("(.-)\n") do
	local name = line:match("glfw(.-)%(")
	
	if name then
		glfw[name] = lib["glfw" .. name]
	end
end

for key, val in pairs(enums) do
	e[key] = val
end

do
	local reverse_enums = {}

	for k,v in pairs(enums) do
		local nice = k:lower():sub(6)
		reverse_enums[v] = nice
	end

	function glfw.EnumToString(num)
		return reverse_enums[num]
	end
end

do
	local keys = {}

	for k,v in pairs(enums) do
		if k:sub(0, 8) == "GLFW_KEY" then
			keys[v] = k:lower():sub(10)
		end
	end

	function glfw.KeyToString(num)
		return keys[num]
	end
end

do
	local mousebuttons = {}

	for k,v in pairs(e) do
		if k:sub(0, 10) == "GLFW_MOUSE" then
			mousebuttons[v] = k:lower():sub(12)
		end
	end

	function glfw.MouseToString(num)
		return mousebuttons[num]
	end
end

function glfw.GetVersion()
	local major = ffi.new("int[1]")
	local minor = ffi.new("int[1]")
	local rev = ffi.new("int[1]")
	
	lib.glfwGetVersion(major, minor, rev)
	
	return major[0] + (minor[0] / 100), rev[0]
end

glfw.SetErrorCallback(function(code, msg) logf("[glfw error] %s", ffi.string(msg)) end)

glfw.Init()

return glfw
