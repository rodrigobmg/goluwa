local cam_pos = Vec3(-10, -16.8, 10.02)    
local cam_ang = Deg3(90, 0, 0)
local cam_fov = math.rad(90)

function CalcMovement(dt, cam_ang, cam_fov)
	cam_ang:Normalize()
	local speed = dt * 10

	local delta = window.GetMouseDelta() / 3
		
	local r = cam_ang.r
	local cs = math.cos(r)
	local sn = math.sin(r)
	local x = delta.x * cs - delta.y * sn
	local y = delta.x * sn + delta.y * cs
	
	local original_delta = delta:Copy()
	
	delta.x = x
	delta.y = y
	
	if input.IsKeyDown("r") then
		cam_ang.r = 0
		cam_fov = math.rad(90)
	end
	
	delta = delta * (cam_fov / 175)
	 
	if input.IsKeyDown("left_shift") and input.IsKeyDown("left_control") then
		speed = speed * 32
	elseif input.IsKeyDown("left_shift") then
		speed = speed * 8
	elseif input.IsKeyDown("left_control") then
		speed = speed / 4
	end	
				
	if input.IsKeyDown("left") then
		delta.x = delta.x - speed / 3
	elseif input.IsKeyDown("right") then
		delta.x = delta.x + speed / 3
	end
	
	if input.IsKeyDown("up") then
		delta.y = delta.y - speed / 3
	elseif input.IsKeyDown("down") then
		delta.y = delta.y + speed / 3
	end
		
	if input.IsMouseDown("button_2") then
		cam_ang.r = cam_ang.r + original_delta.x / 100
		cam_fov = math.clamp(cam_fov + original_delta.y / 100 * (cam_fov/math.pi), math.rad(0.1), math.rad(175))
	else	
		cam_ang.p = math.clamp(cam_ang.p + delta.y, -math.pi/2, math.pi/2)
		cam_ang.y = cam_ang.y - delta.x
	end
	
	local forward = Vec3(0,0,0)
	local side = Vec3(0,0,0)
	local up = Vec3(0,0,0)

	if input.IsKeyDown("space") then
		up = up + cam_ang:GetUp() * speed
	end

	local offset = cam_ang:GetForward() * speed

	if input.IsKeyDown("w") then
		side = side + offset
	elseif input.IsKeyDown("s") then
		side = side - offset
	end

	offset = cam_ang:GetRight() * speed

	if input.IsKeyDown("a") then
		forward = forward + offset
	elseif input.IsKeyDown("d") then
		forward = forward - offset
	end

	if input.IsKeyDown("left_alt") then
		cam_ang.r = math.rad(math.round(math.deg(cam_ang.r) / 45) * 45)
	end
	
	if cam_fov > math.rad(90) then
		side = side / ((cam_fov/math.rad(90)) ^ 4)
	else
		side = side / ((cam_fov/math.rad(90)) ^ 0.25)
	end

	return forward + side + up, cam_ang, cam_fov
end

event.AddListener("Update", "fly_camera_3d", function(dt)
	if network.IsConnected() then return end
	if not window.IsOpen() then return end		
	if not window.GetMouseTrapped() then return end
		
	local dir, ang, fov = CalcMovement(dt, cam_ang, cam_fov)
		
	cam_pos = cam_pos + dir

	render.SetupView3D(cam_pos, cam_ang, cam_fov)
end)

local roll = 0
local pos = Vec2(0, 0)
local zoom = 1

local max_zoom = 100
local min_zoom = 0.01

event.AddListener("Update", "fly_camera_2d", function(dt)
	if not window.IsOpen() then return end
	
	local speed = dt * 1000

	local delta = window.GetMouseDelta() / 100
	
	if input.IsKeyDown("kp_5") then
		pos = Vec2(0,0)
		zoom = 1
		roll = 0
	end
	
	if input.IsKeyDown("left_shift") then
		speed = speed * 8
	elseif input.IsKeyDown("left_control") then
		speed = speed / 4
	end	
	
	if input.IsKeyDown("kp_subtract") then
		zoom = math.clamp(zoom - speed / 1000, min_zoom, max_zoom)
	elseif input.IsKeyDown("kp_add") then
		zoom = math.clamp(zoom + speed / 1000, min_zoom, max_zoom)
	end

	if input.IsKeyDown("kp_7") then
		roll = roll - speed / 4
	elseif input.IsKeyDown("kp_9") then
		roll = roll + speed / 4 
	end
	
	if input.IsKeyDown("left_alt") then
		roll = math.round(roll / math.rad(45)) * math.rad(45)
	end
	
	if input.IsKeyDown("kp_8") then
		pos.y = pos.y + speed
	elseif input.IsKeyDown("kp_2") then
		pos.y = pos.y - speed
	end

	if input.IsKeyDown("kp_4") then
		pos.x = pos.x + speed
	elseif input.IsKeyDown("kp_6") then
		pos.x = pos.x - speed
	end
			
	render.SetupView2D(pos:GetRotated(math.rad(-roll)), roll, 1/zoom)
end)  
