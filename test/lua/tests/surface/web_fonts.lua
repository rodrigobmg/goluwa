﻿window.Open()

local font = surface.CreateFont("lol", {
	path = "Aladin",
	size = 50,
})  
   
event.AddListener("Draw2D", "lol", function()
	surface.SetColor(1,1,1,1)

	surface.SetFont(font)
	surface.SetTextPosition(10, 10)
	surface.DrawText("Aladin ㅁ國國ㄴㅇ ㅁㅁㅇ >> 👾👾 << no aliens in unifont :(") 
end)        