local window = _G.window or {}

window.wnd = window.wnd or NULL

setmetatable(window, {
	__index = function(s, key)
		if s.wnd:IsValid() and s.wnd[key] then
			return function(...)
				return s.wnd[key](s.wnd, ...)
			end
		end
	end,
})

function window.Open(...)  
	if window.wnd:IsValid() then return end
	
	local wnd = render.CreateWindow(...)
	
	window.wnd = wnd
	
	event.Call("WindowOpened", wnd)
end

function window.IsOpen()
	return window.wnd:IsValid()
end

function window.Close()
	if window.wnd:IsValid() then
		window.wnd:Remove()
	end
end

do -- I'm not sure if this belongs here..
	local glfw = require("lj-glfw") -- Window Manager

	function system.SetClipboard(str)
		if window.wnd:IsValid() then
			glfw.SetClipboardString(window.wnd.__ptr, str)
		end
	end

	function system.GetClipboard()
		if window.wnd:IsValid() then
			local str = glfw.GetClipboardString(window.wnd.__ptr)
			if str ~= nil then
				return ffi.string(str)
			end
		end
	end
	
	timer.SetSystemTimeClock(glfw.GetTime)
end

return window