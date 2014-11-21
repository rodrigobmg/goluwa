local gui = ... or _G.gui

local PANEL = {}

PANEL.ClassName = "checkbox_label"

prototype.GetSetDelegate(PANEL, "Text", "", "label")
prototype.GetSetDelegate(PANEL, "ParseTags", false, "label")
prototype.GetSetDelegate(PANEL, "Font", nil, "label")
prototype.GetSetDelegate(PANEL, "TextColor", nil, "label")
prototype.GetSetDelegate(PANEL, "TextWrap", false, "label")
prototype.GetSetDelegate(PANEL, "ConcatenateTextToSize", false, "label")

prototype.Delegate(PANEL, "label", "CenterText", "Center")
prototype.Delegate(PANEL, "label", "CenterTextY", "CenterY")
prototype.Delegate(PANEL, "label", "CenterTextX", "CenterX")
prototype.Delegate(PANEL, "label", "GetTextSize", "GetSize")

function PANEL:Initialize()
	self:SetNoDraw(true)
	
	local check = self:CreatePanel("button", "checkbox")
	check:SetActiveStyle("check")
	check:SetInactiveStyle("uncheck")
	check:SetMode("toggle")

	local label = self:CreatePanel("text", "label")
	self:Layout(true)
	
	self.tied_checkboxes = {}
	check.OnStateChanged = function(_, b)
		self:OnCheck(b)
		
		for i,v in ipairs(self.tied_checkboxes) do
			if v:IsValid() and v ~= check then
				v.checkbox:SetState(not b)
			end
		end
	end
end

function PANEL:TieCheckbox(checkbox)	
	checkbox.tied_checkboxes = {}
	table.insert(self.tied_checkboxes, checkbox)
	
	for k,v in ipairs(self.tied_checkboxes) do
		v.checkbox:SetActiveStyle("rad_check")
		v.checkbox:SetInactiveStyle("rad_uncheck")
	end
	
	self.checkbox:SetActiveStyle("rad_check")
	self.checkbox:SetInactiveStyle("rad_uncheck")
end

function PANEL:IsChecked()
	return self.checkbox:GetState()
end

function PANEL:OnCheck(b)
	
end

function PANEL:SizeToText()
	local marg = self:GetMargin()
	
	self.checkbox:SetX(0)
	self.label:SetX(self.checkbox:GetPosition().x + marg.left + self.checkbox:GetWidth())
	self:SetSize(self.label:GetPosition() + Vec2(marg.left, 0) + self.label:GetSize() + marg:GetSize())
	self.label:CenterY()
	self.checkbox:CenterY()
	
	if self.LayoutSize then
		self.LayoutSize = self:GetSize():Copy()
	end
end

gui.RegisterPanel(PANEL)