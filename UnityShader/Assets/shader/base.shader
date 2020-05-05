Shader "Base/diffuse"{
	Properties{
		_Color("Color", Color) = (1.0,1.0,1.0,1.0)
	}
	SubShader{
		Pass{
			CGPROGRAM

			
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			fixed4 _Color;
			struct v2f{
				float4 clippos : SV_POSITION;
				fixed3 color : COLOR;
				fixed2 unit_screenpos : TEXCOORD0;
			};

			//shader代码测试ComputeScreenPos的用法
			v2f vert(appdata_full i){
				v2f o;
				o.clippos = UnityObjectToClipPos(i.vertex);
				o.color = i.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
				float4 screenpos = ComputeScreenPos(o.clippos);
				o.unit_screenpos = screenpos.xy / screenpos.w;
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				fixed3 color = i.color * _Color.rgb;
				fixed2 unit_screenpos = i.unit_screenpos;
				//利用smoothstep实现简单分屏效果，step和smoothstep的区别在于边缘过渡效果
				color = lerp(color, fixed3(1.0,1.0,1.0), smoothstep(0.4,0.6,unit_screenpos.x));
				return fixed4(color, 1.0);
			}

			ENDCG
		}
	}
}

