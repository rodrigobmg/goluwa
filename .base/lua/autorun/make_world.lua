if SCITE then return end

local function go()
	if SERVER then
		console.RunString("map gm_flatgrass")

		for i = 1, 1 do
			local body = entities.CreateEntity("physical")
			body:SetPhysicsModelPath("models/cube.obj")
			body:SetModelPath("models/cube.obj")
			body:SetMass(10)
			body:InitPhysicsBox(Vec3(1, 1, 1))  
			body:SetPosition(Vec3(0,0,100+i*2)) 
			--body:SetScale(Vec3(1,5,1))
			body:SetSize(1) 
		end 
	end
end

if RELOAD  then
	go() 
end

if CLIENT then
	event.Delay(function()
		go() 
	end)
end

if SERVER then
	event.AddListener("NetworkStarted", "spawn_world", function()
		go()
	end)
end