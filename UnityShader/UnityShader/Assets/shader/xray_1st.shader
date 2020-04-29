Shader "Advance/Xray_1st"{
	Properties{
		_BodyColor("Body Color", Color) = (1.0,1.0,1.0,1.0)
		_OutlineColor("Outline Color", Color) = (1.0,1.0,1.0,1.0)
	}

	SubShader{
		//第一个pass正常渲染物体
		Pass{

			ZWrite Off
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			
			struct v2f{
				float4 clippos : SV_POSITION;
				
			};

			v2f vert(appdata_full i){
				v2f o;
				o.clippos = UnityObjectToClipPos(i.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				return fixed4(1.0,0.0,0.0,1.0);
			}

			ENDCG
		}
		//第二个pass渲染被遮挡的部分
		Pass{

			ZTest GEqual
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			fixed4 _OutlineColor;
			fixed4 _BodyColor;

			struct v2f{
				float4 clippos : SV_POSITION;
			};

			v2f vert(appdata_full i){
				v2f o;
				o.clippos = UnityObjectToClipPos(i.vertex);
				return o;
			}

			fixed4 frag(v2f i):SV_TARGET{
				return _BodyColor;
			}

			ENDCG
		}
	}
	Fallback Off

}

