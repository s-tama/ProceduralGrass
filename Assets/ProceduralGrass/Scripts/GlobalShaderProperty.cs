//
// GlobalShaderProperty.cs
//

using UnityEngine;

public class GlobalShaderProperty : MonoBehaviour
{
    void Update()
    {
        Shader.SetGlobalFloat("_DeltaTime", Time.deltaTime);
    }
}
