// Upgrade NOTE: commented out 'float4x4 _WorldToCamera', a built-in variable
// Upgrade NOTE: replaced '_WorldToCamera' with 'unity_WorldToCamera'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/PlawiusSSR"
{
        Properties
    {
    	_MainTex ("", any) = "" {} 
    	_Original ("", any) = "" {} 
    	
    	_FresnelStart ("Fresnel Factor R0", Range(0.0,1.0)) = 0.0
		_FaceViewerFactor ("Face Viewer Factor", Range(0.0,1.0)) = 0.5

		_Cutoff_Start ("Cut-off start", Range(-1.0,1.0)) = -0.2
		_Cutoff_End ("Cut-off end", Range(-1.0,1.0)) = 0.2

		_LinearStepK ("Linear Step Coefficient", Range(1.0,30.0)) = 30.0
		_Bias ("Z Bias", Range(0.0,0.2)) = 0.0001
		_MaxIter ("Max Raymarch Iterations", Range(16,256)) = 128
    }

    CGINCLUDE
    
    #include "UnityCG.cginc"
    #pragma glsl


	float _FresnelStart;
	float _FaceViewerFactor;
			
	float _Cutoff_Start;
	float _Cutoff_End;
	
	int _MaxIter;
	
	float _LinearStepK;
	float _Bias;
	
	sampler2D _Original;// should be build-in
    
    sampler2D _MainTex;// should be build-in
    float4 _MainTex_ST;// should be build-in
    float4 _MainTex_TexelSize;// should be build-in


    uniform float _fadeToView;
    uniform float4x4 _ProjMatrix;
    uniform float4 _ProjInfo;

    sampler2D _CameraNormalsTexture;		// should be build-in
    // float4x4 _WorldToCamera;

    sampler2D _CameraDepthTexture;	// should be build-in
    float4 _CameraDepthTexture_TexelSize;	// should be build-in
		
	struct v2f {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    v2f vert (appdata_img v)
    {
        v2f o;
        o.pos = UnityObjectToClipPos (v.vertex);
        o.uv =  v.texcoord.xy;
        
   		#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0.0)
			o.uv.y = 1.0 - o.uv.y;
		#endif	
	
        return o;
    }
    
   	float3 ReconstructCSPosition(float2 S, float linEyeZ) 
	{
		return float3(( ( S.xy * _MainTex_TexelSize.zw) * _ProjInfo.xy + _ProjInfo.zw) * linEyeZ, linEyeZ);
	}
	
	float3 view2ndc(float3 view_vector)
	{
		float4 clip_pos = mul(_ProjMatrix, float4(view_vector, 1.0));
		return clip_pos.xyz / clip_pos.w;
	}

	float3 view2screen(float3 view_vector)
	{
		return float3(view2ndc(view_vector).xy * 0.5 + 0.5, view_vector.z);
	}

	float3 getViewNormal(float2 uv_coords, float4 normal_spec)
	{
		//float4 normal_spec = tex2D (_CameraNormalsTexture, uv_coords);
		float3 world_normal = normal_spec.xyz * 2.0 - 1.0;
		
		float3 view_normal = mul ((float3x3)unity_WorldToCamera, world_normal);
		view_normal.z = -view_normal.z;
		
		return normalize(view_normal);
	}

	float2 center_texel(float2 uv_coords, float2 texel_size)
	{
		return uv_coords;
//		float2 uv_coord_texel = uv_coords / texel_size;
//		float2 uv_coord_texel_center = float2(((int)(uv_coord_texel.x / 0.5)) * 0.5 , ((int)(uv_coord_texel.y / 0.5)) * 0.5);
//		return uv_coord_texel_center * texel_size;
	}

	float sampleDepth(float2 uv_coords)
	{
		return UNITY_SAMPLE_DEPTH(tex2Dlod (_CameraDepthTexture, float4(center_texel(uv_coords,_CameraDepthTexture_TexelSize.xy),0,0)));
	}

	float sampleDepthD(float2 uv_coords, float2 dx, float2 dy)
	{
		return UNITY_SAMPLE_DEPTH(tex2D (_CameraDepthTexture, center_texel(uv_coords, _CameraDepthTexture_TexelSize.xy), dx, dy));
	}

	float mapTo01(float val, float min_val, float max_val)
	{
		return saturate((val - min_val) / (max_val - min_val));
	}
	
//	float rand(float2 co){
//    	return frac(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
//	}
	
	// ---------------------------
	float4 calculateSSR(v2f i, float4 main_image, float4 normal_spec)
	{
		const float cutoff_start_z = _Cutoff_Start;
		const float cutoff_end_z = _Cutoff_End;
		
		// ---------------------------
		float view_linear_depth = LinearEyeDepth(sampleDepth(i.uv));
		
		if (view_linear_depth > _ProjectionParams.z)
			return main_image;
		
		// ---------------------------
		float3 view_normal = getViewNormal(i.uv, normal_spec);
		float3 view_position = ReconstructCSPosition(i.uv, view_linear_depth);
		float3 view_position_normalized = normalize(view_position);
		
		// ---------------------------
		float3 view_reflect = normalize( reflect(view_position_normalized, view_normal) );
		
		float lerp_factor = saturate(normal_spec.w);
		
		float view_factor = mapTo01(view_reflect.z, cutoff_start_z, cutoff_end_z);
		lerp_factor *= view_factor;
				
		// ---------------------------
		float face_viewer_factor = saturate(1.0 - (mapTo01(view_reflect.z, cutoff_end_z, 1.0) * _FaceViewerFactor));
		float fresnel_factor = saturate(_FresnelStart + (1.0 - _FresnelStart) * pow(1.0 - dot(view_normal, view_position_normalized),  5));
    	
    	lerp_factor *= face_viewer_factor;
		lerp_factor *= fresnel_factor;
		// ---------------------------

		if (lerp_factor <= 0.0f)
		{
			return main_image;
		}
		
		
    	float3 view_reflect_position = view_position + view_reflect;
    	float3 screen_reflect_position = float3(view2screen(view_reflect_position).xy, view_reflect_position.z);
    	float3 screen_start_pos = float3(i.uv, view_linear_depth);
    	float3 screen_reflect_one_pixel_delta = screen_reflect_position - screen_start_pos;
    	
    	// one pixel step in screen space (xy)
    	screen_reflect_one_pixel_delta *= min(_CameraDepthTexture_TexelSize.x, _CameraDepthTexture_TexelSize.y) / length(screen_reflect_one_pixel_delta.xy);
    	
    	// ---------------------------
		float2 dx, dy;
		dx = ddx( i.uv );
		dy = ddy( i.uv );
		
		float screen_reflect_lenght = _LinearStepK; 
		
		// ---------------------------
		float3 screen_reflect_delta = screen_reflect_one_pixel_delta * screen_reflect_lenght;
		
		float3 screen_current_position = screen_start_pos + screen_reflect_delta;
		float3 screen_prev_position = screen_start_pos;
		
		int curr_sample_num = 0;
		float curr_dist = 0.0;
		float halve_again = 1.0;
		float delta;
		
		float back_mul = 1;
		//for (int curr_sample_num = 0; curr_sample_num < _MaxIter; ++curr_sample_num) 
		while (curr_sample_num < _MaxIter)
		{
    		if (screen_current_position.x < 0 || screen_current_position.x > 1) break;//return main_image;
			if (screen_current_position.y < 0 || screen_current_position.y > 1) break;//return main_image;
			if (screen_current_position.z < 0 || screen_current_position.z > _ProjectionParams.z) break;//return main_image;
			
			float current_texture_eye_depth = LinearEyeDepth(sampleDepthD(screen_current_position.xy, dx, dy));
    		float current_traced_eye_depth = screen_current_position.z;
    		
    		float delta = current_traced_eye_depth - current_texture_eye_depth;
    		if (delta >= 0.0) 
    		{
    			if (delta <= _Bias)
    			{
					float2 screen_corrected_position = screen_prev_position.xy + (current_texture_eye_depth - screen_prev_position.z) * screen_reflect_delta.xy;
		    		float4 reflected = tex2D(_MainTex, screen_corrected_position.xy, dx, dy);
		    		
		    		// ---------------------------
					float screendedgefact = saturate(distance(screen_current_position.xy , float2(0.5, 0.5)) * 2.0);
					screendedgefact = 1.0 - screendedgefact * screendedgefact;
					
					lerp_factor *= screendedgefact;
					lerp_factor *= 1.0 - (float)curr_sample_num / (float)_MaxIter;
					lerp_factor = 1.0 - lerp_factor;

	    			main_image.xyz = lerp(reflected.xyz, main_image.xyz, lerp_factor);
	    			
	    			main_image.w = lerp_factor;
	    			// ---------------------------
						
		    		return main_image;
		    	}
		    	else
		    	{
		    		back_mul = 0.5;
		    		
		    		screen_reflect_lenght *= back_mul;
		    		screen_reflect_delta *= back_mul;
		    	
		    		curr_dist -= screen_reflect_lenght;
				
		    		screen_current_position = screen_prev_position + screen_reflect_delta;
		    		
		    		//return float4(1,0,0,1);
		    	}
			}
    		else
    		{
	    		screen_prev_position = screen_current_position;
				
				screen_reflect_lenght *= back_mul;
			    screen_reflect_delta *= back_mul;
			    					
				curr_dist += screen_reflect_lenght;
				screen_current_position += screen_reflect_delta;
				
				//return float4(1,1,1,1);
			}
			
			++curr_sample_num;
		}
		
		return main_image;
	}


	half4 frag_only_SSR (v2f i) : COLOR
    {
    	float4 normal_spec = tex2D (_CameraNormalsTexture, i.uv);
		float4 result = float4(0, 0, 0, 1);
		
		return (normal_spec.a < 0.001) ? result : calculateSSR(i, result, normal_spec);
    }
    
    half4 frag_mixed (v2f i) : COLOR
    {
    	float4 normal_spec = tex2D (_CameraNormalsTexture, i.uv);
    	float4 result = tex2D(_MainTex, i.uv);

		return (normal_spec.a < 0.001) ? result : calculateSSR(i, result, normal_spec);
    }

	half4 frag_lerp (v2f i) : COLOR
    {
    	float4 original = tex2D(_Original, i.uv);
    	float4 reflection = tex2D(_MainTex, i.uv);
    	
    	float lerp_factor = reflection.a;
    	
    	return float4(reflection.xyz + original.xyz * (lerp_factor), 1.0);
    }

    ENDCG


	SubShader
    {
            
        // -------- BLUR -----------
        // 0: just reflections
        Pass
        {
        	CGPROGRAM

			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag_only_SSR
			#pragma target 3.0 
			//#pragma exclude_renderers d3d11_9x flash
		
			ENDCG
        }

		// 1: blend reflections and main tex
        Pass
        {
        	CGPROGRAM

			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag_lerp
			#pragma target 3.0 
			//#pragma exclude_renderers d3d11_9x flash
		
			ENDCG
        }
                
        // -------- WITHOUT BLUR -----------
        // 2: 
        Pass
        {
        	CGPROGRAM

			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag_mixed
			#pragma target 3.0 
			//#pragma exclude_renderers d3d11_9x flash
		
			ENDCG
        }
        
    }

}