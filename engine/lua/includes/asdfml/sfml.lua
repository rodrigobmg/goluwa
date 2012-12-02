
sfml = {}
sfml.library_path = "lua/includes/asdfml/bin32/"
sfml.libraries = {}

function sfml.LoadLibraries()
	for file_name in pairs(file.Find(sfml.library_path .. "*", true)) do
		local lib_name = file_name:match("sfml%-(.-)%-2.dll")
		sfml.libraries[lib_name] = ffi.load("../" .. sfml.library_path .. file_name)
		printf("loaded library %s", file_name)
	end
end

do -- header parse

	sfml.headers_path = "lua/includes/asdfml/headers/"
	
	local function read_header(path)
		return file.Read("../" .. sfml.headers_path .. path, nil, true)
	end
	
	local included = {}

	local function parse_headers(str)
		local out = ""
		
		for line in str:gmatch("(.-)\n") do
			if included[line] then
			elseif line:find("#include") then
				local file = line:match("#include <(.-)>")
				file = file:gsub("SFML/", "")
				included[line] = true
				out = out .. parse_headers(read_header(file) or (" // missing header " .. file))
			elseif not line:find("#") then
				out = out .. line
			end
			
			out = out .. "\n"
		end
		
		return out
	end

	local function remove_definitions(str)
		str = str:gsub("CSFML_.- ", "")
		return str
	end

	local function remove_comments(str)
		str = str:gsub("//.-\n", "")
		return str
	end

	local function remove_whitespace(str)
		str = str:gsub("%s+", " ")
		str = str:gsub(";", ";\n")
		return str
	end
	
	function sfml.ParseHeader(header)
		local str = read_header(header) or ""
		local included = {}
	
		local out = parse_headers(str)
		out = remove_definitions(out)
		out = remove_comments(out)
		out = remove_whitespace(out)
		
		return out
	end
	
	sfml.headers = {}
	
	function sfml.DefineHeaders()
		for file_name in lfs.dir("../"..sfml.headers_path) do
			if file_name:find(".h", nil, true) then
				local header = sfml.ParseHeader(file_name)
				ffi.cdef(header)
				sfml.headers[file_name] = header
			end
		end
	end
end

function sfml.GenerateObjects()
	local objects = {}
	
	for file_name, header in pairs(sfml.headers) do
		for line in header:gmatch("(.-)\n") do
			if line:find("_create") then
				local type = line:match(".-(sf.-)%*")
				if type then
					type = type:sub(3)
					
					-- hack..
					local lib = file_name:gsub("%.h", ""):lower()
					if type == "Window" or type == "Context" then
						lib = "window"
					elseif type == "Thread" or type == "Mutex" or type == "Clock" then
						lib = "system"
					end
					
					local tbl = objects[type] or {ctors = {}, lib = lib, funcs = {}}
					local ctor = line:match("_createFrom(.-)%(")
					
					if ctor then
						table.insert(tbl.ctors, ctor)
					end
					
					objects[type] = tbl
				else
					--print(line)
				end
			end
		end
	end
	
	for type, data in pairs(objects) do	
		for file_name, header in pairs(sfml.headers) do
			for line in header:gmatch("(.-)\n") do
				if line:find(" sf" .. type .. "_") then
					local func_name = line:match(" (sf" .. type .. "_.-)%(")
					table.insert(data.funcs, func_name)
				end
			end
		end
	end
		
	for type, data in pairs(objects) do
		local META = {}
		META.__index = META
		
		local ctors = {}		
			
		_G[type] = function(typ, ...)
			local ctor = _G.type(typ) == "string" and typ:lower()
			
			if ctor then
				return ctors[ctor](...)
			elseif typ and ctors[""] then
				return ctors[""](typ, ...)
			else
				return ctors[""]()
			end
		end
		
		function META:__tostring()
			return ("%s [%p]"):format(type, self)
		end
		
		for _, func_name in pairs(data.funcs) do
			if func_name == "sf"..type.."_create" then
				ctors[""] = sfml.libraries[data.lib][func_name]
			end
			local name = func_name:gsub("sf"..type.."_", "")
			name = name:sub(1,1):upper() .. name:sub(2)
			META[name] = function(self, ...)
				return sfml.libraries[data.lib][func_name](self, ...)
			end
		end
		
		for _, ctor in pairs(data.ctors) do
			ctors[ctor:lower()] = sfml.libraries[data.lib]["sf"..type .. "_createFrom" .. ctor]
		end
		
		ffi.metatype("sf" .. type, META)
	end
end

sfml.LoadLibraries()
sfml.DefineHeaders()
sfml.GenerateObjects()