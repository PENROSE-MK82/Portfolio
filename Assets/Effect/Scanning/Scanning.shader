Shader "Custom/Scan"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_BaseColor("Base Color",Color) = (1,1,1,1)
		_ScanDistance("ScanDistance", Range(0,100)) = 1
		_ScanWidth("_ScanWidth", Range(0, 10)) = 1
	}
	SubShader
	{
		Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }
		Pass
		{
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			sampler2D _MainTex;
			SAMPLER(sampler_MainTex);

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);
			float4 _CameraDepthTexture_TexelSize;
			float4 _BaseColor;
			float _ScanDistance;
			float _ScanWidth;

			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct Varyings
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			Varyings vert(Attributes input)
			{
				Varyings output;

				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
				output.vertex = vertexInput.positionCS;
				output.uv = input.uv;

				return output;
			}

			float4 frag(Varyings input) : SV_Target
			{
				float4 color = tex2D(_MainTex, input.uv);
				float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, input.uv);
				float depth = Linear01Depth(rawDepth, _ZBufferParams);
				float dist = depth * _ProjectionParams.z;
				float l = 0;
				if (dist < _ScanDistance && dist > _ScanDistance - _ScanWidth) {
					float l = (dist - _ScanDistance + _ScanWidth) / _ScanWidth;
					color = color * (1 - l) + _BaseColor * l;
				}
				return color;
			}
			ENDHLSL
		}
	}
	FallBack "Diffuse"
}