window.Open()

local fb = render.CreateFrameBuffer(512, 512, {
	attach = "color1",
	texture_format = {
		internal_format = "RGB32F",
	}
})

local brush = Texture(128, 128):Fill(function(x, y) 
	x = x / 128
	y = y / 128
	
	x = x - 1
	y = y - 1.5
	
	x = x * math.pi
	y = y * math.pi
		
	local a = math.sin(x) * math.cos(y)
	
	a = a ^ 32
		
	return 255, 255, 255, a * 128
end)

local size = 16 
   
event.CreateTimer("fb_update", 0, 0, function()
	fb:Begin()
		surface.Start(0, 0, 512, 512)			
			if input.IsMouseDown("button_1") then
				surface.SetTexture(brush)
				surface.Color(1, 1, 1, 1)
				local x, y = surface.GetMousePos()
				local vx, vy = surface.GetMouseVel()
				vx = vx * 100
				vy = vy * 100
				if vx ~= 0 and vy ~= 0 then
					local len = Vec2(vx, vy):GetLength() / 100
					local deg = math.deg(math.atan2(vx, -vy))
					surface.Color(HSVToColor(timer.GetSystemTime(), 1, len):Unpack())
					for i = 1, 12 do
						local size = size * i / 8
						surface.DrawRect(x + math.randomf(-size, size), y + math.randomf(-size, size), size, size + 100, deg, size/2, size/2 + 50)
					end
				end
			end
		surface.End()
	fb:End()
end)

event.AddListener("OnDraw2D", "fb", function()
	surface.SetTexture(fb:GetTexture())
	surface.Color(1,1,1,1)
	surface.DrawRect(0, 0, 512, 512) 
end)   