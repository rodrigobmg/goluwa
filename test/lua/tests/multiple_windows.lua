local wnd = utility.RemoveOldObject(render.CreateWindow(512, 512),"lol")

function wnd:OnUpdate(dt)	
	render.PushWindow(self)
		render.Clear("color", "depth")
		
		surface.SetWhiteTexture()
		surface.SetColor(Color():GetRandom())
		surface.DrawRect(0,0,50,50)
		
		render.SwapBuffers()
	render.PopWindow()
end