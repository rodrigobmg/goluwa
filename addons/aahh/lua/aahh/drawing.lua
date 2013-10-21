do
	function aahh.GetScreenSize()
		return Vec2(surface.GetScreenSize())
	end

	function aahh.GetTextSize(font, str)
		surface.SetFont(font)		
		return Vec2(surface.GetTextSize(str))
	end	
		
	function aahh.SetCursor()
		
	end
	
	local shapes = {
		rect = function(rect, color, roundness, border_size, border_color, shadow_distance, shadow_color, tl, tr, bl, br)    
			color = color or Color(1,1,1,1)

			surface.SetWhiteTexture()
			
			if shadow_distance then
				shadow_color = shadow_color or Color(0,0,0,0.5)
				surface.Color(shadow_color:Unpack())
				surface.DrawRect(rect.x + shadow_distance.x, rect.y + shadow_distance.y, rect.w, rect.h)
			end
			
			if border_size and border_size > 0 then
				border_color = border_color or Color(1,1,1,1)

				surface.Color(border_color:Unpack())
				surface.DrawRect(rect:Unpack())
			
				rect:Shrink(border_size)
			end			
			
			surface.Color(color:Unpack())
			surface.DrawRect(rect:Unpack())
		end,
		
		text = function(text, pos, font, color, align_normal, shadow_dir, shadow_color, shadow_size, shadow_blur)			
			surface.SetFont(font)
			
			if align_normal then
				local x, y = pos:Unpack()
				local w, h = surface.GetTextSize(text)
				
				x = x + w*align_normal.x
				y = y + h*align_normal.y
			
				surface.SetTextPos(x, y)
			end
			
			surface.Color(color:Unpack())
			surface.DrawText(text)
			
			if aahh.debug then
				surface.Color(1,0,0,0.25)
				surface.SetWhiteTexture()
				local w, h = surface.GetTextSize(text)
				surface.DrawRect(pos.x, pos.y, w, h)
			end
		end,
		
		texture = function(tex, rect, color, uv, nofilter)
			color = color or Color(1,1,1,1)

			surface.SetTexture(tex)
			surface.Color(color:Unpack())
			surface.DrawRect(rect:Unpack())
		end,
		
		line = function(a, b, color)
			surface.Color(color:Unpack())
			surface.DrawLine(a.x, a.y, b.x, b.y)
		end,
	}

	function aahh.Draw(type, ...)
		if shapes[type] then
			shapes[type](...)
		else
			--errorf("unknown shape %s", 2, type)
		end
	end

	function aahh.StartDraw(pnl)
		if not pnl:IsValid() then return end
		local x,y = pnl:GetWorldPos():Unpack()
		local w,h = pnl:GetSize():Unpack()
		
		surface.PushMatrix(x,y)
		--surface.StartClipping(x,y,w,h)
	end

	function aahh.EndDraw(pnl)	
	--	surface.EndClipping()
		surface.PopMatrix()
	end
end

aahh.remove_these = aahh.remove_these or {}

function aahh.Update(delta)
	for key, pnl in pairs(aahh.remove_these) do
		pnl:Remove(true)
		aahh.remove_these[key] = nil
	end

	if aahh.ActivePanel:IsValid() then
		input.DisableFocus = true
	else
		input.DisableFocus = false
	end
	
	event.Call("DrawHUD")
	
	event.Call("PreDrawMenu")
		if aahh.ActiveSkin:IsValid() then
			aahh.ActiveSkin.FT = delta
			aahh.ActiveSkin:Think(delta)
		end
		
		if aahh.World:IsValid() then
			aahh.World:Draw()
		end
		
		if aahh.HoveringPanel:IsValid() then
			aahh.SetCursor(aahh.HoveringPanel:GetCursor())
		else
			aahh.SetCursor(1)
		end
	event.Call("PostDrawMenu")
end

event.AddListener("OnDraw2D", "aahh", aahh.Update, logn)