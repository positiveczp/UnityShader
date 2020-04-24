Shader "PostProcess/BoxBlur"{
	Properties{
		_MainTex("MainTex", 2D) = "white"{}
		_BlurRadius("BlurRadius", float) = 0.3
	}

	SubShader{

			CGINCLUDE 

			#include "UnityCG.cginc"
			#define SAMPLE 5

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			half _BlurRadius;

			struct v2f{
				float4 clippos : SV_POSITION;
				half2 uv[SAMPLE] : TEXCOORD0;
			};

			v2f vertHorizontal(appdata_base i){
				v2f o;
				o.clippos = UnityObjectToClipPos(i.vertex);
				
				half2 uv = i.texcoord;
				for(int x = 0; x < SAMPLE; ++x){
					o.uv[x] = uv + half2(x - SAMPLE / 2, 0) *_MainTex_TexelSize * _BlurRadius;
				}
				return o;
			}

			v2f vertVertical(appdata_base i){
				v2f o;
				o.clippos = UnityObjectToClipPos(i.vertex);

				half2 uv = i.texcoord;
				for(int y = 0; y < SAMPLE; ++y){
					o.uv[y] = uv + half2(0, y - SAMPLE / 2) *_MainTex_TexelSize * _BlurRadius;
				}
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				fixed3 finalColor;
				for(int idx = 0; idx < SAMPLE; ++idx){
					finalColor += tex2D(_MainTex, i.uv[idx]).rgb * (1.0f / SAMPLE);
				}
				return fixed4(finalColor, 1.0);
			}

			ENDCG

			Cull Off ZWrite Off ZTest Always
			Pass{
				NAME "BOXBLURHORIZONTAL"
				CGPROGRAM

				#pragma vertex vertHorizontal
				#pragma fragment frag
			
				ENDCG

			}

			Pass{
				NAME "BOXBLURVERTICAL"
				CGPROGRAM

				#pragma vertex vertVertical
				#pragma fragment frag	
			
				ENDCG

			}

		}
	Fallback Off

}

