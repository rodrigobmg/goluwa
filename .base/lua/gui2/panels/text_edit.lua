local gui2 = ... or _G.gui2
local PANEL = {}

PANEL.ClassName = "text_edit"

prototype.GetSet(PANEL, "Editable", true)

prototype.GetSetDelegate(PANEL, "Text", "", "label")
prototype.GetSetDelegate(PANEL, "ParseTags", false, "label")
prototype.GetSetDelegate(PANEL, "Font", gui2.skin.default_font, "label")
prototype.GetSetDelegate(PANEL, "TextColor", gui2.skin.font_edit_color, "label")
prototype.GetSetDelegate(PANEL, "TextWrap", false, "label")

prototype.Delegate(PANEL, "label", "CenterText", "Center")
prototype.Delegate(PANEL, "label", "CenterTextY", "CenterY")
prototype.Delegate(PANEL, "label", "CenterTextX", "CenterX")
prototype.Delegate(PANEL, "label", "GetTextSize", "GetSize")

function PANEL:Initialize()	
	self:SetColor(gui2.skin.font_edit_background)
	self:SetFocusOnClick(true)
	self.BaseClass.Initialize(self)
	
	local label = gui2.CreatePanel("text", self)
	label.markup:SetEditable(self.Editable)
	label:SetFont(self.Font)
	label:SetTextColor(self.TextColor)
	label:SetClipping(true)
	label:SetIgnoreMouse(true)
	self.label = label
	
	self:SetEditable(true)
	
	label.OnTextChanged = function(_, ...) self:OnTextChanged(...) end
	label.OnEnter = function(_, ...) self:OnEnter(...) end
end

function PANEL:SelectAll()
	self.label.markup:SelectAll()
	print(self.label.markup.select_stop.x, self.label.markup.select_stop.y)
end

function PANEL:SetEditable(b)
	self.Editable = b
	self.label.markup:SetEditable(b)
end

function PANEL:SizeToText()
	local marg = self:GetMargin()
		
	self.label:SetPosition(marg:GetPosition())
	self:SetSize(self.label:GetSize() + marg:GetSize()*2)
end

function PANEL:OnFocus()
	if self.Editable then
		self.label.markup:SetEditable(true)
	end
end

function PANEL:OnUnfocus()
	self.label.markup:SetEditable(false)
end

function PANEL:OnKeyInput(...)
	return self.label:OnKeyInput(...)
end

function PANEL:OnCharInput(...)
	return self.label:OnCharInput(...)
end

function PANEL:OnMouseInput(button, press, ...)
	self.label:OnMouseInput(button, press, ...)
end

function PANEL:OnMouseMove(...)
	self.label:OnMouseMove(...)
end

function PANEL:OnEnter() end
function PANEL:OnTextChanged() end
	
gui2.RegisterPanel(PANEL)