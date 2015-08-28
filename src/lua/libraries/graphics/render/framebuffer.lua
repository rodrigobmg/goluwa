local gl = require("graphics.ffi.opengl") -- OpenGL
local render = (...) or _G.render

local base_color = gl.e.GL_COLOR_ATTACHMENT0

local function attachment_to_enum(self, var)
	if not var then return end
	
	if self.textures[var] then
		return var
	elseif type(var) == "number" then
		return base_color + var - 1
	elseif var == "depth" then
		return "GL_DEPTH_ATTACHMENT"
	elseif var == "stencil" then
		return "GL_STENCIL_ATTACHMENT"
	elseif var == "depth_stencil" then
		return "GL_DEPTH_STENCIL_ATTACHMENT"
	elseif var:startswith("color") then
		return base_color + (tonumber(var:match(".-(%d)")) or 0) - 1
	end
end

local function bind_mode_to_enum(str)		
	if str == "all" or str == "read_write" then
		return "GL_FRAMEBUFFER"
	elseif str == "read" then
		return "GL_READ_FRAMEBUFFER"
	elseif str == "write" or str == "draw" then
		return "GL_DRAW_FRAMEBUFFER"
	end
end

local function generate_draw_buffers(self)
	local draw_buffers = {}
	--self.read_buffer = nil -- TODO

	for k,v in pairs(self.textures) do
		if (v.mode == "GL_DRAW_FRAMEBUFFER" or v.mode == "GL_FRAMEBUFFER") and not v.draw_manual then
			table.insert(draw_buffers, v.pos)
		else
			--if self.read_buffer then
			--	warning("more than one read buffer attached", 2)
			--end
			--self.read_buffer = v.mode
			--table.insert(draw_buffers, 0)
		end
	end
	
	for k,v in pairs(self.render_buffers) do
		if (v.mode == "GL_DRAW_FRAMEBUFFER" or v.mode == "GL_FRAMEBUFFER") and not v.draw_manual then
			table.insert(draw_buffers, v.pos)
		else
			--if self.read_buffer then
			--	warning("more than one read buffer attached", 2)
			--end
			--self.read_buffer = v.mode
			table.insert(draw_buffers, 0)
		end
	end
	
	table.sort(draw_buffers, function(a, b) return a < b end)
	
	return ffi.new("GLenum["..#draw_buffers.."]", draw_buffers), #draw_buffers
end

local META = prototype.CreateTemplate("framebuffer")

META:GetSet("BindMode", "all", {"all", "read", "write"})
META:GetSet("Size", Vec2(128,128))

function render.GetScreenFrameBuffer()
	if not gl.GenFramebuffer then return end
	if not render.screen_buffer then
		local self = prototype.CreateObject(META)
		self.fb = gl.CreateFramebuffer(0)
		self.textures = {}
		self.render_buffers = {}
		self.draw_buffers_cache = {}
		self:SetSize(render.GetScreenSize())
		self:SetBindMode("read_write")
		
		render.screen_buffer = self
	end
	
	return render.screen_buffer
end

function render.CreateFrameBuffer(width, height, textures)
	local self = prototype.CreateObject(META)
	self.fb = gl.CreateFramebuffer()
	self.textures = {}
	self.render_buffers = {}
	self.draw_buffers_cache = {}
	
	self:SetBindMode("read_write")
	
	if width and height then
		self:SetSize(Vec2(width, height))
		
		if not textures then
			textures = {
				attach = "color",
				internal_format = "rgba8",
			}
		end
	end
	
	if textures then
		if not textures[1] then textures = {textures} end
		
		for i, v in ipairs(textures) do
			local attach = v.attach or "color"
			
			if attach == "color" then
				attach = i
			end
			
			local name = v.name or attach
			
			local tex = render.CreateTexture()
			tex:SetSize(self:GetSize():Copy())
			
			if attach == "depth" then
				tex:SetMagFilter("nearest")
				--tex:SetMinFilter("nearest")
				tex:SetWrapS("clamp_to_edge")
				tex:SetWrapT("clamp_to_edge")
			else
				if v.filter == "nearest" then
					--tex:SetMinFilter("nearest")
					tex:SetMagFilter("nearest")
				end
			end
				
			if v.internal_format then 
				tex:SetInternalFormat(v.internal_format)
			end
			
			if v.depth_texture_mode then
				tex:SetDepthTextureMode(v.depth_texture_mode)
			end
			
			tex:SetMipMapLevels(1)
			tex:SetupStorage()
			--tex:Clear()
			
			self:SetTexture(attach, tex, nil, name)
		end
		
		self:CheckCompletness()
	end
	
	return self
end

function META:__tostring2()
	return ("[%i]"):format(self.fb.id)
end

function META:CheckCompletness()
	local err = self.fb:CheckStatus("GL_FRAMEBUFFER")
	
	if err ~= gl.e.GL_FRAMEBUFFER_COMPLETE then
		local str = "Unknown error: " .. err
		
		if err == gl.e.GL_FRAMEBUFFER_UNSUPPORTED then
			str = "format not supported"
		elseif err == gl.e.GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT then
			str = "incomplete texture"
		elseif err == gl.e.GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT then
			str = "missing texture"
		elseif err == gl.e.GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS then
			str = "attached textures must have same dimensions"
		elseif err == gl.e.GL_FRAMEBUFFER_INCOMPLETE_FORMATS then
			str = "attached textures must have same format"
		elseif err == gl.e.GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER then
			str = "missing draw buffer"
		elseif err == gl.e.GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER then
			str = "missing read buffer"
		elseif err == 0 then
			str = "invalid framebuffer target"
		end
		
		for k, v in pairs(self.textures) do
			logn(v.tex, " attached to ", v.pos)
			v.tex:DumpInfo()
		end
		
		warning(str)
	end
end

function META:SetBindMode(str)
	self.BindMode = str
	
	self.enum_bind_mode = bind_mode_to_enum(str)
end

do -- binding
	local current_id = 0

	do
		local stack = {}
		
		function META:Push(...)
			table.insert(stack, current_id)
		
			self:Bind()
			
			if self.draw_buffers_size then
				self.fb:DrawBuffers(self.draw_buffers_size, self.draw_buffers)
			end
			
			--if fb.read_buffer then
			--	gl.ReadBuffer(fb.read_buffer)
			--end
				
			current_id = self.fb.id
		end
		
		function META:Pop()		
			local id = table.remove(stack)		
			
			--fb:Unbind()
			gl.BindFramebuffer("GL_FRAMEBUFFER", id)
			
			current_id = id
		end
		
		function META:Begin(...)
			self:Push(...)
			render.PushViewport(0, 0, self.Size.w, self.Size.h)
		end

		function META:End()
			render.PopViewport()
			self:Pop()
		end
	end

	function META:Bind()
		self.fb:Bind(self.enum_bind_mode)
	end
	
	function META:Unbind()
		gl.BindFramebuffer(self.enum_bind_mode, 0) -- uh
	end
end

do
	local base = gl.e.GL_TEXTURE_CUBE_MAP_POSITIVE_X

	function META:SetCubemapTexture(pos, i, tex)
		pos = attachment_to_enum(self, pos)
		self.fb:Texture2D(pos, base + i - 1, tex and tex.gl_tex.id or 0, 0)
	end
end
	
function META:SetTexture(pos, tex, mode, uid)
	pos = attachment_to_enum(self, pos)
	mode = bind_mode_to_enum(mode or "write")
	
	if not uid then
		uid = pos
	end
	
	if typex(tex) == "texture" then
		local id = tex and tex.gl_tex.id or 0 -- 0 will be detach if tex is nil
	
		--if MESA and not gl.CreateFramebuffers then
		--	self.fb:Texture2D(pos, "GL_TEXTURE_2D", id, 0)
		--else
			self.fb:Texture(pos, id, 0)
		--end
		
		if id ~= 0 then			
			self.textures[uid] = {
				tex = tex, 
				mode = mode, 
				pos = pos, 
				uid = uid, 
				draw_manual = pos == "GL_DEPTH_ATTACHMENT" or pos == "GL_STENCIL_ATTACHMENT" or pos == "GL_DEPTH_STENCIL_ATTACHMENT"
			}
			self:SetSize(tex:GetSize():Copy())
		else
			self.textures[uid] = nil
		end
	else
		if tex then
			local rb = self.render_buffers[uid] or gl.CreateRenderbuffer()
		
			-- ASDF
			if tex.size then
				tex.width = tex.size.w
				tex.height = tex.size.h
				tex.size = nil
			end
		
			rb:StorageMultisample(
				"GL_RENDERBUFFER",
				0,				
				"GL_" .. tex.internal_format:upper(),
				tex.width, 
				tex.height
			)

			self.fb:Renderbuffer("GL_FRAMEBUFFER", pos, "GL_RENDERBUFFER", rb.id)
		
			self.render_buffers[uid] = {rb = rb}
		else
			if self.render_buffers[uid] then
				self.render_buffers[uid].rb:Delete()
			end
			
			self.render_buffers[uid] = nil
		end
	end
		
	self.draw_buffers, self.draw_buffers_size = generate_draw_buffers(self)
end

function META:GetTexture(pos)
	local uid = attachment_to_enum(self, pos or 1)
		
	if not uid then
		return render.GetErrorTexture()
	end
	
	return self.textures[uid] and self.textures[uid].tex or render.GetErrorTexture()
end
	
function META:SetWrite(pos, b)
	pos = attachment_to_enum(self, pos)
	if pos then
		local val = self.textures[pos]
		local mode = val.mode
		
		if b then
			if mode == "GL_READ_FRAMEBUFFER" then
				val.mode = "GL_FRAMEBUFFER"
			end
		else
			if mode == "GL_FRAMEBUFFER" or mode == "GL_DRAW_FRAMEBUFFER" then
				val.mode = "GL_READ_FRAMEBUFFER"
			end
		end
		
		if mode ~= val.mode then
			self.draw_buffers, self.draw_buffers_size = generate_draw_buffers(self)
		end
	end
end

function META:SetRead(pos, b)
	pos = attachment_to_enum(self, pos)
	
	if pos then
		local val = self.textures[pos]
		local mode = val.mode
		
		if b then
			if val.mode == "GL_DRAW_FRAMEBUFFER" then
				val.mode = "GL_FRAMEBUFFER"
				self.draw_buffers, self.draw_buffers_size = generate_draw_buffers(self)
			end
		else
			if mode == "GL_FRAMEBUFFER" or mode == "GL_READ_FRAMEBUFFER" then
				val.mode = "GL_DRAW_FRAMEBUFFER"
			end
		end
		
		if mode ~= val.mode then
			self.draw_buffers, self.draw_buffers_size = generate_draw_buffers(self)
		end
	end
end

function META:WriteThese(str)
	if not self.draw_buffers_cache[str] then
		for pos in pairs(self.textures) do
			self:SetWrite(pos, false)
		end
		
		if str == "all" then
			for pos in pairs(self.textures) do
				self:SetWrite(pos, true)
			end
		elseif str == "none" then
			for pos in pairs(self.textures) do
				self:SetWrite(pos, false)
			end
		else
			for _, pos in pairs(tostring(str):explode("|")) do
				pos = tonumber(pos) or pos
				self:SetWrite(pos, true)
			end
		end
		
		self.draw_buffers_cache[str] = {self.draw_buffers, self.draw_buffers_size}
	end
	
	self.draw_buffers, self.draw_buffers_size = self.draw_buffers_cache[str][1], self.draw_buffers_cache[str][2]
end

do
	local temp_color = ffi.new("float[4]")
	local temp_colori = ffi.new("int[4]")

	function META:Clear(i, r,g,b,a, d,s)
		if self.draw_buffers_size then
			self.fb:DrawBuffers(self.draw_buffers_size, self.draw_buffers)
		end
		
		i = i or "all"
			
		if i == "all" then
			self:Clear("color", r,g,b,a)			
			self:Clear("depth", d or 1)
			if s then self:Clear("stencil", s) end
		elseif i == "color" then
			
			temp_color[0] = r or 0
			temp_color[1] = g or 0
			temp_color[2] = b or 0
			temp_color[3] = a or 0
			
			for i = 0, self.draw_buffers_size or 1 do
				self.fb:Clearfv("GL_COLOR", i, temp_color)
			end
		elseif i == "depth" then
			temp_color[0] = r or 0
			self.fb:Clearfv("GL_DEPTH", 0, temp_color)
		elseif i == "stencil" then
			temp_colori[0] = r or 0
			self.fb:Cleariv("GL_STENCIL", 0, temp_colori)
		elseif i == "depth_stencil" then
			self.fb:Clearfi("GL_DEPTH_STENCIL", 0, r or 0, g or 0)
		elseif type(i) == "number" then
			
			temp_color[0] = r or 0
			temp_color[1] = g or 0
			temp_color[2] = b or 0
			temp_color[3] = a or 0
			
			self.fb:Clearfv("GL_COLOR", i - 1, temp_color)
		elseif self.textures[i] then
			self:Clear(self.textures[i].pos - base_color - 1, r,g,b,a, d,s)
		end
	end
end
	
prototype.Register(META)


if not RELOAD then return end 
 


local fb = render.CreateFrameBuffer() 
fb:SetSize(Vec2()+1024)

do
	local tex = render.CreateTexture("2d")
	tex:SetSize(Vec2(1024, 1024))
	tex:SetInternalFormat("rgba8")
	tex:Clear()

	fb:SetTexture(1, tex, "read_write")
end

do
	local tex = render.CreateTexture("2d") 
	tex:SetSize(Vec2(1024, 1024))
	tex:SetInternalFormat("rgba8")
	tex:Clear()

	fb:SetTexture(2, tex, "read_write")
end

do	
	fb:WriteThese("2")

	fb:Begin()
		surface.SetColor(1,1,1,1)
		surface.DrawText("YOU SHOULD SEE THIS", 150, 80)
	fb:End()
end

do	
	fb:WriteThese("1")

	fb:Begin()
		surface.SetColor(1,1,1,1)
		surface.DrawText("YOU SHOULD NOT SEE THIS", 250, 50)
	fb:End()

	fb:Clear(1)
end

do -- write a red square only to attachment 2
	fb:WriteThese("2")

	fb:Begin() 
		surface.SetWhiteTexture()
		surface.SetColor(1,0,0,1)
		surface.DrawRect(30,30,50,50)
	fb:End()
end

do	-- write a pink square only to attachment 1
	fb:WriteThese("1")

	fb:Begin()
		surface.SetWhiteTexture()
		surface.SetColor(1,0,1,1)
		surface.DrawRect(100,30,50,50)
	fb:End()
end

--fb:WriteThese("stencil")
 
do -- write a rotated green rectangle to attachment 1 and 2
	fb:WriteThese("1|2")
	
	fb:Begin()
		surface.SetWhiteTexture()
		surface.SetColor(0,1,0,0.5)
		surface.DrawRect(20,20,50,50, 50)
	fb:End()
end

event.AddListener("PostDrawMenu", "lol", function()
	surface.SetTexture(fb:GetTexture(1))
	surface.SetColor(1, 1, 1, 1)
	surface.DrawRect(0, 0, 1024, 1024)
	
	surface.SetTexture(fb:GetTexture(2))
	surface.SetColor(1, 1, 1, 1)
	surface.DrawRect(300, 300, 1024, 1024)
end)
