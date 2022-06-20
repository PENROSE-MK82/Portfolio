#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

#ifndef SHADERGRAPH_PREVIEW
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #if (SHADERPASS != SHADERPASS_FORWARD)
            #undef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
        #endif
#endif

float3 _Diffuse;
float3 _Specular;
float3 _Color;

struct CustomLightingData
{
    float3 positionWS;
    float3 normalWS;
    float3 viewDirectionWS;
    float4 shadowCoord;
    
    float3 albedo;
    float smoothness;
    float ambientOcclusion;

    float3 bakedGI;
};

float GetSmoothnessPower(float rawSmoothness)
{
    return exp2(10 * rawSmoothness + 1);
}

#ifndef SHADERGRAPH_PREVIEW

float3 CustomGlobalIllumination(CustomLightingData d, Light light)
{
    float3 indirectDiffuse = /*light.color */d.bakedGI /** d.ambientOcclusion*/;
    return indirectDiffuse;
}


float3 CustomLightHandling(CustomLightingData d, Light light)
{
    float3 radiance = light.color * light.distanceAttenuation * light.shadowAttenuation;
    float diffuse = saturate(dot(d.normalWS, light.direction));
    float specularDot = saturate(dot(d.normalWS, normalize(light.direction + d.viewDirectionWS)));
    float specular = pow(specularDot, GetSmoothnessPower(d.smoothness))  * diffuse;
        
    float3 color = d.albedo * radiance * (diffuse + specular) +  d.bakedGI * d.ambientOcclusion;
    return color;
}

float3 CalculateDiffuse(CustomLightingData d, Light light)
{
    float3 NdotL = saturate(dot(d.normalWS, light.direction));
    return NdotL;
}


float3 CalculateSpecular(CustomLightingData d, Light light, float3 diffuse)
{
    float3 specularDot = saturate(dot(d.normalWS, normalize(light.direction + d.viewDirectionWS)));
    float3 specular = pow(specularDot, GetSmoothnessPower(d.smoothness)) * diffuse;
    float3 radiance = light.color * light.distanceAttenuation * light.shadowAttenuation;
    
    return specular/* * radiance*/;
}

float3 CalculateCastShadow(Light light)
{
    float3 castShadow = /*light.color **/ light.distanceAttenuation * light.shadowAttenuation;
    return castShadow;
}


void AddAdditionalLights(CustomLightingData d)
{
    #ifdef _ADDITIONAL_LIGHTS
    int lightsCount = GetAdditionalLightsCount();
    for (int lightI = 0 ; lightI < lightsCount ; lightI++)
    {
        Light light = GetAdditionalLight(lightI, d.positionWS, 1);
        _Diffuse += CalculateDiffuse(d, light);
        _Specular += CalculateSpecular(d, light, _Diffuse);
    }
    #endif
}

#endif

float3 CalculateCustomLighting(CustomLightingData d)
{
    #ifdef SHADERGRAPH_PREVIEW
        float3 lightDir = float3(0.5,0.5,0);
        float3 intensity = saturate(dot(d.normalWS, lightDir)) +
            pow(saturate(dot(d.normalWS, normalize(d.viewDirectionWS + lightDir))), GetSmoothnessPower(d.smoothness));
        return d.albedo * intensity;
        
    #else
        Light mainLight = GetMainLight(d.shadowCoord, d.positionWS, 1);

        float3 color = 0;
        MixRealtimeAndBakedGI(mainLight, d.normalWS, d.bakedGI);
        color = CustomGlobalIllumination(d, mainLight);
        color += CustomLightHandling(d, mainLight);

        #ifdef _ADDITIONAL_LIGHTS
            int lightsCount = GetAdditionalLightsCount();
            for (int lightI = 0 ; lightI < lightsCount ; lightI++)
            {
                Light light = GetAdditionalLight(lightI, d.positionWS, 1);
                color += CustomLightHandling(d, light);
            }
        #endif
    
        return color;
    #endif
}

void SetPreview(CustomLightingData d)
{
    float3 lightDir = float3(0.5,0.5,0);
    _Diffuse = saturate(dot(d.normalWS, lightDir));
    _Specular = pow(saturate(dot(d.normalWS, normalize(d.viewDirectionWS + lightDir))), GetSmoothnessPower(d.smoothness));
    d.shadowCoord = 0;
    d.bakedGI = 0;
}

void CelShading_float(float3 Position, float3 Normal, float3 ViewDirection,
    float3 Albedo, float Smoothness, float AmbientOcclusion, float2 LightmapUV,
    out float3 Diffuse, out float3 Specular, out float3 Color, out float3 GIColor, out float3 CastShadow, out float3 MainLightColor)
{
    CustomLightingData d;
    d.positionWS = Position;
    d.normalWS = Normal;
    d.albedo = Albedo;
    d.viewDirectionWS = ViewDirection;
    d.smoothness = Smoothness;
    d.ambientOcclusion = AmbientOcclusion;
    
    #ifdef SHADERGRAPH_PREVIEW
    SetPreview(d);
    #else
        float4 positionCS = TransformWorldToHClip(Position);
        #if SHADOWS_SCREEN
            d.shadowCoord = ComputeScreenPos(positionCS);
        #else
            d.shadowCoord = TransformWorldToShadowCoord(Position);
        #endif

    float3 lightmapUV;
    OUTPUT_LIGHTMAP_UV(LightmapUV, unity_LightmapST, lightmapUV);

    float3 vertexSH;
    OUTPUT_SH(Normal, vertexSH);
    d.bakedGI = SAMPLE_GI(lightmapUV, vertexSH, Normal);
    #endif

    float3 giColor = (1,1,1);
    float3 castShadow = (1,1,1);
    float3 mainLightColor = (1,1,1);
        
    #ifndef SHADERGRAPH_PREVIEW
    
    Light mainLight = GetMainLight(d.shadowCoord, d.positionWS, 1);
    
    _Diffuse = CalculateDiffuse(d, mainLight);
    _Specular = CalculateSpecular(d, mainLight, _Diffuse);
    Color = float3 (1,1,1);
    CastShadow = float3 (1,1,1);
    
    AddAdditionalLights(d);
    giColor = CustomGlobalIllumination(d, mainLight);
    castShadow = CalculateCastShadow(mainLight);
    mainLightColor = mainLight.color;
    
    #endif

    CastShadow = castShadow;
    Diffuse = _Diffuse * castShadow;
    Specular = _Specular;
    Color = d.albedo;
    GIColor = giColor;
    MainLightColor = mainLightColor;
}

#endif