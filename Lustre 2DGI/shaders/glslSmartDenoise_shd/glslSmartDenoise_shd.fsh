//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//  Copyright (c) 2018-2019 Michele Morrone
//  All rights reserved.
//
//  https://michelemorrone.eu - https://BrutPitt.com
//
//  me@michelemorrone.eu - brutpitt@gmail.com
//  twitter: @BrutPitt - github: BrutPitt
//  
//  https://github.com/BrutPitt/glslSmartDeNoise/
//
//  This software is distributed under the terms of the BSD 2-Clause license
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#define INV_SQRT_OF_2PI 0.39894228040143267793994605993439  // 1.0/SQRT_OF_2PI
#define INV_PI 0.31830988618379067153776752674503

uniform vec2 u_texture_size;
uniform sampler2D u_Albeo;
uniform sampler2D u_Normal;

//  smartDeNoise - parameters
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  sampler2D tex     - sampler image / texture
//  vec2 uv           - actual fragment coord
//  float sigma  >  0 - sigma Standard Deviation
//  float kSigma >= 0 - sigma coefficient 
//      kSigma * sigma  -->  radius of the circular kernel
//  float threshold   - edge sharpening threshold 


vec4 smartDeNoise(sampler2D tex, sampler2D albedo, sampler2D normal, vec2 uv, float sigma, float kSigma, float threshold)
{
    float radius = floor(kSigma*sigma+0.5);
    float radQ = radius * radius;

    float invSigmaQx2 = .5 / (sigma * sigma);      // 1.0 / (sigma^2 * 2.0)
    float invSigmaQx2PI = INV_PI * invSigmaQx2;    // 1/(2 * PI * sigma^2)

    float invThresholdSqx2 = .5 / (threshold * threshold);     // 1.0 / (sigma^2 * 2.0)
    float invThresholdSqrt2PI = INV_SQRT_OF_2PI / threshold;   // 1.0 / (sqrt(2*PI) * sigma^2)

    vec4 centrPx = texture2D(normal,uv); 
    //centrPx +=  texture2D(albedo,uv);
	centrPx +=  texture2D(tex,uv) * 0.25;
	//centrPx *= 0.333;

    float zBuff = 0.0;
    vec4 aBuff = vec4(0.0);
    vec2 size = u_texture_size;//vec2(textureSize(tex, 0));

    vec2 d;
    for (d.x=-radius; d.x <= radius; d.x++) {
        float pt = sqrt(radQ-d.x*d.x);       // pt = yRadius: have circular trend
        for (d.y=-pt; d.y <= pt; d.y++) {
            float blurFactor = exp( -dot(d , d) * invSigmaQx2 ) * invSigmaQx2PI;

            vec4 walkPx =  texture2D(normal,uv+d/size);
            //walkPx +=  texture2D(albedo,uv+d/size);
            vec4 colPx =  texture2D(tex,uv+d/size);
			walkPx += colPx * 0.25;
			//walkPx *= 0.333;
			
            vec4 dC = walkPx-centrPx;
			
            float deltaFactor = exp( -dot(dC, dC) * invThresholdSqx2) * invThresholdSqrt2PI * blurFactor;

            zBuff += deltaFactor;
            aBuff += deltaFactor*colPx;
        }
    }
    return aBuff/zBuff;
}

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
	float sigma = 2.0;
	float kSigma = 3.0;
	float threshold = 0.02025;
	
    gl_FragColor = v_vColour * smartDeNoise( gm_BaseTexture, u_Albeo, u_Normal, v_vTexcoord, sigma, kSigma, threshold );
	gl_FragColor.a = texture2D(gm_BaseTexture,v_vTexcoord).a;
    //gl_FragColor.rgb = texture2D(u_Albeo,v_vTexcoord).rgb;
	//gl_FragColor.a = 1.0;
}

