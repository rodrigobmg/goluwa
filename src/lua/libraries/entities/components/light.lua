if not render then return end

local COMPONENT = {}

COMPONENT.Name = "light"
COMPONENT.Require = {"transform"}
COMPONENT.Events = {"Draw3DLights", "DrawShadowMaps"}

prototype.StartStorable()
	prototype.GetSet(COMPONENT, "Color", Color(1, 1, 1))
	
	-- automate this!!
	prototype.GetSet(COMPONENT, "Intensity", 0.5)

	prototype.GetSet(COMPONENT, "Shadow", false)
	prototype.GetSet(COMPONENT, "ShadowCubemap", false)
	prototype.GetSet(COMPONENT, "ShadowSize", 1024)
	prototype.GetSet(COMPONENT, "FOV", 90, {editor_min = 0, editor_max = 180})
	prototype.GetSet(COMPONENT, "NearZ", 1)
	prototype.GetSet(COMPONENT, "FarZ", 32000)
	prototype.GetSet(COMPONENT, "ProjectFromCamera", false) 
	prototype.GetSet(COMPONENT, "OrthoSize", 0)
	prototype.GetSet(COMPONENT, "LensFlare", false)
prototype.EndStorable()

if GRAPHICS then	
	local gl = require("graphics.ffi.opengl")
	
	render.shadow_maps = render.shadow_maps or utility.CreateWeakTable()
	
	function COMPONENT:OnAdd(ent)
		render.LoadModel("models/cube.obj", function(meshes)
			self.light_mesh = meshes[1]
		end)
	end

	function COMPONENT:OnRemove(ent)
		render.shadow_maps[self] = nil
	end
	
	function COMPONENT:SetShadow(b)
		self.Shadow = b
		if not b then
			render.shadow_maps[self] = nil
		end
	end
	
	function COMPONENT:OnDraw3DLights()
		if not self.light_mesh then return end -- grr
		
		if self.Shadow then			
			self:DrawShadowMap()
		end
		
		-- automate this!!
		render.gbuffer_light_shader.light_color = self.Color
		render.gbuffer_light_shader.light_intensity = self.Intensity
		render.gbuffer_light_shader.light_shadow = self.Shadow
		render.gbuffer_light_shader.light_point_shadow = self.ShadowCubemap
		render.gbuffer_light_shader.project_from_camera = self.ProjectFromCamera
		
		local transform = self:GetComponent("transform")
		
		render.camera_3d:SetWorld(transform:GetMatrix())
		local mat = render.camera_3d:GetMatrices().view_world
		local x,y,z = mat:GetTranslation()
		
		render.gbuffer_light_shader.light_view_pos:Set(x,y,z)
		render.gbuffer_light_shader.light_radius = transform:GetSize()		
		
		render.SetShaderOverride(render.gbuffer_light_shader)
		self.light_mesh:Draw()
		render.SetShaderOverride()
	end

	local directions = {
		{e = gl.e.GL_TEXTURE_CUBE_MAP_POSITIVE_X, rot = QuatDeg3(0,90,0)},
		{e = gl.e.GL_TEXTURE_CUBE_MAP_NEGATIVE_X, rot = QuatDeg3(0,-90,0)},
		{e = gl.e.GL_TEXTURE_CUBE_MAP_POSITIVE_Y, rot = QuatDeg3(90,0,0)},
		{e = gl.e.GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, rot = QuatDeg3(-90,0,0)},
		{e = gl.e.GL_TEXTURE_CUBE_MAP_POSITIVE_Z, rot = QuatDeg3(0,0,0)},
		{e = gl.e.GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, rot = QuatDeg3(180,0,0)},
	}
	
	render.shadow_map_shader = nil
						
	function COMPONENT:DrawShadowMap(ortho_divider)
		if not self.Shadow then
			if render.shadow_maps[self] then
				render.shadow_maps[self] = nil
			end
			return 
		end
		
		if not render.shadow_map_shader then
			render.shadow_map_shader = render.CreateShader({
				name = "shadow_map",
				vertex = {
					mesh_layout = {
						{pos = "vec3"},
						{normal = "vec3"},
						{uv = "vec2"},
						{texture_blend = "float"},
					},	
					source = "gl_Position = g_projection_view_world * vec4(pos, 1);"
				},
				fragment = {
					mesh_layout = {
						{uv = "vec2"},
					},
					source = [[
						out vec4 out_color;
						
						void main()
						{				
							if (lua[Translucent = false] && texture(lua[DiffuseTexture = "sampler2D"], uv).a < 0.9)
							{
								discard;
							}
						}
					]],
				},
			})
		end
			
		if not render.shadow_maps[self] then
			local cube_texture = {
				name = "cubemap",
				attach = "color0",
				texture_format = {
					type = "cubemap",
					internal_format = "r32f",
					upload_format = "red",
					min_filter = "linear",
					wrap_s = "clamp_to_edge",
					wrap_t = "clamp_to_edge",
					wrap_r = "clamp_to_edge",
					mip_map_levels = 0,
				}
			}
						
			local shadow_map = render.CreateFrameBuffer()
			shadow_map:SetSize(Vec2() + self.ShadowSize)
			
			local tex = render.CreateTexture("2d")
			tex:SetSize(Vec2() + self.ShadowSize)
			tex:SetInternalFormat("depth_component32f")
			tex:SetDepthTextureMode("red")
			tex:SetupStorage()
			
			shadow_map:SetTexture("depth", tex)
		
			if self.ShadowCubemap then
				local tex = render.CreateTexture("cubemap")
				tex:SetInternalFormat("r32f")
				tex:SetWrapS("clamp_to_edge")
				tex:SetWrapT("clamp_to_edge")
				tex:SetWrapR("clamp_to_edge")
				tex:SetMinFilter("linear")
				tex:SetMipMapLevels(0)
				tex:SetupStorage()				
				shadow_map:SetTexture(1, tex)
			end
			
			self.shadow_map = shadow_map
			
			render.shadow_maps[self] = self.shadow_map
		end
		
		render.EnableDepth(true)	
		--render.SetBlendMode("additive")
		render.SetBlendMode("one", "one")
		render.SetCullMode("front")
	
		local transform = self:GetComponent("transform")
		local pos = transform:GetPosition()
		local rot = transform:GetRotation()
		
		self.shadow_map:Begin()
		self.shadow_map:Clear()
				
		---self.shadow_map:SetWriteBuffer("depth")
		
		render.SetCullMode("front", true)
		render.SetShaderOverride(render.shadow_map_shader)
				
		for i, info in ipairs(directions) do
			if self.ShadowCubemap then
				self.shadow_map:SetReadBuffer("depth")
				self.shadow_map:SetWriteBuffer("cubemap", info.e)
			end
			
			-- setup the view matrix
			local view = Matrix44()
			
			if self.ShadowCubemap then
				view:SetRotation(info.rot)
			else
				view:SetRotation(rot)
			end

			if self.ProjectFromCamera then
				pos = render.camera_3d:GetPosition()
				view:Translate(pos.y, pos.x, pos.z)
			else
				view:Translate(pos.y, pos.x, pos.z)			
			end
		
			-- setup the projection matrix
			local projection = Matrix44()
			
			if self.OrthoSize == 0 then
				projection:Perspective(math.rad(self.FOV), render.camera_3d.FarZ, render.camera_3d.NearZ, render.camera_3d.Viewport.w / render.camera_3d.Viewport.h) 
			else
				local size = self.OrthoSize * (ortho_divider or 1)
				projection:Ortho(-size, size, -size, size, size, -size) 
			end
			
			local old_view = render.camera_3d:GetView()
			local old_projection = render.camera_3d:GetProjection()
			
			render.camera_3d:SetView(view)
			render.camera_3d:SetProjection(projection)
			
			render.gbuffer_light_shader.light_projection_view = render.camera_3d:GetMatrices().projection_view
			
			-- render the scene with this matrix
			
			render.Draw3DScene()
			
			render.camera_3d:SetView(old_view)
			render.camera_3d:SetProjection(old_projection)
			
			if not self.ShadowCubemap then 
				break 
			end
		end
		
		render.SetShaderOverride()
		render.SetCullMode(nil, false)
		
		render.gbuffer_light_shader.cascade_pass = i
		render.gbuffer_light_shader.tex_shadow_map = self.shadow_map:GetTexture("depth")
		
		if self.ShadowCubemap then 	
			render.gbuffer_light_shader.tex_shadow_map_cube = self.shadow_map:GetTexture("cubemap")
		end
		
		render.EnableDepth(false)
		
		self.shadow_map:End()
	end
end

prototype.RegisterComponent(COMPONENT)

if RELOAD then
	render.InitializeGBuffer()
end