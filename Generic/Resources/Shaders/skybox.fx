//--------------------------------------------------------------------------------------------------
// Forward rendering shader
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
// Includes
//--------------------------------------------------------------------------------------------------
#include "lib\platform.fxh"
#include "lib\lighting.fxh"

//--------------------------------------------------------------------------------------------------
// Defines
//--------------------------------------------------------------------------------------------------
#define 			MAX_DIRECTIONAL_LIGHT_PER_PASS  1
#define 			MAX_POINT_LIGHT_PER_PASS        48
#define 			MAX_SPECIALIZED_LIGHT_PASS      8

//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
float4x4 			mWorldViewProjection;
float4x4 			mProjection;
float4x4 			mView;
uniform float3		vCameraPosition;
//uniform int 		iPointLightCount;

//--------------------------------------------------------------------------------------------------
// Maps Samplers
//--------------------------------------------------------------------------------------------------
#if !SH_DX11
texture skyTextureMap;
sampler 	skyTextureMapSampler = sampler_state 
{
	Texture = <skyTextureMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
	MipLODBias = 0.0f;
};
#else
Texture2D  	skyTextureMap;
SamplerState skyTextureMapSampler 
{
	Filter = Min_Mag_Linear_Mip_Point;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
	MipLODBias = 0.0f;
};
#endif
//--------------------------------------------------------------------------------------------------
// Vertex shader output structure - Pixel shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
    float4 position		: POSITION0;
    float2 texcoord		: TEXCOORD0;
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_INPUT
{
	float4	position	: POSITION;
	float2	texcoord	: TEXCOORD0;
	float3	tangent0	: TANGENT0;	
	float3	binormal0	: BINORMAL0;
	float3	normal0		: NORMAL0;	
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT VertexShaderFunction(in VS_INPUT vInput)
{
    VS_OUTPUT output;

	// Rotate into view-space, centered on the camera
    float3 positionVS = mul(vInput.position, (float3x3)mView);

    // Transform to clip-space
	output.position = mul(float4(positionVS, 1.0f), mProjection);
	output.position.z = output.position.w;
    output.texcoord = vInput.texcoord;
 
    return output;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 PixelShaderFunction(VS_OUTPUT vInput) : COLOR0
{
	//
	/// We get the right texel from the skybox texture cube
#if !SH_DX11
    return tex2D(skyTextureMapSampler, vInput.texcoord);
#else
	return skyTextureMap.Sample(skyTextureMapSampler, vInput.texcoord);
#endif
}

#if !SH_DX11
technique DefaultTechnique
{
	pass
	{
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader  = compile ps_3_0 PixelShaderFunction();
	}
}
#else
technique11 DefaultTechnique
{
	pass
	{
        SetVertexShader(	CompileShader( vs_4_0, VertexShaderFunction()));
        SetPixelShader(		CompileShader( ps_4_0, PixelShaderFunction()));
	}
}
#endif