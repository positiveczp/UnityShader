using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[AddComponentMenu("Image Effects/ScreenSpaceReflectionsEffect")]
[RequireComponent(typeof(Camera))]
public class SSREffect : MonoBehaviour
{	
	SSRSettings m_settings;
	protected SSRSettings settings {
		get {
			if (m_settings == null)
			{
				m_settings = (SSRSettings)FindObjectOfType(typeof(SSRSettings));
				if (m_settings == null)
					m_settings = (new GameObject("SSR_Settings")).AddComponent<SSRSettings>();
			}
			return m_settings;
		} 
	}

	public Shader blurShader = null;	
	public Shader ssrShader = null;	
	public Shader ssrDeferredShader = null;	

	static Material m_Material = null;
	protected Material material {
		get {
			if (m_Material == null) {

				Shader shader = ssrDeferredShader;
				if (this.GetComponent<Camera>().renderingPath == RenderingPath.DeferredLighting)
				{
					shader = ssrShader;
				}

				m_Material = new Material(shader);
				m_Material.hideFlags = HideFlags.DontSave;
			}
			return m_Material;
		} 
	}

	static Material m_MaterialBlur = null;
	protected Material materialBlur {
		get {
			if (m_MaterialBlur == null) {
				m_MaterialBlur = new Material(blurShader);
				m_MaterialBlur.hideFlags = HideFlags.DontSave;
			}
			return m_MaterialBlur;
		} 
	}

	private RenderingPath prevRenderingPath;

	void OnEnable () {

		prevRenderingPath = this.GetComponent<Camera>().renderingPath;

		if (this.GetComponent<Camera>().renderingPath == RenderingPath.DeferredLighting)
		{
			GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
			Debug.LogError("[SSR] Working in legacy mode (Deferred). Unity 5 PBR won't work with SSR!");
		}
		else if (this.GetComponent<Camera>().renderingPath == RenderingPath.DeferredShading)
		{
			GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
		}
		else
		{
			this.GetComponent<Camera>().renderingPath = RenderingPath.DeferredShading;
			Debug.Log("[SSR] Camera's rendering path changed to Deferred Shading");
		}

		if (ssrShader == null)
			ssrShader = Shader.Find ("Hidden/PlawiusSSR");
		if (ssrShader == null)
		{
			enabled = false;
			Debug.LogError("[SSR] Please, import PlawiusSSR shader, I cannot found it");
			return;
		}

		if (ssrDeferredShader == null)
			ssrDeferredShader = Shader.Find ("Hidden/PlawiusDeferredSSR");
		if (ssrDeferredShader == null)
		{
			enabled = false;
			Debug.LogError("[SSR] Please, import PlawiusDeferredSSR shader, I cannot found it");
			return;
		}

		if (blurShader == null)
			blurShader = Shader.Find ("Hidden/BlurEffectConeTap");
		if (blurShader == null)
		{
			enabled = false;
			Debug.LogError("[SSR] Please, import BlurEffectConeTap shader from Standard Unity pack");
			return;
		}
		
		if (!ssrShader || !material.shader.isSupported) {
			enabled = false;
			Debug.Log("[SSR] Screen space reflections is not supported on your videocard");
			return;
		}

		if (!blurShader || !materialBlur.shader.isSupported) {
			enabled = false;
			Debug.Log("[SSR] Blur shader is not supported on your videocard");
			return;
		}
	}
	
	protected void OnDisable() {
		if( m_Material ) {
			DestroyImmediate( m_Material );
			m_Material = null;
		}
		if( m_MaterialBlur ) {
			DestroyImmediate( m_MaterialBlur );
			m_MaterialBlur = null;
		}
	}	
	
	// --------------------------------------------------------
	
	protected void Start()
	{
		// Disable if we don't support image effects
		if (!SystemInfo.supportsImageEffects) {
			enabled = false;
			Debug.Log("[SSR] Image Effects is not supported");
			return;
		}
	}

	// Performs one blur iteration.
	public void FourTapCone (RenderTexture source, RenderTexture dest, int iteration)
	{
		float off = 0.5f + iteration * settings.blurSpread;
		Graphics.BlitMultiTap (source, dest, materialBlur,
		                       new Vector2(-off, -off),
		                       new Vector2(-off,  off),
		                       new Vector2( off,  off),
		                       new Vector2( off, -off)
		                       );
	}
	
	// Downsamples the texture to a quarter resolution.
	private void DownSample4x (RenderTexture source, RenderTexture dest)
	{
		float off = 1.0f;
		Graphics.BlitMultiTap (source, dest, materialBlur,
		                       new Vector2(-off, -off),
		                       new Vector2(-off,  off),
		                       new Vector2( off,  off),
		                       new Vector2( off, -off)
		                       );
	}

	
	// Called by the camera to apply the image effect
	void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
		if (Application.isEditor)
		{
			if (prevRenderingPath != this.GetComponent<Camera>().renderingPath)
			{
				this.enabled = false;
				this.enabled = true;
			}
		}

		Matrix4x4 P = this.GetComponent<Camera>().projectionMatrix; 

		bool d3d = SystemInfo.graphicsDeviceVersion.IndexOf("Direct3D") > -1;
		
		if (d3d)	
		{
			// Scale and bias from OpenGL -> D3D depth range
			for (int i = 0; i < 4; i++) 	
			{
				P[2,i] = P[2,i]*0.5f + P[3,i]*0.5f;	
			}	
		}

		Vector4 projInfo = new Vector4
			((-2.0f / (Screen.width * this.GetComponent<Camera>().rect.width * P[0])), 
			 (-2.0f / (Screen.height * this.GetComponent<Camera>().rect.height * P[5])),
			 ((1.0f - P[2]) / P[0]), 
			 ((1.0f + P[6]) / P[5]));

		this.material.SetVector ("_ProjInfo", projInfo); 
		this.material.SetMatrix ("_ProjMatrix",P);

		if (settings.cutOffStart >= settings.cutOffEnd)
		{
			settings.cutOffStart = settings.cutOffEnd;
		}

		this.material.SetFloat ("_Cutoff_Start", settings.cutOffStart);
		this.material.SetFloat ("_Cutoff_End", settings.cutOffEnd);

		this.material.SetFloat ("_FresnelStart", settings.fresnelFactorStart);
		this.material.SetFloat ("_FaceViewerFactor", settings.faceViewerFactor);

		this.material.SetFloat ("_LinearStepK", settings.linearCoefficient);
		this.material.SetFloat ("_Bias", settings.zBias);
		this.material.SetInt ("_MaxIter", settings.maxRaymarchIterations);
		// ---

		int rtW = source.width;
		int rtH = source.height;

		if (settings.iterations == 0 && settings.downscale <= 1)
		{
			Graphics.Blit(source, destination, this.material, 2);
		}
		else
		{
			RenderTexture blurredMain2 = RenderTexture.GetTemporary(rtW , rtH, 0);
			RenderTexture blurredMain = RenderTexture.GetTemporary(rtW / settings.downscale, rtH / settings.downscale, 0);

			Graphics.Blit(source, blurredMain2, this.material, 0);
			//Copy source to the 4x4 smaller texture.
			DownSample4x (blurredMain2, blurredMain);
			RenderTexture.ReleaseTemporary(blurredMain2);

			//Blur the small texture
			for(int i = 0; i < settings.iterations; i++)
			{
				RenderTexture buffer2 = RenderTexture.GetTemporary(rtW / settings.downscale, rtH / settings.downscale, 0);
				FourTapCone (blurredMain, buffer2, i);
				RenderTexture.ReleaseTemporary(blurredMain);
				blurredMain = buffer2;
			}

			this.material.SetTexture ("_Original", source);
			Graphics.Blit(blurredMain, destination, this.material, 1);


			RenderTexture.ReleaseTemporary(blurredMain);
		}

	}	
}


