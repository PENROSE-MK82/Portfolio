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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
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
                //float2 uv               : TEXCOORD0;
            	half3 normal        : NORMAL;
            };

            struct Varyings
            {
            	//float3 objectDir : TEXCOORD3;
            	float3 viewSpaceDir : TEXCOORD2;
            	float3 texcoordStereo : TEXCOORD1;
                float2 texcoord       : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            	#if STEREO_INSTANCING_ENABLED
				uint stereoTargetEyeIndex : SV_RenderTargetArrayIndex;
				#endif
            };

            float4 alphaBlend(float4 top, float4 bottom)
			{
				float3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a));
				float alpha = top.a + bottom.a * (1 - top.a);

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
            	o.vertex = float4(input.vertex.xy, 0 ,0);
            	o.texcoord = TransformTriangleVertexToUV(input.vertex.xy);
            	
            	//o.vertex = float4(vertexInput.positionCS);
            	o.viewSpaceDir = mul(_ClipToView, o.vertex).xyz;
            	//o.viewSpaceDir = mul(_ClipToView, float4(1,1,1,1)).xyz;
            	//o.texcoord = input.uv;

            	o.vertex = float4(vertexInput.positionCS);
				//o.vertex = float4(input.positionOS.xy, 0.0, 1.0);
				//
            	//o.texcoord = TransformWorldToObject(vertexInput.positionCS);
            	
            	o.texcoord = input.vertex.xy;
            	
            	o.texcoordStereo = TransformWorldToObject(input.normal); 
			#if UNITY_UV_STARTS_AT_TOP
				//o.texcoord = o.texcoord * float2(1.0, -1.0) + float2(0.0, 1.0);
			#endif
			
				//o.texcoordStereo = TransformStereoScreenSpaceTex(o.uv, 1.0);
			
				return o;	
			}
            
            float3 frag (Varyings input) : SV_Target 
            {
				//return input.viewSpaceDir;
            	
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				float halfScaleFloor = floor(_Scale * 0.5);
				float halfScaleCeil = ceil(_Scale * 0.5);

				float2 bottomLeftUV = input.texcoord - float2(_MainTex_TexelSize.x, _MainTex_TexelSize.y) * halfScaleFloor;
				float2 topRightUV = input.texcoord + float2(_MainTex_TexelSize.x, _MainTex_TexelSize.y) * halfScaleCeil;  
            	float2 bottomRightUV = input.texcoord + float2(_MainTex_TexelSize.x * halfScaleCeil, -_MainTex_TexelSize.y * halfScaleFloor);
				float2 topLeftUV = input.texcoord + float2(-_MainTex_TexelSize.x * halfScaleFloor, _MainTex_TexelSize.y * halfScaleCeil);
            	
				float depth0 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, bottomLeftUV).r;
				float depth1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, topRightUV).r;
				float depth2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, bottomRightUV).r;
				float depth3 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, topLeftUV).r;
            	
				float3 normal0 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, bottomLeftUV).rgb;
				float3 normal1 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, topRightUV).rgb;
				float3 normal2 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, bottomRightUV).rgb;
				float3 normal3 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, topLeftUV).rgb;

            	float3 convert = mul(UNITY_MATRIX_V, normal0);
				float3 viewNormal = normal0 * 2 - 1;	
				float NdotV = dot(convert, -input.viewSpaceDir);
	   //
    //         	
            	float depthFiniteDifference0 = depth1 - depth0;
            	float depthFiniteDifference1 = depth3 - depth2;
            	
				float edgeDepth = sqrt(pow(depthFiniteDifference0, 2) + pow(depthFiniteDifference1, 2)) * 100;
            	
				float depthThreshold = _DepthThreshold * depth0;
            	edgeDepth = edgeDepth > depthThreshold ? 1 : 0;
	   
				float3 normalFiniteDifference0 = normal1 - normal0;
				float3 normalFiniteDifference1 = normal3 - normal2;
	   
				float edgeNormal = sqrt(dot(normalFiniteDifference0, normalFiniteDifference0) + dot(normalFiniteDifference1, normalFiniteDifference1));
				edgeNormal = edgeNormal > _NormalThreshold ? 1 : 0;
				float edge = max(edgeDepth, edgeNormal);
    
            	float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.texcoord);
             	float4 edgeColor = float4(color * _Color.rgb , _Color.a * edge);

            	//return convert;
				return alphaBlend(edgeColor, color);
            	//return input.viewSpaceDir;
            	
            }
            
			ENDHLSL
		}
	} 

}