local render = ... or _G.render

local META = prototype.CreateTemplate("material", "base")

do
	META:GetSet("Error", nil)

	function render.GetErrorMaterial()

		if not render.error_material then 	
			render.error_material = render.CreateMaterial("base")
			render.error_material:SetError("render.GetErrorMaterial")
		end
		
		return render.error_material
	end
end

function META:SetError(reason)
	self.Error = reason
	self.DiffuseTexture = render.GetErrorTexture()
end

META:Register()

function render.CreateMaterial(name)
	return prototype.CreateDerivedObject("material", name)
end

function render.CreateMaterialTemplate(name)
	local META = prototype.CreateTemplate()
	
	META.Name = name
	
	function META:Register()
		META.TypeBase = "base"
		prototype.Register(META, "material", META.Name)
	end
	
	return META
end

function render.SetMaterial(mat)
	render.material = mat
end

function render.GetMaterial()
	return render.material
end