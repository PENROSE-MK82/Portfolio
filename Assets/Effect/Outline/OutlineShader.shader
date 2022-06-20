Shader "Custom/StudyConvert"
{
    Properties 
	{
	    _MainTex ("Main Texture", 2D) = "white" {}
		_Intensity("Intensty", Range(0,1)) = 0.1
		_OverlayColor("Color", Color) = (0.1, 0.2, 0.3, 1)
		_Scale("Scale", Range(0,10)) = 0.1
		_DepthThreshold("Depth threshold", float) = 1.5
		_NormalThreshold("Normal threshold", float) = 1.5
		_Color("Color", color) = (1,1,1,1)
	}
	SubShader 
	{
		//Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
		Cull Off ZWrite Off ZTest Always
		Pass
		{
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
			
            
			#pragma vertex vert
			#pragma fragment frag
			
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

			float _Intensity;
            float4 _OverlayColor;
			float _Scale;
            float4 _MainTex_TexelSize;
            float _DepthThreshold;
            float _NormalThreshold;
			float4 _Color;
			float4x4 _ClipToView;
            float4x4 _CameraMatrix;
            
            struct Attributes
            {
                float4 vertex       : SV_POSITION;
            	half3 normal        : NORMAL;
            };

            struct Varyings
            {
                float2 texcoord       : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float4 alphaBlend(float4 edgeColor, float4 texColor)
			{
				float3 color = (edgeColor.rgb * edgeColor.a) + (texColor.rgb * (1 - edgeColor.a));
				float alpha = edgeColor.a + texColor.a * (1 - edgeColor.a);

				return float4(color, alpha);
			}

			float2 TransformTriangleVertexToUV(float2 vertex)
			{
			    float2 uv = (vertex + 1.0) * 0.5;
			    return uv;
			}
            
			Varyings vert(Attributes input)
			{
				Varyings o;
            	VertexPositionInputs vertexInput = GetVertexPositionInputs(input.vertex.xyz);

            	o.vertex = float4(vertexInput.positionCS);
            	o.texcoord = input.vertex.xy;
            	
				return o;	
			}
            
            float4 frag (Varyings input) : SV_Target 
            {
				float halfScaleFloor = floor(_Scale * 0.5);
				float halfScaleCeil = ceil(_Scale * 0.5);

				float2 bottomLeftUV = input.texcoord - float2(_MainTex_TexelSize.x, _MainTex_TexelSize.y) * halfScaleFloor;
				float2 topRightUV = input.texcoord + float2(_MainTex_TexelSize.x, _MainTex_TexelSize.y) * halfScaleCeil;  
            	float2 bottomRightUV = input.texcoord + float2(_MainTex_TexelSize.x * halfScaleCeil, -_MainTex_TexelSize.y * halfScaleFloor);
				float2 topLeftUV = input.texcoord + float2(-_MainTex_TexelSize.x * halfScaleFloor, _MainTex_TexelSize.y * halfScaleCeil);
            	
				float depthBL = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, bottomLeftUV).r;
				float depthTR = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, topRightUV).r;
				float depthBR = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, bottomRightUV).r;
				float depthTL = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, topLeftUV).r;
            	
				float3 normalBL = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, bottomLeftUV).rgb;
				float3 normalTR = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, topRightUV).rgb;
				float3 normalBR = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, bottomRightUV).rgb;
				float3 normalTL = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, topLeftUV).rgb;
       	
            	float depthD0 = depthTR - depthBL;
            	float depthD1 = depthTL - depthBR;
            	
				float edgeDepth = sqrt(depthD0 * depthD0 + depthD1 * depthD1) * 100;
            	
				float depthThreshold = _DepthThreshold * depthBL;
            	edgeDepth = edgeDepth > depthThreshold ? 1 : 0;
	   
				float3 normalD0 = normalTR - normalBL;
				float3 normalD1 = normalTL - normalBR;
	   
				float edgeNormal = sqrt(dot(normalD0, normalD0) + dot(normalD1, normalD1));
				edgeNormal = edgeNormal > _NormalThreshold ? 1 : 0;
				float edge = max(edgeDepth, edgeNormal);
    
            	float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.texcoord);
             	float4 edgeColor = float4(color * _Color.rgb , _Color.a * edge);
            	
				return alphaBlend(edgeColor, color);
            }
            
			ENDHLSL
		}
	} 

}