using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EffectManager : MonoBehaviour
{
    public enum Effect
    {
        Missile,
        Explosion
    }

    private Dictionary<string, GameObject> _effectUsingPool = new Dictionary<string, GameObject>();
    private Dictionary<string, GameObject> _effectReadyPool = new Dictionary<string, GameObject>();

    [SerializeField] private Transform usingGroup;
    [SerializeField] private Transform readyGroup;
    
    [SerializeField] private GameObject missleEffect;
    [SerializeField] private GameObject explosionEffect;
    public static EffectManager i;
    private void Awake()
    {
        if (i == null)
        {
            i = this;
        }
        else if (i != this)
            Destroy(gameObject);
    }

    // Start is called before the first frame update
    void Start()
    {
        InitialzieEffectDictionary();
        InitializeEffect();
    }

    private void InitialzieEffectDictionary()
    {
        foreach (Effect effect in System.Enum.GetValues(typeof(Effect)))
        {
            string key = effect.ToString();
            
            GameObject effectUsingGroup = new GameObject(key);
            GameObject effectReadyGroup = new GameObject(key);
            
            effectUsingGroup.transform.SetParent(usingGroup);
            effectReadyGroup.transform.SetParent(readyGroup);
            
            _effectUsingPool.Add(key, effectUsingGroup);
            _effectReadyPool.Add(key, effectReadyGroup);
        }
    }
    
    private void InitializeEffect()
    {
        for (int i = 0; i < 10; i++)
        {
            GameObject missileEffectObj = Instantiate(missleEffect, _effectReadyPool["Missile"].transform);
            GameObject explosionEffectObj = Instantiate(explosionEffect, _effectReadyPool["Explosion"].transform);
            
            missileEffectObj.SetActive(false);
            explosionEffectObj.SetActive(false);
        }
    }

    public GameObject ShowEffect(Effect effectKey, Vector3 showPos, float size) // 피격 이펙트
    {
        string effectKeyStr = effectKey.ToString();
        int effectCount = _effectReadyPool[effectKeyStr].transform.childCount;
        
        GameObject usingEffect;
        if (effectCount > 0)
        {
            usingEffect = _effectReadyPool[effectKeyStr].transform.GetChild(0).gameObject;
        }
        else
        {
            usingEffect = Instantiate(explosionEffect, _effectReadyPool[effectKeyStr].transform);
        }
        
        usingEffect.transform.localScale = new Vector3(size, size, size);
        StartCoroutine(PoolCorou(effectKey, usingEffect, showPos));

        return usingEffect;
    }

    public void HideEffect(Effect effectKey, GameObject usingEffect)
    {
        string keyStr = effectKey.ToString();
        usingEffect.transform.SetParent(_effectReadyPool[keyStr].transform);
        usingEffect.SetActive(false);
    }
    
    IEnumerator PoolCorou(Effect effectKey, GameObject usingEffect, Vector3 showPos)
    {
        string keyStr = effectKey.ToString();
        usingEffect.transform.SetParent(_effectUsingPool[keyStr].transform);
        usingEffect.SetActive(true);
        usingEffect.transform.position = showPos;
        
        ParticleSystem particle = usingEffect.GetComponent<ParticleSystem>();
        
        float playTime = particle.main.startLifetimeMultiplier;
        particle.Play();

        yield return new WaitForSeconds(playTime);

        usingEffect.transform.SetParent(_effectReadyPool[keyStr].transform);
        usingEffect.SetActive(false);
    }
}
