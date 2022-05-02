//
// Simple passthrough vertex shader
//
attribute vec3 in_Position;                  // (x,y,z)
//attribute vec3 in_Normal;                    // (x,y,z)     unused in this shader.
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 UV;
varying vec4 v_vColour;
//varying vec3 v_vTangent;
//varying vec3 Normal;

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    //vec4 object_space_nrm = vec4( in_Normal.x, in_Normal.y, in_Normal.z, 0.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
	
	//Normal=vec4(gm_Matrices[MATRIX_WORLD] * object_space_nrm).xyz;
	
	//// calculate tangent
    ////(So far this is what has given me the best result
    //// however it seems to be kind of inside out)
    //vec3 tangent;
    
    //vec3 c1 = cross( in_Normal, vec3( 0.0, 1.0, 0.0 ) );
    //vec3 c2 = cross( in_Normal, vec3( 0.0, 0.0, 1.0 ) );
    
    //if ( length( c1 ) > length( c2 ) )
    //    { tangent = c1; }
    //else
    //    { tangent = c2; }
        
    //normalize( tangent );
    
    //v_vTangent = tangent;
    
    v_vColour = in_Colour;
    UV = in_TextureCoord;
}
