Shader "PostProcess/RadialBlur"{
	Properties{
		_MainTex("MainTex", 2D) = "white"{}
		_BlurRadius("BlurRadius", Float) = 0.3
		_Iter("Iter", Int) = 3
		_ClearRadius("ClearRadius", Float) = 0.2
		_CenterX("CenterX", Float) = 0.5
		_CenterY("CenterY", Float) = 0.5
	}
	SubShader{
		CGINCLUDE

		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		half _BlurRadius;
		int _Iter;
		half _CenterX;
		half _CenterY;
		half _ClearRadius;

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
			fixed4 finalColor;
			half2 dist = half2(_CenterX, _CenterY) - i.uv;
			half2 dir = dist * _BlurRadius;
			fixed sep = step(_ClearRadius, length(dist));
			for(int idx = 0; idx < _Iter; ++idx){
				fixed4 col = lerp(tex2D(_MainTex, i.uv), tex2D(_MainTex, i.uv + dir * half(idx) / _Iter), sep);
				finalColor += col;
			}
			return finalColor/_Iter;
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
