Shader "PostProcess/SSAO2"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader{

		CGINCLUDE
		#include "UnityCG.cginc"

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		// sampler2D _SSAOTex;

		sampler2D_float _CameraDepthTexture;
		sampler2D_float _CameraDepthNormalsTexture;
			
		half4x4 _InverseViewProject;
		half4x4 _CameraModelView;

		sampler2D _NoiseTex;
		half4 _Params1; // Noise Size / Sample Radius / Intensity / Distance
		half4 _Params2; // Bias / Luminosity Contribution / Distance Cutoff / Cutoff Falloff
		half4 _OcclusionColor;

		// half2 _Direction;
		// half _BilateralThreshold;

		inline half invlerp(half from, half to, half value)
		{
			return (value - from) / (to - from);
		}

		inline half getDepth(half2 uv)
		{
			// #if HIGH_PRECISION_DEPTHMAP_OFF
			return tex2D(_CameraDepthTexture, uv).x;
			// #elif HIGH_PRECISION_DEPTHMAP_ON
			// return tex2D(_DepthNormalMapF32, uv).x;
			// #endif

			// return 0;
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
			return vsnormal;
		}

		inline half calcAO(half2 tcoord, half2 uv, half3 p, half3 cnorm)
		{
			half2 t = tcoord + uv;
			half depth = getDepth(t);
			half3 diff = getWSPosition(t, depth) - p; // World space
			half3 v = normalize(diff);
			half d = length(diff) * _Params1.w;
			// return max(0.0, dot(cnorm, v));
			return max(0.0, dot(cnorm, v) - _Params2.x) * (1.0 / (1.0 + d)) * _Params1.z;
		}

		half ssao(half2 uv)
		{
			const half2 CROSS[4] = { half2(1.0, 0.0), half2(-1.0, 0.0), half2(0.0, 1.0), half2(0.0, -1.0) };
				
			half depth = getDepth(uv);
			half eyeDepth = LinearEyeDepth(depth);
			
			half3 position = getWSPosition(uv, depth); // World space
			half3 normal = getWSNormal(uv); // World space

			// #if defined(SAMPLE_NOISE)
			half2 random = normalize(tex2D(_NoiseTex, _ScreenParams.xy * uv / _Params1.x).rg * 2.0 - 1.0);
			// #endif

			half radius = max(_Params1.y / eyeDepth, 0.005);
			clip(_Params2.z - eyeDepth); // Skip out of range pixels
			half ao = 0.0;

			// Sampling
			for (int j = 0; j < 4; j++)
			{
				half2 coord1;

				//#if defined(SAMPLE_NOISE)
				coord1 = reflect(CROSS[j], random) * radius;
				//#else
				// coord1 = CROSS[j];
				coord1 = CROSS[j] * radius;
				//#endif

				// #if !SAMPLES_VERY_LOW
				half2 coord2 = coord1 * 0.707;
				coord2 = half2(coord2.x - coord2.y, coord2.x + coord2.y);
				// #endif
	
				#if SAMPLES_ULTRA			// 20
				ao += calcAO(uv, coord1 * 0.20, position, normal);
				ao += calcAO(uv, coord2 * 0.40, position, normal);
				ao += calcAO(uv, coord1 * 0.60, position, normal);
				ao += calcAO(uv, coord2 * 0.80, position, normal);
				ao += calcAO(uv, coord1, position, normal);
				#elif SAMPLES_HIGH			// 16
				ao += calcAO(uv, coord1 * 0.25, position, normal);
				ao += calcAO(uv, coord2 * 0.50, position, normal);
				ao += calcAO(uv, coord1 * 0.75, position, normal);
				ao += calcAO(uv, coord2, position, normal);
				#elif SAMPLES_MEDIUM		// 12
				ao += calcAO(uv, coord1 * 0.30, position, normal);
				ao += calcAO(uv, coord2 * 0.60, position, normal);
				ao += calcAO(uv, coord1 * 0.90, position, normal);
				#elif SAMPLES_LOW			// 8
				ao += calcAO(uv, coord1 * 0.30, position, normal);
				ao += calcAO(uv, coord2 * 0.80, position, normal);
				#elif SAMPLES_VERY_LOW		// 4
				ao += calcAO(uv, coord1 * 0.50, position, normal);
				#endif
			}
			
			#if SAMPLES_ULTRA
			ao /= 20.0;
			#elif SAMPLES_HIGH
			ao /= 16.0;
			#elif SAMPLES_MEDIUM
			ao /= 12.0;
			#elif SAMPLES_LOW
			ao /= 8.0;
			#elif SAMPLES_VERY_LOW
			ao /= 4.0;
			#endif

			// Distance cutoff
			ao = 1 - ao;
			// ao = lerp(1.0 - ao, 1.0, saturate(invlerp(_Params2.z - _Params2.w, _Params2.z, eyeDepth)));

			return ao;
		}

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

		fixed4 frag(v2f i) : SV_TARGET{
			half ao = ssao(i.uv);
			return fixed4(ao, ao, ao, 1.0);
		}


		ENDCG
		Cull Off ZTest Always ZWrite Off
		Pass{
			CGPROGRAM

			#pragma multi_compile SAMPLES_VERY_LOW  SAMPLES_LOW  SAMPLES_MEDIUM  SAMPLES_HIGH  SAMPLES_ULTRA
			#pragma multi_compile HIGH_PRECISION_DEPTHMAP_ON  HIGH_PRECISION_DEPTHMAP_OFF
			#pragma vertex vert
			#pragma fragment frag

			ENDCG
		}

	}
}
