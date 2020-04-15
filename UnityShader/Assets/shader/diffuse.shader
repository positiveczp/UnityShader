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
				fixed3 binormal : TEXCOORD0;
			};

			v2f vert(appdata_full i){
				v2f o;
				o.clippos = UnityObjectToClipPos(i.vertex);
				o.binormal = 0.5 * cross(i.normal, i.tangent.xyz) * i.tangent.w + 0.5;
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				return fixed4(i.binormal, 1.0);
			}

			ENDCG
		}
	}
}

