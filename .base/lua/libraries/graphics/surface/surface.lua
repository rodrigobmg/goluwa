local surface = _G.surface or {}

include("mesh2d.lua", surface)
include("markup/markup.lua", surface)

function surface.Initialize()		
	surface.rect_mesh = surface.CreateMesh() -- mesh defaults to rect, see mesh2d.lua
		
	surface.SetWhiteTexture()				 
	surface.InitializeFonts()
	
	surface.ready = true
end

if surface.ready then
	surface.Initialize()
end

function surface.IsReady()
	return surface.ready == true
end

function surface.GetScreenSize()
	return render.camera.w, render.camera.h
end

function surface.Start(...)	
	render.Start2D(...)
end

function surface.End(...)	
	render.End2D(...)
end

local gl = require("lj-opengl")

function surface.Start3D(pos, ang, scale)	
	local w, h = render.GetHeight(), render.GetHeight()
	
	pos = pos or Vec3(0, 0, 0)
	ang = ang or Ang3(0, 0, 0)
	scale = scale or Vec3(4, 4 * (w / h), 1)
		
	
	-- this is the amount the gui will translate upwards for each
	-- call to surface.PushMatrix
	surface.scale_3d = -scale.z / (w + h) -- dunno
	surface.in_3d = true
	
	-- tell the 2d shader to use the 3d matrix instead
	surface.mesh_2d_shader.pvm_matrix = render.GetPVWMatrix3D

	render.PushWorldMatrix(pos, ang, Vec3(scale.x / w, scale.y / h, 1))
end

function surface.End3D()
	render.PopWorldMatrix()
	
	surface.mesh_2d_shader.pvm_matrix = render.GetPVWMatrix2D
	surface.in_3d = false
end

local X, Y = 0, 0
local W, H = 0, 0
local R,G,B,A,A2 = 1,1,1,1,1

include("fonts.lua", surface)

do -- orientation
	function surface.Translate(x, y)	
		render.Translate(math.ceil(tonumber(x)), math.ceil(tonumber(y)), 0)
	end
	
	function surface.Rotate(a)		
		render.Rotate(a, 0, 0, 1)
	end
	
	function surface.Scale(w, h)
		render.Scale(w, h or w, 1)
	end
	
	function surface.LoadIdentity()
		render.LoadIdentity()
	end
		
	function surface.PushMatrix(x,y, w,h, a, dont_multiply)
		render.PushWorldMatrix(nil, nil, nil, dont_multiply)

		if x and y then surface.Translate(x, y) end
		if w and h then surface.Scale(w, h) end
		if a then surface.Rotate(a) end
		
		if surface.in_3d then
			surface.push_count_3d = (surface.push_count_3d or -1) + 1
			render.Translate(0, 0, surface.push_count_3d * (surface.scale_3d or 1))
		end
	end
	
	function surface.PopMatrix()
		if surface.in_3d then
			surface.push_count_3d = (surface.push_count_3d or -1) - 1
		end
	
		render.PopWorldMatrix() 
	end
end

local COLOR = Color()
local oldr, oldg, oldb, olda

function surface.SetColor(r, g, b, a)
	oldr, oldg, oldb, olda = R,G,B,A
	
	if not g then
		a = r.a
		b = r.b
		g = r.g
		r = r.r
	end
	
	R = r
	G = g
	B = b
	
	if a then
		A = a
	end
	
	COLOR.r = R
	COLOR.g = G
	COLOR.b = B
	COLOR.a = A
	
	surface.mesh_2d_shader.global_color = COLOR
	
	return oldr, oldg, oldb, olda
end

function surface.GetColor(obj)
	if obj then
		return COLOR
	end
	
	return R, G, B, A
end


function surface.SetAlpha(a)
	olda = A
	
	A = a
	COLOR.a = a
	
	surface.mesh_2d_shader.global_color = COLOR
	
	return olda
end

function surface.GetAlpha()
	return A
end

function surface.SetAlphaMultiplier(a)
	A2 = a
	--surface.fontmesh.alpha_multiplier = A2
	surface.mesh_2d_shader.alpha_multiplier = A2
end

function surface.SetTexture(tex)
	tex = tex or render.GetWhiteTexture()
	
	surface.bound_texture = tex
end

function surface.SetWhiteTexture()
	surface.bound_texture = render.GetWhiteTexture() 
end

function surface.GetTexture()
	return surface.bound_texture or render.GetWhiteTexture()
end

do
	--[[{
		{pos = {0, 0}, uv = {xbl, ybl}, color = color_bottom_left},
		{pos = {0, 1}, uv = {xtl, ytl}, color = color_top_left},
		{pos = {1, 1}, uv = {xtr, ytr}, color = color_top_right},

		{pos = {1, 1}, uv = {xtr, ytr}, color = color_top_right},
		{pos = {1, 0}, uv = {xbr, ybr}, color = mesh_data[1].color},
		{pos = {0, 0}, uv = {xbl, ybl}, color = color_bottom_left},
	})]]
	
	-- sdasdasd
	
	local last_xtl = 0
	local last_ytl = 0
	local last_xtr = 1
	local last_ytr = 0
	
	local last_xbl = 0
	local last_ybl = 1
	local last_xbr = 1
	local last_ybr = 1
	
	local last_color_bottom_left = Color(1,1,1,1)
	local last_color_top_left = Color(1,1,1,1)
	local last_color_top_right = Color(1,1,1,1)
	local last_color_bottom_right = Color(1,1,1,1)
	
	local function update_vbo()
		
		if 
			last_xtl ~= surface.rect_mesh.vertices[1].uv.A or
			last_ytl ~= surface.rect_mesh.vertices[1].uv.B or
			last_xtr ~= surface.rect_mesh.vertices[3].uv.A or
			last_ytr ~= surface.rect_mesh.vertices[3].uv.B or
			
			last_xbl ~= surface.rect_mesh.vertices[0].uv.A or
			last_ybl ~= surface.rect_mesh.vertices[1].uv.B or
			last_xbr ~= surface.rect_mesh.vertices[4].uv.A or
			last_ybr ~= surface.rect_mesh.vertices[4].uv.B or
			
			last_color_bottom_left ~= surface.rect_mesh.vertices[0].color or
			last_color_top_left ~= surface.rect_mesh.vertices[1].color or
			last_color_top_right ~= surface.rect_mesh.vertices[2].color or
			last_color_bottom_right ~= surface.rect_mesh.vertices[4].color
		then
		
			surface.rect_mesh:UpdateBuffer()
			
			last_xtl = surface.rect_mesh.vertices[1].uv.A
			last_ytl = surface.rect_mesh.vertices[1].uv.B
			last_xtr = surface.rect_mesh.vertices[3].uv.A
			last_ytr = surface.rect_mesh.vertices[3].uv.B
			           
			last_xbl = surface.rect_mesh.vertices[0].uv.A
			last_ybl = surface.rect_mesh.vertices[1].uv.B
			last_xbr = surface.rect_mesh.vertices[4].uv.A
			last_ybr = surface.rect_mesh.vertices[4].uv.B
			
			last_color_bottom_left = surface.rect_mesh.vertices[0].color
			last_color_top_left = surface.rect_mesh.vertices[1].color
			last_color_top_right = surface.rect_mesh.vertices[2].color
			last_color_bottom_right = surface.rect_mesh.vertices[4].color	
		end		
	end

	do
		local X, Y, W, H, SX, SY
		
		function surface.SetRectUV(x,y, w,h, sx,sy)
			if not x then
				surface.rect_mesh.vertices[0].uv.A = 0
				surface.rect_mesh.vertices[0].uv.B = 1
				
				surface.rect_mesh.vertices[1].uv.A = 0
				surface.rect_mesh.vertices[1].uv.B = 0
				
				surface.rect_mesh.vertices[2].uv.A = 1
				surface.rect_mesh.vertices[2].uv.B = 0
				
				--
				
				surface.rect_mesh.vertices[3].uv = surface.rect_mesh.vertices[2].uv
				
				surface.rect_mesh.vertices[4].uv.A = 1
				surface.rect_mesh.vertices[4].uv.B = 1
				
				surface.rect_mesh.vertices[5].uv = surface.rect_mesh.vertices[0].uv	
			else			
				sx = sx or 1
				sy = sy or 1
				
				y = -y - h
				
				surface.rect_mesh.vertices[0].uv.A = x / sx
				surface.rect_mesh.vertices[0].uv.B = (y + h) / sy
				
				surface.rect_mesh.vertices[1].uv.A = x / sx
				surface.rect_mesh.vertices[1].uv.B = y / sy
				
				surface.rect_mesh.vertices[2].uv.A = (x + w) / sx
				surface.rect_mesh.vertices[2].uv.B = y / sy
				
				--
				
				surface.rect_mesh.vertices[3].uv = surface.rect_mesh.vertices[2].uv
				
				surface.rect_mesh.vertices[4].uv.A = (x + w) / sx
				surface.rect_mesh.vertices[4].uv.B = (y + h) / sy
				
				surface.rect_mesh.vertices[5].uv = surface.rect_mesh.vertices[0].uv	
			end
			
			update_vbo()
			
			X = x
			Y = y
			W = w
			H = h
			SX = sx
			SY = sy
		end
		
		function surface.GetRectUV()
			return X, Y, W, H, SX, SY
		end
	end

	local white_t = {1,1,1,1}

	function surface.SetRectColors(cbl, ctl, ctr, cbr)			
		if not cbl then
			for i = 1, 6 do
				surface.rect_mesh.vertices[i].color = white_t
			end
		else
			surface.rect_mesh.vertices[0].color = {cbl:Unpack()}
			surface.rect_mesh.vertices[1].color = {ctl:Unpack()}
			surface.rect_mesh.vertices[2].color = {ctr:Unpack()}
			surface.rect_mesh.vertices[3].color = surface.rect_mesh.vertices[2].color
			surface.rect_mesh.vertices[4].color = {cbr:Unpack()}
			surface.rect_mesh.vertices[5].color = surface.rect_mesh.vertices[1]
		end
		
		update_vbo()
	end
end

function surface.DrawRect(x,y, w,h, a, ox,oy)	
	surface.PushMatrix()			
		surface.Translate(x, y)
		
		if a then
			surface.Rotate(a)
		end
		
		if ox then
			surface.Translate(-ox, -oy)
		end
				
		surface.Scale(w, h)
		
		surface.mesh_2d_shader.tex = surface.bound_texture
		surface.mesh_2d_shader:Bind()
		surface.rect_mesh:Draw()
	surface.PopMatrix()
end

function surface.DrawLine(x1,y1, x2,y2, w, skip_tex, ox, oy)
	w = w or 1
	
	if not skip_tex then 
		surface.SetWhiteTexture() 
	end
	
	local dx,dy = x2-x1, y2-y1
	local ang = math.atan2(dx, dy)
	local dst = math.sqrt((dx * dx) + (dy * dy))
	
	ox = ox or (w*0.5)
	oy = oy or 0 
		
	surface.DrawRect(x1, y1, w, dst, -math.deg(ang), ox, oy)
end

--[[
	1 2 3
	4 5 6
	7 8 9
]]

local poly

function surface.DrawNinePatch(x, y, w, h, patch_size_w, patch_size_h, corner_size, u_offset, v_offset)
	poly = poly or surface.CreatePoly(9)
	
	u_offset = u_offset or 0
	v_offset = v_offset or 0
	
	if w < corner_size then corner_size = w end
	if h < corner_size then corner_size = h end
	
	local skin = surface.GetTexture()
		
	-- 1
	poly:SetUV(u_offset, v_offset, corner_size, corner_size, skin.w, skin.h)
	poly:SetRect(1, x, y, corner_size, corner_size)
	
	-- 2
	poly:SetUV(u_offset + corner_size, v_offset, patch_size_w - corner_size*2, corner_size, skin.w, skin.h)
	poly:SetRect(2, x + corner_size, y, w - corner_size*2, corner_size)
	
	-- 3
	poly:SetUV(u_offset + patch_size_w - corner_size, v_offset, corner_size, corner_size, skin.w, skin.h)
	poly:SetRect(3, x + w - corner_size, y, corner_size, corner_size)
	
	-- 4
	poly:SetUV(u_offset, v_offset + corner_size, corner_size, patch_size_w - corner_size*2, skin.w, skin.h)
	poly:SetRect(4, x, y + corner_size, corner_size, h - corner_size*2)
	
	-- 5
	poly:SetUV(u_offset + corner_size, v_offset + corner_size, patch_size_w - corner_size*2, patch_size_h - corner_size*2, skin.w, skin.h)
	poly:SetRect(5, x + corner_size, y + corner_size, w - corner_size*2, h - corner_size*2)
	
	-- 6
	poly:SetUV(u_offset + patch_size_w - corner_size, v_offset + corner_size, corner_size, patch_size_h - corner_size*2, skin.w, skin.h)
	poly:SetRect(6, x + w - corner_size, y + corner_size, corner_size, h - corner_size*2)
	
	-- 7
	poly:SetUV(u_offset, v_offset + patch_size_h - corner_size, corner_size, corner_size, skin.w, skin.h)
	poly:SetRect(7, x, y + h - corner_size, corner_size, corner_size)
	
	-- 8
	poly:SetUV(u_offset + corner_size, v_offset + patch_size_h - corner_size, patch_size_w - corner_size*2, corner_size, skin.w, skin.h)
	poly:SetRect(8, x + corner_size, y + h - corner_size, w - corner_size*2, corner_size)
	
	-- 9
	poly:SetUV(u_offset + patch_size_w - corner_size, v_offset + patch_size_h - corner_size, corner_size, corner_size, skin.w, skin.h)
	poly:SetRect(9, x + w - corner_size, y + h - corner_size, corner_size, corner_size)
	
	poly:Draw()
end

function surface.SetScissor(x, y, w, h)
	if not x then 
		render.SetScissor() 
	else
		x, y = surface.WorldToLocal(-x, -y)
		render.SetScissor(-x, -y, w, h)
	end
end

do
    local stack = {}
	local depth = 1
	
	local stencil_debug_tex
	
	function surface.DrawStencilTexture()
	       
	    stencil_debug_tex = stencil_debug_tex or Texture(render.GetWidth(), render.GetHeight())
	    
		local stencilStateArray = ffi.new("GLboolean[1]", 0)
		gl.GetBooleanv(gl.e.GL_STENCIL_TEST, stencilStateArray)
		
		--if wait(0.25) then
			
			gl.Enable(gl.e.GL_STENCIL_TEST)
			
			local stencilWidth = render.GetWidth()
			local stencilHeight = render.GetHeight()
			local stencilSize = stencilWidth*stencilHeight
			local stencilData = ffi.new("unsigned char[?]", stencilSize)
			gl.ReadPixels(0, 0, stencilWidth, stencilHeight, gl.e.GL_STENCIL_INDEX, gl.e.GL_UNSIGNED_BYTE, stencilData)
			
			--[[for y = 0, stencilHeight-1 do
				for x = 0, stencilWidth-1 do
					local i = y*stencilWidth + x
					io.stdout:write(string.format("%02X ", stencilData[i]))
				end
				io.stdout:write("\n")
			end]]
			
			local y = math.floor(stencilHeight/2)
			for x = math.floor(stencilWidth/2-10), math.floor(stencilWidth/2+10) do
				local i = y*stencilWidth + x
				stencilData[i] = 1
			end
			
			local maxValue = 0
			for i = 0, stencilSize-1 do
				maxValue = math.max(maxValue, stencilData[i])
			end
			
			local scale = 255/maxValue
			for i = 0, stencilSize-1 do
				stencilData[i] = math.floor(stencilData[i]*scale)
			end
			
			stencil_debug_tex:Upload(stencilData, {upload_format = "red", internal_format = "r8"})
		--end

		surface.PushMatrix()
		surface.LoadIdentity()
    		surface.SetColor(1,1,1,1)
    		surface.SetTexture(stencil_debug_tex)
    		gl.Disable(gl.e.GL_STENCIL_TEST)
    		surface.DrawRect(64,64,128,128)
    		gl.Enable(gl.e.GL_STENCIL_TEST)
		surface.PopMatrix()
		
		if stencilStateArray[0] == 0 then
		    gl.Disable(gl.e.GL_STENCIL_TEST)
	    end
    end
	
	function surface.EnableStencilClipping()
		--assert(#stack == 0, "I think this is good assertion, wait, you may want to draw something regardless of clipping, so nvm")
		--table.clear(stack)
		-- that means the stack should not be emptied, in case you want to disobey clipping?
		
		-- Don't consider depth buffer while stenciling or drawing
		gl.DepthMask(gl.e.GL_FALSE)
		gl.DepthFunc(gl.e.GL_ALWAYS)
		
		-- Enable stencil test
		gl.Enable(gl.e.GL_STENCIL_TEST)
	    
		-- Write to all stencil bits
		gl.StencilMask(0xFF)
		
		-- Don't consider stencil buffer while clearing it
		gl.StencilFunc(gl.e.GL_ALWAYS, 0, 0xFF)
		
		-- Clear the stencil buffer to zero
		gl.ClearStencil(0)
		gl.Clear(gl.e.GL_STENCIL_BUFFER_BIT)
	    
		-- Stop writing to stencil
		gl.StencilMask(gl.e.GL_FALSE)
	end

	function surface.DisableStencilClipping()
		-- disable stencil completely, how2
		gl.Disable(gl.e.GL_STENCIL_TEST)
	end
    
    --[[
		it works like this:
		
		00000000000000000000000000
	    push frame; depth = 1
    		00011111111111111000000000
		    push panel; depth = 2
        		00011222222222211000000000
        		push button1; depth = 3
        		    00011233322222211000000000
    		    pop button1; depth = 2
    		    00011222222222211000000000
    		    push button2; depth = 3
    		        00011222222333211000000000
		        pop button2; depth = 2
		        00011222222222211000000000
	        pop panel; depth = 1
	        00011111111111111000000000
        pop frame; depth = 0
        00000000000000000000000000
        
        gl.StencilFunc(gl.e.GL_EQUAL, depth, 0xFF)
        means
        only draw if stencil == current depth
	]]
    
	local function update_stencil_buffer(mode)
	    
		-- Write to all stencil bits
		gl.StencilMask(0xFF)
		
		-- For each object on the stack, increment/decrement any pixel it touches by 1
		gl.DepthMask(gl.e.GL_FALSE) -- Don't write to depth buffer
		gl.StencilFunc(gl.e.GL_NEVER, 0, 0xFF) -- Update stencil regardless of current value 
		gl.StencilOp(
			mode, -- For each pixel white pixel, increment/decrement
			gl.e.GL_REPLACE, -- Ignore depth buffer
			gl.e.GL_REPLACE -- Ignore depth buffer
		)
		
		local data = stack[depth] 
		data.func(unpack(data.args))
	    
		-- Stop writing to stencil
		gl.StencilMask(gl.e.GL_FALSE)
		
		-- Now make future drawing obey stencil buffer
		gl.DepthMask(gl.e.GL_TRUE) -- Write to depth buffer
		gl.StencilFunc(gl.e.GL_EQUAL, depth-1, 0xFF) -- Pass test if stencil value is equal to depth
	end

	function surface.PushClipFunction(draw_func, ...)
	    depth = depth+1		
	    
		stack[depth] = {func = draw_func, args = {...}}
		
		update_stencil_buffer(gl.e.GL_INCR)
	end

	function surface.PopClipFunction()
		update_stencil_buffer(gl.e.GL_DECR)
		
		stack[depth] = nil
		depth = depth-1
		
		if depth < 1 then
			error("stack underflow", 2)
		end
	end
end

local gl = require("lj-opengl")
do
	local X, Y, W, H

	function surface.EnableClipRect(x, y, w, h)
		gl.Enable(gl.e.GL_STENCIL_TEST)
		
		gl.StencilFunc(gl.e.GL_ALWAYS, 1, 0xFF) -- Set any stencil to 1
		gl.StencilOp(gl.e.GL_KEEP, gl.e.GL_KEEP, gl.e.GL_REPLACE)
		gl.StencilMask(0xFF) -- Write to stencil buffer
		gl.DepthMask(gl.e.GL_FALSE) -- Don't write to depth buffer
		gl.Clear(gl.e.GL_STENCIL_BUFFER_BIT) -- Clear stencil buffer (0 by default)
		
		local tex = surface.GetTexture()
		surface.SetWhiteTexture()
		local r,g,b,a = surface.SetColor(0,0,0,0)
		surface.DrawRect(x, y, w, h)
		surface.SetColor(r,g,b,a)
		surface.SetTexture(tex)
		
		gl.StencilFunc(gl.e.GL_EQUAL, 1, 0xFF) -- Pass test if stencil value is 1
		gl.StencilMask(0x00) -- Don't write anything to stencil buffer
		gl.DepthMask(gl.e.GL_TRUE) -- Write to depth buffer	
		
		x = X
		y = Y
		w = W
		h = H
	end

	function surface.GetClipRect()
		return X or 0, Y or 0, W or render.GetWidth(), H or render.GetHeight()
	end

	function surface.DisableClipRect()
		gl.Disable(gl.e.GL_STENCIL_TEST)
	end
end

function surface.GetMousePosition()
	if window.GetMouseTrapped() then
		return render.GetWidth() / 2, render.GetHeight() / 2
	end
	return window.GetMousePosition():Unpack()
end

function surface.WorldToLocal(x, y)
	if surface.in_3d then
		x = ((x / render.GetWidth()) - 0.5) * 2
		y = ((y / render.GetHeight()) - 0.5) * 2
		
		local m = render.matrices.view_3d_inverse * render.matrices.world:GetInverse()
		
		cursor_x, cursor_y, cursor_z = m:TransformVector(render.matrices.projection_3d_inverse:TransformVector(x, -y, 1))
		local camera_x, camera_y, camera_z = m:TransformVector(0, 0, 0)

		--local intersect = camera + ( camera.z / ( camera.z - cursor.z ) ) * ( cursor - camera )
		
		local z = camera_z / ( camera_z - cursor_z )
		local intersect_x = camera_x + z * ( cursor_x - camera_x )
		local intersect_y = camera_y + z * ( cursor_y - camera_y )
				
		return intersect_x, intersect_y
	else
		local x, y = (render.matrices.view_2d_inverse * render.matrices.world:GetInverse()):TransformVector(x, y, 1)
	
		return x, y
	end
end

local last_x = 0
local last_y = 0
local last_diff = 0

function surface.GetMouseVel()
	local x, y = window.GetMousePosition():Unpack()
	
	local vx = x - last_x
	local vy = y - last_y
	
	local time = system.GetTime()
	
	if last_diff < time then
		last_x = x
		last_y = y
		last_diff = time + 0.1
	end
	
	return vx, vy
end

include("poly.lua", surface)

do -- points
	local gl = require("lj-opengl")
	
	local SIZE = 1
	local STYLE = "smooth"

	function surface.SetPointStyle(style)
		if style == "smooth" then
			gl.Enable(gl.e.GL_POINT_SMOOTH)
		else
			gl.Disable(gl.e.GL_POINT_SMOOTH)
		end
		
		STYLE = style
	end
	
	function surface.GetPointStyle()
		return STYLE
	end
	
	function surface.SetPointSize(size)
		gl.PointSize(size)
		SIZE = size
	end
	
	function surface.GetPointSize()
		return SIZE
	end
	
	function surface.DrawPoint(x, y)
		gl.Disable(gl.e.GL_TEXTURE_2D)
		gl.Begin(gl.e.GL_POINTS)
			gl.Vertex2f(x, y)
		gl.End()
	end
end

function surface.DrawCircle(x, y, radius, width, resolution)
	resolution = resolution or 16
	
	local spacing = (resolution/radius) - 0.1
	
	for i = 0, resolution do		
		local i1 = ((i+0) / resolution) * math.pi * 2
		local i2 = ((i+1 + spacing) / resolution) * math.pi * 2
		
		surface.DrawLine(
			x + math.sin(i1) * radius, 
			y + math.cos(i1) * radius, 
			
			x + math.sin(i2) * radius, 
			y + math.cos(i2) * radius, 
			width
		)
	end
end

event.AddListener("RenderContextInitialized", nil, surface.Initialize)

if RELOAD then
	surface.Initialize()
end

return surface
