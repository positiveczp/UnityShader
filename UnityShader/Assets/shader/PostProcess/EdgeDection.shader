Shader "PostProcess/EdgeDection"
{
	Properties{
		_MainTex("MainTex", 2D) = "white"{}
		_EdgeOnly("EdgeOnly", Float) = 0.0
		_EdgeColor("EdgeColor", Color) = (0.0, 0.0, 0.0, 0.0)
		_BackgroundColor("BackgroundColor", Color) = (1.0, 0.0, 0.0, 0.0)
		_DepthThres("DepthThres", Float) = 0.1
		_NormalThres("NormalThres", Float) = 0.1
	}
	SubShader{
			CGINCLUDE

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _CameraDepthNormalsTexture;
			sampler2D _CameraDepthTexture;
			half4 _MainTex_TexelSize;
			fixed _EdgeOnly;
			fixed4 _EdgeColor;
			fixed4 _BackgroundColor;
			float _DepthThres;
			float _NormalThres;

			struct v2f{
				float4 clippos : SV_POSITION;
				float2 uv[5] : TEXCOORD0;
			};

			v2f vert(appdata_base i){
				v2f o;
				o.clippos = UnityObjectToClipPos(i.vertex);
				half2 uv = i.texcoord;
				o.uv[0] = uv + half2(-1, -1) * _MainTex_TexelSize.xy;
				o.uv[1] = uv + half2(1, 1) * _MainTex_TexelSize.xy;
				o.uv[2] = uv + half2(-1, 1) * _MainTex_TexelSize.xy;
				o.uv[3] = uv + half2(1, -1) * _MainTex_TexelSize.xy;
				o.uv[4] = uv;

				return o;
			}

			fixed CheckEdge(fixed4 sample1, fixed4 sample2){
				half2 sample1Normal = sample1.xy;
				half2 sample2Normal = sample2.xy;
				half sample1Depth = sample1.zw;
				half sample2Depth = DecodeFloatRG(sample2.zw);

				half2 diffNormal = abs(sample1Normal - sample2Normal) * _NormalThres;
				half diffDepth = abs(sample1Depth - sample2Depth) * _DepthThres;
				fixed isSameNormal = (diffNormal.x + diffNormal.y) < 0.1;
				fixed isSameDepth = diffDepth < 0.1;

				return isSameDepth * isSameNormal ? 1.0 : 0.0;
			}


			fixed4 frag(v2f i) : SV_TARGET{
				// fixed4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[0]);
				// fixed4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[1]);
				// fixed4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);
				// fixed4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);

				// fixed IsNotEdge = 1.0;
				// IsNotEdge *= CheckEdge(sample1, sample2);
				// IsNotEdge *= CheckEdge(sample3, sample4);

				// fixed4 finalColor = lerp(tex2D(_MainTex, i.uv[4]), _BackgroundColor, _EdgeOnly);
				// finalColor = lerp(_EdgeColor, finalColor, IsNotEdge);

				float depth = DecodeFloatRG(tex2D(_CameraDepthNormalsTexture, i.uv[4]).zw);
				float3 normal;
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.uv[4]), depth, normal);
				depth = tex2D(_CameraDepthTexture, i.uv[4]).r;
				depth = Linear01Depth(depth);
				// fixed4 finalColor = fixed4(depth, depth, depth, 1.0);
				finalColor = fixed4(1,1,1,1);
				return finalColor;

			}

			ENDCG

			Pass{
				ZWrite Off Cull Off ZTest Always
				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag


				ENDCG
			}
	}

}
