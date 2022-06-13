using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class FaceDirection : MonoBehaviour
{
    [SerializeField] private GameObject faceObj;
    private MaterialPropertyBlock _mpb;
    private SkinnedMeshRenderer _renderer;
    private Material _faceMat;
    
    private float _headForward;
    private float _headRight;

    private void OnEnable()
    {
        //_faceMat = faceObj.GetComponent<SkinnedMeshRenderer>().sharedMaterials[0];
        _renderer = faceObj.GetComponent<SkinnedMeshRenderer>();
        _mpb = new MaterialPropertyBlock();
        SetShaderValue();
    }

    private void Update()
    {
        SetShaderValue();
    }

    private void SetShaderValue()
    {
        _mpb.SetVector("_HeadFoward", gameObject.transform.forward);
        _mpb.SetVector("_HeadRight", gameObject.transform.right);
        _renderer.SetPropertyBlock(_mpb);
    }
}
