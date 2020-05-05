Shader "PostProcess/fog"
{
	Properties
	{
		_MainTex ("MainTex", 2D) = "white" {}
	}
	SubShader
	{

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 clippos : SV_POSITION;
				float3 viewpos : TEXCOORD1;
			};

			sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			float4 _MainTex_ST;
			fixed4 _FogColor;
			half _MinDist;
			half _MaxDist;
			
			v2f vert (appdata_img i)
			{
				v2f o;
				o.clippos = UnityObjectToClipPos(i.vertex);
				o.uv = TRANSFORM_TEX(i.texcoord, _MainTex);
				half4 pos = half4(2 * o.uv - 1, 1.0, 1.0);
				pos = mul(unity_CameraInvProjection, pos);
				o.viewpos = pos.xyz / pos.w;
				return o;
			}
			
			fixed invlerp(float dist){
				return (dist - _MinDist) / (_MaxDist - _MinDist);
			}

			fixed4 frag (v2f i) : SV_Target
			{
				half depth = Linear01Depth(tex2D(_CameraDepthTexture, i.uv));
				float3 viewpos = i.viewpos * depth;
				viewpos = _WorldSpaceCameraPos + viewpos;
				fixed4 finalColor = tex2D(_MainTex, i.uv);
				fixed k = invlerp((viewpos.y));
				finalColor = lerp(finalColor, _FogColor, saturate(k));
				return finalColor;
			}

			ENDCG
		}
	}
}
