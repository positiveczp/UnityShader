using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GaussianBlur : PostEffectBase {
	public Shader GaussianBlurShader;
	private Material GaussianBlurMaterial;
	public Material material{
		get{
			GaussianBlurMaterial = CheckShaderAndCreateMaterial(GaussianBlurShader, GaussianBlurMaterial);
			return GaussianBlurMaterial;
		}
	}

	[Range(0, 4)]
	public int iter = 3;
	[Range(1, 8)]
	public int downSample = 2;
	[Range(0.2f, 3.0f)]
	public float blurRadius = 0.5f;

	void OnRenderImage(RenderTexture src, RenderTexture dest){
		if(material!=null){
			int srcWidth = src.width / downSample;
			int srcHeight = src. height / downSample;
			RenderTexture temp0 = RenderTexture.GetTemporary(srcWidth, srcHeight);
			Graphics.Blit(src, temp0);
			for(int idx = 0; idx<iter; ++idx){
				material.SetFloat("_BlurRadius", 1.0f + idx * blurRadius);	
				RenderTexture temp1 = RenderTexture.GetTemporary(srcWidth, srcHeight);
				Graphics.Blit(temp0, temp1, material, 0);
				RenderTexture.ReleaseTemporary(temp0);
				temp0 = temp1;
				temp1 = RenderTexture.GetTemporary(srcWidth, srcHeight);
				Graphics.Blit(temp0, temp1, material, 1);
				temp0 = temp1;
			}
			Graphics.Blit(temp0, dest);
			RenderTexture.ReleaseTemporary(temp0);
		}else{
			Graphics.Blit(src, dest);
		}
	}

}
