local window = _G.window or {}

window.wnd = window.wnd or NULL

setmetatable(window, {
	__index = function(s, key)
		if not s.wnd:IsValid() then print(key , "!!!!!!!!!!!!!") end
		if s.wnd[key] then
			return function(...)
				return s.wnd[key](s.wnd, ...)
			end
		else
			error("the key \"" .. key .. "\" does not exist in _G.window", 2)
		end
	end,
})

function window.Open(...)  
	if window.wnd:IsValid() then return end
	
	local wnd = render.CreateWindow(...)
	
	-- don't draw anything until the everything has be
	event.AddListenerX({
		event = "RenderContextInitialized", 
		unique = "window_start_rendering", 
		callback = function()
			function wnd:OnUpdate(dt)
				render.DrawScene(self, dt)
			end
			return e.EVENT_DESTROY
		end, 
		priority = -100000,
	})

	function wnd:OnCursorPos()
		if system then system.SetCursor(system.GetCursor()) end
	end
	
	local key_trigger = input.SetupInputEvent("Key")
	local mouse_trigger = input.SetupInputEvent("Mouse")
	
	local function ADD_EVENT(name, callback)
		local nice = name:sub(7)
		
		event.AddListener(name, "window_events", function(_wnd, ...) 
			if _wnd == wnd then
				event.Call(nice, ...)
				if callback then
					callback(...)
				end
			end
		end)
	end
	
	ADD_EVENT("WindowCharInput")
	ADD_EVENT("WindowKeyInput", key_trigger)
	ADD_EVENT("WindowMouseInput", mouse_trigger)
	ADD_EVENT("WindowKeyInputRepeat")
	
	
	local mouse_trigger = function(key, press) mouse_trigger(key, press) event.Call("MouseInput", key, press) end
	
	ADD_EVENT("WindowMouseScroll", function(x, y)
		if y ~= 0 then
			for i = 1, math.abs(y) do
				if y > 0 then
					mouse_trigger("mwheel_up", true)
				else
					mouse_trigger("mwheel_down", true)
				end
			end

			event.Delay(function()
				if y > 0 then
					mouse_trigger("mwheel_up", false)
				else
					mouse_trigger("mwheel_down", false)
				end
			end)
		end

		if x ~= 0 then	
			for i = 1, math.abs(x) do
				if x > 0 then
					mouse_trigger("mwheel_left", true)
				else
					mouse_trigger("mwheel_right", true)
				end
			end
			event.Delay(function()
				if x > 0 then
					mouse_trigger("mwheel_left", false)
				else
					mouse_trigger("mwheel_right", false)
				end
			end)
		end
	end)
	
	window.wnd = wnd
end

function window.IsOpen()
	return window.wnd:IsValid()
end

function window.Close()
	if window.wnd:IsValid() then
		window.wnd:Remove()
	end
end

local glfw = require("lj-glfw")

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

return window