local render = ... or _G.render

render.AddGlobalShaderCode([[
float sky_atmospheric_depth(vec3 position, vec3 dir, float depth)
{
	float a = dot(dir, dir);
	float b = 2.0*dot(dir, position);
	float c = dot(position, position)-1.0;
	float det = b*b-4.0*a*c;
	float detSqrt = sqrt(det);
	float q = (-b - detSqrt)/2.0;
	float t1 = c/q;
	return t1 * pow(depth, 2.5) / 7;
}

float sky_phase(float alpha, float g)
{
	float a = 3.0*(1.0-g*g);
	float b = 2.0*(2.0+g*g);
	float c = 1.0+alpha*alpha;
	float d = pow(1.0+g*g-2.0*g*alpha, 1.5);
	d = max(d, 0.00001);
	return (a/b)*(c/d);
}

float sky_horizon_extinction(vec3 position, vec3 dir, float radius)
{
	float u = dot(dir, -position);
	if(u<0.0)
	{
		return 1.0;
	}
	vec3 near = position + u*dir;
	if(length(near) < radius)
	{
		return 0.0;
	}
	else if (length(near) >= radius)
	{
		vec3 v2 = normalize(near)*radius - position;
		float diff = acos(dot(normalize(v2), dir));
		return smoothstep(0.0, 1.0, pow(diff*2.0, 3.0));
	}
	else
		return 1.0;
}

vec3 sky_absorb(vec3 sky_color, float dist, vec3 color, float factor)
{
	return color-color*pow(sky_color, vec3(factor/dist));
}

vec3 get_sky(vec2 uv, vec3 sun_direction, float depth)
{
	float intensity = lua[world_sky_intensity = 10];
	vec3 sky_color = lua[world_sky_color = Vec3(0.18867780436772762, 0.4978442963618773, 0.6616065586417131)];

	const float surface_height = 0.95;
	const int step_count = 8;


	const float rayleigh_brightness = 2;
	const float mie_brightness = 0.99;
	const float spot_brightness = 1;
	const float scatter_strength = 0.1;
	const float rayleigh_strength = 0.839;
	const float mie_strength = 0.964;
	const float rayleigh_collection_power = 0.65;
	const float mie_collection_power = 0.8;
	const float mie_distribution = 0.26;

	vec2 frag_coord = uv;
	frag_coord = (frag_coord-0.5)*2.0;
	vec4 device_normal = vec4(frag_coord, 0.0, 1.0);
	vec3 eye_normal = normalize((g_projection_inverse * device_normal).xyz);
	vec3 world_normal = normalize(mat3(g_view_inverse)*eye_normal).xyz;
	vec3 ray = vec3(world_normal.x, -world_normal.z, world_normal.y);

	vec3 ldir = sun_direction;
	float alpha = dot(ray, ldir);

	float rayleigh_factor = sky_phase(alpha, -0.01) * rayleigh_brightness * ldir.y;
	float mie_factor = sky_phase(alpha - 0.5, mie_distribution) * mie_brightness * (1.0 - ldir.y);

	float sky_mult = pow(depth, 100);
	float spot = smoothstep(0.0, 100.0, sky_phase(alpha, 0.9995)) * spot_brightness * sky_mult;
	float stars = pow(get_noise((ray.xz+sun_direction.xy)/2).x, 15) * 0.25 * sky_mult;

	vec3 eye_position = min(vec3(0,surface_height,0) + (vec3(-g_cam_pos.x, g_cam_pos.z, g_cam_pos.y) / 100010000), vec3(0.999999));
	float eye_depth = sky_atmospheric_depth(eye_position, ray, depth);
	float step_length = eye_depth/float(step_count);

	vec3 rayleigh_collected = vec3(0.0, 0.0, 0.0);
	vec3 mie_collected = vec3(0.0, 0.0, 0.0);

	for(int i=0; i < step_count; i++)
	{
		float sample_distance = step_length * float(i);

		vec3 position = eye_position + ray * sample_distance;
		float extinction = sky_horizon_extinction(position, ldir, surface_height - 0.2);
		float sample_depth = sky_atmospheric_depth(position, ray, depth);
		vec3 influx = sky_absorb(sky_color, sample_depth, vec3(intensity), scatter_strength) * extinction;
		rayleigh_collected += sky_absorb(sky_color, sqrt(sample_distance), sky_color * influx, rayleigh_strength);

		mie_collected += sky_absorb(sky_color, sample_distance, influx, mie_strength);
	}

	rayleigh_collected = rayleigh_collected * pow(eye_depth, rayleigh_collection_power) / float(step_count);
	mie_collected = (mie_collected * pow(eye_depth, mie_collection_power)) / float(step_count);
	return stars + vec3(spot) + clamp(vec3(spot * mie_collected + mie_factor * mie_collected + rayleigh_factor * rayleigh_collected), vec3(0), vec3(1));
}]], "get_sky")

local directions = {
	QuatDeg3(0,-90,-90), -- back
	QuatDeg3(0,90,90), -- front

	QuatDeg3(0,0,0), -- up
	QuatDeg3(180,0,0), -- down

	QuatDeg3(90,0,0), -- left
	QuatDeg3(-90,180,0), -- right
}

local fb
local tex
local shader

local function init()
	tex = render.CreateTexture("cube_map")
	tex:SetInternalFormat("rgb16f")
	tex:SetMipMapLevels(1)
	tex:LoadCubemap("textures/skybox/bluesky.png")

	shader = render.CreateShader({
		name = "sky",
		fragment = {
			variables = {
				sun_direction = {vec3 = function()
					if SUN and SUN:IsValid() then
						local dir = SUN:GetTRPosition():GetNormalized()

						return Vec3(-dir.y, dir.z, -dir.x)
					end

					return Vec3()
				end},
			},
			mesh_layout = {
				{pos = "vec3"},
				{uv = "vec2"},
			},
			source = [[
				out vec3 out_color;

				void main()
				{
					out_color = get_sky(uv, sun_direction, get_depth(uv));
				}
			]]
		}
	})

	fb = render.CreateFrameBuffer()
	fb:SetTexture(1, tex, "write", nil, 1)
	fb:CheckCompletness()
	fb:WriteThese(1)
end

function render.UpdateSky()
	if not tex then init() end

	render.EnableDepth(false)
	render.SetBlendMode()

	render.SetShaderOverride(shader)
	local old_view = render.camera_3d:GetView()
	local old_projection = render.camera_3d:GetProjection()

	local projection = Matrix44()
	projection:Perspective(math.rad(90), render.camera_3d.FarZ, render.camera_3d.NearZ, tex.w / tex.h)

	fb:Begin()
		for i, rot in ipairs(directions) do
			fb:SetTexture(1, tex, nil, nil, i)
			fb:Clear()

			local view = Matrix44()
			view:SetRotation(rot)
			render.camera_3d:SetView(view)
			render.camera_3d:SetProjection(projection)

			surface.DrawRect(0,0,surface.GetSize())
		end
	fb:End()

	render.camera_3d:SetView(old_view)
	render.camera_3d:SetProjection(old_projection)

	render.SetShaderOverride()
end

function render.GetSkyTexture()
	if not tex then init() end
	return tex
end

if RELOAD then
	init()
end