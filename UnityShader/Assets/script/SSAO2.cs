using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SSAO2 : PostEffectBase {
	public Shader SSAOShader;
	private Material SSAOMaterial;
	public Material Material{
		get{
			SSAOMaterial = CheckShaderAndCreateMaterial(SSAOShader, SSAOMaterial);
			return SSAOMaterial;
		}
	}

	private void OnEnable(){
		m_Camera = GetComponent<Camera>();
		m_Camera.depthTextureMode |= DepthTextureMode.DepthNormals;
		m_Camera.depthTextureMode |= DepthTextureMode.Depth;
	}	

	private Camera m_Camera;
	public enum SampleCount
	{
		VeryLow,
		Low,
		Medium,
		High,
		Ultra
	}
	public Texture2D NoiseTexture;
	public SampleCount Samples = SampleCount.Medium;
	[Range(1, 4)]
	public int Downsampling = 1;

	[Range(0.01f, 1.25f)]
	public float Radius = 0.125f;

	[Range(0f, 16f)]
	public float Intensity = 2f;

	[Range(0f, 10f)]
	public float Distance = 1f;

	[Range(0f, 1f)]
	public float Bias = 0.1f;

	[Range(0f, 1f)]
	public float LumContribution = 0.5f;

	[ColorUsage(false)]
	public Color OcclusionColor = Color.black;

	public float CutoffDistance = 150f;
	public float CutoffFalloff = 50f;

	public bool DebugAO = true;




	void OnRenderImage(RenderTexture source, RenderTexture destination){
		if(Material!=null){
			int ssaoPass = SetShaderStates();
			Material.SetMatrix("_InverseViewProject", (m_Camera.projectionMatrix * m_Camera.worldToCameraMatrix).inverse);
			Material.SetMatrix("_CameraModelView", m_Camera.cameraToWorldMatrix);
			Material.SetTexture("_NoiseTex", NoiseTexture);
			Material.SetVector("_Params1", new Vector4(NoiseTexture == null ? 0f : NoiseTexture.width, Radius, Intensity, Distance));
			Material.SetVector("_Params2", new Vector4(Bias, LumContribution, CutoffDistance, CutoffFalloff));
			Material.SetColor("_OcclusionColor", OcclusionColor);

			RenderTexture rt = RenderTexture.GetTemporary(source.width / Downsampling, source.height / Downsampling, 0, RenderTextureFormat.ARGB32);
			Graphics.Blit(rt, rt, Material, 0); // Clear
			
			if (DebugAO)
			{
				Graphics.Blit(source, rt, Material, 0);
				Graphics.Blit(rt, destination);
				RenderTexture.ReleaseTemporary(rt);
				return;
			}

			// Graphics.Blit(src, dest, material, 0);
		}else{
			Graphics.Blit(source, destination);
		}
	}

	private string[] keywords = new string[2];
	int SetShaderStates()
	{
		// Shader keywords
		keywords[0] = (Samples == SampleCount.Low) ? "SAMPLES_LOW"
					: (Samples == SampleCount.Medium) ? "SAMPLES_MEDIUM"
					: (Samples == SampleCount.High) ? "SAMPLES_HIGH"
					: (Samples == SampleCount.Ultra) ? "SAMPLES_ULTRA"
					: "SAMPLES_VERY_LOW";

		keywords[1] = "HIGH_PRECISION_DEPTHMAP_OFF";
		Material.shaderKeywords = keywords;

		// SSAO pass ID
		int pass = 0;

		if (NoiseTexture != null)
			pass = 1;

		if (LumContribution >= 0.001f)
			pass += 2;

		return 1 + pass;
	}




}
