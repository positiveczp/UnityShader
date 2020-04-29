// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Advance/RimLight"{
    Properties{
        _RimColor("Rim Color", Color) = (1.0,1.0,1.0,1.0)
        _Diffuse("Diffuse Color", Color) = (1.0,0.0,0.0,0.0)
        _MainTex("MainTex", 2D) = "white"{}
        _RimThre("RimThre", Range(0, 1)) = 0.1

    }
    SubShader{
        Tags{"LightMode" = "ForwardBase"}
        Pass{
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _RimColor;
            float _RimThre;
            fixed4 _Diffuse;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct v2f{
                float4 clippos : SV_POSITION;
                float4 worldpos : TEXCOORD1;
                float3 worldnormal : TEXCOORD2;
                float2 uv : TEXCOORD0;
                float4 vertex : TEXCOORD3;
            };

            v2f vert(appdata_full i){
                v2f o;
                o.uv = TRANSFORM_TEX(i.texcoord, _MainTex);
                o.worldpos = mul(unity_ObjectToWorld, i.vertex);
                o.worldnormal = UnityObjectToWorldNormal(i.normal);
                o.clippos = UnityObjectToClipPos(i.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed3 unit_worldnormal = normalize(i.worldnormal);
                fixed3 unit_worldlightdir = normalize(UnityWorldSpaceLightDir(i.worldpos));
                fixed3 unit_worldviewdir = normalize(UnityWorldSpaceViewDir(i.worldpos));
                // fixed3 unit_worldviewdir = normalize(WorldSpaceViewDir(i.vertex));
                fixed NdotL = saturate(dot(unit_worldlightdir, unit_worldnormal));
                //ambient
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz *_Diffuse.xyz;
                //half-lambert
                fixed lambert = 0.5*NdotL + 0.5;
                fixed3 diffuse = lambert * _Diffuse.xyz * _LightColor0.xyz;
                fixed4 MainColor = tex2D(_MainTex, i.uv);
                fixed rimFactor = saturate(dot(unit_worldnormal, unit_worldviewdir));
                fixed3 finalColor = MainColor.xyz * diffuse + ambient;
                //可以通过Mask贴图控制边缘光的部位
                //fixed rimMaskFactor = tex2D(_RimMask, i.st).a;
                //_RimColor.xyz = step(_RimColor.xyz, finalColor, rimMaskFactor);
                // finalColor = lerp(_RimColor.xyz, finalColor, step(_RimThre, rimFactor));
                finalColor = lerp(_RimColor.xyz, finalColor, rimFactor - _RimThre);
                // finalColor = lerp(_RimColor, finalColor, smoothstep(_RimThre-0.05, _RimThre+0.05, rimFactor));
                return fixed4(finalColor, 1.0);
            }

            ENDCG
        }
    }

    Fallback "Diffuse"



}


