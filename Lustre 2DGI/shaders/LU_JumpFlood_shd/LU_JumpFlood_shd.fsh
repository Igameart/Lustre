//
// Simple passthrough fragment shader
//
varying vec2 v_vTexCoord;

uniform float u_offset; 
uniform float u_level;
uniform float u_max_steps;
//uniform float u_emission;

uniform vec2 SCREEN_PIXEL_SIZE;

void main()
{
	float closest_dist = 9999999.9;
	vec2 closest_pos = vec2(0.0);
	float inside = texture2D(gm_BaseTexture, v_vTexCoord).b;

	// insert jump flooding algorithm here.
	for(float x = -1.0; x <= 1.0; x += 1.0)
	{
		for(float y = -1.0; y <= 1.0; y += 1.0)
		{
			vec2 voffset = v_vTexCoord;
			voffset += vec2(x, y) * SCREEN_PIXEL_SIZE * u_offset;

			vec2 pos = texture2D(gm_BaseTexture, voffset).xy;
			float dist = distance(pos.xy, v_vTexCoord.xy);

			if(pos.x != 0.0 && pos.y != 0.0 && dist < closest_dist)
			{
				closest_dist = dist;
				closest_pos = pos;
			}
		}
	}
	
    gl_FragColor = vec4(closest_pos, inside, 1.0);
}
