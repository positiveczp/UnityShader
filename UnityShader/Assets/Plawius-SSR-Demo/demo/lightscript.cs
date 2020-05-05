using UnityEngine;
using System.Collections;

public class lightscript : MonoBehaviour {

	Vector3 startPos;
	// Use this for initialization
	void Start () {
		startPos = this.transform.position;
	}
	
	// Update is called once per frame
	void Update () {
		this.transform.position = Quaternion.AngleAxis (Time.time * 50.0f, Vector3.up) * startPos;

		if (this.GetComponent<Camera>())
			this.GetComponent<Camera>().transform.LookAt (Vector3.zero);
	}
}
