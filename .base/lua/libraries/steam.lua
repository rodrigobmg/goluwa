local steam = _G.steam or {}

do 
	local ok, lib = pcall(ffi.load, "steamfriends")
	
	ffi.cdef[[
		const char *steamGetLastError();
		int steamInitialize();
		
		typedef struct
		{
			const char *text;
			const char *sender_steam_id;
			const char *receiver_steam_id;
		}message;
		
		message *steamGetLastChatMessage();
		int steamSendChatMessage(const char *steam_id, const char *text);
		const char *steamGetNickFromSteamID(const char *steam_id);
		const char *steamGetClientSteamID();
		unsigned steamGetFriendCount();
		const char *steamGetFriendByIndex(unsigned i);
	]] 
	
	if not ok then
		logn("steamfriends module not availible")
		lib = nil
	elseif lib.steamInitialize() == 1 then
		logn(ffi.string(lib.steamGetLastError()))
		lib = nil
	else
		timer.Thinker(function()
			local msg = lib.steamGetLastChatMessage()

			if msg ~= nil then
				local sender_steam_id = ffi.string(msg.sender_steam_id)
				local receiver_steam_id = ffi.string(msg.receiver_steam_id)
				local text = ffi.string(msg.text)
				
				event.Call("SteamFriendsMessage", sender_steam_id, text, receiver_steam_id)
			end
		end)
	end
	
	function steam.SendChatMessage(steam_id, text)
		if not lib then logn("steamfriends module not availible") return 1 end
		return lib.steamSendChatMessage(steam_id, text)
	end
	
	function steam.GetNickFromSteamID(steam_id)
		if not lib then logn("steamfriends module not availible") return "" end
		return ffi.string(lib.steamGetNickFromSteamID(steam_id))
	end
	
	function steam.GetClientSteamID()
		if not lib then logn("steamfriends module not availible") return "" end
		return ffi.string(lib.steamGetClientSteamID())
	end
	
	function steam.GetFriends()
		if not lib then logn("steamfriends module not availible") return {} end
		local out = {}
		
		for i = 1, lib.steamGetFriendCount() do
			table.insert(out, ffi.string(lib.steamGetFriendByIndex(i - 1)))
		end
		
		return out
	end
end

function steam.VDFToTable(str)
	str = str:gsub("//.-\n", "")
	
	str = str:gsub("(%b\"\"%s-)%[$(%S-)%](%s-%b{})", function(start, def, stop) 
		if def ~= "WIN32" then
			return ""
		end
		
		return start .. stop
	end) 
	
	str = str:gsub("(%b\"\"%s-)(%b\"\"%s-)%[$(%S-)%]", function(start, stop, def) 
		if def ~= "WIN32" then
			return ""
		end		
		return start .. stop
	end) 
	
	local tbl = {}
	
	for uchar in str:gmatch("([%z\1-\127\194-\244][\128-\191]*)") do
		tbl[#tbl + 1] = uchar
	end

	local in_string = false
	local capture = {}
	local no_quotes = false

	local out = {}
	local current = out
	local stack = {current}
	
	local key, val

	for i = 1, #tbl do
		local char = tbl[i]
			
		if (char == [["]] or (no_quotes and char:find("%s"))) and tbl[i-1] ~= "\\" then
			if in_string then
				
				if key then
					local val = table.concat(capture, "")
					
				
					if val:lower() == "false" then 
						val = false
					elseif val:lower() ==  "true" then
						val =  true
					else
						val = tonumber(val) or val
					end	
					
					if type(current[key]) == "table" then
						table.insert(current[key], val)
					elseif current[key] then
						current[key] = {current[key], val}
					else
						current[key] = val
					end
					
					key = nil
				else
					key = table.concat(capture, "")
				end
				
				in_string = false
				no_quotes = false
				capture = {}
			else
				in_string = true
			end
		else
			if in_string then
				table.insert(capture, char)
			elseif char == [[{]] then
				if key then
					table.insert(stack, current)
					current[key] = {}
					current = current[key]
					key = nil
				else
					return nil, "stack imbalance"
				end
			elseif char == [[}]] then
				current = table.remove(stack) or out
			elseif not char:find("%s") then
				in_string = true
				no_quotes = true
				table.insert(capture, char)
			end
		end
	end
	
	return out
end

do -- steam directories

	function steam.FindGamePaths(force_cache_update)
		steam.paths = {}

		if vfs.Exists(steam.cache_path) and not force_cache_update then
			steam.LoadGamePaths()
		else
			steam._Traverse(steam.GetInstallPath() .. "/SteamApps", function(path, mode, count)
				if mode == "file" and path:find("gameinfo.txt", -12, true) then
					local data = vfs.Read(path)
					
					if data then
						local name = data:match("game%s-\"([^\"]+)\"")
						local appid = data:match("SteamAppId%s-(%d+)")

						if name and appid then
							steam.paths[#steam.paths + 1] = {
								name = name,
								appid = appid,
								path = path:match("^(.-)/?[^/]*$")
							}
							
							logf("found %s with appid %s\n", name, appid)
													
							--table.sort(steam.paths)

							steam.SaveGamePaths()
						end
					end
				end
				if wait(1) then
					logf("found %i files..\n", count)
				end
			end)
		end
	end

	function steam.GetInstallPath()
		local path

		if WINDOWS then
			path = system.GetRegistryValue("CurrentUser/Software/Valve/Steam/SteamPath") or (X64 and "C:\\Program Files (x86)\\Steam" or "C:\\Program Files\\Steam")
		elseif LINUX then
			path = os.getenv("HOME") .. "/.local/share/Steam"
		end

		return lfs.symlinkattributes(path, "mode") and path or nil
	end

	function steam.GetLibraryFolders()
		local base = steam.GetInstallPath()
		
		local tbl = {base .. "/SteamApps/"}
			
		local config = steam.VDFToTable(assert(vfs.Read(base .. "/config/config.vdf", "r")))

		for key, path in pairs(config.InstallConfigStore.Software.Valve.Steam) do
			
			if key:find("BaseInstallFolder_") then
				table.insert(tbl, vfs.FixPath(path) .. "/SteamApps/")
			end
		end
		
		return tbl
	end

	function steam.GetGamePath(game)
		for _, dir in pairs(steam.GetLibraryFolders()) do
			local path = dir .. "common/" .. game .. "/"
			if vfs.IsDir(path) then
				return path
			end
		end
		
		return ""
	end
end

do -- server query
	local queries = {
		info = {
			request = {
				{val = 0x54, type = "byte"},
				{val = "Source Engine Query", type = "string"},
			},
			response = {
				{key = "Header", type = "byte", assert = 0x49}, -- Always equal to 'I' (0x49.)
				{key = "Protocol", type = "byte"}, -- Protocol version used by the server.
				{key = "Name", type = "string"}, -- Name of the server.
				{key = "Map", type = "string"}, -- Map the server has currently loaded.
				{key = "Folder", type = "string"}, -- Name of the folder containing the game files.
				{key = "Game", type = "string"}, -- Full name of the game.
				{key = "ID", type = "short"}, -- Steam Application ID of game.
				{key = "Players", type = "byte"}, -- Number of players on the server.
				{key = "MaxPlayers", type = "byte"}, -- Maximum number of players the server reports it can hold.
				{key = "Bots", type = "byte"}, -- Number of bots on the server.
				{key = "ServerType", type = "byte", translate = {d = "dedicated server", l = "non-dedicated server", p = "SourceTV relay (proxy)"}}, -- Indicates the type of server
				{key = "Environment", type = "byte", translate = {l = "Linux", w = "Windows", m = "Mac", o = "Mac"}}, -- Indicates the operating system of the server
				{key = "Visibility", type = "boolean"}, -- Indicates whether the server requires a password
				{key = "VAC", type = "boolean"}, -- Specifies whether the server uses VAC
				
				-- the ship
				{match = {ID = 2400}, key = "Mode", type = "byte", translate =  {[0] = "Hunt", [1] = "Elimination", [2] = "Duel", [3] = "Deathmatch", [4] = "VIP Team", [5] = "Team Ellimination"}},
				{match = {ID = 2400}, key = "Witnesses", type = "byte"}, -- The number of witnesses necessary to have a player arrested.
				{match = {ID = 2400}, key = "Duration", type = "byte"}, -- Time (in seconds) before a player is arrested while being witnessed
				
				{key = "Version", type = "string"}, -- Version of the game installed on the server.
				{key = "ExtraDataFlag", type = "byte"}, -- If present, this specifies which additional data fields will be included.
				
				{match = {ExtraDataFlag = function(num) return bit.band(num, 0x80) end}, key = "Port", type = "short"}, -- The server's game port number.
				{match = {ExtraDataFlag = function(num) return bit.band(num, 0x10) end}, key = "SteamID", type = "long"}, -- Server's SteamID.

				{match = {ExtraDataFlag = function(num) return bit.band(num, 0x40) end}, key = "Port", type = "short"}, -- Spectator port number for SourceTV.
				{match = {ExtraDataFlag = function(num) return bit.band(num, 0x20) end}, key = "Name", type = "string"}, -- Name of the spectator server for SourceTV.
				
				{match = {ExtraDataFlag = function(num) return bit.band(num, 0x01) end}, key = "Name", type = "long"}, -- The server's 64-bit GameID. If this is present, a more accurate AppID is present in the low 24 bits. The earlier AppID could have been truncated as it was forced into 16-bit storage.
			}
		},
		players = {
			challenge = true,
			request = {
				{val = 0x55, type = "byte"},
				{val = 0xFFFFFFFF, type = "long"},
			},
			response = {
				{key = "Header", type = "byte", assert = 0x44}, -- Always equal to 'D' (0x44.)
				{key = "Players", type = "byte", response = {
					{key = "Index", type = "byte"}, -- Index of player chunk starting from 0.
					{key = "Name", type = "string"}, -- Name of the player.
					{key = "Score", type = "long"}, -- Player's score (usually "frags" or "kills".)
					{key = "Duration", type = "long"}, -- Time (in seconds) player has been connected to the server.
				}}, -- Number of players whose information was gathered.
			}
		},
		rules = {
			challenge = true,
			request = {
				{val = 0x56, type = "byte"},
				{val = 0xFFFFFFFF, type = "long"},
			},
			response = {			
				{key = "Header", type = "byte", assert = 0x45}, -- Always equal to 'E' (0x45.)
				{key = "Rules", type = "short", response = {
					{key = "Name", type = "string"}, -- Name of the rule
					{key = "Value", type = "string"}, -- Value of the rule.
				}}, -- Number of rules in the response.
			}
		},
		ping = {
			request = {
				{val = 0x69, type = "byte"},
			},
			response = {
				{key = "Heading", type = "byte", assert = 0x6A}, -- Always equal to 'j' (0x6A)
				{key = "Payload", type = "string"}, -- '00000000000000'
			}
		},
	}

	local split_query = {
		response = {
			{key = "ID", type = "long"}, -- Same as the Goldsource server meaning. However, if the most significant bit is 1, then the response was compressed with bzip2 before being cut and sent. Refer to compression procedure below.
			{key = "Total", type = "byte"}, -- The total number of packets in the response.
			{key = "Number", type = "byte"}, -- The number of the packet. Starts at 0.
			{key = "Size", type = "short"}, -- (Orange Box Engine and above only.) Maximum size of packet before packet switching occurs. The default value is 1248 bytes (0x04E0), but the server administrator can decrease this. For older engine versions: the maximum and minimum size of the packet was unchangeable. AppIDs which are known not to contain this field: 215, 17550, 17700, and 240 when protocol = 7.
		}
	}

	local function write_request(buffer, request)
		for i, data in ipairs(request) do
			buffer:WriteType(data.val, data.type)
		end
	end
	 
	local function read_response(buffer, response)
		local out = {}
			
		for i, data in ipairs(response) do
		
			if data.match then
				local key, val = next(data.match)
				if (type(val) == "function" and not val(out[key])) or out[key] ~= val then
					goto continue
				end
			end
			
			local val
			
			if data.type == "byte" then
				val = buffer:ReadByte()
				if data.translate then
					val = data.translate[string.char(val)] or "nil"
				end
			else
				val = buffer:ReadType(data.type) 
			end  
			
			if data.assert then
				if val ~= data.assert then
					error("error in header, expected " .. data.type .. " " .. ("%X"):format(data.assert) .. " got " .. (type(val) == "number" and ("%X"):format(val) or type(val)))
				end
			end
						
			out[data.key] = val or "nil"
				
			if data.response then
				local tbl = {}
				out[data.key] = tbl			
				for i = 1, val do
					table.insert(tbl, read_response(buffer, data.response))
				end
			end
			
			::continue::
		end
		
		return out
	end

	local function query_server(ip, port, query, callback)
		callback = callback or table.print
			
		local socket = luasocket.Client("udp", ip, port)
		
		function socket:OnConnect()
			local buffer = Buffer()
			buffer:WriteLong(0xFFFFFFFF)
			write_request(buffer, query.request)
			--logn("sending: ", buffer:GetDebugString())
			socket:Send(buffer:GetString())
		end
		
		function socket:OnReceive(str)
			local buffer = Buffer(str)
			--logn("received: ", buffer:GetDebugString())
			
			local header = buffer:ReadLong()

			-- packet is split up
			if header == 0xFFFFFFFE then
				local info = read_response(buffer, split_query.response)
				
				if not self.buffer_chunks then
					self.buffer_size = buffer:ReadLong()
					self.buffer_crc32_sum = buffer:ReadLong()
					
					self.buffer_chunks = {}
				end
				
				self.buffer_chunks[info.Number + 1] = buffer:ReadRest()
				
				if table.count(self.buffer_chunks) - 1 == info.Total then
					callback(read_response(Buffer(table.concat(self.buffer_chunks)), query.response))
				end
			elseif query.challenge and not self.challenge then
				local type = buffer:ReadByte()
						
				if type == 0x41 then
					local challenge = buffer:ReadLong()
								
					local buffer = Buffer()
					buffer:WriteLong(0xFFFFFFFF)
					buffer:WriteByte(query.request[1].val)
					buffer:WriteLong(challenge)
					
					--logn("sending: ", buffer:GetDebugString())
					self:Send(buffer:GetString())
					
					self.challenge = challenge
				end
			else
				callback(read_response(buffer, query.response))
			end
		end
	end

	function steam.GetServerInfo(ip, port, callback)
		check(ip, "string")
		check(port, "number")
		
		query_server(ip, port, queries.info, callback)
	end

	function steam.GetServerPlayers(ip, port, callback)
		check(ip, "string")
		check(port, "number")
		
		query_server(ip, port, queries.players, callback)
	end

	function steam.GetServerRules(ip, port, callback)
		check(ip, "string")
		check(port, "number")
		
		query_server(ip, port, queries.rules, callback)
	end

	function steam.GetServerPing(ip, port, callback)	
		check(ip, "string")
		check(port, "number")
		
		callback = callback or logn
		local start = timer.clock()
		query_server(ip, port, queries.ping, function()
			callback(timer.clock() - start)
		end)
	end
end

return steam
