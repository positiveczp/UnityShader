using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class SSRSettings : MonoBehaviour {

	[Header("Blur")]
	[SerializeField]
	[Range(1, 4)]
	[Tooltip("Number of blur passes")]
	public int downscale = 2;
	
	[SerializeField]
	[Range(0, 8)]
	[Tooltip("Number of iterations in one pass")]
	public int iterations = 1;
	
	[SerializeField]
	[Range(0.1f, 1.0f)]
	public float blurSpread = 1.0f;

	[Header("Fade factors")]

	[Tooltip("Cut-off start")]
	[SerializeField]
	[Range(-1.0f, 1.0f)]
	public float cutOffStart = -0.1f;

	[Tooltip("Cut-off end")]
	[SerializeField]
	[Range(-1.0f, 1.0f)]
	public float cutOffEnd = 0.2f;

	[Tooltip("Fresnel Factor R0")]
	[SerializeField]
	[Range(0.0f, 1.0f)]
	public float fresnelFactorStart = 0.8f;

	[SerializeField]
	[Range(0.0f, 1.0f)]
	[Tooltip("Direction fade amount")]
	public float faceViewerFactor = 0.2f;

	[Header("Tweak these to fix artifacts")]
	[SerializeField]
	[Range(1.0f, 100.0f)]
	[Tooltip("Raymarch step size")]
	public float linearCoefficient = 30.0f;

	[SerializeField]
	[Range(0.0f, 0.2f)]
	[Tooltip("Z difference for collision detection during raymarching")]
	public float zBias = 0.005f;

	[Header("Try to keep this number small")]
	[SerializeField]
	[Range(8, 256)]
	[Tooltip("Raymarching iterations. The more you set, the better result will be (and the slower perf)")]
	public int maxRaymarchIterations = 32;

	bool working = false;

	void Start()
	{
		if (this.name != "SSR_Settings" || this.transform.parent != null)
		{
			DestroyImmediate(this);
			Debug.LogError("[SSR] Don't manually add internal SSRSettings.cs. It works only with SSR_Settings object in the root of hierarchy");
		}
		if (this.GetComponents<SSRSettings>().Length > 1)
		{
			DestroyImmediate(this);
			Debug.LogError("[SSR] Don't manually add internal SSRSettings.cs. This object already have one");
		}

		working = true;
	}

	void OnEnable()
	{
		if (working == false) return;
		foreach (SSREffect ssr_effect in Resources.FindObjectsOfTypeAll(typeof(SSREffect)) as SSREffect[])
		{
			ssr_effect.enabled = true;
		}
	}

	void OnDisable()
	{
		if (working == false) return;
		foreach (SSREffect ssr_effect in Resources.FindObjectsOfTypeAll(typeof(SSREffect)) as SSREffect[])
		{
			ssr_effect.enabled = false;
		}
	}
}
