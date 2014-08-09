local gl = require("lj-opengl") -- OpenGL
local render = (...) or _G.render
 
render.gbuffer = NULL

local FRAMEBUFFERS = {
	{
		name = "diffuse",
		attach = "color",
		texture_format = {
			internal_format = "RGBA16F",
			min_filter = "nearest",
		}
	},
	{
		name = "normal",
		attach = "color",
		texture_format = {
			internal_format = "RGBA16F",
			min_filter = "nearest",
		}
	},
	{
		name = "position",
		attach = "color",
		texture_format = {
			internal_format = "RGBA16F",
			min_filter = "nearest",
		}
	},
	{
		name = "light",
		attach = "color",
		texture_format = {
			internal_format = "RGBA16F",
			min_filter = "nearest",
		}
	},
	{
		name = "depth",
		attach = "depth",
		draw_manual = true,
		texture_format = {
			internal_format = "DEPTH_COMPONENT32F",	 
			depth_texture_mode = gl.e.GL_RED,
			min_filter = "nearest",				
		} 
	} 
} 

local MESH = {
	name = "mesh_ecs",
	vertex = { 
		uniform = {
			pvm_matrix = "mat4",
		},			
		attributes = {
			{pos = "vec3"},
			{normal = "vec3"},
			{uv = "vec2"},
			{texture_blend = "float"},
		},	
		source = "gl_Position = pvm_matrix * vec4(pos, 1.0);"
	},
	fragment = { 
		uniform = {
			color = Color(1,1,1,1),
			diffuse = "sampler2D",
			diffuse2 = "sampler2D",
			vm_matrix = "mat4",
			v_matrix = "mat4",
			--detail = "sampler2D",
			--detailscale = 1,
			
			bump = "sampler2D",
			specular = "sampler2D",
		},		
		attributes = {
			{pos = "vec3"},
			{normal = "vec3"},
			{uv = "vec2"},
			{texture_blend = "float"},
		},			
		source = [[
			out vec4 out_color[4];

			void main() 
			{
				// diffuse
				out_color[0] = mix(texture(diffuse, uv), texture(diffuse2, uv), texture_blend) * color;			
				
				// specular
				out_color[0].a = texture2D(specular, uv).r;
				
				// normals
				{
					out_color[1] = vec4(normalize(mat3(vm_matrix) * -normal), 1);
									
					vec3 bump_detail = texture(bump, uv).rgb;
					
					if (bump_detail != vec3(1,1,1))
					{
						out_color[1].rgb = normalize(mix(out_color[1].rgb, bump_detail, 0.5));
					}
				}
				
				// position
				out_color[2] = vm_matrix * vec4(pos, 1);
				
				//out_color.rgb *= texture(detail, uv * detailscale).rgb;
			}
		]]
	}  
}

local LIGHT = {
	name = "gbuffer_light",
	vertex = { 
		uniform = {
			pvm_matrix = "mat4",
		},			
		attributes = {
			{pos = "vec3"},
			{normal = "vec3"},
			{uv = "vec2"},
			{texture_blend = "float"},
		},	
		source = "gl_Position = pvm_matrix * vec4(pos*2, 1);"
	}, 
	fragment = {
		uniform = {
			tex_depth = "sampler2D",
			tex_diffuse = "sampler2D",
			tex_normal = "sampler2D",
			tex_position = "sampler2D", 
			cam_pos = "vec3",
			cam_dir = "vec3",
			screen_size = Vec2(1,1),
			
			--light_intensity = 30,
			--light_shininess = 4,
			
			light_pos = Vec3(0,0,0),
			light_color = Color(1,1,1,1),				
			light_ambient_intensity = 0,
			light_diffuse_intensity = 0.5,
			light_specular_power = 64,
			light_radius = 1000,
			light_attenuation_constant = 0,
			light_attenuation_linear = 0,
			light_attenuation_exponent = 0.01,
		},  
		source = [[			
			out vec4 out_color;
			
			vec2 get_uv()
			{
				return gl_FragCoord.xy / screen_size;
			}
			
			vec4 CalcLightInternal(vec3 LightDirection, vec3 WorldPos, vec3 Normal, float gMatSpecularIntensity)
			{
				vec4 AmbientColor = light_color * light_ambient_intensity;
				float DiffuseFactor = dot(Normal, -LightDirection);

				vec4 DiffuseColor  = vec4(0, 0, 0, 0);
				vec4 SpecularColor = vec4(0, 0, 0, 0);

				if (DiffuseFactor > 0) 
				{
					DiffuseColor = light_color * light_diffuse_intensity * DiffuseFactor * 0.5;

					vec3 VertexToEye = normalize(cam_pos - WorldPos);
					vec3 LightReflect = normalize(reflect(LightDirection, Normal));
					
					float SpecularFactor = dot(VertexToEye, LightReflect);
					SpecularFactor = pow(SpecularFactor, light_specular_power);
					
					// this is taken from main2
					/*vec3 R = reflect(-LightDirection, Normal);						  
					vec3 half_dir = normalize(LightDirection + -cam_dir);
					float spec_angle = max(dot(R, half_dir), 0.0);
					float SpecularFactor = pow(spec_angle, light_specular_power);*/
					
					if (SpecularFactor > 0) 
					{
						SpecularColor = light_color * gMatSpecularIntensity * SpecularFactor;
					}
				}

				return (AmbientColor + DiffuseColor + SpecularColor);
			}
			
			vec4 CalcPointLight(vec3 WorldPos, vec3 Normal, float gMatSpecularIntensity)
			{
				vec3 LightDirection = WorldPos - light_pos;
				float Distance = length(LightDirection);
				
				if (Distance > light_radius * 10)
					return vec4(0,0,0,0);
				
				LightDirection = normalize(LightDirection);

				vec4 Color = CalcLightInternal(LightDirection, WorldPos, Normal, gMatSpecularIntensity);

				float Attenuation =  light_attenuation_constant +
									 light_attenuation_linear * Distance +
									 light_attenuation_exponent * Distance * Distance;

				Attenuation = min(1.0, Attenuation);
				
				
				return Color / Attenuation;
			}

			void main()
			{					
				vec2 uv = get_uv();
				
				float Specular = texture(tex_diffuse, uv).a;
				vec3 WorldPos = -texture(tex_position, uv).yxz;
				vec3 Normal = texture(tex_normal, uv).yxz;				
				
				out_color = CalcPointLight(WorldPos, Normal, Specular);
			}				
				
			/*void main2()
			{						
				vec2 uv = get_uv();

				vec3 diffuse = texture(tex_diffuse, uv).rgb;
				vec3 normal = texture(tex_normal, uv).yxz;				
				vec3 position = -texture(tex_position, uv).yxz;
				float specular = texture(tex_specular, uv).x;
													
				vec3 final_color = vec3(0);
				
				vec3 light_vec = light_pos - position;
				float light_dist = length(light_vec);
				
				if (light_dist > light_radius * 10) 
				{
					out_color.rgb = final_color;
					return;
				}
				
				vec3 light_dir = normalize(light_vec);
				
				float lambertian = dot(light_dir, normal);
	
				if (lambertian > 0.0)
				{						
					vec3 R = reflect(-light_dir, normal);
					  
					vec3 half_dir = normalize(light_dir + -cam_dir);
					float spec_angle = max(dot(R, half_dir), 0.0);
					float S = pow(spec_angle, light_shininess);
					
					final_color = (lambertian * diffuse + S * specular) * light_color.rgb;
				}
						
				out_color.rgb = final_color / light_dist * light_intensity;
				out_color.a = 0.5;
			}*/
		]]  
	}
} 

local GBUFFER = {
	name = "gbuffer",
	vertex = {
		uniform = {
			pvm_matrix = "mat4",
		},			
		attributes = {
			{pos = "vec2"},
			{uv = "vec2"},
		},
		source = "gl_Position = pvm_matrix * vec4(pos, 0.0, 1.0);"
	},
	fragment = {
		uniform = {
			tex_diffuse = "sampler2D",
			tex_light = "sampler2D",
			tex_normal = "sampler2D",
			tex_position = "sampler2D", 
			tex_depth = "sampler2D",
			rt_w = "float",
			rt_h = "float",
			time = "float",
			cam_pos = "vec3",
			cam_vec = "vec3",
			pv_matrix = "mat4",
		},  
		attributes = {
			{pos = "vec2"},
			{uv = "vec2"},
		},
		source = [[			
			out vec4 out_color;
			
			//
			//SSAO
			//
			vec2 camerarange = vec2(1.0, 10000.0);

			float readDepth( in vec2 coord ) {
				return (2.0 * camerarange.x) / (camerarange.y + camerarange.x - pow(texture2D(tex_depth, coord ).r,10) * (camerarange.y - camerarange.x));
			}

			float compareDepths( in float depth1, in float depth2 ) {
				float aoCap = 0.25;
				float aoMultiplier=1500.0;
				float depthTolerance=0.0000;
				float aorange = 100000.0;// units in space the AO effect extends to (this gets divided by the camera far range
				float diff = sqrt( clamp(1.0-(depth1-depth2) / (aorange/(camerarange.y-camerarange.x)),0.0,1.0) );
				float ao = min(aoCap,max(0.0,depth1-depth2-depthTolerance) * aoMultiplier) * diff;
				return ao;
			}

			float ssao(void)
			{

				float depth = readDepth( uv );
				float d;

				float pw = 1.0 / rt_w;
				float ph = 1.0 / rt_h;

				float ao = 12;
				
				float aoscale=0.4;

				for (int i = 1; i < 5; i++)
				{					
					ao += compareDepths(depth, readDepth(vec2(uv.x+pw,uv.y+ph))) / aoscale;
					ao += compareDepths(depth, readDepth(vec2(uv.x-pw,uv.y+ph))) / aoscale;
					ao += compareDepths(depth, readDepth(vec2(uv.x+pw,uv.y-ph))) / aoscale;
					ao += compareDepths(depth, readDepth(vec2(uv.x-pw,uv.y-ph))) / aoscale;
				 
					pw *= 2.0;
					ph *= 2.0;
					aoscale *= 1.2;
				}			 
			 
				ao/=16.0;
			 
				return 1-ao;
			}
			
			//
			//FOG
			//
			vec3 mix_fog(vec3 color, float depth, float fog_intensity, vec3 fog_color)
			{
				color = mix( 1 - fog_color, color, clamp(1.0 - (pow(depth, fog_intensity)), 0.0, 1.0));
				
				return color;
			}
			
				
			//
			//DEPTH POSITION
			//
			vec3 get_pos(float z)
			{
				vec4 spos = vec4(uv, z, 1.0);
				spos = (pv_matrix) * spos;
				
				return spos.xyz / spos.w;
			}
			
			void main ()
			{	
				vec3 diffuse = texture(tex_diffuse, uv).rgb;
				float depth = texture(tex_depth, uv).r;	
					
				out_color.rgb = diffuse;
				//out_color.rgb *= ssao();
				out_color.rgb *= texture(tex_light, uv).rgb;
						
				out_color.a = 1;
				
				
				/*vec3 ambient_light_color = vec3(191.0 / 255.0, 205.0 / 255.0, 214.0 / 255.0) * 0.9;
				vec3 atmosphere_color = ambient_light_color;
				vec3 fog_color = atmosphere_color;
				float fog_distance = 750.0;
				out_color.rgb = mix_fog(out_color.rgb, depth, fog_distance, 1-fog_color); //this fog is fucked up, needs to be redone
				*/
			}
		]]  
	}
} 

local EFFECTS = {
	{
		name = "fxaa",
		source = [[
			out vec4 out_color;
					
			//
			//FXAA
			//
			float FXAA_SPAN_MAX = 8.0;
			float FXAA_REDUCE_MUL = 1.0/8.0;
			float FXAA_SUBPIX_SHIFT = 1.0/128.0;

			#define FxaaInt2 ivec2
			#define FxaaFloat2 vec2
			#define FxaaTexLod0(t, p) textureLod(t, p, 0.0)
			#define FxaaTexOff(t, p, o, r) textureLodOffset(t, p, 0.0, o)
			
			vec2 rcpFrame = vec2(1.0/width, 1.0/height);
			vec4 posPos = vec4(uv, uv - (rcpFrame * (0.5 + FXAA_SUBPIX_SHIFT)));

			vec3 FxaaPixelShader(vec4 posPos, sampler2D tex)
			{   

				#define FXAA_REDUCE_MIN   (1.0/128.0)
				//#define FXAA_REDUCE_MUL   (1.0/8.0)
				//#define FXAA_SPAN_MAX     8.0
				

				vec3 rgbNW = FxaaTexLod0(tex, posPos.zw).xyz;
				vec3 rgbNE = FxaaTexOff(tex, posPos.zw, FxaaInt2(1,0), rcpFrame.xy).xyz;
				vec3 rgbSW = FxaaTexOff(tex, posPos.zw, FxaaInt2(0,1), rcpFrame.xy).xyz;
				vec3 rgbSE = FxaaTexOff(tex, posPos.zw, FxaaInt2(1,1), rcpFrame.xy).xyz;
				vec3 rgbM  = FxaaTexLod0(tex, posPos.xy).xyz;
				

				vec3 luma = vec3(0.299, 0.587, 0.114);
				float lumaNW = dot(rgbNW, luma);
				float lumaNE = dot(rgbNE, luma);
				float lumaSW = dot(rgbSW, luma);
				float lumaSE = dot(rgbSE, luma);
				float lumaM  = dot(rgbM,  luma);
				
				float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
				float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

				
				vec2 dir; 
				dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
				dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));


				float dirReduce = max(
					(lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL),
					FXAA_REDUCE_MIN);
				float rcpDirMin = 1.0/(min(abs(dir.x), abs(dir.y)) + dirReduce);
				dir = min(FxaaFloat2( FXAA_SPAN_MAX,  FXAA_SPAN_MAX), 
					  max(FxaaFloat2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX), 
					  dir * rcpDirMin)) * rcpFrame.xy;


				vec3 rgbA = (1.0/2.0) * (
					FxaaTexLod0(tex, posPos.xy + dir * (1.0/3.0 - 0.5)).xyz +
					FxaaTexLod0(tex, posPos.xy + dir * (2.0/3.0 - 0.5)).xyz);
					
				vec3 rgbB = rgbA * (1.0/2.0) + (1.0/4.0) * (
					FxaaTexLod0(tex, posPos.xy + dir * (0.0/3.0 - 0.5)).xyz +
					FxaaTexLod0(tex, posPos.xy + dir * (3.0/3.0 - 0.5)).xyz);
					
				float lumaB = dot(rgbB, luma);

				if ((lumaB < lumaMin) || (lumaB > lumaMax)) return rgbA;

				return rgbB; 
			}
			
			void main() 
			{ 
				out_color.rgb = FxaaPixelShader(posPos, tex_diffuse);
				out_color.a = 1;
			}
		]],
	},
	{
		name = "bloom",
		source = [[
			out vec4 out_color;
						
			//BLUR
			vec4 blur(sampler2D tex)
			{
				float offset = vec2(0.01, 0.01) * 0.2;
				vec3 c = vec3(0.);
				float weight = 0.;
				for(float i = 0.; i <= 2.; i += 0.2) 
				{
					c += texture(tex, uv + i * offset).rgb;
					weight += 1.;
				}
				c /= weight;
				return vec4(c, 1.);
			}
			
			//CONTRAST
			vec4 contrast(vec4 color)
			{
				vec3 col = color.rgb * 1.6;
				col *= col;
				return vec4(col, color.a);
			}
				
			void main() 
			{ 
				out_color = texture(tex_diffuse, uv); 
				out_color += contrast(blur(tex_diffuse)) * 0.05;
				out_color.a = 1;
			}
		]],
	},
	
}

render.pp_shaders = {}

function render.AddPostProcessShader(name, source, priority)
	priority = priority or #render.pp_shaders
	
	local width = render.GetWidth()
	local height = render.GetHeight()
	
	local shader = render.CreateShader({
		name = "gbuffer_post_process_" .. name,
		base = "gbuffer",
		fragment = {
			uniform = {
				tex_diffuse = "sampler2D",
				width = "float",
				height = "float",
			},
			attributes = {
				{pos = "vec2"},
				{uv = "vec2"},
			},
			source = source
		}
	})
	
	local buffer = render.CreateFrameBuffer(width, height, {
		{
			name = "diffuse",
			attach = "color",
			texture_format = {
				internal_format = "RGBA16F",
			}
		},
	})
	
	shader.pvm_matrix = render.GetPVWMatrix2D
	shader.tex_diffuse = buffer:GetTexture("diffuse")

	
	shader.width = width
	shader.height = height
		
	local quad = shader:CreateVertexBuffer({
		{pos = {0, 0}, uv = {0, 1}},
		{pos = {0, 1}, uv = {0, 0}},
		{pos = {1, 1}, uv = {1, 0}},

		{pos = {1, 1}, uv = {1, 0}},
		{pos = {1, 0}, uv = {1, 1}},
		{pos = {0, 0}, uv = {0, 1}},
	})

	for k, v in pairs(render.pp_shaders) do
		if v.name == name then
			table.remove(render.pp_shaders, k)
			break
		end
	end
	
	table.insert(render.pp_shaders, {shader = shader, quad = quad, buffer = buffer, name = name, priority = priority})
	
	table.sort(render.pp_shaders, function(a, b) return a.priority > b.priority end)
end
 
local sphere = NULL

function render.InitializeGBuffer(width, height)
	width = width or render.GetWidth()
	height = height or render.GetHeight()
	
	if width == 0 or height == 0 then return end
	
	logn("[render] initializing gbuffer: ", width, " ", height)
	
	do -- gbuffer	  
		render.gbuffer = render.CreateFrameBuffer(width, height, FRAMEBUFFERS)  
		
		if not render.gbuffer:IsValid() then
			logn("[render] failed to initialize gbuffer")
			return
		end

		local shader = render.CreateShader(GBUFFER)
		
		shader.pvm_matrix = render.GetPVWMatrix2D
		shader.pv_matrix = function() return (render.matrices.projection_3d*render.matrices.view_3d).m end
		shader.cam_pos = function()	return  render.GetCamPos() end
		shader.cam_vec = function() return render.GetCamAng():GetRad():GetForward() end
		shader.time = function() return tonumber(timer.GetSystemTime()) end
		 
		shader.tex_light = render.gbuffer:GetTexture("light")
		shader.tex_diffuse = render.gbuffer:GetTexture("diffuse")
		shader.tex_position = render.gbuffer:GetTexture("position") 
		shader.tex_normal = render.gbuffer:GetTexture("normal")
		shader.tex_depth = render.gbuffer:GetTexture("depth")
		shader.rt_w = width
		shader.rt_h = height

		local vbo = shader:CreateVertexBuffer({
			{pos = {0, 0}, uv = {0, 1}},
			{pos = {0, 1}, uv = {0, 0}},
			{pos = {1, 1}, uv = {1, 0}},

			{pos = {1, 1}, uv = {1, 0}},
			{pos = {1, 0}, uv = {1, 1}},
			{pos = {0, 0}, uv = {0, 1}},
		})
		
		render.gbuffer_shader = shader
		render.gbuffer_screen_quad = vbo
	end
	
	do -- light
		local shader = render.CreateShader(LIGHT)

		shader.pvm_matrix = render.GetPVWMatrix2D
		shader.cam_dir = function() return render.GetCamAng():GetRad():GetForward() end
		shader.cam_pos = render.GetCamPos
		 
		shader.tex_depth = render.gbuffer:GetTexture("depth")
		shader.tex_diffuse = render.gbuffer:GetTexture("diffuse")
		shader.tex_position = render.gbuffer:GetTexture("position")
		shader.tex_normal = render.gbuffer:GetTexture("normal")
		shader.screen_size = Vec2(width, height)
		
		render.gbuffer_light_shader = shader
	end
	
	do -- mesh		
		render.gbuffer_mesh_shader = render.CreateShader(MESH)
	end
			
	event.AddListener("WindowFramebufferResized", "gbuffer", function(window, w, h)
		render.InitializeGBuffer(w, h)
	end)
	
	event.AddListener("Draw2D", "gbuffer_debug", function()
		local size = 4
		local w, h = surface.GetScreenSize()
		if render.debug then
			w = w / size
			h = h / size
			
			local x = 0
			local y = 0
						
			local grey = 0.5 + math.sin(os.clock() * 10) / 10
			surface.SetFont("default")
			
			for i, data in pairs(FRAMEBUFFERS) do
				surface.SetWhiteTexture()
				surface.SetColor(grey, grey, grey, 1)
				surface.DrawRect(x, y, w, h)
				
				surface.SetColor(1,1,1,1)
				surface.SetTexture(render.gbuffer:GetTexture(data.name))
				surface.DrawRect(x, y, w, h)
				
				surface.SetTextPos(x, y + 5)
				surface.DrawText(data.name)
				
				if i%size == 0 then
					y = y + h
					x = 0
				else
					x = x + w
				end
			end
		end
	end)
	
	for i, data in pairs(EFFECTS) do
		render.AddPostProcessShader(data.name, data.source)
	end	
end

function render.ShutdownGBuffer()
	event.RemoveListener("PreDisplay", "gbuffer")
	event.RemoveListener("PostDisplay", "gbuffer")
	event.RemoveListener("WindowFramebufferResized", "gbuffer")
	
	if render.gbuffer:IsValid() then
		render.gbuffer:Remove()
	end
	
	if render.gbuffer_shader:IsValid() then
		render.gbuffer_shader:Remove()
	end
	
	if render.gbuffer_screen_quad:IsValid() then
		render.gbuffer_screen_quad:Remove()
	end
	
	logn("[render] gbuffer shutdown")
end

local size = 4

function render.DrawDeferred(w, h)

	-- geometry
	gl.DepthMask(gl.e.GL_TRUE)
	gl.Enable(gl.e.GL_DEPTH_TEST)
	gl.Disable(gl.e.GL_BLEND)	
	
	render.gbuffer:Begin()
		render.gbuffer:Clear()
		event.Call("Draw3DGeometry", render.gbuffer_mesh_shader)
	render.gbuffer:End()
	
	-- light
	gl.DepthMask(gl.e.GL_FALSE)
	gl.Disable(gl.e.GL_DEPTH_TEST)	
	gl.Enable(gl.e.GL_BLEND)
	render.SetBlendMode("additive")
	
	render.gbuffer:Begin("light")
		event.Call("Draw3DLights", render.gbuffer_light_shader)
	render.gbuffer:End() 
	
	-- gbuffer
	render.SetBlendMode("alpha")	
	render.Start2D()
		-- draw to the pp buffer		
		local effect = render.pp_shaders[1]
		
		if effect then
			
			render.PushWorldMatrix()
			surface.Scale(w, h)
			
			-- draw the gbuffer into the first effect 
			effect.buffer:Begin()
				render.gbuffer_shader:Bind()
				render.gbuffer_screen_quad:Draw()
			effect.buffer:End()
			
			for i = 2, #render.pp_shaders do 
				local next = render.pp_shaders[i]
									
				next.buffer:Begin()
					effect.shader:Bind()
					effect.quad:Draw()
				next.buffer:End()					
				
				effect = next
			end
			
			render.PopWorldMatrix()
			
			-- draw the pp texture as quad
			render.PushWorldMatrix()
				surface.Scale(w, h)
				effect.shader:Bind()
				effect.quad:Draw()
			render.PopWorldMatrix()
		else
			render.PushWorldMatrix()
				surface.Scale(w, h)
				render.gbuffer_shader:Bind()
				render.gbuffer_screen_quad:Draw()
			render.PopWorldMatrix()		
		end		
	render.End2D()
end

local gbuffer_enabled = true

function render.EnableGBuffer(b)
	gbuffer_enabled = b
	if b then 
		render.InitializeGBuffer()
	else
		render.ShutdownGBuffer()
	end
end

if render.gbuffer_shader then
	render.InitializeGBuffer()
end

event.AddListener("RenderContextInitialized", nil, function() 
	local ok, err = xpcall(render.InitializeGBuffer, system.OnError)
	
	if not ok then
		logn("[render] failed to initialize gbuffer: ", err)
		render.ShutdownGBuffer()
	end
end)
