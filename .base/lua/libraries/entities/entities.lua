include("components/*", prototype)

prototype.SetupComponents("group", {}, "textures/silkicons/world.png")

prototype.SetupComponents("light", {"transform", "light", "network"}, "textures/silkicons/lightbulb.png")
prototype.SetupComponents("visual", {"transform", "model", "network"}, "textures/silkicons/shape_square.png")
prototype.SetupComponents("physical", {"transform", "model", "physics", "network"}, "textures/silkicons/shape_handles.png")
prototype.SetupComponents("world", {"world", "network"}, "textures/silkicons/world.png")

local entities = _G.entities or {}

entities.active_entities = entities.active_entities or {}

local id = 1

function entities.CreateEntity(name, parent)
	local self = prototype.CreateEntity(name, parent)
		
	self.Id = id
		
	entities.active_entities[id] = self
	
	id = id + 1
	
	return self
end

event.AddListener("EntityRemove", "entities", function(ent)
	entities.active_entities[ent.Id] = nil
end)

function entities.GetAll()
	return entities.active_entities
end

function entities.Panic()
	for k,v in pairs(entities.GetAll()) do
		v:Remove()
	end
end

function entities.SafeRemove(ent)
	if hasindex(ent) and ent.IsValid and ent.Remove and ent:IsValid() then
		ent:Remove()
	end
end

return entities