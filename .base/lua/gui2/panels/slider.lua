local gui2 = ... or _G.gui2
local S = gui2.skin.scale

local PANEL = {}

PANEL.ClassName = "slider"
PANEL.Base = "base"

prototype.GetSet(PANEL, "Fraction", Vec2(0.5, 0.5))

prototype.GetSet(PANEL, "XSlide", true)
prototype.GetSet(PANEL, "YSlide", false)

prototype.GetSet(PANEL, "RightFill", true)
prototype.GetSet(PANEL, "LeftFill", false)

function PANEL:Initialize()
	self:SetMinimumSize(Vec2(35, 35))
	self:SetColor(Color(0,0,0,0))

	local line = gui2.CreatePanel("base", self)
	line:SetStyle("button_active")
	line.OnPostDraw = function()
		surface.SetTexture(gui2.skin.menu_select[1])
		
		if self.RightFill then
			if self.XSlide and self.YSlide then
				self:DrawRect(0, 0, self.Fraction.x * line:GetWidth(), self.Fraction.y * line:GetHeight())
			elseif self.XSlide then
				self:DrawRect(0, 0, self.Fraction.x * line:GetWidth(), line:GetHeight())
			elseif self.YSlide then
				self:DrawRect(0, 0, line:GetWidth(), self.Fraction.y * line:GetHeight())
			end
		elseif self.LeftFill then
			if self.XSlide and self.YSlide then
				self:DrawRect(
					self.Fraction.x * line:GetWidth(), 
					self.Fraction.y * line:GetHeight(), 
					line:GetWidth() - (self.Fraction.x * line:GetWidth()), 
					line:GetHeight() - (self.Fraction.y * line:GetHeight())
				)
			elseif self.XSlide then
				self:DrawRect(self.Fraction.x * line:GetWidth(), 0, line:GetWidth() - (self.Fraction.x * line:GetWidth()), 4)
			elseif self.YSlide then
				self:DrawRect(0, self.Fraction.y * line:GetHeight(), 4, line:GetHeight() - (self.Fraction.y * line:GetHeight()))
			end
		end
	end
	self.line = line

	local button = gui2.CreatePanel("button", self)
	button:SetStyleTranslation("button_active", "button_rounded_active")
	button:SetStyleTranslation("button_inactive", "button_rounded_inactive")
	button:SetStyle("button_rounded_inactive")
	
	button:SetDraggable(true)
	
	button.OnPositionChanged = function(_, pos)
	
		if self.XSlide and self.YSlide then
			pos.x = math.clamp(pos.x, 0, self:GetWidth() - self.button:GetWidth())
			pos.y = math.clamp(pos.y, 0, self:GetHeight() - self.button:GetHeight())
		elseif self.XSlide then
			pos.x = math.clamp(pos.x, 0, self:GetWidth() - self.button:GetWidth())
			pos.y = self:GetHeight()/2 - button:GetHeight()/2
		elseif self.YSlide then
			pos.x = self:GetWidth()/2 - button:GetWidth()/2
			pos.y = math.clamp(pos.y, 0, self:GetHeight() - self.button:GetHeight())
		end
		
		self.Fraction = pos / (self:GetSize() - self.button:GetSize())
		
		self:MarkCacheDirty()
	end
	self.button = button
end
		
function PANEL:OnLayout()
	self.button:SetSize(self:GetSize():Copy() - S*8)
	
	if self.XSlide and self.YSlide then
		self.line:SetSize(self:GetSize():Copy())
	end
	
	if self.XSlide then
		self.button:SetWidth(S*5)
		self.line:SetY(8*S)
		self.line:SetWidth(self:GetWidth())
		self.line:SetHeight(self:GetHeight()-8*S*2)
	end
	
	if self.YSlide then
		self.button:SetHeight(S*5)
		self.line:SetX(8*S)
		self.line:SetHeight(self:GetHeight())
		self.line:SetWidth(self:GetWidth()-8*S*2)
	end
	
	self.button:SetPosition(self.Fraction * self:GetSize())
end

gui2.RegisterPanel(PANEL)