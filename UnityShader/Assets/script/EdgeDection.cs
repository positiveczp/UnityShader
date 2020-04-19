using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeDection : PostEffectBase {
	public Shader edgeDectionShader;
	private Material edgeDectionMaterial;
	public Material material{
		get{
			edgeDectionMaterial = CheckShaderAndCreateMaterial(edgeDectionShader, edgeDectionMaterial);
			return edgeDectionMaterial;
		}
	}

	void OnRenderImage(RenderTexture src, RenderTexture dest){
		if(material != null){
			material.SetFloat("_EdgeOnly", edgesOnly);
			material.SetColor("_EdgeColor", edgeColor);
			material.SetColor("_BackgroundColor", backgroundColor);
			Graphics.Blit(src, dest, material);
		}else{
			Graphics.Blit(src, dest);
		}
	}

	[Range(0.0f, 1.0f)]
	public float edgesOnly = 0.0f;
	public Color edgeColor = Color.black;
	public Color backgroundColor = Color.white;

}
