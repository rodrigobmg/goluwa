local love = (...) or _G.lovemu.love

love.timer = {}

function love.timer.getDelta()
	return render.delta or 0
end

function love.timer.getFPS()
	return math.ceil(1/render.delta or 0)
end

function love.timer.getMicroTime()
	return system.GetTime()
end

function love.timer.getTime()
	if lovemu.version == "0.8.0" then
		return math.ceil(system.GetTime())
	else
		return system.GetTime()
	end
end

function love.timer.getAverageDelta() -- partial
	return love.timer.getDelta()
end