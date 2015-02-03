local gl = require("lj-opengl") -- OpenGL
local render = (...) or _G.render

render.matrices = {
	projection_2d = Matrix44(),
	projection_3d = Matrix44(),
	view_2d = Matrix44(),
	view_3d = Matrix44(),
	world = Matrix44(),
	
	vpm_matrix = Matrix44(),
	vp_matrix = Matrix44(),
	vp_3d_inverse = Matrix44(),
	projection_3d_inverse = Matrix44(),
	view_2d_inverse = Matrix44(),
	view_3d_inverse = Matrix44(),
}

render.camera = render.camera or {
	x = 0,
	y = 0,
	
	-- if this is defined here it will be "1000" in Update and other events
	--w = 1000,
	--h = 1000,
	
	pos = Vec3(0,0,0),
	ang = Ang3(0,0,0),
	
	pos2d = Vec2(0,0),
	ang2d = 0,
	zoom2d = 1,
	
	fov = 75,
	farz = 32000,
	nearz = 0.1,
	
	ratio = 1,
}

local cam = render.camera

-- useful for shaders
function render.GetCameraPosition()
	return cam.pos
end

function render.GetCameraAngles()
	return cam.ang
end

function render.GetCameraFOV()
	return cam.fov
end

-- projection  
do
	-- this isn't really matrix related..
	function render.SetViewport(x, y, w, h)	
		cam.x = x or cam.x
		cam.y = y or cam.y
		cam.w = w or cam.w
		cam.h = h or cam.h
		
		cam.ratio = cam.w / cam.h 
	
		gl.Viewport(cam.x, cam.y, cam.w, cam.h)
		gl.Scissor(cam.x, cam.y, cam.w, cam.h)
		
		local proj = render.matrices.projection_2d

		proj:LoadIdentity()
		proj:Ortho(0, cam.w, cam.h, 0, -1, 1)
	end
	
	do
		local stack = {}
		
		function render.PushViewport(x, y, w, h)
			table.insert(stack, {cam.x, cam.y, cam.w, cam.h})
					
			render.SetViewport(x, y, w, h)
		end
		
		function render.PopViewport()
			render.SetViewport(unpack(table.remove(stack)))
		end
	end

	function render.Start2D(x, y, w, h)				
		render.PushWorldMatrix()
		
		x = x or cam.x 
		y = y or cam.y
		w = w or cam.w
		h = h or cam.h
		
		render.Translate(x, y, 0)
		
		cam.x = x 
		cam.y = y
		cam.w = w
		cam.h = h
		
		gl.Disable(gl.e.GL_DEPTH_TEST)				
	end
	
	function render.End2D()	
		render.PopWorldMatrix()
	--	render.PopViewport() 
	end
	
	local last_farz
	local last_nearz
	local last_fov
	local last_ratio
		
	function render.Start3D(pos, ang, fov, nearz, farz)				
		cam.fov = fov or cam.fov
		cam.nearz = nearz or cam.nearz
		cam.farz = farz or cam.farz
				
		if 
			last_fov ~= cam.fov or
			last_nearz ~= cam.nearz or
			last_farz ~= cam.farz
		then
			local proj = render.matrices.projection_3d
		
			proj:LoadIdentity()
			proj:Perspective(cam.fov, cam.nearz, cam.farz, cam.ratio) 
			--proj:OpenGLFunc("Perspective", cam.fov, cam.nearz, cam.farz, cam.ratio)
			
			last_fov = cam.fov
			last_nearz = cam.nearz
			last_farz = cam.farz
			
			render.matrices.projection_3d_inverse = proj:GetInverse()
		end
		
		if pos and ang then
			render.SetupView3D(pos, ang, fov)
		end
				
		gl.Enable(gl.e.GL_DEPTH_TEST) 
		
		render.PushWorldMatrix()
	end
	
	event.AddListener("GBufferInitialized", "reset_camera_projection", function()
		last_fov = nil
		last_nearz = nil
		last_farz = nil	
	end)
	
	function render.End3D()
		render.PopWorldMatrix()
	end		
end

function render.SetupView3D(pos, ang, fov, out)
	cam.pos = pos or cam.pos
	cam.ang = ang or cam.ang
	cam.fov = fov or cam.fov
	
	local view = out or render.matrices.view_3d 
	view:LoadIdentity()		
	
	if ang then
		-- source engine style camera angles
		view:Rotate(ang.r, 0, 0, 1)
		view:Rotate(ang.p + math.pi/2, 1, 0, 0)
		view:Rotate(ang.y, 0, 0, 1)
	end
	
	if pos then
		view:Translate(pos.y, pos.x, pos.z)
	end
	
	if out then return out end
	
	render.matrices.vp_matrix = render.matrices.view_3d * render.matrices.projection_3d
	render.matrices.vp_3d_inverse = render.matrices.vp_matrix:GetInverse()
	render.matrices.view_3d_inverse = render.matrices.view_3d:GetInverse()
end

function render.SetCameraPosition(pos)
	cam.pos = pos
	render.SetupView3D(cam.pos, cam.ang)
end

function render.GetCameraPosition()
	return cam.pos
end

function render.SetCameraAngles(ang)
	cam.ang = ang
	render.SetupView3D(cam.pos, cam.ang)
end

function render.GetCameraAngles()
	return cam.ang
end

function render.SetCameraFOV(fov)
	cam.fov = fov
end

function render.GetCameraFOV()
	return cam.fov
end
  

function render.SetupView2D(pos, ang, zoom)
	cam.pos2d = pos or cam.pos2d
	cam.ang2d = ang or cam.ang2d
	cam.zoom2d = zoom or cam.zoom2d
	
	local view = render.matrices.view_2d 
	view:LoadIdentity()		
		
	if ang then
		local x, y = cam.w/2, cam.h/2
		view:Translate(x, y, 0)
		view:Rotate(ang, 0, 0, 1)
		view:Translate(-x, -y, 0)
	end
	
	if pos then
		view:Translate(pos.x, pos.y, 0)
	end
	
	if zoom then
		local x, y = cam.w/2, cam.h/2
		view:Translate(x, y, 0)
		view:Scale(zoom, zoom, 1)
		view:Translate(-x, -y, 0)
	end
	
	render.matrices.view_2d_inverse = view:GetInverse()
end

-- world
do
	do -- push pop helper
		local stack = {}
		local i = 1
		
		function render.PushWorldMatrixEx(pos, ang, scale, dont_multiply)
			if not stack[i] then
				stack[i] = Matrix44()
			else
				stack[i] = render.matrices.world
			end
			
			if dont_multiply then	
				render.matrices.world = Matrix44()
			else				
				render.matrices.world = stack[i]:Copy()
			end
						
			-- source engine style world orientation
			if pos then
				render.Translate(-pos.y, -pos.x, -pos.z) -- Vec3(left/right, back/forth, down/up)	
			end
			
			if ang then
				render.Rotate(-ang.y, 0, 0, 1)
				render.Rotate(-ang.r, 0, 1, 0)
				render.Rotate(-ang.p, 1, 0, 0) 
			end
			
			if scale then 
				render.Scale(scale.x, scale.y, scale.z) 
			end	
	
			i = i + 1
			
			return render.matrices.world
		end
		
		function render.PushWorldMatrix(mat)
			if not stack[i] then
				stack[i] = Matrix44()
			else
				stack[i] = render.matrices.world
			end

			if mat then
				render.matrices.world = stack[i] * mat
			else
				render.matrices.world = stack[i]:Copy()
			end
			
			i = i + 1
			
			return render.matrices.world
		end
		
		function render.PopWorldMatrix()
			i = i - 1
			
			if i < 1 then
				error("stack underflow", 2)
			end
						
			render.matrices.world = stack[i]
		end
		
		render.matrix_stack = stack
	end
	
	function render.SetWorldMatrixOverride(matrix)
		render.matrices.world_override = matrix
	end
	
	-- world matrix helper functions
	function render.Translate(x, y, z)
		render.matrices.world:Translate(x, y, z)
	end
	
	function render.Rotate(a, x, y, z)
		render.matrices.world:Rotate(a, x, y, z)
	end
	
	function render.Scale(x, y, z)
		render.matrices.world:Scale(x, y, z)
	end
	
	function render.LoadIdentity()
		render.matrices.world:LoadIdentity()
	end	
end  
 
-- these are for shaders and they return the raw float[16] array
 
function render.GetProjectionMatrix3D()
	return render.matrices.projection_3d.m
end

function render.GetProjectionMatrix2D()
	return render.matrices.projection_2d.m
end

function render.GetViewMatrix3D()
	return render.matrices.view_3d.m
end

function render.GetViewMatrix2D()
	return render.matrices.view_2d.m
end

function render.GetWorldMatrix()
	return render.matrices.world_override and render.matrices.world_override.m or render.matrices.world.m
end

function render.GetPVWMatrix2D()
	return ((render.matrices.world_override or render.matrices.world) * render.matrices.view_2d * render.matrices.projection_2d).m
end

function render.GetPVWMatrix3D()
	return ((render.matrices.world_override or render.matrices.world) * render.matrices.view_3d * render.matrices.projection_3d).m
end
