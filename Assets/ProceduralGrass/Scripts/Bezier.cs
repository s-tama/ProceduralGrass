using UnityEngine;

public class Bezier : MonoBehaviour
{
    [SerializeField] Transform[] _points = new Transform[3];
    [SerializeField] Transform _p = null;
    [SerializeField, Range(0, 1)] float _deltaTime = 0f;

    void Update()
    {
        Vector3 p0 = Vector3.Lerp(_points[0].position, _points[1].position, _deltaTime);
        Vector3 p1 = Vector3.Lerp(_points[1].position, _points[2].position, _deltaTime);
        _p.position = Vector3.Lerp(p0, p1, _deltaTime);
    }
}
