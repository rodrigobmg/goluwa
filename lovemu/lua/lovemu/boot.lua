function lovemu.CreateLoveEnv(version)
	local love = {}
	
	love._version = lovemu.version
	
	local version = lovemu.version:explode(".")
	
	love._version_major = tonumber(version[1])
	love._version_minor = tonumber(version[2])
	love._version_revision = tonumber(version[3])

	include("lovemu/love/*", love)	
	
	return love
end

function lovemu.RunGame(folder)
	require("socket.http")
	
	render.EnableGBuffer(false)

	local love = lovemu.CreateLoveEnv(lovemu.version)
		
	lovemu.errored = false
	lovemu.error_msg = ""
	lovemu.delta = 0
	lovemu.demoname = folder
	lovemu.love = love
	lovemu.textures = {}
		
	window.Open()	
		
	vfs.AddModuleDirectory("lovers/" .. lovemu.demoname .. "/")
	vfs.Mount(R("lovers/" .. lovemu.demoname .. "/"))
			
	local env
	env = setmetatable({
		love = love, 
		require = function(name, ...)
		
			if package.loaded[name] then 
				return package.loaded[name] 
			end
			
			local func, err, path = require.load(name, folder) 
						
			if type(func) == "function" then
				if debug.getinfo(func).what ~= "C" then
					setfenv(func, env)
				end				
				return require.require_function(name, func, path) 
			end
			
			if not func and err then print(name, err) end
			
			return func
		end,
	}, 
	{
		__index = _G,
	})
	
	env._G = env
	
	do -- config
		lovemu.config = {
			screen = {}, 
			window = {},
			modules = {},
			height = 600,
			width = 800,
			title = "LOVEMU no title",
			author = "who knows",
		}
		
		if vfs.Exists(R("conf.lua"))==true then			
			local func = assert(vfs.loadfile("conf.lua"))
			setfenv(func, env)
			func()
		end
			
		love.conf(lovemu.config)
	end
	
	--check if lovemu.config.screen exists
	if not lovemu.config.screen then
		lovemu.config.screen={}
	end
	
	local w = lovemu.config.screen.width or 800
	local h = lovemu.config.screen.height or 600
	local title = lovemu.config.title or "LovEmu"
	
	love.window.setMode(w,h)
	love.window.setTitle(title)
		
	local main = assert(vfs.loadfile("main.lua"))
	
	setfenv(main, env)
	
	if not xpcall(main, system.OnError) then return end
	if not xpcall(love.load, system.OnError) then return end
			
	
	local id = "lovemu_" .. folder
		
	local function run(dt)
		love.update(dt)
		love.draw(dt)
	end
		
	setfenv(run, env)
		
	event.AddListener("Draw2D", id, function(dt)		
		love.graphics.clear()
		lovemu.delta = dt
		surface.SetWhiteTexture()
		
		if not lovemu.errored then
			local err, msg = xpcall(run, system.OnError, dt)
			if not err then
				logn(msg)
				
				lovemu.errored = true
				lovemu.error_msg = msg
				
				love.errhand(lovemu.error_msg)
			end
		else
			love.errhand(lovemu.error_msg)
		end
	end, {priority = math.huge}) -- draw this first
end