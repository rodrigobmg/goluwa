include("string_anime.lua")

function string.readablehex(str)
	return (str:gsub("(.)", function(str) str = ("%X"):format(str:byte()) if #str == 1 then str = "0" .. str end return str .. " " end))
end

-- gsub doesn't seem to remove \0 

function string.removepadding(str, padding)
	padding = padding or "\0"
	
	local new = {}
	
	for i = 1, #str do
		local char = str:sub(i, i)
		if char ~= padding then
			table.insert(new, char)
		end
	end
	
	return table.concat(new)
end

function string.dumphex(str)
	local str = str:readablehex():lower():explode(" ")
	local out = {}
	
	for i, char in pairs(str) do
		table.insert(out, char)
		table.insert(out, " ")
		if i%16 == 0 then
			table.insert(out, "\n")
		end
		if i%16 == 4 or i%16 == 12 then 
			table.insert(out, " ")
		end
		if i%16 == 8 then 
			table.insert(out, "  ")
		end
		
	end
	table.insert(out, "\n")
	return table.concat(out)
end

function string.endswith(a, b)
	if type(b) == "table" then
		for k, b in pairs(b) do
			if a:sub(-#b) == b then
				return true
			end
		end
		
		return false
	end
	
	return a:sub(-#b) == b
end

function string.levenshtein(a, b)		
	local distance = {}
	
	for i = 0, #a do
	  distance[i] = {}
	  distance[i][0] = i
	end

	for i = 0, #b do
	  distance[0][i] = i
	end
	
	local str1 = utf8.totable(a)
	local str2 = utf8.totable(b)
	
	for i = 1, #a do
		for j = 1, #b do				
			distance[i][j] = math.min(
				distance[i-1][j] + 1, 
				distance[i][j-1] + 1, 
				distance[i-1][j-1] + (str1[i-1] == str2[j-1] and 0 or 1)
			)
		end
	end
	
	return distance[#a][#b]
end

function string.lengthsplit(str, len)
	if #str > len then
		local tbl = {}
		
		local max = math.floor(#str/len)
		local leftover = #str - (max * len)
		
		for i = 0, max do
			
			local left = i * len + 1
			local right = (i * len) + len
			local res = str:sub(left, right)
			
			if res ~= "" then
				table.insert(tbl, res)
			end
		end
		
		return tbl
	end
	
	return {str}
end

function string.getchartype(char)

	if char:find("%p") and char ~= "_" then
		return "punctation"
	elseif char:find("%s") then
		return "space"
	elseif char:find("%d") then
		return "digit"
	elseif char:find("%a") or char == "_" then
		return "letters"
	end
	
	return "unknown"
end

local types = {
	"%a",
	"%c",
	"%d",
	"%l",
	"%p",
	"%u",
	"%w",
	"%x",
	"%z",
}

function string.charclass(char)
	for i, v in ipairs(types) do
		if char:find(v) then
			return v
		end
	end
end

function string.safeformat(str, ...)	
	str = str:gsub("%%(%d+)", "%%s")
	local count = select(2, str:gsub("(%%)", ""))
	
	if count == 0 then	
		return table.concat({str, ...}, "")
	end
	
	local copy = {}
	for i = 1, count do
		table.insert(copy, tostringx(select(i, ...)))
	end
	return string.format(str, unpack(copy))
end

function string.findsimple(self, find)
	return self:find(find, nil, true) ~= nil
end

function string.findsimplelower(self, find)
	return self:lower():find(find:lower(), nil, true) ~= nil
end

function string.compare(self, target)
	return
		self == target or
		self:findsimple(target) or
		self:lower() == target:lower() or
		self:findsimplelower(target)
end

function string.trim(self, char)
    char = char or "%s"
    return (self:gsub("^"..char.."*(.-)"..char.."*$", "%1" ))
end

function string.getchar(self, pos)
	return string.sub(self, pos, pos)
end

function string.getbyte(self, pos)
	return self:getchar(pos):byte() or 0
end

--local cache = {}

function string.explode(self, sep, pattern)
	sep = sep or ""
	pattern = pattern or false
	
	--cache[self] = cache[self] or {}
	--cache[self][sep] = cache[self][sep] or {}
	
	--if cache[self][sep][pattern] then
	---	return table.copy(cache[self][sep][pattern])
	--end
	
	if sep == "" then
		local tbl = {}
		local i = 1
		for char in self:gmatch(".") do
			tbl[i] = char
			i=i+1
		end
		--cache[self][sep][pattern] = tbl
		return tbl
	end

	local tbl = {}
	local i, last_pos = 1,1
	local new_sep = sep

	if not pattern then
		new_sep = new_sep:gsub("[%-%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
	end

	for start_pos, end_pos in self:gmatch("()"..new_sep.."()") do
		tbl[i] = self:sub(last_pos, start_pos-1)
		last_pos = end_pos
		i=i+1
	end

	tbl[i] = self:sub(last_pos)

	--cache[self][sep][pattern] = tbl
	
	return tbl
end

function string.count(self, pattern)
	return select(2, self:gsub(pattern, ""))
end

function string.containsonly(self, pattern)
	return self:gsub(pattern, "") == ""
end

function string.replace(self, a, b)
	local tbl = self:explode(a)
	local out = ""
	
	if #tbl > 1 then
		for i = 1, #tbl - 1 do
			out = out .. tbl[i] .. b
		end
		
		out = out .. tbl[#tbl]
		
		return out
	end
	
	return self
end