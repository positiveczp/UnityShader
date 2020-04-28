using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SSAO : PostEffectBase {
	public Shader SSAOShader;
	private Material SSAOMaterial;
	public Material material{
		get{
			SSAOMaterial = CheckShaderAndCreateMaterial(SSAOShader, SSAOMaterial);
			return SSAOMaterial;
		}
	}

	private void OnEnable(){
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
	}

	private List<Vector4> Samples = new List<Vector4>();
	[Range(0.001f, 1f)]
	public float SampleRadius = 0.01f;
	[Range(4, 32)]
	public int SamplesCount = 5;
	[Range(0.0f, 0.2f)]
	public float FadeBegin = 0.0f;
	[Range(0.3f, 10.0f)]
	public float FadeEnd = 0.5f;
	[Range(2.0f, 6.0f)]
	public float Constrast = 4.0f;
	[Range(0.001f, 0.1f)]
	public float Threshold = 0.1f;


	void OnRenderImage(RenderTexture src, RenderTexture dest){
		if(material!=null){
			GenSamples();
			material.SetFloat("_Threshold", Threshold);
			material.SetFloat("_SampleRadius", SampleRadius);
			material.SetFloat("_FadeBegin", FadeBegin);
			material.SetFloat("_FadeEnd", FadeEnd);
			material.SetFloat("_Constrast", Constrast);
			material.SetInt("_SamplesCount", SamplesCount);
			material.SetVectorArray("_Samples", Samples);
			Graphics.Blit(src, dest, material, 0);
		}else{
			Graphics.Blit(src, dest);
		}
	}

	private void GenSamples(){
		if(SamplesCount == Samples.Count) return;
		Samples.Clear();
		for(int i = 0; i < SamplesCount; ++i){
			Vector4 dir = new Vector4(Random.Range(-1.0f, 1.0f), Random.Range(-1.0f, 1.0f), Random.Range(-1.0f, 1.0f), 1.0f);
			dir.Normalize();
			// float scale = (float) i / SamplesCount;
			// scale = Mathf.Lerp(0.01f, 1.0f, scale*scale);
			// dir *= scale;
			Samples.Add(dir);
		}
	}
}
