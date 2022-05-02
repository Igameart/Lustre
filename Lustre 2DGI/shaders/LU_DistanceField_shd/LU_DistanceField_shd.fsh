//
// Simple passthrough fragment shader
//
precision highp float;
precision highp int;
varying vec2 v_vTexcoord;
uniform float u_dist_mod;

const vec4 bitSh = vec4(256. * 256. * 256., 256. * 256., 256., 1.);
const vec4 bitMsk = vec4(0.,vec3(1./256.0));
const vec4 bitShifts = vec4(1.) / bitSh;

float UnpackDepth24( in vec3 pack )
{
  float depth = dot( pack, 1.0 / vec3(1.0, 256.0, 256.0*256.0) );
  return depth * (256.0*256.0*256.0) / (256.0*256.0*256.0 - 1.0);
}

vec3 PackDepth24( in float depth )
{
    float depthVal = depth * (256.0*256.0*256.0 - 1.0) / (256.0*256.0*256.0);
    vec4 encode = fract( depthVal * vec4(1.0, 256.0, 256.0*256.0, 256.0*256.0*256.0) );
    return encode.xyz - encode.yzw / 256.0 + 1.0/512.0;
}

vec4 PackDepth32( in float depth )
{
    depth *= (256.0*256.0*256.0 - 1.0) / (256.0*256.0*256.0);
    vec4 encode = fract( depth * vec4(1.0, 256.0, 256.0*256.0, 256.0*256.0*256.0) );
    return vec4( encode.xyz - encode.yzw / 256.0, encode.w ) + 1.0/512.0;
}

float UnpackDepth32( in vec4 pack )
{
    float depth = dot( pack, 1.0 / vec4(1.0, 256.0, 256.0*256.0, 256.0*256.0*256.0) );
    return depth * (256.0*256.0*256.0) / (256.0*256.0*256.0 - 1.0);
}

void main()
{
	// input is the voronoi output which stores in each pixel the UVs of the closest surface.
	// here we simply take that value, calculate the distance between the closest surface and this
	// pixel, and return that distance. 
	vec4 tex = texture2D(gm_BaseTexture, v_vTexcoord);
	float dist = distance(tex.xy, v_vTexcoord);
	float mapped = clamp(dist * u_dist_mod, 0.0, 1.0);
    gl_FragColor = vec4(vec3(PackDepth24(mapped)),1.0);
}
