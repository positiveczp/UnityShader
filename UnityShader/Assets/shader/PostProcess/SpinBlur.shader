Shader "PostProcess/SpinBlur"{
	Properties{
		_MainTex("MainTex", 2D) = "white"{}
		_BlurRadius("BlurRadius", Float) = 0.3
		_Iter("Iter", Int) = 3
		_ClearRadius("ClearRadius", Float) = 0.2
		_CenterX("CenterX", Float) = 0.5
		_CenterY("CenterY", Float) = 0.5
		_Degree("Degree", Float) = 5.0
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
		float _Degree;

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

		half2 RotateUV(half2 uv, half degree){
			float DegreeInRad = degree * UNITY_PI / 180.0;
			float s = sin(DegreeInRad);
			float c = cos(DegreeInRad);
			float2x2 RotateMatrix = float2x2(c, -s, s, c);
			// uv -= half2(0.5,0.5);
			uv = mul(RotateMatrix, uv);
			// uv += half2(0.5,0.5);
			return uv;
		}

		fixed4 frag(v2f i) : SV_TARGET{
			fixed4 finalColor;
			//由于XY轴不是统一单位长度的，0.5都是相对于所在的轴
			//计算前需要统一单位，然后采样前需要进行逆变换
			_CenterX *= _ScreenParams.x/_ScreenParams.y;
			_Iter = _Degree;
			float degree = _Degree / _Iter;
			for(int idx = 0; idx < _Iter; ++idx){
				i.uv.x *= _ScreenParams.x/_ScreenParams.y;
				half2 dir = i.uv - half2(_CenterX, _CenterY);
				i.uv = RotateUV(dir, degree);
				i.uv = i.uv + half2(_CenterX, _CenterY);
				i.uv.x *= _ScreenParams.y/_ScreenParams.x;
				finalColor += tex2D(_MainTex, i.uv);
			}

			// float DegreeInRad = _Degree * UNITY_PI / 180.0;
			// float s = sin(DegreeInRad);
			// float c = cos(DegreeInRad);
			// float2x2 RotateMatrix = float2x2(c, -s, s, c);
			// finalColor = tex2D(_MainTex, mul(RotateMatrix, i.uv));
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
