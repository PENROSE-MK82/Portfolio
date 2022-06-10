using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class FaceDirection : MonoBehaviour
{
    [SerializeField] private GameObject faceObj;
    private Material _faceMat;
    
    private float _headForward;
    private float _headRight;

    private void OnEnable()
    {
        _faceMat = faceObj.GetComponent<SkinnedMeshRenderer>().sharedMaterials[0];
        SetShaderValue();
    }

    private void Update()
    {
        SetShaderValue();
    }

    private void SetShaderValue()
    {
        _faceMat.SetVector("_HeadFoward", gameObject.transform.forward);
        _faceMat.SetVector("_HeadRight", gameObject.transform.right);
    }
}
