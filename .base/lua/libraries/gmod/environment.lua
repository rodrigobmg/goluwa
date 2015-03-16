local gmod = ... or _G.gmod

local env = {}
env._R = {}
env._G = env

gmod.env = env

local data = include("lua/libraries/gmod/exported.lua")
local globals = data.functions._G

data.functions._G = nil

do -- copy standard libraries
	local function add_lib_copy(name)
		local lib = {}

		for k,v in pairs(_G[name]) do lib[k] = v end

		env[name] = lib
	end

	add_lib_copy("string")
	add_lib_copy("math")
	add_lib_copy("table")
	add_lib_copy("coroutine")
	add_lib_copy("debug")
	add_lib_copy("bit")
	add_lib_copy("io")
	add_lib_copy("os")
end

do -- enums
	for enum_name, value in pairs(data.enums) do
		env[enum_name] = env[enum_name] or value
	end
	
	include("lua/libraries/gmod/enums.lua", gmod)
end

do -- global functions
	for func_name in pairs(globals) do
		env[func_name] = env[func_name] or function(...) error(("NYI: %s(%s)\n"):format(func_name, table.concat(tostring_args(...), ",")), 2) end
	end
	
	include("lua/libraries/gmod/globals.lua", gmod)
end

do -- metatables
	for meta_name, functions in pairs(data.meta) do
		functions.__tostring = nil
		functions.__newindex = nil
	
		if not env._R[meta_name] then 
			local META = {}
			META.MetaName = meta_name
			META.__index = META
			env._R[meta_name] = META
		end
		for func_name in pairs(functions) do
			env._R[meta_name][func_name] = env._R[meta_name][func_name] or function(...) error(("NYI: %s:%s(%s)\n"):format(meta_name, func_name, table.concat(tostring_args(...), ",")), 2) end
		end	
	end
	
	include("lua/libraries/gmod/meta/*")
end

do -- libraries
	for lib_name, functions in pairs(data.functions) do
		env[lib_name] = env[lib_name] or {}
		
		for func_name in pairs(functions) do
			env[lib_name][func_name] = env[lib_name][func_name] or function(...) error(("NYI: %s.%s(%s)\n"):format(lib_name, func_name, table.concat(tostring_args(...), ",")), 2) end
		end
	end
	
	for file_name in vfs.Iterate("lua/libraries/gmod/libraries/") do
		local lib_name = file_name:match("(.+)%.")
		
		env[lib_name] = env[lib_name] or {}
		
		include("lua/libraries/gmod/libraries/" .. file_name, gmod)
	end
end

setmetatable(env, {__index = _G})