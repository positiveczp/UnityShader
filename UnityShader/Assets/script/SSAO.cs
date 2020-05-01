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
<<<<<<< HEAD
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
	}

	private List<Vector4> Samples = new List<Vector4>();
	[Range(0.001f, 1f)]
	public float SampleRadius = 0.01f;
=======
		cam = GetComponent<Camera>();
		cam.depthTextureMode |= DepthTextureMode.DepthNormals;
		cam.depthTextureMode |= DepthTextureMode.Depth;
	}

	private List<Vector4> Samples = new List<Vector4>();
	[Range(0.001f, 0.005f)]
	public float SampleRadius = 0.001f;
>>>>>>> b24cb2116ef72a111e79e35c80f69bef3d335e53
	[Range(4, 32)]
	public int SamplesCount = 5;
	[Range(0.0f, 0.2f)]
	public float FadeBegin = 0.0f;
	[Range(0.3f, 10.0f)]
	public float FadeEnd = 0.5f;
	[Range(2.0f, 6.0f)]
	public float Constrast = 4.0f;
<<<<<<< HEAD
	[Range(0.001f, 0.1f)]
	public float Threshold = 0.1f;
=======
	[Range(0.01f, 0.1f)]
	public float Bias = 0.2f;
	public Texture2D NoiseTexture;
>>>>>>> b24cb2116ef72a111e79e35c80f69bef3d335e53

	[Range(1, 4)]
	public int Downsampling = 1;

	[Range(0.01f, 1.25f)]
	public float Radius = 0.125f;

	[Range(0f, 16f)]
	public float Intensity = 2f;

	[Range(0f, 10f)]
	public float Distance = 1f;

	[Range(0f, 1f)]
	public float LumContribution = 0.5f;

	[ColorUsage(false)]
	public Color OcclusionColor = Color.black;

	public float CutoffDistance = 150f;
	public float CutoffFalloff = 50f;

	private Camera cam;

	void OnRenderImage(RenderTexture src, RenderTexture dest){
		if(material!=null){
			GenSamples();
<<<<<<< HEAD
			material.SetMatrix("_InverseProjectionMatrix", GetComponent<Camera>().projectionMatrix.inverse);
			material.SetMatrix("_ProjectionMatrix", GetComponent<Camera>().projectionMatrix);
			material.SetFloat("_Threshold", Threshold);
			material.SetFloat("_SampleRadius", SampleRadius);
			material.SetFloat("_FadeBegin", FadeBegin);
			material.SetFloat("_FadeEnd", FadeEnd);
			material.SetFloat("_Constrast", Constrast);
			material.SetInt("_SamplesCount", SamplesCount);
			material.SetVectorArray("_Samples", Samples);
=======
			material.SetMatrix("_CameraModelView", cam.cameraToWorldMatrix);
			material.SetMatrix("_CameraProjection", cam.projectionMatrix);
			material.SetMatrix("_InverseViewProject", (cam.projectionMatrix * cam.worldToCameraMatrix).inverse);
			// material.SetFloat("_Bias", Bias);
			// material.SetFloat("_SampleRadius", SampleRadius);
			// material.SetFloat("_FadeBegin", FadeBegin);
			// material.SetFloat("_FadeEnd", FadeEnd);
			// material.SetFloat("_Constrast", Constrast);
			// material.SetInt("_SamplesCount", SamplesCount);
			// material.SetVectorArray("_Samples", Samples);
			material.SetTexture("_NoiseTex", NoiseTexture);
			material.SetVector("_Params1", new Vector4(NoiseTexture == null ? 0f : NoiseTexture.width, Radius, Intensity, Distance));
			material.SetVector("_Params2", new Vector4(Bias, LumContribution, CutoffDistance, CutoffFalloff));
			material.SetColor("_OcclusionColor", OcclusionColor);
>>>>>>> b24cb2116ef72a111e79e35c80f69bef3d335e53
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
