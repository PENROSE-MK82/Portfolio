using System;
using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;

public class Missile : MonoBehaviour
{
    [SerializeField] private float speed;
    [SerializeField] private Transform target;
    
    private void Start()
    {
        InitializeMissile();
    }

    private void Update()
    {
        gameObject.transform.Translate(Vector3.forward * 0.01f * speed);
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag($"Missile")) return;

        Vector3 hitPos = other.ClosestPoint(transform.position);
        EffectManager.i.HideEffect(EffectManager.Effect.Missile, gameObject);
        EffectManager.i.ShowEffect(EffectManager.Effect.Explosion, hitPos, 0.2f);
    }

    public void InitializeMissile()
    {
        Vector3 relativePos = target.position - transform.position + new Vector3(0, 1.5f, 0);
        Quaternion rotation = Quaternion.LookRotation(relativePos, Vector3.up);
        transform.rotation = rotation;
    }
    
    public void SetTarget(GameObject targetObj)
    {
        target = targetObj.transform;
    }

}
