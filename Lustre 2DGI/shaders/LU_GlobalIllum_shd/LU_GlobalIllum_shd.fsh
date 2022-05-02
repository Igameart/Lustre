//
// Simple passthrough fragment shader
//
precision mediump float;
precision mediump int;

varying vec2 UV;
varying vec4 v_vColour;

#extension GL_OES_standard_derivatives : enable

// constants
const float PI = 3.141596;
const float c_precision = 128.0;
const float c_precisionp1 = c_precision + 1.0;
const float gamma = 2.0;
const float exposure = 1.0;

// uniforms
uniform sampler2D u_scene_colour_data;
uniform sampler2D u_scene_emissive_data;
uniform sampler2D u_normal_data;
uniform sampler2D u_last_frame_data;
uniform sampler2D u_flood_data;

uniform vec2 u_resolution;
uniform float u_dist_mod;
uniform bool Iu_bounce;
uniform float u_emission_multi;
uniform float u_emission_range;
uniform float u_emission_dropoff;
uniform int Iu_max_raymarch_steps;
uniform int Iu_rays_per_pixel;

uniform vec2 SCREEN_PIXEL_SIZE;
uniform float TIME;
uniform float SKYLIGHT;


// ----------------------------------------------------------------------------
mat3 cotangent_frame( vec3 N, vec3 p, vec2 uv ) {
	
	// get edge vectors of the pixel triangle
	vec3 dp1 = dFdx( p );
	vec3 dp2 = dFdy( p );
	vec2 duv1 = dFdx( uv );
	vec2 duv2 = dFdy( uv );
	
	// solve the linear system
	vec3 dp2perp = cross( dp2, N );
	vec3 dp1perp = cross( N, dp1 );
	vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
	vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;
	
	// construct a scale-invariant frame
	float invmax = inversesqrt( max( dot(T,T), dot(B,B) ) );
	return mat3( T * invmax, B * invmax, N );
	}
// ----------------------------------------------------------------------------
vec3 perturb_normal( vec3 N, vec3 V, vec2 texcoord )
{
    // assume N, the interpolated vertex normal and 
    // V, the view vector (vertex to eye)
    vec3 map = texture2D( u_normal_data, texcoord ).xyz;
	
	//if (WITH_NORMALMAP_UNSIGNED == true){
	    //map = map * 255./127. - 128./127.;
	//}
	//if (WITH_NORMALMAP_2CHANNEL == true){
	//    map.z = sqrt( 1. - dot( map.xy, map.xy ) );
	//}
	//if (WITH_NORMALMAP_FLIP_RED == true){
	//    map.x = -map.x;
	//}
	//if (WITH_NORMALMAP_FLIP_GREEN == true){
	//    map.y = -map.y;
	//}
	
    mat3 TBN = cotangent_frame( N, -V, texcoord );
    return normalize( TBN * map );
}


float DecodeFloatRGBA( in vec4 col )
{
	vec3 pack = col.rgb;
  float depth = dot( pack, 1.0 / vec3(1.0, 256.0, 256.0*256.0) );
  return depth * (256.0*256.0*256.0) / (256.0*256.0*256.0 - 1.0);
}

/*
 * \param color normalized RGB value
 * \returns 3-component encoded float
 */
float color2float(vec3 color){
	color = clamp(color, 0.0, 1.0);
	return floor(color.r * c_precision + 0.5)
		+ floor(color.b * c_precision + 0.5) * c_precisionp1
		+ floor(color.g * c_precision + 0.5) * c_precisionp1 * c_precisionp1;
}


float GetEmission( vec2 uv ){
	return color2float( texture2D(u_scene_emissive_data, uv).rgb);//, 0.0, 100.0 );
}

vec3 lin_to_srgb(vec4 color)
{
   vec3 x = color.rgb * 12.92;
   vec3 y = 1.055 * pow(color.rgb, vec3(0.4166667)) - 0.055;
   vec3 clr = color.rgb;
   clr.r = (color.r < 0.0031308) ? x.r : y.r;
   clr.g = (color.g < 0.0031308) ? x.g : y.g;
   clr.b = (color.b < 0.0031308) ? x.b : y.b;
   return clr.rgb;
}

vec3 linearToneMapping(vec3 color)
{
	//float exposure = 1.;
	color = clamp(exposure * color, 0., 1.);
	color = pow(color, vec3(1. / gamma));
	return color;
}

vec3 simpleReinhardToneMapping(vec3 color)
{
	//float exposure = 1.5;
	color *= exposure/(1. + color / exposure);
	color = pow(color, vec3(1. / gamma));
	return color;
}

vec3 lumaBasedReinhardToneMapping(vec3 color)
{
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float toneMappedLuma = luma / (1. + luma);
	color *= toneMappedLuma / luma;
	color = pow(color, vec3(1. / gamma));
	return color;
}

vec3 whitePreservingLumaBasedReinhardToneMapping(vec3 color)
{
	float white = 2.;
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float toneMappedLuma = luma * (1. + luma / (white*white)) / (1. + luma);
	color *= toneMappedLuma / luma;
	color = pow(color, vec3(1. / gamma));
	return color;
}

vec3 RomBinDaHouseToneMapping(vec3 color)
{
    color = exp( -1.0 / ( 2.72*color + 0.15 ) );
	color = pow(color, vec3(1. / gamma));
	return color;
}

vec3 filmicToneMapping(vec3 color)
{
	color = max(vec3(0.), color - vec3(0.004));
	color = (color * (6.2 * color + .5)) / (color * (6.2 * color + 1.7) + 0.06);
	return color;
}

vec3 Uncharted2ToneMapping(vec3 color)
{
	float A = 0.15;
	float B = 0.50;
	float C = 0.10;
	float D = 0.20;
	float E = 0.02;
	float F = 0.30;
	float W = 11.2;
	//float exposure = 2.;
	color *= exposure;
	color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
	float white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
	color /= white;
	color = pow(color, vec3(1. / gamma));
	return color;
}

// ================================================================================
// return half a pixel size in UV space - used for some distance calculations to 
// determine if we're at a surface.
float epsilon()
{
	return 0.45 * max(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y);
}

// ================================================================================
// return the surface data at a given location. 'uv' contains the hit location, while
// hit_data contains the distance data at that location which we already sampled from 
// the map() func.
void get_material(vec2 uv, float hit_data, out float emissive, out vec3 colour)
{	
	// if distance to nearest surface at this location is < epsilon (half pixel), we can
	// consider to be hitting that surface.
	if(hit_data / u_dist_mod < epsilon())
	{
		// convert uvs back to 0-1 range.
		float inv_aspect = u_resolution.y / u_resolution.x;
		uv.x *= inv_aspect;
		
		// read the surface data from emissive/colour maps. 
		// TODO: could probably be optimised by combining into one texture sample.
		
		float emissive_data = GetEmission( uv);
		vec4 colour_data = texture2D(u_scene_colour_data, uv);
		
		emissive = ((emissive_data)) * u_emission_multi;
		colour = colour_data.rgb;
	}
	
	// otherwise the raymarch reached max steps before finding a surface, so nothing is
	// contributed to the pixel brightness/colour.
	else
	{
		emissive = 0.0;
		colour = vec3(0.0);
	}
}

// ================================================================================
// get distance data (to nearest surface) from given UV location.
float map(vec2 uv, bool am_in, out float hit_data, out bool inside, out float inner_emis)
{
	float inv_aspect = u_resolution.y / u_resolution.x;
	uv.x *= inv_aspect;
	hit_data = DecodeFloatRGBA(texture2D(gm_BaseTexture, uv));
	
	
	inside = am_in;
	
	if (inside == true){
		vec4 flood = texture2D(u_flood_data, uv);
		inside = bool( flood.b );
	}
	
	inner_emis = GetEmission( uv);
	
	float d = hit_data / u_dist_mod;// * float(inside);
    return d;
}

// ================================================================================
// get distance data (to nearest surface) from given UV location.
float map2(vec2 uv, bool am_in, out float hit_data, out bool inside, out float inner_emis, out bool point_inside )
{
	float inv_aspect = u_resolution.y / u_resolution.x;
	uv.x *= inv_aspect;
	hit_data = DecodeFloatRGBA(texture2D(gm_BaseTexture, uv));
	
	float d = hit_data / u_dist_mod;// * float(inside);
	
	point_inside = bool( texture2D(u_flood_data, uv).b );
	
	inside = am_in;
	
	if (inside == true){
		inside = point_inside;
	}
	
	inner_emis = GetEmission( uv);
    return d;
}

// ================================================================================
// march a ray from a pixel in a given direction, until it hits a surface or runs out of
// steps. will return if a surface is hit, the hit location, hit data, and total length
// of the ray.

bool raymarch(vec2 origin, vec2 ray, out vec2 hit_pos, out float hit_data, out float ray_dist, out float inner_accum )
{
	float t = 0.0;
	float prev_dist = 1.0;
	float step_dist = 1.0;
	bool inside = true;
	vec2 sample_point;
	inner_accum = -0.20;
	float inner_emis;
	
	bool am_inside = inside;
	bool point_inside = false;
	
	for(int i = 0; i < Iu_max_raymarch_steps; i++)
	{
		sample_point = origin + ray * t;
		am_inside = inside;
		step_dist = map2(sample_point, inside, hit_data, inside, inner_emis, point_inside );
		
		// consider a hit if distance to surface is < epsilon (half pixel).
		if (am_inside == false){
			//if(step_dist < epsilon())
			if(point_inside == true )
			{
				hit_pos = sample_point;
	  			return true;
			}
		}
		
		// if we didn't find a hit, step forward by the distance found in distance texture (min 1px).
		// since this distance is the distance to nearest surface, it guarantees we won't 'overstep'
		// and go past a surface. worst case is we are parallel and close to the surface, so we can't step
		// far but also won't reach the surface. this is where we have to make a trade-off in u_max_raymarch_steps.
		step_dist = max(step_dist, min(1.0 / u_resolution.x, 1.0 / u_resolution.y));
		
		if (am_inside == true){
			
			inner_accum += (step_dist*6.0);
			
		}
		
		t += step_dist;
		ray_dist = t;
	}
	return false;
}

float czm_luminance(vec3 rgb)
{
    // Algorithm from Chapter 10 of Graphics Shaders.
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    return dot(rgb, W);
}

// ================================================================================
// get emission/colour data at this location from the last frame. this allows 'infinite'
// bounces as sufaces that were lit in the last frame will now act as emissive surfaces.
// we need to sample a 3x3 grid around the hit pixel because the surface itself won't have
// emissive data (since it is rendered black, generally), sampling around it will find the
// closest emissive pixel though, which we can consider the surface's value.
void get_last_frame_data(vec2 uv, vec2 pix, vec3 mat_colour, out float last_emission, out vec3 last_colour)
{
	//last_emission = 0.0;
	
	int offset = 1;
	
	for(int x = -offset; x <= offset; x++)
	{
		for(int y = -offset; y <= offset; y++)
		{
			vec3 pixel = texture2D(u_last_frame_data, uv + pix * vec2(float(x), float(y))).rgb;
			if(czm_luminance(pixel) > last_emission)
			{
				last_emission = czm_luminance(pixel);
				last_colour = pixel * mat_colour;
			}
			if (y > offset) {
			    break;
			}
		}
		if (x > offset) {
			break;
		}
	}
}

float random (vec2 st) 
{
   return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float mapf(float value, float inMin, float inMax, float outMin, float outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

vec2 map2(vec2 value, vec2 inMin, vec2 inMax, vec2 outMin, vec2 outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

vec3 map3(vec3 value, vec3 inMin, vec3 inMax, vec3 outMin, vec3 outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

vec4 map4(vec4 value, vec4 inMin, vec4 inMax, vec4 outMin, vec4 outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

// ================================================================================
// do the thing!
void main() 
{
	// since UVs are in 0-1 space, and our viewport could be non-square, we need to convert
	// UVs so our rays aren't skewed. i.e. if we're 1024x512 viewport, this will convert 0-1
	// x/y to 0-2 on x and 0-1 on y.
	// we will need to convert back when doing texture samples, which need 0-1 UV space.
	vec2 uv = UV;
	float aspect = u_resolution.x / u_resolution.y;
	float inv_aspect = u_resolution.y / u_resolution.x;
	uv.x *= aspect;
		
	vec3 col = vec3(0.0);
	float emis = 0.0;//texture2D(u_scene_emissive_data,uv).r * u_emission_multi;
	
	// get a random angle by sampling the noise texture and offsetting it by time (so we don't always sample
	// the same noise).
	//vec2 time = vec2(TIME, -TIME);
	//float rand02pi = texture2D(u_noise_data, fract((uv + time) * 0.4)).r * 2.0 * PI; // noise sample
	
	float ohit_data;
	bool origin_inside;
	float inner_glow;
	
	float inner_depth = map(uv, true, ohit_data, origin_inside, inner_glow );
	
	vec3 fakeNorm = vec3(0.5,0.5,1.0);
	vec3 fakeEye = vec3(0.0,0.0,0.0);
	
	vec4 pdata = texture2D(u_normal_data,UV);
	
	//vec3 N = normalize(fakeNorm);
    //vec3 V = normalize(fakeEye);
    //vec3 R = reflect(-V, N); 
	
	////N = perturb_normal( N, V, v_vTexcoord );
	
	vec3 normals = pdata.rgb;//perturb_normal(N,V,UV);
	normals.b = (1.0 - normals.b)*1.5;
	normals = normalize(normals * 2.0 - 1.0);
	
	float rand02pi = random(UV * vec2(TIME, -TIME)) * 2.0 * PI;
	float golden_angle = PI * 0.7639320225;
	
	vec4 scene = texture2D(u_scene_colour_data,UV);
	
	for(float i = 0.0; i < float(Iu_rays_per_pixel); i++)
	{
		vec2 hit_pos;
		float hit_data;
		float ray_dist;
		float inside = 0.0;
		
		// get our ray dir by taking the random angle and adding golden_angle * ray number.
		float cur_angle = rand02pi + golden_angle * i;
		vec2 rand_direction = vec2(cos(cur_angle), sin(cur_angle));
		bool hit = raymarch(uv, rand_direction, hit_pos, hit_data, ray_dist, inside);
		
		vec3 lDir = vec3(rand_direction.xy,0.25);
		
		float nMul = max( dot(normals, lDir), 0.0);
		
		if (scene.a == 0.0){
			nMul = 1.0;
		}
		
		if(hit)
		{
			float mat_emissive;
			vec3 mat_colour;
			get_material(hit_pos, hit_data, mat_emissive, mat_colour);
			
			// convert UVs back to 0-1 space.
			vec2 st = hit_pos;
			st.x *= inv_aspect;
			
			float last_emission = 0.0;
			vec3 last_colour = vec3(0.0);
			
			if(Iu_bounce)
			{
				// we don't want emissive surfaces themselves to bounce light (we could, but it would probably blow
				// out the scene).
				
				if(mat_emissive < epsilon())
				{
					get_last_frame_data(st, SCREEN_PIXEL_SIZE, mat_colour, last_emission, last_colour);
				}
			}
			
			// calculate total emissive/colour values from direct and bounced (last frame) lighting.
			float emission = mat_emissive + last_emission * 0.52;
			float r = u_emission_range;
			float drop = u_emission_dropoff;
			
			// attenuation calculation - very tweakable to get the correct sort of light range/dropoff.
			float att = pow(max(1.0 - (ray_dist * ray_dist) / (r * r), 0.0), u_emission_dropoff);
			
			att = max(att,0.0);
			
			emis += emission * att * nMul;
			col += (emission ) * (mat_colour + last_colour) * att * nMul;
		}
	}
	
	// right now, emis and col store the sum of contribution of all rays to this pixel, we need
	// to normalise it.
	//emis *= (1.0 / (float(Iu_rays_per_pixel)* u_emission_multi )) ;
	col *= (1.0 / float(Iu_rays_per_pixel));
	
	if (inner_glow > 0.0){
		float r = u_emission_range;
		float sim_dist = 0.0 * inner_glow;
		float att = pow(max(1.0 - (sim_dist * sim_dist) / (r * r), 0.0), 1.0) * 0.1250;
		
		//emis += inner_glow * att * u_emission_multi;
		col += inner_glow * u_emission_multi * scene.rgb * att;
	}
	
	//float alp = max(scene.a,5.0/255.0);
	
	if (scene.a == 0.0){
		col.rgb *= SKYLIGHT;
	}
	
	gl_FragColor = vec4(col, 1.0) * scene;
	
	gl_FragColor = clamp(gl_FragColor,0.0,1.0);
	
	gl_FragColor.rgb = linearToneMapping(gl_FragColor.rgb);
	
	gl_FragColor.a = 1.0;
	
	//gl_FragColor = pdata;
	
	
}
