using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpinBlur : PostEffectBase {
	public Shader SpinBlurShader;
	private Material SpinBlurMaterial;
	public Material material{
		get{
			SpinBlurMaterial = CheckShaderAndCreateMaterial(SpinBlurShader, SpinBlurMaterial);
			return SpinBlurMaterial;
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
	[Range(1.0f, 360.0f)]
	public float Degree = 5.0f;

	void OnRenderImage(RenderTexture src, RenderTexture dest){
		if(material!=null){
			material.SetFloat("_BlurRadius", BlurRadius);
			material.SetInt("_Iter", iter);
			material.SetFloat("_CenterX", CenterX);
			material.SetFloat("_CenterY", CenterY);
			material.SetFloat("_ClearRadius", ClearRadius);
			material.SetFloat("_Degree", Degree);
			Graphics.Blit(src, dest, material, 0);
		}else{
			Graphics.Blit(src, dest);
		}
	}

}
