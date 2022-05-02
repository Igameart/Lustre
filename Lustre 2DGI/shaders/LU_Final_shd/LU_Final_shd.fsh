//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform sampler2D u_alpha;

uniform bool render_type;

void main()
{
    gl_FragColor = texture2D( gm_BaseTexture, v_vTexcoord );
	float alpha = texture2D( u_alpha, v_vTexcoord ).a;
	
	if (render_type == true){
		gl_FragColor.a = alpha;
	}else{
		gl_FragColor.a = 1.0 - alpha;
	}
	gl_FragColor *= v_vColour;
}
