Shader "PostProcess/BoxBlur"{
	Properties{
		_MainTex("MainTex", 2D) = "white"{}
		_BlurNumber("BlurNumber", Int) = 5.0
	}

	SubShader{
		ZWrite Off ZTest Always Cull Off

		Pass{

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			int _BlurNumber;

			struct v2f{
				float4 clippos : SV_POSITION;
				half2 uv[9] : TEXCOORD0;
			};

			v2f vert(appdata_base i){
				v2f o;
				o.clippos = UnityObjectToClipPos(i.vertex);
				
				half2 uv = i.texcoord;
				int idx = 0;
				for (int x = -1; x <= 1; ++x){
					for(int y = -1; y <= 1; ++y){
						o.uv[idx] = uv + half2(x, y) * _MainTex_TexelSize;
						idx += 1;
					}
				}
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{


				return fixed4(tex2D(_MainTex, i.uv[4]));
			}

			ENDCG
		}
	}
	Fallback Off

}

