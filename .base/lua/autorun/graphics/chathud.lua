local blur_shader = [[
	float sum = 0;
		
	vec2 blur = radius/size;

	sum += texture(self, vec2(uv.x - 4.0*blur.x*dir.x, uv.y - 4.0*blur.y*dir.y)).a * 0.0162162162;
	sum += texture(self, vec2(uv.x - 3.0*blur.x*dir.x, uv.y - 3.0*blur.y*dir.y)).a * 0.0540540541;
	sum += texture(self, vec2(uv.x - 2.0*blur.x*dir.x, uv.y - 2.0*blur.y*dir.y)).a * 0.1216216216;
	sum += texture(self, vec2(uv.x - 1.0*blur.x*dir.x, uv.y - 1.0*blur.y*dir.y)).a * 0.1945945946;

	sum += texture(self, vec2(uv.x, uv.y)).a * 0.2270270270;

	sum += texture(self, vec2(uv.x + 1.0*blur.x*dir.x, uv.y + 1.0*blur.y*dir.y)).a * 0.1945945946;
	sum += texture(self, vec2(uv.x + 2.0*blur.x*dir.x, uv.y + 2.0*blur.y*dir.y)).a * 0.1216216216;
	sum += texture(self, vec2(uv.x + 3.0*blur.x*dir.x, uv.y + 3.0*blur.y*dir.y)).a * 0.0540540541;
	sum += texture(self, vec2(uv.x + 4.0*blur.x*dir.x, uv.y + 4.0*blur.y*dir.y)).a * 0.0162162162;

	sum = pow(sum, 0.5);
	
	float black = -sum;
	sum -= texture(self, uv).a*2;
			
	return vec4(black,black,black, sum)*1.1;
]]

local max = 8
local passes = {}

for i = -max, max do
	local f = i/max
	local s = math.sin(f * math.pi)
	local c = math.sin(f * math.pi)
	
	table.insert(passes, {source = blur_shader, vars = {dir = Vec2(c,s), radius = 0.05}})
end

chathud = { 
	font_translate = {
		-- usage
		-- chathud.font_translate.chathud_default = "my_font"
		-- to override fonts
	},
	config = {
		max_width = 500,
		max_height = 1200,
		height_spacing = 3,
		history_life = 20,
		
		extras = {
			["...."] = {type = "font", val = "DefaultFixed"},
			["!!!!"] = {type = "font", val = "Trebuchet24"},
			["!!!!!11"] = {type = "font", val = "DermaLarge"},
		},
		
		smiley_translate =
		{
			v = "vee",
		},	

		shortcuts = {		
			smug = "<texture=masks/smug>",
			downs = "<texture=masks/downs>",
			saddowns = "<texture=masks/saddowns>",
			niggly = "<texture=masks/niggly>",
			colbert = "<texture=masks/colbert>",
			eli = "<texture=models/eli/eli_tex4z,4>",
			bubu = "<remember=bubu><color=1,0.3,0.2><texture=materials/hud/killicons/default.vtf,50>  <translate=0,-15><color=0.58,0.239,0.58><font=ChatFont>Bubu<color=1,1,1>:</translate></remember>",
			acchan = "<remember=acchan><translate=20,-35><scale=1,0.6><texture=http://www.theonswitch.com/wp-content/uploads/wow-speech-bubble-sidebar.png,64></scale></translate><scale=0.75,1><texture=http://img1.wikia.nocookie.net/__cb20110317001632/southparkfanon/images/a/ad/Kyle.png,64></scale></remember>",
		}
		
	},
	fonts = {
		default = {
			name = "chathud_default",
			data = {
				path = "Roboto",
				fallback = "default",
				size = 16,
				padding = 8, 
				shade = passes,
				shadow = 1,
			} ,
		}
	},
	tags = {},
}
 
if surface.DrawFlag then
	chathud.tags.flag =
	{		
		arguments = {"gb"},
		
		draw = function(markup, self, x,y, flag)
			surface.DrawFlag(flag, x, y - 12)
		end,
	}
end

local chathud_show = console.CreateVariable("cl_chathud_show", 1)
local height_mult = console.CreateVariable("cl_chathud_height_mult", 0.76)
local width_mult = console.CreateVariable("cl_chathud_width_mult", 0.6)

chathud.markup =  surface.CreateMarkup()
chathud.markup:SetEditable(false)
chathud.markup:SetSelectable(false)
chathud.life_time = 20

local first = true

function chathud.AddText(...)
	
	if first then
		for _, v in pairs(vfs.Find("textures/silkicons/")) do
			chathud.config.shortcuts[v:gsub("(%.png)$","")] = "<texture=textures/silkicons/" .. v .. ",16>"
		end

		for name, data in pairs(chathud.fonts) do
			surface.CreateFont(data.name, data.data)
		end
		first = nil
	end

	local args = {}
		
	for k,v in pairs({...}) do
		local t = typex(v)
		if t == "client" then
			table.insert(args, v:GetUniqueColor())
			table.insert(args, v:GetNick())
			table.insert(args, ColorBytes(255, 255, 255, 255))
		elseif t == "string" then
		
			if v == ": sh" or v == "sh" or v:find("%ssh%s") then
				chathud.markup:TagPanic()
			end
		
			v = v:gsub("<remember=(.-)>(.-)</remember>", function(key, val) 
				chathud.config.shortcuts[key] = val
			end)
		
			v = v:gsub("(:[%a%d]-:)", function(str)
				str = str:sub(2, -2)
				if chathud.config.shortcuts[str] then
					return chathud.config.shortcuts[str]
				end
			end)
			
			v = v:gsub("\\n", "\n")
			v = v:gsub("\\t", "\t")
			
			for pattern, font in pairs(chathud.config.extras) do
				if v:find(pattern, nil, true) then
					table.insert(args, #args-1, font)
				end
			end
						
			table.insert(args, v)
		else
			table.insert(args, v)
		end
	end
	
	event.Call("ChatAddText", args)
	 
	local markup = chathud.markup
	
	markup:BeginLifeTime(chathud.life_time)
		-- this will make everything added here get removed after said life time
		markup:AddFont("chathud_default") -- also reset the font just in case
		markup:AddTable(args, true)
		markup:AddTagStopper()
		markup:AddString("\n")
	markup:EndLifeTime()
	
	markup:SetMaxWidth(surface.GetSize() * width_mult:Get())
		
	for k,v in pairs(chathud.tags) do
		markup.tags[k] = v
	end
end
   
function chathud.Draw()
	local markup = chathud.markup
	
	local w, h = surface.GetSize()
	local x, y = 30, h * height_mult:Get()
	
	y = y - markup.height
	
	surface.PushMatrix(x,y)
		markup:Update()
		markup:Draw(x, y, w, h, mat)
	surface.PopMatrix()
end

function chathud.MouseInput(button, press, x, y)
	chathud.markup:OnMouseInput(button, press, x, y)
end

event.AddListener("DrawHUD", "chathud", function()
	chathud.Draw()
end)

event.AddListener("MouseInput", "chathud", function(button, press)
	chathud.MouseInput(button, press, window.GetMousePosition():Unpack())
end)

event.AddListener("Chat", "chathud", function(name, str, client)
	local tbl = chat.AddTimeStamp()
	
	if client:IsValid() then
		table.insert(tbl, client:GetUniqueColor())
	end
	
	table.insert(tbl, name)
	table.insert(tbl, Color(1,1,1,1))
	table.insert(tbl, ": ")
	table.insert(tbl, str)
	chathud.AddText(unpack(tbl))
end)

include("tradingcard_emotes.lua")

if RELOAD then
	chathud.AddText("hello world")
end