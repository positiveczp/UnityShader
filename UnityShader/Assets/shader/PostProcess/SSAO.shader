Shader "PostProcess/SSAO"{
	Properties{
		_MainTex("MainTex", 2D) = "white"{}
	}

	SubShader{
		CGINCLUDE

		#include "UnityCG.cginc"
		#define MAX_COUNT 32
		sampler2D _MainTex;
		sampler2D _CameraDepthNormalsTexture;
		sampler2D _CameraDepthTexture;
		float4x4 _InverseProjectionMatrix;
		float4x4 _ProjectionMatrix;
		half _SampleRadius;
		half _FadeBegin;
		half _FadeEnd;
		half _Constrast;
		half _Threshold;
		int _SamplesCount;
		fixed4 _Samples[MAX_COUNT];

		struct v2f{
			float4 clippos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float3 viewposInFar : TEXCOORD1;
		};

		v2f vert(appdata_base i){
			v2f o;
			o.clippos = UnityObjectToClipPos(i.vertex);
			o.uv = i.texcoord;
			float4 pos = float4(2.0f * o.uv - 1.0f, 1.0f, 1.0f);
			float4 viewposInFar = mul(_InverseProjectionMatrix, pos);
			o.viewposInFar = viewposInFar.xyz / viewposInFar.w;
			return o;
		}

		float Invlinear(float distz){
			// if(distz < _Threshold) return 0.0f;
			return saturate((_FadeEnd - distz) / (_FadeEnd - _FadeBegin));
		}

		fixed4 frag(v2f i) : SV_TARGET{
			float4 enc = tex2D(_CameraDepthNormalsTexture, i.uv);
			float viewlineardepth;
			float3 viewnormal;
			//normal 视角空间下[-1, 1]
			//depth 视角空间下[0, 1]线性深度
			DecodeDepthNormal(enc, viewlineardepth, viewnormal);
			// viewlineardepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, 0.5*i.uv + 0.5);
			// viewlineardepth = LinearEyeDepth(viewlineardepth);
			float3 viewpos = i.viewposInFar * viewlineardepth;//p
			float occlusion = 0.0f;
			for(int idx = 0; idx < _SamplesCount; ++idx){
				float3 randomdir = _Samples[idx].xyz;
				randomdir = dot(randomdir, viewnormal) < 0 ? -randomdir : randomdir;
				float3 sampleviewpos = viewpos + randomdir * _SampleRadius;//q
				// float4 sampleclippos = mul(unity_CameraProjection, float4(sampleviewpos, 1.0));
				float4 sampleclippos = mul(_ProjectionMatrix, float4(sampleviewpos, 1.0f));
				float3 samplendcpos = sampleclippos.xyz / sampleclippos.w;
				float sampledepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, 0.5*samplendcpos.xy + 0.5);
				sampledepth = LinearEyeDepth(sampledepth);
				float3 pos_r = sampleviewpos * (sampledepth / sampleviewpos.z);//r
				float3 dirtosam = normalize(pos_r - viewpos);
				float distz = length(pos_r - viewpos);
				float ao = max(0.0f, dot(dirtosam, normalize(viewnormal)) - _Threshold) * (1/(1+distz))*_FadeEnd;
				// float ao = sampledepth+_Threshold>sampleviewpos.z?1.0:0.0;
				occlusion += ao;
			}
			occlusion /= _SamplesCount;
			float accessible = 1.0f - occlusion;
			fixed col = pow(accessible, _Constrast);
			return fixed4(col, col, col, 1.0f);
		}

		ENDCG

		Cull Off ZTest Always ZWrite Off
		Pass{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			ENDCG
		}
	}
	Fallback Off

}




