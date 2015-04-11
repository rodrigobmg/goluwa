local gmod = ... or gmod
local META = gmod.env.FindMetaTable("IMaterial")

function META:GetTexture()
	return gmod.WrapObject(self.__obj:GetDiffuseTexture(), "ITexture")
end

function META:GetColor(x,y)
	local r,g,b,a = self.__obj:GetDiffuseTexture():GetPixelColor(x,y)
	return {r=r,g=g,b=b,a=a or 255}
end

function META:GetName()
	return self.__obj.gmod_name
end

function META:GetShader()
	return self.__obj.vmt and self.__obj.vmt.shader or "Loading"-- this isn't cased properly
end