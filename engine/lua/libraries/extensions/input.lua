input.binds = {}

function input.Bind(key, cmd, callback)
	serializer.SetKeyValueInFile("luadata", "data/input.txt", key, cmd)

	local modifiers = key:split("+")
	table.remove(modifiers, 1)

	input.binds[key .. cmd] = {
		key = key:sub(1, 1) == "+" and key:sub(2) or key,
		trigger = key:match("^%-(.-)%+") or key:match("^(.-)%+") or key,
		cmd = cmd,
		modifiers = modifiers,
		trigger_on_release = cmd:sub(1, 1) == "-",
	}

	if callback then
		commands.Add(cmd .. "=nil", callback)
	end
end

function input.Unbind(key)
	for k, v in pairs(input.binds) do
		if k:startswith(key) then
			input.binds[k] = nil
			commands.Remove(v.cmd)
			break
		end
	end
end

function input.Initialize()
	input.binds = serializer.ReadFile("luadata", "data/input.txt") or {}
end

function input.Call(key, press)
	if input.DisableFocus then return end

	for _, data in pairs(input.binds) do
		if data.trigger == key then
			if (press and not data.trigger_on_release) or (not press and data.trigger_on_release) then
				local ok = true
				for _, v in ipairs(data.modifiers) do
					if not input.IsKeyDown(v) then
						ok = false
						break
					end
				end
				if ok then
					commands.RunString(data.cmd)
					return false
				end
			end
		end
	end
end

event.AddListener("KeyInput", "keybind", input.Call, {on_error = system.OnError, priority = math.huge})

commands.Add("bind=string,string_rest", function(key, str)
	input.Bind(key, str)
end)