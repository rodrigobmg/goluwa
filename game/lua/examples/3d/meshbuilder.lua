local heightmap = render.CreateTextureFromPath("textures/heightmap/HeightMap6.jpg")
local diffuse = render.CreateTextureFromPath("textures/heightmap/HeightMap_6BaseTexture.jpg")

local model = gfx.CreatePolygon3D()
model:LoadHeightmap(heightmap, heightmap:GetSize()/5, Vec2(128, 128), -200)
model:SmoothNormals()
model:AddSubMesh(model:GetVertices())
model:Upload()

local ent = utility.RemoveOldObject(entities.CreateEntity("visual"), "lol")
ent:AddSubModel(model)

local mat = render.CreateMaterial("model")
mat:SetAlbedoTexture(diffuse)
ent:SetMaterialOverride(mat)