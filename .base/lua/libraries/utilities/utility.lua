local utility = _G.utility or {}

include("mesh.lua", utility)
include("packed_rectangle.lua", utility)


local diffuse_suffixes = {
	"_diff",
	"_d",
}

function utility.FindTextureFromSuffix(path, ...)
	path = path:lower()
	
	local suffixes = {...}

	-- try to find the normal texture
	for _, suffix in pairs(suffixes) do
		local new = path:gsub("(.+)(%.)", "%1" .. suffix .. "%2")
		
		if new ~= path and vfs.Exists(new) then
			return new
		end
	end
	
	-- try again without the __diff suffix
	for _, diffuse_suffix in pairs(diffuse_suffixes) do
		for _, suffix in pairs(suffixes) do
			local new = path:gsub(diffuse_suffix .. "%.", suffix ..".")
			
			if new ~= path and vfs.Exists(new) then
				return new
			end
		end
	end
end

function utility.CreateWeakTable()
	return setmetatable({}, {__mode = "kv"})
end

function utility.TableToColumns(title, tbl, columns, check, sort_key)
	local top = {}
	
	for k, v in pairs(tbl) do
		if not check or check(v) then
			table.insert(top, {key = k, val = v})
		end
	end
	
	if type(sort_key) == "function" then
		table.sort(top, function(a, b)
			return sort_key(a.val, b.val)
		end)
	else
		table.sort(top, function(a, b)
			return a.val[sort_key] > b.val[sort_key]
		end)
	end

	local max_lengths = {}
	local temp = {}
	
	for i, column in ipairs(top) do
		for key, data in ipairs(columns) do
			data.tostring = data.tostring or function(...) return ... end
			data.friendly = data.friendly or data.key
			
			max_lengths[data.key] = max_lengths[data.key] or 0
			
			local str = tostring(data.tostring(column.val[data.key], column.val, top))
			column.str = column.str or {}
			column.str[data.key] = str
			
			if #str > max_lengths[data.key] then
				max_lengths[data.key] = #str
			end			
			
			temp[key] = data
		end
	end
	
	columns = temp
	
	local width = 0
		
	for k,v in pairs(columns) do 		
		if max_lengths[v.key] > #v.friendly then 
			v.length = max_lengths[v.key]
		else 
			v.length = #v.friendly + 1
		end 
		width = width + #v.friendly + max_lengths[v.key] - 2 
	end
	
	local out = " "
		
	out = out .. ("_"):rep(width - 1) .. "\n"
	out = out .. "|" .. (" "):rep(width / 2 - math.floor(#title / 2)) .. title .. (" "):rep(math.floor(width / 2) - #title + math.floor(#title / 2)) .. "|\n"
	out = out .. "|" .. ("_"):rep(width - 1) .. "|\n"

	for k,v in ipairs(columns) do 
		out = out .. "| " .. v.friendly .. ": " .. (" "):rep(-#v.friendly + max_lengths[v.key] - 1)  -- 2 = : + |
	end 
	out = out .. "|\n"
	
	
	for k,v in ipairs(columns) do 
		out = out .. "|" .. ("_"):rep(v.length + 2) 
	end 
	out = out .. "|\n"
	
	for k,v in ipairs(top) do 
		for _,column in ipairs(columns) do 
			out = out .. "| " .. v.str[column.key] .. (" "):rep(-#v.str[column.key] + column.length + 1) 
		end 
		out = out .. "|\n"
	end 
	
	out = out .. "|"
	
	out = out .. ("_"):rep(width-1) .. "|\n"


	return out
end

-- thread
do
	local META = metatable.CreateTemplate("thread")
	
	metatable.GetSet(META, "Frequency", 0)
	metatable.GetSet(META, "IterationsPerTick", 0)
	 
	META.wait = 0
	 
	function META:Start()
		local co = coroutine.create(function(...) return select(2, xpcall(self.OnStart, system.OnError, ...)) end)

		event.CreateThinker(function()
			if not self:IsValid() then return false end -- removed
			
			local time = timer.GetSystemTime()

			if next(self.progress) then
				for k, v in pairs(self.progress) do	
					if v.i < v.max then 
						if not v.last_print or v.last_print < time then
							logf("%s %s progress: %s\n", self, k, self:GetProgress(k))
							v.last_print = time + 1
						end
					end
				end
			end
						
			if time > self.wait then
				local ok, res, err = coroutine.resume(co, self)
				
				if coroutine.status(co) == "dead" then
					self:OnUpdate()
					self:OnFinish(res)
					return false
				end
				
				if ok == false and res then				
					if self.OnError then
						self:OnError(res)
					else
						logf("%s internal error: %s\n", self, res)
					end
				elseif ok and res == false and err then
					if self.OnError then
						self:OnError(err)
					else
						logf("%s user error: %s\n", self, err)
					end
				else
					self:OnUpdate()
				end
				
				return res
			end
		end, (self.Frequency > 0 and 1/self.Frequency) or (self.IterationsPerTick > 0 and self.IterationsPerTick), self.Frequency > 0, true)
	end
	 
	function META:Sleep(sec)
		if sec then self.wait = timer.GetSystemTime() + sec end
		coroutine.yield()
	end
	
	function META:OnStart()
		return false, "run function not defined"
	end
	
	function META:OnFinish()
		
	end
	
	function META:OnUpdate()
	
	end
	
	function META:Report(what)
		if not self.last_report or self.last_report < timer.GetSystemTime() then
			logf("%s report: %s\n", self, what)
			self.last_report = timer.GetSystemTime() + 1
		end
	end
	
	META.progress = {}
	
	function META:ReportProgress(what, max)
		self.progress[what] = self.progress[what] or {}
		self.progress[what].i = (self.progress[what].i or 0) + 1
		self.progress[what].max = max or 100
	end
	
	function META:GetProgress(what)
		if self.progress[what] then
			return ("%.2f%%"):format(math.round((self.progress[what].i / self.progress[what].max) * 100, 3))
		end
		
		return "0%"
	end
	
	function utility.CreateThread()
		local self = metatable.CreateObject(META)
		
		return self
	end
	
	if RELOAD then 
		local thread = utility.CreateThread()
		
		function thread:OnStart()
			for i = 1, 1000 do
				self:ReportProgress("first iteration", 1000)
				self:Sleep(0.01)
			end
			
			return "woho"
		end
		
		function thread:OnFinish(...)
			print(...)
		end
		 
		thread:SetIterationsPerTick(10)
		thread:Start()
	end
end

do -- tree
	local META = metatable.CreateTemplate("tree")

	function META:SetEntry(str, value)		
		local keys = type(str) == "table" and str or str and str:explode(self.delimiter) or {}
		
		local next = self.tree
				
		for i, key in ipairs(keys) do
			if key ~= "" then
				if not next[key] then
					next[key] = {}
				end
				next = next[key]
			end
		end
		
		next.key = str
		next.value = value
	end

	function META:GetEntry(str)		
		local keys = type(str) == "table" and str or str and str:explode(self.delimiter) or {}
				
		local next = self.tree
		
		for i, key in ipairs(keys) do
			if key ~= "" then
				if not next[key] then
					error("key ".. key .." not found")
				end
				next = next[key]
			end
		end
		
		return next.value
	end
	
	function META:GetChildren(str)		
		local keys = type(str) == "table" and str or str and str:explode(self.delimiter) or {}
		local next = self.tree
		
		for i, key in ipairs(keys) do
			if key ~= "" then
				if not next[key] then
					error("not found")
				end
				next = next[key]
			end
		end
				
		return next
	end

	function utility.CreateTree(delimiter)
		local self = metatable.CreateObject(META)
		
		self.tree = {}	
		self.delimiter = delimiter
		
		return self
	end
end

function utility.TableToFlags(flags, valid_flags)
	if type(flags) == "string" then
		flags = {flags}
	end
	
	local out = 0
	
	for k, v in pairs(flags) do
		local flag = valid_flags[v] or valid_flags[k]
		if not flag then 
			error("invalid flag", 2) 
		end
		out = bit.band(out, flag)
	end
	
	return out
end

function utility.FlagsToTable(flags, valid_flags)

	if not flags then return valid_flags.default_valid_flag end
	
	local out = {}
	
	for k, v in pairs(valid_flags) do
		if bit.band(flags, v) > 0 then
			out[k] = true
		end
	end
	
	return out
end

do -- long long
	ffi.cdef [[
	  typedef union {
		char b[8];
		int64_t i;
	  } buffer_int64;
	]]

	local btl = ffi.typeof("buffer_int64")
	
	function utility.StringToLongLong(str)
		return btl(str).i
	end
end

do -- find value
	local found =  {}
	local done = {}

	local skip =
	{
		UTIL_REMAKES = true,
		ffi = true,
	}

	local keywords =
	{
		AND = function(a, func, x,y) return func(a, x) and func(a, y) end	
	}

	local function args_call(a, func, ...)
		local tbl = {...}
		
		for i = 1, #tbl do
			local val = tbl[i]
			
			if not keywords[val] then
				local keyword = tbl[i+1]
				if keywords[keyword] and tbl[i+2] then
					local ret = keywords[keyword](a, func, val, tbl[i+2])
					if ret ~= nil then
						return ret
					end
				else
					local ret = func(a, val)
					if ret ~= nil then
						return ret
					end
				end
			end
		end
	end

	local function strfind(str, ...)
		return args_call(str, string.compare, ...) or args_call(str, string.find, ...)
	end

	local function find(tbl, name, dot, level, ...)
		if level >= 3 then return end
			
		for key, val in pairs(tbl) do	
			local T = type(val)
			key = tostring(key)
				
			if not skip[key] and T == "table" and not done[val] then
				done[val] = true
				find(val, name .. "." .. key, dot, level + 1, ...)
			else
				if (T == "function" or T == "number") and strfind(name .. "." .. key, ...) then					
					
					local nice_name
					
					if type(val) == "function" then
						local params = debug.getparams(val)
						
						if dot == ":" and params[1] == "self" then
							table.remove(params, 1)
						end
					
						nice_name = ("%s%s%s(%s)"):format(name, dot, key, table.concat(params, ", "))
					else
						nice_name = ("%s = %s"):format(key, val)
					end
				
					if name == "_G" or name == "_M" then
						table.insert(found, {key = key, val = val, name = name, nice_name = nice_name})
					else
						name = name:gsub("_G%.", "")
						name = name:gsub("_M%.", "")
						table.insert(found, {key = ("%s%s%s"):format(name, dot, key), val = val, name = name, nice_name = nice_name})
					end
				end
			end
		end
	end

	function utility.FindValue(...)		
		found = {}
		done = 
		{
			[_G] = true,
			[package] = true,
			[_OLD_G] = true,
		}
			
		find(_G, "_G", ".", 1, ...)
		find(metatable.GetAllRegistered(), "_M", ":", 1, ...)
		for cmd, v in pairs(console.GetCommands()) do
			if strfind(cmd, ...) then
				local arg_line = table.concat(debug.getparams(v.callback), ", ")
				arg_line = arg_line:gsub("line, ", "")
				arg_line = arg_line:gsub("line", "")
				
				table.insert(found, {key = cmd, val = v.callback, name = ("console.GetCommands().%s.callback"):format(cmd), nice_name = ("command->%s(%s)"):format(cmd, arg_line)})
			end
		end
		
		table.sort(found, function(a, b) 
			return #a.key < #b.key
		end)
		
		return found
	end
end

do -- thanks etandel @ #lua!
	function utility.SetGCCallback(t, func)
		func = func or t.Remove
		
		if not func then 
			error("could not find remove function", 2)
		end
		
		if ffi then
			local ud = t.__gc or ffi.new("char[1]")
						
			ffi.gc(ud, function()
				if not t.IsValid or t:IsValid() then
					return func(t) 
				end
			end)
			
			t.__gc = ud
		else
			local ud = t.__gc or newproxy(true)
			
			debug.getmetatable(ud).__gc = function() 
				if not t.IsValid or t:IsValid() then
					return func(t) 
				end
			end
			
			t.__gc = ud  
		end

		return t
	end
end

do
	-- http://cakesaddons.googlecode.com/svn/trunk/glib/lua/glib/stage1.lua
	local size_units = 
	{ 
		"B", 
		"KiB", 
		"MiB", 
		"GiB", 
		"TiB", 
		"PiB", 
		"EiB", 
		"ZiB", 
		"YiB" 
	}
	function utility.FormatFileSize(size)
		local unit_index = 1
		
		while size >= 1024 and size_units[unit_index + 1] do
			size = size / 1024
			unit_index = unit_index + 1
		end
		
		return tostring(math.floor(size * 100 + 0.5) / 100) .. " " .. size_units[unit_index]
	end
end

function utility.SafeRemove(obj, gc)
	if hasindex(obj) then
		
		if obj.IsValid and not obj:IsValid() then return end
		
		if type(obj.Remove) == "function" then
			obj:Remove()
		elseif type(obj.Close) == "function" then
			obj:Close()
		end
		
		if gc and type(obj.__gc) == "function" then
			obj:__gc()
		end
	end
end

function utility.RemoveOldObject(obj, id)
	
	if hasindex(obj) and type(obj.Remove) == "function" then
		UTIL_REMAKES = UTIL_REMAKES or {}
			
		id = id or (debug.getinfo(2).currentline .. debug.getinfo(2).source)
		
		if typex(UTIL_REMAKES[id]) == typex(obj) then
			UTIL_REMAKES[id]:Remove()
		end
		
		UTIL_REMAKES[id] = obj
	end
	
	return obj
end

function utility.GetCurrentPath(level)
	return (debug.getinfo(level or 1).source:gsub("\\", "/"):sub(2):gsub("//", "/"))
end

function utility.GeFolderFromPath(str)
	str = str or utility.GetCurrentPath()
	return str:match("(.+/).+") or ""
end

function utility.GetParentFolder(str, level)
	str = str or utility.GetCurrentPath()
	return str:match("(.*/)" .. (level == 0 and "" or (".*/"):rep(level or 1))) or ""
end

function utility.GetFolderNameFromPath(str)
	str = str or utility.GetCurrentPath()
	if str:sub(#str, #str) == "/" then
		str = str:sub(0, #str - 1)
	end
	return str:match(".+/(.+)") or ""
end

function utility.GetFileNameFromPath(str)
	str = str or utility.GetCurrentPath()
	return str:match(".+/(.+)") or ""
end

function utility.GetExtensionFromPath(str)
	str = str or utility.GetCurrentPath()
	return str:match(".+%.(%a+)")
end

function utility.GetFolderFromPath(self)
	return self:match("(.*)/") .. "/"
end

function utility.GetFileFromPath(self)
	return self:match(".*/(.*)")
end

do 
	local hooks = {}

	function utility.SetFunctionHook(tag, tbl, func_name, type, callback)
		local old = hooks[tag] or tbl[func_name]
		
		if type == "pre" then
			tbl[func_name] = function(...)
				local args = {callback(old, ...)}
				
				if args[1] == "abort_call" then return end
				if #args == 0 then return old(...) end
				
				return unpack(args)
			end
		elseif type == "post" then
			tbl[func_name] = function(...)
				local args = {old(...)}
				if callback(old, unpack(args)) == false then return end
				return unpack(args)
			end
		end
		
		return old
	end
	
	function utility.RemoveFunctionHook(tag, tbl, func_name)
		local old = hooks[tag]
		
		if old then
			tbl[func_name] = old
			hooks[tag] = nil
		end
	end
end

do -- header parse
	local directories

	local function read_file(path)
		for _, dir in pairs(directories) do
			local str = vfs.Read(dir .. path)
			if str then
				return str
			end
		end
		
		for _, dir in pairs(directories) do
			local str = vfs.Read(dir .. path .. ".in")
			if str then
				return str
			end
		end
	end
	
	local macros = {}
	
	local function process_macros(str)
		for line in str:gmatch("(.-\n)") do
			if line:find("#") then
				local type = line:match("#%s-([%l%d_]+)()")
			
				print(type, line)
			end
		end
		
		return str
	end

	local included = {}

	local function process_include(str)
		local out = ""
		
		for line in str:gmatch("(.-\n)") do
			if not included[line] then
				if line:find("#include") then
					included[line] = true
					
					local path = line:match("%s-#include.-<(.-)>")
					
					if path then
						local content = read_file(path)
						
						if content then
							out = out .. "// HEADER: " .. path .. ";"
							out = out .. process_include(content)
						else
							out = out .. "// missing header " .. path .. ";"
						end
					end
				else 
					out = out .. line
				end
			end
			
			out = out
		end
		
		return out
	end

	local function remove_comments(str)
		str = str:gsub("/%*.-%*/", "")
		
		return str
	end

	local function remove_whitespace(str)
		str = str:gsub("%s+", " ")
		str = str:gsub(";", ";\n")
		
		return str
	end

	local function solve_definitions(str)
		local definitions = {}
		
		str = str:gsub("\\%s-\n", "")
		
		for line in str:gmatch("#define(.-)\n") do
			local key, val = line:match("%s-(%S+)%s-(%S+)")
			if key and val then
				definitions[key] = tonumber(val)
			end
		end
		 
		return str, definitions
	end
	 
	local function solve_typedefs(str)
		
		local typedefs = {}
			
		for line in str:gmatch("typedef(.-);") do
			if not line:find("enum") then
				local key, val = line:match("(%S-)%s-(%S+)$")
				if key and val then
					typedefs[key] = val
				end
			end
		end 
		
		return str, typedefs
	end

	local function solve_enums(str)
		local enums = {}
		
		for line in str:gmatch("(.-)\n") do

			if line:find("enum%s-{") then
				local i = 0
				local um = line:match(" enum {(.-)}")
				if not um then print(line) end
				for enum in (um .. ","):gmatch(" (.-),") do
					if enum:find("=") then
						local left, operator, right = enum:match(" = (%d) (.-) (%d)")
						enum = enum:match("(.-) =")
						if not operator then
							enums[enum] = enum:match(" = (%d)")
						elseif operator == "<<" then
							enums[enum] = bit.lshift(left, right)
						elseif operator == ">>" then
							enums[enum] = bit.rshift(left, right)
						end
					else
						enums[enum] = i
						i = i + 1
					end
				end
			end
		end
		
		return str, enums
	end

	function utility.ParseHeader(path, directories_)
		directories = directories_

		local header, definitions, typedefs, enums

		header = read_file(path)

		header = process_macros(header)
		header = process_include(header)
		header = remove_comments(header)
		header = remove_whitespace(header)
		 
		header, definitions = solve_definitions(header)
		header, typedefs = solve_typedefs(header)
		header, enums = solve_enums(header)
		
		return {
			header = header, 
			definitions = definitions, 
			typedefs = typedefs, 
			enums = enums,
		}
	end
end

return utility