include("gui2.lua")

local scale = 2
local bg = Color(64, 44, 128)

surface.CreateFont("snow_font", {path = "fonts/zfont.txt", size = 8*scale})   

local function create_button(pos, text)
	local button = gui2.CreatePanel()
	button:SetColor(Color(88, 92, 88))
	button:SetPosition(pos)
	button:SetClipping(true)
	button:SetParseTags(true) 
	button:SetText("<font=snow_font><color=220,220,220>" .. text)
	button:SetSize(button:GetTextSize() + Vec2(5,5) * scale)
	button:CenterText()
	return button:GetSize().x
end

local padding = 4 * scale
local x = padding
local y = 4 * scale
x = x + create_button(Vec2(x, y), "↓") + padding
x = x + create_button(Vec2(x, y), "game") + padding
x = x + create_button(Vec2(x, y), "config") + padding
x = x + create_button(Vec2(x, y), "cheat") + padding
x = x + create_button(Vec2(x, y), "netplay") + padding
x = x + create_button(Vec2(x, y), "misc") + padding


local gradient = Texture(64, 64):Fill(function(x, y) 
	local v = (math.sin(y / 64 * math.pi) * 255) / 2 + 128
	return v, v, v, 255
end)

local emitter = ParticleEmitter(800)
emitter:SetPos(Vec3(50,50,0))
--emitter:SetMoveResolution(0.25)  
emitter:SetAdditive(false)     

event.AddListener("PreDrawMenu", "zsnow", function(dt)	
	emitter:Update(dt)
	emitter:Draw()
	
	surface.SetWhiteTexture()
	surface.SetColor(bg)
	surface.DrawRect(0, 0, render.GetWidth(), render.GetHeight())
	
	surface.SetColor(1,1,1,1)
	emitter:Draw()
	
	surface.SetColor(0,0,0,0.25)
	surface.DrawRect(4*scale,4*scale, x, 17 * scale)
	
	surface.SetTexture(gradient)
	surface.SetColor(0.1,0.2,1,1)
	surface.DrawRect(0,0, x, 17 * scale)
end) 

event.CreateTimer("zsnow", 0.01, function()
	emitter:SetPos(Vec3(math.random(render.GetWidth() + 100) - 150, -50, 0))
		
	local p = emitter:AddParticle()
	p:SetDrag(1)

	--p:SetStartLength(Vec2(0))
	--p:SetEndLength(Vec2(30, 0))
	p:SetAngle(math.random(360)) 
	 
	p:SetVelocity(Vec3(math.random(100),math.random(40, 80)*2,0))

	p:SetLifeTime(20)

	p:SetStartSize(2 * (1 + math.random() ^ 50))
	p:SetEndSize(2 * (1 + math.random() ^ 50))
	p:SetColor(Color(1,1,1, math.randomf(0.5, 0.8)))
end) 