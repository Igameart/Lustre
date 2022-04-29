//
// Simple passthrough fragment shader
//
precision mediump float;
precision mediump int;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_emission;
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

void main()
{
	gl_FragColor = v_vColour * texture2D( gm_BaseTexture, v_vTexcoord );
    gl_FragColor.rgb = PackDepth24( gl_FragColor.r * u_emission, 0.0, 100.0 );
	
    //gl_FragColor.rgb = vec3(UnpackDepth24( gl_FragColor.rgb, 0.0, u_emission ));
	
}
