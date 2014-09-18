local gl = require("lj-opengl") -- OpenGL
local sdl = require("lj-sdl") -- window manager

local render = (...) or _G.render

function timer.GetSystemTime()
	return tonumber(sdl.GetTicks()) / 1000
end

do -- lol
	local glfw = require("lj-glfw") -- window manager

	function timer.GetSystemTime()
		return glfw.GetTime()
	end
end

do -- window meta
	local META = metatable.CreateTemplate("render_window")

	function META:Remove()
		if self.OnRemove then self:OnRemove() end
		event.RemoveListener("OnUpdate", self)
		
		sdl.DestroyWindow(self.__ptr)
		render.sdl_windows[self.sdl_window_id] = nil
		
		metatable.MakeNULL(self)
	end

	local x = ffi.new("int[1]")
	local y = ffi.new("int[1]")
	
	function META:GetSize()
		sdl.GetWindowSize(self.__ptr, x, y)
		return Vec2(x[0], y[0])
	end
		
	function META:SetSize(pos)
		sdl.SetWindowSize(self.__ptr, pos:Unpack())
	end

	function META:SetTitle(title)
		sdl.SetWindowTitle(self.__ptr, title)
	end
	
	local x, y = ffi.new(sdl and "int[1]" or "double[1]"), ffi.new(sdl and "int[1]" or "double[1]")
	
	function META:GetMousePos()
		sdl.GetMouseState(x, y)
		return Vec2(x[0], y[0])
	end

	function META:SetMousePos(pos)
		sdl.WarpMouseInWindow(self.__ptr, pos:Unpack())
	end

	function META:HasFocus()
		return self.focused
	end
	
	function META:ShowCursor(b)
		sdl.ShowCursor(b and 1 or 0)
		self.cursor_visible = b
	end	
	
	function META:IsCursorVisible()
		return self.cursor_visible
	end

	function META:SetMouseTrapped(b)
		self.mouse_trapped = b
		
		sdl.SetWindowGrab(self.__ptr, b and 1 or 0)
		sdl.ShowCursor(sdl.e.SDL_DISABLE)
		sdl.SetRelativeMouseMode(b and 1 or 0)
	end
		
	function META:GetMouseDelta()
		return self.mouse_delta or Vec2()
	end
		 
	function META:UpdateMouseDelta()	
		local pos = self:GetMousePos()
	
		if self.last_mpos then
			self.mouse_delta = (pos - self.last_mpos)
		end
				
		self.last_mpos = pos
	end
	
	function META:MakeContextCurrent()
		sdl.GL_MakeCurrent(self.__ptr, self.context) 
	end
	
	function META:SwapBuffers()
		sdl.GL_SwapWindow(self.__ptr)
	end
	
	function META:SwapInterval(b)
		sdl.GL_SetSwapInterval(b and 1 or 0)
	end

	function META:OnUpdate(delta)
		
	end
	
	function META:OnFocus(focused)
		
	end
	
	function META:OnClose()
		
	end
	
	function META:OnCursorPos(x, y)

	end
	
	function META:OnFileDrop(paths)
	
	end
	
	function META:OnCharInput(str)
	
	end
	
	function META:OnKeyInput(key, press)
	
	end
	
	function META:OnKeyInputRepeat(key, press)
	
	end
	
	function META:OnMouseInput(key, press)
		
	end
	
	function META:OnMouseScroll(x, y)
	
	end
	
	function META:OnCursorEnter()
	
	end
	
	function META:OnRefresh()
		
	end
	
	function META:OnFramebufferResized(width, height)
	
	end
	
	function META:OnMove(x, y)
	
	end
	
	function META:OnIconify()
	
	end
	
	function META:OnResize(width, height)
		
	end
	
	function META:OnTextEditing(str)
		
	end
	
	function render.CreateWindow(width, height, title)	
		width = width or 800
		height = height or 600
		title = title or ""
	
		sdl.Init(sdl.e.SDL_INIT_VIDEO)
		sdl.video_init = true

		sdl.GL_SetAttribute(sdl.e.SDL_GL_CONTEXT_MAJOR_VERSION, 4)
		sdl.GL_SetAttribute(sdl.e.SDL_GL_CONTEXT_MINOR_VERSION, 4)
		
		sdl.GL_SetAttribute(sdl.e.SDL_GL_CONTEXT_FLAGS, sdl.e.SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG)
		sdl.GL_SetAttribute(sdl.e.SDL_GL_CONTEXT_PROFILE_MASK, sdl.e.SDL_GL_CONTEXT_PROFILE_COMPATIBILITY)
		
		local ptr = sdl.CreateWindow(
			title, 
			sdl.e.SDL_WINDOWPOS_CENTERED, 
			sdl.e.SDL_WINDOWPOS_CENTERED,
			width, 
			height, 
			bit.bor(sdl.e.SDL_WINDOW_OPENGL, sdl.e.SDL_WINDOW_SHOWN, sdl.e.SDL_WINDOW_RESIZABLE)
		)		
		local context = sdl.GL_CreateContext(ptr)
		sdl.GL_MakeCurrent(ptr, context) 
		gl.GetProcAddress = sdl.GL_GetProcAddress

		logn("sdl version: ", ffi.string(sdl.GetRevision()))	
		
		-- this needs to be initialized once after a context has been created..
		if gl and gl.InitMiniGlew and not gl.gl_init then
			gl.gl_init = true
			gl.InitMiniGlew()
		end
			
		local self = META:New()
		
		self.last_mpos = Vec2()
		self.mouse_delta = Vec2()
		self.__ptr = ptr
		self.context = context
			
		render.sdl_windows = render.sdl_windows or {}
		local id = sdl.GetWindowID(ptr)
		self.sdl_window_id = id
		render.sdl_windows[id] = self
		
		local event_name_translate = {}
		local key_translate = {
			left_ctrl = "left_control",
		}
		
		local function call(self, name, ...)
			if not self then return end
						
			if not event_name_translate[name] then
				event_name_translate[name] = name:gsub("^On", "Window")
			end
			
			if self[name] then
				if self[name](...) ~= false then
					event.Call(event_name_translate[name], self, ...)
				end
			else
				print(name, ...)
			end
		end
		
		local event = ffi.new("SDL_Event")
		local mbutton_translate = {}
		for i = 1, 8 do mbutton_translate[i] = "button_" .. i end
		mbutton_translate[3] = "button_2"
		mbutton_translate[2] = "button_3"

		_G.event.AddListener("Update", self, function(dt)
			if not self:IsValid() or not sdl.video_init then
				sdl.PollEvent(event) -- this needs to be done or windows thinks the application froze..
				return
			end
			
			self.mouse_delta:Zero()
			--self:UpdateMouseDelta()
			self:OnUpdate(dt)
			
			while sdl.PollEvent(event) ~= 0 do
				local window 
				if event.window and event.window.windowID then
					window = render.sdl_windows[event.window.windowID]
				end
								
				if event.type == sdl.e.SDL_WINDOWEVENT then
					local case = event.window.event
										
					if case == sdl.e.SDL_WINDOWEVENT_SHOWN then
						call(window, "OnShow")
					elseif case == sdl.e.SDL_WINDOWEVENT_HIDDEN then
						call(window, "OnHide")
					elseif case == sdl.e.SDL_WINDOWEVENT_EXPOSED then
						call(window, "OnFramebufferResized", self:GetSize():Unpack())
					elseif case == sdl.e.SDL_WINDOWEVENT_SIZE_CHANGED then
						call(window, "OnFramebufferResized", event.window.data1, event.window.data2)
					elseif case == sdl.e.SDL_WINDOWEVENT_MOVED then
						call(window, "OnMove", event.window.data1, event.window.data2)
					elseif case == sdl.e.SDL_WINDOWEVENT_RESIZED then
						call(window, "OnResize", event.window.data1, event.window.data2)
						call(window, "OnFramebufferResized", event.window.data1, event.window.data2)
					elseif case == sdl.e.SDL_WINDOWEVENT_MINIMIZED then
						call(window, "OnMinimize")
					elseif case == sdl.e.SDL_WINDOWEVENT_MAXIMIZED then
						call(window, "OnResize", self:GetSize():Unpack())
						call(window, "OnFramebufferResized", self:GetSize():Unpack())
					elseif case == sdl.e.SDL_WINDOWEVENT_RESTORED then
						call(window, "OnRefresh")
					elseif case == sdl.e.SDL_WINDOWEVENT_ENTER then
						call(window, "OnCursorEnter", false)
					elseif case == sdl.e.SDL_WINDOWEVENT_LEAVE then
						call(window, "OnCursorEnter", true)
					elseif case == sdl.e.SDL_WINDOWEVENT_FOCUS_GAINED then
						call(window, "OnFocus", true)
					elseif case == sdl.e.SDL_WINDOWEVENT_FOCUS_LOST then
						call(window, "OnFocus", false)
					elseif case == sdl.e.SDL_WINDOWEVENT_CLOSE then
						call(window, "OnClose")
					end
				elseif event.type == sdl.e.SDL_KEYDOWN or event.type == sdl.e.SDL_KEYUP then
					local window = render.sdl_windows[event.key.windowID]
					local key = ffi.string(sdl.GetKeyName(event.key.keysym.sym)):lower():gsub(" ", "_")
				
					key = key_translate[key] or key
				
					call(
						window, 
						event.key["repeat"] == 0 and "OnKeyInput" or "OnKeyInputRepeat", 
						key, 
						event.type == sdl.e.SDL_KEYDOWN, 
						
						event.key.state, 
						event.key.keysym.mod, 
						ffi.string(sdl.GetScancodeName(event.key.keysym.scancode)):lower(), 
						event.key.keysym
					)
				elseif event.type == sdl.e.SDL_TEXTINPUT then
					local window = render.sdl_windows[event.edit.windowID]

					call(window, "OnCharInput", ffi.string(event.edit.text), event.edit.start, event.edit.length)
				elseif event.type == sdl.e.SDL_TEXTEDITING then
					local window = render.sdl_windows[event.text.windowID]

					call(window, "OnTextEditing", ffi.string(event.text.text))
				elseif event.type == sdl.e.SDL_MOUSEMOTION then
					local window = render.sdl_windows[event.motion.windowID]
					self.mouse_delta.x = event.motion.xrel
					self.mouse_delta.y = event.motion.yrel
					call(window, "OnCursorPos", event.motion.x, event.motion.y, event.motion.xrel, event.motion.yrel, event.motion.state, event.motion.which)
				elseif event.type == sdl.e.SDL_MOUSEBUTTONDOWN or event.type == sdl.e.SDL_MOUSEBUTTONUP then
					local window = render.sdl_windows[event.button.windowID]
					call(window, "OnMouseInput", mbutton_translate[event.button.button], event.type == sdl.e.SDL_MOUSEBUTTONDOWN, event.button.x, event.button.y)
				elseif event.type == sdl.e.SDL_MOUSEWHEEL then
					local window = render.sdl_windows[event.button.windowID]
					call(window, "OnMouseScroll", event.wheel.x, event.wheel.y, event.wheel.which)
				end
			end
		end)
		
		if not render.current_window:IsValid() then
			render.current_window = self
		end

		render.context_created = true
		render.Initialize()
		
		return self
	end
end
