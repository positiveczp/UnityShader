Shader "Base/diffuse_pixel"{
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
				float3 worldnormal : TEXCOORD1;
				float3 worldpos : TEXCOORD2;
			};

			v2f vert(appdata_full i){
				v2f o;
				o.clippos = UnityObjectToClipPos(i.vertex);
				o.worldnormal = UnityObjectToWorldNormal(i.normal);
				o.worldpos = mul(unity_ObjectToWorld, i.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				fixed3 unit_worldnormal = normalize(i.worldnormal);
				fixed3 unit_worldlightdir = normalize(UnityWorldSpaceLightDir(i.worldpos));
				fixed3 color = saturate(dot(unit_worldnormal, unit_worldlightdir)) * _Diffuse.xyz * _LightColor0.xyz;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
				color += ambient;
				return fixed4(color, 1.0);
			}

			ENDCG
		}
	}
}

