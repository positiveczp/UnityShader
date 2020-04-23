using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoxBlur  : PostEffectBase{
    public Shader BoxBlurShader;
    private Material BoxBlurMaterial;
    public Material material{
        get{
            BoxBlurMaterial = CheckShaderAndCreateMaterial(BoxBlurShader, BoxBlurMaterial);
            return BoxBlurMaterial;
        }
    } 

    [Range(0, 10)]
    public int Iter = 0;
    [Range(1, 8)]
    public int downSample = 1;
    [Range(0.2f, 3.0f)]
    public float blurRadius = 0.5f;

    void OnRenderImage(RenderTexture src, RenderTexture dest){
        if(material!=null){
            material.SetFloat("_BlurRadius", blurRadius);
            int width = src.width / downSample;
            int height = src.height / downSample;
            RenderTexture temp0 = RenderTexture.GetTemporary(width, height);
            Graphics.Blit(src, temp0);
            for(int idx = 0; idx < Iter; ++idx){
                material.SetFloat("_BlurRadius", blurRadius);
                RenderTexture temp1 = RenderTexture.GetTemporary(width, height);
                Graphics.Blit(temp0, temp1, material, 0);
                RenderTexture.ReleaseTemporary(temp0);
                temp0 = temp1;
                temp1 = RenderTexture.GetTemporary(width, height);
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

