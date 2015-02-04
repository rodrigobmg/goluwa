local vfs = (...) or _G.vfs

function vfs.Delete(path, ...)
	check(path, "string")
	local abs_path = vfs.GetAbsolutePath(path, ...)
	
	if abs_path then
		local ok, err = os.remove(abs_path)
		
		if not ok and err then
			warning(err)
		end
	end
	
	local err = ("No such file or directory %q"):format(path)
	
	warning(err)
	
	return false, "No such file or directory"
end

local function add_helper(name, func, mode, cb)
	vfs[name] = function(path, ...)
		check(path, "string")
		
		if cb then cb(path) end
		
		local file, err = vfs.Open(path, mode)
		
		if file then			
			local data = {file[func](file, ...)}
			
			file:Close()
			
			return unpack(data)
		end
			
		return file, err
	end
end

add_helper("Read", "ReadAll", "read")
add_helper("Write", "WriteBytes", "write", function(path) 
	if path:startswith("data/") then
		local fs = vfs.GetFileSystem("os")
		if fs then
			local dir = ""
			local base
			for folder in path:gmatch("(.-/)") do
				dir = dir .. folder
				base = base or vfs.GetAbsolutePath(dir)
				fs:CreateFolder({full_path = base .. dir:sub(#"data/"+1)})
			end
		end
	end
end)
add_helper("GetLastModified", "GetLastModified", "read")
add_helper("GetLastAccessed", "GetLastAccessed", "read")

function vfs.CreateFolder(path)
	check(path, "string")
	
	for i, data in ipairs(vfs.TranslatePath(path, true)) do	
		data.context:PCall("CreateFolder", data.path_info)
	end
end

function vfs.IsFolder(path)
	if path == "" then return false end
	
	for i, data in ipairs(vfs.TranslatePath(path, true)) do
		if data.context:PCall("IsFolder", data.path_info) then
			return true
		end
	end
	
	return false
end

function vfs.IsFile(path)
	if path == "" then return false end
	
	for i, data in ipairs(vfs.TranslatePath(path)) do	
		if data.context:PCall("IsFile", data.path_info) then
			return true
		end
	end
	
	return false
end

function vfs.Exists(path)
	return vfs.IsFolder(path) or vfs.IsFile(path)
end