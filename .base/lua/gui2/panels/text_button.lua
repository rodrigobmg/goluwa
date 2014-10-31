local gui2 = ... or _G.gui2
local S = gui2.skin.scale

local PANEL = {}

PANEL.ClassName = "text_button"
PANEL.Base = "button"

prototype.GetSetDelegate(PANEL, "Text", "", "label")
prototype.GetSetDelegate(PANEL, "ParseTags", false, "label")
prototype.GetSetDelegate(PANEL, "Font", "default", "label")
prototype.GetSetDelegate(PANEL, "TextColor", Color(1,1,1), "label")
prototype.GetSetDelegate(PANEL, "TextWrap", false, "label")

prototype.Delegate(PANEL, "label", "CenterText", "Center")
prototype.Delegate(PANEL, "label", "CenterTextY", "CenterY")
prototype.Delegate(PANEL, "label", "CenterTextX", "CenterX")
prototype.Delegate(PANEL, "label", "GetTextSize", "GetSize")

function PANEL:Initialize()
	self.BaseClass.Initialize(self)
	
	local label = gui2.CreatePanel("text", self)
	label:SetEditable(false)
	label:SetIgnoreMouse(true)
	self.label = label
end

function PANEL:SizeToText()
	local marg = self:GetMargin()
		
	self.label:SetPosition(marg:GetPosition())
	self:SetSize(self.label:GetSize() + marg:GetSize()*2)
end

function PANEL:Test()		
	local btn = gui2.CreatePanel("text_button")
	btn:SetText("oh")
	btn:SetMargin(Rect()+S*2)
	btn:SizeToText()
	btn:SetMode("toggle")
	btn:SetPosition(Vec2()+100)
end

gui2.RegisterPanel(PANEL)