//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform sampler2D u_WorldTex;

vec3 lin_to_srgb(vec4 color)
{
    vec3 x = color.rgb * 12.92;
    vec3 y = 1.055 * pow(clamp(color.rgb, 0.0, 1.0), vec3(0.4166667)) - 0.055;
    vec3 clr = color.rgb;
    clr.r = (color.r < 0.0031308) ? x.r : y.r;
    clr.g = (color.g < 0.0031308) ? x.g : y.g;
    clr.b = (color.b < 0.0031308) ? x.b : y.b;
	return clr.rgb;
}

void main()
{
    gl_FragColor = v_vColour * texture2D( gm_BaseTexture, v_vTexcoord );
    //vec4 bg = texture2D( u_WorldTex, v_vTexcoord );
	gl_FragColor = vec4(lin_to_srgb(gl_FragColor), 1.0);
	gl_FragColor.a = 1.0;
}
