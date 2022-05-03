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
	    
    v_vColour = in_Colour;
    UV = in_TextureCoord;
}
