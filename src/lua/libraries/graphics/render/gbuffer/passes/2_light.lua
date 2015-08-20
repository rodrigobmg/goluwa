local render = ... or _G.render

local PASS = {}

PASS.Stage, PASS.Name = FILE_NAME:match("(%d-)_(.+)")

PASS.Buffers = {
	{"light", "RGB16F"},
}

function PASS:Draw3D()
	render.EnableDepth(false)	
	render.SetBlendMode("one", "one")
	
	render.gbuffer:WriteThese("light")
	render.gbuffer:Clear("light")
	render.gbuffer:Begin()
		event.Call("Draw3DLights")
	render.gbuffer:End() 	
end

function PASS:DrawDebug(i,x,y,w,h,size)
	for name, map in pairs(render.shadow_maps) do
		local tex = map:GetTexture("depth")
	
		surface.SetWhiteTexture()
		surface.SetColor(1, 1, 1, 1)
		surface.DrawRect(x, y, w, h)
		
		surface.SetColor(1,1,1,1)
		surface.SetTexture(tex)
		surface.DrawRect(x, y, w, h)
		
		surface.SetTextPosition(x, y + 5)
		surface.DrawText(tostring(name))
		
		if i%size == 0 then
			y = y + h
			x = 0
		else
			x = x + w
		end
		
		i = i + 1
	end
	
	return i,x,y,w,h
end

PASS.Shader = {
	vertex = {
		mesh_layout = {
			{pos = "vec3"},
		},	
		source = "gl_Position = g_projection_view_world * vec4(-pos, 1);"
	},
	fragment = { 
		variables = {			
			light_view_pos = Vec3(0,0,0),
			light_color = Color(1,1,1,1),				
			light_intensity = 0.5,
			light_projection_view = "mat4",
			tex_shadow_map = "sampler2D",
		},  
		source = [[			
			out vec4 out_color;
			
			#define EPSILON 0.00001			
			
			float get_shadow(vec2 uv, float bias)    
			{
				float visibility = 0;
			
				if (lua[light_point_shadow = false])
				{
					vec3 light_dir = get_view_pos(uv) - light_view_pos;
				
					float SampledDistance = texture(lua[tex_shadow_map_cube = "samplerCube"], light_dir).r;

					float Distance = length(light_dir);

					if (Distance <= SampledDistance + EPSILON)
						return 100.0;
					else
						return SampledDistance;
				}
				else
				{
					vec4 temp = light_projection_view * g_projection_view_inverse * vec4(uv * 2 - 1, texture(tex_depth, uv).r * 2 -1, 1.0);
					vec3 shadow_coord = temp.xyz / temp.w;

					if (shadow_coord.x > -1 && shadow_coord.x < 1 && shadow_coord.y > -1 && shadow_coord.y < 1 && shadow_coord.z > -1 && shadow_coord.z < 1)
					{						
						shadow_coord = 0.5 * shadow_coord + 0.5;
						vec2 texelSize = 1.0 / textureSize(tex_shadow_map, 0);
						
						for(int x = -1; x <= 1; ++x)
						{
							for(int y = -1; y <= 1; ++y)
							{
								visibility += shadow_coord.z- bias < texture(tex_shadow_map, shadow_coord.xy + vec2(x, y) * texelSize).r ? 1.0 : 0.0;        
							}    
						}
						
						visibility /= 9.0;
					}
					else if(lua[project_from_camera = false])
					{
						visibility = 1;
					}
				}
				
				return visibility;
			}  
									
			vec3 get_attenuation(vec2 uv, vec3 P, vec3 N, float cutoff)
			{			
				// calculate normalized light vector and distance to sphere light surface
				float r = lua[light_radius = 1000]/10;
				vec3 L = light_view_pos - P;
				float distance = length(L);
				float d = max(distance - r, 0);
				L /= distance;
				 
				float attenuation = 1;
				
				// calculate basic attenuation
				if (!lua[project_from_camera = false])
				{
					float denom = d/r + 1;
					attenuation = 1 / (denom*denom);
				}
				 
				// scale and bias attenuation such that:
				//   attenuation == 0 at extent of max influence
				//   attenuation == 1 when d == 0
				attenuation = (attenuation - cutoff) / (1 - cutoff);
				attenuation = max(attenuation, 0);
				 
				float dot = max(dot(L, N), 0);
				attenuation *= dot;
				
				if (lua[light_shadow = false])
				{					
					attenuation *= get_shadow(uv, attenuation*0.0005);
				}
				
				return light_color.rgb * attenuation * light_intensity;
			}
			
			vec3 get_ambient()
			{
				if (lua[project_from_camera = false])
				{
					vec3 ambient = lua[light_ambient_color = Color(0,0,0)].rgb * light_intensity;
						
					if (ambient == vec3(0,0,0))
					{
						ambient = light_color.rgb * 0.75 * light_intensity;
					}

					return ambient;
				}
			}
			
			const float e = 2.71828182845904523536028747135;
			const float pi = 3.1415926535897932384626433832;
			
			float beckmannDistribution(float x, float roughness) {
			  float NdotH = max(x, 0.0001);
			  float cos2Alpha = NdotH * NdotH;
			  float tan2Alpha = (cos2Alpha - 1.0) / cos2Alpha;
			  float roughness2 = roughness;
			  float denom = 3.141592653589793 * roughness2 * cos2Alpha * cos2Alpha;
			  return exp(tan2Alpha / roughness2) / denom;
			}
			
			float get_specular(vec3 lightDirection, vec3 viewDirection, vec3 surfaceNormal, float roughness, float fresnel) 
			{
			  float VdotN = max(dot(viewDirection, surfaceNormal), 0.0);
			  float LdotN = max(dot(lightDirection, surfaceNormal), 0.0);

			  //Half angle vector
			  vec3 H = normalize(lightDirection + viewDirection);

			  //Geometric term
			  float NdotH = max(dot(surfaceNormal, H), 0.0);
			  float VdotH = max(dot(viewDirection, H), 0.000001);
			  float LdotH = max(dot(lightDirection, H), 0.000001);
			  float G1 = (2.0 * NdotH * VdotN) / VdotH;
			  float G2 = (2.0 * NdotH * LdotN) / LdotH;
			  float G = min(1.0, min(G1, G2));
			  
			  //Distribution term
			  float D = beckmannDistribution(NdotH, roughness);

			  //Fresnel term
			  float F = (1.0 - VdotN) * fresnel*4;

			  //Multiply terms and done
			  return  G * F * D / max(3.14159265 * VdotN, 0.000001);
			}
				
			void main()
			{		
				//{out_color.rgb = vec3(1); return;}
			
				vec2 uv = get_screen_uv();					
				vec3 view_pos = get_view_pos(uv);
				vec3 normal = get_view_normal(uv);				
				
				vec3 attenuate = get_attenuation(uv, view_pos, normal, 0.005);
				vec3 ambient = get_ambient();
				vec3 diffuse = texture(tex_diffuse, uv).rgb;
				float metallic = get_metallic(uv)+0.025;
				float roughness = get_roughness(uv);
				
				vec3 reflection = texture(tex_reflection, uv).rgb;
				vec3 specular = vec3(get_specular(normalize(view_pos - light_view_pos), normalize(view_pos), -normal, (pow(roughness, 3)) + 0.0005, metallic));
				
				
				out_color.rgb = diffuse * mix(vec3(1,1,1), reflection, metallic);
				out_color.rgb += specular * attenuate;
				out_color.rgb *= ambient + attenuate;
			
			
				out_color.a = 1;
			}
		]]  
	}
}

render.RegisterGBufferPass(PASS)

render.AddGlobalShaderCode([[
vec3 get_light(vec2 uv)
{
	return texture(tex_light, uv).rgb;
}]], "get_light")