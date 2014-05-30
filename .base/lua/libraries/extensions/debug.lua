do 
	local started = {}	
	
	function debug.LogLibrary(library, filter, post_calls_only, lib_name) 
		lib_name = lib_name or ""
		
		if type(library) == "string" then
			lib_name = library
			library = _G[library]
		end
		
		local log_name = lib_name .. "_calls"
		
		if started[library] then
			for name, func in pairs(started[library]) do
				library[name] = func
			end
		else
			if type(filter) == "string" then
				filter = {filter}
			end
			
			filter = filter or {}
			
			for k,v in pairs(filter) do filter[v] = true end		
		
			started[library] = {}			
			
			local function log_return(...)		
				if not filter[name] then
					if post_calls_only or post_calls_only == nil then
						
						local ret = {}
						for i = 1, select("#", ...) do 
							table.insert(ret, serializer.GetLibrary("luadata").ToString((select(i, ...))))
						end
						
						if #ret == 0 then
							logn()
						else
							logn(table.concat(ret, ", "))
						end
					end
				end
				
				setlogfile()
				
				return ...
			end
			
			for name, func in pairs(library) do
				if type(func) == "function" then
					library[name] = function(...)
						setlogfile(log_name)
						
						if not post_calls_only and not filter[name] then
						
							local args = {}
							for i = 1, select("#", ...) do 
								table.insert(args, serializer.GetLibrary("luadata").ToString((select(i, ...)))) 
							end
							
							logf("%s.%s(%s) >> ", lib_name, name, table.concat(args, ", "))
						end

						return log_return(func(...))
					end
					
					started[library][name] = func
				end
			end
		end
	end

end

function debug.openscript(lua_script, line)
	local path = console.GetVariable("editor_path")
	
	if not path then return false end
	lua_script = R(lua_script)
	
	if not vfs.Exists(lua_script) then
		logf("debug.openscript: script %q doesn't exist\n", lua_script)
		return false
	end
	
	path = path:gsub("%%LINE%%", line)
	path = path:gsub("%%PATH%%", lua_script)
	
	os.execute(path)
	
	return true
end

function debug.openfunction(func, line)
	local info = debug.getinfo(func)
	if info.what == "Lua" then
		return debug.openscript(info.source:sub(2), line or info.linedefined)
	end
end

function debug.trace(skip_print)	
	local lines = {}
	
	for level = 1, math.huge do
		local info = debug.getinfo(level, "Sln")
		
		if info then
			lines[#lines + 1] = ("%i: Line %d\t\"%s\"\t%s"):format(level, info.currentline, info.name or "unknown", info.short_src or "")
		else
			break
		end
    end
	
		
	local str
	
	if debug.debugging then
		str = {}
		
		-- this doesn't really be long here..
		local stop = #lines
		
		for i = 2, #lines do
			if lines[i]:find("event") then
				stop = i - 2
			end
		end
		
		for i = 2, stop do
			table.insert(str, lines[i])
		end
	else
		str = lines
	end

	str = table.concat(str, "\n")
	
	if not skip_print then
		logn(str)
	end
	
	return str
end

function debug.getparams(func)
    local params = {}
	
	for i = 1, math.huge do
		local key = debug.getlocal(func, i)
		if key then
			table.insert(params, key)
		else
			break
		end
	end

    return params
end

function debug.getparamsx(func)
    local params = {}
	
	for i = 1, math.huge do
		local key, val = debug.getlocal(func, i)
		if key then
			table.insert(params, {key = key, val = val})
		else
			break
		end
	end

    return params
end

function debug.dumpcall(level, line, info_match)
	level = level + 1
	local info = debug.getinfo(level)
	local path = info.source:sub(2)
	local currentline = info.currentline
	
	if info_match and info.func ~= info_match.func then 
		return 
	end
	
	if info.source == "=[C]" then return end
	if info.source:find("ffi_binds") then return end
	if info.source:find("console%.lua") then return end
	if info.source:find("string%.lua") then return end
	if info.source:find("globals%.lua") then return end
	if info.source:find("strung%.lua") then return end
	if path == "../../../lua/init.lua" then return end
	
	local script = vfs.Read(path)
		
	if script then
		local lines = script:explode("\n")
		
		for i = -20, 20 do
			local line = lines[currentline + i]
			
			if line then
				line = line:gsub("\t", "  ")
				if i == 0 then
					line = (currentline + i) .. ":==>\t" ..  line
				else
					line = (currentline + i) .. ":\t" .. line
				end
				
				logn(line)
			else
				if i == 0 then
					line = (">"):rep(string.len(currentline)) .. ":"
				else
					line = (currentline + i) .. ":"
				end
				
				logn(line, " ", "This line does not exist. It may be due to inlining so try running jit.off()")
			end
		end
	end
	
	logn(path)
	
	
	logn("LOCALS: ")
	for _, data in pairs(debug.getparamsx(level+1)) do
		--if not data.key:find("(",nil,true) then
			local val
			
			if type(data.val) == "table" then
				val = tostring(data.val)
			elseif type(data.val) == "string" then
				val = data.val:sub(0, 10)
				
				if val ~= data.val then
					val = val .. " .. " .. utilities.FormatFileSize(#data.val)
				end
			else
				val = serializer.GetLibrary("luadata").ToString(data.val)
			end
			
			logf("%s = %s\n", data.key, val)
		--end
	end
	
	if info_match then
		print(info_match.func)
		print(info.func)
	end
	
	return true
end

function debug.logcalls(b, type)
	if not b then
		debug.sethook()
		return
	end
	
	type = type or "r"
	
	local hook

	hook = function() 
		debug.sethook()
		
		setlogfile("lua_calls")
			debug.dumpcall(2)
		setlogfile()
		
		debug.sethook(hook, type)
	end
	
	debug.sethook(hook, type)
end

function debug.stepin()
	if not console.curses then return end
	
	debug.debugging = true
	
	local first_time = true
	local curinfo

	local step
	
	step = function(mode, line)	
		console.ClearWindow()
		
		local ok = debug.dumpcall(2, line, curinfo)
		
		while ok do
			if first_time then
				first_time = false
				break
			end
					
			local key = console.GetActiveKey()			
			
			if key == "KEY_SPACE" then
				debug.debugging = false
				debug.sethook()
				console.ScrollLogHistory(1)
				break
			elseif key == "KEY_ENTER" then
				curinfo = nil
				debug.sethook(step, "r")
				break
			elseif key == "KEY_LEFT" then
				debug.sethook(step, "r")
				break
			elseif key == "KEY_RIGHT" then
				curinfo = nil
				debug.sethook(step, "l")
				break
			elseif key == "KEY_NPAGE" then
				curinfo = nil
				debug.sethook(step, "c")
				break
			elseif key == "KEY_DOWN" then
				curinfo = debug.getinfo(2) 
				debug.sethook(step, "l")				
				break
			end
		end
	end
	
	debug.sethook(step, "c")
end