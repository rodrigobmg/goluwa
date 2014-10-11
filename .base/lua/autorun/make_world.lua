local function go()
	console.RunString("map gm_flatgrass")

	if SERVER then
		for i = 1, 10 do
			local body = entities.CreateEntity("networked")
			body:SetModelPath("models/cube.obj")
			body:SetMass(10)
			body:InitPhysicsBox(Vec3(1, 1, 1))  
			body:SetPosition(Vec3(0,0,-100+i*2)) 
			--body:SetScale(Vec3(1,5,1  )) 
			body:SetSize(1) 
		end 
	end
end

event.AddListener("NetworkStarted", "spawn_world", function()
	go()
end)

if RELOAD then
	go() 
end