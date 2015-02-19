local COMPONENT = {}

COMPONENT.Name = "physics"
COMPONENT.Require = {"transform"}
COMPONENT.Events = {"Update"}

COMPONENT.Network = {
	Position = {"vec3", 1/30, "unreliable", false, 70},
	Rotation = {"quat", 1/30, "unreliable", false, 70},
	
	Gravity = {"vec3", 1/5},
	Mass = {"unsigned long", 1/5},
	LinearDamping = {"float", 1/5},
	AngularDamping = {"float", 1/5},
	MassOrigin = {"vec3", 1/5},
	PhysicsBoxScale = {"vec3", 1/5},
	PhysicsSphereRadius = {"float", 1/5},
	PhysicsCapsuleZRadius = {"float", 1/5},
	PhysicsCapsuleZHeight = {"float", 1/5},
	AngularSleepingThreshold = {"float", 1/5},
	LinearSleepingThreshold = {"float", 1/5},
	SimulateOnClient = {"boolean", 1/5},
	PhysicsModelPath = {"string", 1/10, "reliable", true}, -- last true means don't send default path (blank path in this case)
}

function COMPONENT:Initialize()
	self.rigid_body = NULL	
end

prototype.StartStorable()

	prototype.GetSet(COMPONENT, "SimulateOnClient", false)	
	prototype.GetSet(COMPONENT, "Position", Vec3(0, 0, 0))
	prototype.GetSet(COMPONENT, "Rotation", Quat(0, 0, 0, 1))
	prototype.GetSet(COMPONENT, "PhysicsModelPath", "")
	
	do		
		for _, info in pairs(prototype.GetRegistered("physics_body").prototype_variables) do
			prototype.GetSet(COMPONENT, info.var_name, info.default)
			
			COMPONENT[info.set_name] = function(self, var)
				self[info.var_name] = var
				
				if self.rigid_body:IsValid() then
					self.rigid_body[info.set_name](self.rigid_body, var)
				end
			end
		
			COMPONENT[info.get_name] = function(self)			
				if self.rigid_body:IsValid() then
					return self.rigid_body[info.get_name](self.rigid_body)
				end
				
				return self[info.var_name]
			end
		end
	end
	
prototype.EndStorable()

prototype.GetSet(COMPONENT, "PhysicsModel", nil)

local function to_bullet(self)
	if not self.rigid_body:IsValid() or not self.rigid_body:IsPhysicsValid() then return end
	
	local pos = self.Position
	local rot = self.Rotation
	
	local out = Matrix44()
	out:SetTranslation(pos.x, pos.y, pos.z)  
	out:SetRotation(rot)
	
	self.rigid_body:SetMatrix(out)
end

local function from_bullet(self)
	if not self.rigid_body:IsValid() or not self.rigid_body:IsPhysicsValid() then return Matrix44() end

	local out = self.rigid_body:GetMatrix()
 	
--	local x,y,z = out:GetTranslation()
	--local p,y,r = out:GetAngles()
	
--	local out = Matrix44()
			
	--out:Translate(x, y, z)
	

	--out:Rotate(math.deg(y), 0, 1, 0)
	--out:Rotate(math.deg(r), 1, 0, 0)
	
	--out:Scale(1,-1,-1)
			
--	print(self:GetEntity(), self.Position, out:GetTranslation())
			
	return out:Copy() 
end

function COMPONENT:UpdatePhysicsObject()
	to_bullet(self)
end

local temp = Matrix44()

function COMPONENT:SetPosition(vec)
	self.Position = vec
	to_bullet(self)
end

function COMPONENT:GetPosition()
	return Vec3(from_bullet(self):GetTranslation())
end

function COMPONENT:SetRotation(rot)
	self.Rotation = rot
	to_bullet(self)
end

function COMPONENT:GetRotation()
	return from_bullet(self):GetRotation()
end

function COMPONENT:SetAngles(ang)
	self:SetRotation(Quat(0,0,0,1):SetAngles(ang))
end

function COMPONENT:GetAngles()
	return self:GetRotation():GetAngles()
end

do
	local assimp = require("lj-assimp")

	function COMPONENT:InitPhysicsSphere(rad)
		local tr = self:GetComponent("transform")
		self.rigid_body:SetMatrix(tr:GetMatrix():Copy())
		
		self.rigid_body:InitPhysicsSphere(rad)
		
		if SERVER then
			local obj = self:GetComponent("network")
			if obj:IsValid() then obj:CallOnClientsPersist(self.Name, "InitPhysicsSphere", rad) end
		end
		
		to_bullet(self)
	end
	
	function COMPONENT:InitPhysicsBox(scale)
		local tr = self:GetComponent("transform")
		self.rigid_body:SetMatrix(tr:GetMatrix():Copy())
		
		if scale then
			self.rigid_body:InitPhysicsBox(scale)
		else
			self.rigid_body:InitPhysicsBox()
		end
		
		if SERVER then
			local obj = self:GetComponent("network")
			if obj:IsValid() then obj:CallOnClientsPersist(self.Name, "InitPhysicsBox", scale) end
		end
		
		to_bullet(self)
	end
	
	function COMPONENT:InitPhysicsCapsuleZ()
		local tr = self:GetComponent("transform")
		self.rigid_body:SetMatrix(tr:GetMatrix():Copy())
		

		self.rigid_body:InitPhysicsCapsuleZ()
		
		if SERVER then
			local obj = self:GetComponent("network")
			if obj:IsValid() then obj:CallOnClientsPersist(self.Name, "InitPhysicsCapsuleZ") end
		end
		
		to_bullet(self)
	end
	
	function COMPONENT:SetPhysicsModelPath(path)
		self.PhysicsModelPath = path
		
		utility.LoadPhysicsModel(path, function(physics_meshes)
			if not self:IsValid() then return end
			
			-- TODO: support for more bodies
			if #physics_meshes > 1 then
				
				for k,v in pairs(self:GetEntity():GetChildren()) do
					if v.physics_chunk then
						v:Remove()
					end
				end
				
				for i, mesh in ipairs(physics_meshes) do
					local chunk = entities.CreateEntity("physical", self:GetEntity(), {exclude_components = {"network"}})
					chunk:SetHideFromEditor(true)
					chunk:SetName("physics chunk " .. i)
					chunk:SetPhysicsModel(mesh)
					chunk:InitPhysicsTriangles(true)
					chunk:SetMass(0)
					chunk.physics_chunk = true
				end
			else
				self:SetPhysicsModel(physics_meshes[1])
			end
			
			to_bullet(self)
		end, function(err)
			logf("%s failed to load physics model %q: %s\n", self, path, err)
			for k,v in pairs(self:GetEntity():GetChildren()) do
				if v.physics_chunk then
					v:Remove()
				end
			end
		end)
	end
	
	function COMPONENT:InitPhysicsConvexHull()
		local tr = self:GetComponent("transform")
		self.rigid_body:SetMatrix(tr:GetMatrix():Copy())
		
		if self:GetPhysicsModel() then
			self.rigid_body:InitPhysicsConvexHull(self:GetPhysicsModel().vertices.pointer, self:GetPhysicsModel().vertices.count)
		end
		
		if SERVER then
			local obj = self:GetComponent("network")
			if obj:IsValid() then obj:CallOnClientsPersist(self.Name, "InitPhysicsConvexHull") end
		end
		
		to_bullet(self)
	end
	
	function COMPONENT:InitPhysicsConvexTriangles()
		local tr = self:GetComponent("transform")
		self.rigid_body:SetMatrix(tr:GetMatrix():Copy())
		
		if self:GetPhysicsModel() then
			self.rigid_body:InitPhysicsConvexTriangles(self:GetPhysicsModel())
		end
		
		if SERVER then
			local obj = self:GetComponent("network")
			if obj:IsValid() then obj:CallOnClientsPersist(self.Name, "InitPhysicsConvexTriangles") end
		end
		
		to_bullet(self)
	end
		
	function COMPONENT:InitPhysicsTriangles(quantized_aabb_compression)
		local tr = self:GetComponent("transform")
		self.rigid_body:SetMatrix(tr:GetMatrix():Copy())
		
		if self:GetPhysicsModel() then
			self.rigid_body:InitPhysicsTriangles(self:GetPhysicsModel(), quantized_aabb_compression)
		end
		
		if SERVER then
			local obj = self:GetComponent("network")
			if obj:IsValid() then obj:CallOnClientsPersist(self.Name, "InitPhysicsTriangles") end
		end
		
		to_bullet(self)
	end
end		

local zero = Vec3()

function COMPONENT:OnUpdate()
	if not self.rigid_body:IsValid() or not self.rigid_body:IsPhysicsValid() then return end
	
	local transform = self:GetComponent("transform")
	
	transform:SetTRMatrix(from_bullet(self))
	
	if CLIENT then
		if not self.SimulateOnClient then
			if self.rigid_body:GetMass() ~= 0 then	
				self.rigid_body:SetVelocity(zero)
				self.rigid_body:SetAngularVelocity(zero)
				self.rigid_body:SetMass(0)
				to_bullet(self)
			end
		else
			if self.rigid_body:GetMass() ~= self:GetMass() then
				self:SetMass(self:GetMass())
			end
		end
	end
end

function COMPONENT:OnAdd(ent)	
	self:GetComponent("transform"):SetSkipRebuild(true)
	self.rigid_body = physics.CreateBody()
	self.rigid_body.ent = self
end

function COMPONENT:OnRemove(ent)
	if self.rigid_body:IsValid() then
		self.rigid_body:Remove()
	end
end

prototype.RegisterComponent(COMPONENT)

--include("physics_container.lua")