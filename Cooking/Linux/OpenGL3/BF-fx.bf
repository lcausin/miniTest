�     ��!�=>@/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/LightPrePass.glfx �  g3  .E�F��/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/primitive_solid.glfx 9  	  o��7>Ÿ/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/Blit.glfx +B  �  ���(�^�/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/entity_standard.glfx �F  �+  @�ۢmu/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/Fonts.glfx �r  n  N9���RNc/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/entity_standard_direct.glfx {  �3  ��w��c��/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/DiffuseColorSolid.glfx î  l  �e���H��/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/entity_standard_shadow.glfx /�  >  N&e͆��/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/SingleTexture.glfx m�  �  4 *�����/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/primitive_wire.glfx 4�  l  ��4�n��/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/entity_standard_nd.glfx ��  Z  �����/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/particle.glfx ��  b  ;��>]�/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/forward_rendering_standard.glfx \ /  ��/�p~��/home/lcausin/Documents/MiniProjetGui/./Generic//Resources/Shaders/skybox.glfx � 4
  <!--- // Light pass (rev 2) -->
<glfx>

<include name="lib/platform.glfxh" />
<include name="lib/lighting.glfxh" />

<texture name="NormalShininessMap" />
<texture name="DepthMap" />
<texture name="SSAOMap" />

<sampler name="NormalShininessMapSampler" type="sampler2D">
	<texture>NormalShininessMap</texture>
	<min>POINT</min><mag>POINT</mag><mip>NONE</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>
<sampler name="DepthMapSampler" type="sampler2D">
	<texture>DepthMap</texture>
	<min>POINT</min><mag>POINT</mag><mip>NONE</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>
<sampler name="SSAOMapSampler" type="sampler2D">
	<texture>SSAOMap</texture>
	<min>POINT</min><mag>POINT</mag><mip>NONE</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>

<input name="VS_INPUT">
	<field name="POSITION" lname="position" type="vec2" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
</input>

<output name="PS_INPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="TEXCOORD0" lname="texcoord_screen" type="vec4" prec="mediump" />
</output>

<code><![CDATA[
//--------------------------------------------------------------------------------------------------
// Defines
//--------------------------------------------------------------------------------------------------
#define MAX_DIRECTIONAL_LIGHT_PER_PASS  1
#define MAX_POINT_LIGHT_PER_PASS        16
#define MAX_SPECIALIZED_LIGHT_PASS      8

//--------------------------------------------------------------------------------------------------
// Viewport and scene
//--------------------------------------------------------------------------------------------------
uniform float4x4        mInverseViewProj;
uniform float3          vCameraPosition;
uniform float			fSSAOFactor;

//--------------------------------------------------------------------------------------------------
// Directionnal Light
//--------------------------------------------------------------------------------------------------
uniform float4			DirectionalLightVector[MAX_DIRECTIONAL_LIGHT_PER_PASS];
uniform float4			DirectionalLightColor[MAX_DIRECTIONAL_LIGHT_PER_PASS];


//--------------------------------------------------------------------------------------------------
// Point Lights
//--------------------------------------------------------------------------------------------------
uniform float4          PointLight_Position_AttNear[MAX_POINT_LIGHT_PER_PASS];
uniform float4          PointLight_Color_AttFar[MAX_POINT_LIGHT_PER_PASS];

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
PS_INPUT vs(VS_INPUT In)
{
	PS_INPUT	Out;

    // XY: texture coordinates (top,left) = (0,0)
    Out.texcoord_screen.xy = In.texcoord;

    // ZW: clip space coordinates (top,left) = (-1,+1)
    Out.texcoord_screen.zw = In.position;

    // Output position
	Out.position = vec4(In.position,1,1);

	return Out;
}


//--------------------------------------------------------------------------------------------------
// Compute Point Light
//--------------------------------------------------------------------------------------------------
half4 ComputeDirectionalLightParams(
        in  float3      world_position,
        in  half3      world_normal,
        in  half3      view_vector,
        in  half 		shininess,
		in  half		occlusion,
        in  half3      light_vector,
        in  half3      light_diffuse )
{
#ifndef NO_SPECULAR
	half2 lighting      = BlinnFactor(world_normal, -light_vector, view_vector, shininess);
	half4 returnAccum   = vec4(light_diffuse * (lighting.x * occlusion), ComputeLuminance(light_diffuse) * lighting.y);
#else // NO_SPECULAR
	half lighting       = BlinnFactor(world_normal, -light_vector) * occlusion;
	half4 returnAccum   = vec4(light_diffuse * lighting, 0);
#endif // NO_SPECULAR
    return returnAccum;
}

//--------------------------------------------------------------------------------------------------
// Compute Point Light
//--------------------------------------------------------------------------------------------------
half4 ComputePointLightParams(
        in  float3      world_position,
        in  half3      world_normal,
        in  half3      view_vector,
        in  half 		shininess,
		in  half		occlusion,
        in  float3      light_position,
        in  half3      light_diffuse,
        in  float2      light_attenuation )
{
	highp float attenuation	= AttenutaionPointLight(world_position, light_position, light_attenuation);
	half3 light_vector		= normalize(light_position - world_position);

#ifndef NO_SPECULAR
	half2 lighting	= BlinnFactor(world_normal, light_vector, view_vector, shininess) * attenuation;
  half4 returnAccum = vec4(light_diffuse * (lighting.x * occlusion), ComputeLuminance(light_diffuse) * lighting.y);
#else // NO_SPECULAR
	half lighting	= BlinnFactor(world_normal, light_vector) * attenuation * occlusion;
  half4 returnAccum = vec4(light_diffuse * lighting, 0);
#endif // NO_SPECULAR
  return returnAccum;
}

#define directional_light_count		1
#define point_light_count			NUMPT

//--------------------------------------------------------------------------------------------------
// Pixel Shader Code
//--------------------------------------------------------------------------------------------------
float4 ps(PS_INPUT Vin)
{
	//
	// Scale and Bias Normal / Shininess
  float4 offset1 = vec4(2, 2, 2, 128);
  float4 offset2 = vec4(1, 1, 1, 0);
	float4 normal_shininess = tex2D(NormalShininessMapSampler, Vin.texcoord_screen.xy) * offset1 - offset2;
	half3 world_normal = normalize(normal_shininess.xyz);
	half shininess = normal_shininess.w;

	//
	// Reconstruct world position using inverse viewproj matrix
	highp float	Z = GetZ(DepthMapSampler, Vin.texcoord_screen.xy);
  float4 zTexcoord = vec4(Vin.texcoord_screen.zw,Z*2.0-1.0 ,1);
	float4 unproject_world_position = mul(zTexcoord,mInverseViewProj);
	float3 world_position = unproject_world_position.xyz / unproject_world_position.w;

	//
	// Camera/World Vector
	half3 view_vector = normalize(vCameraPosition - world_position);

    //
    // SSAO Factor
  float2 screenInverse = vec2(1.0/SCREENW,1.0/SCREENH);
  float2 halfscreenInverse = vec2(1.0/HALFSCREENW,1.0/HALFSCREENH);
	float2 ssao_uv = Vin.texcoord_screen.xy - 0.5 * screenInverse + 0.5 * halfscreenInverse;
	//float ssao_factor = fSSAOFactor * (tex2D(SSAOMapSampler, ssao_uv).r * 2.0 - 1.0) * 0.0 + 1.0;
	float ssao_factor = 1.0;

	//
	// Accumulate lights
	float4 accum_light = vec4(0.0,0.0,0.0,0.0);

	//
	// Directionnal Light
	//
    for( int i = 0 ; i < directional_light_count ; i++ )
    {
        accum_light += ComputeDirectionalLightParams(
            world_position,
            world_normal,
            view_vector,
            shininess,
			ssao_factor,
            DirectionalLightVector[i].xyz,
            DirectionalLightColor[i].rgb);
    }
//	return accum_light;
    //
    // Point Light
	//
    for( int i = 0 ; i < point_light_count ; i += 1 )
    {
        float2 plPosColor = vec2(PointLight_Position_AttNear[i].w, PointLight_Color_AttFar[i].w);
        accum_light += ComputePointLightParams(
            world_position,
            world_normal,
            view_vector,
            shininess,
			ssao_factor,
            PointLight_Position_AttNear[i].xyz,
            PointLight_Color_AttFar[i].rgb,
            plPosColor);
    }

#ifndef NO_SPECULAR
	return accum_light;
#else // NO_SPECULAR
    return vec4(accum_light.xyz,1);
#endif // NO_SPECULAR
}

]]></code>

<tech name="directional_1_0"><define name="NUMPT" value="0" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_1"><define name="NUMPT" value="1" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_2"><define name="NUMPT" value="2" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_3"><define name="NUMPT" value="3" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_4"><define name="NUMPT" value="4" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_5"><define name="NUMPT" value="5" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_6"><define name="NUMPT" value="6" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_7"><define name="NUMPT" value="7" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_8"><define name="NUMPT" value="8" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_9"><define name="NUMPT" value="9" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_10"><define name="NUMPT" value="10" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_11"><define name="NUMPT" value="11" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_12"><define name="NUMPT" value="12" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_13"><define name="NUMPT" value="13" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_14"><define name="NUMPT" value="14" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_15"><define name="NUMPT" value="15" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="directional_1_16"><define name="NUMPT" value="16" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>

<tech name="nospec_directional_1_0"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="0" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_1"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="1" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_2"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="2" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_3"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="3" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_4"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="4" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_5"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="5" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_6"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="6" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_7"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="7" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_8"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="8" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_9"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="9" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_10"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="10" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_11"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="11" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_12"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="12" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_13"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="13" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_14"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="14" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_15"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="15" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>
<tech name="nospec_directional_1_16"><define name="NO_SPECULAR" value="1" /><define name="NUMPT" value="16" /><vs name="vs" input="VS_INPUT" output="PS_INPUT" /><ps name="ps" /></tech>

</glfx>

<!--- // Singletexture.glfx -->
<glfx>

<input name="VS_INPUT">
	<field name="POSITION" lname="position" type="vec4" />
<!--	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
	<field name="TANGENT" lname="tangent" type="vec3" />
	<field name="BINORMAL" lname="binormal" type="vec3" />
	<field name="NORMAL" lname="normal" type="vec3" /> -->
	<field name="COLOR" lname="color" type="vec4" />
</input>

<output name="VS_OUTPUT_VC">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="COLOR" lname="color" type="vec4" prec="mediump" />
</output>

<output name="VS_OUTPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
</output>

<code><![CDATA[
//--------------------------------------------------------------------------------------------------
// Pick buffer
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
// Parameters
//--------------------------------------------------------------------------------------------------
uniform highp mat4  	mWorldViewProjection;
uniform mediump vec4	DiffuseColor;

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT_VC vsVC(VS_INPUT vIn)
{
	VS_OUTPUT_VC vOut;
	vOut.position = vIn.position * mWorldViewProjection;
	vOut.color    = vIn.color;
	return(vOut);
}

VS_OUTPUT vs(VS_INPUT vIn)
{
	VS_OUTPUT vOut;
	vOut.position = vIn.position * mWorldViewProjection;
	return(vOut);
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
lowp vec4 psVC(VS_OUTPUT_VC vIn)
{
	return(DiffuseColor * vIn.color);
}

lowp vec4 ps(VS_OUTPUT vIn)
{
	return(DiffuseColor);
}

]]></code>

<tech name="DefaultTechnique">
	<vs name="vsVC" input="VS_INPUT" output="VS_OUTPUT_VC" />
	<ps name="psVC" />
</tech>

<tech name="DefaultTechniqueNoVertexColor">
	<vs name="vs" input="VS_INPUT" output="VS_OUTPUT" />
	<ps name="ps" />
</tech>

</glfx>
<!--- // Blit.glfx -->
<glfx>

<include name="lib/platform.glfxh" />

<texture name="InputTextureColor" />
<sampler name="InputTextureColorSampler" type="sampler2D">
	<texture>InputTextureColor</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>NONE</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>

<input name="VS_INPUT">
	<field name="POSITION" lname="vPosition" type="vec4" />
	<field name="TEXCOORD" lname="vTexcoord" type="vec2" />
</input>

<output name="VS_OUTPUT">
	<field name="POSITION" lname="vPosition" type="vec4" prec="highp" />
	<field name="TEXCOORD" lname="vTexcoord" type="vec2" prec="mediump" />
</output>

<code><![CDATA[

VS_OUTPUT BlitVS(VS_INPUT vIn)
{
	VS_OUTPUT vOut;
	vOut.vTexcoord = vIn.vTexcoord;
	vOut.vPosition = vIn.vPosition;

	return(vOut);
}

//-----------------------------------------------------------------------------
// 
//-----------------------------------------------------------------------------
float4 BlitPS( in VS_OUTPUT pIn)
{
	return tex2D(InputTextureColorSampler, pIn.vTexcoord);
}

]]></code>

<tech name="Blit">
	<vs name="BlitVS" input="VS_INPUT" output="VS_OUTPUT" />
	<ps name="BlitPS" />
</tech>

</glfx><!--- // entity_standard.glfx -->
<glfx>

<include name="lib/platform.glfxh" />
<include name="lib/lighting.glfxh" />
<include name="lib/skinning.glfxh" />

<texture name="DiffuseMap" />
<texture name="SpecularMap" />
<texture name="LightBufferMap" />
<texture name="ShadowMap" />

<sampler name="DiffuseMapSampler" type="sampler2D">
	<texture>DiffuseMap</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>POINT</mip>
	<wrapu>REPEAT</wrapu><wrapv>REPEAT</wrapv>
</sampler>
<sampler name="SpecularMapSampler" type="sampler2D">
	<texture>SpecularMap</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>POINT</mip>
	<wrapu>REPEAT</wrapu><wrapv>REPEAT</wrapv>
</sampler>
<sampler name="LightBufferMapSampler" type="sampler2D">
	<texture>LightBufferMap</texture>
	<min>POINT</min><mag>POINT</mag><mip>NONE</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>
<sampler name="ShadowMapSampler" type="sampler2D">
	<texture>ShadowMap</texture>
	<min>POINT</min><mag>POINT</mag><mip>NONE</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>

<input name="VS_INPUT">
	<field name="POSITION" lname="position" type="vec2" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
</input>
<input name="VS_INPUT_COLOR">
	<field name="POSITION" lname="position" type="vec2" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
	<field name="COLOR" lname="color" type="vec4" />
</input>
<input name="VS_INPUT_POSITION4">
	<field name="POSITION" lname="position" type="vec4" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
	<field name="COLOR" lname="color" type="vec4" />
</input>

<output name="VS_OUTPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="TEXCOORD0" lname="texcoord" type="vec4" prec="highp" />
	<field name="TEXCOORD1" lname="worldPos" type="vec3" prec="highp" />
	<field name="TEXCOORD2" lname="shadtexcoord" type="vec4" prec="highp" />
	<field name="TEXCOORD3" lname="viewNormal" type="vec3" prec="highp" />
</output>
<output name="VS_OUTPUT_COLOR">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" prec="mediump" />
	<field name="COLOR" lname="color" type="vec4" prec="lowp" />
</output>

<code><![CDATA[
//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
uniform highp mat4 	mWorld;
uniform highp mat4 	mWorldIT;
uniform highp mat4	mView;
uniform highp mat4 	mWorldViewProjection;

//--------------------------------------------------------------------------------------------------
// Automatic Shadow Parameters
//--------------------------------------------------------------------------------------------------
uniform highp mat4 	mShadowTexture;

//--------------------------------------------------------------------------------------------------
// Automatic Fog Parameters
//--------------------------------------------------------------------------------------------------
uniform mediump vec3  	verticalFogColor;
uniform highp vec2   	verticalFogStartEnd;

//--------------------------------------------------------------------------------------------------
// Automatic Colors Parameters
//--------------------------------------------------------------------------------------------------
uniform mediump vec3   	AmbientColor;
uniform mediump vec3	SelfIllumColor2;

uniform mediump float	RenderIfOccluded;
uniform mediump vec4	ModulateColor;
uniform mediump vec4	SaturateColor;

//--------------------------------------------------------------------------------------------------
// Material Parameters
//--------------------------------------------------------------------------------------------------
uniform mediump vec3   	DiffuseMapModulator;
uniform mediump vec3   	SpecularMapModulator;
uniform mediump vec3   	SelfIllumColor;
uniform mediump float  	SpecularLevel;

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_NOSKIN_INPUT vIn)
{
	VS_OUTPUT Out;
	Out.position = mul(vIn.position0, mWorldViewProjection);
	Out.texcoord.xy = vIn.texcoord;
	Out.worldPos = mul(vIn.position0,mWorld).xyz;
#if ENGINE_HAS_SHADOW
	Out.shadtexcoord = mul(vIn.position0, mShadowTexture);
#endif
	Out.viewNormal = mul(normalize(mul(vIn.normal0, mat3(mWorldIT)).xyz), mat3(mView)).xyz;//TEMP

	return Out;
}

float4 ps(VS_OUTPUT vIn)
{
	//
	// Get the diffuse color from the diffuse map
	float3 diffuseMapTexel = tex2D(DiffuseMapSampler, vIn.texcoord.xy).rgb * DiffuseMapModulator;

#if USE_SPECULAR_MAP
	//
	// Get the specular color from the specular map
	float3 specularMapTexel = tex2D(SpecularMapSampler, vIn.texcoord.xy).rgb * SpecularMapModulator;
#endif

	//
	// Compute screen position
	half2 ScreenPos = gl_FragCoord.xy * SCREEN_SIZE.zw;
	ScreenPos.y = 1.0 - ScreenPos.y;

	//
	// LightBuffer values
	float4 lightsparams     = tex2D(LightBufferMapSampler, ScreenPos);
	float3 diffuse_color    = lightsparams.xyz;
	mediump float  specular_factor  = lightsparams.w;

	//
	// Final color
	float3 C = AmbientColor;

#if USE_SPECULAR_MAP
	//
	// Compute Blinn
	C += Blinn(diffuseMapTexel, diffuse_color, specularMapTexel, SpecularLevel, vec2(1.0,specular_factor));
#else
	C += diffuseMapTexel * diffuse_color;
#endif

	//
	// Final color += self illumination term
	C += SelfIllumColor + SelfIllumColor2;

#if ENGINE_HAS_SHADOW
    //
    // Shadow
	C *= ComputeShadow(vIn.shadtexcoord, ShadowMapSampler);
#endif

#if USE_SILHOUETTE
	//
	// Silhouette Effect (Outline, Ghost, Invisibility)
	C = LightingComputeSilhouette(C, vIn.worldPos, vIn.viewNormal, mView);
#endif

#if USE_OCCLUDED
	//
	// Modulate + Saturate
	//C *= ModulateColor;	C += SaturateColor;
	C = (1.0 - RenderIfOccluded) * C + RenderIfOccluded * (C * ModulateColor.rgb + SaturateColor.rgb);
#endif

	//
	// Fog
	C = ApplyVFog(C, vIn.worldPos.z, verticalFogColor, verticalFogStartEnd);

    //
    // Alpha channel is used by FXAA
    return FXAALuminance(C);
}

]]></code>

<tech name="Solid">
	<define name="FEATURE_FLAGS" value="15" />
	<vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" />
	<ps name="ps" />
</tech>
<!---
<tech name="SolidSilhouette">
	<define name="FEATURE_FLAGS" value="31" />
	<vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" />
	<ps name="ps" />
</tech>
--->

<tech name="Solid0"><define name="FEATURE_FLAGS" value="0" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid1"><define name="FEATURE_FLAGS" value="1" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid2"><define name="FEATURE_FLAGS" value="2" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid3"><define name="FEATURE_FLAGS" value="3" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid4"><define name="FEATURE_FLAGS" value="4" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid5"><define name="FEATURE_FLAGS" value="5" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid6"><define name="FEATURE_FLAGS" value="6" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid7"><define name="FEATURE_FLAGS" value="7" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid8"><define name="FEATURE_FLAGS" value="8" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid9"><define name="FEATURE_FLAGS" value="9" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid10"><define name="FEATURE_FLAGS" value="10" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid11"><define name="FEATURE_FLAGS" value="11" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid12"><define name="FEATURE_FLAGS" value="12" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid13"><define name="FEATURE_FLAGS" value="13" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid14"><define name="FEATURE_FLAGS" value="14" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid15"><define name="FEATURE_FLAGS" value="15" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<!---
<tech name="Solid16"><define name="FEATURE_FLAGS" value="16" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid17"><define name="FEATURE_FLAGS" value="17" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid18"><define name="FEATURE_FLAGS" value="18" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid19"><define name="FEATURE_FLAGS" value="19" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid20"><define name="FEATURE_FLAGS" value="20" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid21"><define name="FEATURE_FLAGS" value="21" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid22"><define name="FEATURE_FLAGS" value="22" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid23"><define name="FEATURE_FLAGS" value="23" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid24"><define name="FEATURE_FLAGS" value="24" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid25"><define name="FEATURE_FLAGS" value="25" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid26"><define name="FEATURE_FLAGS" value="26" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid27"><define name="FEATURE_FLAGS" value="27" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid28"><define name="FEATURE_FLAGS" value="28" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid29"><define name="FEATURE_FLAGS" value="29" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid30"><define name="FEATURE_FLAGS" value="30" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid31"><define name="FEATURE_FLAGS" value="31" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
--->

</glfx>
<!--- // Singletexture.glfx -->
<glfx>
<texture name="TextureMap" />
<texture name="TileSet" />

<sampler name="TextureMapSampler" type="sampler2D">
	<texture>TextureMap</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>LINEAR</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>
<sampler name="TileSetSampler" type="sampler2D">
	<texture>TileSet</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>LINEAR</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>

<input name="VS_INPUT">
	<field name="POSITION" lname="position" type="vec2" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
	<field name="COLOR" lname="color" type="vec4" />
</input>

<output name="VS_OUTPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" prec="mediump" />
	<field name="COLOR" lname="color" type="vec4" prec="mediump" />
</output>

<code><![CDATA[
//
// Transformations parameters
//
uniform highp mat4 WorldViewProjection;

//
// DiffuseColor Color
//
uniform mediump vec4 DiffuseColor;
uniform mediump vec4 SCREEN_SIZE;

uniform mediump vec2	TextureMapSize;
uniform mediump vec2	TileSetSize;

//--------------------------------------------------------------------------------------------------
// 2D elements in clip-space [-1,+1] with position.xy and texcoord.xy
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_INPUT vIn)
{
	VS_OUTPUT	vOut;

	vOut.texcoord = vIn.texcoord;
	vOut.position = vec4(vIn.position,0,1) * WorldViewProjection;
	vOut.color = vIn.color;

	return vOut;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
lowp vec4 ps(VS_OUTPUT vIn)
{
	lowp vec4 textureColor = texture2D(TextureMapSampler, vIn.texcoord);
	return vec4(1.0, 1.0, 1.0, textureColor.a) * vIn.color * DiffuseColor;
}

]]></code>

<tech name="DefaultTechnique">
	<vs name="vs" input="VS_INPUT" output="VS_OUTPUT" />
	<ps name="ps" />
</tech>
</glfx>
<!--- // entity_standard_direct.glfx -->
<glfx>

<include name="lib/platform.glfxh" />
<include name="lib/lighting.glfxh" />
<include name="lib/skinning.glfxh" />

<texture name="DiffuseMap" />
<texture name="SpecularMap" />
<texture name="ShadowMap" />
<texture name="NormalMap" />

<sampler name="DiffuseMapSampler" type="sampler2D">
	<texture>DiffuseMap</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>POINT</mip>
	<wrapu>REPEAT</wrapu><wrapv>REPEAT</wrapv>
</sampler>
<sampler name="SpecularMapSampler" type="sampler2D">
	<texture>SpecularMap</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>POINT</mip>
	<wrapu>REPEAT</wrapu><wrapv>REPEAT</wrapv>
</sampler>
<sampler name="ShadowMapSampler" type="sampler2D">
	<texture>ShadowMap</texture>
	<min>POINT</min><mag>POINT</mag><mip>NONE</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>
<sampler name="NormalMapSampler" type="sampler2D">
	<texture>NormalMap</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>LINEAR</mip>
	<wrapu>REPEAT</wrapu><wrapv>REPEAT</wrapv>
</sampler>

<input name="VS_INPUT">
	<field name="POSITION" lname="position" type="vec2" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
</input>
<input name="VS_INPUT_COLOR">
	<field name="POSITION" lname="position" type="vec2" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
	<field name="COLOR" lname="color" type="vec4" />
</input>
<input name="VS_INPUT_POSITION4">
	<field name="POSITION" lname="position" type="vec4" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
	<field name="COLOR" lname="color" type="vec4" />
</input>

<output name="VS_OUTPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" prec="highp" />
	<field name="TEXCOORD1" lname="shadtexcoord" type="vec4" prec="highp" />
	<field name="TEXCOORD2" lname="worldNormal" type="vec3" prec="mediump" />
	<field name="TEXCOORD3" lname="worldTangent" type="vec3" prec="mediump" />
	<field name="TEXCOORD4" lname="worldBinormal" type="vec3" prec="mediump" />
	<field name="TEXCOORD5" lname="worldPos" type="vec3" prec="highp" />
</output>
<output name="VS_OUTPUT_COLOR">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" prec="mediump" />
	<field name="COLOR" lname="color" type="vec4" prec="lowp" />
</output>

<code><![CDATA[
//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
uniform highp mat4 	mWorld;
uniform highp mat4 	mWorldIT;
uniform highp mat4	mView;
uniform highp mat4 	mWorldViewProjection;
uniform float3      vCameraPosition;

//--------------------------------------------------------------------------------------------------
// Automatic Shadow Parameters
//--------------------------------------------------------------------------------------------------
uniform highp mat4 	mShadowTexture;

//--------------------------------------------------------------------------------------------------
// Automatic Fog Parameters
//--------------------------------------------------------------------------------------------------
uniform mediump vec3  	verticalFogColor;
uniform highp vec2   	verticalFogStartEnd;

//--------------------------------------------------------------------------------------------------
// Automatic Colors Parameters
//--------------------------------------------------------------------------------------------------
uniform mediump vec3   	AmbientColor;
uniform mediump vec3	SelfIllumColor2;

uniform mediump float	RenderIfOccluded;
uniform mediump vec4	ModulateColor;
uniform mediump vec4	SaturateColor;

//--------------------------------------------------------------------------------------------------
// Material Parameters
//--------------------------------------------------------------------------------------------------
uniform mediump vec3   	DiffuseMapModulator;
uniform mediump vec3   	SpecularMapModulator;
uniform mediump vec3   	SelfIllumColor;
uniform mediump float  	SpecularLevel;
uniform mediump float	Shininess;
uniform bool			FlipNormalMapY;

//--------------------------------------------------------------------------------------------------
// Light Parameters
//--------------------------------------------------------------------------------------------------
uniform float4			DirectionalLightVector;
uniform float4			DirectionalLightColor;

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_NOSKIN_INPUT vIn)
{
	VS_OUTPUT Out;

	Out.position = mul(vIn.position0, mWorldViewProjection);
	Out.worldPos = mul(vIn.position0, mWorld).xyz;
#if ENGINE_HAS_SHADOW
	Out.shadtexcoord = mul(vIn.position0, mShadowTexture);
#endif

	//
	// Compute normal in world space
	Out.worldNormal = normalize(mul(vIn.normal0, mat3(mWorldIT)).xyz);

	//
	// Compute tangent in world space
	Out.worldTangent = normalize(mul(vIn.tangent0, mat3(mWorldIT)).xyz);
	if (FlipNormalMapY == true)
	{
		Out.worldTangent = -Out.worldTangent;
	}

	//
	// Compute binormal in world space
	Out.worldBinormal = normalize(mul(vIn.binormal0, mat3(mWorldIT)).xyz);

	//
	// Forward texture coordinates
	Out.texcoord.xy = vIn.texcoord;

	return Out;
}

half4 ComputeDirectionalLightParams(
        in  float3      world_position,
        in  half3      world_normal,
        in  half3      view_vector,
        in  half 		shininess,
        in  half3      light_vector,
        in  half3      light_diffuse )
{
#ifdef USE_SPECULAR_MAP
		half2 lighting         = BlinnFactor(world_normal, -light_vector, view_vector, shininess);
		return( vec4(light_diffuse * lighting.x, ComputeLuminance(light_diffuse) * lighting.y) );
#else
		half lighting         = BlinnFactor(world_normal, -light_vector);
		return( vec4(light_diffuse * lighting, 0 ));
#endif
}

float4 ps(VS_OUTPUT vIn)
{
	//
	// Get the normal from the normal map
	float3 normalMapTexel = UnpackNormalMap(NormalMapSampler, vIn.texcoord.xy);

	//
	// Compute normal map
	float3 world_normal = ApplyNormalMapping(normalMapTexel, vIn.worldTangent, vIn.worldBinormal, vIn.worldNormal);
	half shininess = Shininess / 128.0;

	float3 world_position = vIn.worldPos;

	//
	// Camera/World Vector
	half3 view_vector = normalize(vCameraPosition - world_position);

	//
	// Directionnal Light
	half4 dlp = ComputeDirectionalLightParams(
            world_position, 
            world_normal, 
            view_vector, 
            shininess, 
            DirectionalLightVector.xyz,
            DirectionalLightColor.rgb);

	//
	// Get the diffuse color from the diffuse map
	float3 diffuseMapTexel = tex2D(DiffuseMapSampler, vIn.texcoord.xy).rgb * DiffuseMapModulator;

#if USE_SPECULAR_MAP
	//
	// Get the specular color from the specular map
	float3 specularMapTexel = tex2D(SpecularMapSampler, vIn.texcoord.xy).rgb * SpecularMapModulator;
#endif

	float3 diffuse_color = dlp.xyz;
	mediump float specular_factor = dlp.w;

	//
	// Final color
	float3 C = AmbientColor;

#if USE_SPECULAR_MAP
	//
	// Compute Blinn
	C += Blinn(diffuseMapTexel, diffuse_color, specularMapTexel, SpecularLevel, vec2(1.0,specular_factor));
#else
	C += diffuseMapTexel * diffuse_color;
#endif

	//
	// Final color += self illumination term
	C += SelfIllumColor + SelfIllumColor2;

#if ENGINE_HAS_SHADOW
    //
    // Shadow
	C *= ComputeShadow(vIn.shadtexcoord, ShadowMapSampler);
#endif

#if USE_SILHOUETTE
	//
	// Silhouette Effect (Outline, Ghost, Invisibility)
	C = LightingComputeSilhouette(C, vIn.worldPos, normalize(view_vector), mView);
#endif

#if USE_OCCLUDED
	//
	// Modulate + Saturate
	//C *= ModulateColor;	C += SaturateColor;
	C = (1.0 - RenderIfOccluded) * C + RenderIfOccluded * (C * ModulateColor.rgb + SaturateColor.rgb);
#endif

	//
	// Fog
	C = ApplyVFog(C, vIn.worldPos.z, verticalFogColor, verticalFogStartEnd);

    //
    // Alpha channel is used by FXAA
    return FXAALuminance(C);
}

]]></code>

<tech name="Solid">
	<define name="FEATURE_FLAGS" value="15" />
	<vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" />
	<ps name="ps" />
</tech>
<!----
<tech name="SolidSilhouette">
	<define name="FEATURE_FLAGS" value="31" />
	<vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" />
	<ps name="ps" />
</tech>
---->

<tech name="Solid0"><define name="FEATURE_FLAGS" value="0" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid1"><define name="FEATURE_FLAGS" value="1" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid2"><define name="FEATURE_FLAGS" value="2" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid3"><define name="FEATURE_FLAGS" value="3" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid4"><define name="FEATURE_FLAGS" value="4" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid5"><define name="FEATURE_FLAGS" value="5" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid6"><define name="FEATURE_FLAGS" value="6" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid7"><define name="FEATURE_FLAGS" value="7" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid8"><define name="FEATURE_FLAGS" value="8" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid9"><define name="FEATURE_FLAGS" value="9" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid10"><define name="FEATURE_FLAGS" value="10" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid11"><define name="FEATURE_FLAGS" value="11" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid12"><define name="FEATURE_FLAGS" value="12" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid13"><define name="FEATURE_FLAGS" value="13" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid14"><define name="FEATURE_FLAGS" value="14" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid15"><define name="FEATURE_FLAGS" value="15" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<!---
<tech name="Solid16"><define name="FEATURE_FLAGS" value="16" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid17"><define name="FEATURE_FLAGS" value="17" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid18"><define name="FEATURE_FLAGS" value="18" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid19"><define name="FEATURE_FLAGS" value="19" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid20"><define name="FEATURE_FLAGS" value="20" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid21"><define name="FEATURE_FLAGS" value="21" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid22"><define name="FEATURE_FLAGS" value="22" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid23"><define name="FEATURE_FLAGS" value="23" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid24"><define name="FEATURE_FLAGS" value="24" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid25"><define name="FEATURE_FLAGS" value="25" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid26"><define name="FEATURE_FLAGS" value="26" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid27"><define name="FEATURE_FLAGS" value="27" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid28"><define name="FEATURE_FLAGS" value="28" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid29"><define name="FEATURE_FLAGS" value="29" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid30"><define name="FEATURE_FLAGS" value="30" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="Solid31"><define name="FEATURE_FLAGS" value="31" /><vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
---->

</glfx>
<!--- //DiffuseColorSolid.glfx --->

<glfx>

<input name="VS_INPUT">
	<field name="POSITION" lname="position" type="vec4" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
	<field name="TANGENT" lname="tangent" type="vec3" />
	<field name="BINORMAL" lname="binormal" type="vec3" />
	<field name="NORMAL" lname="normal" type="vec3" />
	<field name="COLOR" lname="color" type="vec3" />
</input>

<output name="VS_OUTPUT_VC">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="COLOR" lname="color" type="vec4" prec="mediump" />
</output>

<output name="VS_OUTPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
</output>

<code><![CDATA[

uniform mediump mat4 mWorldViewProjection;
uniform mediump vec4 DiffuseColor;

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT_VC vsVC(VS_INPUT vIn)
{
	VS_OUTPUT_VC vOut;
	vOut.position = vIn.position * mWorldViewProjection;
	vOut.color    = vec4(vIn.color, 1);
	return(vOut);
}

VS_OUTPUT vs(VS_INPUT vIn)
{
	VS_OUTPUT vOut;
	vOut.position = vIn.position * mWorldViewProjection;
	return(vOut);
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
lowp vec4 psVC(VS_OUTPUT_VC vIn)
{
	return(DiffuseColor * vIn.color);
}

lowp vec4 ps(VS_OUTPUT vIn)
{
	return(DiffuseColor);
}

]]></code>

<tech name="DefaultTechnique">
	<vs name="vsVC" input="VS_INPUT" output="VS_OUTPUT_VC" />
	<ps name="psVC" />
</tech>

<tech name="DefaultTechniqueNoVertexColor">
	<vs name="vs" input="VS_INPUT" output="VS_OUTPUT" />
	<ps name="ps" />
</tech>

</glfx><!---
//--------------------------------------------------------------------------------------------------
// Shadow shader for standard material (rev 1)
//--------------------------------------------------------------------------------------------------
--->
<glfx>

<include name="lib/platform.glfxh" />
<include name="lib/skinning.glfxh" />

<output name="VS_OUTPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
</output>

<code><![CDATA[

//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
uniform float4x4 mWorldViewProjection;

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(in VS_NOSKIN_INPUT vIn)
{
	//
	// Output structure declaration
	VS_OUTPUT Out;
	
	//
	// Compute projected position
	Out.position = mul(vIn.position0, mWorldViewProjection);

	return Out;
}

float4 ps(VS_OUTPUT vIn)
{
	return vec4(1,1,1,1);
}

]]></code>

<tech name="Solid">
	<vs name="vs" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" />
	<ps name="ps" />
</tech>

</glfx><!--- // Singletexture.glfx -->
<glfx>
<texture name="TextureMap" />
<texture name="TileSet" />

<sampler name="TextureMapSampler" type="sampler2D">
	<texture>TextureMap</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>NONE</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>
<sampler name="TileSetSampler" type="sampler2D">
	<texture>TileSet</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>NONE</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>

<input name="VS_INPUT">
	<field name="POSITION" lname="position" type="vec2" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
</input>
<input name="VS_INPUT_COLOR">
	<field name="POSITION" lname="position" type="vec2" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
	<field name="COLOR" lname="color" type="vec4" />
</input>
<input name="VS_INPUT_POSITION4">
	<field name="POSITION" lname="position" type="vec4" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
	<field name="COLOR" lname="color" type="vec4" />
</input>

<output name="VS_OUTPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" prec="mediump" />
</output>
<output name="VS_OUTPUT_COLOR">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" prec="mediump" />
	<field name="COLOR" lname="color" type="vec4" prec="lowp" />
</output>

<code><![CDATA[
//
// Transformations parameters
//
uniform highp mat4 WorldViewProjection;

//
// DiffuseColor Color
//
uniform mediump vec4 DiffuseColor;
uniform mediump vec4 SCREEN_SIZE;

uniform mediump vec2	TextureMapSize;
uniform mediump vec2	TileSetSize;

//--------------------------------------------------------------------------------------------------
// 2D elements in clip-space [-1,+1] with position.xy and texcoord.xy
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_INPUT vIn)
{
	VS_OUTPUT	vOut;

	vOut.texcoord = vIn.texcoord;
	vOut.position = vec4(vIn.position,0,1) * WorldViewProjection;

	return vOut;
}

//--------------------------------------------------------------------------------------------------
// 2D elements in screen-space [0,SCREENW/H] with position.xy and texcoord.xy
//--------------------------------------------------------------------------------------------------
VS_OUTPUT_COLOR vs_screenspace(VS_INPUT_COLOR vIn)
{
	VS_OUTPUT_COLOR	vOut;

	vOut.texcoord = vIn.texcoord;
	vOut.color = vIn.color;

	//
	// Compute clip space position from:
	// [0,SCREEN_SIZE.X] to [-1,+1] and [0,SCREEN_SIZE.Y] to [+1,-1] with SCREEN_SIZE.zw = 1.0f / SCREEN_SIZE.xy
	vOut.position.x = -1.0 + vIn.position.x * 2.0 * SCREEN_SIZE.z;
	vOut.position.y = +1.0 - vIn.position.y * 2.0 * SCREEN_SIZE.w;
	vOut.position.z = 0.0;
	vOut.position.w = 1.0;

	return vOut;
}

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT_COLOR vs_position4(VS_INPUT_POSITION4 vIn)
{
	VS_OUTPUT_COLOR	vOut;
	
	vOut.texcoord = vIn.texcoord;
	vOut.color = vIn.color;

	//
	// Compute projected position
	vOut.position = vIn.position * WorldViewProjection;

	return vOut;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
lowp vec4 ps(VS_OUTPUT vIn)
{
	lowp vec4 textureColor = texture2D(TextureMapSampler, vIn.texcoord);
	return textureColor * DiffuseColor;
}

void clip(lowp float x)
{
	if (x < 0.0)
		discard;
}

lowp vec4 GetTiledPixel(mediump vec2 uv)
{
	mediump vec4	tile = texture2D(TextureMapSampler, uv).bgra;			// load the tilemap value
	mediump vec2	tileIndex = (tile.xz * 255.0) + (tile.yw * 255.0 * 256.0);	// convert to integer tile X,Y
	tileIndex = floor(tileIndex + 0.5);							// *exact* integer, please!
	mediump vec2	tileSubUv = uv * TextureMapSize;				// convert UV to pixel index within tilemap; each pixel is a single tile
	tileIndex += fract(tileSubUv);							// the fractional part is added to the tile index to address the correct pixel in the tile
	tileIndex *= 8.0;								// now pixel index in the tileset
	tileIndex /= TileSetSize;							// now UV in the tileset
	return texture2D(TileSetSampler, tileIndex);
}

lowp vec4 ps_tile(VS_OUTPUT vIn)
{
	lowp vec4	textureColor = GetTiledPixel(vIn.texcoord);
	return textureColor * DiffuseColor;
}

lowp vec4 psSC(VS_OUTPUT_COLOR vIn)
{
	lowp vec4 textureColor = texture2D(TextureMapSampler, vIn.texcoord);
	return textureColor * vIn.color;
}

lowp vec4 psSC_tile(VS_OUTPUT_COLOR vIn)
{
	lowp vec4	textureColor = GetTiledPixel(vIn.texcoord);
	return textureColor * vIn.color;
}

lowp vec4 ps3(VS_OUTPUT_COLOR vIn)
{
	lowp vec4 textureColor = texture2D(TextureMapSampler, vIn.texcoord);
	return textureColor * vIn.color * DiffuseColor;
}

lowp vec4 ps3_tile(VS_OUTPUT_COLOR vIn)
{
	lowp vec4 textureColor = GetTiledPixel(vIn.texcoord);
	return textureColor * vIn.color * DiffuseColor;
}

lowp vec4 psPickBuffer(VS_OUTPUT_COLOR vIn)
{
	lowp vec4 textureColor = texture2D(TextureMapSampler, vIn.texcoord);
	clip(textureColor.a - 0.5);
	return DiffuseColor;
}

lowp vec4 psPickBuffer_tile(VS_OUTPUT_COLOR vIn)
{
	lowp vec4 textureColor = GetTiledPixel(vIn.texcoord);
	clip(textureColor.a - 0.5);
	return DiffuseColor;
}

lowp vec4 psFrozen(VS_OUTPUT_COLOR vIn)
{
	lowp vec4 textureColor = texture2D(TextureMapSampler, vIn.texcoord);
	lowp float grayscale = 0.30 * textureColor.r + 0.59 * textureColor.g + 0.11 * textureColor.b;
	grayscale = 0.2 + grayscale * 0.2;
	return vec4(grayscale, grayscale, grayscale, textureColor.a);
}

lowp vec4 psFrozen_tile(VS_OUTPUT_COLOR vIn)
{
	lowp vec4 textureColor = GetTiledPixel(vIn.texcoord);
	lowp float grayscale = 0.30 * textureColor.r + 0.59 * textureColor.g + 0.11 * textureColor.b;
	grayscale = 0.2 + grayscale * 0.2;
	return vec4(grayscale, grayscale, grayscale, textureColor.a);
}

]]></code>

<tech name="DefaultTechnique">
	<vs name="vs" input="VS_INPUT" output="VS_OUTPUT" />
	<ps name="ps" />
</tech>
<tech name="DefaultTechniqueSC">
	<vs name="vs_screenspace" input="VS_INPUT_COLOR" output="VS_OUTPUT_COLOR" />
	<ps name="psSC" />
</tech>
<tech name="DefaultTechnique3">
	<vs name="vs_position4" input="VS_INPUT_POSITION4" output="VS_OUTPUT_COLOR" />
	<ps name="ps3" />
</tech>
<tech name="DefaultTechniquePickBuffer">
	<vs name="vs_position4" input="VS_INPUT_POSITION4" output="VS_OUTPUT_COLOR" />
	<ps name="psPickBuffer" />
</tech>
<tech name="DefaultTechniqueFrozen">
	<vs name="vs_position4" input="VS_INPUT_POSITION4" output="VS_OUTPUT_COLOR" />
	<ps name="psFrozen" />
</tech>
<tech name="DefaultTechnique_Tile">
	<vs name="vs" input="VS_INPUT" output="VS_OUTPUT" />
	<ps name="ps_tile" />
</tech>
<tech name="DefaultTechniqueSC_Tile">
	<vs name="vs_screenspace" input="VS_INPUT_COLOR" output="VS_OUTPUT_COLOR" />
	<ps name="psSC_tile" />
</tech>
<tech name="DefaultTechnique3_Tile">
	<vs name="vs_position4" input="VS_INPUT_POSITION4" output="VS_OUTPUT_COLOR" />
	<ps name="ps3_tile" />
</tech>
<tech name="DefaultTechniquePickBuffer_Tile">
	<vs name="vs_position4" input="VS_INPUT_POSITION4" output="VS_OUTPUT_COLOR" />
	<ps name="psPickBuffer_tile" />
</tech>
<tech name="DefaultTechniqueFrozen_Tile">
	<vs name="vs_position4" input="VS_INPUT_POSITION4" output="VS_OUTPUT_COLOR" />
	<ps name="psFrozen_tile" />
</tech>
</glfx>

<!--- // Singletexture.glfx -->
<glfx>

<input name="VS_INPUT">
	<field name="POSITION" lname="position" type="vec4" />
<!--	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
	<field name="TANGENT" lname="tangent" type="vec3" />
	<field name="BINORMAL" lname="binormal" type="vec3" />
	<field name="NORMAL" lname="normal" type="vec3" /> -->
	<field name="COLOR" lname="color" type="vec4" />
</input>

<output name="VS_OUTPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="COLOR" lname="color" type="vec4" prec="mediump" />
</output>

<code><![CDATA[
//--------------------------------------------------------------------------------------------------
// Pick buffer
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
// Parameters
//--------------------------------------------------------------------------------------------------
uniform highp mat4  	mWorldViewProjection;
uniform mediump vec4	DiffuseColor;

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_INPUT vIn)
{
	VS_OUTPUT vOut;
	vOut.position = vIn.position * mWorldViewProjection;
	vOut.color    = vIn.color;
	return(vOut);
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
lowp vec4 ps(VS_OUTPUT vIn)
{
	return(DiffuseColor * vIn.color);
}

]]></code>

<tech name="DefaultTechnique">
	<vs name="vs" input="VS_INPUT" output="VS_OUTPUT" />
	<ps name="ps" />
</tech>
</glfx>
<!--- // entity_standard_nd.glfx -->
<glfx>

<include name="lib/platform.glfxh" />
<include name="lib/lighting.glfxh" />
<include name="lib/skinning.glfxh" />

<texture name="NormalMap" />
<sampler name="NormalMapSampler" type="sampler2D">
	<texture>NormalMap</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>LINEAR</mip>
	<wrapu>REPEAT</wrapu><wrapv>REPEAT</wrapv>
</sampler>

<output name="VS_OUTPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="TEXCOORD0" lname="texcoord_depth" type="vec4" prec="highp" />
	<field name="TEXCOORD1" lname="worldNormal" type="vec4" prec="mediump" />
	<field name="TEXCOORD2" lname="worldTangent" type="vec3" prec="mediump" />
	<field name="TEXCOORD3" lname="worldBinormal" type="vec3" prec="mediump" />
</output>

<code><![CDATA[
//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
uniform float4x4 mWorldIT;
uniform float4x4 mWorldViewProjection;

//--------------------------------------------------------------------------------------------------
// Material Parameters
//--------------------------------------------------------------------------------------------------
mediump float    Shininess;
uniform bool 	 FlipNormalMapY;



//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs_noskin(VS_NOSKIN_INPUT vIn)
{
	VS_OUTPUT Out;

	Out.position = mul(vIn.position0, mWorldViewProjection);
	float2 depth = Out.position.zw;

	//
	// Compute normal in world space
	Out.worldNormal.xyz = normalize(mul(vIn.normal0, mat3(mWorldIT)).xyz);

	//
	// Compute tangent in world space
	Out.worldTangent = normalize(mul(vIn.tangent0, mat3(mWorldIT)).xyz);
	if (FlipNormalMapY == true)
	{
		Out.worldTangent = -Out.worldTangent;
	}

	//
	// Compute binormal in world space
	Out.worldBinormal = normalize(mul(vIn.binormal0, mat3(mWorldIT)).xyz);

	//
	// Forward texture coordinates
	Out.texcoord_depth.xy = vIn.texcoord;
	Out.texcoord_depth.zw = depth;
	Out.worldNormal.w = Shininess / 128.0;

	return Out;
}
VS_OUTPUT vs_skin(VS_SKIN_INPUT vIn)
{
	VS_OUTPUT Out;

	skin(vIn);
	Out.position = mul(vIn.position0, mWorldViewProjection);
	float2 depth = Out.position.zw;
	//
	// Compute normal in world space
	Out.worldNormal.xyz = normalize(mul(vIn.normal0, mat3(mWorldIT)).xyz);

	//
	// Compute tangent in world space
	Out.worldTangent = normalize(mul(vIn.tangent0, mat3(mWorldIT)).xyz);
	if (FlipNormalMapY == true)
	{
		Out.worldTangent = -Out.worldTangent;
	}

	//
	// Compute binormal in world space
	Out.worldBinormal = normalize(mul(vIn.binormal0, mat3(mWorldIT)).xyz);

	//
	// Forward texture coordinates
	Out.texcoord_depth.xy = vIn.texcoord;
	Out.texcoord_depth.zw = depth;
	Out.worldNormal.w = Shininess / 128.0;

	return Out;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn)
{
	//
	// Get the normal from the normal map
	float3 normalMapTexel = UnpackNormalMap(NormalMapSampler, vIn.texcoord_depth.xy);

	//
	// Compute normal map
	float3 N = ApplyNormalMapping(normalMapTexel, vIn.worldTangent, vIn.worldBinormal, vIn.worldNormal.xyz);
	
	//
	// Pack the outputs into RGBA8
	return vec4(N * 0.5 + 0.5, vIn.worldNormal.w);
}

]]></code>

<tech name="Solid">
	<vs name="vs_noskin" input="VS_NOSKIN_INPUT" output="VS_OUTPUT" />
	<ps name="ps" />
</tech>

<!----
<tech name="SolidSkinning">
	<vs name="vs_skin" input="VS_SKIN_INPUT" output="VS_OUTPUT" />
	<ps name="ps" />
</tech>
--->

</glfx>
<!---
//--------------------------------------------------------------------------------------------------
// Particle System (rev 2)
//--------------------------------------------------------------------------------------------------
--->
<glfx>

<include name="lib/platform.glfxh" />
<include name="lib/lighting.glfxh" />

<texture name="DiffuseMap" />
<texture name="NormalMap" />
<texture name="Animated1Map" />
<texture name="Animated2Map" />

<sampler name="DiffuseMapSampler" type="sampler2D">
	<texture>DiffuseMap</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>POINT</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>
<sampler name="NormalMapSampler" type="sampler2D">
	<texture>NormalMap</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>POINT</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>
<sampler name="Animated1MapSampler" type="sampler2D">
	<texture>Animated1Map</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>POINT</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>
<sampler name="Animated2MapSampler" type="sampler2D">
	<texture>Animated2Map</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>POINT</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>

<input name="VS_INPUT">
	<field name="POSITION" lname="position" type="vec3" />
	<field name="COLOR" lname="color" type="vec4" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
</input>

<output name="VS_OUTPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="COLOR" lname="color" type="vec4" prec="mediump" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" prec="highp" />
</output>

<output name="VS_NORMALMAP_OUTPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="COLOR" lname="color" type="vec4" prec="mediump" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" prec="highp" />
	<field name="TEXCOORD1" lname="Ldir" type="vec3" prec="highp" />
	<field name="TEXCOORD2" lname="Vdir" type="vec3" prec="highp" />
</output>

<code><![CDATA[
//--------------------------------------------------------------------------------------------------
// Constants
//--------------------------------------------------------------------------------------------------
#define Shininess 5.0

//--------------------------------------------------------------------------------------------------
// Parametters
//--------------------------------------------------------------------------------------------------
uniform float4x4	mWorldView;
uniform float4x4	mWorldViewProj;
uniform float4		LightVector;
uniform float4		LightColor;
uniform float4		AnimatedTextureBlendFactor;

//--------------------------------------------------------------------------------------------------
// Vertex shader 
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_INPUT vIn)
{
	VS_OUTPUT vOut;
	
	float4 Pos = vec4(vIn.position, 1.0);
	
	vOut.position = mul( Pos, mWorldViewProj);
	vOut.texcoord = vIn.texcoord;
	vOut.color = vIn.color;
	
        return vOut;
}
VS_NORMALMAP_OUTPUT vs_normalmap(VS_INPUT vIn)
{
	VS_NORMALMAP_OUTPUT vOut;
	
	float4 Pos = vec4(vIn.position, 1.0);
	
	vOut.position = mul( Pos, mWorldViewProj);
	vOut.texcoord = vIn.texcoord;
	vOut.color = vIn.color;
	
        float3 WorldViewPos = mul(Pos, mWorldView).xyz;
        vOut.Ldir = normalize(mul(LightVector.xyz, mat3(mWorldView)) - WorldViewPos);
        vOut.Vdir = normalize(-WorldViewPos);
	
        return vOut;
}


//--------------------------------------------------------------------------------------------------
// Pixel shader 
//--------------------------------------------------------------------------------------------------
float4 lit(half LdotN, half HdotN, half s)
{
	return vec4(1.0, max(LdotN,0.0), step(0.0,LdotN) * max(HdotN,0.0) * s, 1.0);
}

float4 ps(VS_OUTPUT vIn)
{
	float4 texcolor = vIn.color;
#if ANIMMAP
	float4 texcolor1 = tex2D(Animated1MapSampler, vIn.texcoord);
	float4 texcolor2 = tex2D(Animated2MapSampler, vIn.texcoord);
	texcolor *= mix(texcolor1, texcolor2, AnimatedTextureBlendFactor.x);
#else
	texcolor *= tex2D(DiffuseMapSampler, vIn.texcoord);
#endif	
	return texcolor;
}
float4 ps_normalmap(VS_NORMALMAP_OUTPUT vIn)
{
	float4 texcolor = vIn.color;
#if ANIMMAP
	float4 texcolor1 = tex2D(Animated1MapSampler, vIn.texcoord);
	float4 texcolor2 = tex2D(Animated2MapSampler, vIn.texcoord);
	texcolor *= mix(texcolor1, texcolor2, AnimatedTextureBlendFactor.x);
#else
	texcolor *= tex2D(DiffuseMapSampler, vIn.texcoord);
#endif

	float3 normal = UnpackNormalMap(NormalMapSampler, vIn.texcoord);
	float3 H = normalize(vIn.Ldir + vIn.Vdir);
	float4 lighting = lit(dot(vIn.Ldir, normal), dot(H, normal), Shininess);
	texcolor.rgb *= (lighting.y + lighting.z) * LightColor.rgb;

	return texcolor;
}
]]></code>

<tech name="NoNormalNoAnim"><define name="ANIMMAP" value="0" /><vs name="vs" input="VS_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="NormalNoAnim"><define name="ANIMMAP" value="0" /><vs name="vs_normalmap" input="VS_INPUT" output="VS_NORMALMAP_OUTPUT" /><ps name="ps_normalmap" /></tech>
<tech name="NoNormalAnim"><define name="ANIMMAP" value="1" /><vs name="vs" input="VS_INPUT" output="VS_OUTPUT" /><ps name="ps" /></tech>
<tech name="NormalAnim"><define name="ANIMMAP" value="1" /><vs name="vs_normalmap" input="VS_INPUT" output="VS_NORMALMAP_OUTPUT" /><ps name="ps_normalmap" /></tech>

</glfx>
<!--- // forward_rendering_standard.glfx -->
<glfx>

<include name="lib/platform.glfxh"/>

<texture name="DiffuseMap"/>

<sampler name="DiffuseMapSampler" type="sampler2D">
	<texture>DiffuseMap</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>NONE</mip>
	<wrapu>REPEAT</wrapu><wrapv>REPEAT</wrapv>
</sampler>

<input name="VS_INPUT">
	<field name="POSITION" lname="position" type="vec4" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" />
</input>

<output name="VS_OUTPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" prec="mediump" />
</output>

<code><![CDATA[

//--------------------------------------------------------------------------------------------------
// forward_rendering_standard.glfx
//--------------------------------------------------------------------------------------------------

//The camera world view projection matrix
uniform highp mat4 			mWorldViewProjection;

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT VertexShaderFunction(VS_INPUT vInput)
{
	//
	// Output structure declaration
	VS_OUTPUT Out;

	//
	// Texture coords
	Out.texcoord = vInput.texcoord;
	
	// Position is computed from the vertex position multiplied with the view projection matrix
	Out.position = mul(vInput.position, mWorldViewProjection);

	return(Out);
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
lowp vec4 PixelShaderFunction(VS_OUTPUT vInput)
{
	//Return computed texel color
	lowp vec4 textureColor = tex2D(DiffuseMapSampler, vInput.texcoord);
	return textureColor;
}

]]></code>

<tech name="DefaultTechnique"><vs name="VertexShaderFunction" input="VS_INPUT" output="VS_OUTPUT" /><ps name="PixelShaderFunction" /></tech>

</glfx>
<!--- // skybox.glfx -->
<glfx>

<include name="lib/platform.glfxh" />
<include name="lib/lighting.glfxh" />

<texture name="skyTextureMap" />
<sampler name="skyTextureMapSampler" type="sampler2D">
	<texture>skyTextureMap</texture>
	<min>LINEAR</min><mag>LINEAR</mag><mip>POINT</mip>
	<wrapu>CLAMP</wrapu><wrapv>CLAMP</wrapv>
</sampler>

<input name="VS_INPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" prec="mediump" />
</input>

<output name="VS_OUTPUT">
	<field name="POSITION" lname="position" type="vec4" prec="highp" />
	<field name="TEXCOORD0" lname="texcoord" type="vec2" prec="mediump" />
</output>

<code><![CDATA[

	//--------------------------------------------------------------------------------------------------
	// Defines
	//--------------------------------------------------------------------------------------------------
	#define 			MAX_DIRECTIONAL_LIGHT_PER_PASS  1
	#define 			MAX_POINT_LIGHT_PER_PASS        48
	#define 			MAX_SPECIALIZED_LIGHT_PASS      8

	//--------------------------------------------------------------------------------------------------
	// Automatic Parameters
	//--------------------------------------------------------------------------------------------------
	uniform float4x4 	mWorldViewProjection;
	uniform float4x4 	mProjection;
	uniform float4x4 	mView;
	uniform float3		vCameraPosition;
	//uniform int 		iPointLightCount;

	//--------------------------------------------------------------------------------------------------
	// Vertex shader code
	//--------------------------------------------------------------------------------------------------
	VS_OUTPUT VertexShaderFunction(VS_INPUT vInput)
	{
		VS_OUTPUT Out;

		// Rotate into view-space, centered on the camera
		float3 positionVS = mul(vInput.position.xyz, mat3(mView));

		// Transform to clip-space
		Out.position = mul(vec4(positionVS, 1.0f), mProjection);
		Out.position.z = Out.position.w;
		Out.texcoord = vInput.texcoord;
	
		return Out;
	}

	//--------------------------------------------------------------------------------------------------
	// Pixel shader code
	//--------------------------------------------------------------------------------------------------
	float4 PixelShaderFunction(VS_OUTPUT vInput)
	{
		//
		// We get the right texel from the skybox texture cube
		return tex2D(skyTextureMapSampler, vInput.texcoord);
	}

]]></code>

<tech name="DefaultTechnique">
	<vs name="VertexShaderFunction" input="VS_INPUT" output="VS_OUTPUT" />
	<ps name="PixelShaderFunction" />
</tech>

</glfx>