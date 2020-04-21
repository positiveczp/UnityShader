Shader "PostProcess/GaussianBlur"{
	Properties{
		_MainTex("MainTex", 2D) = "white"{}
		_BlurRadius("BlurRadius", Float) = 0.5
	}
	SubShader{
		CGINCLUDE

		#include "UnityCG.cginc"
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		half _BlurRadius;
		
		struct v2f{
			float4 clippos : SV_POSITION;
			half2 uv[5] : TEXCOORD0;
		};

		v2f vertHorizontal(appdata_base i){
			v2f o;
			o.clippos = UnityObjectToClipPos(i.vertex);

			half2 uv = i.texcoord;
			o.uv[0] = uv;
			o.uv[1] = uv + half2(1, 0) * _MainTex_TexelSize *_BlurRadius;
			o.uv[2] = uv + half2(-1, 0) * _MainTex_TexelSize *_BlurRadius;
			o.uv[3] = uv + half2(2, 0) * _MainTex_TexelSize *_BlurRadius;
			o.uv[4] = uv + half2(-2, 0) * _MainTex_TexelSize *_BlurRadius;
			return o;
		}

		v2f vertVertical(appdata_base i){
			v2f o;
			o.clippos = UnityObjectToClipPos(i.vertex);

			half2 uv = i.texcoord;
			o.uv[0] = uv;
			o.uv[1] = uv + half2(0, 1) * _MainTex_TexelSize *_BlurRadius;
			o.uv[2] = uv + half2(0, -1) * _MainTex_TexelSize *_BlurRadius;
			o.uv[3] = uv + half2(0, 2) * _MainTex_TexelSize *_BlurRadius;
			o.uv[4] = uv + half2(0, -2) * _MainTex_TexelSize *_BlurRadius;
			return o;
		}

		fixed4 frag(v2f i) : SV_TARGET{
			half weight[3] = {0.4026, 0.2442, 0.0545};
			fixed3 finalColor = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
			finalColor += tex2D(_MainTex, i.uv[1]).rgb * weight[1];
			finalColor += tex2D(_MainTex, i.uv[2]).rgb * weight[1];
			finalColor += tex2D(_MainTex, i.uv[3]).rgb * weight[2];
			finalColor += tex2D(_MainTex, i.uv[4]).rgb * weight[2];
			return fixed4(finalColor, 1.0);
		}

		ENDCG

		ZTest Always Cull Off ZWrite Off
		Pass{
			NAME "GAUSSIAN_BLUR_HORIZONTAL"
			CGPROGRAM

			#pragma vertex vertHorizontal
			#pragma fragment frag

			ENDCG
		}

		Pass{
			NAME "GAUSSIAN_BLUR_VERTICAL"
			CGPROGRAM

			#pragma vertex vertVertical
			#pragma fragment frag

			ENDCG
		}
	}
	Fallback Off
}


