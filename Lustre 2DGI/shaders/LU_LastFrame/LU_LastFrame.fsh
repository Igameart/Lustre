//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;

void main()
{
	vec4 sample = texture2D(gm_BaseTexture, v_vTexcoord);
    gl_FragColor = min(vec4(1.0), sample);
}
