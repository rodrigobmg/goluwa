local sockets = (...) or _G.sockets

local sck = sockets.sockets.udp()

function sockets.SendUDPData(ip, port, str)

	if not str and type(port) == "string" then
		str = port
		port = tonumber(ip:match(".-:(.+)"))
	end

	local ok, msg = sck:sendto(str, ip, port)

	if ok then
		sockets.DebugPrint(nil, "SendUDPData sent data to %s:%i (%s)", ip, port, str:readablehex())
	else
		sockets.DebugPrint(nil, "SendUDPData failed %q", msg)
	end

	return ok, msg
end