local fb = render.CreateFrameBuffer(512, 512, {
	attach = "color1",
	texture_format = {
		internal_format = "RGB32F",
		min_filter = "nearest",
	}
})

event.CreateTimer("fb_update", 0, 0, function()
	fb:Begin()
		surface.Start(0, 0, 512, 512)			
			surface.SetWhiteTexture()
			surface.SetColor(math.randomf(), math.randomf(), math.randomf(), 1)
			surface.DrawRect(math.random(512), math.random(512), 100, 100)
		surface.End()
	fb:End()
end)

event.AddListener("Draw2D", "fb", function()
	surface.SetTexture(fb:GetTexture())
	surface.SetColor(1,1,1,1)
	surface.DrawRect(128, 128, 128, 128, system.GetTime()*100, 64, 64)
end)   