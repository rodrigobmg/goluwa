if CLIENT then
	local angles = Ang3(0, 0, 0)
	local fov = math.rad(75)

	event.AddListener("CreateMove", "spooky", function(client, prev_cmd, dt)	
		if not window.IsOpen() then return end
		if chat and chat.IsVisible() then return end
		if menu and menu.visible then return end
		
		local dir, angles, fov = CalcMovement(1, angles, fov)
		
		local cmd = {}
				
		cmd.velocity = dir
		cmd.angles = angles
		cmd.fov = fov
		cmd.mouse_pos = window.GetMousePosition()
		
		render.SetCameraAngles(cmd.angles)
		render.SetCamFOV(cmd.fov)
		
		local ghost = client.nv.ghost or NULL
		if ghost:IsValid() then
			local pos = ghost:GetComponent("physics"):GetPosition() 
			render.SetCamPosition(Vec3(-pos.y, -pos.x, -pos.z))
		end

		return cmd
	end)
	
	-- 2d
	event.AddListener("DrawHUD", "cursors", function()

		if not menu.IsVisible() then return end
		
		surface.SetColor(1,1,1,1)
		surface.SetFont("default")
		
		for _, client in pairs(clients.GetAll()) do
			if not client:IsBot() then
				local cmd = client:GetCurrentCommand()
				surface.SetTextPosition(cmd.mouse_pos.x, cmd.mouse_pos.y)

				local str = client:GetNick()
				local coh = client:GetChatAboveHead()
				
				if #coh > 0 then
					str = str .. ": " .. coh
				end
				
				surface.DrawText(str)
			end
		end
		
		surface.SetAlphaMultiplier(1)
	end)
end 
 
 
for k,v in pairs(clients.GetAll()) do
	if v.nv.ghost and v.nv.ghost:IsValid() then
		v.nv.ghost:Remove()
	end
end    
    
event.AddListener("Move", "spooky", function(client, cmd)
	if CLIENT and not network.IsConnected() then return end
	
	local ghost = NULL
	
	if SERVER then
		if not client.nv.ghost or not client.nv.ghost:IsValid() then
			ghost = entities.CreateEntity("networked")
				
			local filter = clients.CreateFilter():AddAllExcept(client)
			
			ghost:ServerFilterSync(filter, "Position")
			ghost:ServerFilterSync(filter, "Rotation")
			
			--ghost:SetNetworkChannel(1) 
			ghost:SetModelPath("models/sphere.obj")
			ghost:SetMass(85)
			ghost:InitPhysicsSphere(0.5)
			ghost:SetPosition(Vec3(0,0,-40))  
			ghost:SetLinearSleepingThreshold(0)  
			ghost:SetAngularSleepingThreshold(0)  
			ghost:SetSize(1/12)  
 			ghost:SetSimulateOnClient(true) 
			
			client.nv.ghost = ghost
		end
	end
	
	if client.nv.ghost and client.nv.ghost:IsValid() then
		ghost = client.nv.ghost
	end
	
	if not ghost:IsValid() then return end
	
	local physics = ghost:GetComponent("physics")
	local pos =  physics:GetPosition() 
			
	if CLIENT then		
		if cmd.net_position and cmd.net_position:Distance(pos) > 1 then
			physics:SetPosition(cmd.net_position)   
			physics:SetAngles(cmd.angles)  
		end
	end
	
	physics:SetVelocity(physics:GetVelocity() + cmd.velocity * 0.2)
	physics:SetVelocity(physics:GetVelocity() * 0.75)   
	physics:SetAngularVelocity(physics:GetAngularVelocity() * 0.75)   
	
	return pos, physics:GetVelocity()
end) 
 
if SERVER then
	event.AddListener("ClientMouseInput", "bsp_lol", function(client, button, press)	
		if button == "button_1" and press then
			local cmd = client:GetCurrentCommand()
			
			local ent = entities.CreateEntity("networked")
			ent:InitPhysicsBox(Vec3(1, 1, 1)/12)
			ent:SetSize(1/12)
			ent:SetModelPath("models/cube.obj")
			ent:SetMass(100)
			ent:SetPosition(cmd.net_position) 
			ent:SetVelocity(cmd.angles:GetForward() * 100)
			
			event.Delay(3, function()
				entities.SafeRemove(ent)
			end)
			
			print(client, button, press, ent, cmd.net_position)
		end
	end)
end