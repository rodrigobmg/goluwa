local gl = require("lj-opengl")
local render = (...) or _G.render

local META = prototype.CreateTemplate("vertex_buffer")

prototype.GetSet(META, "UpdateIndices", true)

function render.CreateVertexBuffer(vertex_attributes, vertices, indices, vertices_size, indices_size)
	check(vertex_attributes, "table")
	check(vertices, "cdata")
	check(indices, "cdata")
	
	local self = prototype.CreateObject(META)
	self.vertices_id = gl.GenBuffer()
	self.indices_id = gl.GenBuffer()
	self.vao_id = gl.GenVertexArray()
	self.vertex_attributes = vertex_attributes
	
	self:UpdateBuffer(vertices, indices, vertices_size, indices_size)

	return self
end 

function META:OnRemove()
	gl.DeleteBuffers(1, ffi.new("GLuint[1]", self.vertices_id))
	gl.DeleteBuffers(1, ffi.new("GLuint[1]", self.indices_id))
end

function META:Draw(count)
	render.BindVertexArray(self.vao_id)
	--render.BindArrayBuffer(self.vertices_id)	
	gl.BindBuffer(gl.e.GL_ELEMENT_ARRAY_BUFFER, self.indices_id)
	gl.DrawElements(gl.e.GL_TRIANGLES, count or self.indices_count, gl.e.GL_UNSIGNED_INT, nil)
end

function META:UpdateBuffer(vertices, indices, vertices_size, indices_size)
	vertices = vertices or self.vertices
	indices = indices or self.indices
	
	if vertices then
		self.vertices = vertices
		self.vertices_size = vertices_size or ffi.sizeof(vertices)
		
		render.BindArrayBuffer(self.vertices_id)
		gl.BufferData(gl.e.GL_ARRAY_BUFFER, self.vertices_size, vertices, gl.e.GL_STATIC_DRAW)
	end
	
	if indices and self.UpdateIndices then
		indices_size = indices_size or ffi.sizeof(self.indices)
		
		self.indices = indices
		self.indices_size = indices_size
		self.indices_count = indices_size / ffi.sizeof("unsigned int")
		
		gl.BindBuffer(gl.e.GL_ELEMENT_ARRAY_BUFFER, self.indices_id)
		gl.BufferData(gl.e.GL_ELEMENT_ARRAY_BUFFER, indices_size, indices, gl.e.GL_STATIC_DRAW)
	end
		
	render.BindVertexArray(self.vao_id)		
		for _, data in ipairs(self.vertex_attributes) do
			gl.EnableVertexAttribArray(data.location)
			gl.VertexAttribPointer(data.location, data.arg_count, data.enum, false, data.stride, data.type_stride)
		end
	render.BindVertexArray(0)
	
	render.BindArrayBuffer(0)
	gl.BindBuffer(gl.e.GL_ELEMENT_ARRAY_BUFFER, 0)
	
	--logf("[render] updated %s with %s amount of data\n", self, utility.FormatFileSize(self.vertices_size + self.indices_size))
end

function META:UnreferenceMesh()
	self.vertices = nil
	self.indices = nil
	collectgarbage("step")
end