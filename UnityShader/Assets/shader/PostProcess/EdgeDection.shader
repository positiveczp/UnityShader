Shader "PostProcess/EdgeDection"
{
	Properties{
		_MainTex("MainTex", 2D) = "white"{}
		_EdgeOnly("EdgeOnly", Float) = 0.0
		_EdgeColor("EdgeColor", Color) = (0.0, 0.0, 0.0, 0.0)
		_BackgroundColor("BackgroundColor", Color) = (1.0, 0.0, 0.0, 0.0)
	}
	SubShader{
		Pass{
			ZTest Always ZWrite Off Cull Off
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _CameraDepthNormalsTexture;
			half4 _MainTex_TexelSize;
			fixed _EdgeOnly;
			fixed4 _EdgeColor;
			fixed4 _BackgroundColor;

			struct v2f{
				float4 clippos : SV_POSITION;
				float2 uv[9] : TEXCOORD0;
			};

			v2f vert(appdata_base i){
				v2f o;
				o.clippos = UnityObjectToClipPos(i.vertex);
				half2 uv = i.texcoord;

				int index = 0;
				for(int x = -1; x<=1; ++x){
					for(int y = -1; y<=1; ++y){
						o.uv[index] = uv + _MainTex_TexelSize.xy * half2(x, y);
						index += 1;
					}
				}

				return o;
			}

			half Sobel(v2f i){
				const half Gx[9] = {
					-1, -2, -1,
					0, 0, 0,
					1, 2, 1,
				};
				const half Gy[9] = {
					-1, 0, 1,
					-2, 0, 2,
					-1, 0, 1
				};

				half edgeX = 0.0f;
				half edgeY = 0.0f;

				for(int idx = 0; idx < 9; ++idx){
					fixed lum = Luminance(tex2D(_MainTex, i.uv[idx]));
					edgeX += lum * Gx[idx];
					edgeY += lum * Gy[idx];
				}
				return abs(edgeX) + abs(edgeY);
			}


			fixed4 frag(v2f i) : SV_TARGET{
				half edge = Sobel(i);
				fixed4 finalColor = tex2D(_MainTex, i.uv[4]);
				finalColor = lerp(finalColor, _BackgroundColor, _EdgeOnly);
				finalColor = lerp(finalColor, _EdgeColor, edge);
				// return finalColor;

				float depth;
				half3 normal;
				float4 enc = tex2D(_CameraDepthNormalsTexture, i.uv[4]);
				DecodeDepthNormal(enc, depth, normal);
				depth = DecodeFloatRG(enc.zw);
				// return fixed4(normal * 0.5 + 0.5, 1.0);
				return fixed4(depth, depth, depth, 1.0);

			}




			
			ENDCG
		}
	}

}
