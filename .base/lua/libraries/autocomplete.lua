local autocomplete = _G.autocomplete or {}

do -- lists
	autocomplete.lists = autocomplete.lists or {}

	function autocomplete.RemoveList(id, list)
		for i, v in ipairs(autocomplete.lists) do
			if v.id == id then
				table.remove(autocomplete.lists, 1)
				return true
			end
		end	
	end
	
	function autocomplete.AddList(id, list)
		autocomplete.RemoveList(id)
		table.insert(autocomplete.lists, {id = id, list = list})
	end
	
	function autocomplete.GetList(id)
		for i, v in ipairs(autocomplete.lists) do
			if v.id == id then
				local list = v.list
				if type(list) == "function" then list = list() end
				return list
			end
		end	
	end

	function autocomplete.GetLists()
		return autocomplete.lists
	end
end

local function search(list, str, found, found_list)
	local pattern = "^.-" .. str
	
	if not pcall(string.find, pattern, pattern) then return found end

	if type(list) == "table" then
		if str == "" then
			for i = 1, 100 do
				found[#found + 1] = list[math.random(#list)]
			end			
		else
			for i = found_list and 1 or math.max(#str+1, 1), #list do
				if list[i]:find(pattern) then
					found[#found + 1] = list[i]
				end
			end
		end
	elseif type(list) == "function" then
		local v = list(str)
		if v then 
			found[#found + 1] = v
		end
	end
end

function autocomplete.Search(str, id)
	
	local found = {}
	
	-- check if it's a valid string pattern
	if not pcall(string.find, "", str) then return found end
	
	if type(id) == "string" then
		local list = autocomplete.GetList(id)
		search(list, str, found)
	elseif type(id) == "table" then
		search(id, str, found, true)
	else
		for i, data in ipairs(autocomplete.lists) do
			search(data.list, str, found)
		end
	end
		
	return found
end

function autocomplete.DrawFound(x, y, found, max, offset)
	offset = offset or 1
	max = max or 100
	
	surface.SetFont("default")
	surface.SetColor(1,1,1,1)
	
	surface.PushMatrix(x, y)
		for i = offset, max do
			local v = found[i]
			
			if not v then break end
			
			local w, h = surface.GetTextSize(v)
			local alpha = (-(i / max) + 1) ^ 15
			
			surface.SetAlphaMultiplier(alpha)
			surface.SetTextPos(5, (i-offset) * h)
			surface.DrawText(v)
		end
		
		surface.SetAlphaMultiplier(1)
	surface.PopMatrix()
end

function autocomplete.ScrollFound(found, offset)
	table.scroll(found, offset)
end

local env = {}

function autocomplete.Query(id, str, offset, list)
	if not env[id] then
		env[id] = {found_autocomplete = {}}
	end
	
	if not offset then
		if env[id].last_str and #env[id].last_str > #str then
			env[id].tab_str = nil
			env[id].tab_autocomplete = nil
			env[id].pause_autocomplete = false
		end	
	end

	if not env[id].pause_autocomplete then 
		env[id].found_autocomplete = autocomplete.Search(env[id].tab_str or str, env[id].tab_autocomplete or list or id)
		
		if #env[id].found_autocomplete == 0 then 
			env[id].pause_autocomplete = str 
		end
	else
		if #env[id].pause_autocomplete > #str then
			env[id].pause_autocomplete = false
		end
	end

	if offset then
		autocomplete.ScrollFound(env[id].tab_autocomplete or env[id].found_autocomplete, offset)
		
		if #env[id].found_autocomplete > 0 then 
			local out = env[id].found_autocomplete[1]
			if not env[id].tab_str then
				env[id].tab_str = str
				env[id].tab_autocomplete = env[id].found_autocomplete
			end
			env[id].last_str = str
			return out
		end
	end
end

return autocomplete