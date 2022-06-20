#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

#ifndef SHADERGRAPH_PREVIEW
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #if (SHADERPASS != SHADERPASS_FORWARD)
            #undef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
        #endif
#endif

float3 tDiffuse;
float3 tSpecular;
float3 shadowDirF;

// float3 _HeadFoward;
// float3 _HeadRight;
float3 _DotF;
float3 _DotR;
float3 _CastShadow;

//SAMPLE_TEXTURE2D(_TextureReference, sampler_TextureReference);

struct CustomLightingData
{
    float3 positionWS;
    float3 normal;
    float3 normalWS;
    float4 shadowCoord;
    float3 viewDirectionWS;
    
    // float3 albedo;
    float smoothness;
    //Texture2D shadowTex;
    float ambientOcclusion;
    float3 bakedGI;
};

#ifndef SHADERGRAPH_PREVIEW
float3 CalculateDiffuse(CustomLightingData d, Light light)
{
    float3 NdotL = saturate(dot(d.normalWS, light.direction));
    return NdotL;
}

float GetSmoothnessPower(float rawSmoothness)
{
    return exp2(10 * rawSmoothness + 1);
}


float3 CalculateSpecular(CustomLightingData d, Light light, float3 diffuse)
{
    float3 specularDot = saturate(dot(d.normalWS, normalize(light.direction + d.viewDirectionWS)));
    float3 specular = pow(specularDot, GetSmoothnessPower(d.smoothness)) * diffuse;
    float3 radiance = light.color * light.distanceAttenuation * light.shadowAttenuation;
    
    return specular/* * radiance*/;
}

float3 CalculateRadiance(Light light)
{
    float3 radiance = light.color * light.distanceAttenuation * light.shadowAttenuation;
    return radiance;
}

float3 CustomGlobalIllumination(CustomLightingData d)
{
    float3 indirectDiffuse = d.bakedGI;
    return indirectDiffuse;
}

#endif

void SetPreview(CustomLightingData d)
{
    float3 lightDir = float3(0.5,0.5,0);
    tDiffuse = saturate(dot(d.normalWS, lightDir));
}

float3 _DotFStep;
float3 _AngleDir;

void FaceToon_float(float3 HeadFoward, float3 HeadRight, float3 Position, float3 Normal,
    out float3 DotR, out float3 DotFStep, out float3 AngleDir, out float3 CastShadow, out float3 MainLightColor, out float3 GIColor)
{
    CustomLightingData d;
    d.positionWS = Position;

    float3 mainLightColor = float3(0,0,0);
    float3 giColor = float3(0,0,0);
    float3 vertexSH;

    _DotF = float3(1,1,1);
    _DotR = float3(1,1,1);
    _DotFStep = float3(1,1,1);
    _AngleDir = float3(1,1,1);
    _CastShadow = float3(0.5,0.5,0);
    
    #ifdef SHADERGRAPH_PREVIEW
    SetPreview(d);
    
    #else
    float4 positionCS = TransformWorldToHClip(Position);
    #if SHADOWS_SCREEN
    d.shadowCoord = ComputeScreenPos(positionCS);
    #else
    d.shadowCoord = TransformWorldToShadowCoord(Position);
    #endif

    #endif

    #ifndef SHADERGRAPH_PREVIEW
    
    Light mainLight = GetMainLight(d.shadowCoord, d.positionWS, 1);

    _DotF = dot(HeadFoward.xz, mainLight.direction.xz);
    _DotR = dot(HeadRight.xz, mainLight.direction.xz);

    float hRLength = length(HeadRight.xz);
    float mlLength = length(mainLight.direction.xz);

    //빛을 정면에서 받으면 1, 뒤에서 받으면 0
    _DotFStep = step(0, _DotF);
    
    float _RadianAngle = (acos(_DotR / (hRLength * mlLength)) / PI) * 2;
    _AngleDir = (_DotR > 0) ? (1 - _RadianAngle) : (_RadianAngle - 1);
    
    _CastShadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
    _CastShadow = mainLight.shadowAttenuation;
    
    OUTPUT_SH(Normal, vertexSH);
    d.bakedGI = SAMPLE_GI(lightmapUV, vertexSH, Normal);
    giColor = d.bakedGI;
    mainLightColor = mainLight.color;

    #endif

    DotR = _DotR;
    DotFStep = _DotFStep;
    AngleDir = _AngleDir;
    CastShadow = _CastShadow;
    MainLightColor = mainLightColor;
    GIColor = giColor;
}

#endif