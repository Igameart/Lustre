//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;


uniform vec2 SCREEN_PIXEL_SIZE;

bool is_edge()
{
	vec2 div = 1.0/SCREEN_PIXEL_SIZE;
	float sample = 0.0;
	
	sample += texture2D( gm_BaseTexture, v_vTexcoord + vec2(0.0,div.y) ).a;
	sample += texture2D( gm_BaseTexture, v_vTexcoord + vec2(0.0,-div.y) ).a;
	sample += texture2D( gm_BaseTexture, v_vTexcoord + vec2(-div.x,0.0) ).a;
	sample += texture2D( gm_BaseTexture, v_vTexcoord + vec2(div.x,0.0) ).a;
	
	sample += texture2D( gm_BaseTexture, v_vTexcoord + vec2(-div.x,div.y) ).a;
	sample += texture2D( gm_BaseTexture, v_vTexcoord + vec2(-div.x,-div.y) ).a;
	sample += texture2D( gm_BaseTexture, v_vTexcoord + vec2(div.x,div.y) ).a;
	sample += texture2D( gm_BaseTexture, v_vTexcoord + vec2(div.x,-div.y) ).a;
	
	if (sample < 8.0){
		return true;
	}
	return false;
}

void main()
{
    vec4 sceneCol = texture2D( gm_BaseTexture, v_vTexcoord );
	gl_FragColor = vec4(v_vTexcoord.x * float(is_edge()) * sceneCol.a,v_vTexcoord.y * float(is_edge()) * sceneCol.a, sceneCol.a, 1.0);
}
