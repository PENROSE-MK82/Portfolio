using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

public class MissileShooter : MonoBehaviour
{
    [SerializeField] private GameObject unitObj;
    
    public void StartMissile()
    {
        StartCoroutine(ShootMissileCorou());
    }
    
    private IEnumerator ShootMissileCorou()
    {
        while (true)
        {
            yield return new WaitForSeconds(1);
            ShootMissile();
        }
    }
    
    private void ShootMissile()
    {
        float randX = Random.Range(-6, 6);
        float randY = Random.Range(1, 6);
        float randZ = Random.Range(-6, 6);
        
        while (randX > -3 && randX < 3)
        {
            randX = Random.Range(-6, 6);
        }
        while (randZ > -3 && randZ < 3)
        {
            randZ = Random.Range(-6, 6);
        }
        
        Vector3 thisPos = transform.position;

        Vector3 pos = new Vector3(thisPos.x + randX, thisPos.y + randY, thisPos.z + randZ);
        GameObject missileObj = EffectManager.i.ShowEffect(EffectManager.Effect.Missile, pos, 0.2f);

        Missile missile = missileObj.GetComponent<Missile>();
        missile.SetTarget(unitObj);
        missile.InitializeMissile();
    }
}
