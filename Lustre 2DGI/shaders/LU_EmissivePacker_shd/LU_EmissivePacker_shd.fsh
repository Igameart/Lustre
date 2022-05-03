//
// Simple passthrough fragment shader
//
precision mediump float;
precision mediump int;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_emission;
uniform bool u_is_passable;


const float c_precision = 128.0;
const float c_precisionp1 = c_precision + 1.0;

#define SCALE_FACTOR (256.0 * 256.0 * 256.0 - 1.0)

vec3 PackDepth24(float v, float min, float max) {
   float zeroToOne = (v - min) / (max - min);
   float zeroTo24Bit = zeroToOne * SCALE_FACTOR;
   return floor(
        vec3(
            mod(zeroTo24Bit, 256.0),
            mod(zeroTo24Bit / 256.0, 256.0),
            zeroTo24Bit / 256.0 / 256.0
        )
    ) / 255.0;
}

float UnpackDepth24(vec3 v, float min, float max) {
   vec3 scaleVector = vec3(1.0, 256.0, 256.0 * 256.0) / SCALE_FACTOR * 255.0;
   float zeroToOne = dot(v, scaleVector);
   return zeroToOne * (max - min) + min;
}

/*
 * \param value 3-component encoded float
 * \returns normalized RGB value
 */
vec3 float2color(float value) {
	vec3 color;
	color.r = mod(value, c_precisionp1) / c_precision;
	color.b = mod(floor(value / c_precisionp1), c_precisionp1) / c_precision;
	color.g = floor(value / (c_precisionp1 * c_precisionp1)) / c_precision;
	return color;
}

void main()
{
	gl_FragColor = v_vColour * texture2D( gm_BaseTexture, v_vTexcoord );
    gl_FragColor.rgb = float2color( gl_FragColor.r * u_emission );//, 0.0, 100.0 );
	
	gl_FragColor.a *= float(u_is_passable);
	
}
