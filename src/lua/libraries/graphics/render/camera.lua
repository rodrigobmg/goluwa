local render = ... or _G.render

local META = prototype.CreateTemplate("camera")

META:StartStorable()

META:GetSet("Position", Vec3(0, 0, 0), {callback = "InvalidateView"})
META:GetSet("Angles", Ang3(0, 0, 0), {callback = "InvalidateView"})
META:GetSet("FOV", math.pi/2, {callback = "InvalidateProjection"})
META:GetSet("Zoom", 1, {callback = "InvalidateView"})
META:GetSet("NearZ", 0.1, {callback = "InvalidateProjection"})
META:GetSet("FarZ", 32000, {callback = "InvalidateProjection"})
META:GetSet("Viewport", Rect(0, 0, 1000, 1000), {callback = "InvalidateProjection"})
META:GetSet("3D", true, {callback = "Invalidate"})
META:GetSet("Ortho", false, {callback = "InvalidateProjection"})

META:EndStorable()

META:GetSet("Projection", nil, {callback = "InvalidateProjection"})
META:GetSet("View", nil, {callback = "InvalidateView"})

META:GetSet("World", Matrix44(), {callback = "InvalidateWorld"})

do
	META.matrix_stack_i = 1

	function META:PushWorldEx(pos, ang, scale, dont_multiply)
		self.matrix_stack[self.matrix_stack_i] = self.World

		if dont_multiply then
			self.World = Matrix44()
		else
			self.World = self.matrix_stack[self.matrix_stack_i]:Copy()
		end

		-- source engine style world orientation
		if pos then
			self:TranslateWorld(-pos.y, -pos.x, -pos.z) -- Vec3(left/right, back/forth, down/up)
		end

		if ang then
			self:RotateWorld(-ang.y, 0, 0, 1)
			self:RotateWorld(-ang.z, 0, 1, 0)
			self:RotateWorld(-ang.x, 1, 0, 0)
		end

		if scale then
			self:ScaleWorld(scale.x, scale.y, scale.z)
		end

		self.matrix_stack_i = self.matrix_stack_i + 1

		self:InvalidateWorld()

		return self.World
	end

	function META:PushWorld(mat, dont_multiply)
		self.matrix_stack[self.matrix_stack_i] = self.World

		if dont_multiply then
			if mat then
				self.World = mat
			else
				self.World = Matrix44()
			end
		else
			if mat then
				self.World = self.matrix_stack[self.matrix_stack_i] * mat
			else
				self.World = self.matrix_stack[self.matrix_stack_i]:Copy()
			end
		end

		self.matrix_stack_i = self.matrix_stack_i + 1

		self:InvalidateWorld()

		return self.World
	end

	function META:PopWorld()
		self.matrix_stack_i = self.matrix_stack_i - 1

		--if self.matrix_stack_i < 1 then
		--	error("stack underflow", 2)
		--end

		self.World = self.matrix_stack[self.matrix_stack_i]

		self:InvalidateWorld()
	end

	-- world matrix helper functions
	function META:TranslateWorld(x, y, z)
		self.World:Translate(x, y, z)
		self:InvalidateWorld()
	end

	function META:RotateWorld(a, x, y, z)
		self.World:Rotate(a, x, y, z)
		self:InvalidateWorld()
	end

	function META:ScaleWorld(x, y, z)
		self.World:Scale(x, y, z)
		self:InvalidateWorld()
	end

	function META:ShearWorld(x, y, z)
		self.World:SetShear(x, y, z)
		self:InvalidateWorld()
	end

	function META:LoadIdentityWorld()
		self.World:LoadIdentity()
		self:InvalidateWorld()
	end
end

do -- 3d 2d
	function META:Start3D2DEx(pos, ang, scale)
		pos = pos or Vec3(0, 0, 0)
		ang = ang or Ang3(0, 0, 0)
		scale = scale or Vec3(4 * (self.Viewport.w / self.Viewport.h), 4 * (self.Viewport.w / self.Viewport.h), 1)

		self:Set3D(true)
		self.oldpos, self.oldang, self.oldfov = self:GetPosition(), self:GetAngles(), self:GetFOV()
		self:SetPosition(render.camera_3d:GetPosition())
		self:SetAngles(render.camera_3d:GetAngles())
		self:SetFOV(render.camera_3d:GetFOV())
		self:PushWorldEx(pos, ang, Vec3(scale.x / self.Viewport.w, scale.y / self.Viewport.h, 1))
		self:Rebuild()
	end

	function META:Start3D2D(mat, dont_multiply)
		--self:Set3D(true)
		self:Rebuild()

		self:PushWorld(mat, dont_multiply)
	end

	function META:End3D2D()
		self:PopWorld()
		self:Set3D(false)
		self:SetPosition(self.oldpos)
		self:SetAngles(self.oldang)
		self:SetFOV(self.oldfov)
		self:Rebuild()
	end

	function META:ScreenToWorld(x, y)
		local m = (self:GetMatrices().view * self:GetMatrices().world):GetInverse()

		if self:Get3D() then
			x = ((x / self.Viewport.w) - 0.5) * 2
			y = ((y / self.Viewport.h) - 0.5) * 2

			local cursor_x, cursor_y, cursor_z = m:TransformVector(self:GetMatrices().projection_inverse:TransformVector(x, -y, 1))
			local camera_x, camera_y, camera_z = m:TransformVector(0, 0, 0)

			--local intersect = camera + ( camera.z / ( camera.z - cursor.z ) ) * ( cursor - camera )

			local z = camera_z / ( camera_z - cursor_z )
			local intersect_x = camera_x + z * ( cursor_x - camera_x )
			local intersect_y = camera_y + z * ( cursor_y - camera_y )

			return intersect_x, intersect_y
		else
			local x, y = m:TransformVector(x, y, 1)
			return x, y
		end
	end
end

function META:Rebuild(what)
	local vars = self.shader_variables

	if what == nil or what == "projection" then
		if self.Projection then
			vars.projection = self.Projection
		else
			local proj = Matrix44()

			if self.Ortho then
				local mult = 100 * self.FOV
				local ratio = self.Viewport.h / self.Viewport.w
				proj:Ortho(
					-mult, mult,
					ratio * -mult, ratio * mult,
					0, self.FarZ
				)
			else
				if self:Get3D() then
					proj:Perspective(self.FOV, self.FarZ, self.NearZ, self.Viewport.w / self.Viewport.h)
					proj:Translate(self.Viewport.x, self.Viewport.y, 0)
				else
					proj:Ortho(self.Viewport.x, self.Viewport.w, self.Viewport.h, self.Viewport.y, -1, 1)
				end
			end

			vars.projection = proj
		end
	end

	if what == nil or what == "view" then
		if self.View then
			vars.view = self.View
		else
			local view = Matrix44()

			if self:Get3D() then
				view:Rotate(self.Angles.z, 0, 0, 1)
				view:Rotate(self.Angles.x + math.pi/2, 1, 0, 0)
				view:Rotate(self.Angles.y, 0, 0, 1)

				view:Translate(self.Position.y, self.Position.x, self.Position.z)
			else
				local x, y

				x, y = self.Viewport.w/2, self.Viewport.h/2
				view:Translate(x, y, 0)
				view:Rotate(self.Angles.y, 0, 0, 1)
				view:Translate(-x, -y, 0)

				view:Translate(self.Position.x, self.Position.y, 0)

				x, y = self.Viewport.w/2, self.Viewport.h/2
				view:Translate(x, y, 0)
				view:Scale(self.Zoom, self.Zoom, 1)
				view:Translate(-x, -y, 0)
			end

			vars.view = view
		end
	end

	if self:Get3D() then
		if what == nil or what == "projection" or what == "view" then
			vars.projection_inverse = vars.projection:GetInverse()
			vars.view_inverse = vars.view:GetInverse()

			vars.projection_view = vars.view * vars.projection
			vars.projection_view_inverse = vars.projection_view:GetInverse()
		end

		if what == nil or what == "view" or what == "world" then
			vars.world = self.World
			vars.view_world =  vars.world * vars.view
			vars.view_world_inverse = vars.view_world:GetInverse()
			vars.normal_matrix = vars.view_world_inverse:GetTranspose()
		end

		--if type == nil or type == "world" then
			--vars.world_inverse = vars.world:GetInverse()
		--end
	else
		vars.world = self.World
	end

	vars.projection_view_world = vars.world * vars.view * vars.projection
end

function META:InvalidateProjection()
	if self.rebuild_matrix then self.rebuild_matrix = true return end
	self.rebuild_matrix = "projection"
end

function META:InvalidateView()
	if self.rebuild_matrix and self.rebuild_matrix ~= "view" and self.rebuild_matrix ~= "projection" then return end
	self.rebuild_matrix = "view"
end

function META:InvalidateWorld()
	if self.rebuild_matrix and self.rebuild_matrix ~= "world" then return end
	self.rebuild_matrix = "world"
end

function META:Invalidate()
	self.rebuild_matrix = true
end

function META:GetMatrices()
	if self.rebuild_matrix then
		if self.rebuild_matrix == true then
			self:Rebuild()
		else
			self:Rebuild(self.rebuild_matrix)
		end
		self.rebuild_matrix = false
	end

	return self.shader_variables
end

META:Register()

function render.CreateCamera()
	local self = prototype.CreateObject("camera")
	self.matrix_stack = {}
	self.shader_variables = {}
	self:Rebuild()
	return self
end

local old_data
if render.camera_3d then
	old_data = render.camera_3d:GetStorableTable()
end

render.camera_2d = render.CreateCamera()
render.camera_2d:Set3D(false)

render.camera_3d = render.CreateCamera()
if old_data then
	render.camera_3d:SetStorableTable(old_data)
end

local variables = {
	"projection",
	"projection_inverse",

	"view",
	"view_inverse",

	"world",
	"world_inverse",

	"projection_view",
	"projection_view_inverse",

	"view_world",
	"view_world_inverse",
	"projection_view_world",

	"normal_matrix",
}

for _, v in pairs(variables) do
	render.SetGlobalShaderVariable("g_" .. v .. "_2d", function() return render.camera_2d:GetMatrices()[v] end, "mat4")
	render.SetGlobalShaderVariable("g_" .. v, function() return render.camera_3d:GetMatrices()[v] end, "mat4")
end

render.SetGlobalShaderVariable("g_cam_nearz", function() return render.camera_3d.NearZ end, "float")
render.SetGlobalShaderVariable("g_cam_farz", function() return render.camera_3d.FarZ end, "float")
render.SetGlobalShaderVariable("g_cam_fov", function() return render.camera_3d.FOV end, "float")

render.SetGlobalShaderVariable("g_cam_pos", function() return render.camera_3d:GetPosition() end, "vec3")
render.SetGlobalShaderVariable("g_cam_up", function() return render.camera_3d:GetAngles():GetUp() end, "vec3")
render.SetGlobalShaderVariable("g_cam_forward", function() return render.camera_3d:GetAngles():GetForward() end, "vec3")
render.SetGlobalShaderVariable("g_cam_right", function() return render.camera_3d:GetAngles():GetRight() end, "vec3")

render.AddGlobalShaderCode([[
float get_depth(vec2 uv)
{
	return texture(tex_depth, uv).r;
}]])

render.AddGlobalShaderCode([[
float linearize_depth(float depth)
{
	return (2.0 * g_cam_nearz) / (g_cam_farz + g_cam_nearz - depth * (g_cam_farz - g_cam_nearz));
}]])

render.AddGlobalShaderCode([[
float get_linearized_depth(vec2 uv)
{
	return linearize_depth(get_depth(uv));
}]])

render.AddGlobalShaderCode([[
vec3 get_camera_dir(vec2 uv)
{
    vec4 device_normal = vec4(uv * 2 - 1, 0.0, 1.0);
    vec3 eye_normal = normalize((g_projection_inverse * device_normal).xyz);
    vec3 world_normal = normalize(mat3(g_view_inverse)*eye_normal);
    return world_normal;
}]])


