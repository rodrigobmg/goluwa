gl.debug = true
local window = glw.OpenWindow(1280, 720)

local cam_pos = Vec3(0, 0, -10)
local cam_ang = Ang3(0, 0, 0)

local function calc_camera(window, dt)
 
	cam_ang:Normalize()
	local speed = dt * 10

	local delta = input.GetMouseDelta() * dt / 2
	cam_ang.p = cam_ang.p + delta.y
	cam_ang.y = cam_ang.y + delta.x
	cam_ang.p = math.clamp(cam_ang.p, -math.pi/2, math.pi/2)

	if input.IsKeyDown("left_shift") then
		speed = speed * 4
	elseif input.IsKeyDown("left_control") then
		speed = speed / 4
	end

	if input.IsKeyDown("space") then
		cam_pos = cam_pos - Vec3(0, speed, 0);
	end

	local offset = cam_ang:GetUp() * speed;
	offset.x = -offset.x;
	offset.y = -offset.y

	if input.IsKeyDown("w") then

		cam_pos = cam_pos + offset
	elseif input.IsKeyDown("s") then
		cam_pos = cam_pos - offset
	end

	offset = cam_ang:GetRight() * speed
	offset.z = -offset.z

	if input.IsKeyDown("a") then
		cam_pos = cam_pos + offset
	elseif input.IsKeyDown("d") then
		cam_pos = cam_pos - offset
	end

	speed = dt * 5
  
	if input.IsKeyDown("up") then
		cam_ang.p = cam_ang.p - speed
	elseif input.IsKeyDown("down") then
		cam_ang.p = cam_ang.p + speed
	end

	if input.IsKeyDown("left") then
		cam_ang.y = cam_ang.y - speed
	elseif input.IsKeyDown("right") then
		cam_ang.y = cam_ang.y + speed
	end  
end        

local obj = utilities.RemoveOldObject(Entity("model"), "um")
obj:SetMesh(Mesh(utilities.CreateSphere(4)))
obj:SetTexture("face1.png")

local obj = utilities.RemoveOldObject(Entity("model"), "um2") 
obj:SetPos(Vec3(5,0,0))
obj:SetObj("face.obj")
obj:SetTexture("face1.png")

gl.ClearColor(0.5,0.5,0.5,1)
input.SetMouseTrapped(true)

gl.debug = true
ftgl.debug = true
local font = Font(R"fonts/arial.ttf", "texture")  
font:SetFaceSize(50, 512)
  
event.AddListener("OnDraw", "gl", function(dt)
  	calc_camera(window, dt)

	render.Start(window)

		render.Clear(e.GL_COLOR_BUFFER_BIT, e.GL_DEPTH_BUFFER_BIT)

		render.Start3D(cam_pos, cam_ang:GetDeg())
			entities.world_entity:Draw()
			
		surface.Start()
			font:Render(os.date())
			surface.SetWhiteTexture()
			 			
			surface.Color(1,1,1,0.5)
			surface.DrawRect(0,0,500,500)
			
			surface.StartClipping(0, 0, 500, 500)			
				ERROR_TEXTURE:Bind()
				
				for i = 1, 400 do
					local c = HSVToColor(i/400, 0.75, 1)
					c.a = (i/400) ^ 3
					surface.Color(c:Unpack())
					
					local size = i/400
					size = size * 100
					
					local x = math.sin(os.clock()) / 2
					local y = math.cos(os.clock()) / 2
					
					surface.DrawRect(300 + (i * x), 300 + (i * y),50+size,50+size, i+os.clock()*100)
				end			
			surface.EndClipping()
	render.End()
end)