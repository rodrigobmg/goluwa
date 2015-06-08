local COMPONENT = {}

COMPONENT.Name = "model"
COMPONENT.Require = {"transform"}

prototype.StartStorable()
	prototype.GetSet(COMPONENT, "MaterialOverride", nil)
	prototype.GetSet(COMPONENT, "Cull", true)	
	prototype.GetSet(COMPONENT, "ModelPath", "models/cube.obj")
	prototype.GetSet(COMPONENT, "BBMin", Vec3())
	prototype.GetSet(COMPONENT, "BBMax", Vec3())
prototype.EndStorable()

prototype.GetSet(COMPONENT, "Model", nil)

COMPONENT.Network = {
	ModelPath = {"string", 1/5, "reliable", true},
	Cull = {"boolean", 1/5},
}

if GRAPHICS then 
	function COMPONENT:Initialize()
		self.sub_models = {}
		self:SetModelPath(self.ModelPath)
	end

	function COMPONENT:OnAdd(ent)
		table.insert(render.scene_3d, self)
	end

	function COMPONENT:OnRemove(ent)
		table.removevalue(render.scene_3d, self)
	end

	function COMPONENT:SetModelPath(path)
		self:RemoveMeshes()
		
		self.ModelPath = path
		
		render.LoadModel(
			path, 
			function() 
				if steam.LoadMap and path:endswith(".bsp") then
					steam.SpawnMapEntities(path, self:GetEntity())
				end
			end, 
			function(mesh)
				self:AddMesh(mesh)
				self:BuildBoundingBox()
			end,
			function(err)
				logf("%s failed to load model %q: %s\n", self, path, err)
				self:RemoveMeshes()
			end
		)
	end
	
	do		
		function COMPONENT:AddMesh(mesh)
			checkx(mesh, "mesh_builder")
			table.insert(self.sub_models, mesh)
			mesh:CallOnRemove(function()
				if self:IsValid() then
					self:RemoveMesh(mesh)
				end
			end, self)
		end
		
		function COMPONENT:RemoveMesh(mesh)
			for i, _mesh in ipairs(self.sub_models) do
				if mesh == _mesh then
					table.remove(self.sub_models, i)
					break
				end
			end
		end
		
		function COMPONENT:RemoveMeshes()
			table.clear(self.sub_models)
			collectgarbage("step")
		end
		
		function COMPONENT:GetMeshes()
			return self.sub_models
		end
	end

	do		
		local function corner_helper(self, i, j)
			return bit.band(bit.rshift(i, j), 1) == 0 and self.BBMin or self.BBMax
		end
		
		function COMPONENT:BuildBoundingBox()	
			local min, max = Vec3(), Vec3()

			for i, sub_model in ipairs(self.sub_models) do				
				if sub_model.BBMin.x < min.x then min.x = sub_model.BBMin.x end
				if sub_model.BBMin.y < min.y then min.y = sub_model.BBMin.y end
				if sub_model.BBMin.z < min.z then min.z = sub_model.BBMin.z end
				
				if sub_model.BBMax.x > max.x then max.x = sub_model.BBMax.x end
				if sub_model.BBMax.y > max.y then max.y = sub_model.BBMax.y end
				if sub_model.BBMax.z > max.z then max.z = sub_model.BBMax.z end
			end
			
			self.BBMin = min
			self.BBMax = max
			
			self.corners = {}
			
			for i = 0, 7 do
				local x = corner_helper(self, i, 2).x
				local y = corner_helper(self, i, 1).y
				local z = corner_helper(self, i, 0).z
				
				self.corners[i+1] = Vec3(x, y, z)
			end
		end
	end

	function COMPONENT:Draw()	
		render.camera_3d:SetWorld(self:GetComponent("transform"):GetMatrix())

		if self.corners then
			self.visible = self:GetComponent("transform"):IsPointsVisible(self.corners, render.camera_3d:GetMatrices().projection_view)
		end

		if not self.Cull or self.visible == nil or self.visible == true then
			if self.MaterialOverride then render.SetMaterial(self.MaterialOverride) end
			for i, model in ipairs(self.sub_models) do				
				if not self.MaterialOverride then render.SetMaterial(model.material) end
				model:Draw()
			end
		end
	end
end

prototype.RegisterComponent(COMPONENT)

if RELOAD then
	render.InitializeGBuffer()
end