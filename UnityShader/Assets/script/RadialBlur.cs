using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RadialBlur : PostEffectBase {
	public Shader RadialBlurShader;
	private Material RadialBlurMaterial;
	public Material material{
		get{
			RadialBlurMaterial = CheckShaderAndCreateMaterial(RadialBlurShader, RadialBlurMaterial);
			return RadialBlurMaterial;
		}
	}

	[Range(0, 10)]
	public int iter = 1;
	[Range(0.0f, 0.8f)]
	public float BlurRadius = 0.5f;
	[Range(0.0f, 0.5f)]
	public float ClearRadius = 0.2f;
	[Range(0.0f, 1.0f)]
	public float CenterX = 0.5f;
	[Range(0.0f, 1.0f)]
	public float CenterY = 0.5f;

	void OnRenderImage(RenderTexture src, RenderTexture dest){
		if(material!=null){
			material.SetFloat("_BlurRadius", BlurRadius);
			material.SetInt("_Iter", iter);
			material.SetFloat("_CenterX", CenterX);
			material.SetFloat("_CenterY", CenterY);
			material.SetFloat("_ClearRadius", ClearRadius);
			Graphics.Blit(src, dest, material, 0);
		}else{
			Graphics.Blit(src, dest);
		}
	}

}
