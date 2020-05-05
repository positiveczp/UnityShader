Shader "Base/diffuse_vertex"{
	Properties{
		_Diffuse("Diffuse Color", Color) = (1.0,1.0,1.0,1.0)
	}
	SubShader{
		//逐顶点着色需要ForwardBase这个Tag
		Tags{"LightMode" = "ForwardBase"}
		Pass{
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			fixed4 _Diffuse;
			struct v2f{
				float4 clippos : SV_POSITION;
				fixed3 color : TEXCOORD0;
			};

			v2f vert(appdata_full i){
				v2f o;
				o.clippos = UnityObjectToClipPos(i.vertex);
				fixed3 unit_worldnormal = normalize(UnityObjectToWorldNormal(i.normal));
				float4 worldpos = mul(unity_ObjectToWorld, i.vertex);
				fixed3 unit_worldlightdir = normalize(UnityWorldSpaceLightDir(worldpos.xyz));
				o.color = saturate(dot(unit_worldnormal, unit_worldlightdir)) * _Diffuse.xyz * _LightColor0.xyz;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
				o.color += ambient;
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				return fixed4(i.color, 1.0);
			}

			ENDCG
		}
	}
}

