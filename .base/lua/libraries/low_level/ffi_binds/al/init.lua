-- https://github.com/malkia/ufo/blob/master/ffi/OpenAL.lua

-- The code below was contributed by David Hollander along with OpenALUT.cpp
-- To run on Windows, there are few choices, easiest one is to download
-- http://connect.creativelabs.com/openal/Downloads/oalinst.zip
-- and run the executable from inside of it (I've seen couple of games use it).

local header = include("header.lua") 

local enums = include("enums.lua")
local extensions = include("extensions.lua")

local reverse_enums = {}
for k,v in pairs(enums) do 
	k = k:gsub("AL_", "")
	k = k:gsub("_", " ")
	k = k:lower()	

	reverse_enums[v] = k 
end

for k,v in pairs(enums) do
	e[k] = v
end
 
ffi.cdef(header)

local library = ffi.load(WINDOWS and "openal32" or "openal")

local al = _G.al or {}

local function gen_available_params(type, user_unavailable) -- effect params
	local available = {}

	local unavailable = {
		last_parameter = true,
		first_parameter = true,
		type = true,
		null = true,
	}
	
	for k,v in pairs(user_unavailable) do
		unavailable[v] = true
	end
	
	local type_pattern = "AL_"..type:upper().."_(.+)"

	for key, val in pairs(enums) do
		local type = key:match(type_pattern)
		
		if type then 
			type = type:lower()
			if not unavailable[type] then
				available[type] = {enum = val, params = {}}
			end
		end
	end

	for name, data in pairs(available) do
		for key, val in pairs(enums) do
			local param = key:match("AL_" .. name:upper() .. "_(.+)")
			
			if param then
				local name = param:lower() 
				
				if param:find("DEFAULT_") then
					name = param:match("DEFAULT_(.+)")
					key = "default"
				elseif param:find("MIN_") then
					name = param:match("MIN_(.+)")
					key = "min"
				elseif param:find("MAX_") then
					name = param:match("MAX_(.+)")
					key = "max"
				else
					key = "enum" 
				end
				
				name = name:lower()
				
				data.params[name] = data.params[name] or {}
				data.params[name][key] = val
			end
		end
	end
	
	al["GetAvailable" .. type .. "s"] = function()
		return available
	end

end

gen_available_params("Effect", {"pitch_shifter", "vocal_morpher", "frequency_shifter"})
gen_available_params("Filter", {"highpass", "bandpass"})

local function add_al_func(name, func)
	al[name] = function(...) 
		local val = func(...)
		
		if al.logcalls then
			setlogfile("al_calls")
				logf("%s = al%s(%s)", luadata.ToString(val), name, table.concat(tostring_args(...), ",\t"))
			setlogfile()
		end
		
		if name ~= "GetError" and al.debug then
		
			local code = al.GetError()
		
			if code ~= 0 then
				local str = reverse_enums[code] or "unkown error"
				
				local info = debug.getinfo(2)
				for i = 1, 10 do
					if info.source:find("al.lua", nil, true) then
						info = debug.getinfo(2+i)
					else
						break
					end
				end
				
				logf("[openal] %q in function %s at %s:%i", str, info.name, info.short_src, info.currentline)
			end
		end
		
		return val
	end
end

for line in header:gmatch("(.-)\n") do
	local func_name = line:match(" (al%u.-)%(")
	if func_name then
		add_al_func(func_name:sub(3), library[func_name])
	end 
end

for name, type in pairs(extensions) do
	local func = al.GetProcAddress(name)
	func = ffi.cast(type, func)
	
	al[name:sub(3)] = func
end

for name, func in pairs(al) do
	if name:find("Gen%u%l") then
		al[name:sub(0,-2)] = function()
			local id = ffi.new("ALuint [1]") 
			al[name](1, id) 
			return id[0]
		end
	end
end

return al
