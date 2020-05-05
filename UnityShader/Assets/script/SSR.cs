using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SSR : PostEffectBase {
	private Material SSRMaterial;
	public Shader SSRShader;
	public Material material{
		get{
			SSRMaterial = CheckShaderAndCreateMaterial(SSRShader, SSRMaterial);
			return SSRMaterial;
		}
	}

	private void OnEnable(){
		cam = GetComponent<Camera>();
		cam.depthTextureMode |= DepthTextureMode.Depth;
		cam.depthTextureMode |= DepthTextureMode.DepthNormals;
	}


	[Range(0, 600)]
	public int iter = 25;
	[Range(0.1f, 1000f)]
	public float thre = 1.0f;
	[Range(0.0f, 1.0f)]
	public float intensity = 0.5f;
	private Camera cam;

	void OnRenderImage(RenderTexture src, RenderTexture dest){
		if(material!=null){
			material.SetInt("_Iter", iter);
			material.SetFloat("_Thre", thre);
			material.SetFloat("_Intensity", intensity);
			material.SetMatrix("_CameraProjectionMatrix", cam.projectionMatrix);
			material.SetMatrix("_CameraInvProjectionMatrix", cam.projectionMatrix.inverse);
			material.SetMatrix("_WorldToCameraMatrix", cam.worldToCameraMatrix);
			Graphics.Blit(src, dest, material, 0);
		}else{
			Graphics.Blit(src, dest);
		}
	}

}
