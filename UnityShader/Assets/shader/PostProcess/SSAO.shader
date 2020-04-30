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
		sampler2D _NoiseTex;
		half _SampleRadius;
		half _Bias;
		half _FadeBegin;
		half _FadeEnd;
		half _Constrast;
		int _SamplesCount;
		fixed4 _Samples[MAX_COUNT];
		float4x4 _CameraModelView;
		float4x4 _CameraProjection;
		float4x4 _InverseViewProject;
		half4 _Params1; // Noise Size / Sample Radius / Intensity / Distance
		half4 _Params2; // Bias / Luminosity Contribution / Distance Cutoff / Cutoff Falloff

		struct v2f{
			float4 clippos : SV_POSITION;
			float2 uv : TEXCOORD0;
			// float3 viewposInFar : TEXCOORD1;
		};

		v2f vert(appdata_base i){
			v2f o;
			o.clippos = UnityObjectToClipPos(i.vertex);
			o.uv = i.texcoord;
			// float4 pos = float4(2.0f * o.uv - 1.0f, 1.0f, 1.0f);
			// float4 viewposInFar = mul(_InverseProjectionMatrix, pos);
			// o.viewposInFar = viewposInFar.xyz / viewposInFar.w;
			return o;
		}

		float fade(float distz){
			return saturate((_FadeEnd - distz) / (_FadeEnd - _FadeBegin));
		}

		inline half3 getWSPosition(half2 uv, half depth)
		{
			// Compute world space position from the view depth
			half4 pos = half4(uv.xy * 2.0 - 1.0, depth, 1.0);
			half4 ray = mul(_InverseViewProject, pos);
			return ray.xyz / ray.w;
		}

		inline half3 getWSNormal(half2 uv)
		{
			// Get the view space normal and convert it to world space
			half3 nn = tex2D(_CameraDepthNormalsTexture, uv).xyz * half3(3.5554, 3.5554, 0) + half3(-1.7777, -1.7777, 1.0);
			half g = 2.0 / dot(nn.xyz, nn.xyz);
			half3 vsnormal = half3(g * nn.xy, g - 1.0); // View space
			half3 wsnormal = mul((half3x3)_CameraModelView, vsnormal); // World space
			return wsnormal;
		}

		inline half getDepth(half2 uv)
		{
			#if HIGH_PRECISION_DEPTHMAP_OFF
			return tex2D(_CameraDepthTexture, uv).x;
			#elif HIGH_PRECISION_DEPTHMAP_ON
			// return tex2D(_DepthNormalMapF32, uv).x;
			#endif

			return 0;
	}

		inline half calcAO(half2 tcoord, half2 uv, half3 p, half3 cnorm)
		{
			half2 t = tcoord + uv;
			half depth = getDepth(t);
			half3 diff = getWSPosition(t, depth) - p; // World space
			half3 v = normalize(diff);
			half d = length(diff);
			// return max(0.0, dot(cnorm, v));
			return max(0.0, dot(cnorm, v) - _Params2.x) * (1.0 / (1.0 + d)) * _Params1.z;
		}

		fixed4 frag(v2f i) : SV_TARGET{
			// float4 enc = tex2D(_CameraDepthNormalsTexture, i.uv);
			// float viewlineardepth;
			// float3 viewnormal;
			// //normal 视角空间下[-1, 1]
			// //depth 视角空间下[0, 1]线性深度
			// DecodeDepthNormal(enc, viewlineardepth, viewnormal);
			half depth = getDepth(i.uv);
			half eyeDepth = LinearEyeDepth(depth);
			half3 normal = getWSNormal(i.uv);
			float3 position = getWSPosition(i.uv, depth);

			half radius = max(_Params1.y / eyeDepth, 0.005);
			clip(5000 - eyeDepth); // Skip out of range pixels

			float3 viewpos = position;
			float occlusion = 0.0f;
			float ao = 0.0f;
			for(int idx = 0; idx < _SamplesCount; ++idx){
				// float3 randomdir = _Samples[idx].xyz;
				// randomdir = dot(randomdir, viewnormal) < 0 ? -randomdir : randomdir;
				// float3 sampleviewpos = viewpos + randomdir * _SampleRadius;
				// float4 sampleclippos = mul(_CameraProjection, float4(sampleviewpos, 1.0f));
				// float3 samplendcpos = sampleclippos.xyz / sampleclippos.w;
				// float sampledepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, 0.5*samplendcpos.xy + 0.5);
				// sampledepth = Linear01Depth(sampledepth);
				// sampleviewpos = sampleviewpos * (sampledepth / sampleviewpos.z);


				// float3 dirtosam = normalize(sampleviewpos - viewpos);
				// float distz = viewpos.z - sampleviewpos.z;
				// float ao = max(0.0f, dot(dirtosam, viewnormal)-_Bias) * fade(distz);
				// float ao = sampledepth+_Bias<sampleviewpos.z?1.0:0.0;

				// half2 uv_r = 0.5*samplendcpos.xy + 0.5;
				// uv_r = i.uv + randomdir * _SampleRadius;
				// float3 position_r = getWSPosition(uv_r, tex2D(_CameraDepthTexture, uv_r));
				// float3 dir = normalize(position_r - position_p);
				// float ao = max(0.0f, dot(dir, viewnormal));
				// occlusion += ao;
			}
			#define SAMPLE_NOISE
			#if defined(SAMPLE_NOISE)
				half2 random = normalize(tex2D(_NoiseTex, _ScreenParams.xy * i.uv / _Params1.x).rg * 2.0 - 1.0);
		#endif
			half2 uv = i.uv;
			const half2 CROSS[4] = { half2(1.0, 0.0), half2(-1.0, 0.0), half2(0.0, 1.0), half2(0.0, -1.0) };
			for (int j = 0; j < 4; j++)
			{
			half2 coord1;
			#if defined(SAMPLE_NOISE)
			coord1 = reflect(CROSS[j], random) * radius;
			#else
			// coord1 = CROSS[j];
			coord1 = CROSS[j] * radius;
			#endif

			#if !SAMPLES_VERY_LOW
			half2 coord2 = coord1 * 0.707;
			coord2 = half2(coord2.x - coord2.y, coord2.x + coord2.y);
			#endif
				coord2 = half2(coord2.x - coord2.y, coord2.x + coord2.y);
				ao += calcAO(uv, coord1 * 0.20, position, normal);
				ao += calcAO(uv, coord2 * 0.40, position, normal);
				ao += calcAO(uv, coord1 * 0.60, position, normal);
				ao += calcAO(uv, coord2 * 0.80, position, normal);
				ao += calcAO(uv, coord1, position, normal);
			}
			ao /= 20.0;
			ao = 1 - ao;
			return fixed4(ao, ao, ao, 1.0f);
			// occlusion /= _SamplesCount;
			// float accessible = 1.0f - occlusion;
			// fixed col = pow(accessible, _Constrast);
			// return fixed4(col, col, col, 1.0f);
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




