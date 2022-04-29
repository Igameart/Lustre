//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 size;
const float u_sigma = 2.0;
const int u_width = 4;

float CalcGauss( float x, float sigma ) 
{
  float coeff = 1.0 / (2.0 * 3.14157 * sigma);
  float expon = -(x*x) / (2.0 * sigma);
  return (coeff*exp(expon));
}

float czm_luminance(vec3 rgb)
{
    // Algorithm from Chapter 10 of Graphics Shaders.
    //const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    //return dot(rgb, W);
	return (rgb.r * 0.3) + (rgb.g * 0.59) + (rgb.b * 0.11);
}

void main()
{
    vec2 texC = v_vTexcoord;
    vec4 texCol = texture2D( gm_BaseTexture, texC );
    vec4 gaussCol = vec4( texCol.rgb, 1.0 );
    vec2 step = 1.0 / size;
	if (czm_luminance(texCol.rgb)>=0.9){
	    for ( int i = 1; i <= u_width; ++ i )
	    {
	        //vec2 actStep = vec2( float(i) * step.x, 0.0 );   // this is for the X-axis
	         vec2 actStep = vec2( 0.0, float(i) * step.y );   //this would be for the Y-axis

	        float weight = CalcGauss( float(i) / float(u_width), u_sigma );
	        texCol = texture2D( gm_BaseTexture, texC + actStep );    
	        gaussCol += vec4( texCol.rgb * weight, weight );
	        texCol = texture2D( gm_BaseTexture, texC - actStep );
	        gaussCol += vec4( texCol.rgb * weight, weight );
	    }
	}
    gaussCol.rgb /= gaussCol.w;
    gl_FragColor = vec4( gaussCol.rgb, 1.0 );
}
