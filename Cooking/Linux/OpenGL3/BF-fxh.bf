b     �w�%@/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/lib/skinning.glfxh f  �  �_�q�/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/lib/lighting.glfxh ,  =#  �w�%@/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/lib/skinning.fxh i3  �  ��DK=3z�/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/lib/platform.fxh /A    ��DK=3z�/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/lib/platform.glfxh CG    �_�q�/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/lib/lighting.fxh WM  =#  <!--- // skinning.glfxh -->
<glfx>

<texture name="BoneMapTexture" />

<sampler name="BoneMapSampler" type="sampler2D">
	<texture>BoneMapTexture</texture>
	<min>POINT</min><mag>POINT</mag><mip>NONE</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>

<input name="VS_SKIN_INPUT">
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
	
	<field name="POSITION0" lname="position0" type="vec4" />
	<field name="TANGENT0" lname="tangent0" type="vec3" />
	<field name="BINORMAL0" lname="binormal0" type="vec3" />
	<field name="NORMAL0" lname="normal0" type="vec3" />
	
	<field name="POSITION1" lname="position1" type="vec4" />
	<field name="TANGENT1" lname="tangent1" type="vec3" />
	<field name="BINORMAL1" lname="binormal1" type="vec3" />
	<field name="NORMAL1" lname="normal1" type="vec3" />
	
	<field name="POSITION2" lname="position2" type="vec4" />
	<field name="TANGENT2" lname="tangent2" type="vec3" />
	<field name="BINORMAL2" lname="binormal2" type="vec3" />
	<field name="NORMAL2" lname="normal2" type="vec3" />
	
	<field name="BLENDWEIGHT" lname="weights" type="vec4" />
	<field name="BLENDINDICES" lname="indices" type="vec4" />
</input>

<input name="VS_NOSKIN_INPUT">
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
	
	<field name="POSITION0" lname="position0" type="vec4" />
	<field name="TANGENT0" lname="tangent0" type="vec3" />
	<field name="BINORMAL0" lname="binormal0" type="vec3" />
	<field name="NORMAL0" lname="normal0" type="vec3" />
</input>

<code><![CDATA[

//--------------------------------------------------------------------------------------------------
// Texture with bones matrix
//--------------------------------------------------------------------------------------------------
float4 vBoneMapSize;

//
// Return the bone matrix at index u
//
float4x4 sample_bone_matrix(mediump float u)
{
	float4	r0 = tex2D(BoneMapSampler, vec2(u + vBoneMapSize.x * 0.0, 0.5));
	float4	r1 = tex2D(BoneMapSampler, vec2(u + vBoneMapSize.x * 1.0, 0.5));
	float4	r2 = tex2D(BoneMapSampler, vec2(u + vBoneMapSize.x * 2.0, 0.5));
	float4	r3 = vec4(0.0, 0.0, 0.0, 1.0);
	
	return mat4(r0.x,r1.x,r2.x,r3.x,
				r0.y,r1.y,r2.y,r3.y,
				r0.z,r1.z,r2.z,r3.z,
				r0.w,r1.w,r2.w,r3.w);
}

//
//
//
void skin(inout VS_SKIN_INPUT v)
{
	v.indices = (v.indices * 3.0 + 0.5) * vBoneMapSize.xxxx;
		
	float4x4 m0 = sample_bone_matrix(v.indices.x);
	float4x4 m1 = sample_bone_matrix(v.indices.y);
	float4x4 m2 = sample_bone_matrix(v.indices.z);
	
	v.position0 = vec4(mul(vec4(v.position0.xyz,1.0), m0).xyz * v.weights.x
				     + mul(vec4(v.position1.xyz,1.0), m1).xyz * v.weights.y
				     + mul(vec4(v.position2.xyz,1.0), m2).xyz * v.weights.z, 1.0);

	v.tangent0 = mul(v.tangent0.xyz, mat3(m0)) * v.weights.x
			   + mul(v.tangent1.xyz, mat3(m1)) * v.weights.y
			   + mul(v.tangent2.xyz, mat3(m2)) * v.weights.z;

	v.binormal0 = mul(v.binormal0.xyz, mat3(m0)) * v.weights.x
				+ mul(v.binormal1.xyz, mat3(m1)) * v.weights.y
				+ mul(v.binormal2.xyz, mat3(m2)) * v.weights.z;

	v.normal0 = mul(v.normal0.xyz, mat3(m0)) * v.weights.x
			  + mul(v.normal1.xyz, mat3(m1)) * v.weights.y
			  + mul(v.normal2.xyz, mat3(m2)) * v.weights.z;
}

//
//
//
void wind(inout float3 v, highp float time, float2 speed, mediump float freq, mediump float scale)
{
	highp float time_freq = 6.283185 * time * freq;
	v.xy += vec2(cos(time_freq),sin(time_freq)) * speed * v.z / scale;
}

//
//
//
void wind(inout float3 v, float2 offset, mediump float scale)
{
	v.xy += offset * v.z * v.z / scale;
}

]]></code>
</glfx>
<!--- // lighting.glfxh -->
<glfx>

<code><![CDATA[

//--------------------------------------------------------------------------------------------------
// Compute color luminance
//--------------------------------------------------------------------------------------------------
half ComputeLuminance(half3 color)
{
        const half3 RGB_TO_LUMA = vec3(0.2126, 0.7152, 0.0722); // or 0.299 + 0.587 + 0.114
        return(dot(RGB_TO_LUMA,color));        
}

//--------------------------------------------------------------------------------------------------
// Unpack normal from DXT5_X_Y normal map
//--------------------------------------------------------------------------------------------------
float3 UnpackNormalMap(sampler2D map, float2 uv)
{
#if 0
	float3 normal;
	normal.xy = tex2D(map, uv).ag * 2.0 - 1.0;
	normal.z = sqrt(1.0 - normal.x * normal.x - normal.y * normal.y);
	return normal;
#else
	return tex2D(map, uv).rgb * 2.0 - 1.0;
#endif
}


//--------------------------------------------------------------------------------------------------
// helper to read the Z buffer
//--------------------------------------------------------------------------------------------------
highp float GetZ(sampler2D tex, float2 position)
{
	highp float	Z = tex2D(tex, position).r;
	return Z;
}

//--------------------------------------------------------------------------------------------------
// Compute pixel normal value from tangent space and normal map texel value
//--------------------------------------------------------------------------------------------------
half3 ApplyNormalMapping(const half3 normalmap_value, const half3 world_tangent, const half3 world_binormal, const half3 world_normal)
{
	//
	// Construct tangent space
	half3x3 tangentSpace;
	tangentSpace[0] = world_tangent;
	tangentSpace[1] = world_binormal;
	tangentSpace[2] = world_normal;

	//
	// Normalize tangent space
	// (can be disabled to improve shader performance on lower end graphic cards but it will reduce image quality)
	//tangentSpace[0] = normalize(tangentSpace[0]);
	//tangentSpace[1] = normalize(tangentSpace[1]);
	//tangentSpace[2] = normalize(tangentSpace[2]);

	//
	// Offset world space normal with normal map values
	half3 N = mul(tangentSpace, normalmap_value);
	
	//
	// Normalize World space normal
	N = normalize(N);
	
	//
	// Return new normal value
	return N;
}
	
//--------------------------------------------------------------------------------------------------
// Compute blinn lighting diffuse and specular factor
//--------------------------------------------------------------------------------------------------
half2 BlinnFactor(const half3 normal_vector, const half3 light_vector, const half3 view_vector, const half shininess)
{
	half n_dot_l = dot(normal_vector, light_vector);
	half3 half_vector = normalize(view_vector + light_vector);
	half n_dot_h = dot(normal_vector, half_vector);
	half diffuse_factor = (n_dot_l < 0.0) ? 0.0 : n_dot_l;
	half specular_factor = (n_dot_l < 0.0) || (n_dot_h < 0.0) ? 0.0 : pow(n_dot_h, shininess);
	half2 blinn_factor = vec2( diffuse_factor, specular_factor );
	return blinn_factor;
}

half BlinnFactor(const half3 normal_vector, const half3 light_vector)
{
	half n_dot_l = dot(normal_vector, light_vector);
	half diffuse_factor = clamp(n_dot_l, 0.0, 1.0);
	return diffuse_factor;
}

//--------------------------------------------------------------------------------------------------
// Compute blinn lighting color
//--------------------------------------------------------------------------------------------------
half3 Blinn(const half3 diffuse_map_color, const half3 light_diffuse_color, const half3 specular_map_color, const half specular_level, const half2 blinn_factor)
{
	half3 diffuse = light_diffuse_color * diffuse_map_color * blinn_factor.x;
	half3 specular = ComputeLuminance(light_diffuse_color) * specular_map_color * specular_level * blinn_factor.y;
	return diffuse + specular;
}

half3 Blinn(const half3 diffuse_map_color, const half3 light_diffuse_color, const half blinn_factor)
{
	half3 diffuse = light_diffuse_color * diffuse_map_color * blinn_factor;
	return diffuse;
}

//--------------------------------------------------------------------------------------------------
// Compute point light attenuation
//--------------------------------------------------------------------------------------------------
highp float AttenutaionPointLight(const float3 world_position, const float3 light_position, const float2 attenuation_factor)
{
        highp float distance = length(light_position - world_position);
        return 1.0 - smoothstep(attenuation_factor.x, attenuation_factor.y, distance);
}

//--------------------------------------------------------------------------------------------------
// Compute vertical fog color
//--------------------------------------------------------------------------------------------------
half3 ApplyVFog(const half3 color, const half z, const half3 fog_color, const half2 fog_start_end)
{
	half f = saturate((z - fog_start_end.x) / (fog_start_end.y - fog_start_end.x));
	return fog_color * (1.0 - f) + color * f;
}

#if ENGINE_HAS_SHADOW
//--------------------------------------------------------------------------------------------------
// Compute shadow term
//--------------------------------------------------------------------------------------------------
mediump float ComputeShadow(in float4 shadow_texcoord, in sampler2D ShadowMapSampler)
{
	float3	ShadowViewportC = 0.5 * shadow_texcoord.xyz / shadow_texcoord.w + 0.5;

	mediump float LightAmount = 1.0;
	if (shadow_texcoord.w > 0.0)
	{
		if (ShadowViewportC.x < 0.0 || ShadowViewportC.y < 0.0 || ShadowViewportC.x > 1.0 || ShadowViewportC.y > 1.0)
		{
			LightAmount = 1.0;
		}
		else
		{
			highp float z = GetZ(ShadowMapSampler, ShadowViewportC.xy);
			LightAmount = (z + 0.001 < ShadowViewportC.z)? 0.6: 1.0;  
		}
	}
	return LightAmount;
}
#endif

//--------------------------------------------------------------------------------------------------
// Compute Silhouette (ghost/outline)
//--------------------------------------------------------------------------------------------------

float3 vWorldCameraPosition;
bool   bLightingSilhouette          = false;
float4 vLightingSilhouetteConstant  = vec4(1.0, 0.0, 0.0, 0.0);
float4 vLightingSilhouetteColor     = vec4(1.0, 1.0, 1.0, 1.0);
float2 vLightingSilhouetteThreshold = vec2(0.7, 0.9);

float3 LightingComputeSilhouette(in float3 vColor, in float3 vWorldPosition, in float3 vViewNormal, in float4x4 mView)
{
	float3 K;
	float3 VN;

	float3 VZ = -normalize(mul(vWorldPosition - vWorldCameraPosition, mat3(mView)).xyz);

	//K = 1.0f - 2.0f * (dot(vViewNormal, vViewNormal).xxx - 0.5f);
	//VN = 0.5f + normalize(vViewNormal) * 0.5f;
	VN = normalize(vViewNormal);
	mediump float sK = 0.5 + dot(VN, VZ) * 0.5;
	//K = dot(VN, VZ);
	//K = smoothstep(0.7f, 0.9f, K); //smoothstep(min, max, x) 
	sK = smoothstep(vLightingSilhouetteThreshold.x, vLightingSilhouetteThreshold.y, sK); //smoothstep(min, max, x)
	sK = 1.0 - sK;
	K = sK * vLightingSilhouetteColor.rgb;

	//K.x = K.x * 2.8f; K.y = K.y * 2.9f; K.z = K.z * 0.5f;
	//K = K * 2.0f * 3.145f - 3.145f;K = 0.5f + sin(C) * 0.5f;
	
	float3 x = vLightingSilhouetteConstant.xxx;
	float3 y = vLightingSilhouetteConstant.yyy;
	float3 z = vLightingSilhouetteConstant.zzz;
	float3 w = vLightingSilhouetteConstant.www;
	
	return x * vColor + y * vColor * K + z * K + w;
}

float3 _ComputeSilhouette(in float3 vColor, in float2 vThreshold, in float3 vSilhouetteColor, in float3 vSilhouetteConstant, in float3 vVertexToEye, in float3 vViewNormal, in float4x4 mView)
{
	float3 VZ = normalize(mul(vVertexToEye, mat3(mView)));
	float3 VN = normalize(vViewNormal);
	
	float3 K;
	mediump float sK = 0.5 + dot(VN, VZ) * 0.5;
	sK = smoothstep(vThreshold.x, vThreshold.y, sK);
	sK = 1.0 - sK;
	K = K * vSilhouetteColor.rgb;

	float3 x = vSilhouetteConstant.xxx;
	float3 y = vSilhouetteConstant.yyy;
	float3 z = vSilhouetteConstant.zzz;

	return x * vColor + y * vColor * K + z * K;
}

//--------------------------------------------------------------------------------------------------
// Stuff to support shader option builds
//--------------------------------------------------------------------------------------------------
// FEATURE SET:
// 00000 - 11111
// ABCD
//
// A = silhouette flag
// B = specular map flag
// C = env map flag
// D = self illumination flag
// E = render if occluded flag
//
// 11111 = original shader

#define FEATURE_FLAG_SILHOUETTE	16
#define FEATURE_FLAG_SPECULAR_MAP	8
#define FEATURE_FLAG_ENVMAP		4
#define FEATURE_FLAG_SELF_ILLUM	2
#define FEATURE_FLAG_OCCLUDED		1

#define USE_SILHOUETTE		(FEATURE_FLAGS & FEATURE_FLAG_SILHOUETTE)
#define USE_SPECULAR_MAP	(FEATURE_FLAGS & FEATURE_FLAG_SPECULAR_MAP)
#define USE_ENVMAP		(FEATURE_FLAGS & FEATURE_FLAG_ENVMAP)
#define USE_SELF_ILLUM		(FEATURE_FLAGS & FEATURE_FLAG_SELF_ILLUM)
#define USE_OCCLUDED		(FEATURE_FLAGS & FEATURE_FLAG_OCCLUDED)

]]></code>
</glfx>
<!--- // skinning.glfxh -->
<glfx>

<texture name="BoneMapTexture" />

<sampler name="BoneMapSampler" type="sampler2D">
	<texture>BoneMapTexture</texture>
	<min>POINT</min><mag>POINT</mag><mip>NONE</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>

<input name="VS_SKIN_INPUT">
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
	
	<field name="POSITION0" lname="position0" type="vec4" />
	<field name="TANGENT0" lname="tangent0" type="vec3" />
	<field name="BINORMAL0" lname="binormal0" type="vec3" />
	<field name="NORMAL0" lname="normal0" type="vec3" />
	
	<field name="POSITION1" lname="position1" type="vec4" />
	<field name="TANGENT1" lname="tangent1" type="vec3" />
	<field name="BINORMAL1" lname="binormal1" type="vec3" />
	<field name="NORMAL1" lname="normal1" type="vec3" />
	
	<field name="POSITION2" lname="position2" type="vec4" />
	<field name="TANGENT2" lname="tangent2" type="vec3" />
	<field name="BINORMAL2" lname="binormal2" type="vec3" />
	<field name="NORMAL2" lname="normal2" type="vec3" />
	
	<field name="BLENDWEIGHT" lname="weights" type="vec4" />
	<field name="BLENDINDICES" lname="indices" type="vec4" />
</input>

<input name="VS_NOSKIN_INPUT">
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
	
	<field name="POSITION0" lname="position0" type="vec4" />
	<field name="TANGENT0" lname="tangent0" type="vec3" />
	<field name="BINORMAL0" lname="binormal0" type="vec3" />
	<field name="NORMAL0" lname="normal0" type="vec3" />
</input>

<code><![CDATA[

//--------------------------------------------------------------------------------------------------
// Texture with bones matrix
//--------------------------------------------------------------------------------------------------
float4 vBoneMapSize;

//
// Return the bone matrix at index u
//
float4x4 sample_bone_matrix(mediump float u)
{
	float4	r0 = tex2D(BoneMapSampler, vec2(u + vBoneMapSize.x * 0.0, 0.5));
	float4	r1 = tex2D(BoneMapSampler, vec2(u + vBoneMapSize.x * 1.0, 0.5));
	float4	r2 = tex2D(BoneMapSampler, vec2(u + vBoneMapSize.x * 2.0, 0.5));
	float4	r3 = vec4(0.0, 0.0, 0.0, 1.0);
	
	return mat4(r0.x,r1.x,r2.x,r3.x,
				r0.y,r1.y,r2.y,r3.y,
				r0.z,r1.z,r2.z,r3.z,
				r0.w,r1.w,r2.w,r3.w);
}

//
//
//
void skin(inout VS_SKIN_INPUT v)
{
	v.indices = (v.indices * 3.0 + 0.5) * vBoneMapSize.xxxx;
		
	float4x4 m0 = sample_bone_matrix(v.indices.x);
	float4x4 m1 = sample_bone_matrix(v.indices.y);
	float4x4 m2 = sample_bone_matrix(v.indices.z);
	
	v.position0 = vec4(mul(vec4(v.position0.xyz,1.0), m0).xyz * v.weights.x
				     + mul(vec4(v.position1.xyz,1.0), m1).xyz * v.weights.y
				     + mul(vec4(v.position2.xyz,1.0), m2).xyz * v.weights.z, 1.0);

	v.tangent0 = mul(v.tangent0.xyz, mat3(m0)) * v.weights.x
			   + mul(v.tangent1.xyz, mat3(m1)) * v.weights.y
			   + mul(v.tangent2.xyz, mat3(m2)) * v.weights.z;

	v.binormal0 = mul(v.binormal0.xyz, mat3(m0)) * v.weights.x
				+ mul(v.binormal1.xyz, mat3(m1)) * v.weights.y
				+ mul(v.binormal2.xyz, mat3(m2)) * v.weights.z;

	v.normal0 = mul(v.normal0.xyz, mat3(m0)) * v.weights.x
			  + mul(v.normal1.xyz, mat3(m1)) * v.weights.y
			  + mul(v.normal2.xyz, mat3(m2)) * v.weights.z;
}

//
//
//
void wind(inout float3 v, highp float time, float2 speed, mediump float freq, mediump float scale)
{
	highp float time_freq = 6.283185 * time * freq;
	v.xy += vec2(cos(time_freq),sin(time_freq)) * speed * v.z / scale;
}

//
//
//
void wind(inout float3 v, float2 offset, mediump float scale)
{
	v.xy += offset * v.z * v.z / scale;
}

]]></code>
</glfx>
<!--- // platform.glfxh -->
<glfx>

<code><![CDATA[

//--------------------------------------------------------------------------------------------------
// Platform specific constants and defines (rev 2)
//--------------------------------------------------------------------------------------------------

#define ISOLATE invariant
#define TEXTURELODBIAS MipLODBias
#define DEFAULT_TEXTURELODBIAS 0.0

//
// Define value above which pixel are discarded in alpha test
const mediump float 	INT_ALPHA_REF 		= 150.0;
const lowp float 	FLOAT_ALPHA_REF 	= INT_ALPHA_REF / 255.0;

//
// define HLSL types
#define half	mediump float
#define half2	mediump vec2
#define half3	mediump vec3
#define half4	mediump vec4

#define half2x2	mediump mat2
#define half3x3	mediump mat3
#define half4x4	mediump mat4

#define float2	highp vec2
#define float3	highp vec3
#define float4	highp vec4

#define float2x2	highp mat2
#define float3x3	highp mat3
#define float4x4	highp mat4

//
// Loop keyword
#define LOOP

#define saturate(X)	clamp(X,0.0,1.0)
#define tex2D		texture2D
#define mul(A,B)	(A * B)
#define tex2Dlod	texture2DLod

const float2 VPOS_offset = vec2(0.0,0.0);

//
// Disable FXAA on iOS for now
float4 FXAALuminance(float3 color)
{
    const float3 RGB_TO_LUMA = vec3(0.299, 0.587, 0.114);
    return(vec4(color, dot(RGB_TO_LUMA, sqrt(saturate(color)))));
}

//
// Screen resolution
uniform mediump float	SCREENW;
uniform mediump float	SCREENH;
uniform mediump float	HALFSCREENW;
uniform mediump float	HALFSCREENH;
uniform float4	SCREEN_SIZE;

]]></code>
</glfx>
<!--- // platform.glfxh -->
<glfx>

<code><![CDATA[

//--------------------------------------------------------------------------------------------------
// Platform specific constants and defines (rev 2)
//--------------------------------------------------------------------------------------------------

#define ISOLATE invariant
#define TEXTURELODBIAS MipLODBias
#define DEFAULT_TEXTURELODBIAS 0.0

//
// Define value above which pixel are discarded in alpha test
const mediump float 	INT_ALPHA_REF 		= 150.0;
const lowp float 	FLOAT_ALPHA_REF 	= INT_ALPHA_REF / 255.0;

//
// define HLSL types
#define half	mediump float
#define half2	mediump vec2
#define half3	mediump vec3
#define half4	mediump vec4

#define half2x2	mediump mat2
#define half3x3	mediump mat3
#define half4x4	mediump mat4

#define float2	highp vec2
#define float3	highp vec3
#define float4	highp vec4

#define float2x2	highp mat2
#define float3x3	highp mat3
#define float4x4	highp mat4

//
// Loop keyword
#define LOOP

#define saturate(X)	clamp(X,0.0,1.0)
#define tex2D		texture2D
#define mul(A,B)	(A * B)
#define tex2Dlod	texture2DLod

const float2 VPOS_offset = vec2(0.0,0.0);

//
// Disable FXAA on iOS for now
float4 FXAALuminance(float3 color)
{
    const float3 RGB_TO_LUMA = vec3(0.299, 0.587, 0.114);
    return(vec4(color, dot(RGB_TO_LUMA, sqrt(saturate(color)))));
}

//
// Screen resolution
uniform mediump float	SCREENW;
uniform mediump float	SCREENH;
uniform mediump float	HALFSCREENW;
uniform mediump float	HALFSCREENH;
uniform float4	SCREEN_SIZE;

]]></code>
</glfx>
<!--- // lighting.glfxh -->
<glfx>

<code><![CDATA[

//--------------------------------------------------------------------------------------------------
// Compute color luminance
//--------------------------------------------------------------------------------------------------
half ComputeLuminance(half3 color)
{
        const half3 RGB_TO_LUMA = vec3(0.2126, 0.7152, 0.0722); // or 0.299 + 0.587 + 0.114
        return(dot(RGB_TO_LUMA,color));        
}

//--------------------------------------------------------------------------------------------------
// Unpack normal from DXT5_X_Y normal map
//--------------------------------------------------------------------------------------------------
float3 UnpackNormalMap(sampler2D map, float2 uv)
{
#if 0
	float3 normal;
	normal.xy = tex2D(map, uv).ag * 2.0 - 1.0;
	normal.z = sqrt(1.0 - normal.x * normal.x - normal.y * normal.y);
	return normal;
#else
	return tex2D(map, uv).rgb * 2.0 - 1.0;
#endif
}


//--------------------------------------------------------------------------------------------------
// helper to read the Z buffer
//--------------------------------------------------------------------------------------------------
highp float GetZ(sampler2D tex, float2 position)
{
	highp float	Z = tex2D(tex, position).r;
	return Z;
}

//--------------------------------------------------------------------------------------------------
// Compute pixel normal value from tangent space and normal map texel value
//--------------------------------------------------------------------------------------------------
half3 ApplyNormalMapping(const half3 normalmap_value, const half3 world_tangent, const half3 world_binormal, const half3 world_normal)
{
	//
	// Construct tangent space
	half3x3 tangentSpace;
	tangentSpace[0] = world_tangent;
	tangentSpace[1] = world_binormal;
	tangentSpace[2] = world_normal;

	//
	// Normalize tangent space
	// (can be disabled to improve shader performance on lower end graphic cards but it will reduce image quality)
	//tangentSpace[0] = normalize(tangentSpace[0]);
	//tangentSpace[1] = normalize(tangentSpace[1]);
	//tangentSpace[2] = normalize(tangentSpace[2]);

	//
	// Offset world space normal with normal map values
	half3 N = mul(tangentSpace, normalmap_value);
	
	//
	// Normalize World space normal
	N = normalize(N);
	
	//
	// Return new normal value
	return N;
}
	
//--------------------------------------------------------------------------------------------------
// Compute blinn lighting diffuse and specular factor
//--------------------------------------------------------------------------------------------------
half2 BlinnFactor(const half3 normal_vector, const half3 light_vector, const half3 view_vector, const half shininess)
{
	half n_dot_l = dot(normal_vector, light_vector);
	half3 half_vector = normalize(view_vector + light_vector);
	half n_dot_h = dot(normal_vector, half_vector);
	half diffuse_factor = (n_dot_l < 0.0) ? 0.0 : n_dot_l;
	half specular_factor = (n_dot_l < 0.0) || (n_dot_h < 0.0) ? 0.0 : pow(n_dot_h, shininess);
	half2 blinn_factor = vec2( diffuse_factor, specular_factor );
	return blinn_factor;
}

half BlinnFactor(const half3 normal_vector, const half3 light_vector)
{
	half n_dot_l = dot(normal_vector, light_vector);
	half diffuse_factor = clamp(n_dot_l, 0.0, 1.0);
	return diffuse_factor;
}

//--------------------------------------------------------------------------------------------------
// Compute blinn lighting color
//--------------------------------------------------------------------------------------------------
half3 Blinn(const half3 diffuse_map_color, const half3 light_diffuse_color, const half3 specular_map_color, const half specular_level, const half2 blinn_factor)
{
	half3 diffuse = light_diffuse_color * diffuse_map_color * blinn_factor.x;
	half3 specular = ComputeLuminance(light_diffuse_color) * specular_map_color * specular_level * blinn_factor.y;
	return diffuse + specular;
}

half3 Blinn(const half3 diffuse_map_color, const half3 light_diffuse_color, const half blinn_factor)
{
	half3 diffuse = light_diffuse_color * diffuse_map_color * blinn_factor;
	return diffuse;
}

//--------------------------------------------------------------------------------------------------
// Compute point light attenuation
//--------------------------------------------------------------------------------------------------
highp float AttenutaionPointLight(const float3 world_position, const float3 light_position, const float2 attenuation_factor)
{
        highp float distance = length(light_position - world_position);
        return 1.0 - smoothstep(attenuation_factor.x, attenuation_factor.y, distance);
}

//--------------------------------------------------------------------------------------------------
// Compute vertical fog color
//--------------------------------------------------------------------------------------------------
half3 ApplyVFog(const half3 color, const half z, const half3 fog_color, const half2 fog_start_end)
{
	half f = saturate((z - fog_start_end.x) / (fog_start_end.y - fog_start_end.x));
	return fog_color * (1.0 - f) + color * f;
}

#if ENGINE_HAS_SHADOW
//--------------------------------------------------------------------------------------------------
// Compute shadow term
//--------------------------------------------------------------------------------------------------
mediump float ComputeShadow(in float4 shadow_texcoord, in sampler2D ShadowMapSampler)
{
	float3	ShadowViewportC = 0.5 * shadow_texcoord.xyz / shadow_texcoord.w + 0.5;

	mediump float LightAmount = 1.0;
	if (shadow_texcoord.w > 0.0)
	{
		if (ShadowViewportC.x < 0.0 || ShadowViewportC.y < 0.0 || ShadowViewportC.x > 1.0 || ShadowViewportC.y > 1.0)
		{
			LightAmount = 1.0;
		}
		else
		{
			highp float z = GetZ(ShadowMapSampler, ShadowViewportC.xy);
			LightAmount = (z + 0.001 < ShadowViewportC.z)? 0.6: 1.0;  
		}
	}
	return LightAmount;
}
#endif

//--------------------------------------------------------------------------------------------------
// Compute Silhouette (ghost/outline)
//--------------------------------------------------------------------------------------------------

float3 vWorldCameraPosition;
bool   bLightingSilhouette          = false;
float4 vLightingSilhouetteConstant  = vec4(1.0, 0.0, 0.0, 0.0);
float4 vLightingSilhouetteColor     = vec4(1.0, 1.0, 1.0, 1.0);
float2 vLightingSilhouetteThreshold = vec2(0.7, 0.9);

float3 LightingComputeSilhouette(in float3 vColor, in float3 vWorldPosition, in float3 vViewNormal, in float4x4 mView)
{
	float3 K;
	float3 VN;

	float3 VZ = -normalize(mul(vWorldPosition - vWorldCameraPosition, mat3(mView)).xyz);

	//K = 1.0f - 2.0f * (dot(vViewNormal, vViewNormal).xxx - 0.5f);
	//VN = 0.5f + normalize(vViewNormal) * 0.5f;
	VN = normalize(vViewNormal);
	mediump float sK = 0.5 + dot(VN, VZ) * 0.5;
	//K = dot(VN, VZ);
	//K = smoothstep(0.7f, 0.9f, K); //smoothstep(min, max, x) 
	sK = smoothstep(vLightingSilhouetteThreshold.x, vLightingSilhouetteThreshold.y, sK); //smoothstep(min, max, x)
	sK = 1.0 - sK;
	K = sK * vLightingSilhouetteColor.rgb;

	//K.x = K.x * 2.8f; K.y = K.y * 2.9f; K.z = K.z * 0.5f;
	//K = K * 2.0f * 3.145f - 3.145f;K = 0.5f + sin(C) * 0.5f;
	
	float3 x = vLightingSilhouetteConstant.xxx;
	float3 y = vLightingSilhouetteConstant.yyy;
	float3 z = vLightingSilhouetteConstant.zzz;
	float3 w = vLightingSilhouetteConstant.www;
	
	return x * vColor + y * vColor * K + z * K + w;
}

float3 _ComputeSilhouette(in float3 vColor, in float2 vThreshold, in float3 vSilhouetteColor, in float3 vSilhouetteConstant, in float3 vVertexToEye, in float3 vViewNormal, in float4x4 mView)
{
	float3 VZ = normalize(mul(vVertexToEye, mat3(mView)));
	float3 VN = normalize(vViewNormal);
	
	float3 K;
	mediump float sK = 0.5 + dot(VN, VZ) * 0.5;
	sK = smoothstep(vThreshold.x, vThreshold.y, sK);
	sK = 1.0 - sK;
	K = K * vSilhouetteColor.rgb;

	float3 x = vSilhouetteConstant.xxx;
	float3 y = vSilhouetteConstant.yyy;
	float3 z = vSilhouetteConstant.zzz;

	return x * vColor + y * vColor * K + z * K;
}

//--------------------------------------------------------------------------------------------------
// Stuff to support shader option builds
//--------------------------------------------------------------------------------------------------
// FEATURE SET:
// 00000 - 11111
// ABCD
//
// A = silhouette flag
// B = specular map flag
// C = env map flag
// D = self illumination flag
// E = render if occluded flag
//
// 11111 = original shader

#define FEATURE_FLAG_SILHOUETTE	16
#define FEATURE_FLAG_SPECULAR_MAP	8
#define FEATURE_FLAG_ENVMAP		4
#define FEATURE_FLAG_SELF_ILLUM	2
#define FEATURE_FLAG_OCCLUDED		1

#define USE_SILHOUETTE		(FEATURE_FLAGS & FEATURE_FLAG_SILHOUETTE)
#define USE_SPECULAR_MAP	(FEATURE_FLAGS & FEATURE_FLAG_SPECULAR_MAP)
#define USE_ENVMAP		(FEATURE_FLAGS & FEATURE_FLAG_ENVMAP)
#define USE_SELF_ILLUM		(FEATURE_FLAGS & FEATURE_FLAG_SELF_ILLUM)
#define USE_OCCLUDED		(FEATURE_FLAGS & FEATURE_FLAG_OCCLUDED)

]]></code>
</glfx>
