local chat = _G.chat or {}

local function getnick(client)
	return client:IsValid() and client:GetNick() or "server"
end

local enabled = console.CreateVariable("chat_timestamps", true)

function chat.AddTimeStamp(tbl)
	if not enabled:Get() then return {} end
	
	tbl = tbl or {}
	
	local time = os.date("*t")
	
	table.insert(tbl, 1, " - ")
	table.insert(tbl, 1, Color(1, 1, 1))
	table.insert(tbl, 1, ("%.2d:%.2d"):format(time.hour, time.min))
	table.insert(tbl, 1, ColorBytes(118, 170, 217))

	return tbl
end

function chat.GetTimeStamp()
	local time = os.date("*t")

	return ("%.2d:%.2d - "):format(time.hour, time.min)
end

function chat.Append(var, str, skip_log)

	if not str then
		str = var
		var = NULL
	end

	local client = NULL
	
	if typex(var) == "client" then
		client = var
		var = getnick(var)
	elseif typex(var) == "null" then
		var = "disconnected"
	elseif not network.IsConnected() then
		var = "server"
	else
		var = tostring(var)
	end	

	if CLIENT then
		local tbl = chat.AddTimeStamp()
		
		if client:IsValid() then
			table.insert(tbl, client:GetUniqueColor())
		end
		
		table.insert(tbl, var)
		table.insert(tbl, Color(1,1,1,1))
		table.insert(tbl, ": ")
		table.insert(tbl, str)
		chathud.AddText(unpack(tbl))
	end
	
	if not skip_log then
		logf("%s%s: %s\n", chat.GetTimeStamp(), var, str)
	end
end

if CLIENT then	
	message.AddListener("say", function(client, str, seed)
		chat.ClientSay(client, str, seed)
	end)

	function chat.Say(str)
		str = tostring(str)	
		if network.IsConnected() then
			message.Send("say", str)
		else	
			chat.ClientSay(clients.GetLocalClient(), str)
		end
	end	
	
	chat.panel = chat.panel or NULL
	
	function chat.IsVisible()
		return chat.panel:IsValid()
	end
		
	function chat.SetInputText(str)
		if not chat.IsVisible() then return end
		chat.panel:SetText(str)
	end
	
	function chat.GetInputText()
		if not chat.IsVisible() then return "" end
		return chat.panel:GetText()
	end	
	
	function chat.GetInputPosition()
		if not chat.IsVisible() then return 0, 0 end
		return chat.panel:GetPosition()
	end
		
	--[[event.AddListener("ConsoleLineEntered", "chat", function(line)
		if not network.IsStarted() then return end
	
		if not console.RunString(line, true) then
			chat.Say(line)
		end
		
		return false
	end)]]
	

	local i = 1
	local history = {}
	local last_history
	
	-- this depends on "gui" which is an addon, which may as well be a part of goluwa
 	-- TODO!!
			
	console.AddCommand("showchat", function()	
		local frame =  chat.panel
		local found_autocomplete = {}
				
		if not frame:IsValid() then
			local old_mouse_trap = window.GetMouseTrapped()
			
			frame = gui2.CreatePanel("frame")
			frame:SetTitle("chatbox")
			frame:SetSize(Vec2(400, 250))
			frame:SetColor(gui2.skin.font_edit_background)
			
			local S = gui2.skin.scale
			
			local edit = frame:CreatePanel("text_edit")
			edit:SetStretchToPanelWidth(frame)
			edit:SetHeight(10*S)
			edit:SetColor(Color(1,1,1,1))
			edit:SetStyle("frame")
			edit:SetTextColor(Color(0,0,0,1))
			frame.edit = edit
			
			local scroll = frame:CreatePanel("scroll")
			scroll:SetXScrollBar(false)
			frame.scroll = scroll

			local text = scroll:SetPanel(gui2.CreatePanel("text"))
			text:SetPosition(Vec2()+S*2)
			text.markup:SetLineWrap(true)
			text:AddEvent("ChatAddText")

			function text:OnChatAddText(args)
				self.markup:AddFont(gui2.skin.default_font)
				self.markup:AddTable(args, true)
				self.markup:AddTagStopper()
				self.markup:AddString("\n")
			end
			
			function text:OnLayout()
				self.markup:SetMaxWidth(self.Parent:GetWidth())
			end
			
			text:Layout()
		
			edit:RequestFocus()
			--edit:SetMultiline(true)
			
			-- autocomplete should be done after keys like space and backspace are pressed
			-- so we can use the string after modifications
			edit.OnPostKeyInput = function(self, key, press)
				if not press then return end
				
				local str = self:GetText():trim()
				
				local scroll = 0
				 
				if key == "tab" then
					scroll = input.IsKeyDown("left_shift") and -1 or 1
				end
				
				found_autocomplete = autocomplete.Query("chatsounds", str, scroll)
									
				if key == "tab" and found_autocomplete then
					edit:SetText(found_autocomplete[1])
					return false
				end
			end
			
			edit.OnPreKeyInput = function(self, key, press)	
				if not press then return end
				
				local str = self:GetText()
				
				local ctrl = input.IsKeyDown("left_control") or input.IsKeyDown("right_control")
				
				if ctrl or str == "" or str == last_history then
					local browse = false
					
					if key == "up" then
						i = math.clamp(i + 1, 1, #history)
						browse = true
					elseif key == "down" then
						i = math.clamp(i - 1, 1, #history)
						browse = true
					end
					
					local found = history[i]
					if browse and found then
						edit:SetText(found)
						edit:SetCaretPosition(Vec2(#found, 0))
						last_history = found
					end
				end

				if key == "enter" and not ctrl or key == "escape" then
				
					if key ~= "escape" then
						i = 0
						if #str > 0 then
							chat.Say(str)
							if history[1] ~= str then
								table.insert(history, 1, str)
							end
						end
					end
					
					window.SetMouseTrapped(old_mouse_trap) 
					
					edit:SetText("")
					frame:Minimize()
					input.DisableFocus = false
					
					event.Call("ChatTextChanged", "")
					
					return
				end	
				
				event.Call("ChatTextChanged", str)
			end
				
			edit.OnTextChanged = function(self, str)
				event.Call("ChatTextChanged", str)
				frame:Layout()
			end
			
			edit.OnLayout = function()
				edit:SizeToText()
				edit:SetHeight(math.max(edit:GetHeight(), S*8))
				edit:SetWidth(frame:GetWidth())
				edit:SetY(frame:GetHeight() - edit:GetHeight())
				edit:SetX(0)
				edit.label.markup:SetMaxWidth(frame:GetWidth())
				
				scroll:SetPosition(Vec2(0, 10*S))
				scroll:SetHeight(frame:GetHeight() - edit:GetHeight() - S*10)
				scroll:SetWidth(frame:GetWidth())
				scroll.scroll_area:SetScrollFraction(Vec2(0,1))
			end
			
			edit.OnPostDraw = function()
				if found_autocomplete and #found_autocomplete > 0 then
					autocomplete.DrawFound(0, edit:GetHeight(), found_autocomplete, nil, 2) 
				end
			end
				
			window.SetMouseTrapped(false)
		end
				
		frame:Minimize(true)
		frame.scroll.scroll_area:SetScrollFraction(Vec2(0,1))
		frame.edit:SetText("")
		frame:Layout(true)
		input.DisableFocus = true

		chat.panel = frame
	end)
	
	input.Bind("y", "showchat")
end

local SEED = 0

function chat.ClientSay(client, str, skip_log, seed)
	seed = seed or SEED
	
	if event.Call("ClientChat", client, str, seed) ~= false then
		chat.Append(client, str, skip_log)
		if SERVER then message.Broadcast("say", client, str, seed) SEED = SEED + 1 end
	end
end

if SERVER then

	message.AddListener("say", function(client, str)
		chat.ClientSay(client, str)
	end)

	function chat.Say(str)
		str = tostring(str)		
		message.Broadcast("say", NULL, str)
		chat.Append(NULL, str)
	end
end

return chat