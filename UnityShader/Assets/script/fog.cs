using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class fog : PostEffectBase {
	public Shader fogShader;
	private Material fogMaterial;
	public Material material{
		get{
			fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
			return fogMaterial;
		}
	}

	void OnEnable(){
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
	}

	public Color fogColor = Color.white;
	[Range(0.0f, 100.0f)]
	public float minDist = 0.0f;
	[Range(10.0f, 200.0f)]
	public float maxDist = 10.0f;

	void OnRenderImage(RenderTexture src, RenderTexture dest){
		if(material != null){
			material.SetColor("_FogColor", fogColor);
			material.SetFloat("_MinDist", minDist);
			material.SetFloat("_MaxDist", maxDist);
			Graphics.Blit(src, dest, material);
		}else{
			Graphics.Blit(src, dest);
		}
	}
}
