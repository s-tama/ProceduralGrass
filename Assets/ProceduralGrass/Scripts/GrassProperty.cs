//
// GrassProperty.cs
//

using UnityEngine;

public class GrassProperty : MonoBehaviour
{
    [SerializeField] Material _material = null;

    void Update()
    {
        _material.SetFloat("_DeltaTime", Time.deltaTime);
    }
}
