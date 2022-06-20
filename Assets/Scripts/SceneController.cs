using System;
using System.Collections;
using System.Collections.Generic;
using DG.Tweening;
using UnityEngine;

public class SceneController : MonoBehaviour
{
    [SerializeField] private Transform lightTransform;
    [SerializeField] private Material scanningMat;
    [SerializeField] private GameObject shieldObj;
    [SerializeField] private Material shieldMat;

    [SerializeField] private MissileShooter missileShooter;
    private float _lightYAngle = -240;
    
    private void Awake()
    {
        Initialize();
    }

    void Start()
    {
        StartSequence();
    }

    // private void Update()
    // {
    //     _lightYAngle += Time.deltaTime * 5;
    //     lightTransform.eulerAngles = new Vector3(40, _lightYAngle, 0);
    // }

    private void Initialize()
    {
        scanningMat.SetFloat("_ScanDistance", 0);
        shieldMat.SetFloat("_Size", -1000);
        shieldObj.SetActive(false);
        
        _lightYAngle = -240;
    }

    private void StartSequence()
    {
        Sequence sequence = DOTween.Sequence()
            .AppendInterval(3)
            .Append(ShowCity())
            .AppendCallback( () => shieldObj.SetActive(true))
            .Append(ShowShield())
            .Append(SetShield())
            .OnComplete(() => missileShooter.StartMissile());
    }
    
    private Tween ShowCity()
    {
        return scanningMat.DOFloat(60, "_ScanDistance", 3);
    }

    private Tween ShowShield()
    {
        return shieldMat.DOFloat(1000, "_Size", 0.5f).SetEase(Ease.OutCubic);
    }
    
    private Tween SetShield()
    {
        return shieldMat.DOFloat(150, "_Size", 0.5f).SetEase(Ease.InCubic);
    }
}
