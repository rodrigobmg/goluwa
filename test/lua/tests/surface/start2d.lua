local fb = render.CreateFrameBuffer(256, 256, {
	attach = "color1",
	texture_format = {
		internal_format = "RGB32F",
		min_filter = "nearest",
	}
})

local tex = fb:GetTexture()

event.CreateTimer("updatefb", 0.1, function()
	local t = system.GetTime()
	
	fb:Begin()				
		surface.Start(0, 0, tex.w, tex.h)
			surface.Translate(math.sin(t) * 100, math.cos(t) * 100)
			surface.Rotate(t*100)
			
			surface.SetWhiteTexture() 
			local x, y = surface.GetMousePos()
			
			x = x - 50
			y = y - 50
			
			local x, y = surface.WorldToLocal(x, y) 
			surface.DrawRect(x,y,5,5, 0, 2.5, 2.5)  
			
			render.SetBlendMode("additive")
			
			for i = 1, 10 do
				surface.SetColor(math.randomf(), math.randomf(), math.randomf(), 0.2)
				surface.DrawRect(math.random(tex.w), math.random(tex.h), 100, 100, math.random(360))
			end
			
			render.SetBlendMode("alpha")
		surface.End()
	fb:End() 
end)
 
event.AddListener("Draw2D", "lol", function() 
	local t = system.GetTime()
	
	surface.SetWhiteTexture()
	surface.SetColor(0, 0, 1, 1) 
	surface.DrawRect(0, 0, 100, 100)

	surface.PushMatrix(50, 50)
		surface.SetWhiteTexture()
		surface.SetColor(1, 0, 1, 1)
		surface.DrawRect(0, 0, tex.w, tex.h)
				
		surface.PushMatrix(256, 256)
			surface.StartClipping(0, 0, 100, 100)
				surface.Rotate(45)
				surface.SetWhiteTexture() 
				surface.SetColor(0, 1, 0, 1) 
				surface.DrawRect(0, 0, 256, 256)
			surface.EndClipping()
		surface.PopMatrix()
	surface.PopMatrix()
		
	surface.SetTexture(tex)
	surface.SetColor(1, 1, 1, 1)
	surface.DrawRect(50, 50, tex.w, tex.h)
	
	surface.SetTexture(tex)
	surface.SetColor(1, 1, 1, 1)
	surface.DrawRect(tex.w, tex.h, 50, 50, t*100, 25, 25)
end) 