local profiler = _G.profiler or {}

profiler.data = profiler.data or {sections = {}, statistical = {}, trace_aborts = {}}
profiler.raw_data = profiler.raw_data or {sections = {}, statistical = {}, trace_aborts = {}}

local jit_profiler = require("jit.profile")
local jit_vmdef = require("jit.vmdef")
local jit_util = require("jit.util")

local blacklist = {
	["leaving loop in root trace"] = true,		
	["error thrown or hook called during recording"] = true,		
}

local function trace_dump_callback(what, trace_id, func, pc, trace_error_id, trace_error_arg)
	if what == "abort" then
		local info = jit_util.funcinfo(func, pc)
		table.insert(profiler.raw_data.trace_aborts, {info, trace_error_id, trace_error_arg})		
	end
end

local function parse_raw_trace_abort_data()
	local data = profiler.data.trace_aborts

	for i = 1, #profiler.raw_data.trace_aborts do
		local args = table.remove(profiler.raw_data.trace_aborts)
		
		local info = args[1]
		local trace_error_id = args[2]
		local trace_error_arg = args[3]
		
		local reason = jit_vmdef.traceerr[trace_error_id]
		
		if not blacklist[reason] then		
			if type(trace_error_arg) == "number" and reason:find("bytecode") then
				trace_error_arg = string.sub(jit_vmdef.bcnames, trace_error_arg*6+1, trace_error_arg*6+6)
				reason = reason:gsub("(%%d)", "%%s")
			end
			
			reason = reason:format(trace_error_arg)
				
			local path = info.source
			local line = info.currentline or info.linedefined
								
			data[path] = data[path] or {}
			data[path][line] = data[path][line] or {}
			data[path][line][reason] = (data[path][line][reason] or 0) + 1	
		end
	end
end

function profiler.EnableTraceAbortLogging(b)
	if b then
		jit.attach(trace_dump_callback, "trace")
	else
		jit.attach(trace_dump_callback)
	end
end

local function statistical_callback(thread, samples, vmstate)
	local str = jit_profiler.dumpstack(thread, "pl\n", 10)
	table.insert(profiler.raw_data.statistical, {str, samples})
end

local function parse_raw_statistical_data()
	local data = profiler.data.statistical

	for i = 1, #profiler.raw_data.statistical do
		local args = table.remove(profiler.raw_data.statistical)
		local str, samples = args[1], args[2]
		local children = {}
		
		for line in str:gmatch("(.-)\n") do
			local path, line_number = line:match("(.+):(%d+)")
			
			if not path and not line_number then
				line = line:gsub("%[builtin#(%d+)%]", function(x)
				  return jit_vmdef.ffnames[tonumber(x)]
				end)
								
				table.insert(children, {name = line or -1, external_function = true})
			else
				table.insert(children, {path = path, line = tonumber(line_number) or -1, external_function = false})
			end
		end
		
		local info = children[#children]
		table.remove(children, #children)
		
		local path = info.path or info.name
		local line = tonumber(info.line) or -1
				
		data[path] = data[path] or {}
		data[path][line] = data[path][line] or {total_time = 0, samples = 0, children = {}, parents = {}, ready = false, func_name = path}
		
		data[path][line].samples = data[path][line].samples + samples
		data[path][line].start_time = data[path][line].start_time or system.GetTime()	
		
		local parent = data[path][line]
				
		for _, info in ipairs(children) do
			local path = info.path or info.name
			local line = tonumber(info.line) or -1
				
			data[path] = data[path] or {}
			data[path][line] = data[path][line] or {total_time = 0, samples = 0, children = {}, parents = {}, ready = false, func_name = path}
			
			data[path][line].samples = data[path][line].samples + samples
			data[path][line].start_time = data[path][line].start_time or system.GetTime()	
			
			data[path][line].parents[tostring(parent)] = parent
			parent.children[tostring(data[path][line])] = data[path][line]
			
			--table.insert(data[path][line].parents, parent)
			--table.insert(parent.children, data[path][line])
		end
	end
end

function profiler.EnableStatisticalProfiling(b)		
	if b then	
		jit_profiler.start("l", function(...) 
			local ok, err = xpcall(statistical_callback, system.OnError, ...)
			if not ok then
				logn(err)
				profiler.StopStatisticalProfiling()
			end
		end)	
	else
		jit_profiler.stop()
	end
end

function profiler.Restart()
	profiler.data = {sections = {}, statistical = {}, trace_aborts = {}}
	profiler.raw_data = {sections = {}, statistical = {}, trace_aborts = {}}
end

do
	local data = profiler.data.sections
	
	local base_garbage = 0
	local stack = {}
	local enabled = false
	local i = 0
		
	function profiler.PushSection(section_name)
		if not enabled then return end
		
		local info = debug.getinfo(2)		
		local start_gc = collectgarbage("count")
		local start_time = system.GetTime()
				
		info.source = info.source:sub(2)
		
		table.insert(stack, {	
			section_name = section_name,
			start_gc = start_gc, 
			start_time = start_time, 
			info = info, 
			level = #stack,
		})
		
		collectgarbage("stop")
	end

	function profiler.PopSection()
		if not enabled then return end
		
		local res = table.remove(stack)
		
		if not res then return end
		
		local time = system.GetTime() - res.start_time
		local gc = ((collectgarbage("count") - res.start_gc) * 1024) - base_garbage
		
		collectgarbage("restart")
		
		local path, line = res.info.source, res.info.currentline
		
		if type(res.section_name) == "string" then line = res.section_name end
				
		if base_garbage == 0 then
			base_garbage = gc
			return
		end
		
		data[path] = data[path] or {}
		data[path][line] = data[path][line] or {total_time = 0, samples = 0, total_garbage = 0, name = res.section_name, section_name = res.section_name, instrumental = true, section = true}
	
		data[path][line].total_time = data[path][line].total_time + time
		data[path][line].total_garbage = data[path][line].total_garbage + gc
		data[path][line].samples = data[path][line].samples + 1
		data[path][line].level = res.level
		data[path][line].start_time = res.start_time
		data[path][line].i = i
		
		i = i + 1
				
		return time, gc
	end
	
	function profiler.RemoveSection(name)
		data[name] = nil
	end
	
	function profiler.EnableSectionProfiling(b, reset)
		enabled = b
		if reset then table.clear(data) end
	end
	
	profiler.PushSection()
	profiler.PopSection()
end

do -- timer
	local stack = {}

	function profiler.StartTimer(str, ...)
		table.insert(stack, {str = str:format(...), time = system.GetTime(), level = #stack})
	end
	
	function profiler.StopTimer(no_print)
		local time = system.GetTime()
		local data = table.remove(stack)
		local delta = time - data.time
		
		if not no_print then
			logf("%s%s: %s\n", (" "):rep(data.level-1), data.str, math.round(delta, 3))
		end
		
		return delta
	end
end

function profiler.GetBenchmark(type, file, dump_line)	
	
	if type == "statistical" then
	 	parse_raw_statistical_data()
	end

	local out = {}

	for path, lines in pairs(profiler.data[type]) do
		if not file or path:find(file) then
			for line, data in pairs(lines) do
				
				line = tonumber(line) or line
				
				local name = "unknown(file not found)"
				
				if data.func then					
					debug_info = debug.getinfo(data.func)
					
					-- remove some useless fields
					debug_info.source = nil
					debug_info.short_src = nil
					debug_info.currentline = nil
					debug_info.func = nil
				end
				
				if dump_line then
					local content = vfs.Read(path)
					
					if content then
						name = content:explode("\n")[line]
						if name then
							name = name:gsub("function ", "")
							name = name:trim()			
						end
					end
				elseif data.func then		
					name = ("%s(%s)"):format(data.func_name, table.concat(debug.getparams(data.func), ", "))
				else
					local full_path = R(path) or path
					full_path = full_path:replace("../../../", e.BASE_FOLDER)
					full_path = full_path:lower():replace(e.ROOT_FOLDER:lower(), "")
					name = full_path .. ":" .. line
				end
				
				if data.section_name then
					data.section_name = data.section_name:match(".+lua/(.+)") or data.section_name
				end
				
				name = name:trim()
					
				data.path = path
				data.file_name = path:match(".+/(.+)%.") or path
				data.line = line
				data.name = name
				data.debug_info = debug_info
				data.ready = true
				
				if data.total_time then
					data.average_time = data.total_time / data.samples
					data.total_time = data.total_time
				end
				
				if data.total_garbage and data.total_garbage > 0 then
					data.average_garbage = math.floor(data.total_garbage / data.samples)
					data.total_garbage = data.total_garbage
				else
					data.average_garbage = 0
				end
				
				data.start_time = data.start_time or 0
				data.samples = data.samples or 0
				
				data.sample_duration = system.GetTime() - data.start_time
				data.times_called = data.samples
							
				table.insert(out, data)
			end
		end
	end
	
	return out
end


function profiler.PrintTraceAborts(min_samples)
	min_samples = min_samples or 500
	
	parse_raw_statistical_data()
	parse_raw_trace_abort_data()
	
	logn("trace abort reasons for functions that were sampled by the profiler more than ", min_samples, " times:")
	
	for path, lines in pairs(profiler.data.trace_aborts) do		
		path = path:sub(2)
		
		local s = profiler.data.statistical
		
		if s[path] or not next(s) then			
			local full_path = R(path) or path
			full_path = full_path:replace("../../../", e.BASE_FOLDER)
			full_path = full_path:lower():replace(e.ROOT_FOLDER:lower(), "")
		
			local temp = {}
		
			for line, reasons in pairs(lines) do
				if not next(s) or s[path][line] and s[path][line].samples > min_samples then
					local str = "unknown line"
					
					local content, err = vfs.Read(path)
					
					if content then
						local lines = content:explode("\n")
						str = lines[line]
						str = "\"" .. str:trim() .. "\""
					else
						str = err
					end
								
					for reason, count in pairs(reasons) do
						table.insert(temp, "\t\t" .. reason:trim() .. " (x" .. count .. ")")
						table.insert(temp, "\t\t\t" .. line .. ": " .. str)
					end
				end
			end
			
			if #temp > 0 then
				logn("\t", full_path)
				logn(table.concat(temp, "\n"))
			end
		end
	end
end

function profiler.PrintSections()
	log(utility.TableToColumns(
		"sections",
		profiler.GetBenchmark("sections"), 
		{
			{key = "times_called", friendly = "calls"},
			{key = "name", tostring = function(val, column) return ("    "):rep(column.level - 1) .. tostring(val) end}, 
			{key = "average_time", friendly = "time", tostring = function(val) return math.round(val * 100 * 100, 3) end},
			{key = "average_garbage", friendly = "garbage", tostring = function(val) return utility.FormatFileSize(val) end},
		}, 
		function(a) return a.times_called > 50 end,
		"i"
	))
end

function profiler.PrintStatistical()
	log(utility.TableToColumns(
		"statistical",
		profiler.GetBenchmark("statistical"), 
		{
			{key = "name"}, 
			{key = "times_called", friendly = "percent", tostring = function(val, column, columns)  return math.round((val / columns[#columns].val.times_called) * 100, 2) end},
		}, 
		function(a) return a.name and a.times_called > 100 end,
		function(a, b) return a.times_called < b.times_called end
	))
end

function profiler.MeasureInstrumental(time, file_filter)
	profiler.EnableSectionProfiling(true, true)
	
	debug.sethook(function(what) 
		local info = debug.getinfo(2)
			
		if info.linedefined <= 0 or info.source:endswith("profiler.lua") then return end
		
		if file_filter and not info.source:find(file_filter, nil, true) then 
			return
		end
				
		if what == "call" then
			profiler.PushSection(info.source .. ":" .. info.linedefined)
		elseif what == "return" then
			profiler.PopSection()
		end
	end, "cr")

	event.Delay(time, function() 
		debug.sethook()
		
		log(utility.TableToColumns(
			"instrumental",
			profiler.GetBenchmark("sections"), 
			{
				{key = "times_called", friendly = "calls"},
				{key = "section_name"}, 
				{key = "average_time", friendly = "time", tostring = function(val) return math.round(val * 100 * 100, 3) end},
				{key = "average_garbage", friendly = "garbage", tostring = function(val) return utility.FormatFileSize(val) end},
			}, 
			function(a) return a.average_time > 0.0001 and (file_filter or a.times_called > 100) end,
			function(a, b) return a.average_time < b.average_time end
		))
		
		profiler.EnableSectionProfiling(false, true)
	end)
end

return profiler
