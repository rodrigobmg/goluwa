local utf8 = {}

local math_floor = math.floor

-- a lot of this was taken from 
-- http://cakesaddons.googlecode.com/svn/trunk/glib/lua/glib/unicode/utf8.lua
-- and http://www.curse.com/addons/wow/utf8/546587

function utf8.byte(char, offset)
	if char == "" then return -1 end
	offset = offset or 1
	
	local byte = char:byte(offset)
	local length = 1
	if byte >= 128 then
		if byte >= 240 then
			-- 4 byte sequence
			length = 4
			if #char < 4 then return -1, length end
			byte = (byte % 8) * 262144
			byte = byte + (char:byte(offset + 1) % 64) * 4096
			byte = byte + (char:byte(offset + 2) % 64) * 64
			byte = byte + (char:byte(offset + 3) % 64)
		elseif byte >= 224 then
			-- 3 byte sequence
			length = 3
			if #char < 3 then return -1, length end
			byte = (byte % 16) * 4096
			byte = byte + (char:byte(offset + 1) % 64) * 64
			byte = byte + (char:byte(offset + 2) % 64)
		elseif byte >= 192 then
			-- 2 byte sequence
			length = 2
			if #char < 2 then return -1, length end
			byte = (byte % 32) * 64
			byte = byte + (char:byte(offset + 1) % 64)
		else
			-- invalid sequence
			byte = -1
		end
	end
	return byte, length
end

function utf8.char(byte)
	local utf8 = ""
	
	if byte <= 127 then
		utf8 = string.char(byte)
	elseif byte < 2048 then
		utf8 = ("%c%c"):format(
			192 + math_floor(byte / 64), 
			128 + (byte % 64)
		)
	elseif byte < 65536 then
		utf8 = ("%c%c%c"):format(
			224 + math_floor(byte / 4096),   
			128 + (math_floor(byte / 64) % 64),   
			128 + (byte % 64)
		)
	elseif byte < 2097152 then
		utf8 = ("%c%c%c%c"):format(
			240 + math_floor(byte / 262144), 
			128 + (math_floor(byte / 4096) % 64), 
			128 + (math_floor(byte / 64) % 64), 
			128 + (byte % 64)
		)
	end
	
	return utf8
end

function utf8.sub(str, i, j)
	j = j or -1

	local pos = 1
	local bytes = #str
	local length = 0

	-- only set l if i or j is negative
	local l = (i >= 0 and j >= 0) or utf8.length(str)
	local start_char = (i >= 0) and i or l + i + 1
	local end_char   = (j >= 0) and j or l + j + 1

	-- can't have start before end!
	if start_char > end_char then
		return ""
	end

	-- byte offsets to pass to string.sub
	local start_byte, end_byte = 1, bytes

	while pos <= bytes do
		length = length + 1

		if length == start_char then
			start_byte = pos
		end

		pos = pos + select(2, utf8.byte(str, pos))

		if length == end_char then
			end_byte = pos - 1
			break
		end
	end

	return str:sub(start_byte, end_byte)
end

local function utf8replace(str, mapping)
	local pos = 1
	local bytes = str:len()
	local char_bytes
	local new_str = ""

	while pos <= bytes do
		char_bytes = select(2, utf8.byte(str, pos))
		local c = str:sub(pos, pos + char_bytes - 1)

		new_str = new_str .. (mapping[c] or c)

		pos = pos + char_bytes
	end

	return new_str
end

local upper, lower = include("utf8data.lua")

function utf8.upper(str)
	return utf8replace(str, upper)
end

function utf8.lower(str)
	return utf8replace(str, lower)
end

function utf8.length(str)
	local _, length = str:gsub("[^\128-\191]", "")
	return length
end

function utf8.totable(str)
	local tbl = {}
	
	for uchar in str:gmatch("([%z\1-\127\194-\244][\128-\191]*)") do
		tbl[#tbl + 1] = uchar
	end
	
	return tbl
end

return utf8