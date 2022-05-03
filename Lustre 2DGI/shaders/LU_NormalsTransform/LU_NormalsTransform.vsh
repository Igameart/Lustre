//
// Simple passthrough vertex shader
//
attribute vec3 in_Position;                  // (x,y,z)
//attribute vec3 in_Normal;                  // (x,y,z)     unused in this shader.
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec3 v_vTangent;
varying vec3 v_vWPos;

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    v_vWPos = vec4(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos).xyz;
	
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
	
	vec3 in_Normal = vec3(0.0,0.0,1.0);
    
	// calculate tangent
    //(So far this is what has given me the best result
    // however it seems to be kind of inside out)
    vec3 tangent;
    
    vec3 c1 = cross( in_Normal, vec3( 0.0, 1.0, 0.0 ) );
    vec3 c2 = cross( in_Normal, vec3( 0.0, 0.0, 1.0 ) );
    
    if ( length( c1 ) > length( c2 ) )
        { tangent = c1; }
    else
        { tangent = c2; }
        
    v_vTangent = normalize( tangent );
	
	//v_vTangent = vec4(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(v_vTangent,1.0)).xyz;
	
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
}
