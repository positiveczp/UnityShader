Shader "PostProcess/SSR"{
	Properties{
		_MainTex("MainTex", 2D) = "white"{}
	}

	SubShader{

		CGINCLUDE

		#include  "UnityCG.cginc"
		sampler2D _MainTex;
		sampler2D _CameraDepthTexture;
		sampler2D _CameraGBufferTexture2; //normal
		sampler2D _CameraDepthNormalsTexture;
		float4x4 _CameraProjectionMatrix;
		float4x4 _CameraInvProjectionMatrix;
		float4x4 _WorldToCameraMatrix;
		half _Iter;
		half _Thre;
		half _Intensity;
		
		struct v2f{
			float4 clippos : SV_POSITION;
			half2 uv : TEXCOORD0;
			// float3 pos : TEXCOORD1;
		};

		v2f vert(appdata_base i){
			v2f o;
			o.clippos = UnityObjectToClipPos(i.vertex);
			o.uv = i.texcoord;
			// float4 pos = mul(_CameraInvProjectionMatrix, half4(2*o.uv-1, 1, 1));
			// o.pos = pos.xyz / pos.w;
			return o;
		}

		half getDepth(half2 uv){
			half depth = tex2Dlod(_CameraDepthTexture, half4(uv,0,0));
			return depth;
		}

		float3 getViewPosition(half2 uv, half depth){
			float4 clippos = float4(uv, depth, 1.0);
			clippos.xyz = 2.0 * clippos.xyz - 1.0;
			clippos = mul(_CameraInvProjectionMatrix, clippos);
			clippos.xyz /= clippos.w;
			return clippos.xyz;
		}

		half2 getUVFromViewPosition(float3 viewpos){
			float4 clippos = mul(_CameraProjectionMatrix, float4(viewpos, 1.0));
			clippos.xyz /= clippos.w;
			half2 uv = 0.5 * clippos.xy + 0.5;
			return uv;
		}	

		bool IsValidUV(half2 uv){
			return (uv.x > 0 && uv.x < 1 && uv.y > 0 && uv.y < 1);
		}

		bool Raymarch(float3 rayorigin, float3 raydirection, out half2 hituv){
			float3 step = raydirection;
			float3 newpos = rayorigin;
			for(int i = 1; i < _Iter; ++i){
				//newpos = newpos + i * raydirection * 0.1;
				half2 uv = getUVFromViewPosition(newpos);
				if (! IsValidUV(uv)) return false;
				half depth = getDepth(uv);
				depth = LinearEyeDepth(depth);
				half vsdepth = abs(newpos.z);
				//if(vsdepth > depth){
				if(vsdepth > depth && vsdepth < depth + _Thre){
					hituv = uv; 
					return true;
				}
				step *= 1.0 - 0.5 * max(sign(vsdepth - depth), 0.0);
				newpos += step * (sign(depth - vsdepth));
			}
			return false;
		}

		fixed4 frag(v2f i) : SV_TARGET{
			half3 worldnormal = tex2D(_CameraGBufferTexture2, i.uv).rgb * 2.0 - 1.0;
			half3 viewnormal = normalize(mul(_WorldToCameraMatrix, worldnormal));
			half depth = getDepth(i.uv);
			float3 rayorigin = getViewPosition(i.uv, depth);
			viewnormal.z = - viewnormal.z;
			float3 raydirection = normalize(reflect(normalize(rayorigin), viewnormal));
			half2 hituv;
			fixed4 col;
			if(Raymarch(rayorigin, raydirection, hituv)){
				col = _Intensity * fixed4(tex2D(_MainTex, hituv).rgb, 1.0);
			}else{
				col = fixed4(0,0,0,1);
			}
			// return col;
			return col + tex2D(_MainTex, i.uv);
			// return fixed4(viewnormal,1);
		}

		ENDCG

		ZTest Always ZWrite Off ZTest Off
		Pass{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			ENDCG
		}
	}



}

