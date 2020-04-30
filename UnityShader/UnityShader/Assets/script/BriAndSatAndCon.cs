using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BriAndSatAndCon : PostEffectBase {
	public Shader shader;
	private Material BriSatConMaterial;
	public Material material{
		get{
			BriSatConMaterial = CheckShaderAndCreateMaterial(shader, BriSatConMaterial);
			return BriSatConMaterial;
		}
	}

	[Range(0.0f, 3.0f)]
	public float brightness = 1.0f;
	[Range(0.0f, 3.0f)]
	public float saturation = 1.0f;
	[Range(0.0f, 3.0f)]
	public float constrast = 1.0f;

	void OnRenderImage(RenderTexture src, RenderTexture dest){
		if(material != null){
			material.SetFloat("_Brightness", brightness);
			material.SetFloat("_Saturation", saturation);
			material.SetFloat("_Constrast", constrast);
			Graphics.Blit(src, dest, material);
		}else{
			Graphics.Blit(src, dest);
		}
	}


}
