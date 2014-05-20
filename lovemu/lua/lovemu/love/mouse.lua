local love=love
local lovemu=lovemu
love.mouse={}

local input=input

function love.mouse.getPosition()
	return window.GetMousePos():Unpack()
end

function love.mouse.getX()
	return window.GetMousePos().x
end

function love.mouse.getY()
	return window.GetMousePos().y
end

function love.mouse.newCursor()
	local obj = lovemu.NewObject("Cursor")
	
end

function love.mouse.getCursor()
	local obj = lovemu.NewObject("Cursor")
	obj.getType = function()
		return system.GetCursor()
	end
	return obj
end

function love.mouse.setCursor()
	--system.SetCursor()
end

function love.mouse.getSystemCursor()
	local obj = lovemu.NewObject("Cursor")
	obj.getType = function()
		return system.GetCursor()
	end
	return obj
end


local visible=false
function love.mouse.setVisible(bool)	--partial
	visible=bool
end

function love.mouse.getVisible(bool)	--partial
	return visible
end

local mouse_keymap={
	button_1="l",
	button_2="r",
	button_3="m",
	button_4="x1",
	button_5="x2"
}
function love.mouse.isDown(key)
	return input.IsMouseDown(mouse_keymap[key])
end

event.AddListener("MouseInput","lovemu_mouse",function(key,press)
	local x, y = window.GetMousePos():Unpack()

	key = mouse_keymap[key]
	if press then
		if love.mousepressed then
			love.mousepressed(x, y, key)
		end
	else
		if love.mousereleased then
			love.mousereleased(x, y, key)
		end
	end
end) 