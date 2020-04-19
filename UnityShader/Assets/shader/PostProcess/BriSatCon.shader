Shader "PostProcess/BriSatCon"{
	Properties{
		_Brightness("Brightness", Float) = 1.0
		_Saturation("Saturation", Float) = 1.0
		_Constrast("Constrast", Float) = 1.0
		_MainTex("MainTex", 2D) = "white"{}
	}

	SubShader{
		Pass{
			ZTest Always Cull Off ZWrite Off 

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			half _Brightness;
			half _Saturation;
			half _Constrast;
			sampler2D _MainTex;
			
			struct v2f{
				float4 clippos : SV_POSITION;
				half2 uv : TEXCOORD0;
			};

			v2f vert(appdata_base i){
				v2f o;
				o.clippos = UnityObjectToClipPos(i.vertex);
				o.uv = i.texcoord;
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				fixed4 renderTex = tex2D(_MainTex, i.uv);

				//brightness
				fixed3 finalColor = renderTex.rgb * _Brightness;
				fixed lum = Luminance(renderTex.rgb);
				fixed3 lumColor = fixed3(lum, lum, lum);
				finalColor = lerp(lumColor, finalColor, _Saturation);
				fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
				finalColor = lerp(avgColor, finalColor, _Constrast);
				return fixed4(finalColor, 1.0);
			}

			ENDCG
		}
	}


}


