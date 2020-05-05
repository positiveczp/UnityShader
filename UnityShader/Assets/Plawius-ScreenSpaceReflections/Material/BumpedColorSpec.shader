Shader "Demo/Bumped Specular Map" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_SpecMap ("Spec map", 2D) = "white" {}
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
	_Shininess ("Shininess", Range (0.03, 1)) = 0.078125
}
SubShader { 
	Tags { "RenderType"="Opaque" }
	LOD 400
	
CGPROGRAM
#pragma surface surf BlinnPhong alphatest:_Cutoff


sampler2D _MainTex;
sampler2D _BumpMap;
sampler2D _SpecMap;
fixed4 _Color;
half _Shininess;

struct Input {
	float2 uv_MainTex;
	float2 uv_BumpMap;
};

void surf (Input IN, inout SurfaceOutput o) {
	fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
	fixed4 tex_spec = tex2D(_SpecMap, IN.uv_MainTex);
	 
	o.Albedo = tex.rgb * _Color.rgb;
	o.Gloss = tex_spec.a;
	o.Alpha = tex.a * _Color.a;
	o.Specular = _Shininess;
	o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
}
ENDCG
}

FallBack "Transparent/Cutout/Bumped Specular"
}
