local bullet = require("lj-bullet3")

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
	AngularSleepingThreshold = {"float", 1/5},
	LinearSleepingThreshold = {"float", 1/5},
	SimulateOnClient = {"boolean", 1/5},
	PhysicsModelPath = {"string", 1/10, "reliable", true}, -- last true means don't send default path (blank path in this case)
}

COMPONENT.matrix = Matrix44()
COMPONENT.rigid_body = NULL

local function DELEGATE(META, field, typ)
	
	if typ == "vec3" then
		prototype.GetSet(META, field, Vec3())
		local name = "Set" .. field
		META[name] = function(s, vec)
			s[field] = vec
			if s.rigid_body:IsValid() then
				s.rigid_body[name](s.rigid_body, -vec.y, -vec.x, -vec.z)
			end
		end
				
		local name = "Get" .. field
		META[name] = function(s, ...)
			if s.rigid_body:IsValid() then
				local x, y, z = s.rigid_body[name](s.rigid_body, ...)
				return Vec3(-y, -x, -z)
			end
			return s[field]
		end
	elseif typ == "ang3" then
		prototype.GetSet(META, field, Ang3())
		local name = "Set" .. field
		META[name] = function(s, ang)
			s[field] = ang
			if s.rigid_body:IsValid() then
				s.rigid_body[name](s.rigid_body, ang.p, ang.y, ang.r)
			end
		end
				
		local name = "Get" .. field
		META[name] = function(s, ...)
			if s.rigid_body:IsValid() then
				local x, y, z = s.rigid_body[name](s.rigid_body, ...)
				return Ang3(x, y, z) 
			end
			return s[field]
		end
	else
		prototype.GetSet(META, field, 0)
		local name = "Set" .. field
		META[name] = function(s, val)
			s[field] = val
			if s.rigid_body:IsValid() then
				s.rigid_body[name](s.rigid_body, val)
			end
		end
		
		local name = "Get" .. field
		META[name] = function(s, val)
			if s.rigid_body:IsValid() then
				return s.rigid_body[name](s.rigid_body)
			end
			return s[field]
		end
	end
end

prototype.StartStorable()

	prototype.GetSet(COMPONENT, "SimulateOnClient", false)

	DELEGATE(COMPONENT, "MassOrigin", "vec3")
	DELEGATE(COMPONENT, "Gravity", "vec3")
	DELEGATE(COMPONENT, "Velocity", "vec3")
	DELEGATE(COMPONENT, "AngularVelocity", "vec3")
	DELEGATE(COMPONENT, "PhysicsBoxScale", "vec3")
	DELEGATE(COMPONENT, "PhysicsSphereRadius")

	DELEGATE(COMPONENT, "Mass")
	DELEGATE(COMPONENT, "AngularDamping")
	DELEGATE(COMPONENT, "LinearDamping")
	DELEGATE(COMPONENT, "LinearSleepingThreshold")
	DELEGATE(COMPONENT, "AngularSleepingThreshold")

	prototype.GetSet(COMPONENT, "Position", Vec3(0, 0, 0))
	prototype.GetSet(COMPONENT, "Rotation", Quat(0, 0, 0, 1))
	prototype.GetSet(COMPONENT, "PhysicsModelPath", "")

prototype.EndStorable()

prototype.GetSet(COMPONENT, "PhysicsModel", nil)

local function to_bullet(self)
	if not self.rigid_body:IsValid() or not self.rigid_body:IsPhysicsValid() then return end
	
	
	local pos = self.Position
	local rot = self.Rotation
	
	local out = Matrix44()
	out:SetTranslation(pos.x, pos.y, pos.z)  
	out:SetRotation(rot)
	
	self.rigid_body:SetMatrix(out.m)
end

local function from_bullet(self)
	if not self.rigid_body:IsValid() or not self.rigid_body:IsPhysicsValid() then return Matrix44() end

	local out = Matrix44()
	out.m = self.rigid_body:GetMatrix()
 	
--	local x,y,z = out:GetTranslation()
	--local p,y,r = out:GetAngles()
	
--	local out = Matrix44()
			
	--out:Translate(x, y, z)
	

	--out:Rotate(math.deg(y), 0, 1, 0)
	--out:Rotate(math.deg(r), 1, 0, 0)
	
	--out:Scale(1,-1,-1)
		
	return out:Copy() 
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
		self.rigid_body:SetMatrix(tr:GetMatrix():Copy().m)
		
		self.rigid_body:InitPhysicsSphere(rad)
		
		if SERVER then
			local obj = self:GetComponent("networked")
			if obj:IsValid() then obj:CallOnClientsPersist(self.Name, "InitPhysicsSphere", rad) end
		end
		
		self:SetPosition(self.Position)
		self:SetRotation(self.Rotation)
	end
	
	function COMPONENT:InitPhysicsBox(scale)
		local tr = self:GetComponent("transform")
		self.rigid_body:SetMatrix(tr:GetMatrix():Copy().m)
		
		if scale then
			self.rigid_body:InitPhysicsBox(scale.x, scale.y, scale.z)
		else
			self.rigid_body:InitPhysicsBox()
		end
		
		if SERVER then
			local obj = self:GetComponent("networked")
			if obj:IsValid() then obj:CallOnClientsPersist(self.Name, "InitPhysicsBox", scale) end
		end
		
		self:SetPosition(self.Position)
		self:SetRotation(self.Rotation)
	end
	
	function COMPONENT:SetPhysicsModelPath(path)
		self.PhysicsModelPath = path
		
		if not vfs.IsFile(path) then
			return nil, path .. " not found"
		end
		
		local scene = assimp.ImportFile(R(path), assimp.e.aiProcessPreset_TargetRealtime_Quality)
		
		if scene.mMeshes[0].mNumVertices == 0 then
			return nil, "no vertices found in " .. path
		end
							
		local vertices = ffi.new("float[?]", scene.mMeshes[0].mNumVertices  * 3)
		local triangles = ffi.new("unsigned int[?]", scene.mMeshes[0].mNumFaces * 3)
		
		ffi.copy(vertices, scene.mMeshes[0].mVertices, ffi.sizeof(vertices))

		local i = 0
		for j = 0, scene.mMeshes[0].mNumFaces - 1 do
			for k = 0, scene.mMeshes[0].mFaces[j].mNumIndices - 1 do
				triangles[i] = scene.mMeshes[0].mFaces[j].mIndices[k]
				i = i + 1 
			end
		end
					
		local mesh = {	
			triangles = {
				count = tonumber(scene.mMeshes[0].mNumFaces), 
				pointer = triangles, 
				stride = ffi.sizeof("unsigned int") * 3, 
			},					
			vertices = {
				count = tonumber(scene.mMeshes[0].mNumVertices),  
				pointer = vertices, 
				stride = ffi.sizeof("float") * 3,
			},
		}
		
		assimp.ReleaseImport(scene)
		
		self:SetPhysicsModel(mesh)
		
		self:SetPosition(self.Position)
		self:SetRotation(self.Rotation)
		
		return true
	end
	
	function COMPONENT:InitPhysicsConvexHull()
		local tr = self:GetComponent("transform")
		self.rigid_body:SetMatrix(tr:GetMatrix():Copy().m)
		
		self.rigid_body:InitPhysicsConvexHull(self:GetPhysicsModel().vertices.pointer, self:GetPhysicsModel().vertices.count)
		
		if SERVER then
			local obj = self:GetComponent("networked")
			if obj:IsValid() then obj:CallOnClientsPersist(self.Name, "InitPhysicsConvexHull") end
		end
		
		self:SetPosition(self.Position)
		self:SetRotation(self.Rotation)
	end
	
	function COMPONENT:InitPhysicsConvexTriangles()
		local tr = self:GetComponent("transform")
		self.rigid_body:SetMatrix(tr:GetMatrix():Copy().m)
		
		self.rigid_body:InitPhysicsConvexTriangles(self:GetPhysicsModel())
		
		if SERVER then
			local obj = self:GetComponent("networked")
			if obj:IsValid() then obj:CallOnClientsPersist(self.Name, "InitPhysicsConvexTriangles") end
		end
		
		self:SetPosition(self.Position)
		self:SetRotation(self.Rotation)
	end
		
	function COMPONENT:InitPhysicsTriangles(quantized_aabb_compression)
		local tr = self:GetComponent("transform")
		self.rigid_body:SetMatrix(tr:GetMatrix():Copy().m)
		
		self.rigid_body:InitPhysicsTriangles(self:GetPhysicsModel(), quantized_aabb_compression)
		
		if SERVER then
			local obj = self:GetComponent("networked")
			if obj:IsValid() then obj:CallOnClientsPersist(self.Name, "InitPhysicsTriangles") end
		end
		
		self:SetPosition(self.Position)
		self:SetRotation(self.Rotation)
	end
end		

function COMPONENT:OnUpdate()
	if not self.rigid_body:IsValid() or not self.rigid_body:IsPhysicsValid() then return end
	
	local transform = self:GetComponent("transform")
	
	transform:SetTRMatrix(from_bullet(self))
	
	if CLIENT then
		if not self.SimulateOnClient then
			if self.rigid_body:GetMass() ~= 0 then
				self.rigid_body:SetMass(0)
			end
		end
	end
end

function COMPONENT:OnAdd(ent)	
	self:GetComponent("transform"):SetSkipRebuild(true)
	self.rigid_body = bullet.CreateRigidBody()
	self.rigid_body.ent = self
end

function COMPONENT:OnRemove(ent)
	if self.rigid_body:IsValid() then
		self.rigid_body:Remove()
	end
end

prototype.RegisterComponent(COMPONENT)