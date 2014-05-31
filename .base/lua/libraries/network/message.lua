local message = _G.message or {}

message.Listeners = message.Listeners or {}

function message.AddListener(id, callback)
	message.Listeners[id] = callback
end

function message.RemoveListener(id)
	message.Listeners[id] = callback
end

if CLIENT then
	function message.Send(id, ...)
		network.SendMessageToServer(network.MESSAGE, id, ...)
	end
	
	function message.OnMessageReceived(id, ...)		
		if message.Listeners[id] then
			message.Listeners[id](...)
		end
	end

	event.AddListener("NetworkMessageReceived", "message", message.OnMessageReceived, print)
end

if SERVER then
	function message.Send(id, filter, ...)		
		if typex(filter) == "player" then
			network.SendMessageToClient(filter.socket, network.MESSAGE, id, ...)
		elseif typex(filter) == "player_filter" then
			for _, player in pairs(filter:GetAll()) do
				network.SendMessageToClient(player.socket, network.MESSAGE, id, ...)
			end
		else
			for key, ply in pairs(players.GetAll()) do
				network.SendMessageToClient(ply.socket, network.MESSAGE, id, ...)
			end
		end
	end
	
	function message.Broadcast(id, ...)
		return message.Send(id, nil, ...)
	end
	
	function message.OnMessageReceived(ply, id, ...)
		if message.Listeners[id] then
			message.Listeners[id](ply, ...)
		end
	end
	
	event.AddListener("NetworkMessageReceived", "message", message.OnMessageReceived, print)
end

do -- console extension
	message.server_commands = message.server_commands or {}
	
	local player = NULL
	
	function console.SetPlayer(ply)
		player = ply or NULL
	end
	
	function console.GetPlayer()
		return player
	end
	
	if SERVER then
		message.AddListener("scmd", function(ply, cmd, line, ...)
			local callback = message.server_commands[cmd]
			
			if callback then
				callback(ply, line, ...)
			end
		end)
	end

	function console.AddServerCommand(command, callback)
		message.server_commands[command] = callback
		
		if CLIENT then
			console.AddCommand(command, function(line, ...)
				message.Send("scmd", command, line, ...)
			end)
		end
		
		if SERVER then
			console.AddCommand(command, function(line, ...)
				callback(player, line, ...)
			end)
		end
	end
	
	function console.RemoveServerCommand(command)
		console.RemoveCommand(command)
		message.server_commands[command] = nil
	end

end

do -- event extension
	if CLIENT then
		message.AddListener("evtmsg", function(...)
			event.Call(...)
		end)
	end
	
	if SERVER then
		function event.CallOnClient(event, filter, ...)
			message.Send("evtmsg", filter, event, ...)
		end
		
		function event.BroadcastCall(event, ...)
			_G.event.CallOnClient(event, nil, ...)
		end
	end
end

return message