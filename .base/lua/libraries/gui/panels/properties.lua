local gui = ... or _G.gui

do -- base property
	local PANEL = {}
	
	PANEL.Base = "text_button"
	PANEL.ClassName = "base_property"
	
	prototype.GetSet(PANEL, "DefaultValue")
	
	function PANEL:Initialize()
		self.special = NULL
			
		prototype.GetRegistered(self.Type, PANEL.Base).Initialize(self)
		 
		self:SetActiveStyle("property")
		self:SetInactiveStyle("property")
		self:SetHighlightOnMouseEnter(false)
		self:SetClicksToActivate(2)
		self:SetConcatenateTextToSize(true)
	end
	
	function PANEL:SetSpecialCallback(callback)
		prototype.SafeRemove(self.special)
		local special = self:CreatePanel("text_button", "special")
		special:SetText("...")		
		special:SetMode("toggle")
		special.OnStateChanged = function(_, b) callback(b) end
	end
	
	function PANEL:OnLayout(S)
		self.label:SetPadding(Rect()+S)
		
		if self.special:IsValid() then
			self.special:SetX(self:GetWidth() - self.special:GetWidth())
			self.special:SetSize(Vec2()+self:GetHeight())
			self.special:CenterText()
		end
	end
	
	function PANEL:OnUpdate()
		if self.edit then return end
		local val = self:GetValue()
		if val ~= self.last_value then
			self:SetText(self:Encode(val))
			self.last_value = val
		end
	end
		
	function PANEL:OnMouseInput(button, press)
		prototype.GetRegistered(self.Type, "button").OnMouseInput(self, button, press)
		
		if press then
			if button == "button_1" then
				self:OnClick()
			elseif button == "button_2" then
			
				local option
				
				if PROPERTY_LINK_INFO then
					option = {L"link to property", function() 
						local info = PROPERTY_LINK_INFO						
						prototype.AddPropertyLink(
							info.obj, 
							self.obj, 
							info.info.var_name, 
							self.info.var_name, 
							info.info.field, 
							self.info.field
						)
						PROPERTY_LINK_INFO = nil
					end, "textures/silkicons/link.png"}
				else
					option = {L"link", function() 
						PROPERTY_LINK_INFO = {obj = self.obj, info = self.info}
					end, "textures/silkicons/link_add.png"}
				end
			
				gui.CreateMenu({
					{L"copy", function() system.SetClipboard(self:GetEncodedValue()) end, self:GetSkin().icons.copy},
					{L"paste", function() self:SetEncodedValue(system.GetClipboard()) end, self:GetSkin().icons.paste},
					{},
					option,
					{L"remove links", function() prototype.RemovePropertyLinks(self.obj) end, "textures/silkicons/link_break.png"},
					{},
					{L"reset", function() self:SetValue(self:GetDefaultValue()) end, self:GetSkin().icons.clear},
				}, self)
			end
		end
	end
	
	function PANEL:OnPress()	
		self:StartEditing()
	end
	
	function PANEL:StartEditing()
		if self.edit then return end
		
		local edit = self:CreatePanel("text_edit", "edit")
		edit:SetText(self:GetEncodedValue())
		edit:SetSize(self:GetSize())
		edit:SelectAll()
		edit.OnEnter = function() 
			self:StopEditing()
		end
		
		edit:RequestFocus()
	end
	
	function PANEL:StopEditing()	
		local edit = self.edit
		if edit then
			local str = edit:GetText()
			local val = self:Decode(str)
			
			str = self:Encode(val)
			
			self:SetText(str)
			edit:Remove()
			self:OnValueChanged(val)
			self:OnValueChangedInternal(val)
			
			self.edit = nil
		end
	end
	
	function PANEL:SetValue(val, skip_internal)
		self:SetText(self:Encode(val))
		self:OnValueChanged(val)
		if not skip_internal then
			self:OnValueChangedInternal(val)
		end
		--self:SizeToText()
		self.label:SetupLayout("left")
		self:Layout()
	end
	
	function PANEL:GetValue()
		local val = self:Decode(self:GetText()) 
		
		if val == nil then
			return self:GetDefaultValue()
		end
		
		return val
	end
	
	function PANEL:GetEncodedValue()
		return self:Encode(self:GetValue() or self:GetDefaultValue())
	end
	
	function PANEL:SetEncodedValue(str)
		self:SetValue(self:Decode(str))
	end
	
	function PANEL:Encode(var)
		return tostring(var)
	end
	
	function PANEL:Decode(str)
		return str
	end 
	
	function PANEL:OnValueChanged(val)
	
	end
	
	function PANEL:OnValueChangedInternal(val)
	
	end
	
	function PANEL:OnClick()
	
	end
	
	gui.RegisterPanel(PANEL)
end

do -- string
	local PANEL = {}
	
	PANEL.Base = "base_property"
	PANEL.ClassName = "string_property"
		
	function PANEL:Initialize()
		prototype.GetRegistered(self.Type, PANEL.Base).Initialize(self)
		
		self:SetClicksToActivate(1)
	end
	
	gui.RegisterPanel(PANEL)
end

do -- number
	local PANEL = {}
	
	PANEL.Base = "base_property"
	PANEL.ClassName = "number_property"
	
	prototype.GetSet(PANEL, "Minimum")
	prototype.GetSet(PANEL, "Maximum")
	prototype.GetSet(PANEL, "Sensitivity", 1)
	
	PANEL.slider = NULL
	
	function PANEL:Initialize()
		prototype.GetRegistered(self.Type, PANEL.Base).Initialize(self)
		
		self:SetCursor("sizens")
	end
	
	function PANEL:Decode(str)
		return tonumber(str)
	end
	
	function PANEL:Encode(num)
		return tostring(num)
	end
	
	function PANEL:OnClick()
		self:SetAlwaysCalcMouse(true)
		
		self.drag_number = true
		self.base_value = nil
		self.drag_y_pos = nil
		self.real_base_value = nil
	end
	
	function PANEL:OnPostDraw()
		if self.Minimum and self.Maximum then
			surface.SetWhiteTexture()
			surface.SetColor(0.5,0.75,1,0.5)
			surface.DrawRect(0, 0, self:GetWidth() * math.normalize(self:GetValue(), self.Minimum, self.Maximum), self:GetHeight())
		elseif self.drag_number then
			surface.SetWhiteTexture()
			
			local frac = math.abs((self.real_base_value - self:GetValue())) / 100
			surface.SetColor(1,0.5,0.5,frac)
			
			surface.DrawRect(0, 0, self:GetWidth(), self:GetHeight())
		end
	end
		
	function PANEL:OnUpdate()
		prototype.GetRegistered(self.Type, PANEL.Base).OnUpdate(self)
		
		if not self.drag_number then return end
				
		if input.IsKeyDown("left_shift") and self.real_base_value then
			self:SetValue(self.real_base_value)
			self.base_value = nil
			self.drag_y_pos = nil
		end
		
		if input.IsMouseDown("button_1") then			
			local pos = self:GetMousePosition()
			
			self.base_value = self.base_value or self:GetValue()
			self.real_base_value = self.real_base_value or self.base_value
			
			if not self.base_value then return end
			
			self.drag_y_pos = self.drag_y_pos or pos.y
		
			local sens = self.Sensitivity
			
			if input.IsKeyDown("left_alt") then
				sens = sens / 10
			end
			
			do
				for i, parent in ipairs(self:GetParentList()) do
					if parent.ClassName == "properties" then
						local ppos = self:LocalToWorld(pos)
						if ppos.y > render.GetHeight() then
							local mpos = window.GetMousePosition()
							mpos.y = 4
							window.SetMousePosition(mpos)
							
							self.base_value = nil
							self.drag_y_pos = nil
							return
						elseif ppos.y < 0 then
							local mpos = window.GetMousePosition()
							mpos.y = render.GetHeight()-4
							window.SetMousePosition(mpos)
							
							self.base_value = nil
							self.drag_y_pos = nil
							return
						end
					end
				end

				--if wpos.y > render.GetHeight()
			end
				
			local delta = ((self.drag_y_pos - pos.y) / 10) * sens
			local value = self.base_value + delta
			
			if input.IsKeyDown("left_control") then
				value = math.round(value)
			else
				value = math.round(value, 3)
			end
			
			if self.Minimum then
				value = math.max(value, self.Minimum)
			end
			
			if self.Maximum then
				value = math.min(value, self.Maximum)
			end

			self:SetValue(value)
		else
			self.drag_number = false 
			self:SetAlwaysCalcMouse(false)
		end
	end
	
	gui.RegisterPanel(PANEL)
end

do -- boolean
	local PANEL = {}
	
	PANEL.Base = "base_property"
	PANEL.ClassName = "boolean_property"
	
	function PANEL:Initialize()
		local panel = self:CreatePanel("button", "panel")
		panel:SetMode("toggle")
		panel:SetActiveStyle("check")
		panel:SetInactiveStyle("uncheck")
		panel:SetupLayout("left")
		panel.OnStateChanged = function(_, b) self:SetValue(b, true) end
		
		prototype.GetRegistered(self.Type, PANEL.Base).Initialize(self)
	end
	
	function PANEL:OnValueChangedInternal(val)
		self.panel:SetState(val)
	end
	
	local str2bool = {
		["true"] = true,
		["false"] = false,
		["1"] = true,
		["0"] = false,
		["yes"] = true,
		["no"] = false,
	}
		
	function PANEL:Decode(str)
		return str2bool[str:lower()] or false
	end
	
	function PANEL:Encode(b)
		return b and "true" or "false"
	end
	
	function PANEL:OnLayout(S)
		prototype.GetRegistered(self.Type, PANEL.Base).OnLayout(self, S)
		
		self.panel:SetPadding(Rect()+S)
	end
	
	gui.RegisterPanel(PANEL)
end

do -- color
	local PANEL = {}
	
	PANEL.Base = "base_property"
	PANEL.ClassName = "color_property"
	
	function PANEL:Initialize()
		local panel = self:CreatePanel("button", "panel")
		panel:SetStyle("none")
		panel:SetActiveStyle("none")
		panel:SetInactiveStyle("none")
		panel:SetHighlightOnMouseEnter(false)
		panel:SetupLayout("left")
		
		panel.OnPress = function()
			local frame = gui.CreatePanel("frame")
			frame:SetSize(Vec2(300, 300))
			frame:Center()
			frame:SetTitle("color picker")
			
			local picker = frame:CreatePanel("color_picker")
			picker:SetupLayout("fill_x", "fill_y")
			picker.OnColorChanged = function(_, color) self:SetValue(color) end
			
			panel:CallOnRemove(function() gui.RemovePanel(frame) end)
		end
		
		prototype.GetRegistered(self.Type, "base_property").Initialize(self)
	end
		
	function PANEL:OnValueChangedInternal(val)
		self.panel:SetColor(val)
	end
	
	function PANEL:Decode(str)
		return ColorBytes(str:match("(%d+)%s-(%d+)%s-(%d+)"))
	end
	
	function PANEL:Encode(color)
		local r,g,b = (color*255):Round():Unpack()
		return ("%d %d %d"):format(r,g,b)
	end
	
	function PANEL:OnLayout(S)
		prototype.GetRegistered(self.Type, PANEL.Base).OnLayout(self, S)
		
		self.panel:SetLayoutSize(Vec2(S*8, S*8) - S*2)
		self.panel:SetPadding(Rect()+S)
	end
	
	gui.RegisterPanel(PANEL)
end

local PANEL = {}

PANEL.ClassName = "properties"

function PANEL:Initialize()
	self.added_properties = {}
	self:SetStack(true)
	self:SetStackRight(false) 
	self:SetSizeStackToWidth(true)  
	--self:SetStyle("property")
	self:SetMargin(Rect())
	
	self:AddEvent("PanelMouseInput")
	
	local divider = self:CreatePanel("divider", "divider")
	divider:SetMargin(Rect())
	divider:SetHideDivider(true)
	divider:SetupLayout("fill_x", "fill_y")
	
	local left = self.divider:SetLeft(gui.CreatePanel("base"))
	left:SetStack(true)
	left:SetPadding(Rect(0,0,0,-1))
	left:SetStackRight(false)
	left:SetSizeStackToWidth(true)
	--left:SetupLayout("fill_x", "fill_y")
	left:SetNoDraw(true)  
	self.left = left
	
	local right = self.divider:SetRight(gui.CreatePanel("base"))
	right:SetStack(true)
	right:SetPadding(Rect(0,0,0,-1))
	right:SetStackRight(false)
	right:SetSizeStackToWidth(true)
	--right:SetupLayout("fill_x", "fill_y")
	right:SetNoDraw(true)
	right:SetMargin(Rect())
	self.right = right
end

function PANEL:AddGroup(name)
	local left = self.left:CreatePanel("base")
	left:SetNoDraw(true)
	left.group = true
	--left:SetStyle("property")
	
	local exp = left:CreatePanel("button", "expand")
	exp:SetStyle("-")
	exp:SetStyleTranslation("button_active", "+")
	exp:SetStyleTranslation("button_inactive", "-")
	exp:SetMode("toggle")
	exp:SetupLayout("left")
	exp.OnStateChanged = function(_, b)
		local found = false
		for i, panel in ipairs(self.left:GetChildren()) do
			if found then
				if panel.group then break end
				
				self.right:GetChildren()[i]:SetVisible(not b)
				self.right:GetChildren()[i]:SetStackable(not b)
				panel:SetStackable(not b)
				panel:SetVisible(not b)

				self:Layout()
			end
		
			if panel == left then
				found = true
			end
		end
		
		found = false
		
		for i, panel in ipairs(self.left:GetChildren()) do	
			if found then
			
				if panel.expand and not b then
					panel.expand:OnStateChanged(panel.expand:GetState())
				end
				
			end
			
			if panel == left then
				found = true
			end
		end
	end
	
	local label = left:CreatePanel("text", "label")
	label:SetText(name)
	label:SetupLayout("left")
	
	local right = self.right:CreatePanel("base")
	right.group = true
	right:SetNoDraw(true)
end

function PANEL:AddProperty(name, set_value, get_value, default, extra_info, obj)
	set_value = set_value or print
	get_value = get_value or function() return default end
	extra_info = extra_info or {}
	
	if default == nil then
		default = get_value()
	end
	
	local fields = extra_info.fields
	
	if not fields and hasindex(default) then
		fields = fields or default.Args
		if type(fields[1]) == "table" then
			local temp = {}
			for i,v in ipairs(fields) do
				temp[i] = v[2] or v[1]
			end
			fields = temp
		end
	end
	
	local t = typex(default)
	
	self.left_offset = 8
			
	local left = self.left:CreatePanel("button")
	left:SetStyle("property")
	left.left_offset = self.left_offset	
	left:SetInactiveStyle("property")
	left:SetMode("toggle")
	left.OnStateChanged = function(_, b) left:SetState(b) for i,v in ipairs(self.added_properties) do if v.left ~= left then v.left:SetState(false) end end end
	
	local exp
	
	if fields then
		exp = left:CreatePanel("button", "expand")
		exp:SetStyleTranslation("button_active", "+")
		exp:SetStyleTranslation("button_inactive", "-")
		exp:SetState(true)
		exp:SetMode("toggle")
		exp:SetupLayout("left")
	end
	
	local label = left:CreatePanel("text", "label")
	label:SetText(name)
	label.label_offset = extra_info.__label_offset
	label:SetIgnoreMouse(true)
	label:SetupLayout("left")
	
	local right = self.right:CreatePanel("base") 
	right:SetMargin(Rect())
	right:SetWidth(500)
	
	local property
	
	if prototype.GetRegistered("panel2", t .. "_property") then
		local panel = right:CreatePanel(t .. "_property")
					
		panel:SetValue(default)
		panel:SetDefaultValue(extra_info.default or default)
		panel.GetValue = get_value
		panel.OnValueChanged = function(_, val) set_value(val) end
		panel:SetupLayout("fill_x", "fill_y")
		panel.left = left
		property = panel
		
		if t == "number" then
			if extra_info.editor_min then
				panel:SetMinimum(extra_info.editor_min)
			end
			
			if extra_info.editor_max then
				panel:SetMaximum(extra_info.editor_max)
			end
			
			if extra_info.editor_sens then
				panel:SetMaximum(extra_info.max)
			end
		end
				
		right:SetWidth(panel.label:GetWidth())
				
		table.insert(self.added_properties, panel)
	else
		local panel = right:CreatePanel("base_property")
				
		function panel:Decode(str)
			local val = serializer.Decode("luadata", str)[1]
			
			if typex(val) ~= t then
				val = default
			end
			
			return val
		end
		
		function panel:Encode(val)
			return serializer.Encode("luadata", val)
		end
				
		panel:SetValue(default)
		panel:SetDefaultValue(extra_info.default or default)
		panel.GetValue = get_value
		panel.OnValueChanged = function(_, val) set_value(val) end
		panel:SetupLayout("fill_x", "fill_y")
		panel.left = left
		property = panel
		
		right:SetWidth(panel.label:GetWidth())
		
		table.insert(self.added_properties, panel)
	end	
		
	if fields then
		local panels = {}
		
		exp.OnStateChanged = function(_, b)
			for i, panel in ipairs(panels) do
				panel.right:SetVisible(not b)
				panel.right:SetStackable(not b)
				
				panel.left:SetStackable(not b)
				panel.left:SetVisible(not b)
					
			end
			self:Layout()
		end
		
		for i, key in ipairs(fields) do
			local extra_info = table.merge({
				__label_offset = self.left_offset + (label.label_offset or self.left_offset),
				field = key,
			}, extra_info)
			
			extra_info.default = extra_info.default[key]
			extra_info.fields = nil
			
			local left, right = self:AddProperty(
				key, 
				function(val_)
					local val = property:GetValue()
					val[key] = val_
					property:SetValue(val)
				end, 
				function()
					return property:GetValue()[key]
				end,
				default[key],
				extra_info,
				obj
			)
			
			left:SetStackable(false)
			right:SetStackable(false)
			
			left:SetVisible(false)
			right:SetVisible(false)
			
			table.insert(panels, {left = left, right = right})
		end			
	end
		
	property.obj = obj
	property.info = extra_info
	
	self.first_time = true
	
	self:Layout()
	
	return left, right
end

function PANEL:OnStyleChanged(skin)
	self:SetColor(skin.property_background)
end

function PANEL:OnLayout(S)	
	self.left_max_width = self.left_max_width or 0
	self.right_max_width = self.right_max_width or 0
	
	for i, left in ipairs(self.left:GetChildren()) do
		if left.group then
			left:SetHeight(S*10)
		else
			left:SetHeight(S*8)
		end
		
		if left.left_offset then
			left:SetDrawPositionOffset(Vec2(left.left_offset*S, 0))	
		end
		
		if left.expand then
			left.expand:SetPadding(Rect()+S)
		end
		
		left.label:SetPadding(Rect(S*2,S*2,left.label.label_offset or S*2,S*2))
		
		if self.first_time then
			self.left_max_width = math.max(self.left_max_width, left.label:GetWidth() + left.label:GetX() + (self.left_offset*S) + left.label:GetPadding().right)
		end
	end
	
	for i, right in ipairs(self.right:GetChildren()) do
		if right.group then
			right:SetHeight(S*10)
		else
			right:SetHeight(S*8)
		end
				
		if self.first_time then
			self.right_max_width = math.max(self.right_max_width, right:GetWidth() + S*5) -- *5, why?
		end
	end
	
	if self.first_time then
		self.divider:SetDividerPosition(self.left_max_width)
	end
	
	local h = self.left:GetSizeOfChildren().h
	self.divider:SetSize(Vec2(self.left_max_width + self.right_max_width, h))
	self:SetWidth(self.left_max_width + self.right_max_width)
	self:SetHeight(h)
	
	self.first_time = false
end

function PANEL:OnPanelMouseInput(panel, button, press)
	if press and button == "button_1" and panel.ClassName:find("_property") then
		for i, right in ipairs(self.added_properties) do
			if panel ~= right then
				right:StopEditing()
			end
		end
	end
end

function PANEL:AddPropertiesFromObject(obj)	
	for _, info in ipairs(prototype.GetStorableVariables(obj)) do		
		local get = obj[info.get_name]
		local set = obj[info.set_name]
		local def = get(obj)
		
		local nice_name
		
		if info.var_name:upper() == info.var_name then
			nice_name = info.var_name:lower()
		else
			nice_name = info.var_name:gsub("%u", " %1"):lower():sub(2)
		end		
				
		self:AddProperty(
			L(nice_name), 
			function(val)
				if obj:IsValid() then				
					set(obj, val)
				end
			end, 
			function() 
				if obj:IsValid() then 
					return get(obj)
				end
				
				return def
			end, 
			def,
			info,
			obj
		)
	end
end

gui.RegisterPanel(PANEL)