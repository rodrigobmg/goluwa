local gl = desire("graphics.ffi.opengl") -- OpenGL

if not gl then return end

local render = _G.render or {}

function render.Initialize()

	if not gl then 
		logn("cannot initialize render: ", err)
	return end
	
	if not render.context_created then error("a window must exist before the renderer can be initialized", 2) end

	logf("opengl version: %s\n", render.GetVersion())
	logf("glsl version: %s\n", render.GetShadingLanguageVersion())
	logf("vendor: %s\n", render.GetVendor())
	
	if render.GetVersion():find("OpenGL ES") then
		OPENGL_ES = true
	end
	
	local vendor = render.GetVendor()
	
	if vendor:lower():find("nvidia") then
		NVIDIA = true
	elseif vendor:lower():find("ati") or vendor:lower():find("amd") then
		ATI = true
		-- AMD = true grr cpus
	end
		
	if render.debug then
		render.EnableDebug(true)
	end
		
	render.GenerateTextures()
	
	include("lua/libraries/graphics/decoders/*")
	
	render.frame = 0
		
	render.SetBlendMode("src_alpha", "one_minus_src_alpha")
	render.EnableDepth(false)
	
	render.SetClearColor(0.25, 0.25, 0.25, 0.5)
	
	for i = 0, 15 do
		render.ActiveTexture(i)
	end
	
	include("lua/libraries/graphics/render/shader_builder.lua", render)
	
	surface.Initialize()
	
	event.Delay(function()
		event.Call("RenderContextInitialized")	
	end)
end

function render.Shutdown()
	
end

render.global_shader_variables = render.global_shader_variables or {}

function render.SetGlobalShaderVariable(key, val, type)
	render.global_shader_variables[key] = {[type] = val, global_variable = true}
end

render.global_shader_code = render.global_shader_code or {}

function render.AddGlobalShaderCode(glsl_code, require)
	for i,v in ipairs(render.global_shader_code) do
		if v.require == require then
			table.remove(render.global_shader_code, i)
			break
		end
	end
	
	table.insert(render.global_shader_code, {code = glsl_code, require = require})
end

function render.GetGlobalShaderCode(code)
	local out = {}
	
	for i, v in ipairs(render.global_shader_code) do
		if not code or (v.require and code:find(v.require, nil, true)) then
			table.insert(out, v.code)
		end
	end
	
	return table.concat(out, "\n\n")
end

do -- occlusion query
	local META = prototype.CreateTemplate("occlusion_query")
	
	function META:Begin()
		gl.BeginQuery("GL_SAMPLES_PASSED", self.id)
	end
	
	function META:End()
		gl.EndQuery("GL_SAMPLES_PASSED")
	end
	
	local ready = ffi.new("GLuint[1]")
	
	function META:GetVisibility()
		gl.GetQueryObjectuiv(self.id, "GL_QUERY_RESULT_AVAILABLE", ready)
		if ready[0] ~= 0 then
			gl.GetQueryObjectuiv(self.id, "GL_QUERY_RESULT", ready)
			return tonumber(ready[0])/480000
		end
		
		return 0
	end
	
	META:Register()
	
	function render.CreateOcclusionQuery()
		local self = prototype.CreateObject("occlusion_query")
		self.id = gl.GenQuerie()
		
		return self
	end
end

do -- shaders
	local status = ffi.new("GLint[1]")
	local shader_strings = ffi.new("const char * [1]")
	local log = ffi.new("char[1024]")

	function render.CreateGLShader(type, source)
		check(type, "number")
		check(source, "string")
		
		if not render.CheckSupport("CreateShader") then return 0 end
		
		local shader = gl.CreateShader(type)
		
		shader_strings[0] = ffi.cast("const char *", source)
		gl.ShaderSource(shader, 1, shader_strings, nil)
		gl.CompileShader(shader)
		gl.GetShaderiv(shader, "GL_COMPILE_STATUS", status)		

		if status[0] == 0 then			
		
			gl.GetShaderInfoLog(shader, 1024, nil, log)
			gl.DeleteShader(shader)
			
			error(ffi.string(log), 2)
		end

		return shader
	end

	function render.CreateGLProgram(cb, ...)	

		if not render.CheckSupport("CreateProgram") then return 0 end

		local shaders = {...}
		local program = gl.CreateProgram()
		
		for _, shader_id in pairs(shaders) do
			gl.AttachShader(program, shader_id)
		end
		
		cb(program)

		gl.LinkProgram(program)

		gl.GetProgramiv(program, "GL_LINK_STATUS", status)

		if status[0] == 0 then
		
			gl.GetProgramInfoLog(program, 1024, nil, log)
			gl.DeleteProgram(program)		
			
			error(ffi.string(log), 2)
		end
		
		for _, shader_id in pairs(shaders) do
			gl.DetachShader(program, shader_id)
			gl.DeleteShader(shader_id)
		end
		
		return program
	end

	do
		local last

		function render.UseProgram(id)
			if last ~= id then
				gl.UseProgram(id)
				last = id
				render.current_program = id
			end
		end
	end

	do
		local last

		function render.BindArrayBuffer(id)
			if last ~= id then
				gl.BindBuffer("GL_ARRAY_BUFFER", id)
				last = id
			end
		end
	end
	
	do
		local last

		function render.BindVertexArray(id)
			if last ~= id then
				gl.BindVertexArray(id)
				last = id
				
				return true
			end
			
			return false
		end
	end
end

do
	local vsync = 0
	
	function render.SetVSync(b)
		if gl.SwapIntervalEXT then
			gl.SwapIntervalEXT(b == true and 1 or b == "adaptive" and -1 or 0)
		elseif window and window.IsOpen() then
			window.SwapInterval(b) -- works on linux
		end
		vsync = b
	end

	function render.GetVSync(b)
		return vsync
	end
end
 
function render.Shutdown()	

end

function render.GetVersion()		
	return ffi.string(gl.GetString("GL_VERSION"))
end

function render.GetShadingLanguageVersion()		
	return ffi.string(gl.GetString("GL_SHADING_LANGUAGE_VERSION"))
end

function render.GetVendor()		
	return ffi.string(gl.GetString("GL_VENDOR"))
end

function render.CheckSupport(func)
	if not gl[func] then
		logf("%s: the function gl.%s does not exist\n", debug.getinfo(2).func:name(), func)
		return false
	end
	
	return true
end

do
	local R,G,B,A = 0,0,0,1
	
	function render.SetClearColor(r,g,b,a)
		R = r
		G = g
		B = b
		A = a or 1
		
		gl.ClearColor(R,G,B,A)
	end

	function render.GetClearColor()
		return R,G,B,A
	end
end

do
	local enums = {
		color = gl.e.GL_COLOR_BUFFER_BIT,
		depth = gl.e.GL_DEPTH_BUFFER_BIT,
		stencil = gl.e.GL_STENCIL_BUFFER_BIT,
		accum = gl.e.GL_ACCUM_BUFFER_BIT,
	}
	
	function render.Clear(a, b, c, d)		
	
		local flag = enums[a] or enums.color
		if b then flag = bit.bor(flag, enums[b]) end
		if c then flag = bit.bor(flag, enums[c]) end
		if d then flag = bit.bor(flag, enums[d]) end
		
		gl.Clear(flag)
	end
end

do
	local X, Y, W, H = 0, 0, 0, 0
	
	function render.SetScissor(x,y,w,h)
		--render.ScissorRect(x,y,w,h)  
		--surface.SetScissor(x, y, w, h)

		local sw, sh = render.GetScreenSize():Unpack()
		
		x = x or 0
		y = y or 0
		w = w or sw
		h = h or sh
		
		gl.Scissor(x, sh - (y + h), w, h)
		
		X = x
		Y = y
		W = w
		H = h
	end

	function render.GetScissor()
		return X,Y,W,H
	end
end

do
	local X,Y,W,H
	
	local last = Rect()
	
	function render.SetViewport(x, y, w, h)
		X,Y,W,H = x,y,w,h
		
		if last.x ~= x or last.y ~= y or last.w ~= w or last.h ~= h then
			gl.Viewport(x, y, w, h)
			gl.Scissor(x, y, w, h)
			
			render.camera_2d.Viewport.w = w
			render.camera_2d.Viewport.h = h
			render.camera_2d:Rebuild()
			
			last.x = x
			last.y = y
			last.w = w
			last.h = h
		end
	end
	
	function render.GetViewport()
		return x,y,w,h
	end

	local stack = {}
	
	function render.PushViewport(x, y, w, h)
		table.insert(stack, {X or 0,Y or 0,W or render.GetWidth(),H or render.GetHeight()})
				
		render.SetViewport(x, y, w, h)
	end
	
	function render.PopViewport()
		render.SetViewport(unpack(table.remove(stack)))
	end
end

do 
	local enums = gl and {
		zero = gl.e.GL_ZERO,
		one = gl.e.GL_ONE,
		src_color = gl.e.GL_SRC_COLOR,
		one_minus_src_color = gl.e.GL_ONE_MINUS_SRC_COLOR,
		dst_color = gl.e.GL_DST_COLOR,
		one_minus_dst_color = gl.e.GL_ONE_MINUS_DST_COLOR,
		src_alpha = gl.e.GL_SRC_ALPHA,
		one_minus_src_alpha = gl.e.GL_ONE_MINUS_SRC_ALPHA,
		dst_alpha = gl.e.GL_DST_ALPHA,
		one_minus_dst_alpha = gl.e.GL_ONE_MINUS_DST_ALPHA,
		constant_color = gl.e.GL_CONSTANT_COLOR,
		one_minus_constant_color = gl.e.GL_ONE_MINUS_CONSTANT_COLOR,
		constant_alpha = gl.e.GL_CONSTANT_ALPHA,
		one_minus_constant_alpha = gl.e.GL_ONE_MINUS_CONSTANT_ALPHA,
		src_alpha_saturate = gl.e.GL_SRC_ALPHA_SATURATE,
		
		add = gl.e.GL_FUNC_ADD,
		sub = gl.e.GL_FUNC_SUBTRACT,
		reverse_sub = gl.e.GL_FUNC_REVERSE_SUBTRACT,
		min = gl.e.GL_MIN,
		max = gl.e.GL_MAX,
	} or {}

	function render.SetBlendMode(src_color, dst_color, func_color, src_alpha, dst_alpha, func_alpha)

		if src_color then
			gl.Enable("GL_BLEND")
		else
			gl.Disable("GL_BLEND")
			return
		end
		
		if src_color == "alpha" then
			gl.AlphaFunc("GL_GEQUAL", 0)
			
			gl.BlendFuncSeparate(	
				"GL_SRC_ALPHA", "GL_ONE_MINUS_SRC_ALPHA", 
				"GL_ONE", "GL_ONE_MINUS_SRC_ALPHA"
			)
		elseif src_color == "multiplicative" then
			gl.BlendFunc("GL_DST_COLOR", "GL_ZERO")
		elseif src_color == "premultiplied" then
			gl.BlendFunc("GL_ONE", "GL_ONE_MINUS_SRC_ALPHA")
		elseif src_color == "additive" then
			gl.BlendFunc("GL_SRC_ALPHA", "GL_ONE")
		else		
			src_color = enums[src_color or "src_alpha"]
			dst_color = enums[dst_color or "one_minus_src_alpha"]
			func_color = enums[func_color or "add"]
			
			src_alpha = enums[src_alpha] or src_color
			dst_alpha = enums[dst_alpha] or dst_color
			func_alpha = enums[func_alpha] or func_color
			
			gl.BlendFuncSeparate(src_color, dst_color, src_alpha, dst_alpha)
			gl.BlendEquationSeparate(func_color, func_alpha)		
		end
	end
end

do	
	local cull_mode = "front"
	local override_

	function render.SetCullMode(mode, override)
		if mode == cull_mode then return end
		if override == false then override_ = nil end
		if override_ then return end
		
		if mode == "none" then
			gl.Disable("GL_CULL_FACE")
		else
			gl.Enable("GL_CULL_FACE")
		end
	
		if mode == "front" then
			gl.CullFace("GL_FRONT")
		elseif mode == "back" then
			gl.CullFace("GL_BACK")
		elseif mode == "front_and_back" then
			gl.CullFace("GL_FRONT_AND_BACK")
		end
		
		cull_mode = mode
		override_ = override
	end

	function render.GetCullMode()
		return cull_mode
	end
end

do
	local data = ffi.new("float[3]")

	function render.ReadPixels(x, y, w, h)
		w = w or 1
		h = h or 1
		
		gl.ReadPixels(x, y, w, h, "GL_RGBA", "GL_FLOAT", data)
			
		return data[0], data[1], data[2], data[3]
	end
end

function render.EnableDepth(b)
	if b then
		gl.Enable("GL_DEPTH_TEST")
		gl.DepthMask(1)
		gl.DepthFunc("GL_LESS")
	else
		gl.Disable("GL_DEPTH_TEST")
		gl.DepthMask(0)
		--gl.DepthFunc(gl.e.GL_ALWAYS)
	end
end

-- shadertoy

--[[
Shader Inputs
uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iGlobalTime;           // shader playback time (in seconds)
uniform float     iChannelTime[4];       // channel playback time (in seconds)
uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube
uniform vec4      iDate;                 // (year, month, day, time in seconds)
uniform float     iSampleRate;           // sound sample rate (i.e., 44100)]]

render.SetGlobalShaderVariable("iResolution", function() return Vec2(render.camera.w, render.camera.h, render.camera.ratio) end, "vec3")
render.SetGlobalShaderVariable("iGlobalTime", function() return system.GetElapsedTime() end, "float")
render.SetGlobalShaderVariable("iMouse", function() return Vec2(surface.GetMousePosition()) end, "float")
render.SetGlobalShaderVariable("iDate", function() return Color(os.date("%y"), os.date("%m"), os.date("%d"), os.date("%s")) end, "vec4")

if RELOAD then return end

include("enum_translate.lua", render)
include("generated_textures.lua", render)
include("camera.lua", render)
include("scene.lua", render)
include("texture2.lua", render)
include("framebuffer2.lua", render)
--include("texture.lua", render)
--include("framebuffer.lua", render)
include("gbuffer/gbuffer.lua", render)
include("vertex_buffer.lua", render)
include("texture_atlas.lua", render)
include("mesh_builder.lua", render)
include("material.lua", render)
include("model_loader.lua", render)

if USE_GLFW then
	include("glfw_window.lua", render)
else
	include("sdl_window.lua", render)
end

include("debug.lua", render)
include("globals.lua", render)

return render
