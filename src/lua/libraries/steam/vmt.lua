local steam = ... or _G.steam

local path_translate = {
	DiffuseTexture = "basetexture",
	Diffuse2Texture = "basetexture2",
	NormalTexture = "bumpmap",
	Normal2Texture = "bumpmap2",
	MetallicTexture = "envmapmask",
	RoughnessTexture = "envmapmask",
}

local property_translate = {
	--IlluminationColor = {"selfillumtint"},
	AlphaTest = {"alphatest", function(num) return num == 1 end},
	SSBump = {"ssbump", function(num) return num == 1 end},
	DetailScale = {"detailscale"},
	DetailBlendFactor = {"detailblendfactor"},
	NoCull = {"nocull"},
	Translucent = {"alphatest", "translucent", function(num) return num == 1 end},
	NormalAlphaMetallic = {"normalmapalphaenvmapmask", function(num) return num == 1 end},
	DiffuseAlphaMetallic = {"basealphaenvmapmask", function(num) return num == 1 end},
	RoughnessMultiplier = {"phongexponent", function(num) return num/255 end},
	MetallicMultiplier = {"phongboost", function(num) return num/100 end},
}

function steam.LoadMaterial(path, material)
	material:SetName(path)
		
	resource.Download(
		path,  
		function(path)
			local vmt, err = steam.VDFToTable(vfs.Read(path), function(key) return (key:lower():gsub("%$", "")) end)
			
			if err then	
				material:SetError(err)
				return
			end
			
			local k,v = next(vmt)
						
			if type(k) ~= "string" or type(v) ~= "table" then
				material:SetError("bad material " .. path)
				return
			end
			
			if k == "patch" then
				if not vfs.IsFile(v.include) then
					v.include = v.include:lower()
				end
				
				local vmt2, err2 = steam.VDFToTable(vfs.Read(v.include), function(key) return (key:lower():gsub("%$", "")) end)
				
				if err2 then	
					material:SetError(err2)
					return
				end
				
				local k2,v2 = next(vmt2)
							
				if type(k2) ~= "string" or type(v2) ~= "table" then
					material:SetError("bad material " .. path)
					return
				end
				
				table.merge(vmt2, v.replace)
				
				vmt = vmt2
				v = v2
				k = k2
			end
						
			vmt = v
			vmt.shader = k
			vmt.fullpath = path
			
			for key, info in pairs(property_translate) do
				for i,v in ipairs(info) do
					local val = vmt[v]
					if val then
						local func = info[#info]
						
						material["Set" .. key](material, (type(func) == "function" and func(val)) or val)
						
						break
					end
				end
			end
			
			if not vmt.bumpmap and vmt.basetexture then
				local new_path = vfs.FixPath(vmt.basetexture)
				if not new_path:endswith(".vtf") then
					new_path = new_path .. ".vtf"
				end
				new_path = new_path:gsub("%.vtf", "_normal.vtf")
				if vfs.IsFile("materials/" .. new_path) then
					vmt.bumpmap = new_path
				else
					new_path = new_path:lower()
					if vfs.IsFile("materials/" .. new_path) then
						vmt.bumpmap = new_path
					end
				end
				
				if vmt.bumpmap then
					logf("normal map not defined in %s. using %s as normal map instead\n", material:GetName(), vmt.bumpmap)
				end
			end
			
			for key, field in pairs(path_translate) do
				if vmt[field] then
					local new_path = vfs.FixPath("materials/" .. vmt[field])
					if not new_path:endswith(".vtf") then
						new_path = new_path .. ".vtf"
					end
					resource.Download(
						new_path,
						function(path)
							material["Set" .. key](material, Texture(path))
						end
					)
				end
			end
			
			if material:GetMetallicMultiplier() == 0 then
				material:SetMetallicMultiplier(0.1)
			end
			
			material:SetNormalMapScale(Vec3(1,1,1))
			
			material.vmt = vmt	
		end, 
		function()
			material:SetError("material "..path.." not found")
		end
	)
end